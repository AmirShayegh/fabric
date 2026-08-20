import SwiftUI
#if os(macOS)
import AppKit
#endif

// MARK: - Fabric Attention Pulse

/// Which halo, if any, belongs behind the content right now.
///
/// Split out as a pure function because it is the whole rule, and because a
/// view that must be driven by a real window's occlusion state is otherwise
/// untestable: this way the decision has a test and only the wiring does not.
enum FabricAttentionPulseGate {
    enum Halo: Equatable {
        /// Nothing to draw attention to.
        case none
        /// Visible but not animating: hidden window, or reduced motion.
        case still
        /// The breathing halo.
        case pulsing
    }

    /// The `still` fallback is deliberate rather than "draw nothing". The state
    /// has to stay legible while the animator is gated, or a window revealed
    /// after being hidden would show no sign of a live session until the next
    /// frame of an animation that has not started yet.
    static func halo(isActive: Bool, windowVisible: Bool, reduceMotion: Bool) -> Halo {
        guard isActive else { return .none }
        return windowVisible && !reduceMotion ? .pulsing : .still
    }
}

/// Wraps any content in a slow breathing halo that says "there is something
/// live in here" without demanding a click.
///
/// **Why this is a Fabric component rather than app code (ISS-740).** A
/// `repeatForever` animation never pauses on macOS: each display-link tick
/// re-renders the hosting view, and in a large window that render walks the
/// whole hierarchy. One decorative ring kept a production app at 25-45% CPU
/// with every window occluded, minimized, or on another Space. Anything that
/// animates for as long as a session is alive has exactly that shape, so the
/// occlusion gate lives here, in one place, rather than being remembered at
/// each call site.
///
/// The gate works by IDENTITY SWAP, not by a transaction: removing the animated
/// subtree is what actually cancels the animator. Writing the animated state
/// back inside a `disablesAnimations` transaction does not stop it.
public struct FabricAttentionPulse<Content: View>: View {
    private let isActive: Bool
    private let accent: FabricAccent
    private let content: Content

    /// - Parameters:
    ///   - isActive: whether there is anything to draw attention to. False
    ///     renders the content untouched, with no animator and no reader.
    ///   - accent: halo colour.
    ///   - content: the thing being highlighted (typically a toolbar icon).
    public init(
        isActive: Bool,
        accent: FabricAccent = .editorialThread,
        @ViewBuilder content: () -> Content
    ) {
        self.isActive = isActive
        self.accent = accent
        self.content = content()
    }

    public var body: some View {
        content
            // `isActive` is the `.none` case of the gate, expressed
            // structurally: while there is nothing to highlight, neither the
            // halo nor the occlusion reader exists at all.
            .background { if isActive { Halo(accent: accent) } }
    }

    /// Owns the visibility state, and owns it for exactly as long as the pulse
    /// is active.
    ///
    /// That lifetime is the point. Keeping `windowVisible` on the parent let it
    /// outlive a deactivation: hide the window while inactive, reactivate, and
    /// the first frame would read `true` from before and mount the animator
    /// behind a window nobody is looking at, until the freshly mounted reader
    /// got around to reporting. A child whose identity begins with the active
    /// period cannot carry a stale answer into it -- every activation starts
    /// from `false` and pulses only once a reader has said otherwise.
    private struct Halo: View {
        let accent: FabricAccent

        @Environment(\.accessibilityReduceMotion) private var reduceMotion

        #if os(macOS)
        @State private var windowVisible = false
        #elseif targetEnvironment(macCatalyst)
        /// Catalyst is the case where BOTH other answers are wrong. It is not
        /// `os(macOS)`, so it gets no occlusion reader, but its windows can be
        /// minimized, covered, or on another Space while the app stays active,
        /// so the iOS reasoning below does not hold either. With no way to
        /// observe visibility here, refusing to animate is the only answer that
        /// cannot reproduce ISS-740; the state stays legible as a static halo.
        private let windowVisible = false
        #else
        /// No occlusion concept applies: an app that is not on screen is
        /// suspended, so its animations stop with it.
        private let windowVisible = true
        #endif

        var body: some View {
            content
            #if os(macOS)
                .background {
                    WindowOcclusionReader { visible in
                        if visible != windowVisible { windowVisible = visible }
                    }
                }
            #endif
        }

        @ViewBuilder
        private var content: some View {
            switch FabricAttentionPulseGate.halo(
                isActive: true, windowVisible: windowVisible, reduceMotion: reduceMotion
            ) {
            case .pulsing:
                PulsingHalo(accent: accent)
            case .still, .none:
                StaticHalo(accent: accent)
            }
        }
    }

    private struct PulsingHalo: View {
        let accent: FabricAccent
        @State private var isAnimating = false

        var body: some View {
            Circle()
                .fill(accent.foreground.opacity(isAnimating ? 0.22 : 0.06))
                .scaleEffect(isAnimating ? 1.35 : 0.95)
                .animation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true), value: isAnimating)
                .onAppear { isAnimating = true }
                .allowsHitTesting(false)
        }
    }

    private struct StaticHalo: View {
        let accent: FabricAccent

        var body: some View {
            Circle()
                .fill(accent.foreground.opacity(0.14))
                .scaleEffect(1.15)
                .allowsHitTesting(false)
        }
    }
}

#if os(macOS)
public extension View {
    /// Reports whether this view's own window is currently visible on screen.
    ///
    /// Exposed so that non-view work which should also stop while hidden --
    /// polling, decay timers, anything on a clock -- can gate on the SAME
    /// signal the animation gate uses, instead of each caller inventing its own
    /// notion of "visible" and drifting from it.
    ///
    /// `occlusionState` covers every invisible case at once: fully covered by
    /// other windows, minimized, app hidden, and Spaces the user is not looking
    /// at. Reports `false` when detached from any window.
    func fabricWindowVisibility(_ onChange: @escaping (Bool) -> Void) -> some View {
        background(WindowOcclusionReader(onChange: onChange))
    }
}
#endif

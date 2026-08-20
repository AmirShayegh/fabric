import SwiftUI
#if os(macOS)
import AppKit
#endif

// MARK: - Fabric Pulse Ring

/// The expanding pulse ring used behind "current" markers (timeline phases,
/// step indicators). One shared implementation so the visibility gating below
/// exists in exactly one place.
///
/// **Why gated (ISS-740):** a `repeatForever` animation never pauses on macOS.
/// Each display-link tick re-renders the hosting view, and in a large window
/// that render walks the whole hierarchy, so one decorative 26pt ring kept a
/// production app at 25-45% CPU with every window occluded, minimized, or on
/// another Space. AppKit reports exactly the needed signal
/// (`NSWindow.occlusionState`), so on macOS the ring animates only while its
/// own window is actually visible. `TimelineView(.animation)` is NOT an
/// alternative: measured on macOS 26 it keeps ticking while hidden and costs
/// more while visible (per-frame body evaluation).
struct FabricPulseRing: View {
    let accent: FabricAccent
    let delay: Double

    #if os(macOS)
    @State private var windowVisible = false

    var body: some View {
        ZStack {
            if windowVisible {
                AnimatedRing(accent: accent, delay: delay)
            } else {
                StaticRing(accent: accent)
            }
        }
        .background(WindowOcclusionReader { visible in
            if visible != windowVisible { windowVisible = visible }
        })
    }
    #else
    var body: some View {
        AnimatedRing(accent: accent, delay: delay)
    }
    #endif

    /// The animated form, mounted ONLY while the window is visible. Removing
    /// the view is what actually cancels the repeatForever animation: writing
    /// the animated state back inside a disablesAnimations transaction does
    /// NOT stop the running animator on macOS (measured: the display-link
    /// render loop keeps ticking). Identity change tears the animator down
    /// deterministically; re-mounting restarts the pulse from onAppear.
    private struct AnimatedRing: View {
        let accent: FabricAccent
        let delay: Double

        @State private var isAnimating = false

        var body: some View {
            Circle()
                .stroke(accent.foreground, lineWidth: 1.5)
                .frame(width: 26, height: 26)
                .scaleEffect(isAnimating ? 1.8 : 0.9)
                .opacity(isAnimating ? 0 : 0.5)
                .onAppear {
                    withAnimation(
                        .easeOut(duration: FabricAnimation.pulseDuration)
                        .repeatForever(autoreverses: false)
                        .delay(delay)
                    ) {
                        isAnimating = true
                    }
                }
                .accessibilityHidden(true)
        }
    }

    #if os(macOS)
    /// The resting form shown while the window is not visible: the ring at
    /// its base scale and opacity, no animation attached.
    private struct StaticRing: View {
        let accent: FabricAccent

        var body: some View {
            Circle()
                .stroke(accent.foreground, lineWidth: 1.5)
                .frame(width: 26, height: 26)
                .scaleEffect(0.9)
                .opacity(0.5)
                .accessibilityHidden(true)
        }
    }
    #endif
}

#if os(macOS)

// MARK: - Window Occlusion Reader

/// Zero-size AppKit view that reports whether ITS OWN window is visible on
/// screen. `occlusionState` covers every invisible case at once: fully
/// covered by other windows, minimized, app hidden, and Spaces the user is
/// not looking at. Reports `false` when detached from any window.
private struct WindowOcclusionReader: NSViewRepresentable {
    let onChange: (Bool) -> Void

    final class ReaderView: NSView {
        var onChange: ((Bool) -> Void)?

        // Selector-based observation: auto-unregistered on dealloc since
        // macOS 10.11, so no deinit cleanup (which strict concurrency
        // forbids for a MainActor-isolated stored token anyway).
        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            NotificationCenter.default.removeObserver(
                self, name: NSWindow.didChangeOcclusionStateNotification, object: nil
            )
            guard let window else {
                onChange?(false)
                return
            }
            onChange?(window.occlusionState.contains(.visible))
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(occlusionChanged(_:)),
                name: NSWindow.didChangeOcclusionStateNotification,
                object: window
            )
        }

        @objc private func occlusionChanged(_ note: Notification) {
            guard let win = note.object as? NSWindow, win == window else { return }
            onChange?(win.occlusionState.contains(.visible))
        }
    }

    func makeNSView(context: Context) -> ReaderView {
        let view = ReaderView()
        view.onChange = onChange
        return view
    }

    func updateNSView(_ view: ReaderView, context: Context) {
        view.onChange = onChange
    }
}

#endif

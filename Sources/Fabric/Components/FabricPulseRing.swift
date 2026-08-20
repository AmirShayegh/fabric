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

    @State private var isAnimating = false

    var body: some View {
        ring
        #if os(macOS)
            .background(WindowOcclusionReader { visible in
                if visible {
                    startPulse()
                } else {
                    stopPulse()
                }
            })
        #else
            .onAppear { startPulse() }
        #endif
    }

    private var ring: some View {
        Circle()
            .stroke(accent.foreground, lineWidth: 1.5)
            .frame(width: 26, height: 26)
            .scaleEffect(isAnimating ? 1.8 : 0.9)
            .opacity(isAnimating ? 0 : 0.5)
            .accessibilityHidden(true)
    }

    private func startPulse() {
        guard !isAnimating else { return }
        withAnimation(
            .easeOut(duration: FabricAnimation.pulseDuration)
            .repeatForever(autoreverses: false)
            .delay(delay)
        ) {
            isAnimating = true
        }
    }

    private func stopPulse() {
        // Writing the state back without animation is what actually cancels a
        // repeatForever animation; plain assignment would leave it running.
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            isAnimating = false
        }
    }
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
        private var observer: NSObjectProtocol?

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            if let observer {
                NotificationCenter.default.removeObserver(observer)
                self.observer = nil
            }
            guard let window else {
                onChange?(false)
                return
            }
            onChange?(window.occlusionState.contains(.visible))
            observer = NotificationCenter.default.addObserver(
                forName: NSWindow.didChangeOcclusionStateNotification,
                object: window,
                queue: .main
            ) { [weak self] note in
                guard let win = note.object as? NSWindow else { return }
                self?.onChange?(win.occlusionState.contains(.visible))
            }
        }

        deinit {
            if let observer {
                NotificationCenter.default.removeObserver(observer)
            }
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

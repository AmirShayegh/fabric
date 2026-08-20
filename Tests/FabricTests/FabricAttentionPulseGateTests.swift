import XCTest
@testable import Fabric

/// The rule behind `FabricAttentionPulse`, tested where it can be tested.
///
/// The view itself is driven by a real window's occlusion state, so a unit test
/// cannot observe its subtree without a hosting harness this package does not
/// have. What CAN be pinned is the decision, and the decision is the part with
/// consequences: choosing `pulsing` while a window is hidden is ISS-740, where
/// an unconditional `repeatForever` held a production app at 25-45% CPU with
/// every window occluded.
final class FabricAttentionPulseGateTests: XCTestCase {

    private func halo(
        active: Bool, visible: Bool, reduceMotion: Bool
    ) -> FabricAttentionPulseGate.Halo {
        FabricAttentionPulseGate.halo(
            isActive: active, windowVisible: visible, reduceMotion: reduceMotion
        )
    }

    /// The full matrix, so no future edit can quietly widen the one case that
    /// is allowed to animate.
    func test_onlyVisibleActiveAndFullMotionPulses() {
        XCTAssertEqual(halo(active: true, visible: true, reduceMotion: false), .pulsing)

        XCTAssertEqual(halo(active: true, visible: false, reduceMotion: false), .still)
        XCTAssertEqual(halo(active: true, visible: true, reduceMotion: true), .still)
        XCTAssertEqual(halo(active: true, visible: false, reduceMotion: true), .still)

        for visible in [true, false] {
            for reduceMotion in [true, false] {
                XCTAssertEqual(
                    halo(active: false, visible: visible, reduceMotion: reduceMotion), .none,
                    "inactive must never render a halo (visible=\(visible) reduceMotion=\(reduceMotion))"
                )
            }
        }
    }

    /// A hidden window is the ISS-740 case by name, stated on its own so the
    /// reason survives a refactor of the matrix above.
    func test_hiddenWindowNeverPulses() {
        XCTAssertNotEqual(halo(active: true, visible: false, reduceMotion: false), .pulsing)
    }

    /// Gating the animator must not blank the state. A window revealed after
    /// being hidden has to show a live session immediately, not wait for a
    /// frame of an animation that has not started.
    func test_gatedActiveStateStaysVisible() {
        XCTAssertEqual(halo(active: true, visible: false, reduceMotion: false), .still)
        XCTAssertNotEqual(halo(active: true, visible: false, reduceMotion: false), FabricAttentionPulseGate.Halo.none)
    }
}

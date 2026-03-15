import SwiftUI

/// Elevation tokens for the Fabric design system.
///
/// Shadows in Fabric follow the "pebbles on fabric" metaphor:
/// - **Outer shadows** come in pairs: a tight contact shadow + a wide ambient shadow.
/// - **Inner shadows** (insets) represent elements recessed *into* the fabric.
///
/// Shadow *colors* live in ``FabricColors`` (`.shadow`, `.shadowTight`, `.innerShadow`).
/// This enum provides only *geometry* — radius and y-offset values.
public enum FabricElevation {

    // MARK: - Shadow Geometry

    /// Radius and vertical offset for a single shadow pass.
    public struct Shadow: Sendable {
        public let radius: Double
        public let y: Double
    }

    /// A paired contact + ambient shadow for elevated elements ("pebbles").
    public struct ShadowPair: Sendable {
        /// Close, sharp contact shadow (uses ``FabricColors/shadowTight``).
        public let tight: Shadow
        /// Wide, diffuse ambient shadow (uses ``FabricColors/shadow``).
        /// `nil` for the smallest elements that only need a contact shadow.
        public let ambient: Shadow?

        /// Tiny indicators — status dots, loading dots. Contact shadow only.
        public static let micro = ShadowPair(
            tight: Shadow(radius: 0.3, y: 0.3), ambient: nil
        )
        /// Small controls — toggle knobs, timeline dots, pills.
        public static let low = ShadowPair(
            tight: Shadow(radius: 0.5, y: 0.5), ambient: Shadow(radius: 4, y: 2)
        )
        /// Medium surfaces — task cards (resting), buttons.
        public static let mid = ShadowPair(
            tight: Shadow(radius: 1, y: 1), ambient: Shadow(radius: 8, y: 4)
        )
        /// Large surfaces — cards, task cards (hovered).
        public static let high = ShadowPair(
            tight: Shadow(radius: 1.5, y: 1.5), ambient: Shadow(radius: 12, y: 6)
        )
        /// Lifted/dragged elements — maximum elevation.
        public static let drag = ShadowPair(
            tight: Shadow(radius: 2, y: 3), ambient: Shadow(radius: 20, y: 10)
        )
    }

    // MARK: - Drag Scalar Conveniences

    /// Non-optional ambient shadow radius for drag level.
    public static var dragAmbientRadius: Double { ShadowPair.drag.ambient?.radius ?? 0 }
    /// Non-optional ambient shadow Y offset for drag level.
    public static var dragAmbientY: Double { ShadowPair.drag.ambient?.y ?? 0 }
    /// Non-optional contact shadow radius for drag level.
    public static var dragContactRadius: Double { ShadowPair.drag.tight.radius }
    /// Non-optional contact shadow Y offset for drag level.
    public static var dragContactY: Double { ShadowPair.drag.tight.y }

    // MARK: - Inset (Inner Shadow) Geometry

    /// Geometry for inner shadows on recessed elements.
    public struct Inset: Sendable {
        public let radius: Double
        public let spread: Double
        public let y: Double

        /// Barely-there recess — timeline event dots, slider tracks.
        public static let subtle = Inset(radius: 1.5, spread: 1.5, y: 0.5)

        /// Light recess — text fields, error banners.
        public static let shallow = Inset(radius: 2, spread: 2, y: 1)

        /// Visible recess — kanban columns, drop placeholders, pressed buttons.
        public static let recessed = Inset(radius: 3, spread: 3, y: 1.5)

        /// Deep press — task cards in pressed state.
        public static let deep = Inset(radius: 4, spread: 5, y: 2)
    }
}

// MARK: - View Extensions

extension View {
    /// Apply the standard pebble double-shadow for a given elevation level.
    /// Handles nil ambient automatically (micro-level elements skip ambient).
    public func fabricShadow(
        _ level: FabricElevation.ShadowPair,
        tightColor: Color = FabricColors.shadowTight,
        ambientColor: Color = FabricColors.shadow
    ) -> some View {
        self
            .shadow(color: tightColor, radius: level.tight.radius, x: 0, y: level.tight.y)
            .shadow(
                color: level.ambient != nil ? ambientColor : .clear,
                radius: level.ambient?.radius ?? 0,
                x: 0,
                y: level.ambient?.y ?? 0
            )
    }

    /// Apply an inner shadow using an elevation inset token.
    public func fabricInnerShadow<S: Shape>(
        _ shape: S,
        _ level: FabricElevation.Inset,
        color: Color = FabricColors.innerShadow
    ) -> some View {
        self.innerShadow(shape, color: color, radius: level.radius, spread: level.spread, y: level.y)
    }
}

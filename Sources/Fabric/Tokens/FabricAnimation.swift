import SwiftUI

// MARK: - Animation Tokens

/// Centralized animation presets for the Fabric design system.
/// All component animations should use these tokens instead of hardcoded values.
public enum FabricAnimation {
    // MARK: - Duration Scale

    /// 0.15s — hover, micro-interactions
    public static let quick: Double = 0.15
    /// 0.25s — press, state changes
    public static let standard: Double = 0.25
    /// 0.35s — springs, expand/collapse
    public static let smooth: Double = 0.35
    /// 0.40s — loading dot bounce, phased loops
    public static let phased: Double = 0.40
    /// 0.50s — modals, overlays
    public static let extended: Double = 0.50
    /// 1.2s — slow ambient loops
    public static let ambient: Double = 1.2
    /// 1.5s — skeleton shimmer pass duration
    public static let shimmerDuration: Double = 1.5
    /// Shimmer bright-band width as fraction of total width
    public static let shimmerBandFraction: Double = 0.35
    /// Seconds per full spinner revolution
    public static let spinPeriod: Double = 1.8
    /// Fraction of circle shown in loading ring (0.28 ≈ 100°)
    public static let loadingRingArc: Double = 0.28
    /// Broadcast pulse full cycle duration
    public static let pulseDuration: Double = 2.5
    /// Stagger offset between two pulse rings
    public static let pulseStagger: Double = 1.25

    // MARK: - Animation Presets

    /// Snappy spring for press/tap interactions
    public static let press = Animation.spring(response: 0.25, dampingFraction: 0.70)
    /// Gentle spring for value changes and expand/collapse
    public static let soft = Animation.spring(response: 0.35, dampingFraction: 0.65)
    /// Quick ease-out for hover state transitions
    public static let hover = Animation.easeOut(duration: quick)
    /// Spring for drag lift — weighty pickup, high damping so a pebble doesn't bounce
    public static let lift = Animation.spring(response: 0.30, dampingFraction: 0.75)
    /// Spring for reorder shifts — cards sliding to make room
    public static let reorder = Animation.spring(response: 0.35, dampingFraction: 0.70)
    /// Snappy spring for sliding indicators (tab underline, segmented control capsule)
    public static let slide = Animation.spring(response: 0.18, dampingFraction: 0.88)

    // MARK: - Drag & Drop Constants

    /// Scale factor for a card lifted during drag
    public static let liftScale: Double = 1.04
    /// Rotation angle (degrees) for lifted drag card
    public static let liftRotation: Double = 1.5
    /// Opacity for the ghost card left at the source position
    public static let ghostOpacity: Double = 0.4
    /// Scale factor for a column when it is an active drop target
    public static let dropTargetScale: Double = 1.01
    /// Ambient shadow radius for a lifted/dragged card
    @available(*, deprecated, message: "Use FabricElevation.drag")
    public static var dragShadowRadius: Double { FabricElevation.dragAmbientRadius }
    /// Ambient shadow Y offset for a lifted/dragged card
    @available(*, deprecated, message: "Use FabricElevation.drag")
    public static var dragShadowY: Double { FabricElevation.dragAmbientY }
    /// Contact shadow radius for a lifted/dragged card
    @available(*, deprecated, message: "Use FabricElevation.drag")
    public static var dragContactShadowRadius: Double { FabricElevation.dragContactRadius }
    /// Contact shadow Y offset for a lifted/dragged card
    @available(*, deprecated, message: "Use FabricElevation.drag")
    public static var dragContactShadowY: Double { FabricElevation.dragContactY }
    /// Width of the custom drag preview
    public static let dragPreviewWidth: Double = 240
    /// Opacity of the custom drag preview
    public static let dragPreviewOpacity: Double = 0.85
    /// Default height for the drop placeholder indicator
    public static let placeholderHeight: Double = 52
}

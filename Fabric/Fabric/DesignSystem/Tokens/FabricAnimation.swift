import SwiftUI

// MARK: - Animation Tokens

/// Centralized animation presets for the Fabric design system.
/// All component animations should use these tokens instead of hardcoded values.
enum FabricAnimation {
    // MARK: - Duration Scale

    /// 0.15s — hover, micro-interactions
    static let quick: Double = 0.15
    /// 0.25s — press, state changes
    static let standard: Double = 0.25
    /// 0.35s — springs, expand/collapse
    static let smooth: Double = 0.35
    /// 0.40s — loading dot bounce, phased loops
    static let phased: Double = 0.40
    /// 0.50s — modals, overlays
    static let extended: Double = 0.50
    /// 1.2s — slow ambient loops
    static let ambient: Double = 1.2
    /// 1.5s — skeleton shimmer pass duration
    static let shimmerDuration: Double = 1.5
    /// Shimmer bright-band width as fraction of total width
    static let shimmerBandFraction: Double = 0.35
    /// Seconds per full spinner revolution
    static let spinPeriod: Double = 1.8
    /// Fraction of circle shown in loading ring (0.28 ≈ 100°)
    static let loadingRingArc: Double = 0.28
    /// Broadcast pulse full cycle duration
    static let pulseDuration: Double = 2.5
    /// Stagger offset between two pulse rings
    static let pulseStagger: Double = 1.25

    // MARK: - Animation Presets

    /// Snappy spring for press/tap interactions
    static let press = Animation.spring(response: 0.25, dampingFraction: 0.70)
    /// Gentle spring for value changes and expand/collapse
    static let soft = Animation.spring(response: 0.35, dampingFraction: 0.65)
    /// Quick ease-out for hover state transitions
    static let hover = Animation.easeOut(duration: quick)
}

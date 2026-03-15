import SwiftUI

/// A recessed "dip in the fabric" indicating where a dragged card will land.
/// Follows the fabric metaphor — the surface depresses to receive the pebble.
public struct FabricDropPlaceholder: View {

    public let height: Double
    public let accent: FabricAccent

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(height: Double = FabricAnimation.placeholderHeight, accent: FabricAccent = .indigo) {
        self.height = height
        self.accent = accent
    }

    private var shape: RoundedRectangle {
        FabricSpacing.shape(radius: FabricSpacing.radiusSm)
    }

    public var body: some View {
        shape
            .fill(accent.fill)
            .frame(height: height)
            .fabricInnerShadow(shape, .recessed)
            .overlay {
                shape.strokeBorder(
                    accent.foreground.opacity(0.25),
                    style: StrokeStyle(lineWidth: 1.5, dash: [6, 4])
                )
            }
            .transition(
                reduceMotion
                    ? .opacity
                    : .asymmetric(
                        insertion: .scale(scale: 0.95, anchor: .top)
                            .combined(with: .opacity),
                        removal: .scale(scale: 0.98)
                            .combined(with: .opacity)
                    )
            )
            .accessibilityHidden(true)
    }
}

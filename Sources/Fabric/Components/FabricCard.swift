import SwiftUI

public struct FabricCard<Content: View>: View {

    public enum Style {
        /// Default pebble-on-fabric card: canvas fill with faint linen texture,
        /// `.high` double shadow, highlight rim at the top edge.
        case elevated
        /// Editorial page-on-page card: parchment fill with *no* texture overlay
        /// so the card reads as a clean page above the paper ground. Thinner,
        /// warmer rim and softer `.mid` shadow. Use when sitting on
        /// `.fabricSurfacePaper()`.
        case editorial
    }

    public let style: Style
    @ViewBuilder public let content: Content

    public init(
        style: Style = .elevated,
        @ViewBuilder content: () -> Content
    ) {
        self.style = style
        self.content = content()
    }

    private var shape: RoundedRectangle {
        FabricSpacing.shape(radius: FabricSpacing.radiusMd)
    }

    public var body: some View {
        switch style {
        case .elevated: elevatedBody
        case .editorial: editorialBody
        }
    }

    // MARK: - Variants

    private var elevatedBody: some View {
        content
            .padding(FabricSpacing.cardPadding)
            .fabricSurface(FabricColors.canvas, textureIntensity: 0.025)
            .clipShape(shape)
            // Subtle top-edge highlight — light catching the cloth surface
            .overlay {
                shape.strokeBorder(
                    LinearGradient(
                        colors: [FabricColors.highlight, Color.clear],
                        startPoint: .top,
                        endPoint: .center
                    ),
                    lineWidth: 0.5
                )
            }
            // Double shadow: tight contact shadow + wide ambient
            .fabricShadow(.high)
    }

    private var editorialBody: some View {
        content
            .padding(FabricSpacing.cardPadding)
            // Flat parchment fill — deliberately no texture so the card reads
            // as a pressed page above the paper ground, not another layer of grain.
            .background(FabricColors.parchment)
            .clipShape(shape)
            // Hairline thread-tinted rim — reads as a paper deckle, not a pebble rim.
            .overlay {
                shape.strokeBorder(
                    FabricColors.connectorThread,
                    lineWidth: 0.5
                )
            }
            // Softer shadow — the page isn't lifted as far off the ground.
            .fabricShadow(.mid)
    }
}

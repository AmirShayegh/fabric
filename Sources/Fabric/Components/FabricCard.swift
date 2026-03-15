import SwiftUI

public struct FabricCard<Content: View>: View {

    @ViewBuilder public let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    private var shape: RoundedRectangle {
        FabricSpacing.shape(radius: FabricSpacing.radiusMd)
    }

    public var body: some View {
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
}

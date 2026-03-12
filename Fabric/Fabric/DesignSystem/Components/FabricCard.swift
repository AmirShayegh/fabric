import SwiftUI

struct FabricCard<Content: View>: View {

    @ViewBuilder let content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    private var shape: RoundedRectangle {
        FabricSpacing.shape(radius: FabricSpacing.radiusMd)
    }

    var body: some View {
        content()
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
            .shadow(color: FabricColors.shadowTight, radius: 1, x: 0, y: 1)
            .shadow(color: FabricColors.shadow, radius: 12, x: 0, y: 6)
    }
}

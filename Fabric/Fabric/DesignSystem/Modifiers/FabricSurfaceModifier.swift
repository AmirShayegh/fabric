import SwiftUI

struct FabricSurfaceModifier: ViewModifier {
    let color: Color
    let textureIntensity: CGFloat

    @Environment(\.displayScale) private var displayScale

    func body(content: Content) -> some View {
        content
            .background {
                ZStack {
                    color

                    Rectangle()
                        .foregroundStyle(
                            TextureGenerator.linenPaint(
                                displayScale: displayScale,
                                intensity: textureIntensity
                            )
                        )
                }
            }
    }
}

extension View {
    func fabricSurface(
        _ color: Color = FabricColors.linen,
        textureIntensity: CGFloat = 0.04
    ) -> some View {
        modifier(FabricSurfaceModifier(color: color, textureIntensity: textureIntensity))
    }
}

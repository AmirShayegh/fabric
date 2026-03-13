import SwiftUI

public struct FabricSurfaceModifier: ViewModifier {
    public let color: Color
    public let textureIntensity: CGFloat

    @Environment(\.displayScale) private var displayScale

    public init(color: Color, textureIntensity: CGFloat) {
        self.color = color
        self.textureIntensity = textureIntensity
    }

    public func body(content: Content) -> some View {
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
    public func fabricSurface(
        _ color: Color = FabricColors.linen,
        textureIntensity: CGFloat = 0.04
    ) -> some View {
        modifier(FabricSurfaceModifier(color: color, textureIntensity: textureIntensity))
    }
}

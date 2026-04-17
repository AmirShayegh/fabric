import SwiftUI

public struct FabricSurfaceModifier: ViewModifier {
    public let color: Color
    public let textureIntensity: CGFloat
    public let warmGlow: Bool
    public let weave: TextureGenerator.Weave

    @Environment(\.displayScale) private var displayScale
    @Environment(\.colorScheme) private var colorScheme

    public init(
        color: Color,
        textureIntensity: CGFloat,
        warmGlow: Bool = false,
        weave: TextureGenerator.Weave = .linen
    ) {
        self.color = color
        self.textureIntensity = textureIntensity
        self.warmGlow = warmGlow
        self.weave = weave
    }

    public func body(content: Content) -> some View {
        content
            .background {
                ZStack {
                    color

                    // Paper-by-candlelight glow is dark-mode only. In light mode
                    // the surface is already cream, so layering `.plusLighter`
                    // warm gradients over it pushes the whole surface toward
                    // yellow. The candlelight metaphor only reads on dim paper.
                    if warmGlow && colorScheme == .dark {
                        // Two soft warm radial glows in opposing corners.
                        // Ochre bottom-left, thread top-right. Very low opacity — ambient, not decorative.
                        GeometryReader { geo in
                            ZStack {
                                RadialGradient(
                                    colors: [FabricColors.ochre.opacity(0.10), .clear],
                                    center: UnitPoint(x: 0.15, y: 0.85),
                                    startRadius: 0,
                                    endRadius: max(geo.size.width, geo.size.height) * 0.55
                                )
                                RadialGradient(
                                    colors: [FabricColors.thread.opacity(0.09), .clear],
                                    center: UnitPoint(x: 0.85, y: 0.15),
                                    startRadius: 0,
                                    endRadius: max(geo.size.width, geo.size.height) * 0.55
                                )
                            }
                            .blendMode(.plusLighter)
                            .allowsHitTesting(false)
                        }
                    }

                    Rectangle()
                        .foregroundStyle(
                            TextureGenerator.linenPaint(
                                displayScale: displayScale,
                                intensity: textureIntensity,
                                weave: weave
                            )
                        )
                }
            }
    }
}

extension View {
    public func fabricSurface(
        _ color: Color = FabricColors.linen,
        textureIntensity: CGFloat = 0.04,
        warmGlow: Bool = false,
        weave: TextureGenerator.Weave = .linen
    ) -> some View {
        modifier(FabricSurfaceModifier(
            color: color,
            textureIntensity: textureIntensity,
            warmGlow: warmGlow,
            weave: weave
        ))
    }

    /// Editorial "paper by candlelight" surface — canvas with subtle warm
    /// radial glows in the corners **in dark mode only**. In light mode the
    /// glow is suppressed (it would push the already-cream surface yellow),
    /// so this modifier reads as plain textured canvas.
    public func fabricSurfaceDim() -> some View {
        fabricSurface(FabricColors.canvas, textureIntensity: 0.06, warmGlow: true)
    }

    /// Handmade-paper surface — parchment tone with directional fiber grain and
    /// sparse warm flecks. Use as the *ground* that editorial `FabricCard`s sit
    /// on (pair with `FabricCard(style: .editorial)`). `warmGlow` only renders
    /// in dark mode; in light mode the parchment stands alone.
    public func fabricSurfacePaper(warmGlow: Bool = true) -> some View {
        fabricSurface(
            FabricColors.parchment,
            textureIntensity: 0.055,
            warmGlow: warmGlow,
            weave: .paper
        )
    }
}

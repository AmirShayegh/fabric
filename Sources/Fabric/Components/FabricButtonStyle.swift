import SwiftUI

public struct FabricButtonStyle: ButtonStyle {

    public enum Variant { case primary, secondary, ghost }

    public let variant: Variant

    public init(variant: Variant = .primary) {
        self.variant = variant
    }

    public func makeBody(configuration: Configuration) -> some View {
        FabricButtonBody(variant: variant, configuration: configuration)
    }
}

// MARK: - Button Metrics (per-variant typography + sizing tokens)

/// Centralizes all per-variant visual values for the button.
/// Typography intentionally diverges from FabricTextStyle because buttons
/// need tighter tracking and variant-specific sizing (Figma source: Button/v2).
private enum ButtonMetrics {

    struct Values {
        let font: Font
        let tracking: CGFloat
        let horizontalPadding: CGFloat
        let verticalPadding: CGFloat
        let minHeight: CGFloat
    }

    static subscript(variant: FabricButtonStyle.Variant) -> Values {
        switch variant {
        case .primary:
            Values(
                font: .system(size: 15, weight: .medium),
                tracking: -0.23,
                horizontalPadding: FabricSpacing.lg,
                verticalPadding: 8,
                minHeight: FabricSpacing.buttonMinHeightMd
            )
        case .secondary:
            Values(
                font: .system(size: 17, weight: .medium),
                tracking: 0,
                horizontalPadding: FabricSpacing.lg,
                verticalPadding: 10,
                minHeight: FabricSpacing.buttonMinHeightLg
            )
        case .ghost:
            Values(
                font: .system(size: 15, weight: .regular),
                tracking: -0.23,
                horizontalPadding: FabricSpacing.md,
                verticalPadding: 6,
                minHeight: FabricSpacing.buttonMinHeightSm
            )
        }
    }
}

// MARK: - Body View (owns @State for stable hover tracking)

private struct FabricButtonBody: View {

    let variant: FabricButtonStyle.Variant
    let configuration: ButtonStyleConfiguration

    @State private var isHovered = false
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.displayScale) private var displayScale
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var metrics: ButtonMetrics.Values { ButtonMetrics[variant] }

    var body: some View {
        let isPressed = configuration.isPressed

        configuration.label
            .font(metrics.font)
            .tracking(metrics.tracking)
            .foregroundStyle(foregroundColor)
            .padding(.horizontal, metrics.horizontalPadding)
            .padding(.vertical, metrics.verticalPadding)
            .frame(minHeight: metrics.minHeight)
            .background { backgroundView(isPressed: isPressed) }
            .clipShape(Capsule())
            .scaleEffect(isPressed && !reduceMotion ? 0.96 : 1.0)
            .opacity(isEnabled ? 1.0 : 0.5)
            .animation(
                reduceMotion ? nil : FabricAnimation.press,
                value: isPressed
            )
            .animation(
                reduceMotion ? nil : FabricAnimation.hover,
                value: isHovered
            )
            .onHover { hovering in
                guard isEnabled else { return }
                isHovered = hovering
            }
    }

    // MARK: - Background

    @ViewBuilder
    private func backgroundView(isPressed: Bool) -> some View {
        ZStack {
            Capsule().fill(backgroundColor(isPressed: isPressed))

            if variant == .secondary {
                Capsule().foregroundStyle(
                    TextureGenerator.linenPaint(displayScale: displayScale, intensity: 0.02)
                )
            }

            if !isPressed && variant != .ghost {
                Capsule().strokeBorder(
                    LinearGradient(
                        colors: [FabricColors.highlight, Color.clear],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 0.5
                )
            }
        }
        .innerShadow(
            Capsule(),
            color: FabricColors.innerShadow,
            radius: isPressed ? FabricElevation.Inset.recessed.radius : 0,
            spread: isPressed ? FabricElevation.Inset.recessed.spread : 0,
            y: isPressed ? FabricElevation.Inset.recessed.y : 0
        )
        .fabricShadow(
            .mid,
            tightColor: .clear,
            ambientColor: isPressed || !isEnabled || variant == .ghost ? .clear : FabricColors.shadow
        )
    }

    // MARK: - Colors

    private var foregroundColor: Color {
        switch variant {
        case .primary:   FabricColors.onPrimary
        case .secondary: FabricColors.inkPrimary
        case .ghost:     FabricColors.inkSecondary
        }
    }

    private func backgroundColor(isPressed: Bool) -> Color {
        switch variant {
        case .primary:
            if isPressed { FabricColors.buttonPrimaryPressed }
            else if isHovered { FabricColors.buttonPrimaryHovered }
            else { FabricColors.buttonPrimary }
        case .secondary:
            if isPressed { FabricColors.canvas.opacity(0.80) }
            else if isHovered { FabricColors.canvas.opacity(0.95) }
            else { FabricColors.canvas.opacity(0.88) }
        case .ghost:
            if isPressed { FabricColors.burlap.opacity(0.18) }
            else if isHovered { FabricColors.burlap.opacity(0.08) }
            else { Color.clear }
        }
    }
}

// MARK: - Convenience

extension ButtonStyle where Self == FabricButtonStyle {
    public static var fabric:          FabricButtonStyle { .init(variant: .primary) }
    public static var fabricSecondary: FabricButtonStyle { .init(variant: .secondary) }
    public static var fabricGhost:     FabricButtonStyle { .init(variant: .ghost) }
}

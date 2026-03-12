import SwiftUI

struct FabricButtonStyle: ButtonStyle {

    enum Variant { case primary, secondary, ghost }

    let variant: Variant

    func makeBody(configuration: Configuration) -> some View {
        FabricButtonBody(variant: variant, configuration: configuration)
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

    private var shape: RoundedRectangle {
        FabricSpacing.shape(radius: FabricSpacing.radiusSm)
    }

    var body: some View {
        let isPressed = configuration.isPressed

        configuration.label
            .fabricTypography(.label)
            .foregroundStyle(foregroundColor)
            .frame(minWidth: FabricSpacing.buttonMinWidth, minHeight: FabricSpacing.buttonHeight)
            .padding(.horizontal, FabricSpacing.lg)
            .background { backgroundView(isPressed: isPressed) }
            .clipShape(shape)
            .scaleEffect(isPressed && !reduceMotion ? 0.95 : 1.0)
            .opacity(isEnabled ? 1.0 : 0.5)
            .animation(
                reduceMotion ? nil : .spring(response: 0.25, dampingFraction: 0.7),
                value: isPressed
            )
            .animation(
                reduceMotion ? nil : .easeOut(duration: 0.15),
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
            shape.fill(backgroundColor(isPressed: isPressed))

            if variant != .ghost {
                shape.foregroundStyle(
                    TextureGenerator.linenPaint(displayScale: displayScale, intensity: 0.025)
                )
            }

            if !isPressed && variant != .ghost {
                shape.strokeBorder(
                    LinearGradient(
                        colors: [FabricColors.highlight, Color.clear],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 0.75
                )
            }
        }
        .innerShadow(
            shape,
            color: FabricColors.innerShadow,
            radius: isPressed ? 4 : 0,
            spread: isPressed ? 5 : 0,
            y: isPressed ? 2 : 0
        )
        .shadow(
            color: isPressed || !isEnabled ? .clear : FabricColors.shadowTight,
            radius: 1, x: 0, y: 1
        )
        .shadow(
            color: isPressed || !isEnabled ? .clear : FabricColors.shadow,
            radius: 6, x: 0, y: 3
        )
    }

    // MARK: - Colors

    private var foregroundColor: Color {
        switch variant {
        case .primary:   return FabricColors.onPrimary
        case .secondary: return FabricColors.inkPrimary
        case .ghost:     return FabricColors.inkSecondary
        }
    }

    private func backgroundColor(isPressed: Bool) -> Color {
        switch variant {
        case .primary:
            if isPressed { return FabricColors.buttonPrimaryPressed }
            if isHovered { return FabricColors.buttonPrimaryHovered }
            return FabricColors.buttonPrimary
        case .secondary:
            if isPressed { return FabricColors.burlap.opacity(0.35) }
            if isHovered { return FabricColors.canvas }
            return FabricColors.canvas.opacity(0.90)
        case .ghost:
            if isPressed { return FabricColors.burlap.opacity(0.18) }
            if isHovered { return FabricColors.burlap.opacity(0.08) }
            return Color.clear
        }
    }
}

// MARK: - Convenience

extension ButtonStyle where Self == FabricButtonStyle {
    static var fabric:          FabricButtonStyle { .init(variant: .primary) }
    static var fabricSecondary: FabricButtonStyle { .init(variant: .secondary) }
    static var fabricGhost:     FabricButtonStyle { .init(variant: .ghost) }
}

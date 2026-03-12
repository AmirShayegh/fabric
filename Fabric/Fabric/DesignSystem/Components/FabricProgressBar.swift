import SwiftUI

struct FabricProgressBar: View {

    let value: Double
    let label: String?
    var showPercentage: Bool = false
    var accent: FabricAccent = .indigo

    init(
        value: Double,
        label: String? = nil,
        showPercentage: Bool = false,
        accent: FabricAccent = .indigo
    ) {
        self.value = value
        self.label = label
        self.showPercentage = showPercentage
        self.accent = accent
    }

    var body: some View {
        FabricProgressBarBody(
            value: value,
            label: label,
            showPercentage: showPercentage,
            accent: accent
        )
    }
}

// MARK: - Body View

private struct FabricProgressBarBody: View {

    let value: Double
    let label: String?
    let showPercentage: Bool
    let accent: FabricAccent

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.displayScale) private var displayScale

    private var clampedValue: Double { value.isFinite ? max(0, min(value, 1)) : 0 }

    var body: some View {
        VStack(alignment: .leading, spacing: FabricSpacing.xs) {
            if label != nil || showPercentage {
                HStack {
                    if let label {
                        Text(label).fabricCaption()
                    }
                    Spacer()
                    if showPercentage {
                        Text("\(Int(clampedValue * 100))%")
                            .fabricTypography(.caption)
                            .foregroundStyle(FabricColors.inkTertiary)
                    }
                }
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Track — recessed groove
                    Capsule()
                        .fill(FabricColors.parchment)
                        .innerShadow(
                            Capsule(),
                            color: FabricColors.innerShadow,
                            radius: 2, spread: 2, y: 1
                        )

                    // Fill — elevated progress
                    if clampedValue > 0 {
                        Capsule()
                            .fill(accent.foreground)
                            .overlay {
                                Capsule()
                                    .foregroundStyle(
                                        TextureGenerator.linenPaint(
                                            displayScale: displayScale,
                                            intensity: 0.02
                                        )
                                    )
                            }
                            .overlay {
                                Capsule()
                                    .strokeBorder(
                                        LinearGradient(
                                            colors: [FabricColors.highlight, Color.clear],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        ),
                                        lineWidth: 0.5
                                    )
                            }
                            .clipShape(Capsule())
                            .frame(width: geo.size.width * clampedValue)
                    }
                }
            }
            .frame(height: FabricSpacing.progressBarHeight)
        }
        .opacity(isEnabled ? 1.0 : 0.5)
        .animation(
            reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.65),
            value: clampedValue
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label ?? "Progress")
        .accessibilityValue("\(Int(clampedValue * 100)) percent")
    }
}

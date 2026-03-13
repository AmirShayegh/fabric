import SwiftUI

public struct FabricProgressBar: View {

    public let value: Double
    public let label: String?
    public var showPercentage: Bool = false
    public var accent: FabricAccent = .indigo

    public init(
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

    public var body: some View {
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

    private var clampedValue: Double { value.isFinite ? max(0, min(value, 1)) : 0 }
    private let barHeight: CGFloat = FabricSpacing.progressBarHeight

    var body: some View {
        HStack(spacing: FabricSpacing.sm) {
            if let label {
                Text(label)
                    .fabricTypography(.caption)
                    .foregroundStyle(FabricColors.inkSecondary)
            }

            // Track — simple rounded container with overflow clip
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Background — neutral connector tone
                    RoundedRectangle(cornerRadius: barHeight / 2)
                        .fill(FabricColors.connector.opacity(0.5))

                    // Fill — solid accent, clipped by track shape
                    RoundedRectangle(cornerRadius: barHeight / 2)
                        .fill(accent.foreground)
                        .frame(width: geo.size.width * clampedValue)
                }
            }
            .frame(height: barHeight)

            if showPercentage {
                Text("\(Int(clampedValue * 100))%")
                    .fabricTypography(.caption)
                    .foregroundStyle(FabricColors.inkTertiary)
                    .frame(minWidth: 32, alignment: .trailing)
            }
        }
        .opacity(isEnabled ? 1.0 : 0.5)
        .animation(
            reduceMotion ? nil : FabricAnimation.soft,
            value: clampedValue
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label ?? "Progress")
        .accessibilityValue("\(Int(clampedValue * 100)) percent")
    }
}

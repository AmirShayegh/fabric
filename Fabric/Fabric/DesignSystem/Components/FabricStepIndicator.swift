import SwiftUI

struct FabricStepIndicator: View {

    let steps: [String]
    let currentStep: Int

    init(steps: [String], currentStep: Int) {
        self.steps = steps
        self.currentStep = currentStep
    }

    var body: some View {
        if steps.isEmpty {
            Color.clear
                .frame(width: 0, height: 0)
                .accessibilityLabel("No steps")
        } else {
            FabricStepIndicatorBody(steps: steps, currentStep: currentStep)
        }
    }
}

// MARK: - Body View

private struct FabricStepIndicatorBody: View {

    let steps: [String]
    let currentStep: Int

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.isEnabled) private var isEnabled

    private var clampedStep: Int { max(0, min(currentStep, steps.count - 1)) }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                if index > 0 {
                    connectorLine(beforeIndex: index)
                        .frame(maxWidth: .infinity)
                }

                VStack(spacing: FabricSpacing.xs) {
                    stepCircle(at: index)
                    Text(step)
                        .fabricTypography(.caption)
                        .foregroundStyle(stepLabelColor(at: index))
                        .lineLimit(1)
                }
            }
        }
        .opacity(isEnabled ? 1.0 : 0.5)
        .animation(
            reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.65),
            value: clampedStep
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Progress")
        .accessibilityValue("Step \(clampedStep + 1) of \(steps.count): \(steps[clampedStep])")
    }

    // MARK: - Step Circle

    @ViewBuilder
    private func stepCircle(at index: Int) -> some View {
        let size = FabricSpacing.stepIndicatorSize

        ZStack {
            if index < clampedStep {
                // Completed — elevated, sage
                Circle()
                    .fill(FabricColors.sage)
                    .frame(width: size, height: size)
                    .overlay {
                        Image(systemName: "checkmark")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(FabricColors.onPrimary)
                    }
                    .overlay {
                        Circle()
                            .strokeBorder(
                                LinearGradient(
                                    colors: [FabricColors.highlight, Color.clear],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                lineWidth: 0.5
                            )
                    }
                    .shadow(color: FabricColors.shadowTight, radius: 0.5, x: 0, y: 0.5)
                    .shadow(color: FabricColors.shadow, radius: 3, x: 0, y: 2)
                    .shadow(color: FabricColors.sage.opacity(0.18), radius: 6)

            } else if index == clampedStep {
                // Current — elevated, indigo, subtle glow
                Circle()
                    .fill(FabricColors.indigo)
                    .frame(width: size, height: size)
                    .overlay {
                        Text("\(index + 1)")
                            .fabricTypography(.caption)
                            .foregroundStyle(FabricColors.onPrimary)
                    }
                    .overlay {
                        Circle()
                            .strokeBorder(
                                LinearGradient(
                                    colors: [FabricColors.highlight, Color.clear],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                lineWidth: 0.5
                            )
                    }
                    .shadow(color: FabricColors.shadowTight, radius: 1, x: 0, y: 1)
                    .shadow(color: FabricColors.shadow, radius: 5, x: 0, y: 3)
                    .shadow(color: FabricColors.indigo.opacity(0.20), radius: 8)

            } else {
                // Upcoming — recessed, parchment
                Circle()
                    .fill(FabricColors.parchment)
                    .frame(width: size, height: size)
                    .innerShadow(Circle(), color: FabricColors.innerShadow, radius: 2, spread: 2, y: 1)
                    .overlay {
                        Text("\(index + 1)")
                            .fabricTypography(.caption)
                            .foregroundStyle(FabricColors.inkTertiary)
                    }
            }
        }
    }

    // MARK: - Connector

    private func connectorLine(beforeIndex index: Int) -> some View {
        Capsule()
            .fill(index <= clampedStep ? FabricColors.sage : FabricColors.connector)
            .frame(height: FabricSpacing.connectorWidth)
            .padding(.horizontal, FabricSpacing.xs)
    }

    // MARK: - Label Color

    private func stepLabelColor(at index: Int) -> Color {
        if index < clampedStep { return FabricColors.inkSecondary }
        if index == clampedStep { return FabricColors.indigo }
        return FabricColors.inkTertiary
    }
}

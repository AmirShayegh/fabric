import SwiftUI

public struct FabricStepIndicator: View {

    public let steps: [String]
    public let currentStep: Int
    public var accent: FabricAccent
    public var onStepTapped: ((Int) -> Void)?

    public init(
        steps: [String],
        currentStep: Int,
        accent: FabricAccent = .indigo,
        onStepTapped: ((Int) -> Void)? = nil
    ) {
        self.steps = steps
        self.currentStep = currentStep
        self.accent = accent
        self.onStepTapped = onStepTapped
    }

    public var body: some View {
        if steps.isEmpty {
            Color.clear
                .frame(width: 0, height: 0)
                .accessibilityLabel("No steps")
        } else {
            FabricStepIndicatorBody(
                steps: steps,
                currentStep: currentStep,
                accent: accent,
                onStepTapped: onStepTapped
            )
        }
    }
}

// MARK: - Custom Alignment (connector center ↔ node center)

extension VerticalAlignment {
    fileprivate struct NodeCenter: AlignmentID {
        static func defaultValue(in context: ViewDimensions) -> CGFloat {
            context[VerticalAlignment.center]
        }
    }
    fileprivate static let nodeCenter = VerticalAlignment(NodeCenter.self)
}

// MARK: - Body View

private struct FabricStepIndicatorBody: View {

    let steps: [String]
    let currentStep: Int
    let accent: FabricAccent
    let onStepTapped: ((Int) -> Void)?

    @State private var hoveredIndex: Int? = nil
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.isEnabled) private var isEnabled

    private var clampedStep: Int { max(0, min(currentStep, steps.count - 1)) }

    private let nodeSize: CGFloat = 22
    private let nodeFrameSize: CGFloat = 28
    private let activeRingSize: CGFloat = 26
    private let borderWidth: CGFloat = 2.5
    private let connectorHeight: CGFloat = 3
    private var hasLabels: Bool { steps.contains(where: { !$0.isEmpty }) }

    // Interleaved HStack: connectors and step columns are siblings,
    // so connectors always fill exactly between adjacent nodes.
    var body: some View {
        HStack(alignment: .nodeCenter, spacing: 0) {
            ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                if index > 0 {
                    connector(beforeIndex: index)
                        .alignmentGuide(.nodeCenter) { d in d[VerticalAlignment.center] }
                        .frame(maxWidth: .infinity)
                }

                stepColumn(at: index, label: step)
            }
        }
        .opacity(isEnabled ? 1.0 : 0.5)
        .animation(
            reduceMotion ? nil : FabricAnimation.soft,
            value: clampedStep
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Progress: Step \(clampedStep + 1) of \(steps.count)")
    }

    // MARK: - Step Column

    @ViewBuilder
    private func stepColumn(at index: Int, label: String) -> some View {
        let content = VStack(spacing: FabricSpacing.xs) {
            stepNode(at: index)

            if hasLabels {
                Text(label)
                    .fabricTypography(.caption)
                    .foregroundStyle(stepLabelColor(at: index))
                    .lineLimit(1)
            }
        }

        if let onStepTapped {
            Button { onStepTapped(index) } label: { content }
                .buttonStyle(.plain)
                .onHover { hovering in
                    guard isEnabled else { return }
                    hoveredIndex = hovering ? index : nil
                }
                .alignmentGuide(.nodeCenter) { _ in nodeFrameSize / 2 }
                .stepAccessibility(index: index, label: label, clampedStep: clampedStep)
        } else {
            content
                .alignmentGuide(.nodeCenter) { _ in nodeFrameSize / 2 }
                .stepAccessibility(index: index, label: label, clampedStep: clampedStep)
        }
    }

    // MARK: - Connector

    private func connector(beforeIndex index: Int) -> some View {
        // Connects step (index-1) → step (index)
        let filled = index <= clampedStep
        let transition = index == clampedStep + 1

        return Capsule()
            .fill(
                transition
                    ? AnyShapeStyle(
                        LinearGradient(
                            colors: [accent.foreground, accent.foreground.opacity(0.25)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                      )
                    : filled
                        ? AnyShapeStyle(accent.foreground)
                        : AnyShapeStyle(FabricColors.connector)
            )
            .frame(height: connectorHeight)
            .padding(.horizontal, FabricSpacing.xs)
    }

    // MARK: - Step Node

    @ViewBuilder
    private func stepNode(at index: Int) -> some View {
        let isHovered = hoveredIndex == index && onStepTapped != nil

        if index < clampedStep {
            completedNode
                .scaleEffect(isHovered ? 1.15 : 1.0)
                .animation(reduceMotion ? nil : FabricAnimation.hover, value: isHovered)
        } else if index == clampedStep {
            activeNode(number: index + 1)
                .scaleEffect(isHovered ? 1.1 : 1.0)
                .animation(reduceMotion ? nil : FabricAnimation.hover, value: isHovered)
        } else {
            futureNode(number: index + 1)
                .scaleEffect(isHovered ? 1.15 : 1.0)
                .animation(reduceMotion ? nil : FabricAnimation.hover, value: isHovered)
        }
    }

    private var completedNode: some View {
        ZStack {
            Circle()
                .fill(accent.foreground)
                .frame(width: nodeSize, height: nodeSize)

            Image(systemName: "checkmark")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(FabricColors.onPrimary)

            Circle()
                .stroke(accent.foreground.opacity(0.15), lineWidth: 3)
                .frame(width: nodeFrameSize, height: nodeFrameSize)
        }
        .frame(width: nodeFrameSize, height: nodeFrameSize)
    }

    private func activeNode(number: Int) -> some View {
        ZStack {
            if !reduceMotion {
                PulseRing(accent: accent, delay: 0)
                PulseRing(accent: accent, delay: FabricAnimation.pulseStagger)
            }

            Circle()
                .fill(accent.foreground.opacity(0.10))
                .frame(width: activeRingSize, height: activeRingSize)

            Circle()
                .strokeBorder(accent.foreground, lineWidth: borderWidth)
                .frame(width: activeRingSize, height: activeRingSize)

            Text("\(number)")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(accent.foreground)
        }
        .frame(width: nodeFrameSize, height: nodeFrameSize)
    }

    private func futureNode(number: Int) -> some View {
        ZStack {
            Circle()
                .strokeBorder(FabricColors.connector, lineWidth: borderWidth)
                .frame(width: nodeSize, height: nodeSize)

            Text("\(number)")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(FabricColors.inkTertiary)
        }
        .opacity(0.7)
        .frame(width: nodeFrameSize, height: nodeFrameSize)
    }

    // MARK: - Label Color

    private func stepLabelColor(at index: Int) -> Color {
        if index < clampedStep { FabricColors.inkSecondary }
        else if index == clampedStep { accent.foreground }
        else { FabricColors.inkTertiary }
    }
}

// MARK: - Pulse Ring Animation

private struct PulseRing: View {
    let accent: FabricAccent
    let delay: Double

    @State private var isAnimating = false

    var body: some View {
        Circle()
            .stroke(accent.foreground, lineWidth: 1.5)
            .frame(width: 26, height: 26)
            .scaleEffect(isAnimating ? 1.8 : 0.9)
            .opacity(isAnimating ? 0 : 0.5)
            .onAppear {
                withAnimation(
                    .easeOut(duration: FabricAnimation.pulseDuration)
                    .repeatForever(autoreverses: false)
                    .delay(delay)
                ) {
                    isAnimating = true
                }
            }
            .accessibilityHidden(true)
    }
}

// MARK: - Step Accessibility Modifier

private extension View {
    func stepAccessibility(index: Int, label: String, clampedStep: Int) -> some View {
        self
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Step \(index + 1): \(label)")
            .accessibilityValue(
                index < clampedStep ? "Completed"
                    : index == clampedStep ? "Current"
                    : "Upcoming"
            )
    }
}

import SwiftUI

public struct FabricProgressRing<Label: View>: View {

    public let value: Double
    public let lineWidth: CGFloat
    public let accent: FabricAccent
    public let accessibilityLabel: String
    @ViewBuilder public let label: Label

    public init(
        value: Double,
        lineWidth: CGFloat = 6,
        accent: FabricAccent = .indigo,
        accessibilityLabel: String = "Progress",
        @ViewBuilder label: () -> Label
    ) {
        self.value = value
        self.lineWidth = lineWidth
        self.accent = accent
        self.accessibilityLabel = accessibilityLabel
        self.label = label()
    }

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.isEnabled) private var isEnabled

    private var clampedValue: Double { value.isFinite ? max(0, min(value, 1)) : 0 }

    public var body: some View {
        ZStack {
            // Track — neutral ring
            Circle()
                .stroke(FabricColors.connector, lineWidth: lineWidth)

            // Fill arc — colored progress
            Circle()
                .trim(from: 0, to: clampedValue)
                .stroke(
                    accent.foreground,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            // Center content
            label
        }
        .opacity(isEnabled ? 1.0 : 0.5)
        .animation(
            reduceMotion ? nil : FabricAnimation.soft,
            value: clampedValue
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityValue("\(Int(clampedValue * 100)) percent")
    }
}

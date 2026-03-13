import SwiftUI

struct FabricProgressRing<Label: View>: View {

    let value: Double
    let lineWidth: CGFloat
    let accent: FabricAccent
    @ViewBuilder let label: Label

    init(
        value: Double,
        lineWidth: CGFloat = 6,
        accent: FabricAccent = .indigo,
        @ViewBuilder label: () -> Label
    ) {
        self.value = value
        self.lineWidth = lineWidth
        self.accent = accent
        self.label = label()
    }

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.isEnabled) private var isEnabled

    private var clampedValue: Double { value.isFinite ? max(0, min(value, 1)) : 0 }

    var body: some View {
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
        .accessibilityLabel("Progress")
        .accessibilityValue("\(Int(clampedValue * 100)) percent")
    }
}

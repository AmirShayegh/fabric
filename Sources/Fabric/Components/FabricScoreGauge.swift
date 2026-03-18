import SwiftUI

public struct FabricScoreGauge<Label: View>: View {

    public struct Threshold {
        public let upTo: Double
        public let accent: FabricAccent

        public init(upTo: Double, accent: FabricAccent) {
            self.upTo = upTo
            self.accent = accent
        }
    }

    public let value: Double
    public let thresholds: [Threshold]
    public let lineWidth: Double
    public let accessibilityLabel: String
    @ViewBuilder public let label: Label

    public static var defaultThresholds: [Threshold] {
        [
            Threshold(upTo: 0.4, accent: .madder),
            Threshold(upTo: 0.7, accent: .ochre),
            Threshold(upTo: 1.0, accent: .sage),
        ]
    }

    public init(
        value: Double,
        thresholds: [Threshold]? = nil,
        lineWidth: Double = 8,
        accessibilityLabel: String = "Score",
        @ViewBuilder label: () -> Label
    ) {
        self.value = value
        self.thresholds = (thresholds ?? Self.defaultThresholds).sorted { $0.upTo < $1.upTo }
        self.lineWidth = lineWidth
        self.accessibilityLabel = accessibilityLabel
        self.label = label()
    }

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.isEnabled) private var isEnabled

    private var clampedValue: Double { value.isFinite ? max(0, min(value, 1)) : 0 }

    private var currentAccent: FabricAccent {
        thresholds.first { clampedValue <= $0.upTo }?.accent
            ?? thresholds.last?.accent
            ?? .indigo
    }

    public var body: some View {
        ZStack {
            // Track — neutral ring
            Circle()
                .stroke(FabricColors.connector, lineWidth: lineWidth)

            // Colored arc
            Circle()
                .trim(from: 0, to: clampedValue)
                .stroke(
                    currentAccent.foreground,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            // Center label
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

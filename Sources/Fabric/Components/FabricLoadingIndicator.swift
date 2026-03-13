import SwiftUI

public struct FabricLoadingIndicator: View {

    public enum Style { case dots, ring }

    public let style: Style
    public let accent: FabricAccent
    public let label: String?

    public init(
        _ style: Style = .dots,
        accent: FabricAccent = .indigo,
        label: String? = nil
    ) {
        self.style = style
        self.accent = accent
        self.label = label
    }

    public var body: some View {
        FabricLoadingIndicatorBody(style: style, accent: accent, label: label)
    }
}

// MARK: - Body View (owns animation state)

private struct FabricLoadingIndicatorBody: View {

    let style: FabricLoadingIndicator.Style
    let accent: FabricAccent
    let label: String?

    @State private var isAnimating = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: FabricSpacing.sm) {
            Group {
                switch style {
                case .dots: dotsView
                case .ring: ringView
                }
            }

            if let label {
                Text(label)
                    .fabricCaption()
            }
        }
        .onAppear { isAnimating = true }
        .onDisappear { isAnimating = false }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label ?? "Loading")
        .accessibilityAddTraits(.updatesFrequently)
    }

    // MARK: - Dots

    @ViewBuilder
    private var dotsView: some View {
        let dotSize: CGFloat = 10

        if isAnimating && !reduceMotion {
            PhaseAnimator([0, 1, 2]) { phase in
                HStack(spacing: FabricSpacing.sm) {
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .fill(accent.foreground)
                            .frame(width: dotSize, height: dotSize)
                            .scaleEffect(index == phase ? 1.0 : 0.6)
                            .shadow(
                                color: FabricColors.shadowTight,
                                radius: 0.3, x: 0, y: 0.3
                            )
                    }
                }
            } animation: { _ in
                .easeInOut(duration: FabricAnimation.phased)
            }
        } else {
            HStack(spacing: FabricSpacing.sm) {
                ForEach(0..<3, id: \.self) { _ in
                    Circle()
                        .fill(accent.foreground)
                        .frame(width: dotSize, height: dotSize)
                        .shadow(
                            color: FabricColors.shadowTight,
                            radius: 0.3, x: 0, y: 0.3
                        )
                }
            }
        }
    }

    // MARK: - Ring

    @ViewBuilder
    private var ringView: some View {
        let ringSize: CGFloat = 32
        let strokeWidth: CGFloat = 3

        ZStack {
            Circle()
                .stroke(FabricColors.connector, lineWidth: strokeWidth)

            if isAnimating && !reduceMotion {
                TimelineView(.animation) { timeline in
                    let elapsed = timeline.date.timeIntervalSinceReferenceDate
                    let angle = Angle.degrees(elapsed.truncatingRemainder(dividingBy: FabricAnimation.spinPeriod) / FabricAnimation.spinPeriod * 360)

                    Circle()
                        .trim(from: 0, to: FabricAnimation.loadingRingArc)
                        .stroke(
                            accent.foreground,
                            style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round)
                        )
                        .rotationEffect(angle)
                }
            } else {
                Circle()
                    .trim(from: 0, to: FabricAnimation.loadingRingArc)
                    .stroke(
                        accent.foreground,
                        style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
            }
        }
        .frame(width: ringSize, height: ringSize)
    }
}

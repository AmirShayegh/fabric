import SwiftUI

public struct FabricPill: View {

    public let text: String
    public let accent: FabricAccent?
    private let progress: Double?

    @Environment(\.isEnabled) private var isEnabled

    public init(_ text: String, accent: FabricAccent? = nil, progress: Double? = nil) {
        self.text = text
        self.accent = accent
        self.progress = progress
    }

    public var body: some View {
        Group {
            if let progress {
                VStack(spacing: 0) {
                    textContent
                        .padding(.top, 3)
                        .padding(.bottom, 1)
                    FabricMicroProgress(
                        value: progress,
                        accent: accent ?? .editorialThread
                    )
                    .padding(.horizontal, FabricSpacing.sm)
                    .padding(.bottom, 3)
                }
            } else {
                textContent
            }
        }
        .frame(height: FabricSpacing.pillHeight)
        .background {
            Capsule().fill(accent?.fill ?? FabricColors.badgeFill)
        }
        .clipShape(Capsule())
        .overlay {
            Capsule().strokeBorder(
                LinearGradient(
                    colors: [FabricColors.highlight, Color.clear],
                    startPoint: .top,
                    endPoint: .bottom
                ),
                lineWidth: 0.5
            )
        }
        .fabricShadow(.low, ambientColor: .clear)
        .opacity(isEnabled ? 1.0 : 0.5)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(text)
        .accessibilityValue(progressAccessibilityValue)
    }

    private var textContent: some View {
        Text(text)
            .fabricTypography(.caption)
            .foregroundStyle(accent?.foreground ?? FabricColors.inkSecondary)
            .lineLimit(1)
            .minimumScaleFactor(0.75)
            .padding(.horizontal, FabricSpacing.sm)
    }

    private var progressAccessibilityValue: String {
        guard let progress, progress.isFinite else { return "" }
        return "\(Int(min(max(progress, 0), 1) * 100)) percent"
    }
}

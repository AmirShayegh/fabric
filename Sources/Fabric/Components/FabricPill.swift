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

    private var clampedProgress: Double {
        guard let progress, progress.isFinite else { return 0 }
        return min(max(progress, 0), 1)
    }

    public var body: some View {
        textContent
            .frame(height: FabricSpacing.pillHeight)
            .background {
                if progress != nil {
                    progressBackground
                } else {
                    Capsule().fill(accent?.fill ?? FabricColors.badgeFill)
                }
            }
            .clipShape(Capsule())
            .overlay {
                if progress != nil {
                    Capsule().strokeBorder(
                        (accent?.foreground ?? FabricColors.inkTertiary).opacity(0.35),
                        lineWidth: 1
                    )
                } else {
                    Capsule().strokeBorder(
                        LinearGradient(
                            colors: [FabricColors.highlight, Color.clear],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 0.5
                    )
                }
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

    private var progressBackground: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(accent?.fill.opacity(0.3) ?? FabricColors.badgeFill.opacity(0.3))
                Capsule()
                    .fill(accent?.fill ?? FabricColors.badgeFill)
                    .frame(width: max(geo.size.height, geo.size.width * clampedProgress))
            }
        }
    }

    private var progressAccessibilityValue: String {
        guard let progress, progress.isFinite else { return "" }
        return "\(Int(min(max(progress, 0), 1) * 100)) percent"
    }
}

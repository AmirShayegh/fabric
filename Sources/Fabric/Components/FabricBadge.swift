import SwiftUI

public struct FabricBadge: View {

    public let text: String
    public let accent: FabricAccent?
    /// Optional SF Symbol rendered as a leading glyph in front of `text`.
    /// Inherits the badge's foreground color so it stays hue-consistent with
    /// the label. Use for brand-consistent state indicators (e.g. a "Complete"
    /// badge can render a `checkmark` glyph while keeping the same accent as
    /// its in-progress sibling — differentiation by iconography rather than
    /// color change).
    public let icon: String?

    @Environment(\.isEnabled) private var isEnabled

    public init(_ text: String, accent: FabricAccent? = nil, icon: String? = nil) {
        self.text = text
        self.accent = accent
        self.icon = icon
    }

    public var body: some View {
        HStack(spacing: 4) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .semibold))
                    .accessibilityHidden(true)
            }
            Text(text)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .fabricTypography(.caption)
        .foregroundStyle(accent?.foreground ?? FabricColors.inkSecondary)
        .padding(.horizontal, FabricSpacing.sm)
        .frame(height: FabricSpacing.badgeHeight)
        .background {
            Capsule()
                .fill(accent?.fill ?? FabricColors.badgeFill)
        }
        .clipShape(Capsule())
        .opacity(isEnabled ? 1.0 : 0.5)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(text)
    }
}

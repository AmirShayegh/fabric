import SwiftUI

public struct FabricBadge: View {

    public let text: String
    public let accent: FabricAccent?

    @Environment(\.isEnabled) private var isEnabled

    public init(_ text: String, accent: FabricAccent? = nil) {
        self.text = text
        self.accent = accent
    }

    public var body: some View {
        Text(text)
            .fabricTypography(.caption)
            .foregroundStyle(accent?.foreground ?? FabricColors.inkSecondary)
            .lineLimit(1)
            .minimumScaleFactor(0.75)
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

import SwiftUI

struct FabricBadge: View {

    let text: String
    let accent: FabricAccent?

    @Environment(\.isEnabled) private var isEnabled

    init(_ text: String, accent: FabricAccent? = nil) {
        self.text = text
        self.accent = accent
    }

    var body: some View {
        Text(text)
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

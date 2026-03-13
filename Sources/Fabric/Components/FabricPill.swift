import SwiftUI

public struct FabricPill: View {

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
            .padding(.horizontal, FabricSpacing.sm)
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
            .shadow(color: FabricColors.shadowTight, radius: 0.5, x: 0, y: 0.5)
            .opacity(isEnabled ? 1.0 : 0.5)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(text)
    }
}

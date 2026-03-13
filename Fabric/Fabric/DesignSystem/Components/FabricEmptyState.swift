import SwiftUI

struct FabricEmptyState: View {

    struct Action {
        let title: String
        let handler: () -> Void
    }

    let systemImage: String
    let title: String
    let subtitle: String?
    let action: Action?

    @State private var appeared = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(systemImage: String, title: String, subtitle: String? = nil, action: Action? = nil) {
        self.systemImage = systemImage
        self.title = title
        self.subtitle = subtitle
        self.action = action
    }

    var body: some View {
        VStack(spacing: FabricSpacing.md) {
            Image(systemName: systemImage)
                .font(.system(size: 36, weight: .light))
                .foregroundStyle(FabricColors.inkTertiary)

            Text(title)
                .fabricTypography(.heading)
                .foregroundStyle(FabricColors.inkSecondary)
                .multilineTextAlignment(.center)

            if let subtitle {
                Text(subtitle)
                    .fabricTypography(.body)
                    .foregroundStyle(FabricColors.inkTertiary)
                    .multilineTextAlignment(.center)
            }

            if let action {
                Button(action.title) { action.handler() }
                    .buttonStyle(.fabricGhost)
                    .padding(.top, FabricSpacing.xs)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(FabricSpacing.xxl)
        .opacity(appeared ? 1 : 0)
        .onAppear {
            if reduceMotion {
                appeared = true
            } else {
                withAnimation(.easeOut(duration: FabricAnimation.smooth)) {
                    appeared = true
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
    }

    private var accessibilityText: String {
        var parts = [title]
        if let subtitle { parts.append(subtitle) }
        if let action { parts.append(action.title) }
        return parts.joined(separator: ". ")
    }
}

import SwiftUI

public struct FabricFilterPill: View {

    public let label: String
    public let icon: String?
    public let accent: FabricAccent
    public let isSelected: Bool
    public let onToggle: () -> Void

    public init(
        _ label: String,
        icon: String? = nil,
        accent: FabricAccent = .indigo,
        isSelected: Bool,
        onToggle: @escaping () -> Void
    ) {
        self.label = label
        self.icon = icon
        self.accent = accent
        self.isSelected = isSelected
        self.onToggle = onToggle
    }

    public var body: some View {
        FabricFilterPillBody(
            label: label,
            icon: icon,
            accent: accent,
            isSelected: isSelected,
            onToggle: onToggle
        )
    }
}

// MARK: - Body View (owns @State for hover tracking)

private struct FabricFilterPillBody: View {

    let label: String
    let icon: String?
    let accent: FabricAccent
    let isSelected: Bool
    let onToggle: () -> Void

    @State private var isHovered = false
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button {
            onToggle()
        } label: {
            HStack(spacing: FabricSpacing.xs) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 12, weight: .medium))
                }
                Text(label)
                    .fabricTypography(.caption)
                    .lineLimit(1)
            }
            .foregroundStyle(isSelected ? FabricColors.onPrimary : FabricColors.inkSecondary)
            .padding(.horizontal, FabricSpacing.sm)
            .frame(height: FabricSpacing.chipHeight)
            .background {
                if isSelected {
                    Capsule().fill(accent.foreground)
                } else {
                    Capsule().fill(isHovered ? FabricColors.burlap.opacity(0.08) : FabricColors.badgeFill)
                }
            }
            .overlay {
                if isSelected {
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
            .clipShape(Capsule())
            .fabricShadow(isSelected ? .low : .micro,
                          tightColor: isSelected ? FabricColors.shadowTight : .clear,
                          ambientColor: isSelected ? FabricColors.shadow : .clear)
        }
        .buttonStyle(.plain)
        .frame(minHeight: 44)
        .contentShape(Capsule())
        .onHover { hovering in
            guard isEnabled else { return }
            isHovered = hovering
        }
        .onChange(of: isEnabled) {
            if !isEnabled { isHovered = false }
        }
        .opacity(isEnabled ? 1.0 : 0.5)
        .animation(reduceMotion ? nil : FabricAnimation.press, value: isSelected)
        .animation(reduceMotion ? nil : FabricAnimation.hover, value: isHovered)
        .accessibilityLabel(label)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityHint(isSelected ? "Deselect" : "Select")
    }
}

import SwiftUI

/// A label-value settings row with optional icon, trailing accessory, and tap action.
///
/// Use in settings panels, inspector views, or any configuration surface where
/// information is presented as labeled rows.
///
/// ```swift
/// VStack(spacing: 0) {
///     FabricSettingsRow("Status", value: "Connected", icon: "wifi", accent: .sage)
///     FabricSettingsRow("Transport", value: "LAN")
///     FabricSettingsRow("Advanced Settings", icon: "gearshape", disclosure: true) {
///         showAdvanced()
///     }
/// }
/// ```
public struct FabricSettingsRow: View {

    public let label: String
    public let value: String?
    public let icon: String?
    public let accent: FabricAccent?
    public let disclosure: Bool
    public let onTap: (() -> Void)?

    /// Trailing view slot for custom accessories (badge, toggle, pill, etc.).
    private let trailing: AnyView?

    public init(
        _ label: String,
        value: String? = nil,
        icon: String? = nil,
        accent: FabricAccent? = nil,
        disclosure: Bool = false,
        onTap: (() -> Void)? = nil
    ) {
        self.label = label
        self.value = value
        self.icon = icon
        self.accent = accent
        self.disclosure = disclosure
        self.onTap = onTap
        self.trailing = nil
    }

    /// Create a settings row with a custom trailing accessory view.
    ///
    /// ```swift
    /// FabricSettingsRow("Project", icon: "folder") {
    ///     selectProject()
    /// } trailing: {
    ///     FabricBadge("12 tickets", accent: .indigo)
    /// }
    /// ```
    public init<Trailing: View>(
        _ label: String,
        icon: String? = nil,
        accent: FabricAccent? = nil,
        disclosure: Bool = false,
        onTap: (() -> Void)? = nil,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.label = label
        self.value = nil
        self.icon = icon
        self.accent = accent
        self.disclosure = disclosure
        self.onTap = onTap
        self.trailing = AnyView(trailing())
    }

    public var body: some View {
        FabricSettingsRowBody(
            label: label,
            value: value,
            icon: icon,
            accent: accent,
            disclosure: disclosure,
            onTap: onTap,
            trailing: trailing
        )
    }
}

// MARK: - Body (owns hover state)

private struct FabricSettingsRowBody: View {

    let label: String
    let value: String?
    let icon: String?
    let accent: FabricAccent?
    let disclosure: Bool
    let onTap: (() -> Void)?
    let trailing: AnyView?

    @State private var isHovered = false
    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        let content = HStack(spacing: FabricSpacing.sm) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(accent?.foreground ?? FabricColors.inkSecondary)
                    .frame(width: 24, alignment: .center)
            }

            Text(label)
                .fabricTypography(.label)
                .fabricInk(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .layoutPriority(-1)

            if let trailing {
                trailing
                    .fixedSize()
            } else if let value {
                Text(value)
                    .fabricTypography(.caption)
                    .foregroundStyle(accent?.foreground ?? FabricColors.inkSecondary)
                    .lineLimit(1)
            }

            if disclosure || onTap != nil {
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(FabricColors.inkTertiary)
            }
        }
        .padding(.vertical, FabricSpacing.sm)
        .padding(.horizontal, FabricSpacing.md)
        .background(
            FabricSpacing.shape(radius: FabricSpacing.radiusXs)
                .fill(isHovered ? FabricColors.inkTertiary.opacity(0.08) : .clear)
        )
        .opacity(isEnabled ? 1.0 : 0.5)

        if let onTap {
            Button(action: onTap) {
                content
            }
            .buttonStyle(.plain)
            .onHover { hovering in
                guard isEnabled else { return }
                isHovered = hovering
            }
            .accessibilityLabel(accessibilityText)
        } else {
            content
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(accessibilityText)
        }
    }

    private var accessibilityText: String {
        if let value {
            "\(label), \(value)"
        } else {
            label
        }
    }
}

import SwiftUI

/// A tappable row showing a linked/related item with a colored dot, optional ID, title, and chevron.
///
/// Use in inspector panels and detail views to display related tickets, issues, or linked items.
/// ```swift
/// FabricLinkedItemRow("IPC Bridge implementation", id: "T-061", accent: .indigo) {
///     navigateTo(ticket)
/// }
/// ```
public struct FabricLinkedItemRow: View {

    public let title: String
    public let id: String?
    public let accent: FabricAccent
    public let onTap: (() -> Void)?

    public init(
        _ title: String,
        id: String? = nil,
        accent: FabricAccent = .indigo,
        onTap: (() -> Void)? = nil
    ) {
        self.title = title
        self.id = id
        self.accent = accent
        self.onTap = onTap
    }

    public var body: some View {
        FabricLinkedItemRowBody(
            title: title,
            id: id,
            accent: accent,
            onTap: onTap
        )
    }
}

// MARK: - Body (owns hover state)

private struct FabricLinkedItemRowBody: View {

    let title: String
    let id: String?
    let accent: FabricAccent
    let onTap: (() -> Void)?

    @State private var isHovered = false

    var body: some View {
        Button {
            onTap?()
        } label: {
            HStack(spacing: FabricSpacing.sm) {
                Circle()
                    .fill(accent.foreground)
                    .frame(width: 6, height: 6)

                if let id {
                    Text(id)
                        .fabricTypography(.monoSmall)
                        .foregroundStyle(FabricColors.inkTertiary)
                        .lineLimit(1)
                        .fixedSize()
                }

                Text(title)
                    .fabricTypography(.caption)
                    .foregroundStyle(FabricColors.inkSecondary)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if onTap != nil {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(FabricColors.inkTertiary)
                }
            }
            .padding(.vertical, FabricSpacing.xs)
            .padding(.horizontal, FabricSpacing.sm)
            .background(
                FabricSpacing.shape(radius: FabricSpacing.radiusXs)
                    .fill(isHovered ? FabricColors.inkTertiary.opacity(0.08) : .clear)
            )
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .accessibilityLabel(accessibilityText)
    }

    private var accessibilityText: String {
        if let id {
            "\(id), \(title)"
        } else {
            title
        }
    }
}

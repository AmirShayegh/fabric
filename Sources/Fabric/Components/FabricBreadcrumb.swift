import SwiftUI

public struct FabricBreadcrumb: View {

    public struct Item: Identifiable {
        public let id: String
        public let label: String

        public init(id: String = UUID().uuidString, label: String) {
            self.id = id
            self.label = label
        }
    }

    public let items: [Item]
    public let onSelect: (Item) -> Void

    public init(
        items: [Item],
        onSelect: @escaping (Item) -> Void
    ) {
        self.items = items
        self.onSelect = onSelect
    }

    public var body: some View {
        if items.isEmpty {
            EmptyView()
        } else {
            FabricBreadcrumbBody(items: items, onSelect: onSelect)
        }
    }
}

// MARK: - Body View (owns @State for hover tracking)

private struct FabricBreadcrumbBody: View {

    let items: [FabricBreadcrumb.Item]
    let onSelect: (FabricBreadcrumb.Item) -> Void

    @State private var hoveredItemID: String?
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: FabricSpacing.xs) {
                    ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                        if index > 0 {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(FabricColors.inkTertiary)
                                .accessibilityHidden(true)
                        }

                        let isCurrent = index == items.count - 1

                        if isCurrent {
                            Text(item.label)
                                .fabricTypography(.caption)
                                .foregroundStyle(FabricColors.inkPrimary)
                                .fontWeight(.medium)
                                .lineLimit(1)
                                .frame(minHeight: 44)
                                .contentShape(Rectangle())
                                .accessibilityAddTraits(.isSelected)
                                .id(item.id)
                        } else {
                            Button {
                                onSelect(item)
                            } label: {
                                Text(item.label)
                                    .fabricTypography(.caption)
                                    .foregroundStyle(
                                        hoveredItemID == item.id
                                            ? FabricColors.inkPrimary
                                            : FabricColors.inkSecondary
                                    )
                                    .underline(hoveredItemID == item.id)
                                    .lineLimit(1)
                                    .frame(minHeight: 44)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .onHover { hovering in
                                guard isEnabled else { return }
                                hoveredItemID = hovering ? item.id : nil
                            }
                            .accessibilityLabel(item.label)
                            .id(item.id)
                        }
                    }
                }
                .padding(.horizontal, FabricSpacing.xs)
            }
            .onChange(of: items.last?.id) {
                if let lastID = items.last?.id {
                    withAnimation(reduceMotion ? nil : FabricAnimation.hover) {
                        proxy.scrollTo(lastID, anchor: .trailing)
                    }
                }
            }
        }
        .onChange(of: isEnabled) {
            if !isEnabled { hoveredItemID = nil }
        }
        .opacity(isEnabled ? 1.0 : 0.5)
        .animation(reduceMotion ? nil : FabricAnimation.hover, value: hoveredItemID)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Breadcrumb navigation")
    }
}

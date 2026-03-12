import SwiftUI

// MARK: - Data Model

struct FabricTimelineItem: Identifiable {

    let id: String
    let timestamp: String
    let title: String
    let description: String?
    let style: Style

    enum Style {
        case event
        case milestone(accent: FabricAccent)
    }

    init(
        id: String = UUID().uuidString,
        timestamp: String,
        title: String,
        description: String? = nil,
        style: Style = .event
    ) {
        self.id = id
        self.timestamp = timestamp
        self.title = title
        self.description = description
        self.style = style
    }
}

// MARK: - Timeline Container

struct FabricTimeline: View {

    let items: [FabricTimelineItem]

    init(items: [FabricTimelineItem]) {
        self.items = items
    }

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                switch item.style {
                case .event:
                    FabricTimelineEventRow(
                        item: item,
                        isFirst: index == 0,
                        isLast: index == items.count - 1
                    )
                case .milestone(let accent):
                    FabricTimelineMilestoneRow(
                        item: item,
                        accent: accent,
                        isFirst: index == 0,
                        isLast: index == items.count - 1
                    )
                }
            }
        }
        .accessibilityElement(children: .contain)
    }
}

// MARK: - Metrics

private enum TimelineMetrics {
    static let connectorColumnWidth: CGFloat = 40
}

// MARK: - Event Row

private struct FabricTimelineEventRow: View {

    let item: FabricTimelineItem
    let isFirst: Bool
    let isLast: Bool

    var body: some View {
        HStack(alignment: .top, spacing: FabricSpacing.md) {
            // Connector column
            connectorColumn(
                isFirst: isFirst,
                isLast: isLast
            ) {
                // Event dot — recessed
                Circle()
                    .fill(FabricColors.burlap)
                    .frame(
                        width: FabricSpacing.timelineDotSize,
                        height: FabricSpacing.timelineDotSize
                    )
                    .innerShadow(
                        Circle(),
                        color: FabricColors.innerShadow,
                        radius: 1.5, spread: 1.5, y: 0.5
                    )
            }

            // Content
            VStack(alignment: .leading, spacing: FabricSpacing.xs) {
                Text(item.timestamp)
                    .fabricTypography(.caption)
                    .foregroundStyle(FabricColors.inkTertiary)

                Text(item.title)
                    .fabricTypography(.label)
                    .fabricInk(.primary)

                if let description = item.description {
                    Text(description)
                        .fabricTypography(.body)
                        .foregroundStyle(FabricColors.inkSecondary)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.vertical, FabricSpacing.sm)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(eventAccessibilityLabel)
    }

    private var eventAccessibilityLabel: String {
        var parts = [item.timestamp, item.title]
        if let desc = item.description { parts.append(desc) }
        return parts.joined(separator: ". ")
    }
}

// MARK: - Milestone Row

private struct FabricTimelineMilestoneRow: View {

    let item: FabricTimelineItem
    let accent: FabricAccent
    let isFirst: Bool
    let isLast: Bool

    var body: some View {
        HStack(alignment: .top, spacing: FabricSpacing.md) {
            // Connector column
            connectorColumn(
                isFirst: isFirst,
                isLast: isLast
            ) {
                // Milestone dot — elevated
                Circle()
                    .fill(accent.foreground)
                    .frame(
                        width: FabricSpacing.timelineDotSizeLg,
                        height: FabricSpacing.timelineDotSizeLg
                    )
                    .overlay {
                        Circle()
                            .strokeBorder(
                                LinearGradient(
                                    colors: [FabricColors.highlight, Color.clear],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                lineWidth: 0.5
                            )
                    }
                    .shadow(color: FabricColors.shadowTight, radius: 0.5, x: 0, y: 0.5)
                    .shadow(color: FabricColors.shadow, radius: 4, x: 0, y: 2)
            }

            // Content
            VStack(alignment: .leading, spacing: FabricSpacing.xs) {
                Text(item.timestamp)
                    .fabricTypography(.caption)
                    .foregroundStyle(accent.foreground)

                Text(item.title)
                    .fabricHeading()

                if let description = item.description {
                    Text(description)
                        .fabricTypography(.body)
                        .foregroundStyle(FabricColors.inkSecondary)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.vertical, FabricSpacing.sm)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(milestoneAccessibilityLabel)
    }

    private var milestoneAccessibilityLabel: String {
        var parts = ["Milestone", item.timestamp, item.title]
        if let desc = item.description { parts.append(desc) }
        return parts.joined(separator: ". ")
    }
}

// MARK: - Shared Connector Column

@ViewBuilder
private func connectorColumn<Dot: View>(
    isFirst: Bool,
    isLast: Bool,
    @ViewBuilder dot: () -> Dot
) -> some View {
    // Color.clear stretches in HStack to match content column height.
    // The overlay VStack draws: top-segment → dot → bottom-segment.
    Color.clear
        .frame(width: TimelineMetrics.connectorColumnWidth)
        .accessibilityHidden(true)
        .overlay(alignment: .top) {
            VStack(spacing: 0) {
                // Top segment — height matches content's vertical padding
                Rectangle()
                    .fill(isFirst ? Color.clear : FabricColors.connector)
                    .frame(width: FabricSpacing.connectorWidth, height: FabricSpacing.sm)

                // Dot
                dot()

                // Bottom segment — fills remaining row height
                Rectangle()
                    .fill(isLast ? Color.clear : FabricColors.connector)
                    .frame(width: FabricSpacing.connectorWidth)
                    .frame(maxHeight: .infinity)
            }
        }
}

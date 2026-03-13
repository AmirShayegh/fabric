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
                FabricTimelineRow(
                    item: item,
                    isFirst: index == 0,
                    isLast: index == items.count - 1
                )
            }
        }
        .accessibilityElement(children: .contain)
    }
}

// MARK: - Timeline Row

private struct FabricTimelineRow: View {

    let item: FabricTimelineItem
    let isFirst: Bool
    let isLast: Bool

    private let railWidth: CGFloat = 40

    private var isMilestone: Bool {
        if case .milestone = item.style { true }
        else { false }
    }

    private var accent: FabricAccent? {
        if case .milestone(let a) = item.style { a }
        else { nil }
    }

    private var dotSize: CGFloat {
        isMilestone ? FabricSpacing.timelineDotSizeLg : FabricSpacing.timelineDotSize
    }

    var body: some View {
        HStack(alignment: .top, spacing: FabricSpacing.md) {
            railColumn
            contentView
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
    }

    // MARK: - Rail Column
    //
    // Uses VStack(spacing: 0) with top-segment / dot / elastic-bottom-segment.
    // The bottom segment's .frame(maxHeight: .infinity) guarantees the connector
    // line stretches to fill the full row height.

    private var railColumn: some View {
        Color.clear
            .frame(width: railWidth)
            .overlay(alignment: .top) {
                VStack(spacing: 0) {
                    // Top segment — fixed height matching content's vertical padding
                    Rectangle()
                        .fill(isFirst ? Color.clear : FabricColors.connector)
                        .frame(width: FabricSpacing.connectorWidth, height: FabricSpacing.sm)

                    // Dot
                    dotView

                    // Bottom segment — elastic, fills remaining row height
                    Rectangle()
                        .fill(isLast ? Color.clear : FabricColors.connector)
                        .frame(width: FabricSpacing.connectorWidth)
                        .frame(maxHeight: .infinity)
                }
            }
            .accessibilityHidden(true)
    }

    // MARK: - Dot

    @ViewBuilder
    private var dotView: some View {
        if let accent {
            // Milestone — elevated pebble
            Circle()
                .fill(accent.foreground)
                .frame(width: dotSize, height: dotSize)
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
        } else {
            // Event — recessed into fabric
            Circle()
                .fill(FabricColors.burlap)
                .frame(width: dotSize, height: dotSize)
                .innerShadow(
                    Circle(),
                    color: FabricColors.innerShadow,
                    radius: 1.5, spread: 1.5, y: 0.5
                )
        }
    }

    // MARK: - Content

    private var contentView: some View {
        VStack(alignment: .leading, spacing: FabricSpacing.xs) {
            Text(item.timestamp)
                .fabricTypography(.caption)
                .foregroundStyle(accent?.foreground ?? FabricColors.inkTertiary)

            Text(item.title)
                .fabricTypography(isMilestone ? .heading : .label)
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

    // MARK: - Accessibility

    private var accessibilityText: String {
        var parts = [String]()
        if isMilestone { parts.append("Milestone") }
        parts.append(item.timestamp)
        parts.append(item.title)
        if let desc = item.description { parts.append(desc) }
        return parts.joined(separator: ". ")
    }
}

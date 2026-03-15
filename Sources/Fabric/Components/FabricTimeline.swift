import SwiftUI

// MARK: - Data Model

public struct FabricTimelineItem: Identifiable {

    public let id: String
    public let timestamp: String
    public let title: String
    public let description: String?
    public let style: Style

    public enum Style {
        case event
        case milestone(accent: FabricAccent)
    }

    public init(
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

// MARK: - Custom Alignment (connector line ↔ dot center ↔ content center)

extension HorizontalAlignment {
    fileprivate struct DotCenter: AlignmentID {
        static func defaultValue(in context: ViewDimensions) -> CGFloat {
            context[HorizontalAlignment.center]
        }
    }
    fileprivate static let dotCenter = HorizontalAlignment(DotCenter.self)
}

// MARK: - Timeline Container

public struct FabricTimeline: View {

    public let items: [FabricTimelineItem]

    public init(items: [FabricTimelineItem]) {
        self.items = items
    }

    public var body: some View {
        VStack(alignment: .dotCenter, spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                FabricTimelineConnector(
                    item: item,
                    isFirst: index == 0
                )

                FabricTimelineContentBlock(item: item)
                    .alignmentGuide(.dotCenter) { d in d[HorizontalAlignment.center] }
            }
        }
        .accessibilityElement(children: .contain)
    }
}

// MARK: - Content Block

private struct FabricTimelineContentBlock: View {

    let item: FabricTimelineItem

    private var isMilestone: Bool {
        if case .milestone = item.style { true }
        else { false }
    }

    var body: some View {
        VStack(spacing: FabricSpacing.xs) {
            Text(item.title)
                .fabricTypography(isMilestone ? .heading : .label)
                .fabricInk(.primary)
                .multilineTextAlignment(.center)

            if let description = item.description {
                Text(description)
                    .fabricTypography(.body)
                    .foregroundStyle(FabricColors.inkSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
        .accessibilityAddTraits(isMilestone ? .isHeader : [])
    }

    private var accessibilityText: String {
        var parts = [String]()
        if isMilestone { parts.append("Milestone") }
        parts.append(item.timestamp)
        parts.append(item.title)
        if let desc = item.description { parts.append(desc) }
        return parts.joined(separator: ". ")
    }
}

// MARK: - Connector

private struct FabricTimelineConnector: View {

    let item: FabricTimelineItem
    let isFirst: Bool

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
        VStack(alignment: .dotCenter, spacing: 0) {
            if !isFirst {
                connectorLine
                    .alignmentGuide(.dotCenter) { d in d[HorizontalAlignment.center] }
            }

            HStack(spacing: FabricSpacing.sm) {
                dotView

                Text(item.timestamp)
                    .fabricTypography(.caption)
                    .foregroundStyle(accent?.foreground ?? FabricColors.inkTertiary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .help(item.timestamp)
            }
            .alignmentGuide(.dotCenter) { [dotSize] _ in dotSize / 2 }

            connectorLine
                .alignmentGuide(.dotCenter) { d in d[HorizontalAlignment.center] }
        }
        .padding(.vertical, FabricSpacing.sm)
        .accessibilityHidden(true)
    }

    // MARK: - Line Segment

    private var connectorLine: some View {
        Rectangle()
            .fill(FabricColors.connector)
            .frame(width: FabricSpacing.connectorWidth, height: FabricSpacing.lg)
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
                .fabricShadow(.low)
        } else {
            // Event — recessed into fabric
            Circle()
                .fill(FabricColors.burlap)
                .frame(width: dotSize, height: dotSize)
                .fabricInnerShadow(Circle(), .subtle)
        }
    }
}

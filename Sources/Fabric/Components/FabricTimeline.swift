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
    @Binding public var selection: String?
    public let accent: FabricAccent
    private let isInteractive: Bool

    /// Non-interactive timeline (backward compatible).
    public init(items: [FabricTimelineItem]) {
        self.items = items
        self._selection = .constant(nil)
        self.accent = .indigo
        self.isInteractive = false
    }

    /// Interactive timeline with selection support.
    public init(
        items: [FabricTimelineItem],
        selection: Binding<String?>,
        accent: FabricAccent = .indigo
    ) {
        self.items = items
        self._selection = selection
        self.accent = accent
        self.isInteractive = true
    }

    public var body: some View {
        FabricTimelineBody(
            items: items,
            selection: $selection,
            accent: accent,
            isInteractive: isInteractive
        )
    }
}

// MARK: - Body (owns @State for hover tracking)

private struct FabricTimelineBody: View {

    let items: [FabricTimelineItem]
    @Binding var selection: String?
    let accent: FabricAccent
    let isInteractive: Bool

    @State private var hoveredItemID: String? = nil
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.displayScale) private var displayScale

    var body: some View {
        VStack(alignment: .dotCenter, spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                itemRow(item: item, index: index)
            }
        }
        .focusable(isInteractive)
        .focusEffectDisabled()
        #if os(macOS)
        .onKeyPress(.upArrow) { selectAdjacentItem(offset: -1) }
        .onKeyPress(.downArrow) { selectAdjacentItem(offset: 1) }
        #endif
        .opacity(isEnabled ? 1.0 : 0.5)
        .onChange(of: isEnabled) {
            if !isEnabled { hoveredItemID = nil }
        }
        .animation(reduceMotion ? nil : FabricAnimation.hover, value: hoveredItemID)
        .animation(reduceMotion ? nil : FabricAnimation.press, value: selection)
        .accessibilityElement(children: .contain)
    }

    // MARK: - Item Row

    @ViewBuilder
    private func itemRow(item: FabricTimelineItem, index: Int) -> some View {
        let isSelected = selection == item.id
        let isHovered = hoveredItemID == item.id && !isSelected

        let content = VStack(spacing: 0) {
            FabricTimelineConnector(
                item: item,
                isFirst: index == 0,
                isSelected: isSelected
            )

            FabricTimelineContentBlock(
                item: item,
                isSelected: isSelected,
                isHovered: isHovered,
                accent: itemAccent(for: item),
                displayScale: displayScale
            )
            .alignmentGuide(.dotCenter) { d in d[HorizontalAlignment.center] }
        }

        if isInteractive {
            Button {
                guard isEnabled else { return }
                selection = isSelected ? nil : item.id
            } label: {
                content
            }
            .buttonStyle(.plain)
            .contentShape(Rectangle())
            .onHover { hovering in
                guard isEnabled else { return }
                hoveredItemID = hovering ? item.id : nil
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(accessibilityText(for: item))
            .accessibilityAddTraits(.isButton)
            .accessibilityAddTraits(isSelected ? .isSelected : [])
            .accessibilityHint(isSelected ? "Deselect" : "Select")
        } else {
            content
        }
    }

    // MARK: - Helpers

    private func itemAccent(for item: FabricTimelineItem) -> FabricAccent {
        if case .milestone(let a) = item.style { a }
        else { accent }
    }

    private func accessibilityText(for item: FabricTimelineItem) -> String {
        var parts = [String]()
        let isMilestone: Bool = if case .milestone = item.style { true } else { false }
        if isMilestone { parts.append("Milestone") }
        parts.append(item.timestamp)
        parts.append(item.title)
        if let desc = item.description { parts.append(desc) }
        return parts.joined(separator: ". ")
    }

    // MARK: - Keyboard Navigation

    #if os(macOS)
    private func selectAdjacentItem(offset: Int) -> KeyPress.Result {
        guard isEnabled, isInteractive else { return .ignored }
        guard let currentSelection = selection,
              let currentIndex = items.firstIndex(where: { $0.id == currentSelection }) else {
            if offset > 0, let first = items.first {
                selection = first.id
                return .handled
            } else if offset < 0, let last = items.last {
                selection = last.id
                return .handled
            }
            return .ignored
        }
        let newIndex = currentIndex + offset
        guard items.indices.contains(newIndex) else { return .ignored }
        selection = items[newIndex].id
        return .handled
    }
    #endif
}

// MARK: - Content Block

private struct FabricTimelineContentBlock: View {

    let item: FabricTimelineItem
    let isSelected: Bool
    let isHovered: Bool
    let accent: FabricAccent
    let displayScale: Double

    private var isMilestone: Bool {
        if case .milestone = item.style { true }
        else { false }
    }

    private var shape: RoundedRectangle {
        FabricSpacing.shape(radius: FabricSpacing.radiusSm)
    }

    var body: some View {
        VStack(spacing: FabricSpacing.xs) {
            Text(item.title)
                .fabricTypography(isMilestone ? .heading : .label)
                .fabricInk(.primary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            if let description = item.description {
                Text(description)
                    .fabricTypography(.body)
                    .foregroundStyle(FabricColors.inkSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, FabricSpacing.md)
        .padding(.vertical, FabricSpacing.sm)
        .frame(maxWidth: .infinity)
        .background { backgroundView }
        .clipShape(shape)
        .overlay {
            shape.strokeBorder(
                isSelected ? accent.foreground : Color.clear,
                lineWidth: 2
            )
        }
        .overlay {
            shape.strokeBorder(
                LinearGradient(
                    colors: isSelected
                        ? [FabricColors.highlight, Color.clear]
                        : [Color.clear, Color.clear],
                    startPoint: .top,
                    endPoint: .bottom
                ),
                lineWidth: 0.5
            )
        }
        .fabricShadow(
            .low,
            tightColor: isSelected ? FabricColors.shadowTight : .clear,
            ambientColor: isSelected ? FabricColors.shadow : .clear
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
        .accessibilityAddTraits(isMilestone ? .isHeader : [])
    }

    // MARK: - Background

    @ViewBuilder
    private var backgroundView: some View {
        if isSelected {
            ZStack {
                shape.fill(FabricColors.canvas)
                shape.foregroundStyle(
                    TextureGenerator.linenPaint(displayScale: displayScale, intensity: 0.025)
                )
            }
        } else if isHovered {
            shape.fill(FabricColors.burlap.opacity(0.08))
        }
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

// MARK: - Connector

private struct FabricTimelineConnector: View {

    let item: FabricTimelineItem
    let isFirst: Bool
    let isSelected: Bool

    private var isMilestone: Bool {
        if case .milestone = item.style { true }
        else { false }
    }

    private var accent: FabricAccent? {
        if case .milestone(let a) = item.style { a }
        else { nil }
    }

    private var dotSize: Double {
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
                    .foregroundStyle(timestampColor)
                    .fixedSize(horizontal: false, vertical: true)
                    .help(item.timestamp)
            }
            .alignmentGuide(.dotCenter) { [dotSize] _ in dotSize / 2 }

            connectorLine
                .alignmentGuide(.dotCenter) { d in d[HorizontalAlignment.center] }
        }
        .padding(.vertical, FabricSpacing.sm)
        .accessibilityHidden(true)
    }

    // MARK: - Timestamp Color

    private var timestampColor: Color {
        if let accent {
            accent.foreground
        } else if isSelected {
            FabricColors.inkPrimary
        } else {
            FabricColors.inkTertiary
        }
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
        } else if isSelected {
            // Event + selected — small pebble (elevated from fabric)
            Circle()
                .fill(FabricColors.burlap)
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
                .fabricShadow(.micro)
        } else {
            // Event — recessed into fabric
            Circle()
                .fill(FabricColors.burlap)
                .frame(width: dotSize, height: dotSize)
                .fabricInnerShadow(Circle(), .subtle)
        }
    }
}

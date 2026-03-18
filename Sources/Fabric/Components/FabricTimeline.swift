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

// MARK: - Custom Alignment (vertical mode: connector ↔ dot ↔ content)

extension HorizontalAlignment {
    fileprivate struct DotCenter: AlignmentID {
        static func defaultValue(in context: ViewDimensions) -> CGFloat {
            context[HorizontalAlignment.center]
        }
    }
    fileprivate static let dotCenter = HorizontalAlignment(DotCenter.self)
}

// MARK: - Custom Alignment (horizontal mode: nodes ↔ connectors)

extension VerticalAlignment {
    fileprivate struct DotCenterH: AlignmentID {
        static func defaultValue(in context: ViewDimensions) -> CGFloat {
            context[VerticalAlignment.center]
        }
    }
    fileprivate static let dotCenterH = VerticalAlignment(DotCenterH.self)
}

// MARK: - Timeline Container

public struct FabricTimeline: View {

    public enum Axis {
        case vertical
        case horizontal
    }

    public let items: [FabricTimelineItem]
    @Binding public var selection: String?
    public let accent: FabricAccent
    public let axis: Axis
    public let currentItemID: String?
    private let isInteractive: Bool

    /// Non-interactive timeline (backward compatible).
    public init(items: [FabricTimelineItem], axis: Axis = .vertical) {
        self.items = items
        self._selection = .constant(nil)
        self.accent = .indigo
        self.axis = axis
        self.currentItemID = nil
        self.isInteractive = false
    }

    /// Interactive timeline with selection support.
    public init(
        items: [FabricTimelineItem],
        selection: Binding<String?>,
        currentItemID: String? = nil,
        accent: FabricAccent = .indigo,
        axis: Axis = .vertical
    ) {
        self.items = items
        self._selection = selection
        self.accent = accent
        self.axis = axis
        self.currentItemID = currentItemID
        self.isInteractive = true
    }

    public var body: some View {
        FabricTimelineBody(
            items: items,
            selection: $selection,
            accent: accent,
            axis: axis,
            currentItemID: currentItemID,
            isInteractive: isInteractive
        )
    }
}

// MARK: - Body (owns @State for hover tracking)

private struct FabricTimelineBody: View {

    let items: [FabricTimelineItem]
    @Binding var selection: String?
    let accent: FabricAccent
    let axis: FabricTimeline.Axis
    let currentItemID: String?
    let isInteractive: Bool

    @State private var hoveredItemID: String? = nil
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.displayScale) private var displayScale

    private let nodeSize: Double = 22
    private let nodeFrameSize: Double = 28
    private let activeRingSize: Double = 26
    private let borderWidth: Double = 2.5
    private let connectorHeight: Double = 3

    var body: some View {
        Group {
            if axis == .vertical {
                verticalLayout
            } else {
                horizontalLayout
            }
        }
        .focusable(isInteractive)
        .focusEffectDisabled()
        #if os(macOS)
        .onKeyPress(.upArrow) { axis == .vertical ? selectAdjacentItem(offset: -1) : .ignored }
        .onKeyPress(.downArrow) { axis == .vertical ? selectAdjacentItem(offset: 1) : .ignored }
        .onKeyPress(.leftArrow) { axis == .horizontal ? selectAdjacentItem(offset: -1) : .ignored }
        .onKeyPress(.rightArrow) { axis == .horizontal ? selectAdjacentItem(offset: 1) : .ignored }
        #endif
        .opacity(isEnabled ? 1.0 : 0.5)
        .onChange(of: isEnabled) {
            if !isEnabled { hoveredItemID = nil }
        }
        .animation(reduceMotion ? nil : FabricAnimation.hover, value: hoveredItemID)
        .animation(reduceMotion ? nil : FabricAnimation.press, value: selection)
        .accessibilityElement(children: .contain)
    }

    // MARK: - Node State

    private enum NodeState {
        case completed, current, future
    }

    private func nodeState(at index: Int) -> NodeState {
        guard let currentID = currentItemID,
              let currentIndex = items.firstIndex(where: { $0.id == currentID }) else {
            return .future
        }
        if index < currentIndex { return .completed }
        if index == currentIndex { return .current }
        return .future
    }

    // MARK: - Vertical Layout

    private var verticalLayout: some View {
        VStack(alignment: .dotCenter, spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                verticalItemRow(item: item, index: index)
            }
        }
    }

    @ViewBuilder
    private func verticalItemRow(item: FabricTimelineItem, index: Int) -> some View {
        let isSelected = selection == item.id
        let isHovered = hoveredItemID == item.id && !isSelected

        let content = VStack(spacing: 0) {
            FabricTimelineConnector(
                item: item,
                isFirst: index == 0,
                isSelected: isSelected,
                timestampColor: timestampColor(for: item, isSelected: isSelected)
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

    // MARK: - Horizontal Layout

    private var horizontalLayout: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .dotCenterH, spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    if index > 0 {
                        horizontalConnector(beforeIndex: index)
                            .alignmentGuide(.dotCenterH) { d in d[VerticalAlignment.center] }
                            .frame(maxWidth: .infinity)
                    }

                    horizontalItemColumn(item: item, index: index)
                }
            }

            // Description panel — shown when a title is selected
            if let selectedItem = items.first(where: { $0.id == selection }),
               let description = selectedItem.description {
                Text(description)
                    .fabricTypography(.body)
                    .foregroundStyle(FabricColors.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, FabricSpacing.md)
            }
        }
    }

    // MARK: - Horizontal Item Column

    @ViewBuilder
    private func horizontalItemColumn(item: FabricTimelineItem, index: Int) -> some View {
        let isSelected = selection == item.id
        let isHovered = hoveredItemID == item.id && !isSelected
        let state = nodeState(at: index)

        let column = VStack(spacing: FabricSpacing.xs) {
            horizontalNode(state: state, accent: itemAccent(for: item), isHovered: isHovered)

            Text(item.timestamp)
                .fabricTypography(.caption)
                .foregroundStyle(horizontalLabelColor(state: state))
                .lineLimit(1)

            Text(item.title)
                .fabricTypography(.label)
                .foregroundStyle(
                    isSelected ? itemAccent(for: item).foreground : FabricColors.inkPrimary
                )
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
        .alignmentGuide(.dotCenterH) { _ in nodeFrameSize / 2 }

        if isInteractive {
            Button {
                guard isEnabled else { return }
                selection = isSelected ? nil : item.id
            } label: {
                column
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
            column
        }
    }

    // MARK: - Horizontal Node (step indicator style)

    @ViewBuilder
    private func horizontalNode(state: NodeState, accent: FabricAccent, isHovered: Bool) -> some View {
        switch state {
        case .completed:
            ZStack {
                Circle()
                    .fill(accent.foreground)
                    .frame(width: nodeSize, height: nodeSize)

                Image(systemName: "checkmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(FabricColors.onPrimary)

                Circle()
                    .stroke(accent.foreground.opacity(0.15), lineWidth: 3)
                    .frame(width: nodeFrameSize, height: nodeFrameSize)
            }
            .frame(width: nodeFrameSize, height: nodeFrameSize)
            .scaleEffect(isHovered ? 1.15 : 1.0)
            .animation(reduceMotion ? nil : FabricAnimation.hover, value: isHovered)

        case .current:
            ZStack {
                if !reduceMotion {
                    FabricTimelinePulseRing(accent: accent, delay: 0)
                    FabricTimelinePulseRing(
                        accent: accent,
                        delay: FabricAnimation.pulseStagger
                    )
                }

                Circle()
                    .fill(accent.foreground.opacity(0.10))
                    .frame(width: activeRingSize, height: activeRingSize)

                Circle()
                    .strokeBorder(accent.foreground, lineWidth: borderWidth)
                    .frame(width: activeRingSize, height: activeRingSize)
            }
            .frame(width: nodeFrameSize, height: nodeFrameSize)
            .scaleEffect(isHovered ? 1.1 : 1.0)
            .animation(reduceMotion ? nil : FabricAnimation.hover, value: isHovered)

        case .future:
            ZStack {
                Circle()
                    .strokeBorder(FabricColors.connector, lineWidth: borderWidth)
                    .frame(width: nodeSize, height: nodeSize)
            }
            .opacity(0.7)
            .frame(width: nodeFrameSize, height: nodeFrameSize)
            .scaleEffect(isHovered ? 1.15 : 1.0)
            .animation(reduceMotion ? nil : FabricAnimation.hover, value: isHovered)
        }
    }

    // MARK: - Horizontal Connector (step indicator style)

    private func horizontalConnector(beforeIndex index: Int) -> some View {
        let currentIndex = currentItemID.flatMap { id in
            items.firstIndex(where: { $0.id == id })
        }
        let filled = currentIndex.map { index <= $0 } ?? false
        let transition = currentIndex.map { index == $0 + 1 } ?? false

        return Capsule()
            .fill(
                transition
                    ? AnyShapeStyle(
                        LinearGradient(
                            colors: [accent.foreground, accent.foreground.opacity(0.25)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                      )
                    : filled
                        ? AnyShapeStyle(accent.foreground)
                        : AnyShapeStyle(FabricColors.connector)
            )
            .frame(height: connectorHeight)
            .padding(.horizontal, FabricSpacing.xs)
    }

    // MARK: - Horizontal Label Color

    private func horizontalLabelColor(state: NodeState) -> Color {
        switch state {
        case .completed: FabricColors.inkSecondary
        case .current: accent.foreground
        case .future: FabricColors.inkTertiary
        }
    }

    // MARK: - Shared Helpers

    private func itemAccent(for item: FabricTimelineItem) -> FabricAccent {
        if case .milestone(let a) = item.style { a }
        else { accent }
    }

    private func timestampColor(for item: FabricTimelineItem, isSelected: Bool) -> Color {
        if case .milestone(let a) = item.style {
            a.foreground
        } else if isSelected {
            FabricColors.inkPrimary
        } else {
            FabricColors.inkTertiary
        }
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

// MARK: - Pulse Ring (horizontal mode)

private struct FabricTimelinePulseRing: View {
    let accent: FabricAccent
    let delay: Double

    @State private var isAnimating = false

    var body: some View {
        Circle()
            .stroke(accent.foreground, lineWidth: 1.5)
            .frame(width: 26, height: 26)
            .scaleEffect(isAnimating ? 1.8 : 0.9)
            .opacity(isAnimating ? 0 : 0.5)
            .onAppear {
                withAnimation(
                    .easeOut(duration: FabricAnimation.pulseDuration)
                    .repeatForever(autoreverses: false)
                    .delay(delay)
                ) {
                    isAnimating = true
                }
            }
    }
}

// MARK: - Shared Dot View (vertical mode)

private struct FabricTimelineDot: View {

    let accent: FabricAccent?
    let isSelected: Bool
    let dotSize: Double

    var body: some View {
        if let accent {
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
            Circle()
                .fill(FabricColors.burlap)
                .frame(width: dotSize, height: dotSize)
                .fabricInnerShadow(Circle(), .subtle)
        }
    }
}

// MARK: - Content Block (vertical mode)

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

    private var accessibilityText: String {
        var parts = [String]()
        if isMilestone { parts.append("Milestone") }
        parts.append(item.timestamp)
        parts.append(item.title)
        if let desc = item.description { parts.append(desc) }
        return parts.joined(separator: ". ")
    }
}

// MARK: - Connector (vertical mode only)

private struct FabricTimelineConnector: View {

    let item: FabricTimelineItem
    let isFirst: Bool
    let isSelected: Bool
    let timestampColor: Color

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
                FabricTimelineDot(accent: accent, isSelected: isSelected, dotSize: dotSize)

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

    private var connectorLine: some View {
        Rectangle()
            .fill(FabricColors.connector)
            .frame(width: FabricSpacing.connectorWidth, height: FabricSpacing.lg)
    }
}

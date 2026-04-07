import SwiftUI

// MARK: - Data Model

public struct FabricTimelineItem: Identifiable {

    public let id: String
    public let timestamp: String
    public let title: String
    public let description: String?
    public let kind: Kind

    public enum Kind {
        case event
        case milestone(accent: FabricAccent)
    }

    public init(
        id: String = UUID().uuidString,
        timestamp: String,
        title: String,
        description: String? = nil,
        kind: Kind = .event
    ) {
        self.id = id
        self.timestamp = timestamp
        self.title = title
        self.description = description
        self.kind = kind
    }
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

public struct FabricTimeline<ItemOverlay: View, Trailing: View>: View {

    public enum Axis {
        case vertical
        case horizontal
    }

    public enum VerticalStyle {
        case leading     // dot at leading edge, labels trailing (default)
        case trailing    // dot at trailing edge, labels leading
        case alternating // even-index labels trailing, odd-index labels leading
    }

    public let items: [FabricTimelineItem]
    @Binding public var selection: String?
    public let accent: FabricAccent
    public let axis: Axis
    public let verticalStyle: VerticalStyle
    public let currentItemID: String?
    public let descriptionAlignment: HorizontalAlignment
    private let isInteractive: Bool
    let itemOverlay: (FabricTimelineItem) -> ItemOverlay
    let trailingContent: Trailing

    public var body: some View {
        FabricTimelineBody(
            items: items,
            selection: $selection,
            accent: accent,
            axis: axis,
            verticalStyle: verticalStyle,
            currentItemID: currentItemID,
            isInteractive: isInteractive,
            descriptionAlignment: descriptionAlignment,
            itemOverlay: itemOverlay,
            trailingContent: trailingContent
        )
    }
}

// MARK: - Non-interactive Init (backward compatible)

extension FabricTimeline where ItemOverlay == EmptyView, Trailing == EmptyView {
    public init(
        items: [FabricTimelineItem],
        axis: Axis = .vertical,
        verticalStyle: VerticalStyle = .leading
    ) {
        self.items = items
        self._selection = .constant(nil)
        self.accent = .indigo
        self.axis = axis
        self.verticalStyle = verticalStyle
        self.currentItemID = nil
        self.descriptionAlignment = .leading
        self.isInteractive = false
        self.itemOverlay = { _ in EmptyView() }
        self.trailingContent = EmptyView()
    }
}

// MARK: - Interactive Inits

extension FabricTimeline where ItemOverlay == EmptyView, Trailing == EmptyView {
    /// Interactive timeline with selection support.
    public init(
        items: [FabricTimelineItem],
        selection: Binding<String?>,
        currentItemID: String? = nil,
        accent: FabricAccent = .indigo,
        axis: Axis = .vertical,
        verticalStyle: VerticalStyle = .leading,
        descriptionAlignment: HorizontalAlignment = .leading
    ) {
        self.items = items
        self._selection = selection
        self.accent = accent
        self.axis = axis
        self.verticalStyle = verticalStyle
        self.currentItemID = currentItemID
        self.descriptionAlignment = descriptionAlignment
        self.isInteractive = true
        self.itemOverlay = { _ in EmptyView() }
        self.trailingContent = EmptyView()
    }
}

extension FabricTimeline where Trailing == EmptyView {
    /// Interactive timeline with per-item overlay (for context menus, drag sources, etc.).
    public init(
        items: [FabricTimelineItem],
        selection: Binding<String?>,
        currentItemID: String? = nil,
        accent: FabricAccent = .indigo,
        axis: Axis = .vertical,
        verticalStyle: VerticalStyle = .leading,
        descriptionAlignment: HorizontalAlignment = .leading,
        @ViewBuilder itemOverlay: @escaping (FabricTimelineItem) -> ItemOverlay
    ) {
        self.items = items
        self._selection = selection
        self.accent = accent
        self.axis = axis
        self.verticalStyle = verticalStyle
        self.currentItemID = currentItemID
        self.descriptionAlignment = descriptionAlignment
        self.isInteractive = true
        self.itemOverlay = itemOverlay
        self.trailingContent = EmptyView()
    }
}

extension FabricTimeline where ItemOverlay == EmptyView {
    /// Interactive timeline with trailing content (for "+" buttons, drop zones, etc.).
    public init(
        items: [FabricTimelineItem],
        selection: Binding<String?>,
        currentItemID: String? = nil,
        accent: FabricAccent = .indigo,
        axis: Axis = .vertical,
        verticalStyle: VerticalStyle = .leading,
        descriptionAlignment: HorizontalAlignment = .leading,
        @ViewBuilder trailingContent: () -> Trailing
    ) {
        self.items = items
        self._selection = selection
        self.accent = accent
        self.axis = axis
        self.verticalStyle = verticalStyle
        self.currentItemID = currentItemID
        self.descriptionAlignment = descriptionAlignment
        self.isInteractive = true
        self.itemOverlay = { _ in EmptyView() }
        self.trailingContent = trailingContent()
    }
}

extension FabricTimeline {
    /// Interactive timeline with per-item overlay and trailing content.
    public init(
        items: [FabricTimelineItem],
        selection: Binding<String?>,
        currentItemID: String? = nil,
        accent: FabricAccent = .indigo,
        axis: Axis = .vertical,
        verticalStyle: VerticalStyle = .leading,
        descriptionAlignment: HorizontalAlignment = .leading,
        @ViewBuilder itemOverlay: @escaping (FabricTimelineItem) -> ItemOverlay,
        @ViewBuilder trailingContent: () -> Trailing
    ) {
        self.items = items
        self._selection = selection
        self.accent = accent
        self.axis = axis
        self.verticalStyle = verticalStyle
        self.currentItemID = currentItemID
        self.descriptionAlignment = descriptionAlignment
        self.isInteractive = true
        self.itemOverlay = itemOverlay
        self.trailingContent = trailingContent()
    }
}

// MARK: - Body (owns @State for hover tracking)

private enum FabricTimelineMetrics {
    static let nodeSize: Double = 22
    static let nodeFrameSize: Double = 28
    static let activeRingSize: Double = 26
    static let borderWidth: Double = 2.5
    static let connectorThickness: Double = 3
    static let verticalConnectorHeight: Double = 100
    static let verticalRowMinHeight: Double = nodeFrameSize + verticalConnectorHeight
}

private struct FabricTimelineBody<ItemOverlay: View, Trailing: View>: View {

    let items: [FabricTimelineItem]
    @Binding var selection: String?
    let accent: FabricAccent
    let axis: FabricTimeline<ItemOverlay, Trailing>.Axis
    let verticalStyle: FabricTimeline<ItemOverlay, Trailing>.VerticalStyle
    let currentItemID: String?
    let isInteractive: Bool
    let descriptionAlignment: HorizontalAlignment
    let itemOverlay: (FabricTimelineItem) -> ItemOverlay
    let trailingContent: Trailing

    private typealias Metrics = FabricTimelineMetrics

    @State private var hoveredItemID: String? = nil
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var hasOverlay: Bool { ItemOverlay.self != EmptyView.self }
    private var hasTrailing: Bool { Trailing.self != EmptyView.self }

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

    // MARK: - Shared Node (step indicator style)

    @ViewBuilder
    private func timelineNode(state: NodeState, accent: FabricAccent, isHovered: Bool) -> some View {
        switch state {
        case .completed:
            ZStack {
                Circle()
                    .fill(accent.foreground)
                    .frame(width: Metrics.nodeSize, height: Metrics.nodeSize)

                Image(systemName: "checkmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(FabricColors.onPrimary)

                Circle()
                    .stroke(accent.foreground.opacity(0.15), lineWidth: 3)
                    .frame(width: Metrics.nodeFrameSize, height: Metrics.nodeFrameSize)
            }
            .frame(width: Metrics.nodeFrameSize, height: Metrics.nodeFrameSize)
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
                    .frame(width: Metrics.activeRingSize, height: Metrics.activeRingSize)

                Circle()
                    .strokeBorder(accent.foreground, lineWidth: Metrics.borderWidth)
                    .frame(width: Metrics.activeRingSize, height: Metrics.activeRingSize)
            }
            .frame(width: Metrics.nodeFrameSize, height: Metrics.nodeFrameSize)
            .scaleEffect(isHovered ? 1.1 : 1.0)
            .animation(reduceMotion ? nil : FabricAnimation.hover, value: isHovered)

        case .future:
            ZStack {
                Circle()
                    .strokeBorder(FabricColors.connector, lineWidth: Metrics.borderWidth)
                    .frame(width: Metrics.nodeSize, height: Metrics.nodeSize)
            }
            .opacity(0.7)
            .frame(width: Metrics.nodeFrameSize, height: Metrics.nodeFrameSize)
            .scaleEffect(isHovered ? 1.15 : 1.0)
            .animation(reduceMotion ? nil : FabricAnimation.hover, value: isHovered)
        }
    }

    // MARK: - Shared Connector Fill

    private func connectorFill(
        beforeIndex index: Int,
        startPoint: UnitPoint,
        endPoint: UnitPoint
    ) -> AnyShapeStyle {
        let currentIndex = currentItemID.flatMap { id in
            items.firstIndex(where: { $0.id == id })
        }
        let filled = currentIndex.map { index <= $0 } ?? false
        let transition = currentIndex.map { index == $0 + 1 } ?? false

        if transition {
            return AnyShapeStyle(
                LinearGradient(
                    colors: [accent.foreground, accent.foreground.opacity(0.25)],
                    startPoint: startPoint,
                    endPoint: endPoint
                )
            )
        } else if filled {
            return AnyShapeStyle(accent.foreground)
        } else {
            return AnyShapeStyle(FabricColors.connector)
        }
    }

    // MARK: - Shared Label Color

    private func labelColor(state: NodeState) -> Color {
        switch state {
        case .completed: FabricColors.inkSecondary
        case .current: accent.foreground
        case .future: FabricColors.inkTertiary
        }
    }

    // MARK: - Vertical Layout

    private var verticalLayout: some View {
        VStack(spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                verticalItemRow(item: item, index: index)
            }
            if hasTrailing {
                trailingContent
            }
        }
    }

    // MARK: - Vertical Label Content

    @ViewBuilder
    private func verticalLabelContent(
        item: FabricTimelineItem,
        isSelected: Bool,
        state: NodeState,
        itemAcc: FabricAccent,
        alignment: HorizontalAlignment
    ) -> some View {
        VStack(alignment: alignment, spacing: FabricSpacing.xs) {
            Text(item.timestamp)
                .fabricTypography(.caption)
                .foregroundStyle(labelColor(state: state))

            Text(item.title)
                .fabricTypography(.label)
                .foregroundStyle(
                    isSelected ? itemAcc.foreground : FabricColors.inkPrimary
                )
                .lineLimit(2)

            if let description = item.description {
                Text(description)
                    .fabricTypography(.body)
                    .foregroundStyle(FabricColors.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .multilineTextAlignment(alignment == .trailing ? .trailing : .leading)
    }

    // MARK: - Vertical Label Side

    private func verticalLabelOnTrailingSide(for index: Int) -> Bool {
        switch verticalStyle {
        case .leading: return true
        case .trailing: return false
        case .alternating: return index.isMultiple(of: 2)
        }
    }

    // MARK: - Vertical Spine Background

    @ViewBuilder
    private func verticalSpineBackground(index: Int) -> some View {
        GeometryReader { geo in
            let spineX: CGFloat = switch verticalStyle {
            case .leading: Metrics.nodeFrameSize / 2
            case .trailing: geo.size.width - Metrics.nodeFrameSize / 2
            case .alternating: geo.size.width / 2
            }
            let dotCenterY = Metrics.nodeFrameSize / 2

            // Top segment: from row top to dot center
            if index > 0 {
                Rectangle()
                    .fill(connectorFill(beforeIndex: index, startPoint: .top, endPoint: .bottom))
                    .frame(width: Metrics.connectorThickness, height: dotCenterY)
                    .position(x: spineX, y: dotCenterY / 2)
            }

            // Bottom segment: from dot center to row bottom
            if index < items.count - 1 {
                let segHeight = geo.size.height - dotCenterY
                Rectangle()
                    .fill(connectorFill(
                        beforeIndex: index + 1,
                        startPoint: .top,
                        endPoint: .bottom
                    ))
                    .frame(width: Metrics.connectorThickness, height: segHeight)
                    .position(x: spineX, y: dotCenterY + segHeight / 2)
            }
        }
    }

    // MARK: - Vertical Item Row

    @ViewBuilder
    private func verticalItemRow(item: FabricTimelineItem, index: Int) -> some View {
        let isSelected = selection == item.id
        let isHovered = hoveredItemID == item.id && !isSelected
        let state = nodeState(at: index)
        let itemAcc = itemAccent(for: item)
        let labelsOnTrailing = verticalLabelOnTrailingSide(for: index)

        let content: some View = Group {
            switch verticalStyle {
            case .leading:
                HStack(alignment: .top, spacing: FabricSpacing.sm) {
                    timelineNode(state: state, accent: itemAcc, isHovered: isHovered)
                        .frame(width: Metrics.nodeFrameSize)
                    verticalLabelContent(
                        item: item, isSelected: isSelected,
                        state: state, itemAcc: itemAcc, alignment: .leading
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

            case .trailing:
                HStack(alignment: .top, spacing: FabricSpacing.sm) {
                    verticalLabelContent(
                        item: item, isSelected: isSelected,
                        state: state, itemAcc: itemAcc, alignment: .trailing
                    )
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    timelineNode(state: state, accent: itemAcc, isHovered: isHovered)
                        .frame(width: Metrics.nodeFrameSize)
                }

            case .alternating:
                HStack(alignment: .top, spacing: FabricSpacing.sm) {
                    if labelsOnTrailing {
                        Color.clear.frame(maxWidth: .infinity)
                    } else {
                        verticalLabelContent(
                            item: item, isSelected: isSelected,
                            state: state, itemAcc: itemAcc, alignment: .trailing
                        )
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    }

                    timelineNode(state: state, accent: itemAcc, isHovered: isHovered)
                        .frame(width: Metrics.nodeFrameSize)

                    if labelsOnTrailing {
                        verticalLabelContent(
                            item: item, isSelected: isSelected,
                            state: state, itemAcc: itemAcc, alignment: .leading
                        )
                        .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        Color.clear.frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: Metrics.verticalRowMinHeight)
        .background { verticalSpineBackground(index: index) }

        if isInteractive {
            Button {
                guard isEnabled else { return }
                selection = isSelected ? nil : item.id
            } label: {
                content
            }
            .buttonStyle(.plain)
            .contentShape(Rectangle())
            .overlay { itemOverlay(item) }
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
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .dotCenterH, spacing: 0) {
                        ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                            if index > 0 {
                                Capsule()
                                    .fill(connectorFill(
                                        beforeIndex: index,
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ))
                                    .frame(height: Metrics.connectorThickness)
                                    .padding(.horizontal, FabricSpacing.xs)
                                    .alignmentGuide(.dotCenterH) { d in d[VerticalAlignment.center] }
                                    .frame(width: 200)
                            }

                            horizontalItemColumn(item: item, index: index)
                                .id(item.id)
                        }

                        if hasTrailing {
                            Capsule()
                                .fill(FabricColors.connector)
                                .frame(height: Metrics.connectorThickness)
                                .padding(.horizontal, FabricSpacing.xs)
                                .alignmentGuide(.dotCenterH) { d in d[VerticalAlignment.center] }
                                .frame(width: 200)

                            trailingContent
                                .alignmentGuide(.dotCenterH) { d in d[VerticalAlignment.center] }
                        }
                    }
                    .padding(.top, FabricSpacing.sm)
                    .padding(.bottom, FabricSpacing.xxxl)
                    .padding(.horizontal, 100)
                }
                .mask(
                    GeometryReader { geo in
                        let fadeWidth = max(geo.size.width / 5, 40)
                        let firstID = items.first?.id
                        let lastID = items.last?.id
                        let hideLeadingFade = firstID == selection || firstID == currentItemID
                        let hideTrailingFade = lastID == selection || lastID == currentItemID
                        HStack(spacing: 0) {
                            if hideLeadingFade {
                                Color.black.frame(width: fadeWidth)
                            } else {
                                LinearGradient(colors: [.clear, .black], startPoint: .leading, endPoint: .trailing)
                                    .frame(width: fadeWidth)
                            }
                            Color.black
                            if hideTrailingFade {
                                Color.black.frame(width: fadeWidth)
                            } else {
                                LinearGradient(colors: [.black, .clear], startPoint: .leading, endPoint: .trailing)
                                    .frame(width: fadeWidth)
                            }
                        }
                    }
                )
                .onAppear {
                    DispatchQueue.main.async {
                        if let currentID = currentItemID {
                            proxy.scrollTo(currentID, anchor: .center)
                        }
                    }
                }
                .onChange(of: selection) { _, newValue in
                    if let id = newValue {
                        withAnimation(.smooth(duration: 0.35)) {
                            proxy.scrollTo(id, anchor: .center)
                        }
                    }
                }
            }

            // Description panel — shown when a title is selected
            if let selectedItem = items.first(where: { $0.id == selection }),
               let description = selectedItem.description {
                Text(description)
                    .fabricTypography(.body)
                    .foregroundStyle(FabricColors.inkSecondary)
                    .multilineTextAlignment(descriptionAlignment == .center ? .center : .leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: Alignment(horizontal: descriptionAlignment, vertical: .center))
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
        let itemAcc = itemAccent(for: item)

        let column = timelineNode(state: state, accent: itemAcc, isHovered: isHovered)
            .overlay(alignment: .top) {
                VStack(spacing: FabricSpacing.xs) {
                    Text(item.timestamp)
                        .fabricTypography(.caption)
                        .foregroundStyle(labelColor(state: state))
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)

                    Text(item.title)
                        .fabricTypography(.label)
                        .foregroundStyle(
                            isSelected ? itemAcc.foreground : FabricColors.inkPrimary
                        )
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
                .frame(width: 200)
                .offset(y: Metrics.nodeFrameSize + FabricSpacing.sm)
            }
            .alignmentGuide(.dotCenterH) { _ in Metrics.nodeFrameSize / 2 }

        let hitWidth: Double = 200
        let hitHeight = Metrics.nodeFrameSize + FabricSpacing.xxxl + FabricSpacing.lg
        let hitOffsetX = -(hitWidth - Metrics.nodeFrameSize) / 2

        if isInteractive {
            column
                .background(alignment: .top) {
                    // Full item hit region: overlay + background share exact same geometry
                    ZStack {
                        Color.clear
                        itemOverlay(item)
                    }
                    .frame(width: hitWidth, height: hitHeight)
                    .offset(x: hitOffsetX)
                }
                .contentShape(Rectangle().size(width: hitWidth, height: hitHeight).offset(x: hitOffsetX))
                .onTapGesture {
                    guard isEnabled else { return }
                    selection = isSelected ? nil : item.id
                }
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

    // MARK: - Shared Helpers

    private func itemAccent(for item: FabricTimelineItem) -> FabricAccent {
        if case .milestone(let a) = item.kind { a }
        else { accent }
    }

    private func accessibilityText(for item: FabricTimelineItem) -> String {
        var parts = [String]()
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            switch nodeState(at: index) {
            case .completed: parts.append("Completed")
            case .current: parts.append("Current")
            case .future: break
            }
        }
        let isMilestone: Bool = if case .milestone = item.kind { true } else { false }
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

// MARK: - Pulse Ring

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
            .accessibilityHidden(true)
    }
}

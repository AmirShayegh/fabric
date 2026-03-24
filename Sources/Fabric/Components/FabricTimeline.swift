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

// MARK: - Custom Alignment (vertical mode: connector ↔ node ↔ content)

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

    private enum Metrics {
        static let nodeSize: Double = 22
        static let nodeFrameSize: Double = 28
        static let activeRingSize: Double = 26
        static let borderWidth: Double = 2.5
        static let connectorThickness: Double = 3
    }

    @State private var hoveredItemID: String? = nil
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

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
        let state = nodeState(at: index)
        let itemAcc = itemAccent(for: item)

        let content = VStack(alignment: .dotCenter, spacing: 0) {
            // Top connector line
            if index > 0 {
                Capsule()
                    .fill(connectorFill(beforeIndex: index, startPoint: .top, endPoint: .bottom))
                    .frame(width: Metrics.connectorThickness, height: 100)
                    .alignmentGuide(.dotCenter) { d in d[HorizontalAlignment.center] }
            }

            // Node with labels as overlay (labels don't affect alignment)
            timelineNode(state: state, accent: itemAcc, isHovered: isHovered)
                .alignmentGuide(.dotCenter) { d in d[HorizontalAlignment.center] }
                .overlay(alignment: .leading) {
                    VStack(alignment: .leading, spacing: FabricSpacing.xs) {
                        Text(item.timestamp)
                            .fabricTypography(.caption)
                            .foregroundStyle(labelColor(state: state))

                        Text(item.title)
                            .fabricTypography(.label)
                            .foregroundStyle(
                                isSelected ? itemAcc.foreground : FabricColors.inkPrimary
                            )
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)

                        if let description = item.description {
                            Text(description)
                                .fabricTypography(.body)
                                .foregroundStyle(FabricColors.inkSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .fixedSize()
                    .offset(x: Metrics.nodeFrameSize + FabricSpacing.sm)
                }
                .padding(.vertical, FabricSpacing.xs)
        }
        .padding(.vertical, FabricSpacing.xs)

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
                    }
                    .padding(.top, FabricSpacing.sm)
                    .padding(.horizontal, 600)
                    .padding(.bottom, FabricSpacing.xxxl)
                }
                .mask(
                    HStack(spacing: 0) {
                        LinearGradient(colors: [.clear, .black], startPoint: .leading, endPoint: .trailing)
                            .frame(width: 100)
                        Color.black
                        LinearGradient(colors: [.black, .clear], startPoint: .leading, endPoint: .trailing)
                            .frame(width: 100)
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
                        proxy.scrollTo(id, anchor: .center)
                    }
                }
            }

            // Description panel — shown when a title is selected
            if let selectedItem = items.first(where: { $0.id == selection }),
               let description = selectedItem.description {
                Text(description)
                    .fabricTypography(.body)
                    .foregroundStyle(FabricColors.inkSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .containerRelativeFrame(.horizontal) { width, _ in width * 0.8 }
                    .frame(maxWidth: .infinity)
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

        if isInteractive {
            Button {
                guard isEnabled else { return }
                print("[TIMELINE] tap item=\(item.id) isSelected=\(isSelected) → setting \(isSelected ? "nil" : item.id)")
                selection = isSelected ? nil : item.id
            } label: {
                column
            }
            .buttonStyle(.plain)
            .contentShape(Rectangle().size(width: 200, height: Metrics.nodeFrameSize + FabricSpacing.xxxl + FabricSpacing.lg).offset(x: -(200 - Metrics.nodeFrameSize) / 2))
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

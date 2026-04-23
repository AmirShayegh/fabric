import SwiftUI

// MARK: - Explicit-Mode Status Resolver
//
// Extracted to file scope (internal) so test targets can reach it via
// `@testable import Fabric` without plumbing through the private
// FabricTimelineBody. Pure function: no UI, no side effects.

/// Non-fatal issues detected during explicit-mode resolution.
internal struct TimelineStatusResolutionIssues: Equatable {
    var missingStatusCount: Int
    var extraCurrentCount: Int

    static let none = TimelineStatusResolutionIssues(missingStatusCount: 0, extraCurrentCount: 0)
    var isEmpty: Bool { missingStatusCount == 0 && extraCurrentCount == 0 }
}

/// Normalizes an item list into explicit-mode statuses, or returns nil
/// when every item has `status == nil` (legacy index-comparison mode).
///
/// In explicit mode:
/// - Items with `status == nil` are coerced to `.future` and reported
///   via `issues.missingStatusCount`.
/// - Multiple `.current` entries are coerced so only the FIRST keeps
///   `.current`; additional ones become `.inProgress` and reported via
///   `issues.extraCurrentCount`.
///
/// Pure function: no assertions, no side effects, no UI. Callers that
/// want debug-time noise for caller bugs should inspect `issues` and
/// trigger `assertionFailure` themselves. Tests can verify both the
/// statuses and the issues without the host process terminating.
internal func resolveExplicitTimelineStatuses(
    _ items: [FabricTimelineItem]
) -> (statuses: [FabricTimelineItem.Status], issues: TimelineStatusResolutionIssues)? {
    let hasAnyExplicit = items.contains { $0.status != nil }
    guard hasAnyExplicit else { return nil }
    var sawCurrent = false
    var issues = TimelineStatusResolutionIssues.none
    let resolved: [FabricTimelineItem.Status] = items.map { item in
        guard let s = item.status else {
            issues.missingStatusCount += 1
            return .future
        }
        if s == .current {
            if sawCurrent {
                issues.extraCurrentCount += 1
                return .inProgress
            }
            sawCurrent = true
            return .current
        }
        return s
    }
    return (resolved, issues)
}

// MARK: - Data Model

public struct FabricTimelineItem: Identifiable {

    public let id: String
    public let timestamp: String
    public let title: String
    public let description: String?
    public let kind: Kind
    public let status: Status?

    public enum Kind {
        case event
        case milestone(accent: FabricAccent)
    }

    /// Explicit per-item state for non-linear timelines where completion
    /// does not follow index order (for example, a project roadmap where
    /// phase 1 is complete while phase 0 is still in progress).
    ///
    /// When any item in a timeline sets `status`, `FabricTimeline`
    /// switches to "explicit mode": every node and connector derives
    /// from resolved per-item status. `currentItemID` in that mode
    /// becomes only the horizontal-layout scroll target and plays no
    /// role in visual state.
    ///
    /// When every item has `status == nil`, the legacy index-comparison
    /// behavior against `currentItemID` applies unchanged.
    public enum Status {
        /// Filled accent circle with a checkmark. Connectors to other
        /// completed / inProgress / current items use the accent color.
        case completed
        /// Filled accent circle with no checkmark. For items that are
        /// active but NOT the single primary-focus item.
        case inProgress
        /// Pulse ring plus stroked circle. Reserved for the single item
        /// the user's attention should focus on. In debug builds,
        /// having more than one `.current` in a timeline triggers an
        /// `assertionFailure`; release builds tolerate it but the
        /// pulse rendering becomes visually noisy.
        case current
        /// Outlined empty circle in connector color.
        case future
    }

    public init(
        id: String = UUID().uuidString,
        timestamp: String,
        title: String,
        description: String? = nil,
        kind: Kind = .event,
        status: Status? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.title = title
        self.description = description
        self.kind = kind
        self.status = status
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

    public let items: [FabricTimelineItem]
    @Binding public var selection: String?
    public let accent: FabricAccent
    public let axis: Axis
    public let currentItemID: String?
    public let descriptionAlignment: HorizontalAlignment
    private let isInteractive: Bool
    let itemOverlay: (FabricTimelineItem) -> ItemOverlay
    let trailingContent: Trailing

    /// Optional max width applied to each label column in vertical
    /// timelines. When set, long titles and descriptions wrap inside
    /// this width rather than stretching to half the container width.
    /// `nil` preserves the existing full-width behavior.
    public var labelMaxWidth: CGFloat? = nil

    /// Returns a copy of the timeline with `labelMaxWidth` applied.
    /// Chainable modifier so existing call sites do not need to change
    /// their initializer invocations:
    ///
    ///     FabricTimeline(items: items, selection: $sel)
    ///         .labelMaxWidth(360)
    public func labelMaxWidth(_ width: CGFloat?) -> Self {
        var copy = self
        copy.labelMaxWidth = width
        return copy
    }

    public var body: some View {
        FabricTimelineBody(
            items: items,
            selection: $selection,
            accent: accent,
            axis: axis,
            currentItemID: currentItemID,
            isInteractive: isInteractive,
            descriptionAlignment: descriptionAlignment,
            labelMaxWidth: labelMaxWidth,
            itemOverlay: itemOverlay,
            trailingContent: trailingContent
        )
    }
}

// MARK: - Non-interactive Init (backward compatible)

extension FabricTimeline where ItemOverlay == EmptyView, Trailing == EmptyView {
    public init(
        items: [FabricTimelineItem],
        axis: Axis = .vertical
    ) {
        self.items = items
        self._selection = .constant(nil)
        self.accent = .indigo
        self.axis = axis
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
        descriptionAlignment: HorizontalAlignment = .leading
    ) {
        self.items = items
        self._selection = selection
        self.accent = accent
        self.axis = axis
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
        descriptionAlignment: HorizontalAlignment = .leading,
        @ViewBuilder itemOverlay: @escaping (FabricTimelineItem) -> ItemOverlay
    ) {
        self.items = items
        self._selection = selection
        self.accent = accent
        self.axis = axis
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
        descriptionAlignment: HorizontalAlignment = .leading,
        @ViewBuilder trailingContent: () -> Trailing
    ) {
        self.items = items
        self._selection = selection
        self.accent = accent
        self.axis = axis
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
        descriptionAlignment: HorizontalAlignment = .leading,
        @ViewBuilder itemOverlay: @escaping (FabricTimelineItem) -> ItemOverlay,
        @ViewBuilder trailingContent: () -> Trailing
    ) {
        self.items = items
        self._selection = selection
        self.accent = accent
        self.axis = axis
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
    let currentItemID: String?
    let isInteractive: Bool
    let descriptionAlignment: HorizontalAlignment
    let labelMaxWidth: CGFloat?
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
        case completed, inProgress, current, future
    }

    /// Explicit per-item statuses, resolved once per render.
    /// See `resolveExplicitTimelineStatuses(_:)` for the full contract.
    private var resolvedStatuses: [NodeState] {
        guard let result = resolveExplicitTimelineStatuses(items) else { return [] }
        // Debug-only nudges for caller bugs. Release builds render the
        // normalized output unchanged.
        if result.issues.missingStatusCount > 0 {
            assertionFailure(
                "FabricTimeline: \(result.issues.missingStatusCount) item(s) have nil status in explicit mode; coerced to .future"
            )
        }
        if result.issues.extraCurrentCount > 0 {
            assertionFailure(
                "FabricTimeline: \(result.issues.extraCurrentCount + 1) items have .current status; only one primary-current is supported. Extras coerced to .inProgress"
            )
        }
        return result.statuses.map { s in
            switch s {
            case .completed: return .completed
            case .inProgress: return .inProgress
            case .current: return .current
            case .future: return .future
            }
        }
    }

    private func nodeState(at index: Int) -> NodeState {
        let resolved = resolvedStatuses
        if !resolved.isEmpty {
            return resolved[index]
        }
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

        case .inProgress:
            // Filled accent circle with no checkmark. For active items
            // that are NOT the single primary-current. Intentionally
            // lighter than .completed (no checkmark) but heavier than
            // .future (filled, not outlined) and without the pulse
            // animation reserved for .current.
            ZStack {
                Circle()
                    .fill(accent.foreground)
                    .frame(width: Metrics.nodeSize, height: Metrics.nodeSize)

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
        let resolved = resolvedStatuses
        // Note: callers may pass `beforeIndex: items.count` for the
        // trailing-connector sentinel (vertical bottom segment after
        // the last item). In explicit mode that index has no
        // right-neighbor status, so we fall through to the legacy
        // branch which correctly returns connector color when
        // `currentItemID` is nil.
        if !resolved.isEmpty && index > 0 && index < resolved.count {
            // Explicit mode: derive connector fill from per-item statuses
            // rather than index comparison. Rules applied in order:
            //   1. right == .future  -> connector color (nothing to flow into)
            //   2. left  == .future  -> connector color (nothing to flow from)
            //   3. left or right == .current -> gradient (attention hand-off)
            //   4. otherwise -> full accent
            let left = resolved[index - 1]
            let right = resolved[index]
            if right == .future || left == .future {
                return AnyShapeStyle(FabricColors.connector)
            }
            if left == .current || right == .current {
                let colors = left == .current
                    ? [accent.foreground, accent.foreground.opacity(0.25)]
                    : [accent.foreground.opacity(0.25), accent.foreground]
                return AnyShapeStyle(
                    LinearGradient(colors: colors, startPoint: startPoint, endPoint: endPoint)
                )
            }
            return AnyShapeStyle(accent.foreground)
        }

        // Legacy index-comparison mode: unchanged behavior.
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
        case .inProgress: accent.foreground
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
                verticalTrailingConnector
                trailingContent
            }
        }
    }

    // MARK: - Vertical Trailing Connector

    @ViewBuilder
    private var verticalTrailingConnector: some View {
        GeometryReader { geo in
            Capsule()
                .fill(FabricColors.connector)
                .frame(width: Metrics.connectorThickness, height: FabricSpacing.lg)
                .position(x: geo.size.width / 2, y: FabricSpacing.lg / 2)
        }
        .frame(height: FabricSpacing.lg)
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
        index.isMultiple(of: 2)
    }

    // MARK: - Vertical Spine Background

    @ViewBuilder
    private func verticalSpineBackground(index: Int) -> some View {
        GeometryReader { geo in
            let spineX: CGFloat = geo.size.width / 2
            let dotCenterY = Metrics.nodeFrameSize / 2
            let nodeRadius = Metrics.nodeSize / 2

            // Top segment: from row top to circle top edge
            if index > 0 {
                let topEnd = dotCenterY - nodeRadius
                Rectangle()
                    .fill(connectorFill(beforeIndex: index, startPoint: .top, endPoint: .bottom))
                    .frame(width: Metrics.connectorThickness, height: topEnd)
                    .position(x: spineX, y: topEnd / 2)
            }

            // Bottom segment: from circle bottom edge to row bottom
            if index < items.count - 1 || hasTrailing {
                let bottomStart = dotCenterY + nodeRadius
                let segHeight = geo.size.height - bottomStart
                Rectangle()
                    .fill(connectorFill(
                        beforeIndex: index + 1,
                        startPoint: .top,
                        endPoint: .bottom
                    ))
                    .frame(width: Metrics.connectorThickness, height: segHeight)
                    .position(x: spineX, y: bottomStart + segHeight / 2)
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

        let content: some View = HStack(alignment: .top, spacing: FabricSpacing.sm) {
            Group {
                if labelsOnTrailing {
                    Color.clear
                } else {
                    verticalLabelContent(
                        item: item, isSelected: isSelected,
                        state: state, itemAcc: itemAcc, alignment: .trailing
                    )
                    // Clamp the label content's width when requested,
                    // so long titles wrap into multiple lines instead
                    // of stretching to half the container width. The
                    // outer Group still fills .infinity to keep the
                    // node centered and alignment stable.
                    .frame(maxWidth: labelMaxWidth, alignment: .trailing)
                }
            }
            .frame(maxWidth: .infinity, alignment: labelsOnTrailing ? .center : .trailing)

            timelineNode(state: state, accent: itemAcc, isHovered: isHovered)
                .frame(width: Metrics.nodeFrameSize)

            Group {
                if labelsOnTrailing {
                    verticalLabelContent(
                        item: item, isSelected: isSelected,
                        state: state, itemAcc: itemAcc, alignment: .leading
                    )
                    .frame(maxWidth: labelMaxWidth, alignment: .leading)
                } else {
                    Color.clear
                }
            }
            .frame(maxWidth: .infinity, alignment: labelsOnTrailing ? .leading : .center)
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
            case .inProgress: parts.append("In progress")
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

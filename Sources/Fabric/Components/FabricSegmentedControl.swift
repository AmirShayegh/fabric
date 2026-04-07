import SwiftUI

public struct FabricSegmentedControl<Selection: Hashable>: View {

    @Binding public var selection: Selection
    public let segments: [Segment]
    public let accent: FabricAccent

    public struct Segment: Identifiable, Equatable {
        public let value: Selection
        public let label: String
        public var id: Selection { value }

        public init(_ label: String, value: Selection) {
            self.label = label
            self.value = value
        }
    }

    public init(
        selection: Binding<Selection>,
        segments: [Segment],
        accent: FabricAccent = .indigo
    ) {
        assert(
            Set(segments.map(\.value)).count == segments.count,
            "FabricSegmentedControl: segment values must be unique"
        )
        self._selection = selection
        self.segments = segments
        self.accent = accent
    }

    public var body: some View {
        FabricSegmentedControlBody(
            selection: $selection,
            segments: segments,
            accent: accent
        )
    }
}

// MARK: - String Convenience

extension FabricSegmentedControl where Selection == String {
    public init(
        selection: Binding<String>,
        segments: [String],
        accent: FabricAccent = .indigo
    ) {
        self.init(
            selection: selection,
            segments: segments.map { Segment($0, value: $0) },
            accent: accent
        )
    }
}

// MARK: - Body (owns @Namespace and @State)

private struct FabricSegmentedControlBody<Selection: Hashable>: View {

    @Binding var selection: Selection
    let segments: [FabricSegmentedControl<Selection>.Segment]
    let accent: FabricAccent

    @Namespace private var namespace
    @State private var hoveredSegment: Selection? = nil
    @State private var keyboardNavigated = false
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.displayScale) private var displayScale
    @Environment(\.controlSize) private var controlSize

    private var isCompact: Bool {
        controlSize == .mini || controlSize == .small
    }

    private let trackShape = Capsule()

    var body: some View {
        HStack(spacing: 0) {
            ForEach(segments) { segment in
                segmentButton(segment)
            }
        }
        .background {
            // Single sliding indicator — always present, reads geometry from selected anchor
            if segments.contains(where: { $0.value == selection }) {
                Capsule()
                    .fill(FabricColors.canvas)
                    .overlay {
                        Capsule().strokeBorder(
                            LinearGradient(
                                colors: [FabricColors.highlight, Color.clear],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 0.5
                        )
                    }
                    .fabricShadow(.low)
                    .matchedGeometryEffect(id: selection, in: namespace, isSource: false)
                    .animation(reduceMotion ? nil : FabricAnimation.slide, value: selection)
            }
        }
        .padding(FabricSpacing.xs)
        .frame(minHeight: isCompact ? 0 : 44)
        .background {
            ZStack {
                trackShape.fill(FabricColors.parchment)
                trackShape.foregroundStyle(
                    TextureGenerator.linenPaint(
                        displayScale: displayScale,
                        intensity: 0.025
                    )
                )
            }
        }
        .fabricInnerShadow(trackShape, .shallow)
        .focusable()
        .focusEffectDisabled()
        #if os(macOS)
        .onKeyPress(.leftArrow) { selectAdjacentSegment(offset: -1) }
        .onKeyPress(.rightArrow) { selectAdjacentSegment(offset: 1) }
        #endif
        .animation(reduceMotion ? nil : FabricAnimation.hover, value: hoveredSegment)
        .opacity(isEnabled ? 1.0 : 0.5)
        .onChange(of: isEnabled) {
            if !isEnabled { hoveredSegment = nil }
        }
        .onChange(of: selection) {
            if keyboardNavigated {
                AccessibilityNotification.Announcement(selectedLabel).post()
                keyboardNavigated = false
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityValue(selectedLabel)
    }

    // MARK: - Selected Label (for accessibility)

    private var selectedLabel: String {
        segments.first { $0.value == selection }?.label ?? ""
    }

    // MARK: - Arrow Key Navigation

    #if os(macOS)
    private func selectAdjacentSegment(offset: Int) -> KeyPress.Result {
        guard isEnabled else { return .ignored }
        guard let currentIndex = segments.firstIndex(where: { $0.value == selection }) else {
            return .ignored
        }
        let newIndex = currentIndex + offset
        guard segments.indices.contains(newIndex) else { return .ignored }
        keyboardNavigated = true
        selection = segments[newIndex].value
        return .handled
    }
    #endif

    // MARK: - Segment Button

    private func segmentButton(
        _ segment: FabricSegmentedControl<Selection>.Segment
    ) -> some View {
        let isSelected = selection == segment.value
        let isHovered = hoveredSegment == segment.value

        return Button {
            guard !isSelected else { return }
            selection = segment.value
        } label: {
            Text(segment.label)
                .fabricTypography(.label)
                .foregroundStyle(
                    isSelected ? accent.foreground : FabricColors.inkSecondary
                )
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .padding(.horizontal, FabricSpacing.md)
                .padding(.vertical, FabricSpacing.sm)
                .frame(maxWidth: .infinity, minHeight: isCompact ? 0 : 44)
                .contentShape(Capsule())
                .background {
                    // Invisible anchor — always present, registers this segment's frame
                    Capsule()
                        .fill(Color.clear)
                        .matchedGeometryEffect(id: segment.value, in: namespace, isSource: true)
                }
                .background {
                    // Hover fill — only for unselected segments
                    if !isSelected && isHovered {
                        Capsule()
                            .fill(FabricColors.burlap.opacity(0.08))
                    }
                }
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            guard isEnabled else { return }
            hoveredSegment = hovering ? segment.value : nil
        }
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityLabel(segment.label)
    }

}

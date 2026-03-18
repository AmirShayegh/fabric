import SwiftUI

public struct FabricTabBar<Selection: Hashable>: View {

    @Binding public var selection: Selection
    public let tabs: [Tab]
    public let accent: FabricAccent

    public struct Tab: Identifiable, Equatable {
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
        tabs: [Tab],
        accent: FabricAccent = .indigo
    ) {
        assert(
            Set(tabs.map(\.value)).count == tabs.count,
            "FabricTabBar: tab values must be unique"
        )
        self._selection = selection
        self.tabs = tabs
        self.accent = accent
    }

    public var body: some View {
        FabricTabBarBody(
            selection: $selection,
            tabs: tabs,
            accent: accent
        )
    }
}

// MARK: - String Convenience

extension FabricTabBar where Selection == String {
    public init(
        selection: Binding<String>,
        tabs: [String],
        accent: FabricAccent = .indigo
    ) {
        self.init(
            selection: selection,
            tabs: tabs.map { Tab($0, value: $0) },
            accent: accent
        )
    }
}

// MARK: - Body (owns @Namespace and @State)

private struct FabricTabBarBody<Selection: Hashable>: View {

    @Binding var selection: Selection
    let tabs: [FabricTabBar<Selection>.Tab]
    let accent: FabricAccent

    @Namespace private var namespace
    @State private var hoveredTab: Selection?
    @State private var keyboardNavigated = false
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            VStack(spacing: 0) {
                HStack(spacing: FabricSpacing.lg) {
                    ForEach(tabs) { tab in
                        tabButton(tab)
                    }
                }
                .frame(minHeight: 44)

                // Underline container — inside ScrollView so matchedGeometryEffect
                // shares coordinate space with tab anchors
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(FabricColors.connector)
                        .frame(height: 1)

                    if tabs.contains(where: { $0.value == selection }) {
                        Capsule()
                            .fill(accent.foreground)
                            .frame(height: 2)
                            .matchedGeometryEffect(id: selection, in: namespace, isSource: false)
                            .animation(
                                reduceMotion ? nil : FabricAnimation.slide,
                                value: selection
                            )
                    }
                }
            }
        }
        .focusable()
        .focusEffectDisabled()
        #if os(macOS)
        .onKeyPress(.leftArrow) { selectAdjacentTab(offset: -1) }
        .onKeyPress(.rightArrow) { selectAdjacentTab(offset: 1) }
        #endif
        .opacity(isEnabled ? 1.0 : 0.5)
        .onChange(of: isEnabled) {
            if !isEnabled { hoveredTab = nil }
        }
        .animation(reduceMotion ? nil : FabricAnimation.hover, value: hoveredTab)
        .onChange(of: selection) {
            if keyboardNavigated {
                AccessibilityNotification.Announcement(selectedLabel).post()
                keyboardNavigated = false
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityValue(selectedLabel)
    }

    // MARK: - Selected Label

    private var selectedLabel: String {
        tabs.first { $0.value == selection }?.label ?? ""
    }

    // MARK: - Arrow Key Navigation

    #if os(macOS)
    private func selectAdjacentTab(offset: Int) -> KeyPress.Result {
        guard isEnabled else { return .ignored }
        guard let currentIndex = tabs.firstIndex(where: { $0.value == selection }) else {
            return .ignored
        }
        let newIndex = currentIndex + offset
        guard tabs.indices.contains(newIndex) else { return .ignored }
        keyboardNavigated = true
        selection = tabs[newIndex].value
        return .handled
    }
    #endif

    // MARK: - Tab Button

    private func tabButton(
        _ tab: FabricTabBar<Selection>.Tab
    ) -> some View {
        let isSelected = selection == tab.value
        let isHovered = hoveredTab == tab.value

        return Button {
            guard !isSelected else { return }
            selection = tab.value
        } label: {
            VStack(spacing: 0) {
                Text(tab.label)
                    .fabricTypography(.label)
                    .foregroundStyle(
                        isSelected || isHovered ? FabricColors.inkPrimary : FabricColors.inkSecondary
                    )
                    .lineLimit(1)
                    .padding(.horizontal, FabricSpacing.sm)
                    .padding(.vertical, FabricSpacing.sm)

                // Invisible anchor for matchedGeometryEffect
                Color.clear
                    .frame(height: 2)
                    .matchedGeometryEffect(id: tab.value, in: namespace, isSource: true)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            guard isEnabled else { return }
            hoveredTab = hovering ? tab.value : nil
        }
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityLabel(tab.label)
    }
}

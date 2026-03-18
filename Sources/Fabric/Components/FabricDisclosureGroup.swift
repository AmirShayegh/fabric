import SwiftUI

public struct FabricDisclosureGroup<Content: View>: View {

    public let title: String
    public let count: Int?
    public let accent: FabricAccent?
    @Binding public var isExpanded: Bool
    @ViewBuilder public let content: Content

    public init(
        _ title: String,
        count: Int? = nil,
        accent: FabricAccent? = nil,
        isExpanded: Binding<Bool>,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.count = count
        self.accent = accent
        self._isExpanded = isExpanded
        self.content = content()
    }

    public var body: some View {
        FabricDisclosureGroupBody(
            title: title,
            count: count,
            accent: accent,
            isExpanded: $isExpanded,
            content: { content }
        )
    }
}

// MARK: - Body View (owns @State for hover tracking)

private struct FabricDisclosureGroupBody<Content: View>: View {

    let title: String
    let count: Int?
    let accent: FabricAccent?
    @Binding var isExpanded: Bool
    @ViewBuilder let content: Content

    @State private var isHovered = false
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerView

            if isExpanded {
                Rectangle()
                    .fill(FabricColors.connector)
                    .frame(height: 0.5)
                    .padding(.horizontal, FabricSpacing.md)

                content
                    .padding(.top, FabricSpacing.xs)
                    .padding(.bottom, FabricSpacing.md)
                    .padding(.horizontal, FabricSpacing.md)
            }
        }
        .animation(
            reduceMotion ? nil : FabricAnimation.soft,
            value: isExpanded
        )
        .opacity(isEnabled ? 1.0 : 0.5)
        .accessibilityElement(children: .contain)
    }

    // MARK: - Header

    private var headerView: some View {
        Button {
            if reduceMotion {
                isExpanded.toggle()
            } else {
                withAnimation(FabricAnimation.soft) {
                    isExpanded.toggle()
                }
            }
        } label: {
            HStack(spacing: FabricSpacing.sm) {
                Text(title)
                    .fabricLabel()

                if let count {
                    FabricBadge(
                        "\(count)",
                        accent: accent ?? .indigo
                    )
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(FabricColors.inkTertiary)
                    .rotationEffect(.degrees(isExpanded ? 90 : 0))
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, FabricSpacing.md)
            .padding(.vertical, FabricSpacing.sm)
            .background(FabricColors.burlap.opacity(isHovered ? 0.08 : 0))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            guard isEnabled else { return }
            isHovered = hovering
        }
        .onChange(of: isEnabled) {
            if !isEnabled { isHovered = false }
        }
        .animation(reduceMotion ? nil : FabricAnimation.hover, value: isHovered)
        .accessibilityLabel(title)
        .accessibilityValue(count.map { "\($0) items" } ?? "")
        .accessibilityHint(isExpanded ? "Collapse" : "Expand")
    }
}

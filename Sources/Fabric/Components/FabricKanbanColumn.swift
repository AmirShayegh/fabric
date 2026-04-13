import SwiftUI

public struct FabricKanbanColumn<Content: View, HeaderTrailing: View>: View {

    public let title: String
    public let count: Int?
    public let isDropTarget: Bool
    public let columnWidth: CGFloat?
    public let accent: FabricAccent
    public let showShadow: Bool
    public let onAdd: (() -> Void)?
    @ViewBuilder public let headerTrailing: HeaderTrailing
    @ViewBuilder public let content: Content

    /// When true, body wraps content in LazyVStack (data+builder init).
    /// When false, body wraps content in VStack (legacy @ViewBuilder init).
    private let useLazyLayout: Bool

    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var shape: RoundedRectangle {
        FabricSpacing.shape(radius: FabricSpacing.radiusMd)
    }

    /// Legacy @ViewBuilder initializer. Content is wrapped in an eager VStack.
    public init(
        _ title: String,
        count: Int? = nil,
        isDropTarget: Bool = false,
        columnWidth: CGFloat? = nil,
        accent: FabricAccent = .indigo,
        showShadow: Bool = false,
        onAdd: (() -> Void)? = nil,
        @ViewBuilder headerTrailing: () -> HeaderTrailing = { EmptyView() },
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.count = count
        self.isDropTarget = isDropTarget
        self.columnWidth = columnWidth
        self.accent = accent
        self.showShadow = showShadow
        self.onAdd = onAdd
        self.headerTrailing = headerTrailing()
        self.content = content()
        self.useLazyLayout = false
    }

    /// Data+builder initializer. Content is wrapped in a LazyVStack for
    /// on-demand instantiation -- only visible cards are created (~10-15),
    /// reducing memory from O(n) to O(visible).
    public init<Item: Identifiable, CardView: View>(
        _ title: String,
        data: [Item],
        count: Int? = nil,
        isDropTarget: Bool = false,
        columnWidth: CGFloat? = nil,
        accent: FabricAccent = .indigo,
        showShadow: Bool = false,
        onAdd: (() -> Void)? = nil,
        @ViewBuilder headerTrailing: () -> HeaderTrailing = { EmptyView() },
        @ViewBuilder cardBuilder: @escaping (Item) -> CardView
    ) where Content == ForEach<[Item], Item.ID, CardView> {
        self.title = title
        self.count = count
        self.isDropTarget = isDropTarget
        self.columnWidth = columnWidth
        self.accent = accent
        self.showShadow = showShadow
        self.onAdd = onAdd
        self.headerTrailing = headerTrailing()
        self.content = ForEach(data) { item in cardBuilder(item) }
        self.useLazyLayout = true
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: FabricSpacing.sm) {
            // Header
            HStack(spacing: FabricSpacing.sm) {
                Text(title).fabricHeading()
                headerTrailing
                Spacer()
                if let onAdd {
                    Button(action: onAdd) {
                        Image(systemName: "plus")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(FabricColors.inkTertiary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Add to \(title)")
                }
                if let count {
                    FabricBadge("\(count)")
                }
            }

            // Divider
            Rectangle()
                .fill(FabricColors.inkTertiary.opacity(0.15))
                .frame(height: 0.5)

            // Content -- scrolls when cards overflow the column height.
            // LazyVStack (data+builder) instantiates only visible cards;
            // VStack (legacy @ViewBuilder) instantiates all eagerly.
            ScrollView(.vertical) {
                if useLazyLayout {
                    LazyVStack(spacing: FabricSpacing.sm) {
                        content
                    }
                } else {
                    VStack(spacing: FabricSpacing.sm) {
                        content
                    }
                }
            }
            .contentMargins(.vertical, FabricSpacing.xs, for: .scrollContent)
            .scrollBounceBehavior(.basedOnSize)
        }
        .padding(FabricSpacing.md)
        .frame(
            minWidth: max(columnWidth ?? FabricSpacing.columnMinWidth, FabricSpacing.columnMinWidth),
            maxWidth: columnWidth.map { max($0, FabricSpacing.columnMinWidth) } ?? .infinity,
            alignment: .top
        )
        .fabricSurface(
            isDropTarget
                ? accent.foreground.opacity(0.04)
                : FabricColors.parchment,
            textureIntensity: isDropTarget ? 0.015 : 0.02
        )
        .clipShape(shape)
        .fabricInnerShadow(shape, .recessed)
        .fabricShadow(
            .low,
            tightColor: showShadow ? FabricColors.shadowTight : .clear,
            ambientColor: showShadow ? FabricColors.shadow : .clear
        )
        .overlay {
            if isDropTarget {
                shape.strokeBorder(
                    accent.foreground.opacity(0.50),
                    lineWidth: 2.0
                )
            }
        }
        .scaleEffect(isDropTarget && !reduceMotion ? FabricAnimation.dropTargetScale : 1.0)
        .opacity(isEnabled ? 1.0 : 0.5)
        .animation(
            reduceMotion ? nil : FabricAnimation.press,
            value: isDropTarget
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel(title)
        .accessibilityHint(count.map { "\($0) items" } ?? "")
    }
}

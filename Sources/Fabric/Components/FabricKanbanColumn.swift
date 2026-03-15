import SwiftUI

public struct FabricKanbanColumn<Content: View>: View {

    public let title: String
    public let count: Int?
    public let isDropTarget: Bool
    public let columnWidth: CGFloat?
    @ViewBuilder public let content: Content

    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var shape: RoundedRectangle {
        FabricSpacing.shape(radius: FabricSpacing.radiusMd)
    }

    public init(
        _ title: String,
        count: Int? = nil,
        isDropTarget: Bool = false,
        columnWidth: CGFloat? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.count = count
        self.isDropTarget = isDropTarget
        self.columnWidth = columnWidth
        self.content = content()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: FabricSpacing.sm) {
            // Header
            HStack {
                Text(title).fabricHeading()
                Spacer()
                if let count {
                    FabricBadge("\(count)")
                }
            }

            // Divider
            Rectangle()
                .fill(FabricColors.inkTertiary.opacity(0.15))
                .frame(height: 0.5)

            // Content
            VStack(spacing: FabricSpacing.sm) {
                content
            }
        }
        .padding(FabricSpacing.md)
        .frame(
            minWidth: max(columnWidth ?? FabricSpacing.columnMinWidth, FabricSpacing.columnMinWidth),
            maxWidth: columnWidth.map { max($0, FabricSpacing.columnMinWidth) } ?? .infinity,
            alignment: .top
        )
        .fabricSurface(
            isDropTarget
                ? FabricColors.indigo.opacity(0.04)
                : FabricColors.parchment,
            textureIntensity: isDropTarget ? 0.015 : 0.02
        )
        .clipShape(shape)
        .fabricInnerShadow(shape, .recessed)
        .overlay {
            if isDropTarget {
                shape.strokeBorder(
                    FabricColors.indigo.opacity(0.50),
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

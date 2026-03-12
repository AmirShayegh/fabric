import SwiftUI

struct FabricKanbanColumn<Content: View>: View {

    let title: String
    let count: Int?
    let isDropTarget: Bool
    @ViewBuilder let content: () -> Content

    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var shape: RoundedRectangle {
        FabricSpacing.shape(radius: FabricSpacing.radiusMd)
    }

    init(
        _ title: String,
        count: Int? = nil,
        isDropTarget: Bool = false,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.count = count
        self.isDropTarget = isDropTarget
        self.content = content
    }

    var body: some View {
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
            LazyVStack(spacing: FabricSpacing.sm) {
                content()
            }
        }
        .padding(FabricSpacing.md)
        .frame(minWidth: FabricSpacing.columnMinWidth, alignment: .top)
        .fabricSurface(
            isDropTarget
                ? FabricColors.parchment.opacity(0.95)
                : FabricColors.parchment,
            textureIntensity: 0.02
        )
        .clipShape(shape)
        .innerShadow(
            shape,
            color: FabricColors.innerShadow,
            radius: 3, spread: 3, y: 1.5
        )
        .overlay {
            if isDropTarget {
                shape.strokeBorder(
                    FabricColors.indigo.opacity(0.30),
                    lineWidth: 1.5
                )
            }
        }
        .opacity(isEnabled ? 1.0 : 0.5)
        .animation(
            reduceMotion ? nil : .spring(response: 0.25, dampingFraction: 0.7),
            value: isDropTarget
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel(title)
        .accessibilityHint(count.map { "\($0) items" } ?? "")
    }
}

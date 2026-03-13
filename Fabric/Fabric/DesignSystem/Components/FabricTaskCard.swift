import SwiftUI

struct FabricTaskCard: View {

    let title: String
    let description: String?
    let tags: [Tag]?
    let onTap: (() -> Void)?

    struct Tag: Identifiable, Equatable {
        let id: String
        let label: String
        let accent: FabricAccent

        init(_ label: String, accent: FabricAccent, id: String? = nil) {
            self.id = id ?? UUID().uuidString
            self.label = label
            self.accent = accent
        }

    }

    init(
        _ title: String,
        description: String? = nil,
        tags: [Tag]? = nil,
        onTap: (() -> Void)? = nil
    ) {
        self.title = title
        self.description = description
        self.tags = tags
        self.onTap = onTap
    }

    var body: some View {
        FabricTaskCardBody(
            title: title,
            description: description,
            tags: tags,
            onTap: onTap
        )
    }
}

// MARK: - Body View (owns @State for hover tracking)

private struct FabricTaskCardBody: View {

    let title: String
    let description: String?
    let tags: [FabricTaskCard.Tag]?
    let onTap: (() -> Void)?

    @State private var isHovered = false
    @State private var isPressed = false
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.displayScale) private var displayScale

    private var shape: RoundedRectangle {
        FabricSpacing.shape(radius: FabricSpacing.radiusSm)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: FabricSpacing.sm) {
            Text(title)
                .fabricTypography(.label)
                .fabricInk(.primary)

            if let description {
                Text(description)
                    .fabricTypography(.caption)
                    .foregroundStyle(FabricColors.inkSecondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let tags, !tags.isEmpty {
                FabricFlowLayout(spacing: FabricSpacing.xs) {
                    ForEach(tags) { tag in
                        FabricPill(tag.label, accent: tag.accent)
                    }
                }
            }
        }
        .padding(FabricSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background { backgroundView }
        .clipShape(shape)
        .overlay {
            shape.strokeBorder(
                LinearGradient(
                    colors: [FabricColors.highlight, Color.clear],
                    startPoint: .top,
                    endPoint: .center
                ),
                lineWidth: 0.5
            )
        }
        .shadow(
            color: isPressed || !isEnabled ? .clear : FabricColors.shadowTight,
            radius: isHovered ? 1.5 : 1,
            x: 0,
            y: isHovered ? 1.5 : 1
        )
        .shadow(
            color: isPressed || !isEnabled ? .clear : FabricColors.shadow,
            radius: isHovered ? 12 : 8,
            x: 0,
            y: isHovered ? 6 : 4
        )
        .innerShadow(
            shape,
            color: FabricColors.innerShadow,
            radius: isPressed ? 4 : 0,
            spread: isPressed ? 5 : 0,
            y: isPressed ? 2 : 0
        )
        .scaleEffect(isPressed && !reduceMotion ? 0.95 : 1.0)
        .offset(y: isHovered && !isPressed && !reduceMotion ? -2 : 0)
        .opacity(isEnabled ? 1.0 : 0.5)
        .onHover { hovering in
            guard isEnabled else { return }
            isHovered = hovering
        }
        .onChange(of: isEnabled) {
            if !isEnabled { isHovered = false; isPressed = false }
        }
        .simultaneousGesture(
            onTap != nil
                ? TapGesture().onEnded {
                    guard isEnabled else { return }
                    if reduceMotion {
                        onTap?()
                    } else {
                        isPressed = true
                        withAnimation(FabricAnimation.press) {
                            isPressed = false
                        }
                        onTap?()
                    }
                }
                : nil
        )
        .animation(
            reduceMotion ? nil : FabricAnimation.hover,
            value: isHovered
        )
        .animation(
            reduceMotion ? nil : FabricAnimation.press,
            value: isPressed
        )
        .focusable(onTap != nil)
        .onKeyPress(.space) {
            guard isEnabled, let onTap else { return .ignored }
            onTap()
            return .handled
        }
        .onKeyPress(.return) {
            guard isEnabled, let onTap else { return .ignored }
            onTap()
            return .handled
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
        .accessibilityAddTraits(onTap != nil ? .isButton : [])
        .accessibilityAction { guard isEnabled else { return }; onTap?() }
    }

    // MARK: - Background

    @ViewBuilder
    private var backgroundView: some View {
        ZStack {
            shape.fill(FabricColors.canvas)
            shape.foregroundStyle(
                TextureGenerator.linenPaint(displayScale: displayScale, intensity: 0.025)
            )
        }
    }

    // MARK: - Accessibility

    private var accessibilityText: String {
        var parts = [title]
        if let description { parts.append(description) }
        if let tags, !tags.isEmpty {
            parts.append("Tags: " + tags.map(\.label).joined(separator: ", "))
        }
        return parts.joined(separator: ". ")
    }
}

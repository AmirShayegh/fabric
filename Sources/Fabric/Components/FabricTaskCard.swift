import SwiftUI

public struct FabricTaskCard: View {

    public let title: String
    public let description: String?
    public let tags: [Tag]?
    public let accent: FabricAccent
    public let isSelected: Bool
    public let onTap: (() -> Void)?

    /// Advanced hook for apps managing drag lifecycle externally (e.g., AppKit bridging).
    /// SwiftUI's `.draggable()` has no reliable cancel callback, so the ShowcaseView
    /// demo does NOT wire this binding. When true: lifted shadows, scale, rotation, ghost opacity.
    @Binding public var isDragging: Bool

    public let onMoveUp: (() -> Void)?
    public let onMoveDown: (() -> Void)?
    public let onMoveToColumn: ((String) -> Void)?
    public let availableColumns: [String]

    public struct Tag: Identifiable, Equatable {
        public let id: String
        public let label: String
        public let accent: FabricAccent

        public init(_ label: String, accent: FabricAccent, id: String? = nil) {
            self.id = id ?? UUID().uuidString
            self.label = label
            self.accent = accent
        }

    }

    public init(
        _ title: String,
        description: String? = nil,
        tags: [Tag]? = nil,
        accent: FabricAccent = .indigo,
        isSelected: Bool = false,
        isDragging: Binding<Bool> = .constant(false),
        onTap: (() -> Void)? = nil,
        onMoveUp: (() -> Void)? = nil,
        onMoveDown: (() -> Void)? = nil,
        onMoveToColumn: ((String) -> Void)? = nil,
        availableColumns: [String] = []
    ) {
        self.title = title
        self.description = description
        self.tags = tags
        self.accent = accent
        self.isSelected = isSelected
        self._isDragging = isDragging
        self.onTap = onTap
        self.onMoveUp = onMoveUp
        self.onMoveDown = onMoveDown
        self.onMoveToColumn = onMoveToColumn
        self.availableColumns = availableColumns
    }

    public var body: some View {
        FabricTaskCardBody(
            title: title,
            description: description,
            tags: tags,
            accent: accent,
            isSelected: isSelected,
            isDragging: isDragging,
            onTap: onTap,
            onMoveUp: onMoveUp,
            onMoveDown: onMoveDown,
            onMoveToColumn: onMoveToColumn,
            availableColumns: availableColumns
        )
    }
}

// MARK: - Body View (owns @State for hover tracking)

private struct FabricTaskCardBody: View {

    let title: String
    let description: String?
    let tags: [FabricTaskCard.Tag]?
    let accent: FabricAccent
    let isSelected: Bool
    let isDragging: Bool
    let onTap: (() -> Void)?
    let onMoveUp: (() -> Void)?
    let onMoveDown: (() -> Void)?
    let onMoveToColumn: ((String) -> Void)?
    let availableColumns: [String]

    @State private var isHovered = false
    @State private var isPressed = false
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.displayScale) private var displayScale

    private var shape: RoundedRectangle {
        FabricSpacing.shape(radius: FabricSpacing.radiusSm)
    }

    private var elevation: FabricElevation.ShadowPair {
        if isDragging { .drag }
        else if isHovered { .high }
        else { .mid }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: FabricSpacing.sm) {
            Text(title)
                .fabricTypography(.label)
                .fabricInk(.primary)
                .fixedSize(horizontal: false, vertical: true)

            if let description {
                Text(description)
                    .fabricTypography(.caption)
                    .foregroundStyle(FabricColors.inkSecondary)
                    .lineLimit(2)
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
        .overlay {
            if isSelected {
                shape.strokeBorder(accent.foreground, lineWidth: 2)
            }
        }
        .fabricShadow(
            elevation,
            tightColor: isPressed || !isEnabled ? .clear : FabricColors.shadowTight,
            ambientColor: isPressed || !isEnabled ? .clear : FabricColors.shadow
        )
        .innerShadow(
            shape,
            color: FabricColors.innerShadow,
            radius: isPressed ? FabricElevation.Inset.deep.radius : 0,
            spread: isPressed ? FabricElevation.Inset.deep.spread : 0,
            y: isPressed ? FabricElevation.Inset.deep.y : 0
        )
        .scaleEffect(isPressed && !reduceMotion ? 0.95 : 1.0)
        .scaleEffect(isDragging && !reduceMotion ? FabricAnimation.liftScale : 1.0)
        .rotationEffect(.degrees(isDragging && !reduceMotion ? FabricAnimation.liftRotation : 0))
        .offset(y: isHovered && !isPressed && !reduceMotion ? -2 : 0)
        .opacity(isDragging ? FabricAnimation.ghostOpacity : (isEnabled ? 1.0 : 0.5))
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
        .animation(
            reduceMotion ? nil : FabricAnimation.lift,
            value: isDragging
        )
        .animation(
            reduceMotion ? nil : FabricAnimation.hover,
            value: isSelected
        )
        .focusable(onTap != nil)
        .focusEffectDisabled()
        #if os(macOS)
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
        #endif
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
        .accessibilityAddTraits(onTap != nil ? .isButton : [])
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityAction { guard isEnabled else { return }; onTap?() }
        .modifier(MoveActionsModifier(
            onMoveUp: onMoveUp,
            onMoveDown: onMoveDown,
            onMoveToColumn: onMoveToColumn,
            availableColumns: availableColumns
        ))
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

// MARK: - Accessibility Move Actions

/// Adds conditional accessibility actions for reordering and moving cards.
/// Uses AnyView wrapping internally for the dynamic action list — acceptable since
/// accessibility actions are metadata-only and do not affect layout identity.
private struct MoveActionsModifier: ViewModifier {
    let onMoveUp: (() -> Void)?
    let onMoveDown: (() -> Void)?
    let onMoveToColumn: ((String) -> Void)?
    let availableColumns: [String]

    func body(content: Content) -> some View {
        // Build accessibility actions dynamically. Each action is pure metadata
        // (no layout/animation impact), so dynamic composition is safe.
        var result: AnyView = AnyView(content)

        if let onMoveUp {
            result = AnyView(result.accessibilityAction(named: "Move up") { onMoveUp() })
        }
        if let onMoveDown {
            result = AnyView(result.accessibilityAction(named: "Move down") { onMoveDown() })
        }
        if let onMoveToColumn {
            for column in availableColumns {
                result = AnyView(result.accessibilityAction(named: "Move to \(column)") {
                    onMoveToColumn(column)
                })
            }
        }

        return result
    }
}

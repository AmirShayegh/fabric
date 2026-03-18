import SwiftUI

public struct FabricChip: View {

    public let label: String
    public let accent: FabricAccent
    public var isRemovable: Bool = false
    public var onRemove: (() -> Void)? = nil

    public init(
        _ label: String,
        accent: FabricAccent,
        isRemovable: Bool = false,
        onRemove: (() -> Void)? = nil
    ) {
        self.label = label
        self.accent = accent
        self.isRemovable = isRemovable
        self.onRemove = onRemove
    }

    public var body: some View {
        FabricChipBody(
            label: label,
            accent: accent,
            isRemovable: isRemovable,
            onRemove: onRemove
        )
    }
}

// MARK: - Body View (owns @State for hover tracking)

private struct FabricChipBody: View {

    let label: String
    let accent: FabricAccent
    let isRemovable: Bool
    let onRemove: (() -> Void)?

    @State private var isHovered = false
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var shape: RoundedRectangle {
        FabricSpacing.shape(radius: FabricSpacing.radiusXs)
    }

    var body: some View {
        HStack(spacing: FabricSpacing.xs) {
            Text(label)
                .fabricTypography(.caption)
                .foregroundStyle(accent.foreground)
                .accessibilityHidden(isRemovable)

            if isRemovable {
                Button {
                    onRemove?()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(accent.foreground)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Remove \(label)")
            }
        }
        .padding(.horizontal, FabricSpacing.sm)
        .frame(height: FabricSpacing.chipHeight)
        .background {
            shape.fill(isHovered ? accent.foreground.opacity(0.20) : accent.fill)
        }
        .clipShape(shape)
        .onHover { hovering in
            guard isEnabled else { return }
            isHovered = hovering
        }
        .onChange(of: isEnabled) {
            if !isEnabled { isHovered = false }
        }
        .opacity(isEnabled ? 1.0 : 0.5)
        .animation(
            reduceMotion ? nil : FabricAnimation.hover,
            value: isHovered
        )
        .accessibilityElement(children: isRemovable ? .contain : .ignore)
        .accessibilityLabel(label)
    }
}

import SwiftUI

struct FabricTextField: View {

    /// Bundles a trailing icon button with its action and accessibility label.
    struct TrailingAction {
        let icon: String
        let accessibilityLabel: String
        let action: () -> Void
    }

    let label: String
    let placeholder: String
    @Binding var text: String
    let leadingIcon: String?
    let trailing: TrailingAction?

    @FocusState private var isFocused: Bool
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(
        label: String? = nil,
        placeholder: String,
        text: Binding<String>,
        leadingIcon: String? = nil,
        trailing: TrailingAction? = nil
    ) {
        self.label = label ?? placeholder
        self.placeholder = placeholder
        self._text = text
        self.leadingIcon = leadingIcon
        self.trailing = trailing
    }

    var body: some View {
        HStack(spacing: FabricSpacing.sm) {
            if let leadingIcon {
                Image(systemName: leadingIcon)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(FabricColors.inkTertiary)
            }

            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .font(.system(size: 17, weight: .regular))
                .tracking(-0.08)
                .foregroundStyle(FabricColors.inkPrimary)
                .focused($isFocused)

            if let trailing {
                Button {
                    trailing.action()
                } label: {
                    Image(systemName: trailing.icon)
                        .font(.system(size: 15, weight: .regular))
                        .foregroundStyle(FabricColors.inkTertiary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(trailing.accessibilityLabel)
            }
        }
        .padding(11)
        .background {
            Capsule().fill(FabricColors.parchment)
        }
        .innerShadow(Capsule(), color: FabricColors.innerShadow, radius: 2, spread: 2, y: 1)
        .overlay {
            Capsule().strokeBorder(
                isFocused
                    ? Color(nsColor: .keyboardFocusIndicatorColor)
                    : FabricColors.inkTertiary.opacity(0.15),
                lineWidth: isFocused ? 2.5 : 0.5
            )
        }
        .opacity(isEnabled ? 1.0 : 0.5)
        .animation(reduceMotion ? nil : FabricAnimation.hover, value: isFocused)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(label)
    }
}

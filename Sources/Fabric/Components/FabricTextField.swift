import SwiftUI

public struct FabricTextField: View {

    /// Bundles a trailing icon button with its action and accessibility label.
    public struct TrailingAction {
        public let icon: String
        public let accessibilityLabel: String
        public let action: () -> Void

        public init(icon: String, accessibilityLabel: String, action: @escaping () -> Void) {
            self.icon = icon
            self.accessibilityLabel = accessibilityLabel
            self.action = action
        }
    }

    public let label: String
    public let placeholder: String
    @Binding public var text: String
    public let leadingIcon: String?
    public let trailing: TrailingAction?

    @FocusState private var isFocused: Bool
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(
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

    private var focusRingColor: Color {
        #if os(macOS)
        Color(nsColor: .keyboardFocusIndicatorColor)
        #else
        Color.accentColor
        #endif
    }

    public var body: some View {
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
                    ? focusRingColor
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

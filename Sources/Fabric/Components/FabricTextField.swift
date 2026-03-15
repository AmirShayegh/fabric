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
    public let error: String?

    @FocusState private var isFocused: Bool
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(
        label: String? = nil,
        placeholder: String,
        text: Binding<String>,
        leadingIcon: String? = nil,
        trailing: TrailingAction? = nil,
        error: String? = nil
    ) {
        self.label = label ?? placeholder
        self.placeholder = placeholder
        self._text = text
        self.leadingIcon = leadingIcon
        self.trailing = trailing
        // Normalize empty/whitespace-only strings to nil
        if let error, !error.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            self.error = error
        } else {
            self.error = nil
        }
    }

    private var focusRingColor: Color {
        #if os(macOS)
        Color(nsColor: .keyboardFocusIndicatorColor)
        #else
        Color.accentColor
        #endif
    }

    private var hasError: Bool { error != nil }

    public var body: some View {
        VStack(alignment: .leading, spacing: FabricSpacing.xs) {
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
            .fabricInnerShadow(Capsule(), .shallow)
            .overlay {
                // Error border — always visible when error is set
                if hasError {
                    Capsule().strokeBorder(
                        FabricColors.madder,
                        lineWidth: 1.5
                    )
                }
            }
            .overlay {
                // Focus ring — layered on top of error border when both active
                if isFocused {
                    Capsule().strokeBorder(
                        focusRingColor,
                        lineWidth: 2.5
                    )
                } else if !hasError {
                    // Default subtle border when no error and not focused
                    Capsule().strokeBorder(
                        FabricColors.inkTertiary.opacity(0.15),
                        lineWidth: 0.5
                    )
                }
            }
            .opacity(isEnabled ? 1.0 : 0.5)
            .animation(reduceMotion ? nil : FabricAnimation.hover, value: isFocused)
            .animation(reduceMotion ? nil : FabricAnimation.hover, value: hasError)

            if let error {
                Text(error)
                    .fabricTypography(.caption)
                    .foregroundStyle(FabricColors.madder)
                    .padding(.horizontal, FabricSpacing.sm)
            }
        }
        .onChange(of: error) { old, new in
            if old == nil, let new {
                AccessibilityNotification.Announcement("\(label). \(new)").post()
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(label)
    }
}

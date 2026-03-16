import SwiftUI

public struct FabricSearchField: View {

    public let label: String
    @Binding public var text: String
    public let placeholder: String
    public let onSubmit: (() -> Void)?

    @FocusState private var isFocused: Bool
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(
        label: String? = nil,
        placeholder: String = "Search\u{2026}",
        text: Binding<String>,
        onSubmit: (() -> Void)? = nil
    ) {
        self.label = label ?? placeholder
        self.placeholder = placeholder
        self._text = text
        self.onSubmit = onSubmit
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
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(FabricColors.inkTertiary)

            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .font(.system(size: 17, weight: .regular))
                .tracking(-0.08)
                .foregroundStyle(FabricColors.inkPrimary)
                .focused($isFocused)
                .onSubmit { onSubmit?() }

            Button {
                if reduceMotion {
                    text = ""
                } else {
                    withAnimation(FabricAnimation.hover) {
                        text = ""
                    }
                }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(FabricColors.inkTertiary)
            }
            .buttonStyle(.plain)
            .opacity(text.isEmpty ? 0 : 1)
            .disabled(text.isEmpty)
            .accessibilityLabel("Clear search")
            .accessibilityHidden(text.isEmpty)
        }
        .padding(11)
        .background {
            Capsule().fill(FabricColors.parchment)
        }
        .fabricInnerShadow(Capsule(), .shallow)
        .overlay {
            if isFocused {
                Capsule().strokeBorder(focusRingColor, lineWidth: 2.5)
            } else {
                Capsule().strokeBorder(
                    FabricColors.inkTertiary.opacity(0.15),
                    lineWidth: 0.5
                )
            }
        }
        .frame(minHeight: FabricSpacing.textFieldHeight)
        .opacity(isEnabled ? 1.0 : 0.5)
        .animation(reduceMotion ? nil : FabricAnimation.hover, value: isFocused)
        .animation(reduceMotion ? nil : FabricAnimation.hover, value: text.isEmpty)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(label)
    }
}

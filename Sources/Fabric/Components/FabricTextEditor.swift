import SwiftUI

public struct FabricTextEditor: View {

    public let label: String
    public let placeholder: String
    @Binding public var text: String
    public let error: String?
    public let minHeight: CGFloat
    public let maxHeight: CGFloat

    @FocusState private var isFocused: Bool
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var shape: RoundedRectangle {
        FabricSpacing.shape(radius: FabricSpacing.radiusSm)
    }

    public init(
        label: String? = nil,
        placeholder: String,
        text: Binding<String>,
        error: String? = nil,
        minHeight: CGFloat = 88,
        maxHeight: CGFloat = 300
    ) {
        self.label = label ?? placeholder
        self.placeholder = placeholder
        self._text = text
        self.minHeight = minHeight
        self.maxHeight = maxHeight
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
            ZStack(alignment: .topLeading) {
                // Placeholder — visible when text is empty
                if text.isEmpty {
                    Text(placeholder)
                        .font(.system(size: 17, weight: .regular))
                        .tracking(-0.08)
                        .foregroundStyle(FabricColors.inkTertiary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 12)
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                }

                // TextEditor
                TextEditor(text: $text)
                    .font(.system(size: 17, weight: .regular))
                    .tracking(-0.08)
                    .foregroundStyle(FabricColors.inkPrimary)
                    .textEditorStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .focused($isFocused)
                    .padding(4)
            }
            .frame(minHeight: minHeight, maxHeight: maxHeight)
            .background { shape.fill(FabricColors.parchment) }
            .fabricInnerShadow(shape, .shallow)
            .overlay {
                if hasError {
                    shape.strokeBorder(FabricColors.madder, lineWidth: 1.5)
                }
            }
            .overlay {
                if isFocused {
                    shape.strokeBorder(focusRingColor, lineWidth: 2.5)
                } else if !hasError {
                    shape.strokeBorder(
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

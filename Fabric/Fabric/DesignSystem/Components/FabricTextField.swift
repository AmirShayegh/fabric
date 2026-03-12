import SwiftUI

struct FabricTextField: View {

    let placeholder: String
    @Binding var text: String

    @FocusState private var isFocused: Bool
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var shape: RoundedRectangle {
        FabricSpacing.shape(radius: FabricSpacing.radiusSm)
    }

    var body: some View {
        TextField(placeholder, text: $text)
            .textFieldStyle(.plain)
            .fabricTypography(.body)
            .foregroundStyle(FabricColors.inkPrimary)
            .padding(.horizontal, FabricSpacing.lg)
            .frame(height: FabricSpacing.textFieldHeight)
            .background {
                shape.fill(FabricColors.parchment)
            }
            .innerShadow(shape, color: FabricColors.innerShadow, radius: 3, spread: 3, y: 1.5)
            .overlay {
                shape.strokeBorder(
                    isFocused
                        ? Color.accentColor.opacity(0.5)
                        : FabricColors.inkTertiary.opacity(0.20),
                    lineWidth: isFocused ? 2 : 0.75
                )
            }
            .focused($isFocused)
            .opacity(isEnabled ? 1.0 : 0.5)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.15), value: isFocused)
    }
}

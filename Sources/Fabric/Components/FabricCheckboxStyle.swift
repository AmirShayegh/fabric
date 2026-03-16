import SwiftUI

public struct FabricCheckboxStyle: ToggleStyle {

    public enum CheckState {
        case standard
        case indeterminate
    }

    public let accent: FabricAccent
    public let checkState: CheckState

    public init(
        accent: FabricAccent = .indigo,
        checkState: CheckState = .standard
    ) {
        self.accent = accent
        self.checkState = checkState
    }

    public func makeBody(configuration: Configuration) -> some View {
        FabricCheckboxBody(
            configuration: configuration,
            accent: accent,
            checkState: checkState
        )
    }
}

// MARK: - Convenience Extensions

extension ToggleStyle where Self == FabricCheckboxStyle {
    public static var fabricCheckbox: FabricCheckboxStyle { .init() }

    public static func fabricCheckbox(
        accent: FabricAccent = .indigo,
        checkState: FabricCheckboxStyle.CheckState = .standard
    ) -> FabricCheckboxStyle {
        .init(accent: accent, checkState: checkState)
    }
}

// MARK: - Body View (owns @State for hover tracking)

private struct FabricCheckboxBody: View {

    let configuration: ToggleStyleConfiguration
    let accent: FabricAccent
    let checkState: FabricCheckboxStyle.CheckState

    @State private var isHovered = false
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let boxSize = FabricSpacing.checkboxSize
    private var boxShape: RoundedRectangle { FabricSpacing.shape(radius: 5) }

    private var isOn: Bool { configuration.isOn }
    private var showCheck: Bool { isOn && checkState == .standard }
    private var showMinus: Bool { isOn && checkState == .indeterminate }

    var body: some View {
        Button {
            guard isEnabled else { return }
            if reduceMotion {
                configuration.isOn.toggle()
            } else {
                withAnimation(FabricAnimation.press) {
                    configuration.isOn.toggle()
                }
            }
        } label: {
            HStack(spacing: FabricSpacing.md) {
                checkboxBox

                configuration.label
                    .fabricBody()

                Spacer(minLength: 0)
            }
            .padding(.vertical, FabricSpacing.xs)
            .background(FabricColors.burlap.opacity(isHovered ? 0.08 : 0))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .frame(minHeight: 44)
        .onHover { hovering in
            guard isEnabled else { return }
            isHovered = hovering
        }
        .onChange(of: isEnabled) {
            if !isEnabled { isHovered = false }
        }
        .opacity(isEnabled ? 1.0 : 0.5)
        .animation(reduceMotion ? nil : FabricAnimation.hover, value: isHovered)
        .animation(reduceMotion ? nil : FabricAnimation.press, value: isOn)
        .accessibilityValue(
            checkState == .indeterminate ? "Mixed" : (isOn ? "Checked" : "Unchecked")
        )
    }

    // MARK: - Checkbox Box

    @ViewBuilder
    private var checkboxBox: some View {
        ZStack {
            if isOn {
                // Checked / indeterminate — pebble
                boxShape
                    .fill(accent.foreground)
                    .overlay {
                        boxShape.strokeBorder(
                            LinearGradient(
                                colors: [FabricColors.highlight, Color.clear],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 0.5
                        )
                    }
                    .fabricShadow(.micro)

                Image(systemName: showMinus ? "minus" : "checkmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(FabricColors.onPrimary)
            } else {
                // Unchecked — fabric (recessed)
                boxShape
                    .fill(FabricColors.parchment)
                    .overlay {
                        boxShape.strokeBorder(
                            FabricColors.inkTertiary.opacity(0.15),
                            lineWidth: 0.5
                        )
                    }
                    .fabricInnerShadow(boxShape, .shallow)
            }
        }
        .frame(width: boxSize, height: boxSize)
    }
}

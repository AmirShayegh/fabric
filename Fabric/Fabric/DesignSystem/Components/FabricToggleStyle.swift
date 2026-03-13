import SwiftUI

struct FabricToggleStyle: ToggleStyle {

    func makeBody(configuration: Configuration) -> some View {
        FabricToggleBody(configuration: configuration)
    }
}

// MARK: - Body View (owns @State for stable hover tracking)

private struct FabricToggleBody: View {

    let configuration: ToggleStyleConfiguration

    @State private var isHovered = false
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button {
            guard isEnabled else { return }
            if reduceMotion {
                configuration.isOn.toggle()
            } else {
                withAnimation(FabricAnimation.soft) {
                    configuration.isOn.toggle()
                }
            }
        } label: {
            HStack(spacing: FabricSpacing.md) {
                configuration.label
                    .fabricBody()

                toggleTrack(isOn: configuration.isOn)
            }
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            guard isEnabled else { return }
            isHovered = hovering
        }
        .opacity(isEnabled ? 1.0 : 0.5)
    }

    // MARK: - Track

    private func toggleTrack(isOn: Bool) -> some View {
        let trackW = FabricSpacing.toggleTrackW
        let trackH = FabricSpacing.toggleTrackH
        let knobW = FabricSpacing.toggleKnobW
        let pad = FabricSpacing.togglePadding
        let knobOffset = isOn ? (trackW - knobW) / 2 - pad : -(trackW - knobW) / 2 + pad

        return ZStack {
            // Track fill
            Capsule()
                .fill(trackFill(isOn: isOn))

            // "|" accessibility indicator — always present, opacity-toggled
            Rectangle()
                .fill(FabricColors.onPrimary.opacity(0.7))
                .frame(width: 1, height: 10)
                .offset(x: isOn ? -knobW / 2 - pad : 0)
                .opacity(isOn ? 1 : 0)

            // Pill-shaped knob — positioned via offset
            Capsule()
                .fill(FabricColors.onPrimary)
                .frame(width: knobW, height: FabricSpacing.toggleThumb)
                .overlay {
                    Capsule()
                        .strokeBorder(
                            LinearGradient(
                                colors: [FabricColors.highlight, Color.clear],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 0.5
                        )
                }
                .shadow(color: FabricColors.shadowTight, radius: 0.5, x: 0, y: 0.5)
                .shadow(color: FabricColors.shadow, radius: 3, x: 0, y: 2)
                .offset(x: knobOffset)
        }
        .frame(width: trackW, height: trackH)
        .frame(minWidth: 44, minHeight: 44)
    }

    private func trackFill(isOn: Bool) -> Color {
        if isOn {
            isHovered ? FabricColors.indigo.opacity(0.55) : FabricColors.indigo.opacity(0.42)
        } else {
            isHovered ? FabricColors.burlap.opacity(0.42) : FabricColors.burlap.opacity(0.28)
        }
    }
}

extension ToggleStyle where Self == FabricToggleStyle {
    static var fabric: FabricToggleStyle { .init() }
}

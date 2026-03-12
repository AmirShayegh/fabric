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
        HStack(spacing: FabricSpacing.md) {
            configuration.label
                .fabricBody()

            toggleTrack(isOn: configuration.isOn)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            guard isEnabled else { return }
            if reduceMotion {
                configuration.isOn.toggle()
            } else {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.65)) {
                    configuration.isOn.toggle()
                }
            }
        }
        .onHover { hovering in
            guard isEnabled else { return }
            isHovered = hovering
        }
        .opacity(isEnabled ? 1.0 : 0.5)
    }

    // MARK: - Track

    @ViewBuilder
    private func toggleTrack(isOn: Bool) -> some View {
        let trackShape = Capsule()

        ZStack(alignment: isOn ? .trailing : .leading) {
            trackShape
                .fill(trackFill(isOn: isOn))
                .frame(width: FabricSpacing.toggleTrackW, height: FabricSpacing.toggleTrackH)
                .innerShadow(trackShape, color: FabricColors.innerShadow, radius: 2, spread: 2.5, y: 1)

            Circle()
                .fill(FabricColors.onPrimary)
                .frame(width: FabricSpacing.toggleThumb, height: FabricSpacing.toggleThumb)
                .overlay {
                    Circle()
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
                .padding(.horizontal, 3)
        }
        .frame(minWidth: 44, minHeight: 44)
    }

    private func trackFill(isOn: Bool) -> Color {
        if isOn {
            return isHovered ? FabricColors.indigo.opacity(0.42) : FabricColors.indigo.opacity(0.28)
        } else {
            return isHovered ? FabricColors.burlap.opacity(0.42) : FabricColors.burlap.opacity(0.28)
        }
    }
}

extension ToggleStyle where Self == FabricToggleStyle {
    static var fabric: FabricToggleStyle { .init() }
}

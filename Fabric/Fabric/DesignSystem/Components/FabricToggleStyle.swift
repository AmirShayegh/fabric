import SwiftUI

struct FabricToggleStyle: ToggleStyle {

    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var isHovered = false

    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: FabricSpacing.md) {
            configuration.label
                .fabricBody()

            toggleTrack(isOn: configuration.isOn)
                .onTapGesture {
                    if reduceMotion {
                        configuration.isOn.toggle()
                    } else {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.65)) {
                            configuration.isOn.toggle()
                        }
                    }
                }
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(Rectangle())
                .onHover { hovering in
                    guard isEnabled else { return }
                    isHovered = hovering
                }
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
                .fill(FabricColors.parchment)
                .frame(width: FabricSpacing.toggleThumb, height: FabricSpacing.toggleThumb)
                // Double shadow on thumb for tactile feel
                .shadow(color: FabricColors.shadowTight, radius: 0.5, x: 0, y: 0.5)
                .shadow(color: FabricColors.shadow, radius: 3, x: 0, y: 2)
                .padding(.horizontal, 3)
        }
    }

    private func trackFill(isOn: Bool) -> Color {
        if isOn {
            return isHovered ? FabricColors.indigo.opacity(0.38) : FabricColors.indigo.opacity(0.30)
        } else {
            return isHovered ? FabricColors.burlap.opacity(0.38) : FabricColors.burlap.opacity(0.30)
        }
    }
}

extension ToggleStyle where Self == FabricToggleStyle {
    static var fabric: FabricToggleStyle { .init() }
}

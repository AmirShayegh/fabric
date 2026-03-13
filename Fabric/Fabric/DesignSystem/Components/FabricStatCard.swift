import SwiftUI

struct FabricStatCard: View {

    let value: String
    let label: String
    let accent: FabricAccent?
    let tinted: Bool

    init(
        value: String,
        label: String,
        accent: FabricAccent? = nil,
        tinted: Bool = false
    ) {
        self.value = value
        self.label = label
        self.accent = accent
        self.tinted = tinted
    }

    var body: some View {
        FabricCard {
            VStack(alignment: .leading, spacing: FabricSpacing.xs) {
                Text(value)
                    .fabricTypography(.display)
                    .foregroundStyle(accent?.foreground ?? FabricColors.inkPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)

                Text(label)
                    .fabricCaption()
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                if tinted, let accent {
                    FabricSpacing.shape(radius: FabricSpacing.radiusSm)
                        .fill(accent.fill)
                        .padding(-FabricSpacing.sm)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label): \(value)")
    }
}

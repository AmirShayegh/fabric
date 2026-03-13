import SwiftUI

struct FabricStatusDot: View {

    let accent: FabricAccent?
    let label: String?

    init(accent: FabricAccent? = nil, label: String? = nil) {
        self.accent = accent
        self.label = label
    }

    var body: some View {
        Circle()
            .fill(accent?.foreground ?? FabricColors.inkTertiary)
            .frame(width: FabricSpacing.statusDotSize, height: FabricSpacing.statusDotSize)
            .shadow(color: FabricColors.shadowTight, radius: 0.3, x: 0, y: 0.3)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(label ?? "")
            .accessibilityHidden(label == nil)
            .accessibilityAddTraits(label != nil ? .isStaticText : [])
    }
}

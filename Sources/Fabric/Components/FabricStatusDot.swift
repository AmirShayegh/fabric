import SwiftUI

public struct FabricStatusDot: View {

    public let accent: FabricAccent?
    public let label: String?

    public init(accent: FabricAccent? = nil, label: String? = nil) {
        self.accent = accent
        self.label = label
    }

    private var effectiveLabel: String? {
        guard let label, !label.trimmingCharacters(in: .whitespaces).isEmpty else { return nil }
        return label
    }

    public var body: some View {
        Circle()
            .fill(accent?.foreground ?? FabricColors.inkTertiary)
            .frame(width: FabricSpacing.statusDotSize, height: FabricSpacing.statusDotSize)
            .fabricShadow(.micro)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(effectiveLabel ?? "")
            .accessibilityHidden(effectiveLabel == nil)
            .accessibilityAddTraits(effectiveLabel != nil ? .isStaticText : [])
    }
}

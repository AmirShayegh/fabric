import SwiftUI

enum FabricAccent: CaseIterable {
    case indigo, madder, sage, ochre

    /// Full-strength foreground for text and icons
    var foreground: Color {
        switch self {
        case .indigo: FabricColors.indigo
        case .madder: FabricColors.madder
        case .sage:   FabricColors.sage
        case .ochre:  FabricColors.ochre
        }
    }

    /// Low-opacity fill for chip/badge/tag backgrounds.
    /// Opacity tuned per hue to maintain readable contrast with foreground text.
    var fill: Color {
        switch self {
        case .indigo: FabricColors.indigo.opacity(0.12)
        case .madder: FabricColors.madder.opacity(0.12)
        case .sage:   FabricColors.sage.opacity(0.14)
        case .ochre:  FabricColors.ochre.opacity(0.12)
        }
    }
}

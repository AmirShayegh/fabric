import SwiftUI

enum FabricAccent: CaseIterable {
    case indigo, madder, sage, ochre

    /// Full-strength foreground for text and icons
    var foreground: Color {
        switch self {
        case .indigo: return FabricColors.indigo
        case .madder: return FabricColors.madder
        case .sage:   return FabricColors.sage
        case .ochre:  return FabricColors.ochre
        }
    }

    /// Low-opacity fill for chip/badge/tag backgrounds.
    /// Opacity tuned per hue to maintain readable contrast with foreground text.
    var fill: Color {
        switch self {
        case .indigo: return FabricColors.indigo.opacity(0.12)
        case .madder: return FabricColors.madder.opacity(0.12)
        case .sage:   return FabricColors.sage.opacity(0.14)
        case .ochre:  return FabricColors.ochre.opacity(0.12)
        }
    }
}

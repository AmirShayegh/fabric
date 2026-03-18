import SwiftUI

public enum FabricAccent: CaseIterable {
    case indigo, madder, sage, ochre

    /// Full-strength foreground for text and icons
    public var foreground: Color {
        switch self {
        case .indigo: FabricColors.indigo
        case .madder: FabricColors.madder
        case .sage:   FabricColors.sage
        case .ochre:  FabricColors.ochre
        }
    }

    /// Low-opacity fill for chip/badge/tag backgrounds.
    /// Opacity tuned per hue to maintain readable contrast with foreground text.
    public var fill: Color {
        switch self {
        case .indigo: FabricColors.indigo.opacity(0.12)
        case .madder: FabricColors.madder.opacity(0.12)
        case .sage:   FabricColors.sage.opacity(0.14)
        case .ochre:  FabricColors.ochre.opacity(0.12)
        }
    }

    /// Opaque button fill — darker than `foreground` to guarantee WCAG AA
    /// contrast against `onPrimary` text on both light and dark backgrounds.
    public var buttonFill: Color {
        switch self {
        case .indigo: FabricColors.buttonPrimary
        case .madder: FabricColors.buttonMadder
        case .sage:   FabricColors.buttonSage
        case .ochre:  FabricColors.buttonOchre
        }
    }

    /// Hovered button fill — slightly darker than `buttonFill`.
    public var buttonFillHovered: Color {
        switch self {
        case .indigo: FabricColors.buttonPrimaryHovered
        case .madder: FabricColors.buttonMadderHovered
        case .sage:   FabricColors.buttonSageHovered
        case .ochre:  FabricColors.buttonOchreHovered
        }
    }

    /// Pressed button fill — darkest interactive state.
    public var buttonFillPressed: Color {
        switch self {
        case .indigo: FabricColors.buttonPrimaryPressed
        case .madder: FabricColors.buttonMadderPressed
        case .sage:   FabricColors.buttonSagePressed
        case .ochre:  FabricColors.buttonOchrePressed
        }
    }
}

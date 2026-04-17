import SwiftUI

public enum FabricAccent: CaseIterable {
    case indigo, madder, sage, ochre, thread, moss, rust

    /// Full-strength foreground for text and icons
    public var foreground: Color {
        switch self {
        case .indigo: FabricColors.indigo
        case .madder: FabricColors.madder
        case .sage:   FabricColors.sage
        case .ochre:  FabricColors.ochre
        case .thread: FabricColors.thread
        case .moss:   FabricColors.moss
        case .rust:   FabricColors.rust
        }
    }

    /// Low-opacity fill for chip/badge/tag backgrounds.
    /// Opacity tuned per hue to maintain readable contrast with `textOnFill`.
    public var fill: Color {
        switch self {
        case .indigo: FabricColors.indigo.opacity(0.12)
        case .madder: FabricColors.madder.opacity(0.12)
        case .sage:   FabricColors.sage.opacity(0.14)
        case .ochre:  FabricColors.ochre.opacity(0.12)
        case .thread: FabricColors.thread.opacity(0.12)
        case .moss:   FabricColors.moss.opacity(0.14)
        case .rust:   FabricColors.rust.opacity(0.12)
        }
    }

    /// Darker, hue-matched accent for **text/icon content sitting on `fill`**.
    /// Low-saturation accents (ochre, sage, moss) don't have enough contrast
    /// when `foreground` is used over their own 12–14% wash — this variant
    /// drops brightness to restore readable contrast (WCAG 1.4.3 body-text
    /// target) while keeping the accent identity.
    public var textOnFill: Color { buttonFill }

    /// Opaque button fill — darker than `foreground` to guarantee WCAG AA
    /// contrast against `onPrimary` text on both light and dark backgrounds.
    public var buttonFill: Color {
        switch self {
        case .indigo: FabricColors.buttonPrimary
        case .madder: FabricColors.buttonMadder
        case .sage:   FabricColors.buttonSage
        case .ochre:  FabricColors.buttonOchre
        case .thread: FabricColors.buttonThread
        case .moss:   FabricColors.buttonMoss
        case .rust:   FabricColors.buttonRust
        }
    }

    /// Hovered button fill — slightly darker than `buttonFill`.
    public var buttonFillHovered: Color {
        switch self {
        case .indigo: FabricColors.buttonPrimaryHovered
        case .madder: FabricColors.buttonMadderHovered
        case .sage:   FabricColors.buttonSageHovered
        case .ochre:  FabricColors.buttonOchreHovered
        case .thread: FabricColors.buttonThreadHovered
        case .moss:   FabricColors.buttonMossHovered
        case .rust:   FabricColors.buttonRustHovered
        }
    }

    /// Pressed button fill — darkest interactive state.
    public var buttonFillPressed: Color {
        switch self {
        case .indigo: FabricColors.buttonPrimaryPressed
        case .madder: FabricColors.buttonMadderPressed
        case .sage:   FabricColors.buttonSagePressed
        case .ochre:  FabricColors.buttonOchrePressed
        case .thread: FabricColors.buttonThreadPressed
        case .moss:   FabricColors.buttonMossPressed
        case .rust:   FabricColors.buttonRustPressed
        }
    }
}

import SwiftUI

public enum FabricAccent: CaseIterable, Sendable {
    case indigo, madder, sage, ochre, thread, moss, rust
    // Editorial palette cases (v1.4.0). Route through hex-keyed
    // `FabricColors.editorial*` tokens sampled from the designer's source
    // of truth rather than the HSB-derived legacy accents above. Use these
    // anywhere chrome needs to match the web's editorial rendering exactly
    // (tags, pills, badges, chips).
    case editorialOchre, editorialThread, editorialMoss, editorialRust, editorialRed
    case editorialAmber, editorialPlum

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
        case .editorialOchre:  FabricColors.editorialOchre
        case .editorialThread: FabricColors.editorialThread
        case .editorialMoss:   FabricColors.editorialMoss
        case .editorialRust:   FabricColors.editorialRust
        case .editorialRed:    FabricColors.editorialRed
        case .editorialAmber:  FabricColors.editorialAmber
        case .editorialPlum:   FabricColors.editorialPlum
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
        case .editorialOchre:  FabricColors.editorialOchre.opacity(0.12)
        case .editorialThread: FabricColors.editorialThread.opacity(0.12)
        case .editorialMoss:   FabricColors.editorialMoss.opacity(0.14)
        case .editorialRust:   FabricColors.editorialRust.opacity(0.12)
        case .editorialRed:    FabricColors.editorialRed.opacity(0.12)
        case .editorialAmber:  FabricColors.editorialAmber.opacity(0.12)
        case .editorialPlum:   FabricColors.editorialPlum.opacity(0.14)
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
    ///
    /// Editorial cases route through the closest legacy button ramp until a
    /// dedicated editorial button ramp exists; this keeps press states
    /// working on buttons that consume editorial accents, at the cost of a
    /// slight hue mismatch between the foreground and the pressed fill.
    public var buttonFill: Color {
        switch self {
        case .indigo: FabricColors.buttonPrimary
        case .madder: FabricColors.buttonMadder
        case .sage:   FabricColors.buttonSage
        case .ochre:  FabricColors.buttonOchre
        case .thread: FabricColors.buttonThread
        case .moss:   FabricColors.buttonMoss
        case .rust:   FabricColors.buttonRust
        case .editorialOchre:  FabricColors.editorialOchreDeep
        case .editorialThread: FabricColors.buttonThread
        case .editorialMoss:   FabricColors.buttonMoss
        case .editorialRust:   FabricColors.buttonRust
        case .editorialRed:    FabricColors.buttonMadder
        case .editorialAmber:  FabricColors.buttonOchre
        case .editorialPlum:   FabricColors.buttonMoss
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
        case .editorialOchre:  FabricColors.buttonOchreHovered
        case .editorialThread: FabricColors.buttonThreadHovered
        case .editorialMoss:   FabricColors.buttonMossHovered
        case .editorialRust:   FabricColors.buttonRustHovered
        case .editorialRed:    FabricColors.buttonMadderHovered
        case .editorialAmber:  FabricColors.buttonOchreHovered
        case .editorialPlum:   FabricColors.buttonMossHovered
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
        case .editorialOchre:  FabricColors.buttonOchrePressed
        case .editorialThread: FabricColors.buttonThreadPressed
        case .editorialMoss:   FabricColors.buttonMossPressed
        case .editorialRust:   FabricColors.buttonRustPressed
        case .editorialRed:    FabricColors.buttonMadderPressed
        case .editorialAmber:  FabricColors.buttonOchrePressed
        case .editorialPlum:   FabricColors.buttonMossPressed
        }
    }
}

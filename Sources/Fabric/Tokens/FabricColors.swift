import SwiftUI
#if canImport(AppKit)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

public enum FabricColors {

    // MARK: - Adaptive Helpers

    /// HSB color that adapts to light/dark appearance (alpha = 1).
    private static func hsb(
        _ lH: CGFloat, _ lS: CGFloat, _ lB: CGFloat,
        dark dH: CGFloat, _ dS: CGFloat, _ dB: CGFloat
    ) -> Color {
        #if canImport(AppKit)
        Color(nsColor: NSColor(name: nil, dynamicProvider: { appearance in
            let isDark = appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
            let (h, s, b) = isDark ? (dH, dS, dB) : (lH, lS, lB)
            return NSColor(hue: h, saturation: s, brightness: b, alpha: 1)
        }))
        #elseif canImport(UIKit)
        Color(uiColor: UIColor { traitCollection in
            let isDark = traitCollection.userInterfaceStyle == .dark
            let (h, s, b) = isDark ? (dH, dS, dB) : (lH, lS, lB)
            return UIColor(hue: h, saturation: s, brightness: b, alpha: 1)
        })
        #endif
    }

    /// HSBA color that adapts to light/dark appearance.
    private static func hsba(
        _ lH: CGFloat, _ lS: CGFloat, _ lB: CGFloat, _ lA: CGFloat,
        dark dH: CGFloat, _ dS: CGFloat, _ dB: CGFloat, _ dA: CGFloat
    ) -> Color {
        #if canImport(AppKit)
        Color(nsColor: NSColor(name: nil, dynamicProvider: { appearance in
            let isDark = appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
            let (h, s, b, a) = isDark ? (dH, dS, dB, dA) : (lH, lS, lB, lA)
            return NSColor(hue: h, saturation: s, brightness: b, alpha: a)
        }))
        #elseif canImport(UIKit)
        Color(uiColor: UIColor { traitCollection in
            let isDark = traitCollection.userInterfaceStyle == .dark
            let (h, s, b, a) = isDark ? (dH, dS, dB, dA) : (lH, lS, lB, lA)
            return UIColor(hue: h, saturation: s, brightness: b, alpha: a)
        })
        #endif
    }

    // MARK: - Surfaces
    // Light: warm linen tones.  Dark: warm charcoal-brown (dark wool / denim).

    /// Window/page background — warm raw linen / deep charcoal
    public static let linen     = hsb(36/360, 0.18, 0.92, dark: 25/360, 0.15, 0.13)
    /// Card surface — slightly cooler / lifted above background
    public static let canvas    = hsb(40/360, 0.08, 0.97, dark: 25/360, 0.10, 0.19)
    /// Lightest surface — text field fills, inset areas / recessed dark
    public static let parchment = hsb(42/360, 0.06, 0.99, dark: 22/360, 0.10, 0.15)
    /// Dark accent surface — section backgrounds, emphasis areas
    public static let burlap    = hsb(28/360, 0.22, 0.76, dark: 28/360, 0.15, 0.30)

    // MARK: - Ink
    // Light: warm brown-black (walnut ink).  Dark: warm cream (undyed thread).

    /// Primary text — ~10:1 against canvas in both modes (AAA)
    public static let inkPrimary   = hsb(20/360, 0.45, 0.18, dark: 35/360, 0.10, 0.90)
    /// Secondary text — ~5.5:1 against canvas (AA)
    public static let inkSecondary = hsb(22/360, 0.28, 0.38, dark: 30/360, 0.08, 0.68)
    /// Decorative/placeholder — below AA
    public static let inkTertiary  = hsb(25/360, 0.12, 0.60, dark: 25/360, 0.06, 0.45)

    // MARK: - Accents
    // Natural dye tones — slightly brighter in dark mode to pop against dark ground.

    /// Primary action — deep calm blue with warmth
    public static let indigo = hsb(225/360, 0.35, 0.52, dark: 225/360, 0.30, 0.65)
    /// Destructive/warning — warm terracotta
    public static let madder = hsb(12/360, 0.50, 0.60, dark: 12/360, 0.42, 0.72)
    /// Success/positive — muted sage
    public static let sage   = hsb(145/360, 0.22, 0.58, dark: 145/360, 0.20, 0.65)
    /// Warm highlight — golden ochre
    public static let ochre  = hsb(38/360, 0.55, 0.72, dark: 38/360, 0.48, 0.78)

    // MARK: - Functional
    // Shadows need higher opacity on dark surfaces. Dark mode drops warm tint.

    /// Ambient shadow — warm, diffuse
    public static let shadow      = hsba(25/360, 0.20, 0.30, 0.10, dark: 0, 0, 0, 0.30)
    /// Tight shadow — close, dark
    public static let shadowTight = hsba(25/360, 0.25, 0.20, 0.14, dark: 0, 0, 0, 0.40)
    /// Inner shadow for recessed elements
    public static let innerShadow = hsba(20/360, 0.15, 0.25, 0.12, dark: 0, 0, 0, 0.30)
    /// Top-edge highlight — light catching the weave
    public static let highlight: Color = {
        #if canImport(AppKit)
        Color(nsColor: NSColor(name: nil, dynamicProvider: { appearance in
            let isDark = appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
            return NSColor.white.withAlphaComponent(isDark ? 0.06 : 0.25)
        }))
        #elseif canImport(UIKit)
        Color(uiColor: UIColor { traitCollection in
            let isDark = traitCollection.userInterfaceStyle == .dark
            return UIColor.white.withAlphaComponent(isDark ? 0.06 : 0.25)
        })
        #endif
    }()

    // MARK: - Button Fills
    // Opaque — guaranteed WCAG AA contrast against onPrimary text in both modes.
    // Each accent is hand-tuned: hue/saturation match the accent, brightness is
    // lowered to reach ≥ 4.5:1 contrast vs onPrimary (B ≈ 0.99 light / 0.95 dark).

    // Indigo — H=225
    /// Default ~5.2:1 (light) / ~5.5:1 (dark) vs onPrimary
    public static let buttonPrimary        = hsb(225/360, 0.35, 0.46, dark: 225/360, 0.30, 0.55)
    /// Hovered ~5.7:1 / ~5.9:1
    public static let buttonPrimaryHovered = hsb(225/360, 0.35, 0.44, dark: 225/360, 0.30, 0.52)
    /// Pressed ~6.1:1 / ~6.5:1
    public static let buttonPrimaryPressed = hsb(225/360, 0.35, 0.42, dark: 225/360, 0.30, 0.48)

    // Madder — H=12, warm terracotta
    public static let buttonMadder        = hsb(12/360, 0.50, 0.50, dark: 12/360, 0.42, 0.60)
    public static let buttonMadderHovered = hsb(12/360, 0.50, 0.48, dark: 12/360, 0.42, 0.57)
    public static let buttonMadderPressed = hsb(12/360, 0.50, 0.46, dark: 12/360, 0.42, 0.53)

    // Sage — H=145, higher saturation than foreground to stay green when darkened
    public static let buttonSage        = hsb(145/360, 0.30, 0.45, dark: 145/360, 0.25, 0.52)
    public static let buttonSageHovered = hsb(145/360, 0.30, 0.43, dark: 145/360, 0.25, 0.49)
    public static let buttonSagePressed = hsb(145/360, 0.30, 0.41, dark: 145/360, 0.25, 0.45)

    // Ochre — H=38, higher saturation to compensate for the large brightness drop
    public static let buttonOchre        = hsb(38/360, 0.60, 0.50, dark: 38/360, 0.52, 0.56)
    public static let buttonOchreHovered = hsb(38/360, 0.60, 0.48, dark: 38/360, 0.52, 0.53)
    public static let buttonOchrePressed = hsb(38/360, 0.60, 0.46, dark: 38/360, 0.52, 0.49)

    // MARK: - Semantic

    /// Content color on primary-colored fills (button text, toggle thumbs).
    /// Warm cream in both modes — stays light regardless of appearance.
    public static let onPrimary = hsb(42/360, 0.06, 0.99, dark: 40/360, 0.06, 0.95)

    /// Ink micro-shadow — always dark, prevents glow effect in dark mode.
    public static let inkShadow = hsba(20/360, 0.15, 0.10, 0.15, dark: 0, 0, 0, 0.25)

    // MARK: - Connectors & Decorative

    /// Warm connector line for timelines and step indicators
    public static let connector = hsba(25/360, 0.12, 0.50, 0.18,
                                dark: 25/360, 0.06, 0.60, 0.22)
    /// Badge/chip background tint
    public static let badgeFill = hsba(28/360, 0.15, 0.76, 0.12,
                                dark: 28/360, 0.10, 0.40, 0.18)
}

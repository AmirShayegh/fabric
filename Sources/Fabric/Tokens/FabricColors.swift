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

    /// sRGB color keyed by 24-bit hex literals -- for tokens sampled directly
    /// from a designer's source of truth (e.g. CSS hex codes). Unlike `hsb`,
    /// this is lossless round-trip against the source hex.
    private static func hex(_ light: UInt32, dark: UInt32) -> Color {
        #if canImport(AppKit)
        Color(nsColor: NSColor(name: nil, dynamicProvider: { appearance in
            let isDark = appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
            let v = isDark ? dark : light
            return NSColor(
                srgbRed: CGFloat((v >> 16) & 0xFF) / 255.0,
                green: CGFloat((v >> 8) & 0xFF) / 255.0,
                blue: CGFloat(v & 0xFF) / 255.0,
                alpha: 1.0
            )
        }))
        #elseif canImport(UIKit)
        Color(uiColor: UIColor { traitCollection in
            let isDark = traitCollection.userInterfaceStyle == .dark
            let v = isDark ? dark : light
            return UIColor(
                red: CGFloat((v >> 16) & 0xFF) / 255.0,
                green: CGFloat((v >> 8) & 0xFF) / 255.0,
                blue: CGFloat(v & 0xFF) / 255.0,
                alpha: 1.0
            )
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

    /// Primary text — ~10:1 against canvas in both modes (AAA).
    /// Dark is a warm cream (undyed thread) matching the editorial palette.
    public static let inkPrimary   = hsb(20/360, 0.45, 0.18, dark: 40/360, 0.08, 0.96)
    /// Soft primary — editorial reading contexts where primary feels too stark (~8:1)
    public static let inkSoft      = hsb(22/360, 0.38, 0.24, dark: 40/360, 0.16, 0.87)
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
    /// Warm highlight — golden ochre. Mirrors web `--fabric-ochre` in both modes.
    public static let ochre  = hsb(38/360, 0.55, 0.72, dark: 38/360, 0.48, 0.78)
    /// Editorial emphasis — warm cinnamon/terracotta thread.
    /// Dark shifts to a warmer peach for readability on deep warm surfaces.
    public static let thread = hsb(23/360, 0.57, 0.55, dark: 19/360, 0.47, 0.77)
    /// Editorial — muted moss green. Hue warms slightly (82°→76°) in dark mode
    /// because the web source hex codes differ across modes.
    public static let moss   = hsb(82/360, 0.31, 0.42, dark: 76/360, 0.31, 0.59)
    /// Editorial — warm rust. Brighter editorial cousin of madder
    /// (which stays semantic/destructive).
    public static let rust   = hsb(16/360, 0.73, 0.66, dark: 15/360, 0.63, 0.78)

    // MARK: - Editorial Palette
    // Designer-sampled hex literals, in sync with CPM's `web/src/app/globals.css`
    // (light block + `@media (prefers-color-scheme: dark)`). Additive: these are
    // for surfaces that need to speak the editorial palette across web/Mac/iOS.
    // Existing HSB accents above stay put for non-editorial chrome.

    // Surfaces and ink
    /// Editorial primary text color (walnut ink light / cream dark).
    public static let editorialInk           = hex(0x1C1A17, dark: 0xF4EDE0)
    /// Editorial soft ink for long-form reading body.
    public static let editorialInkSoft       = hex(0x2B2722, dark: 0xDFD3BA)
    /// Editorial page/parchment background.
    public static let editorialParchment     = hex(0xF4EDE0, dark: 0x1C1A17)
    /// Editorial deeper parchment -- section bands, emphasized surfaces.
    public static let editorialParchmentDeep = hex(0xEADFC9, dark: 0x26221E)
    /// Editorial dim parchment -- muted panels and trays.
    public static let editorialParchmentDim  = hex(0xDFD3BA, dark: 0x2B2722)

    // Accents
    /// Editorial ochre -- warm attention / active highlight.
    public static let editorialOchre         = hex(0xC48A3E, dark: 0xD9A055)
    /// Editorial deep ochre -- pressed/hover, darker ochre variants.
    public static let editorialOchreDeep     = hex(0x9A6A2C, dark: 0xBD8338)
    /// Editorial thread -- brand umber. Canonical brand hex.
    public static let editorialThread        = hex(0x905830, dark: 0xC48568)
    /// Editorial moss -- editorial green emphasis.
    public static let editorialMoss          = hex(0x5F6B4A, dark: 0x8A9668)
    /// Editorial rust -- editorial red emphasis.
    public static let editorialRust          = hex(0xA84F2E, dark: 0xC76A4A)
    /// Editorial red -- higher-saturation crimson for critical/severe
    /// emphasis. Distinct from rust (more orange) and madder (browner).
    public static let editorialRed           = hex(0xB8342E, dark: 0xD05449)
    /// Editorial amber -- brighter warm amber between ochre and rust.
    /// For attention/warning tags that shouldn't read as pure gold.
    public static let editorialAmber         = hex(0xD98E3A, dark: 0xE6A658)
    /// Editorial plum -- muted warm-purple-brown. A cool-leaning warm
    /// that differentiates subtle chrome (phase tags, meta annotations)
    /// without leaving the editorial family.
    public static let editorialPlum          = hex(0x6B4A5F, dark: 0x8F6A83)

    // Cold surfaces (distinct ".cold" theme in web, used sparingly)
    /// Editorial cold background -- cooler counterpart to parchment.
    public static let editorialColdBg        = hex(0xE4E2DD, dark: 0x2A2D31)
    /// Editorial cold ink -- counterpart ink on cold surfaces.
    public static let editorialColdInk       = hex(0x3B3E42, dark: 0xD1D3D6)

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
    // Opaque — hand-tuned to hold WCAG 2.1 §1.4.11 non-text contrast (3:1) for
    // UI components against the surrounding surface, and to keep onPrimary
    // (cream) labels legible on top. Buttons are governed by 1.4.11 (3:1), not
    // 1.4.3 body text (4.5:1); individual ramps land between ~3.8:1 and ~5.5:1
    // depending on accent hue/saturation.
    //
    // Each accent: hue/saturation match the foreground, brightness is lowered
    // to darken the fill (B ≈ 0.99 light / 0.95 dark for onPrimary).
    // Hovered/pressed progressively drop brightness by ~2 points per state.

    // Indigo — H=225
    public static let buttonPrimary        = hsb(225/360, 0.35, 0.46, dark: 225/360, 0.30, 0.55)
    public static let buttonPrimaryHovered = hsb(225/360, 0.35, 0.44, dark: 225/360, 0.30, 0.52)
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

    // Thread — H=23, warm cinnamon. Darker than foreground to reach AA on onPrimary.
    public static let buttonThread        = hsb(23/360, 0.60, 0.44, dark: 23/360, 0.50, 0.55)
    public static let buttonThreadHovered = hsb(23/360, 0.60, 0.42, dark: 23/360, 0.50, 0.52)
    public static let buttonThreadPressed = hsb(23/360, 0.60, 0.40, dark: 23/360, 0.50, 0.48)

    // Moss — H=82 light / 76 dark. Darker than foreground to hold contrast on onPrimary cream.
    public static let buttonMoss        = hsb(82/360, 0.35, 0.34, dark: 76/360, 0.30, 0.45)
    public static let buttonMossHovered = hsb(82/360, 0.35, 0.32, dark: 76/360, 0.30, 0.42)
    public static let buttonMossPressed = hsb(82/360, 0.35, 0.30, dark: 76/360, 0.30, 0.39)

    // Rust — H=16 light / 15 dark. Foreground is bright; button ramp drops hard.
    public static let buttonRust        = hsb(16/360, 0.70, 0.50, dark: 15/360, 0.55, 0.60)
    public static let buttonRustHovered = hsb(16/360, 0.70, 0.47, dark: 15/360, 0.55, 0.57)
    public static let buttonRustPressed = hsb(16/360, 0.70, 0.44, dark: 15/360, 0.55, 0.53)

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
    /// Editorial thread-colored connector — for dotted dividers in long-form lists
    public static let connectorThread = hsba(23/360, 0.57, 0.55, 0.32,
                                       dark: 19/360, 0.47, 0.77, 0.38)
    /// Badge/chip background tint
    public static let badgeFill = hsba(28/360, 0.15, 0.76, 0.12,
                                dark: 28/360, 0.10, 0.40, 0.18)
}

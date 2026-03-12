import SwiftUI

enum FabricColors {

    // MARK: - Surfaces
    // Wider value spread between layers for visible depth

    /// Window/page background — warm raw linen
    static let linen     = Color(hue: 36/360, saturation: 0.18, brightness: 0.92)
    /// Card surface — slightly cooler, clearly distinct from linen
    static let canvas    = Color(hue: 40/360, saturation: 0.08, brightness: 0.97)
    /// Lightest surface — text field fills, inset areas
    static let parchment = Color(hue: 42/360, saturation: 0.06, brightness: 0.99)
    /// Dark accent surface — section backgrounds, emphasis areas
    static let burlap    = Color(hue: 28/360, saturation: 0.22, brightness: 0.76)

    // MARK: - Ink
    // Warm brown-black family — like walnut ink on cloth

    /// Primary text — deep warm brown, ~10:1 against canvas (AAA)
    static let inkPrimary   = Color(hue: 20/360, saturation: 0.45, brightness: 0.18)
    /// Secondary text — ~5.5:1 against canvas (AA)
    static let inkSecondary = Color(hue: 22/360, saturation: 0.28, brightness: 0.38)
    /// Decorative/placeholder — below AA
    static let inkTertiary  = Color(hue: 25/360, saturation: 0.12, brightness: 0.60)

    // MARK: - Accents
    // Natural dye tones — richer and more alive

    /// Primary action — deep calm blue with warmth
    static let indigo = Color(hue: 225/360, saturation: 0.35, brightness: 0.52)
    /// Destructive/warning — warm terracotta
    static let madder = Color(hue: 12/360,  saturation: 0.50, brightness: 0.60)
    /// Success/positive — muted sage
    static let sage   = Color(hue: 145/360, saturation: 0.22, brightness: 0.58)
    /// Warm highlight — golden ochre
    static let ochre  = Color(hue: 38/360,  saturation: 0.55, brightness: 0.72)

    // MARK: - Functional
    // Warm shadows — not cold gray, but tinted like real cloth shadows

    /// Ambient shadow — warm, diffuse
    static let shadow      = Color(hue: 25/360, saturation: 0.20, brightness: 0.30).opacity(0.10)
    /// Tight shadow — close, dark
    static let shadowTight = Color(hue: 25/360, saturation: 0.25, brightness: 0.20).opacity(0.14)
    /// Inner shadow for recessed elements
    static let innerShadow = Color(hue: 20/360, saturation: 0.15, brightness: 0.25).opacity(0.12)
    /// Top-edge highlight — light catching the weave
    static let highlight   = Color.white.opacity(0.25)
}

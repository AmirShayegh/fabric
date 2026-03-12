# Fabric Design System

A textile-inspired SwiftUI design system for macOS. The aesthetic is **implied, not literal** — no stitching, no cross-stitch, no overt textile references. Instead: barely-perceptible woven texture, warm muted colors, text that feels absorbed into the surface, and buttons that press in softly like cloth.

## Project Structure

```
Fabric/Fabric/
├── FabricApp.swift                          — App entry point (@main, WindowGroup)
├── ContentView.swift                        — Loads ShowcaseView
├── DesignSystem/
│   ├── Tokens/
│   │   ├── FabricColors.swift               — HSB color palette, warm shadows, button fills
│   │   ├── FabricTypography.swift           — Text styles as composable ViewModifiers
│   │   └── FabricSpacing.swift              — Spacing scale, continuous corner shapes
│   ├── Texture/
│   │   └── TextureGenerator.swift           — CGContext bitmap noise with weave modulation
│   ├── Modifiers/
│   │   ├── InnerShadowModifier.swift        — .innerShadow() via stroke+shadow+clipShape
│   │   └── FabricSurfaceModifier.swift      — .fabricSurface() tiled texture background
│   └── Components/
│       ├── FabricButtonStyle.swift           — ButtonStyle, 3 variants (primary/secondary/ghost)
│       ├── FabricCard.swift                  — Generic card container with texture + shadow
│       ├── FabricTextField.swift             — Recessed text field with a11y label
│       └── FabricToggleStyle.swift           — Custom toggle with capsule track
└── Demo/
    └── ShowcaseView.swift                   — Component gallery
```

## Build

```bash
xcodebuild -project Fabric/Fabric.xcodeproj -scheme Fabric -destination 'platform=macOS' build
```

- macOS deployment target: 26.1
- Swift 5.0, Xcode 26.3
- No external dependencies
- Filesystem-synced groups — new .swift files are auto-discovered by Xcode

## Architecture Patterns

### Design Tokens
All visual values flow through three token enums: `FabricColors`, `FabricTypography`, `FabricSpacing`. Components should never hardcode colors or font sizes directly.

### Typography is Modifier-Based
Text styling uses composable `ViewModifier`s, not wrapper views:
- `.fabricTypography(.title)` — font + tracking + line spacing
- `.fabricInk(.primary)` — color + micro-shadow
- `.fabricTitle()` — convenience combining both

### ButtonStyle / ToggleStyle Pattern
Interactive components use native SwiftUI style protocols. The style struct is a **pure configuration carrier** — it delegates to a private nested `View` that owns `@State` (e.g., `FabricButtonBody`, `FabricToggleBody`). This prevents hover state from resetting when SwiftUI recreates style structs.

### Texture Generation
`TextureGenerator` produces a 64×64pt tileable noise tile via `CGContext` bitmap, cached by `(pixelSize, intensity, seed)` in `NSCache` with 4MB limit. The `FabricSurfaceModifier` reads `@Environment(\.displayScale)` to regenerate when moving between displays.

### Inner Shadow
`.innerShadow()` uses the stroke+shadow+clipShape technique (no `blur()` + `mask()`).

### Continuous Corners
All rounded shapes use `RoundedRectangle(cornerRadius:style:.continuous)` via `FabricSpacing.shape(radius:)`.

## Design Decisions

- **Light theme only** — dark mode is not yet implemented. All colors are fixed HSB values.
- **Warm shadows** — shadows are tinted (hue 25, saturation 0.20) not cold gray/black.
- **Double shadows** on elevated elements: tight contact shadow + wide ambient shadow.
- **Primary button fills are opaque** — no `.opacity()` to ensure consistent WCAG contrast.
- **Focus ring** uses `Color(nsColor: .keyboardFocusIndicatorColor)` for system compliance.
- **Toggle tap target** is the full label+track row, not just the track.

## Known Gaps / Next Steps

- **Dark mode**: Colors need `colorScheme`-aware variants
- **Elevation tokens**: Shadow values are inline; should be systematized
- **Magic numbers**: Some animation scales, stroke widths, texture intensities are hardcoded in components
- **TextField error state**: No visual error treatment yet
- **Responsive layout**: ShowcaseView doesn't reflow on narrow windows
- **macOS HIG**: No context menus, no keyboard shortcuts on Cancel buttons

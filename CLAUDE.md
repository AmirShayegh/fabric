# Fabric Design System

A textile-inspired SwiftUI design system for macOS and iOS. The aesthetic is **implied, not literal** — no stitching, no cross-stitch, no overt textile references. Instead: barely-perceptible woven texture, warm muted colors, text that feels absorbed into the surface, and buttons that press in softly like cloth.

### Pebbles on Fabric

The design metaphor is **pebbles on fabric**:

- **Fabric** = surface layer (linen texture, recessed elements, inner shadows, warm neutrals). Text fields, kanban columns, and skeleton placeholders are _recessed into_ the fabric.
- **Pebbles** = objects resting on the surface (buttons, cards, badges, pills, dots). They are elevated, casting warm double shadows. They have a subtle top-edge highlight where light catches the surface.
- **Text** = ink absorbed into the fabric. It sits flat — neither recessed nor elevated. Micro-shadow gives it a "wicked into fibers" look.

Consuming apps map their own domain semantics to the four accent colors: sage, ochre, madder, indigo.

## Project Structure

```
fabric/
├── Package.swift                             — SPM manifest (macOS 14+, iOS 17+)
├── Sources/Fabric/
│   ├── Tokens/
│   │   ├── FabricColors.swift                — HSB color palette, dark mode via dynamic providers
│   │   ├── FabricTypography.swift            — Text styles as composable ViewModifiers
│   │   ├── FabricSpacing.swift               — Spacing scale, continuous corner shapes
│   │   ├── FabricAnimation.swift             — Animation presets (press/soft/hover/lift)
│   │   ├── FabricAccent.swift                — Four accent colors (indigo/sage/ochre/madder)
│   │   └── FabricElevation.swift             — Shadow geometry tokens (outer + inner)
│   ├── Texture/
│   │   └── TextureGenerator.swift            — CGContext bitmap noise with weave modulation
│   ├── Modifiers/
│   │   ├── InnerShadowModifier.swift         — .innerShadow() via stroke+shadow+clipShape
│   │   └── FabricSurfaceModifier.swift       — .fabricSurface() tiled texture background
│   └── Components/
│       ├── FabricButtonStyle.swift            — ButtonStyle, 3 variants (primary/secondary/ghost)
│       ├── FabricCard.swift                   — Generic card container with texture + shadow
│       ├── FabricTextField.swift              — Recessed text field with error state
│       ├── FabricToggleStyle.swift            — Custom toggle with capsule track
│       ├── FabricBadge.swift                  — Capsule badge (non-interactive)
│       ├── FabricPill.swift                   — Rounded-rect label pebble (non-interactive)
│       ├── FabricStatusDot.swift              — Tiny colored circle pebble
│       ├── FabricStatCard.swift               — Data display card (composes FabricCard)
│       ├── FabricEmptyState.swift             — Centered placeholder watermark
│       ├── FabricChip.swift                   — Interactive chip with hover + optional remove
│       ├── FabricTaskCard.swift               — Draggable task card with tags
│       ├── FabricKanbanColumn.swift           — Kanban column with drop target, vertical scrolling
│       ├── FabricDropPlaceholder.swift        — Dashed drop-target indicator
│       ├── FabricTimeline.swift               — Event/milestone timeline
│       ├── FabricStepIndicator.swift          — Multi-step progress indicator
│       ├── FabricProgressBar.swift            — Horizontal progress bar
│       ├── FabricProgressRing.swift           — Circular progress ring
│       ├── FabricSkeleton.swift               — Shimmer placeholder (line/block)
│       ├── FabricLoadingIndicator.swift       — Dots or ring spinner
│       ├── FabricErrorBanner.swift            — Collapsible warning banner
│       ├── FabricRadarScanner.swift           — Animated radar/scanning indicator
│       ├── FabricSlider.swift                 — Draggable slider with pill knob
│       └── FabricFlowLayout.swift             — Wrapping flow layout
├── Fabric/                                    — Demo app (FabricDemo target)
│   ├── Fabric.xcodeproj
│   ├── Fabric.xcworkspace
│   └── Fabric/
│       ├── FabricApp.swift
│       ├── ContentView.swift
│       └── Demo/ShowcaseView.swift
└── CLAUDE.md
```

## Build

```bash
# Package (compiles for host platform)
swift build

# Demo app (via workspace — resolves local package)
xcodebuild -workspace Fabric/Fabric.xcworkspace -scheme FabricDemo -destination 'platform=macOS' build
```

- Platforms: macOS 14+ / iOS 17+
- Swift 6.0, swift-tools-version 6.0
- No external dependencies
- Filesystem-synced groups — new .swift files are auto-discovered by Xcode

## Architecture Patterns

### Design Tokens
All visual values flow through five token enums: `FabricColors`, `FabricTypography`, `FabricSpacing`, `FabricAnimation`, `FabricElevation`. Components should never hardcode colors, font sizes, shadow geometry, or animation values directly.

### Elevation Tokens
`FabricElevation` systematizes shadow geometry into named levels:
- **Outer shadows** (5 levels): `micro`, `low`, `mid`, `high`, `drag` — each a `ShadowPair` with tight contact + ambient shadow.
- **Inner shadows** (4 levels): `subtle`, `shallow`, `recessed`, `deep` — for recessed elements.
- **View extensions**: `.fabricShadow(.high)` applies the double shadow pair; `.fabricInnerShadow(shape, .recessed)` applies inner shadow. Both accept optional color overrides for stateful components.

### Animation Tokens
`FabricAnimation` centralizes three presets: `press` (snappy spring for tap/press), `soft` (gentle spring for value changes), `hover` (quick ease-out for hover). All animations are guarded by `reduceMotion`. Continuously-animated components (skeleton, loading, radar) gate animation behind `@State isAnimating` toggled by `onAppear`/`onDisappear`.

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
`.innerShadow()` uses the stroke+shadow+clipShape technique (no `blur()` + `mask()`). Prefer `.fabricInnerShadow(shape, .level)` which routes through `FabricElevation.Inset` tokens.

### Continuous Corners
All rounded shapes use `RoundedRectangle(cornerRadius:style:.continuous)` via `FabricSpacing.shape(radius:)`.

## Design Decisions

- **Dark mode supported** — all colors adapt via `NSAppearance`/`UITraitCollection` dynamic providers.
- **Warm shadows** — shadows are tinted (hue 25, saturation 0.20) not cold gray/black.
- **Double shadows** on elevated elements: tight contact shadow + wide ambient shadow, systematized in `FabricElevation`.
- **Primary button fills are opaque** — no `.opacity()` to ensure consistent WCAG contrast.
- **Focus ring** uses `Color(nsColor: .keyboardFocusIndicatorColor)` for system compliance.
- **Toggle tap target** is the full label+track row, not just the track.
- **TextField error state** uses `FabricColors.madder` border + caption text below; when focused, the focus ring is layered above the error border so both remain visible. Error announcement gated on nil→non-nil transition to avoid noisy VoiceOver during live typing. Empty strings are normalized to nil.

## SwiftUI Pro Agent Skill

This project has the **swiftui-pro** agent skill installed (by Paul Hudson / twostraws). It reviews SwiftUI code against 9 reference guides covering modern APIs, accessibility, performance, data flow, navigation, design, views, Swift style, and code hygiene.

**When to use it:** After writing or modifying SwiftUI components — run it as a quality gate before committing. It catches deprecated APIs, accessibility gaps, structural identity issues, and HIG violations.

**How to run:** Read the skill's reference files from `.claude/skills/swiftui-pro/references/` and apply the review process described in `.claude/skills/swiftui-pro/SKILL.md` against the changed files. Organize findings by file with before/after fixes.

**Key rules this project has adopted from the skill:**
- Use `Button` instead of `onTapGesture` for tappable elements (keyboard + VoiceOver)
- Avoid conditional `.if()` modifier helpers — they break structural identity; use ternaries instead
- Route all animation durations through `FabricAnimation` tokens, never hardcode
- Prefer `Double` over `CGFloat` — Swift bridges freely
- Omit `return` in single-expression functions — use if/else as expressions
- `RoundedRectangle` default style is `.continuous` on macOS 26.1 — no need to specify

## Known Gaps / Next Steps

- **Responsive layout**: ShowcaseView doesn't reflow on narrow windows
- **macOS HIG**: No context menus, no keyboard shortcuts on Cancel buttons

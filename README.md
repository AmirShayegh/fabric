# Fabric

A textile-inspired SwiftUI design system for macOS and iOS.

Warm surfaces, soft interactions, and text that feels absorbed into cloth. The aesthetic is implied, not literal — no stitching or overt textile references. Instead: barely-perceptible woven texture, warm muted colors, and buttons that press in softly like cloth.

## Installation

Add Fabric to your project via Swift Package Manager:

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/AmirShayegh/fabric.git", from: "1.0.0")
]
```

Or in Xcode: **File > Add Package Dependencies** and paste the repository URL.

**Requirements:** macOS 14+ / iOS 17+ | Swift 6.0 | No external dependencies

## Quick Start

```swift
import Fabric

struct ContentView: View {
    @State private var name = ""
    @State private var notifications = true

    var body: some View {
        VStack(spacing: 20) {
            Text("Welcome")
                .fabricTitle()

            FabricTextField(placeholder: "Your name", text: $name, leadingIcon: "person")

            Toggle("Notifications", isOn: $notifications)
                .toggleStyle(.fabric)

            HStack {
                Button("Save") { }
                    .buttonStyle(.fabric)
                Button("Cancel") { }
                    .buttonStyle(.fabricGhost)
            }
        }
        .padding()
        .fabricSurface()
    }
}
```

## Design Language

**Pebbles on Fabric** — the core metaphor:

- **Fabric** = surface layer. Linen texture, recessed elements, inner shadows, warm neutrals. Text fields and columns are *recessed into* the surface.
- **Pebbles** = objects resting on the surface. Buttons, cards, badges, pills. Elevated with warm double shadows and a subtle top-edge highlight.
- **Ink** = text absorbed into the fabric. Flat — neither recessed nor elevated. Micro-shadow gives a "wicked into fibers" look.

Four accent colors drawn from natural dyes: **indigo**, **sage**, **ochre**, **madder**.

## Components

### Surfaces & Layout
| Component | Description |
|-----------|-------------|
| `.fabricSurface()` | Tiled linen texture background modifier |
| `FabricCard { }` | Elevated card container with texture and shadow |
| `FabricFlowLayout` | Wrapping flow layout (SwiftUI `Layout`) |
| `FabricKanbanColumn` | Kanban column with drop target styling, vertical scrolling |

### Controls
| Component | Description |
|-----------|-------------|
| `.buttonStyle(.fabric)` | Primary button — opaque fill, press animation |
| `.buttonStyle(.fabricSecondary)` | Secondary — textured surface, lighter weight |
| `.buttonStyle(.fabricGhost)` | Ghost — transparent, minimal |
| `.toggleStyle(.fabric)` | Custom capsule toggle with cloth-press feel |
| `FabricTextField` | Recessed text field with leading icon, trailing action, error state |
| `FabricSlider` | Draggable slider with pill knob, optional ticks and icons |
| `FabricChip` | Interactive chip with hover, optional remove button |

### Data Display
| Component | Description |
|-----------|-------------|
| `FabricBadge` | Capsule badge (non-interactive) |
| `FabricPill` | Rounded-rect label pebble |
| `FabricStatusDot` | Tiny colored status circle |
| `FabricStatCard` | Data display card with large value + label |
| `FabricTaskCard` | Draggable task card with tags |

### Progress & Loading
| Component | Description |
|-----------|-------------|
| `FabricStepIndicator` | Multi-step progress with dots, connectors, labels |
| `FabricProgressBar` | Horizontal progress bar with optional label/percentage |
| `FabricProgressRing` | Circular progress ring with center content |
| `FabricTimeline` | Vertical timeline with event/milestone dots |
| `FabricSkeleton` | Shimmer placeholder (line, block, or circle) |
| `FabricLoadingIndicator` | Dots or ring spinner |
| `FabricRadarScanner` | Animated radar/scanning indicator |

### Feedback
| Component | Description |
|-----------|-------------|
| `FabricEmptyState` | Centered placeholder with icon, title, action |
| `FabricErrorBanner` | Collapsible warning banner with item list |

## Typography

Modifier-based — not wrapper views:

```swift
Text("Title").fabricTitle()         // 28pt serif medium
Text("Heading").fabricHeading()     // 18pt serif semibold
Text("Body text").fabricBody()      // 15pt sans regular
Text("Label").fabricLabel()         // 15pt sans medium
Text("Caption").fabricCaption()     // 13pt sans regular
Text("Display").fabricDisplay()     // 38pt serif regular
```

Or compose directly:

```swift
Text("Custom")
    .fabricTypography(.heading)
    .fabricInk(.secondary)
```

## Validation

```swift
FabricTextField(
    placeholder: "Email",
    text: $email,
    leadingIcon: "envelope",
    error: emailError  // nil = no error, String = shows madder border + message
)
```

## Elevation Tokens

Shadow geometry is systematized into named levels via `FabricElevation`:

```swift
// Apply pebble double-shadow (tight + ambient)
.fabricShadow(.high)

// Apply inner shadow for recessed elements
.fabricInnerShadow(shape, .recessed)
```

Five outer levels: `micro`, `low`, `mid`, `high`, `drag`. Four inner levels: `subtle`, `shallow`, `recessed`, `deep`.

## Accent Colors

```swift
FabricBadge("New", accent: .indigo)
FabricPill("Approved", accent: .sage)
FabricStatusDot(accent: .madder)
FabricProgressBar(value: 0.7, accent: .ochre, showPercentage: true)
```

## Dark Mode

All colors adapt automatically via dynamic color providers. Light mode uses warm linen tones; dark mode shifts to warm charcoal-brown.

## Demo App

The repo includes a showcase app (target: `FabricDemo`). Open the workspace to build and run:

```
open Fabric/Fabric.xcworkspace
```

Select the **FabricDemo** scheme and run. The workspace resolves the local Fabric package automatically.

## License

MIT

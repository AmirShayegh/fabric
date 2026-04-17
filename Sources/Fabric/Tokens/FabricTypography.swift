import SwiftUI

// MARK: - Text Style Definitions

public enum FabricTextStyle {
    case display    // Hero/feature text
    case editorialDisplay // Tight-tracked hero for long-form/editorial layouts
    case title      // Section titles
    case heading    // Card headings
    case body       // Reading text
    case label      // Button/control labels
    case caption    // Secondary info
    case monoSmall  // Small monospaced (identifiers, short codes)
    case monoCaption // Monospaced caption (fractions, dates, metadata)
    case mono       // Monospaced body text (inline code, general mono)
    case monoLarge    // Large monospaced data display (stat values)
    case sectionLabel // Tiny uppercase section headers (inspector panels)

    public var font: Font {
        switch self {
        case .display:     return .system(size: 38, weight: .regular, design: .serif)
        // Larger + lighter weight lets system serif's optical size kick in.
        case .editorialDisplay: return .system(size: 52, weight: .regular, design: .serif)
        case .title:       return .system(size: 28, weight: .medium, design: .serif)
        case .heading:     return .system(size: 18, weight: .semibold, design: .serif)
        case .body:        return .system(size: 15, weight: .regular, design: .default)
        case .label:       return .system(size: 15, weight: .medium, design: .default)
        case .caption:     return .system(size: 13, weight: .regular, design: .default)
        case .monoSmall:   return .system(size: 11, weight: .medium, design: .monospaced)
        case .monoCaption: return .system(size: 13, weight: .regular, design: .monospaced)
        case .mono:        return .system(size: 15, weight: .regular, design: .monospaced)
        case .monoLarge:    return .system(size: 28, weight: .semibold, design: .monospaced)
        case .sectionLabel: return .system(size: 10, weight: .bold, design: .default)
        }
    }

    public var tracking: CGFloat {
        switch self {
        case .display:          return 0.8
        // Tight letterpress tracking (~ -0.025em on web).
        case .editorialDisplay: return -0.8
        case .title:        return 0.5
        case .heading:      return 0.2
        case .body:         return 0.1
        case .label:        return 0.4
        case .caption:      return 0.2
        case .monoSmall:    return 0.2
        case .monoCaption:  return 0.2
        case .mono:         return 0.1
        case .monoLarge:    return 0.0
        case .sectionLabel: return 1.5
        }
    }

    public var lineSpacing: CGFloat {
        switch self {
        case .display:          return 6
        case .editorialDisplay: return 2
        case .title:        return 4
        case .body, .mono:  return 5
        case .sectionLabel: return 2
        default:            return 2
        }
    }
}

public enum FabricInkStyle {
    case primary, soft, secondary, tertiary

    public var color: Color {
        switch self {
        case .primary:   return FabricColors.inkPrimary
        case .soft:      return FabricColors.inkSoft
        case .secondary: return FabricColors.inkSecondary
        case .tertiary:  return FabricColors.inkTertiary
        }
    }

    public var shadowRadius: CGFloat {
        switch self {
        case .primary:   return 0.5
        case .soft:      return 0.4
        case .secondary: return 0.3
        case .tertiary:  return 0
        }
    }
}

// MARK: - Typography Modifier

public struct FabricTypographyModifier: ViewModifier {
    public let style: FabricTextStyle

    public init(style: FabricTextStyle) {
        self.style = style
    }

    public func body(content: Content) -> some View {
        content
            .font(style.font)
            .tracking(style.tracking)
            .lineSpacing(style.lineSpacing)
    }
}

// MARK: - Ink Modifier

public struct FabricInkModifier: ViewModifier {
    public let style: FabricInkStyle

    public init(style: FabricInkStyle) {
        self.style = style
    }

    public func body(content: Content) -> some View {
        content
            .foregroundStyle(style.color)
            .shadow(
                color: FabricColors.inkShadow,
                radius: style.shadowRadius,
                x: 0,
                y: 0.3
            )
    }
}

// MARK: - Emphasis Modifier
// Editorial italic accent — serif, italic, accent-colored. Used for the
// "em-word" treatment (e.g. "Claude Story *CLI.*"). Apply to a Text directly
// or to any inline view. When used on Text, composes with `+` concatenation.

public struct FabricEmphasisModifier: ViewModifier {
    public let accent: FabricAccent

    public init(accent: FabricAccent) {
        self.accent = accent
    }

    public func body(content: Content) -> some View {
        content
            .italic()
            .foregroundStyle(accent.foreground)
    }
}

// MARK: - View Extensions

extension View {
    public func fabricTypography(_ style: FabricTextStyle) -> some View {
        modifier(FabricTypographyModifier(style: style))
    }

    public func fabricInk(_ style: FabricInkStyle) -> some View {
        modifier(FabricInkModifier(style: style))
    }

    /// Serif italic accent — the editorial "em-word" treatment.
    /// Defaults to `.thread` (warm cinnamon). Apply after a typography modifier.
    public func fabricEmphasis(_ accent: FabricAccent = .thread) -> some View {
        modifier(FabricEmphasisModifier(accent: accent))
    }

    public func fabricDisplay() -> some View {
        fabricTypography(.display).fabricInk(.primary)
    }

    /// Tight-tracked editorial hero — pairs with `.fabricEmphasis()` for em-words.
    public func fabricEditorialDisplay() -> some View {
        fabricTypography(.editorialDisplay).fabricInk(.primary)
    }

    public func fabricTitle() -> some View {
        fabricTypography(.title).fabricInk(.primary)
    }

    public func fabricHeading() -> some View {
        fabricTypography(.heading).fabricInk(.primary)
    }

    public func fabricBody() -> some View {
        fabricTypography(.body).fabricInk(.primary)
    }

    /// Long-form reading body — softer ink, less stark than primary.
    public func fabricBodySoft() -> some View {
        fabricTypography(.body).fabricInk(.soft)
    }

    public func fabricLabel() -> some View {
        fabricTypography(.label).fabricInk(.primary)
    }

    public func fabricCaption() -> some View {
        fabricTypography(.caption).fabricInk(.secondary)
    }

    public func fabricMonoSmall() -> some View {
        fabricTypography(.monoSmall).fabricInk(.secondary)
    }

    public func fabricMonoCaption() -> some View {
        fabricTypography(.monoCaption).fabricInk(.secondary)
    }

    public func fabricMono() -> some View {
        fabricTypography(.mono).fabricInk(.primary)
    }

    public func fabricMonoLarge() -> some View {
        fabricTypography(.monoLarge).fabricInk(.primary)
    }

    public func fabricSectionLabel() -> some View {
        fabricTypography(.sectionLabel)
            .foregroundStyle(FabricColors.inkTertiary)
            .textCase(.uppercase)
    }
}

// MARK: - Text Concatenation Support
// Lets em-words participate in `Text("Claude Story ") + Text("CLI.").fabricEmphasis()`

extension Text {
    /// Serif italic accent for inline em-word treatment inside a `Text` concatenation.
    /// Keeps the surrounding typography; only italicizes and recolors the span.
    public func fabricEmphasis(_ accent: FabricAccent = .thread) -> Text {
        self.italic().foregroundStyle(accent.foreground)
    }
}

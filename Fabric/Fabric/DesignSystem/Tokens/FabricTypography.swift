import SwiftUI

// MARK: - Text Style Definitions

enum FabricTextStyle {
    case display    // Hero/feature text
    case title      // Section titles
    case heading    // Card headings
    case body       // Reading text
    case label      // Button/control labels
    case caption    // Secondary info

    var font: Font {
        switch self {
        case .display: return .system(size: 38, weight: .regular, design: .serif)
        case .title:   return .system(size: 28, weight: .medium, design: .serif)
        case .heading: return .system(size: 18, weight: .semibold, design: .serif)
        case .body:    return .system(size: 15, weight: .regular, design: .default)
        case .label:   return .system(size: 15, weight: .medium, design: .default)
        case .caption: return .system(size: 13, weight: .regular, design: .default)
        }
    }

    var tracking: CGFloat {
        switch self {
        case .display: return 0.8
        case .title:   return 0.5
        case .heading: return 0.2
        case .body:    return 0.1
        case .label:   return 0.4
        case .caption: return 0.2
        }
    }

    var lineSpacing: CGFloat {
        switch self {
        case .display: return 6
        case .title:   return 4
        case .body:    return 5
        default:       return 2
        }
    }
}

enum FabricInkStyle {
    case primary, secondary, tertiary

    var color: Color {
        switch self {
        case .primary:   return FabricColors.inkPrimary
        case .secondary: return FabricColors.inkSecondary
        case .tertiary:  return FabricColors.inkTertiary
        }
    }

    var shadowRadius: CGFloat {
        switch self {
        case .primary:   return 0.5
        case .secondary: return 0.3
        case .tertiary:  return 0
        }
    }

    var shadowOpacity: Double {
        switch self {
        case .primary:   return 0.15
        case .secondary: return 0.10
        case .tertiary:  return 0
        }
    }
}

// MARK: - Typography Modifier

struct FabricTypographyModifier: ViewModifier {
    let style: FabricTextStyle

    func body(content: Content) -> some View {
        content
            .font(style.font)
            .tracking(style.tracking)
            .lineSpacing(style.lineSpacing)
    }
}

// MARK: - Ink Modifier

struct FabricInkModifier: ViewModifier {
    let style: FabricInkStyle

    func body(content: Content) -> some View {
        content
            .foregroundStyle(style.color)
            .shadow(
                color: style.color.opacity(style.shadowOpacity),
                radius: style.shadowRadius,
                x: 0,
                y: 0.3
            )
    }
}

// MARK: - View Extensions

extension View {
    func fabricTypography(_ style: FabricTextStyle) -> some View {
        modifier(FabricTypographyModifier(style: style))
    }

    func fabricInk(_ style: FabricInkStyle) -> some View {
        modifier(FabricInkModifier(style: style))
    }

    func fabricDisplay() -> some View {
        fabricTypography(.display).fabricInk(.primary)
    }

    func fabricTitle() -> some View {
        fabricTypography(.title).fabricInk(.primary)
    }

    func fabricHeading() -> some View {
        fabricTypography(.heading).fabricInk(.primary)
    }

    func fabricBody() -> some View {
        fabricTypography(.body).fabricInk(.primary)
    }

    func fabricLabel() -> some View {
        fabricTypography(.label).fabricInk(.primary)
    }

    func fabricCaption() -> some View {
        fabricTypography(.caption).fabricInk(.secondary)
    }
}

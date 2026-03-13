import SwiftUI

// MARK: - Text Style Definitions

public enum FabricTextStyle {
    case display    // Hero/feature text
    case title      // Section titles
    case heading    // Card headings
    case body       // Reading text
    case label      // Button/control labels
    case caption    // Secondary info

    public var font: Font {
        switch self {
        case .display: return .system(size: 38, weight: .regular, design: .serif)
        case .title:   return .system(size: 28, weight: .medium, design: .serif)
        case .heading: return .system(size: 18, weight: .semibold, design: .serif)
        case .body:    return .system(size: 15, weight: .regular, design: .default)
        case .label:   return .system(size: 15, weight: .medium, design: .default)
        case .caption: return .system(size: 13, weight: .regular, design: .default)
        }
    }

    public var tracking: CGFloat {
        switch self {
        case .display: return 0.8
        case .title:   return 0.5
        case .heading: return 0.2
        case .body:    return 0.1
        case .label:   return 0.4
        case .caption: return 0.2
        }
    }

    public var lineSpacing: CGFloat {
        switch self {
        case .display: return 6
        case .title:   return 4
        case .body:    return 5
        default:       return 2
        }
    }
}

public enum FabricInkStyle {
    case primary, secondary, tertiary

    public var color: Color {
        switch self {
        case .primary:   return FabricColors.inkPrimary
        case .secondary: return FabricColors.inkSecondary
        case .tertiary:  return FabricColors.inkTertiary
        }
    }

    public var shadowRadius: CGFloat {
        switch self {
        case .primary:   return 0.5
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

// MARK: - View Extensions

extension View {
    public func fabricTypography(_ style: FabricTextStyle) -> some View {
        modifier(FabricTypographyModifier(style: style))
    }

    public func fabricInk(_ style: FabricInkStyle) -> some View {
        modifier(FabricInkModifier(style: style))
    }

    public func fabricDisplay() -> some View {
        fabricTypography(.display).fabricInk(.primary)
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

    public func fabricLabel() -> some View {
        fabricTypography(.label).fabricInk(.primary)
    }

    public func fabricCaption() -> some View {
        fabricTypography(.caption).fabricInk(.secondary)
    }
}

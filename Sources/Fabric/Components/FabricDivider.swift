import SwiftUI

/// Thin decorative line separating rows or sections.
/// Solid variant uses the neutral warm `connector` color.
/// Dotted variant uses the thread-colored `connectorThread` — editorial lists,
/// step-of-steps, long-form breakdowns.
public struct FabricDivider: View {
    public enum Style {
        case solid
        case dotted
    }

    public enum Tint {
        case neutral
        case thread

        var color: Color {
            switch self {
            case .neutral: return FabricColors.connector
            case .thread:  return FabricColors.connectorThread
            }
        }
    }

    public let style: Style
    public let tint: Tint
    public let thickness: CGFloat

    public init(style: Style = .solid, tint: Tint = .neutral, thickness: CGFloat = 1) {
        self.style = style
        self.tint = tint
        self.thickness = thickness
    }

    public var body: some View {
        GeometryReader { geo in
            Path { path in
                path.move(to: CGPoint(x: 0, y: thickness / 2))
                path.addLine(to: CGPoint(x: geo.size.width, y: thickness / 2))
            }
            .stroke(
                tint.color,
                style: StrokeStyle(
                    lineWidth: thickness,
                    lineCap: .round,
                    dash: style == .dotted ? [1, 5] : []
                )
            )
        }
        .frame(height: thickness)
        .accessibilityHidden(true)
    }
}

#Preview {
    VStack(spacing: 20) {
        FabricDivider()
        FabricDivider(style: .dotted)
        FabricDivider(style: .dotted, tint: .thread)
    }
    .padding(40)
    .frame(width: 400)
    .fabricSurface()
}

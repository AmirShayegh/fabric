import SwiftUI

public struct FabricMicroProgress: View {

    public static let defaultHeight: CGFloat = 3

    private let value: Double
    private let accent: FabricAccent
    private let height: CGFloat

    private var clampedValue: Double { value.isFinite ? min(max(value, 0), 1) : 0 }

    public init(value: Double, accent: FabricAccent = .editorialThread, height: CGFloat = defaultHeight) {
        self.value = value
        self.accent = accent
        self.height = height
    }

    public var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(FabricColors.connector.opacity(0.5))
                if clampedValue > 0 {
                    Capsule()
                        .fill(accent.foreground)
                        .frame(width: max(height, geo.size.width * clampedValue))
                }
            }
        }
        .frame(height: height)
        .accessibilityHidden(true)
    }
}

import SwiftUI

public struct FabricSkeleton: View {

    public enum Variant {
        case line
        case block(lines: Int = 3)
        case circle(diameter: CGFloat = 40)
    }

    public let variant: Variant
    public let height: CGFloat

    @State private var isAnimating = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(_ variant: Variant = .line, height: CGFloat = 12) {
        self.variant = variant
        self.height = height
    }

    public var body: some View {
        // Single TimelineView drives ALL children — one timer per skeleton, not per line
        Group {
            if isAnimating && !reduceMotion {
                TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
                    let elapsed = timeline.date.timeIntervalSinceReferenceDate
                    let duration = FabricAnimation.shimmerDuration
                    let progress = elapsed.truncatingRemainder(dividingBy: duration) / duration

                    skeletonContent(shimmerProgress: progress)
                }
            } else {
                skeletonContent(shimmerProgress: nil)
            }
        }
        .onAppear { isAnimating = true }
        .onDisappear { isAnimating = false }
        .accessibilityHidden(true)
    }

    // MARK: - Content (receives shared progress from single TimelineView)

    @ViewBuilder
    private func skeletonContent(shimmerProgress: Double?) -> some View {
        switch variant {
        case .line:
            skeletonLine(widthFraction: 1.0, shimmerProgress: shimmerProgress)
        case .block(let lines):
            VStack(alignment: .leading, spacing: FabricSpacing.sm) {
                ForEach(0..<lines, id: \.self) { index in
                    skeletonLine(widthFraction: lineFraction(at: index), shimmerProgress: shimmerProgress)
                }
            }
        case .circle(let diameter):
            skeletonShape(width: diameter, height: diameter, radius: diameter / 2, shimmerProgress: shimmerProgress)
        }
    }

    // MARK: - Skeleton Line

    private func skeletonLine(widthFraction: CGFloat, shimmerProgress: Double?) -> some View {
        GeometryReader { geo in
            let lineWidth = geo.size.width * widthFraction
            skeletonShape(width: lineWidth, height: height, radius: height / 2, shimmerProgress: shimmerProgress)
        }
        .frame(height: height)
    }

    // MARK: - Skeleton Shape (shared shimmer renderer)

    private func skeletonShape(width: CGFloat, height: CGFloat, radius: CGFloat, shimmerProgress: Double?) -> some View {
        let shape = RoundedRectangle(cornerRadius: radius)

        return shape
            .fill(FabricColors.parchment)
            .frame(width: width, height: height)
            .overlay {
                if let progress = shimmerProgress {
                    let gradientWidth = width * 3
                    let offset = -width + (progress * gradientWidth)

                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0),
                            .init(color: FabricColors.canvas.opacity(0.6), location: 0.4),
                            .init(color: FabricColors.canvas.opacity(0.8), location: 0.5),
                            .init(color: FabricColors.canvas.opacity(0.6), location: 0.6),
                            .init(color: .clear, location: 1.0)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: gradientWidth)
                    .offset(x: offset)
                }
            }
            .clipShape(shape)
    }

    // MARK: - Width Pattern

    private func lineFraction(at index: Int) -> CGFloat {
        let fractions: [CGFloat] = [1.0, 0.92, 0.78, 0.65, 0.85, 0.70]
        return fractions[index % fractions.count]
    }
}

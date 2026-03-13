import SwiftUI

struct FabricRadarScanner: View {

    let accent: FabricAccent

    init(accent: FabricAccent = .sage) {
        self.accent = accent
    }

    var body: some View {
        FabricRadarScannerBody(accent: accent)
    }
}

// MARK: - Body View (owns animation state)

private struct FabricRadarScannerBody: View {

    let accent: FabricAccent

    @State private var isAnimating = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // Fixed blip positions (angle in degrees from 12-o'clock, radius fraction 0-1)
    private let blips: [(angle: Double, radius: Double)] = [
        (45, 0.55),
        (160, 0.75),
        (280, 0.40)
    ]

    var body: some View {
        ZStack {
            // Concentric rings — connector-colored, recessed into the fabric
            ForEach([0.40, 0.65, 0.90], id: \.self) { fraction in
                Circle()
                    .stroke(FabricColors.connector, lineWidth: 1)
                    .frame(
                        maxWidth: .infinity,
                        maxHeight: .infinity
                    )
                    .scaleEffect(fraction)
            }

            // Crosshairs — faint reference lines
            Rectangle()
                .fill(FabricColors.connector.opacity(0.5))
                .frame(width: 1)
            Rectangle()
                .fill(FabricColors.connector.opacity(0.5))
                .frame(height: 1)

            // Sweep + blips
            if isAnimating && !reduceMotion {
                TimelineView(.animation) { timeline in
                    let elapsed = timeline.date.timeIntervalSinceReferenceDate
                    let sweepAngle = elapsed.truncatingRemainder(dividingBy: 3.0) / 3.0 * 360.0

                    ZStack {
                        sweepView(angle: sweepAngle)
                        blipViews(sweepAngle: sweepAngle)
                    }
                }
            } else {
                blipViews(sweepAngle: nil)
            }

            // Center dot — elevated pebble
            Circle()
                .fill(accent.foreground)
                .frame(width: 8, height: 8)
                .shadow(color: accent.foreground.opacity(0.4), radius: 4)
                .shadow(color: FabricColors.shadowTight, radius: 0.5, x: 0, y: 0.5)
        }
        .aspectRatio(1, contentMode: .fit)
        .onAppear { isAnimating = true }
        .onDisappear { isAnimating = false }
        .accessibilityHidden(true)
    }

    // MARK: - Sweep

    private func sweepView(angle: Double) -> some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let outerRadius = size / 2 * 0.90

            // Draw sweep as a filled arc with opacity gradient
            Path { path in
                path.move(to: center)
                path.addArc(
                    center: center,
                    radius: outerRadius,
                    startAngle: .degrees(angle - 90),
                    endAngle: .degrees(angle - 90 + 50),
                    clockwise: false
                )
                path.closeSubpath()
            }
            .fill(
                AngularGradient(
                    gradient: Gradient(colors: [
                        accent.foreground.opacity(0.30),
                        accent.foreground.opacity(0.05),
                        accent.foreground.opacity(0.0)
                    ]),
                    center: UnitPoint(
                        x: center.x / geo.size.width,
                        y: center.y / geo.size.height
                    ),
                    startAngle: .degrees(angle - 90),
                    endAngle: .degrees(angle - 90 + 50)
                )
            )

            // Leading edge — bright sweep line
            Path { path in
                path.move(to: center)
                let edgeAngle = Angle.degrees(angle - 90)
                path.addLine(to: CGPoint(
                    x: center.x + outerRadius * Darwin.cos(edgeAngle.radians),
                    y: center.y + outerRadius * Darwin.sin(edgeAngle.radians)
                ))
            }
            .stroke(accent.foreground.opacity(0.5), lineWidth: 1.5)
            .shadow(color: accent.foreground.opacity(0.3), radius: 3)
        }
    }

    // MARK: - Blips

    private func blipViews(sweepAngle: Double?) -> some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let maxRadius = size / 2

            ForEach(0..<blips.count, id: \.self) { index in
                let blip = blips[index]
                let pos = blipPosition(
                    center: center,
                    angle: blip.angle,
                    radius: maxRadius * blip.radius
                )

                let lit: Bool = {
                    guard let sweepAngle else { return false }
                    return isInSweep(blipAngle: blip.angle, sweepAngle: sweepAngle)
                }()

                Circle()
                    .fill(accent.foreground)
                    .frame(width: 5, height: 5)
                    .scaleEffect(lit ? 1.6 : 1.0)
                    .opacity(lit ? 1.0 : 0.35)
                    .shadow(
                        color: lit ? accent.foreground.opacity(0.6) : .clear,
                        radius: lit ? 6 : 0
                    )
                    .position(pos)
                    .animation(.easeOut(duration: FabricAnimation.standard), value: lit)
            }
        }
    }

    // MARK: - Helpers

    private func blipPosition(center: CGPoint, angle: Double, radius: Double) -> CGPoint {
        let radians = (angle - 90) * .pi / 180
        let cosVal = Darwin.cos(radians)
        let sinVal = Darwin.sin(radians)
        return CGPoint(
            x: center.x + radius * cosVal,
            y: center.y + radius * sinVal
        )
    }

    private func isInSweep(blipAngle: Double, sweepAngle: Double) -> Bool {
        let diff = (blipAngle - sweepAngle).truncatingRemainder(dividingBy: 360)
        let normalized = diff < 0 ? diff + 360 : diff
        return normalized < 50
    }
}

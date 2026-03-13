import SwiftUI

public struct FabricSlider: View {

    @Binding public var value: Double
    public let label: String
    public let accent: FabricAccent
    public let leadingIcon: String?
    public let trailingIcon: String?
    public let ticks: Int

    public init(
        value: Binding<Double>,
        label: String = "Slider",
        accent: FabricAccent = .indigo,
        leadingIcon: String? = nil,
        trailingIcon: String? = nil,
        ticks: Int = 0
    ) {
        self._value = value
        self.label = label
        self.accent = accent
        self.leadingIcon = leadingIcon
        self.trailingIcon = trailingIcon
        self.ticks = ticks
    }

    public var body: some View {
        FabricSliderBody(
            value: $value,
            label: label,
            accent: accent,
            leadingIcon: leadingIcon,
            trailingIcon: trailingIcon,
            ticks: ticks
        )
    }
}

// MARK: - Body View (owns drag @State)

private struct FabricSliderBody: View {

    @Binding var value: Double
    let label: String
    let accent: FabricAccent
    let leadingIcon: String?
    let trailingIcon: String?
    let ticks: Int

    @State private var isDragging = false
    @State private var isFocused = false
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let trackHeight: CGFloat = 6
    private let knobWidth: CGFloat = 38
    private let knobHeight: CGFloat = 24

    private var clampedValue: Double { max(0, min(value, 1)) }

    /// Unified step resolution used by drag-end snap, VoiceOver, and keyboard.
    private var step: Double { ticks > 1 ? 1.0 / Double(ticks - 1) : 0.1 }

    var body: some View {
        HStack(spacing: FabricSpacing.sm + FabricSpacing.xs) {
            if let leadingIcon {
                Image(systemName: leadingIcon)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(FabricColors.inkSecondary)
                    .frame(width: FabricSpacing.sliderIconWidth)
            }

            sliderTrack

            if let trailingIcon {
                Image(systemName: trailingIcon)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(FabricColors.inkSecondary)
                    .frame(width: FabricSpacing.sliderIconWidth)
            }
        }
        .frame(height: FabricSpacing.sliderHeight)
        .opacity(isEnabled ? 1.0 : 0.5)
        .focusable()
        #if os(macOS)
        .onKeyPress(.leftArrow) {
            guard isEnabled else { return .ignored }
            value = max(0, value - step)
            return .handled
        }
        .onKeyPress(.rightArrow) {
            guard isEnabled else { return .ignored }
            value = min(1, value + step)
            return .handled
        }
        #endif
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
        .accessibilityValue("\(Int(clampedValue * 100)) percent")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: value = min(1, value + step)
            case .decrement: value = max(0, value - step)
            @unknown default: break
            }
        }
    }

    // MARK: - Track + Knob

    private var sliderTrack: some View {
        GeometryReader { geo in
            let trackWidth = geo.size.width
            let usableWidth = trackWidth - knobWidth
            let knobX = knobWidth / 2 + usableWidth * clampedValue

            ZStack(alignment: .leading) {
                // Track background — recessed into fabric
                Capsule()
                    .fill(FabricColors.parchment)
                    .frame(height: trackHeight)
                    .innerShadow(
                        Capsule(),
                        color: FabricColors.innerShadow,
                        radius: 1.5, spread: 1.5, y: 0.5
                    )

                // Fill — accent color up to knob position
                if clampedValue > 0 {
                    Capsule()
                        .fill(accent.foreground)
                        .frame(width: knobX, height: trackHeight)
                }

                // Tick marks
                if ticks > 1 {
                    tickMarks(geo: geo)
                }

                // Knob — pill pebble
                knobView
                    .position(x: knobX, y: geo.size.height / 2)
            }
            .frame(maxHeight: .infinity)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { drag in
                        isDragging = true
                        let fraction = (drag.location.x - knobWidth / 2) / usableWidth
                        value = max(0, min(Double(fraction), 1))
                    }
                    .onEnded { _ in
                        isDragging = false
                        if ticks > 1 {
                            value = (value / step).rounded() * step
                        }
                    }
            )
        }
    }

    // MARK: - Knob

    private var knobView: some View {
        Capsule()
            .fill(FabricColors.onPrimary)
            .frame(width: knobWidth, height: knobHeight)
            .overlay {
                Capsule()
                    .strokeBorder(
                        LinearGradient(
                            colors: [FabricColors.highlight, Color.clear],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 0.5
                    )
            }
            .shadow(color: FabricColors.shadowTight, radius: 0.5, x: 0, y: 0.5)
            .shadow(color: FabricColors.shadow, radius: isDragging ? 8 : 4, x: 0, y: isDragging ? 4 : 2)
            .scaleEffect(isDragging && !reduceMotion ? 1.08 : 1.0)
            .animation(
                reduceMotion ? nil : FabricAnimation.press,
                value: isDragging
            )
    }

    // MARK: - Tick Marks

    private func tickMarks(geo: GeometryProxy) -> some View {
        let usableWidth = geo.size.width - knobWidth
        let spacing = usableWidth / CGFloat(ticks - 1)
        let tickY = geo.size.height / 2 + trackHeight / 2 + 4

        return ForEach(0..<ticks, id: \.self) { index in
            Circle()
                .fill(FabricColors.inkTertiary.opacity(0.4))
                .frame(width: 4, height: 4)
                .position(
                    x: knobWidth / 2 + spacing * CGFloat(index),
                    y: tickY
                )
        }
    }
}

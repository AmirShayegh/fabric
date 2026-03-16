import SwiftUI

public struct FabricMessageBubble<Content: View>: View {

    public enum Role {
        case user
        case assistant
    }

    public enum AvatarContent {
        case icon(String)
        case initials(String)
    }

    public let role: Role
    public let avatar: AvatarContent
    public let accent: FabricAccent
    public let timestamp: String?
    public let isStreaming: Bool
    @ViewBuilder public let content: Content

    public init(
        role: Role,
        avatar: AvatarContent,
        accent: FabricAccent = .indigo,
        timestamp: String? = nil,
        isStreaming: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.role = role
        self.avatar = avatar
        self.accent = accent
        self.timestamp = timestamp
        self.isStreaming = isStreaming
        self.content = content()
    }

    public var body: some View {
        FabricMessageBubbleBody(
            role: role,
            avatar: avatar,
            accent: accent,
            timestamp: timestamp,
            isStreaming: isStreaming,
            content: { content }
        )
    }
}

// MARK: - Body View (owns animation state)

private struct FabricMessageBubbleBody<Content: View>: View {

    let role: FabricMessageBubble<Content>.Role
    let avatar: FabricMessageBubble<Content>.AvatarContent
    let accent: FabricAccent
    let timestamp: String?
    let isStreaming: Bool
    @ViewBuilder let content: Content

    @State private var isAnimating = false
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.displayScale) private var displayScale

    private var shape: RoundedRectangle {
        FabricSpacing.shape(radius: FabricSpacing.radiusSm)
    }

    private var isUser: Bool { role == .user }
    private let avatarSize = FabricSpacing.avatarSizeSm

    var body: some View {
        HStack(alignment: .top, spacing: FabricSpacing.sm) {
            if !isUser {
                avatarView
            }

            VStack(alignment: isUser ? .trailing : .leading, spacing: FabricSpacing.xs) {
                bubbleView
                if let timestamp {
                    Text(timestamp)
                        .fabricTypography(.caption)
                        .foregroundStyle(FabricColors.inkTertiary)
                }
            }

            if isUser {
                avatarView
            }
        }
        .frame(maxWidth: .infinity, alignment: isUser ? .trailing : .leading)
        .padding(isUser ? .leading : .trailing, FabricSpacing.xxxl)
        .onAppear { isAnimating = true }
        .onDisappear { isAnimating = false }
        .opacity(isEnabled ? 1.0 : 0.5)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(isUser ? "Your message" : "Assistant message")
    }

    // MARK: - Bubble

    @ViewBuilder
    private var bubbleView: some View {
        VStack(alignment: .leading, spacing: FabricSpacing.sm) {
            content

            if isStreaming {
                StreamingDots(
                    isAnimating: isAnimating,
                    reduceMotion: reduceMotion
                )
            }
        }
        .padding(FabricSpacing.md)
        .background { bubbleBackground }
        .clipShape(shape)
        .overlay {
            if isUser {
                shape.strokeBorder(
                    LinearGradient(
                        colors: [FabricColors.highlight, Color.clear],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 0.5
                )
            }
        }
        .fabricShadow(.low,
                      tightColor: isUser ? FabricColors.shadowTight : .clear,
                      ambientColor: isUser ? FabricColors.shadow : .clear)
        .fabricInnerShadow(shape, .shallow,
                           color: isUser ? .clear : FabricColors.innerShadow)
    }

    @ViewBuilder
    private var bubbleBackground: some View {
        if isUser {
            ZStack {
                shape.fill(FabricColors.canvas)
                shape.foregroundStyle(
                    TextureGenerator.linenPaint(displayScale: displayScale, intensity: 0.025)
                )
            }
        } else {
            shape.fill(FabricColors.parchment)
        }
    }

    // MARK: - Avatar

    private var avatarView: some View {
        ZStack {
            Circle()
                .fill(isUser ? FabricColors.burlap : accent.foreground)

            switch avatar {
            case .icon(let name):
                Image(systemName: name)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(isUser ? FabricColors.inkPrimary : FabricColors.onPrimary)
            case .initials(let text):
                Text(text)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(isUser ? FabricColors.inkPrimary : FabricColors.onPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
        }
        .frame(width: avatarSize, height: avatarSize)
        .fabricShadow(.micro)
        .accessibilityHidden(true)
    }
}

// MARK: - Streaming Dots

private struct StreamingDots: View {

    let isAnimating: Bool
    let reduceMotion: Bool

    private let dotSize: CGFloat = 6

    var body: some View {
        if isAnimating && !reduceMotion {
            PhaseAnimator([0, 1, 2]) { phase in
                HStack(spacing: FabricSpacing.xs) {
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .fill(FabricColors.inkTertiary)
                            .frame(width: dotSize, height: dotSize)
                            .scaleEffect(index == phase ? 1.0 : 0.5)
                    }
                }
            } animation: { _ in
                .easeInOut(duration: FabricAnimation.phased)
            }
        } else {
            HStack(spacing: FabricSpacing.xs) {
                ForEach(0..<3, id: \.self) { _ in
                    Circle()
                        .fill(FabricColors.inkTertiary)
                        .frame(width: dotSize, height: dotSize)
                }
            }
        }
    }
}


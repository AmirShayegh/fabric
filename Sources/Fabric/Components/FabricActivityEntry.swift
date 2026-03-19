import SwiftUI

/// A lightweight activity feed entry with a colored dot, event text, and timestamp.
///
/// Stack multiple entries in a `VStack` to build an activity feed.
/// ```swift
/// VStack(spacing: FabricSpacing.md) {
///     FabricActivityEntry("Claude edited window_manager.rs", timestamp: "2m ago", accent: .indigo)
///     FabricActivityEntry("Status changed to In Progress", timestamp: "1h ago", accent: .sage)
///     FabricActivityEntry("Ticket created", timestamp: "Mar 12")
/// }
/// ```
public struct FabricActivityEntry: View {

    public let text: String
    public let timestamp: String
    public let accent: FabricAccent?

    public init(
        _ text: String,
        timestamp: String,
        accent: FabricAccent? = nil
    ) {
        self.text = text
        self.timestamp = timestamp
        self.accent = accent
    }

    public var body: some View {
        HStack(alignment: .top, spacing: FabricSpacing.sm) {
            Circle()
                .fill(accent?.foreground ?? FabricColors.inkTertiary)
                .frame(width: FabricSpacing.statusDotSize, height: FabricSpacing.statusDotSize)
                .padding(.top, 3)

            VStack(alignment: .leading, spacing: 2) {
                Text(text)
                    .fabricTypography(.caption)
                    .fabricInk(.primary)

                Text(timestamp)
                    .fabricTypography(.monoSmall)
                    .foregroundStyle(FabricColors.inkTertiary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(text), \(timestamp)")
    }
}

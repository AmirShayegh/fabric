import SwiftUI

public struct FabricErrorBanner: View {

    public struct Warning: Identifiable {
        public let id: String
        public let title: String
        public let subtitle: String

        public init(id: String = UUID().uuidString, title: String, subtitle: String) {
            self.id = id
            self.title = title
            self.subtitle = subtitle
        }
    }

    public let title: String
    public let warnings: [Warning]
    public let accent: FabricAccent
    @Binding public var isExpanded: Bool

    public init(
        _ title: String,
        warnings: [Warning],
        accent: FabricAccent = .madder,
        isExpanded: Binding<Bool>
    ) {
        self.title = title
        self.warnings = warnings
        self.accent = accent
        self._isExpanded = isExpanded
    }

    public var body: some View {
        Group {
            if warnings.isEmpty {
                EmptyView()
            } else {
                FabricErrorBannerBody(
                    title: title,
                    warnings: warnings,
                    accent: accent,
                    isExpanded: $isExpanded
                )
            }
        }
        .onChange(of: warnings.count) {
            if warnings.isEmpty {
                isExpanded = false
            }
        }
    }
}

// MARK: - Body View (owns hover @State)

private struct FabricErrorBannerBody: View {

    let title: String
    let warnings: [FabricErrorBanner.Warning]
    let accent: FabricAccent
    @Binding var isExpanded: Bool

    @State private var isHovered = false
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var shape: RoundedRectangle {
        FabricSpacing.shape(radius: FabricSpacing.radiusSm)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerView
            if isExpanded {
                warningsList
            }
        }
        .background(FabricColors.parchment)
        .clipShape(shape)
        .innerShadow(shape, color: FabricColors.innerShadow, radius: 2, spread: 2, y: 1)
        .opacity(isEnabled ? 1.0 : 0.5)
        .animation(
            reduceMotion ? nil : FabricAnimation.soft,
            value: isExpanded
        )
    }

    // MARK: - Header

    private var headerView: some View {
        Button {
            if reduceMotion {
                isExpanded.toggle()
            } else {
                withAnimation(FabricAnimation.soft) {
                    isExpanded.toggle()
                }
            }
        } label: {
            HStack(spacing: FabricSpacing.sm) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(accent.foreground)
                    .font(.system(size: 13))

                Text(title)
                    .fabricLabel()

                FabricPill("\(warnings.count)", accent: accent)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(FabricColors.inkTertiary)
                    .rotationEffect(.degrees(isExpanded ? 90 : 0))
            }
            .padding(.horizontal, FabricSpacing.md)
            .padding(.vertical, FabricSpacing.sm)
            .background(FabricColors.burlap.opacity(isHovered ? 0.08 : 0))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            guard isEnabled else { return }
            isHovered = hovering
        }
        .accessibilityLabel(title)
        .accessibilityValue("\(warnings.count) warnings")
        .accessibilityHint(isExpanded ? "Collapse" : "Expand")
    }

    // MARK: - Warnings List

    private var warningsList: some View {
        VStack(alignment: .leading, spacing: FabricSpacing.xs) {
            Rectangle()
                .fill(FabricColors.connector)
                .frame(height: 0.5)
                .padding(.horizontal, FabricSpacing.md)

            ForEach(warnings) { warning in
                HStack(alignment: .top, spacing: FabricSpacing.sm) {
                    FabricStatusDot(accent: accent)
                        .padding(.top, 5)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(warning.title)
                            .fabricTypography(.caption)
                            .foregroundStyle(accent.foreground)
                        Text(warning.subtitle)
                            .fabricTypography(.body)
                            .foregroundStyle(FabricColors.inkSecondary)
                    }
                }
                .padding(.horizontal, FabricSpacing.md)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(warning.title): \(warning.subtitle)")
            }
        }
        .padding(.top, FabricSpacing.xs)
        .padding(.bottom, FabricSpacing.md)
    }
}

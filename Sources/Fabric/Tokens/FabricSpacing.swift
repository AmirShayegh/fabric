import SwiftUI

public enum FabricSpacing {

    // MARK: - Spacing Scale (generous, breathable)

    public static let xs:  CGFloat = 4
    public static let sm:  CGFloat = 8
    public static let md:  CGFloat = 14
    public static let lg:  CGFloat = 20
    public static let xl:  CGFloat = 28
    public static let xxl: CGFloat = 40
    public static let xxxl: CGFloat = 56

    // MARK: - Corner Radii (iOS 26 continuous corners — plush, pillowy)

    public static let radiusXs: CGFloat = 8     // chips, badges
    public static let radiusSm: CGFloat = 16
    public static let radiusMd: CGFloat = 24
    public static let radiusLg: CGFloat = 32

    /// Continuous corner shape (squircle) for that iOS feel
    public static func shape(radius: CGFloat) -> RoundedRectangle {
        RoundedRectangle(cornerRadius: radius)
    }

    // MARK: - Component Sizing

    public static let buttonMinHeightSm: CGFloat = 32   // ghost
    public static let buttonMinHeightMd: CGFloat = 36   // primary
    public static let buttonMinHeightLg: CGFloat = 44   // secondary
    public static let buttonMinWidth:    CGFloat = 100
    public static let textFieldHeight: CGFloat = 44
    public static let cardPadding:     CGFloat = 24
    public static let toggleTrackW:    CGFloat = 64
    public static let toggleTrackH:    CGFloat = 28
    public static let toggleThumb:     CGFloat = 24
    public static let toggleKnobW:     CGFloat = 39
    public static let togglePadding:   CGFloat = 2

    // MARK: - Small Elements

    public static let connectorWidth:    CGFloat = 2
    public static let badgeHeight:       CGFloat = 22
    public static let chipHeight:        CGFloat = 26
    public static let stepDotSize:       CGFloat = 12
    public static let timelineDotSize:   CGFloat = 12
    public static let timelineDotSizeLg: CGFloat = 18
    public static let progressBarHeight: CGFloat = 4
    public static let columnMinWidth:    CGFloat = 280
    public static let columnMaxWidth:    CGFloat = 320
    public static let statusDotSize:     CGFloat = 8
    public static let pillHeight:        CGFloat = 22
    public static let sliderHeight:      CGFloat = 52
    public static let sliderIconWidth:   CGFloat = 32
    public static let checkboxSize:      CGFloat = 20
    public static let avatarSizeXs:      CGFloat = 24
    public static let avatarSizeSm:      CGFloat = 32
}

import SwiftUI

enum FabricSpacing {

    // MARK: - Spacing Scale (generous, breathable)

    static let xs:  CGFloat = 4
    static let sm:  CGFloat = 8
    static let md:  CGFloat = 14
    static let lg:  CGFloat = 20
    static let xl:  CGFloat = 28
    static let xxl: CGFloat = 40
    static let xxxl: CGFloat = 56

    // MARK: - Corner Radii (iOS 26 continuous corners — plush, pillowy)

    static let radiusXs: CGFloat = 8     // chips, badges
    static let radiusSm: CGFloat = 16
    static let radiusMd: CGFloat = 24
    static let radiusLg: CGFloat = 32

    /// Continuous corner shape (squircle) for that iOS feel
    static func shape(radius: CGFloat) -> RoundedRectangle {
        RoundedRectangle(cornerRadius: radius)
    }

    // MARK: - Component Sizing

    static let buttonMinHeightSm: CGFloat = 32   // ghost
    static let buttonMinHeightMd: CGFloat = 36   // primary
    static let buttonMinHeightLg: CGFloat = 44   // secondary
    static let buttonMinWidth:    CGFloat = 100
    static let textFieldHeight: CGFloat = 44
    static let cardPadding:     CGFloat = 24
    static let toggleTrackW:    CGFloat = 64
    static let toggleTrackH:    CGFloat = 28
    static let toggleThumb:     CGFloat = 24
    static let toggleKnobW:     CGFloat = 39
    static let togglePadding:   CGFloat = 2

    // MARK: - Small Elements

    static let connectorWidth:    CGFloat = 2
    static let badgeHeight:       CGFloat = 22
    static let chipHeight:        CGFloat = 26
    static let stepDotSize:       CGFloat = 12
    static let timelineDotSize:   CGFloat = 12
    static let timelineDotSizeLg: CGFloat = 18
    static let progressBarHeight: CGFloat = 4
    static let columnMinWidth:    CGFloat = 280
    static let statusDotSize:     CGFloat = 8
    static let pillHeight:        CGFloat = 22
    static let sliderHeight:      CGFloat = 52
    static let sliderIconWidth:   CGFloat = 32
}

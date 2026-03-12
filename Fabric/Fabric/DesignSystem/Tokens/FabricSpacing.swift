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
        RoundedRectangle(cornerRadius: radius, style: .continuous)
    }

    // MARK: - Component Sizing

    static let buttonHeight:    CGFloat = 48
    static let buttonMinWidth:  CGFloat = 100
    static let textFieldHeight: CGFloat = 44
    static let cardPadding:     CGFloat = 24
    static let toggleTrackW:    CGFloat = 52
    static let toggleTrackH:    CGFloat = 32
    static let toggleThumb:     CGFloat = 26

    // MARK: - Small Elements

    static let connectorWidth:    CGFloat = 2
    static let badgeHeight:       CGFloat = 22
    static let chipHeight:        CGFloat = 26
    static let stepIndicatorSize: CGFloat = 32
    static let timelineDotSize:   CGFloat = 12
    static let timelineDotSizeLg: CGFloat = 18
    static let progressBarHeight: CGFloat = 8
    static let columnMinWidth:    CGFloat = 280
}

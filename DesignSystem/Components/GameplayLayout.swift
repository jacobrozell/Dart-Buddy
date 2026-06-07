import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

enum GameplayLayout {
    /// Larger iPhones report `.regular` horizontal size class in landscape, same as iPad.
    private static var defaultIsPad: Bool {
        #if canImport(UIKit)
        UIDevice.current.userInterfaceIdiom == .pad
        #else
        false
        #endif
    }
    /// Readable column for setup, summary, and list-style screens on iPad.
    static func contentMaxWidth(horizontalSizeClass: UserInterfaceSizeClass?) -> CGFloat {
        horizontalSizeClass == .regular ? 760 : .infinity
    }

    /// Active X01/Cricket scoreboards use full width; horizontal padding defines the margins.
    static func matchContentMaxWidth(horizontalSizeClass: UserInterfaceSizeClass?) -> CGFloat {
        .infinity
    }

    /// X01/Cricket scoring uses alternate layout at accessibility text sizes (AX1–AX5).
    static func usesAccessibilityMatchScoringLayout(dynamicTypeSize: DynamicTypeSize) -> Bool {
        dynamicTypeSize.isAccessibilitySize
    }

    /// Number-pad columns: fewer columns at AX sizes so labels stay legible.
    static func scoringPadColumnCount(dynamicTypeSize: DynamicTypeSize) -> Int {
        usesAccessibilityMatchScoringLayout(dynamicTypeSize: dynamicTypeSize) ? 4 : 7
    }

    /// Play setup home uses alternate layout at accessibility text sizes (AX1–AX5).
    static func usesAccessibilitySetupHomeLayout(dynamicTypeSize: DynamicTypeSize) -> Bool {
        dynamicTypeSize.isAccessibilitySize
    }

    /// Tab-root list screens (History, Statistics, Players, Settings) use alternate layout at AX sizes.
    static func usesAccessibilityTabListLayout(dynamicTypeSize: DynamicTypeSize) -> Bool {
        dynamicTypeSize.isAccessibilitySize
    }

    /// Bottom inset for tab-root scroll content so rows clear the tab bar at AX sizes.
    static func tabScrollBottomPadding(dynamicTypeSize: DynamicTypeSize) -> CGFloat {
        usesAccessibilityTabListLayout(dynamicTypeSize: dynamicTypeSize)
            ? DS.Spacing.s6 + 72
            : DS.Spacing.s6
    }

    /// iPhone landscape (compact vertical height): board and pad side-by-side.
    static func usesLandscapeMatchScoringLayout(verticalSizeClass: UserInterfaceSizeClass?) -> Bool {
        verticalSizeClass == .compact
    }

    /// iPad portrait or iPhone landscape: scoreboard beside a fixed-width scoring pad.
    static func usesSideBySideMatchScoringLayout(
        horizontalSizeClass: UserInterfaceSizeClass?,
        verticalSizeClass: UserInterfaceSizeClass?
    ) -> Bool {
        horizontalSizeClass == .regular || verticalSizeClass == .compact
    }

    /// iPad portrait only: two-column scoreboard grid beside the pad.
    static func usesIPadPortraitMatchScoringLayout(
        horizontalSizeClass: UserInterfaceSizeClass?,
        verticalSizeClass: UserInterfaceSizeClass?
    ) -> Bool {
        horizontalSizeClass == .regular && verticalSizeClass == .regular
    }

    /// iPhone landscape only — scoreboard fills the column; iPad portrait keeps scroll/grid layouts.
    static func usesLandscapeIPhoneMatchScoringLayout(
        horizontalSizeClass: UserInterfaceSizeClass?,
        verticalSizeClass: UserInterfaceSizeClass?,
        isPad: Bool = defaultIsPad
    ) -> Bool {
        usesLandscapeIPhoneOnlyMatchScoringLayout(
            horizontalSizeClass: horizontalSizeClass,
            verticalSizeClass: verticalSizeClass,
            isPad: isPad
        )
    }

    /// True iPhone landscape — uses idiom because Plus/Max phones report regular width in landscape.
    static func usesLandscapeIPhoneOnlyMatchScoringLayout(
        horizontalSizeClass: UserInterfaceSizeClass?,
        verticalSizeClass: UserInterfaceSizeClass?,
        isPad: Bool = defaultIsPad
    ) -> Bool {
        _ = horizontalSizeClass
        return verticalSizeClass == .compact && !isPad
    }

    /// iPad landscape (compact height on pad idiom).
    static func usesLandscapeIPadMatchScoringLayout(
        horizontalSizeClass: UserInterfaceSizeClass?,
        verticalSizeClass: UserInterfaceSizeClass?,
        isPad: Bool = defaultIsPad
    ) -> Bool {
        _ = horizontalSizeClass
        return verticalSizeClass == .compact && isPad
    }

    /// Cricket: targets as columns, active player only — iPhone landscape.
    static func usesTransposedCricketBoardLayout(
        horizontalSizeClass: UserInterfaceSizeClass?,
        verticalSizeClass: UserInterfaceSizeClass?,
        isPad: Bool = defaultIsPad
    ) -> Bool {
        usesLandscapeIPhoneOnlyMatchScoringLayout(
            horizontalSizeClass: horizontalSizeClass,
            verticalSizeClass: verticalSizeClass,
            isPad: isPad
        )
    }

    /// Cricket: full multi-player board scales to the scoreboard column (iPad landscape).
    static func usesCricketBoardFillsAvailableHeight(
        horizontalSizeClass: UserInterfaceSizeClass?,
        verticalSizeClass: UserInterfaceSizeClass?,
        isPad: Bool = defaultIsPad
    ) -> Bool {
        usesLandscapeIPadMatchScoringLayout(
            horizontalSizeClass: horizontalSizeClass,
            verticalSizeClass: verticalSizeClass,
            isPad: isPad
        )
    }

    /// Cricket iPhone landscape: current player board pinned above a full-width pad (X01-style),
    /// rather than the side-by-side board + sidebar pad used on iPad where there is more room.
    static func usesCricketLandscapePinnedLayout(
        horizontalSizeClass: UserInterfaceSizeClass?,
        verticalSizeClass: UserInterfaceSizeClass?,
        dynamicTypeSize: DynamicTypeSize,
        isPad: Bool = defaultIsPad
    ) -> Bool {
        usesLandscapeIPhoneOnlyMatchScoringLayout(
            horizontalSizeClass: horizontalSizeClass,
            verticalSizeClass: verticalSizeClass,
            isPad: isPad
        ) && !usesAccessibilityMatchScoringLayout(dynamicTypeSize: dynamicTypeSize)
    }

    /// Cricket side-by-side board + pad: iPad portrait and iPad landscape only (not iPhone landscape).
    static func usesCricketSideBySideMatchScoringLayout(
        horizontalSizeClass: UserInterfaceSizeClass?,
        verticalSizeClass: UserInterfaceSizeClass?,
        dynamicTypeSize: DynamicTypeSize,
        isPad: Bool = defaultIsPad
    ) -> Bool {
        guard !usesAccessibilityMatchScoringLayout(dynamicTypeSize: dynamicTypeSize) else { return false }
        return usesIPadPortraitMatchScoringLayout(
            horizontalSizeClass: horizontalSizeClass,
            verticalSizeClass: verticalSizeClass
        ) || usesLandscapeIPadMatchScoringLayout(
            horizontalSizeClass: horizontalSizeClass,
            verticalSizeClass: verticalSizeClass,
            isPad: isPad
        )
    }

    /// Cricket pad spans the full width below the board (iPhone landscape) instead of a
    /// fixed-width sidebar, so it lays keys out wide and short to leave room for the board.
    static func usesCricketFullWidthLandscapePad(
        horizontalSizeClass: UserInterfaceSizeClass?,
        verticalSizeClass: UserInterfaceSizeClass?,
        dynamicTypeSize: DynamicTypeSize,
        isPad: Bool = defaultIsPad
    ) -> Bool {
        usesCricketLandscapePinnedLayout(
            horizontalSizeClass: horizontalSizeClass,
            verticalSizeClass: verticalSizeClass,
            dynamicTypeSize: dynamicTypeSize,
            isPad: isPad
        )
    }

    /// Fixed scoring pad width in landscape (compact pad targets ~250pt).
    static let landscapeScoringPadWidth: CGFloat = 252

    /// Fixed scoring pad width on iPad portrait.
    static let regularWidthScoringPadWidth: CGFloat = 340

    static func scoringPadFixedWidth(
        horizontalSizeClass: UserInterfaceSizeClass?,
        verticalSizeClass: UserInterfaceSizeClass?
    ) -> CGFloat {
        if horizontalSizeClass == .regular, verticalSizeClass == .regular {
            return regularWidthScoringPadWidth
        }
        return landscapeScoringPadWidth
    }

    /// X01 side-by-side scoreboard + pad: iPad portrait only (landscape uses vertical stack).
    static func usesX01SideBySideMatchScoringLayout(
        horizontalSizeClass: UserInterfaceSizeClass?,
        verticalSizeClass: UserInterfaceSizeClass?,
        dynamicTypeSize: DynamicTypeSize
    ) -> Bool {
        usesIPadPortraitMatchScoringLayout(
            horizontalSizeClass: horizontalSizeClass,
            verticalSizeClass: verticalSizeClass
        ) && !usesAccessibilityMatchScoringLayout(dynamicTypeSize: dynamicTypeSize)
    }

    /// Pins the active X01 card at the top in landscape; portrait scroll pins at 3+ players.
    static func usesPinnedActiveX01PlayerCard(
        playerCount: Int,
        dynamicTypeSize: DynamicTypeSize,
        verticalSizeClass: UserInterfaceSizeClass? = nil
    ) -> Bool {
        guard !usesAccessibilityMatchScoringLayout(dynamicTypeSize: dynamicTypeSize) else { return false }
        if usesLandscapeMatchScoringLayout(verticalSizeClass: verticalSizeClass) {
            return true
        }
        return playerCount >= 3
    }
}

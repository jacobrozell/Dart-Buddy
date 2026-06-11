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
    static let regularContentMaxWidth: CGFloat = 920

    static func contentMaxWidth(horizontalSizeClass: UserInterfaceSizeClass?) -> CGFloat {
        horizontalSizeClass == .regular ? regularContentMaxWidth : .infinity
    }

    /// Play setup uses a two-pane layout on iPad regular width.
    static func usesWideSetupHomeLayout(
        horizontalSizeClass: UserInterfaceSizeClass?,
        dynamicTypeSize: DynamicTypeSize
    ) -> Bool {
        horizontalSizeClass == .regular
            && !usesAccessibilitySetupHomeLayout(dynamicTypeSize: dynamicTypeSize)
    }

    /// Minimum width for the bottom-docked pad column on iPhone portrait.
    static let phonePortraitBottomPadMinWidth: CGFloat = 220

    /// Legacy cap retained for tests; bottom-docked pads use the compact grid instead.
    static let iPadSideBySidePadKeyMaxHeight: CGFloat = 88

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

    /// Fixed scoring pad width in iPhone landscape (compact pad targets ~250pt).
    static let landscapeScoringPadWidth: CGFloat = 252

    /// Fixed scoring pad width on iPad portrait side-by-side layouts.
    static let regularWidthScoringPadWidth: CGFloat = 420

    /// Fixed scoring pad width on iPad landscape side-by-side layouts.
    static let iPadLandscapeScoringPadWidth: CGFloat = 300

    /// Taller keys on iPad side-by-side pads so targets stay comfortable on a tablet.
    static let iPadSideBySidePadKeyMinHeight: CGFloat = 64

    static let iPadSideBySidePadSpacing: CGFloat = 8

    /// Number-pad columns on iPad side-by-side: fewer columns → wider keys in the sidebar.
    static let iPadSideBySidePadColumnCount: Int = 5

    static func scoringPadFixedWidth(
        horizontalSizeClass: UserInterfaceSizeClass?,
        verticalSizeClass: UserInterfaceSizeClass?,
        isPad: Bool = defaultIsPad
    ) -> CGFloat {
        if usesIPadPortraitMatchScoringLayout(
            horizontalSizeClass: horizontalSizeClass,
            verticalSizeClass: verticalSizeClass
        ) {
            return regularWidthScoringPadWidth
        }
        if usesLandscapeIPadMatchScoringLayout(
            horizontalSizeClass: horizontalSizeClass,
            verticalSizeClass: verticalSizeClass,
            isPad: isPad
        ) {
            return iPadLandscapeScoringPadWidth
        }
        return landscapeScoringPadWidth
    }

    /// Standard match layouts dock the pad beside inactive players — compact grid, not a full-height sidebar.
    static func usesBottomDockedScoringPad(dynamicTypeSize: DynamicTypeSize) -> Bool {
        !usesAccessibilityMatchScoringLayout(dynamicTypeSize: dynamicTypeSize)
    }

    /// iPad only: inactive scoreboard scrolls beside a fixed-width pad column below the active band.
    /// iPhone stacks scoreboard, banners, and pad full width (portrait and landscape).
    static func usesSideBySideBottomScoringRegion(
        horizontalSizeClass: UserInterfaceSizeClass?,
        verticalSizeClass: UserInterfaceSizeClass?,
        isPad: Bool = defaultIsPad
    ) -> Bool {
        (isPad && usesIPadPortraitMatchScoringLayout(
            horizontalSizeClass: horizontalSizeClass,
            verticalSizeClass: verticalSizeClass
        )) || usesLandscapeIPadMatchScoringLayout(
            horizontalSizeClass: horizontalSizeClass,
            verticalSizeClass: verticalSizeClass,
            isPad: isPad
        )
    }

    /// Deprecated: pads no longer fill a full-height iPad sidebar.
    static func usesIPadSideBySideScoringPad(
        horizontalSizeClass: UserInterfaceSizeClass?,
        verticalSizeClass: UserInterfaceSizeClass?,
        dynamicTypeSize: DynamicTypeSize,
        isPad: Bool = defaultIsPad
    ) -> Bool {
        _ = horizontalSizeClass
        _ = verticalSizeClass
        _ = isPad
        return false
    }

    /// Width of the bottom-trailing pad column (landscape phone, iPad, or compact portrait phone).
    static func bottomScoringPadColumnWidth(
        horizontalSizeClass: UserInterfaceSizeClass?,
        verticalSizeClass: UserInterfaceSizeClass?,
        isPad: Bool = defaultIsPad
    ) -> CGFloat {
        if usesLandscapeMatchScoringLayout(verticalSizeClass: verticalSizeClass) {
            return scoringPadFixedWidth(
                horizontalSizeClass: horizontalSizeClass,
                verticalSizeClass: verticalSizeClass,
                isPad: isPad
            )
        }
        if usesIPadPortraitMatchScoringLayout(
            horizontalSizeClass: horizontalSizeClass,
            verticalSizeClass: verticalSizeClass
        ) {
            return regularWidthScoringPadWidth
        }
        return phonePortraitBottomPadMinWidth
    }

    /// iPad portrait side-by-side only — landscape uses the fill-height board variant.
    static func usesIPadPortraitSideBySideMatchScoringLayout(
        horizontalSizeClass: UserInterfaceSizeClass?,
        verticalSizeClass: UserInterfaceSizeClass?
    ) -> Bool {
        usesIPadPortraitMatchScoringLayout(
            horizontalSizeClass: horizontalSizeClass,
            verticalSizeClass: verticalSizeClass
        )
    }

    /// X01 side-by-side scoreboard + pad: iPad portrait and iPad landscape (not iPhone landscape).
    static func usesX01SideBySideMatchScoringLayout(
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

    /// iPhone landscape match summary: celebration beside player cards; actions along the bottom.
    static func usesLandscapeIPhoneMatchSummaryLayout(
        horizontalSizeClass: UserInterfaceSizeClass?,
        verticalSizeClass: UserInterfaceSizeClass?,
        dynamicTypeSize: DynamicTypeSize,
        isPad: Bool = defaultIsPad
    ) -> Bool {
        _ = horizontalSizeClass
        guard !usesAccessibilityMatchScoringLayout(dynamicTypeSize: dynamicTypeSize) else { return false }
        return usesLandscapeIPhoneOnlyMatchScoringLayout(
            horizontalSizeClass: horizontalSizeClass,
            verticalSizeClass: verticalSizeClass,
            isPad: isPad
        )
    }

    /// Side-by-side player stat cards when width allows (iPad regular, iPhone 2-player portrait).
    static func usesMatchSummarySideBySidePlayerGrid(
        horizontalSizeClass: UserInterfaceSizeClass?,
        playerCount: Int,
        dynamicTypeSize: DynamicTypeSize
    ) -> Bool {
        guard playerCount >= 2 else { return false }
        guard !usesAccessibilityMatchScoringLayout(dynamicTypeSize: dynamicTypeSize) else { return false }
        if horizontalSizeClass == .regular { return true }
        return playerCount == 2
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

import SwiftUI
import Testing
@testable import DartBuddy

@Test(.tags(.unit, .regression))
func gameplayLayoutUsesWideMaxOnRegularSizeClass() {
    #expect(GameplayLayout.contentMaxWidth(horizontalSizeClass: .regular) == 920)
}

@Test(.tags(.unit, .regression))
func gameplayLayoutUsesFullWidthOnCompactSizeClass() {
    #expect(GameplayLayout.contentMaxWidth(horizontalSizeClass: .compact) == .infinity)
    #expect(GameplayLayout.contentMaxWidth(horizontalSizeClass: nil) == .infinity)
}

@Test(.tags(.unit, .regression))
func gameplayLayoutMatchScreensUseFullWidthOnAllSizeClasses() {
    #expect(GameplayLayout.matchContentMaxWidth(horizontalSizeClass: .regular) == .infinity)
    #expect(GameplayLayout.matchContentMaxWidth(horizontalSizeClass: .compact) == .infinity)
    #expect(GameplayLayout.matchContentMaxWidth(horizontalSizeClass: nil) == .infinity)
}

@Test(.tags(.unit, .regression))
func gameplayLayoutUsesAccessibilityMatchScoringOnlyAtAXSizes() {
    #expect(GameplayLayout.usesAccessibilityMatchScoringLayout(dynamicTypeSize: .large) == false)
    #expect(GameplayLayout.usesAccessibilityMatchScoringLayout(dynamicTypeSize: .xxxLarge) == false)
    #expect(GameplayLayout.usesAccessibilityMatchScoringLayout(dynamicTypeSize: .accessibility1) == true)
    #expect(GameplayLayout.usesAccessibilityMatchScoringLayout(dynamicTypeSize: .accessibility5) == true)
}

@Test(.tags(.unit, .regression))
func gameplayLayoutScoringPadUsesFourColumnsAtAXSizes() {
    #expect(GameplayLayout.scoringPadColumnCount(dynamicTypeSize: .large) == 7)
    #expect(GameplayLayout.scoringPadColumnCount(dynamicTypeSize: .accessibility3) == 4)
}

@Test(.tags(.unit, .regression, .accessibility))
func gameplayLayoutUsesAccessibilitySetupHomeOnlyAtAXSizes() {
    #expect(GameplayLayout.usesAccessibilitySetupHomeLayout(dynamicTypeSize: .large) == false)
    #expect(GameplayLayout.usesAccessibilitySetupHomeLayout(dynamicTypeSize: .xxxLarge) == false)
    #expect(GameplayLayout.usesAccessibilitySetupHomeLayout(dynamicTypeSize: .accessibility1) == true)
    #expect(GameplayLayout.usesAccessibilitySetupHomeLayout(dynamicTypeSize: .accessibility5) == true)
}

@Test(.tags(.unit, .regression))
func gameplayLayoutUsesLandscapeIPhoneMatchScoringOnlyOnPhoneIdiomInLandscape() {
    #expect(
        GameplayLayout.usesLandscapeIPhoneMatchScoringLayout(
            horizontalSizeClass: .compact,
            verticalSizeClass: .compact,
            isPad: false
        ) == true
    )
    #expect(
        GameplayLayout.usesLandscapeIPhoneMatchScoringLayout(
            horizontalSizeClass: .regular,
            verticalSizeClass: .compact,
            isPad: false
        ) == true
    )
    #expect(
        GameplayLayout.usesLandscapeIPhoneMatchScoringLayout(
            horizontalSizeClass: .regular,
            verticalSizeClass: .compact,
            isPad: true
        ) == false
    )
    #expect(
        GameplayLayout.usesLandscapeIPhoneMatchScoringLayout(
            horizontalSizeClass: .regular,
            verticalSizeClass: .regular,
            isPad: false
        ) == false
    )
}

@Test(.tags(.unit, .regression))
func gameplayLayoutLandscapeIPhoneMatchScoringAlignsWithIPhoneOnlyHelper() {
    let combos: [(UserInterfaceSizeClass?, UserInterfaceSizeClass?, Bool)] = [
        (.compact, .compact, false),
        (.regular, .compact, false),
        (.regular, .compact, true),
        (.compact, .regular, false),
        (.regular, .regular, true)
    ]
    for (horizontal, vertical, isPad) in combos {
        #expect(
            GameplayLayout.usesLandscapeIPhoneMatchScoringLayout(
                horizontalSizeClass: horizontal,
                verticalSizeClass: vertical,
                isPad: isPad
            ) == GameplayLayout.usesLandscapeIPhoneOnlyMatchScoringLayout(
                horizontalSizeClass: horizontal,
                verticalSizeClass: vertical,
                isPad: isPad
            )
        )
    }
}

@Test(.tags(.unit, .cricket, .regression))
func gameplayLayoutSplitsLandscapeIPhoneAndIPadFormFactors() {
    #expect(
        GameplayLayout.usesLandscapeIPhoneOnlyMatchScoringLayout(
            horizontalSizeClass: .compact,
            verticalSizeClass: .compact,
            isPad: false
        ) == true
    )
    // Plus/Max iPhones report regular width in landscape but remain phone idiom.
    #expect(
        GameplayLayout.usesLandscapeIPhoneOnlyMatchScoringLayout(
            horizontalSizeClass: .regular,
            verticalSizeClass: .compact,
            isPad: false
        ) == true
    )
    #expect(
        GameplayLayout.usesLandscapeIPhoneOnlyMatchScoringLayout(
            horizontalSizeClass: .regular,
            verticalSizeClass: .compact,
            isPad: true
        ) == false
    )
    #expect(
        GameplayLayout.usesLandscapeIPadMatchScoringLayout(
            horizontalSizeClass: .regular,
            verticalSizeClass: .compact,
            isPad: true
        ) == true
    )
    #expect(
        GameplayLayout.usesTransposedCricketBoardLayout(
            horizontalSizeClass: .regular,
            verticalSizeClass: .compact,
            isPad: false
        ) == true
    )
    #expect(
        GameplayLayout.usesCricketBoardFillsAvailableHeight(
            horizontalSizeClass: .regular,
            verticalSizeClass: .compact,
            isPad: true
        ) == true
    )
    #expect(
        GameplayLayout.usesCricketBoardFillsAvailableHeight(
            horizontalSizeClass: .regular,
            verticalSizeClass: .compact,
            isPad: false
        ) == false
    )
}

@Test(.tags(.unit, .cricket, .regression))
func gameplayLayoutPinsCricketLandscapeOnIPhoneButNotIPad() {
    // iPhone landscape: pinned board + full-width pad (any horizontal size class on phone idiom).
    #expect(
        GameplayLayout.usesCricketLandscapePinnedLayout(
            horizontalSizeClass: .compact,
            verticalSizeClass: .compact,
            dynamicTypeSize: .large,
            isPad: false
        ) == true
    )
    #expect(
        GameplayLayout.usesCricketLandscapePinnedLayout(
            horizontalSizeClass: .regular,
            verticalSizeClass: .compact,
            dynamicTypeSize: .large,
            isPad: false
        ) == true
    )
    // iPad landscape keeps the side-by-side board + sidebar pad.
    #expect(
        GameplayLayout.usesCricketLandscapePinnedLayout(
            horizontalSizeClass: .regular,
            verticalSizeClass: .compact,
            dynamicTypeSize: .large,
            isPad: true
        ) == false
    )
    // Portrait iPhone keeps the stacked board-over-pad layout.
    #expect(
        GameplayLayout.usesCricketLandscapePinnedLayout(
            horizontalSizeClass: .compact,
            verticalSizeClass: .regular,
            dynamicTypeSize: .large,
            isPad: false
        ) == false
    )
}

@Test(.tags(.unit, .cricket, .regression, .accessibility))
func gameplayLayoutDropsCricketLandscapePinnedLayoutAtAXSizes() {
    // AX sizes scroll the board above the pad instead of pinning it in landscape.
    #expect(
        GameplayLayout.usesCricketLandscapePinnedLayout(
            horizontalSizeClass: .compact,
            verticalSizeClass: .compact,
            dynamicTypeSize: .accessibility3
        ) == false
    )
    #expect(
        GameplayLayout.usesCricketFullWidthLandscapePad(
            horizontalSizeClass: .compact,
            verticalSizeClass: .compact,
            dynamicTypeSize: .accessibility3
        ) == false
    )
}

@Test(.tags(.unit, .cricket, .regression))
func gameplayLayoutUsesFullWidthCricketPadOnlyInIPhoneLandscape() {
    #expect(
        GameplayLayout.usesCricketFullWidthLandscapePad(
            horizontalSizeClass: .compact,
            verticalSizeClass: .compact,
            dynamicTypeSize: .large,
            isPad: false
        ) == true
    )
    #expect(
        GameplayLayout.usesCricketFullWidthLandscapePad(
            horizontalSizeClass: .regular,
            verticalSizeClass: .compact,
            dynamicTypeSize: .large,
            isPad: false
        ) == true
    )
    #expect(
        GameplayLayout.usesCricketFullWidthLandscapePad(
            horizontalSizeClass: .regular,
            verticalSizeClass: .compact,
            dynamicTypeSize: .large,
            isPad: true
        ) == false
    )
}

/// Locks the Cricket landscape decision matrix: iPhone pins the board above a
/// full-width pad, while iPad keeps the side-by-side full board. The two layouts
/// must never both claim the same size-class combination.
@Test(.tags(.unit, .cricket, .regression))
func gameplayLayoutCricketLandscapeMatrixIsMutuallyExclusive() {
    // iPhone landscape: pinned board + full-width pad, NOT the iPad fill-height board.
    #expect(
        GameplayLayout.usesCricketLandscapePinnedLayout(
            horizontalSizeClass: .regular,
            verticalSizeClass: .compact,
            dynamicTypeSize: .large,
            isPad: false
        ) == true
    )
    #expect(
        GameplayLayout.usesCricketBoardFillsAvailableHeight(
            horizontalSizeClass: .regular,
            verticalSizeClass: .compact,
            isPad: false
        ) == false
    )

    // iPad landscape: fill-height full board, NOT the iPhone pinned layout.
    #expect(
        GameplayLayout.usesCricketLandscapePinnedLayout(
            horizontalSizeClass: .regular,
            verticalSizeClass: .compact,
            dynamicTypeSize: .large,
            isPad: true
        ) == false
    )
    #expect(
        GameplayLayout.usesCricketBoardFillsAvailableHeight(
            horizontalSizeClass: .regular,
            verticalSizeClass: .compact,
            isPad: true
        ) == true
    )

    // Portrait (iPhone and iPad) uses neither landscape branch.
    for horizontal in [UserInterfaceSizeClass.compact, .regular] {
        #expect(
            GameplayLayout.usesCricketLandscapePinnedLayout(
                horizontalSizeClass: horizontal,
                verticalSizeClass: .regular,
                dynamicTypeSize: .large,
                isPad: false
            ) == false
        )
    }
}

/// The pinned full-width pad layout is keyed off the same predicate, so they stay in lockstep.
@Test(.tags(.unit, .cricket, .regression))
func gameplayLayoutCricketPinnedLayoutAndFullWidthPadAgree() {
    let combos: [(UserInterfaceSizeClass?, UserInterfaceSizeClass?, DynamicTypeSize, Bool)] = [
        (.compact, .compact, .large, false),
        (.regular, .compact, .large, false),
        (.regular, .compact, .large, true),
        (.compact, .regular, .large, false),
        (.regular, .regular, .large, true),
        (.compact, .compact, .accessibility1, false),
        (.compact, .compact, .accessibility5, false)
    ]
    for (horizontal, vertical, size, isPad) in combos {
        #expect(
            GameplayLayout.usesCricketLandscapePinnedLayout(
                horizontalSizeClass: horizontal,
                verticalSizeClass: vertical,
                dynamicTypeSize: size,
                isPad: isPad
            ) == GameplayLayout.usesCricketFullWidthLandscapePad(
                horizontalSizeClass: horizontal,
                verticalSizeClass: vertical,
                dynamicTypeSize: size,
                isPad: isPad
            )
        )
    }
}

@Test(.tags(.unit, .cricket, .regression))
func gameplayLayoutCricketSideBySideExcludesIPhoneLandscape() {
    #expect(
        GameplayLayout.usesCricketSideBySideMatchScoringLayout(
            horizontalSizeClass: .regular,
            verticalSizeClass: .compact,
            dynamicTypeSize: .large,
            isPad: false
        ) == false
    )
    #expect(
        GameplayLayout.usesCricketSideBySideMatchScoringLayout(
            horizontalSizeClass: .regular,
            verticalSizeClass: .compact,
            dynamicTypeSize: .large,
            isPad: true
        ) == true
    )
    #expect(
        GameplayLayout.usesCricketSideBySideMatchScoringLayout(
            horizontalSizeClass: .regular,
            verticalSizeClass: .regular,
            dynamicTypeSize: .large,
            isPad: true
        ) == true
    )
}

@Test(.tags(.unit, .regression))
func gameplayLayoutUsesIPadPortraitMatchScoringOnlyOnRegularSizeClasses() {
    #expect(
        GameplayLayout.usesIPadPortraitMatchScoringLayout(
            horizontalSizeClass: .regular,
            verticalSizeClass: .regular
        ) == true
    )
    #expect(
        GameplayLayout.usesIPadPortraitMatchScoringLayout(
            horizontalSizeClass: .compact,
            verticalSizeClass: .compact
        ) == false
    )
    #expect(
        GameplayLayout.usesIPadPortraitMatchScoringLayout(
            horizontalSizeClass: .regular,
            verticalSizeClass: .compact
        ) == false
    )
}

@Test(.tags(.unit, .regression))
func gameplayLayoutUsesSideBySideMatchScoringOnRegularHorizontalSizeClass() {
    #expect(
        GameplayLayout.usesSideBySideMatchScoringLayout(
            horizontalSizeClass: .regular,
            verticalSizeClass: .regular
        ) == true
    )
    #expect(
        GameplayLayout.usesSideBySideMatchScoringLayout(
            horizontalSizeClass: .compact,
            verticalSizeClass: .compact
        ) == true
    )
    #expect(
        GameplayLayout.usesSideBySideMatchScoringLayout(
            horizontalSizeClass: .compact,
            verticalSizeClass: .regular
        ) == false
    )
}

@Test(.tags(.unit, .regression))
func gameplayLayoutScoringPadWidthMatchesFormFactor() {
    #expect(
        GameplayLayout.scoringPadFixedWidth(
            horizontalSizeClass: .regular,
            verticalSizeClass: .regular
        ) == GameplayLayout.regularWidthScoringPadWidth
    )
    #expect(
        GameplayLayout.scoringPadFixedWidth(
            horizontalSizeClass: .regular,
            verticalSizeClass: .compact,
            isPad: true
        ) == GameplayLayout.iPadLandscapeScoringPadWidth
    )
    #expect(
        GameplayLayout.scoringPadFixedWidth(
            horizontalSizeClass: .regular,
            verticalSizeClass: .compact,
            isPad: false
        ) == GameplayLayout.landscapeScoringPadWidth
    )
    #expect(
        GameplayLayout.scoringPadFixedWidth(
            horizontalSizeClass: .compact,
            verticalSizeClass: .compact,
            isPad: false
        ) == GameplayLayout.landscapeScoringPadWidth
    )
    #expect(
        GameplayLayout.scoringPadFixedWidth(
            horizontalSizeClass: .compact,
            verticalSizeClass: .compact,
            isPad: true
        ) == GameplayLayout.iPadLandscapeScoringPadWidth
    )
}

@Test(.tags(.unit, .regression))
func gameplayLayoutUsesWideSetupHomeOnlyOnIPadRegularWidth() {
    #expect(
        GameplayLayout.usesWideSetupHomeLayout(
            horizontalSizeClass: .regular,
            dynamicTypeSize: .large
        ) == true
    )
    #expect(
        GameplayLayout.usesWideSetupHomeLayout(
            horizontalSizeClass: .compact,
            dynamicTypeSize: .large
        ) == false
    )
    #expect(
        GameplayLayout.usesWideSetupHomeLayout(
            horizontalSizeClass: .regular,
            dynamicTypeSize: .accessibility3
        ) == false
    )
}

@Test(.tags(.unit, .regression, .accessibility))
func gameplayLayoutIPadSideBySidePadTargetsMeetComfortableTabletSizing() {
    #expect(GameplayLayout.iPadSideBySidePadKeyMinHeight >= 44)
    #expect(GameplayLayout.iPadSideBySidePadColumnCount == 5)
    #expect(GameplayLayout.regularWidthScoringPadWidth > GameplayLayout.landscapeScoringPadWidth)
}

@Test(.tags(.unit, .regression))
func gameplayLayoutUsesBottomDockedScoringPadOutsideAccessibilitySizes() {
    #expect(GameplayLayout.usesBottomDockedScoringPad(dynamicTypeSize: .large) == true)
    #expect(GameplayLayout.usesBottomDockedScoringPad(dynamicTypeSize: .accessibility3) == false)
}

@Test(.tags(.unit, .regression))
func gameplayLayoutSideBySideBottomScoringRegionIsIPadOnly() {
    #expect(
        GameplayLayout.usesSideBySideBottomScoringRegion(
            horizontalSizeClass: .compact,
            verticalSizeClass: .regular,
            isPad: false
        ) == false
    )
    #expect(
        GameplayLayout.usesSideBySideBottomScoringRegion(
            horizontalSizeClass: .regular,
            verticalSizeClass: .compact,
            isPad: false
        ) == false
    )
    #expect(
        GameplayLayout.usesSideBySideBottomScoringRegion(
            horizontalSizeClass: .regular,
            verticalSizeClass: .regular,
            isPad: true
        ) == true
    )
    #expect(
        GameplayLayout.usesSideBySideBottomScoringRegion(
            horizontalSizeClass: .regular,
            verticalSizeClass: .regular,
            isPad: false
        ) == false
    )
    #expect(
        GameplayLayout.usesSideBySideBottomScoringRegion(
            horizontalSizeClass: .regular,
            verticalSizeClass: .compact,
            isPad: true
        ) == true
    )
}

@Test(.tags(.unit, .regression))
func gameplayLayoutBottomScoringPadColumnWidthTracksFormFactor() {
    #expect(
        GameplayLayout.bottomScoringPadColumnWidth(
            horizontalSizeClass: .regular,
            verticalSizeClass: .regular,
            isPad: true
        ) == GameplayLayout.regularWidthScoringPadWidth
    )
    #expect(
        GameplayLayout.bottomScoringPadColumnWidth(
            horizontalSizeClass: .compact,
            verticalSizeClass: .regular,
            isPad: false
        ) == GameplayLayout.phonePortraitBottomPadMinWidth
    )
}

@Test(.tags(.unit, .regression))
func gameplayLayoutDeprecatedIPadSideBySideScoringPadIsDisabled() {
    #expect(
        GameplayLayout.usesIPadSideBySideScoringPad(
            horizontalSizeClass: .regular,
            verticalSizeClass: .regular,
            dynamicTypeSize: .large,
            isPad: true
        ) == false
    )
    #expect(
        GameplayLayout.usesIPadSideBySideScoringPad(
            horizontalSizeClass: .regular,
            verticalSizeClass: .compact,
            dynamicTypeSize: .large,
            isPad: true
        ) == false
    )
}

@Test(.tags(.unit, .regression))
func gameplayLayoutUsesLandscapeMatchScoringOnlyWithCompactVerticalSizeClass() {
    #expect(GameplayLayout.usesLandscapeMatchScoringLayout(verticalSizeClass: .compact) == true)
    #expect(GameplayLayout.usesLandscapeMatchScoringLayout(verticalSizeClass: .regular) == false)
    #expect(GameplayLayout.usesLandscapeMatchScoringLayout(verticalSizeClass: nil) == false)
}

@Test(.tags(.unit, .x01, .regression))
func gameplayLayoutWidePlayerScoreCardRequiresPadIdiom() {
    #expect(
        GameplayLayout.usesWidePlayerScoreCardLayout(
            horizontalSizeClass: .regular,
            dynamicTypeSize: .large,
            isPad: false
        ) == false
    )
    #expect(
        GameplayLayout.usesWidePlayerScoreCardLayout(
            horizontalSizeClass: .regular,
            dynamicTypeSize: .large,
            isPad: true
        ) == true
    )
    #expect(
        GameplayLayout.usesWidePlayerScoreCardLayout(
            horizontalSizeClass: .compact,
            dynamicTypeSize: .large,
            isPad: true
        ) == false
    )
}

@Test(.tags(.unit, .regression))
func gameplayLayoutLandscapePadWidthIsFixedForCompactPad() {
    #expect(GameplayLayout.landscapeScoringPadWidth == 252)
}

@Test(.tags(.unit, .x01, .regression))
func gameplayLayoutPinsActiveX01CardForThreePlusPlayersInPortrait() {
    #expect(
        GameplayLayout.usesPinnedActiveX01PlayerCard(
            playerCount: 2,
            dynamicTypeSize: .large,
            verticalSizeClass: .regular
        ) == false
    )
    #expect(
        GameplayLayout.usesPinnedActiveX01PlayerCard(
            playerCount: 3,
            dynamicTypeSize: .large,
            verticalSizeClass: .regular
        ) == true
    )
    #expect(
        GameplayLayout.usesPinnedActiveX01PlayerCard(
            playerCount: 4,
            dynamicTypeSize: .xxxLarge,
            verticalSizeClass: .regular
        ) == true
    )
    #expect(
        GameplayLayout.usesPinnedActiveX01PlayerCard(
            playerCount: 4,
            dynamicTypeSize: .accessibility3,
            verticalSizeClass: .regular
        ) == false
    )
}

@Test(.tags(.unit, .x01, .regression))
func gameplayLayoutPinsActiveX01CardInLandscape() {
    #expect(
        GameplayLayout.usesPinnedActiveX01PlayerCard(
            playerCount: 2,
            dynamicTypeSize: .large,
            verticalSizeClass: .compact
        ) == true
    )
    #expect(
        GameplayLayout.usesX01SideBySideMatchScoringLayout(
            horizontalSizeClass: .compact,
            verticalSizeClass: .compact,
            dynamicTypeSize: .large,
            isPad: false
        ) == false
    )
    #expect(
        GameplayLayout.usesX01SideBySideMatchScoringLayout(
            horizontalSizeClass: .regular,
            verticalSizeClass: .regular,
            dynamicTypeSize: .large,
            isPad: true
        ) == true
    )
}

@Test(.tags(.unit, .x01, .regression))
func gameplayLayoutUsesX01SideBySideOnIPadLandscapeNotIPhoneLandscape() {
    #expect(
        GameplayLayout.usesX01SideBySideMatchScoringLayout(
            horizontalSizeClass: .regular,
            verticalSizeClass: .compact,
            dynamicTypeSize: .large,
            isPad: true
        ) == true
    )
    #expect(
        GameplayLayout.usesX01SideBySideMatchScoringLayout(
            horizontalSizeClass: .regular,
            verticalSizeClass: .compact,
            dynamicTypeSize: .large,
            isPad: false
        ) == false
    )
}

@Test(.tags(.unit, .x01, .cricket, .regression))
func gameplayLayoutX01AndCricketSideBySideMatchOnIPadFormFactors() {
    let iPadCombos: [(UserInterfaceSizeClass?, UserInterfaceSizeClass?)] = [
        (.regular, .regular),
        (.regular, .compact)
    ]
    for (horizontal, vertical) in iPadCombos {
        #expect(
            GameplayLayout.usesX01SideBySideMatchScoringLayout(
                horizontalSizeClass: horizontal,
                verticalSizeClass: vertical,
                dynamicTypeSize: .large,
                isPad: true
            ) == GameplayLayout.usesCricketSideBySideMatchScoringLayout(
                horizontalSizeClass: horizontal,
                verticalSizeClass: vertical,
                dynamicTypeSize: .large,
                isPad: true
            )
        )
    }
    #expect(
        GameplayLayout.usesIPadPortraitSideBySideMatchScoringLayout(
            horizontalSizeClass: .regular,
            verticalSizeClass: .regular
        ) == true
    )
    #expect(
        GameplayLayout.usesIPadPortraitSideBySideMatchScoringLayout(
            horizontalSizeClass: .regular,
            verticalSizeClass: .compact
        ) == false
    )
}

@Test(.tags(.unit, .regression, .accessibility))
func gameplayLayoutUsesAccessibilityTabListOnlyAtAXSizes() {
    #expect(GameplayLayout.usesAccessibilityTabListLayout(dynamicTypeSize: .large) == false)
    #expect(GameplayLayout.usesAccessibilityTabListLayout(dynamicTypeSize: .accessibility1) == true)
}

@Test(.tags(.unit, .regression, .accessibility))
func gameplayLayoutTabScrollPaddingIncreasesAtAXSizes() {
    #expect(GameplayLayout.tabScrollBottomPadding(dynamicTypeSize: .large) == DS.Spacing.s6)
    #expect(GameplayLayout.tabScrollBottomPadding(dynamicTypeSize: .accessibility3) > DS.Spacing.s6)
}

@Test(.tags(.unit, .regression))
func gameplayLayoutUsesLandscapeIPhoneMatchSummaryOnlyOnPhoneLandscape() {
    #expect(
        GameplayLayout.usesLandscapeIPhoneMatchSummaryLayout(
            horizontalSizeClass: .compact,
            verticalSizeClass: .compact,
            dynamicTypeSize: .large,
            isPad: false
        ) == true
    )
    #expect(
        GameplayLayout.usesLandscapeIPhoneMatchSummaryLayout(
            horizontalSizeClass: .regular,
            verticalSizeClass: .compact,
            dynamicTypeSize: .large,
            isPad: false
        ) == true
    )
    #expect(
        GameplayLayout.usesLandscapeIPhoneMatchSummaryLayout(
            horizontalSizeClass: .regular,
            verticalSizeClass: .compact,
            dynamicTypeSize: .large,
            isPad: true
        ) == false
    )
    #expect(
        GameplayLayout.usesLandscapeIPhoneMatchSummaryLayout(
            horizontalSizeClass: .compact,
            verticalSizeClass: .regular,
            dynamicTypeSize: .large,
            isPad: false
        ) == false
    )
    #expect(
        GameplayLayout.usesLandscapeIPhoneMatchSummaryLayout(
            horizontalSizeClass: .compact,
            verticalSizeClass: .compact,
            dynamicTypeSize: .accessibility1,
            isPad: false
        ) == false
    )
}

@Test(.tags(.unit, .regression))
func gameplayLayoutUsesMatchSummarySideBySidePlayerGridWhenWidthAllows() {
    #expect(
        GameplayLayout.usesMatchSummarySideBySidePlayerGrid(
            horizontalSizeClass: .regular,
            playerCount: 2,
            dynamicTypeSize: .large
        ) == true
    )
    #expect(
        GameplayLayout.usesMatchSummarySideBySidePlayerGrid(
            horizontalSizeClass: .regular,
            playerCount: 4,
            dynamicTypeSize: .large
        ) == true
    )
    #expect(
        GameplayLayout.usesMatchSummarySideBySidePlayerGrid(
            horizontalSizeClass: .compact,
            playerCount: 2,
            dynamicTypeSize: .large
        ) == true
    )
    #expect(
        GameplayLayout.usesMatchSummarySideBySidePlayerGrid(
            horizontalSizeClass: .compact,
            playerCount: 3,
            dynamicTypeSize: .large
        ) == false
    )
    #expect(
        GameplayLayout.usesMatchSummarySideBySidePlayerGrid(
            horizontalSizeClass: .compact,
            playerCount: 2,
            dynamicTypeSize: .accessibility1
        ) == false
    )
}

import SwiftUI
import Testing
@testable import DartBuddy

@Test(.tags(.unit, .regression))
func gameplayLayoutUsesWideMaxOnRegularSizeClass() {
    #expect(GameplayLayout.contentMaxWidth(horizontalSizeClass: .regular) == 760)
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
func gameplayLayoutUsesLandscapeIPhoneMatchScoringOnlyOnCompactSizeClasses() {
    #expect(
        GameplayLayout.usesLandscapeIPhoneMatchScoringLayout(
            horizontalSizeClass: .compact,
            verticalSizeClass: .compact
        ) == true
    )
    #expect(
        GameplayLayout.usesLandscapeIPhoneMatchScoringLayout(
            horizontalSizeClass: .regular,
            verticalSizeClass: .regular
        ) == false
    )
    #expect(
        GameplayLayout.usesLandscapeIPhoneMatchScoringLayout(
            horizontalSizeClass: .regular,
            verticalSizeClass: .compact
        ) == true
    )
}

@Test(.tags(.unit, .cricket, .regression))
func gameplayLayoutSplitsLandscapeIPhoneAndIPadFormFactors() {
    #expect(
        GameplayLayout.usesLandscapeIPhoneOnlyMatchScoringLayout(
            horizontalSizeClass: .compact,
            verticalSizeClass: .compact
        ) == true
    )
    #expect(
        GameplayLayout.usesLandscapeIPhoneOnlyMatchScoringLayout(
            horizontalSizeClass: .regular,
            verticalSizeClass: .compact
        ) == false
    )
    #expect(
        GameplayLayout.usesLandscapeIPadMatchScoringLayout(
            horizontalSizeClass: .regular,
            verticalSizeClass: .compact
        ) == true
    )
    #expect(
        GameplayLayout.usesTransposedCricketBoardLayout(
            horizontalSizeClass: .compact,
            verticalSizeClass: .compact
        ) == true
    )
    #expect(
        GameplayLayout.usesCricketBoardFillsAvailableHeight(
            horizontalSizeClass: .regular,
            verticalSizeClass: .compact
        ) == true
    )
    #expect(
        GameplayLayout.usesCricketBoardFillsAvailableHeight(
            horizontalSizeClass: .compact,
            verticalSizeClass: .compact
        ) == false
    )
}

@Test(.tags(.unit, .cricket, .regression))
func gameplayLayoutPinsCricketLandscapeOnIPhoneButNotIPad() {
    // iPhone landscape (compact width + compact height): pinned board + full-width pad.
    #expect(
        GameplayLayout.usesCricketLandscapePinnedLayout(
            horizontalSizeClass: .compact,
            verticalSizeClass: .compact,
            dynamicTypeSize: .large
        ) == true
    )
    // iPad landscape (regular width): keeps the side-by-side board + sidebar pad.
    #expect(
        GameplayLayout.usesCricketLandscapePinnedLayout(
            horizontalSizeClass: .regular,
            verticalSizeClass: .compact,
            dynamicTypeSize: .large
        ) == false
    )
    // Portrait iPhone keeps the stacked board-over-pad layout.
    #expect(
        GameplayLayout.usesCricketLandscapePinnedLayout(
            horizontalSizeClass: .compact,
            verticalSizeClass: .regular,
            dynamicTypeSize: .large
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
            dynamicTypeSize: .large
        ) == true
    )
    #expect(
        GameplayLayout.usesCricketFullWidthLandscapePad(
            horizontalSizeClass: .regular,
            verticalSizeClass: .compact,
            dynamicTypeSize: .large
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
            horizontalSizeClass: .compact,
            verticalSizeClass: .compact,
            dynamicTypeSize: .large
        ) == true
    )
    #expect(
        GameplayLayout.usesCricketBoardFillsAvailableHeight(
            horizontalSizeClass: .compact,
            verticalSizeClass: .compact
        ) == false
    )

    // iPad landscape: fill-height full board, NOT the iPhone pinned layout.
    #expect(
        GameplayLayout.usesCricketLandscapePinnedLayout(
            horizontalSizeClass: .regular,
            verticalSizeClass: .compact,
            dynamicTypeSize: .large
        ) == false
    )
    #expect(
        GameplayLayout.usesCricketBoardFillsAvailableHeight(
            horizontalSizeClass: .regular,
            verticalSizeClass: .compact
        ) == true
    )

    // Portrait (iPhone and iPad) uses neither landscape branch.
    for horizontal in [UserInterfaceSizeClass.compact, .regular] {
        #expect(
            GameplayLayout.usesCricketLandscapePinnedLayout(
                horizontalSizeClass: horizontal,
                verticalSizeClass: .regular,
                dynamicTypeSize: .large
            ) == false
        )
    }
}

/// The pinned full-width pad layout is keyed off the same predicate, so they stay in lockstep.
@Test(.tags(.unit, .cricket, .regression))
func gameplayLayoutCricketPinnedLayoutAndFullWidthPadAgree() {
    let combos: [(UserInterfaceSizeClass?, UserInterfaceSizeClass?, DynamicTypeSize)] = [
        (.compact, .compact, .large),
        (.regular, .compact, .large),
        (.compact, .regular, .large),
        (.regular, .regular, .large),
        (.compact, .compact, .accessibility1),
        (.compact, .compact, .accessibility5)
    ]
    for (horizontal, vertical, size) in combos {
        #expect(
            GameplayLayout.usesCricketLandscapePinnedLayout(
                horizontalSizeClass: horizontal,
                verticalSizeClass: vertical,
                dynamicTypeSize: size
            ) == GameplayLayout.usesCricketFullWidthLandscapePad(
                horizontalSizeClass: horizontal,
                verticalSizeClass: vertical,
                dynamicTypeSize: size
            )
        )
    }
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
            horizontalSizeClass: .compact,
            verticalSizeClass: .compact
        ) == GameplayLayout.landscapeScoringPadWidth
    )
}

@Test(.tags(.unit, .regression))
func gameplayLayoutUsesLandscapeMatchScoringOnlyWithCompactVerticalSizeClass() {
    #expect(GameplayLayout.usesLandscapeMatchScoringLayout(verticalSizeClass: .compact) == true)
    #expect(GameplayLayout.usesLandscapeMatchScoringLayout(verticalSizeClass: .regular) == false)
    #expect(GameplayLayout.usesLandscapeMatchScoringLayout(verticalSizeClass: nil) == false)
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
            dynamicTypeSize: .large
        ) == false
    )
    #expect(
        GameplayLayout.usesX01SideBySideMatchScoringLayout(
            horizontalSizeClass: .regular,
            verticalSizeClass: .regular,
            dynamicTypeSize: .large
        ) == true
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

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
func gameplayLayoutPinsActiveX01CardForThreePlusPlayers() {
    #expect(
        GameplayLayout.usesPinnedActiveX01PlayerCard(playerCount: 2, dynamicTypeSize: .large) == false
    )
    #expect(
        GameplayLayout.usesPinnedActiveX01PlayerCard(playerCount: 3, dynamicTypeSize: .large) == true
    )
    #expect(
        GameplayLayout.usesPinnedActiveX01PlayerCard(playerCount: 4, dynamicTypeSize: .xxxLarge) == true
    )
    #expect(
        GameplayLayout.usesPinnedActiveX01PlayerCard(playerCount: 4, dynamicTypeSize: .accessibility3) == false
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

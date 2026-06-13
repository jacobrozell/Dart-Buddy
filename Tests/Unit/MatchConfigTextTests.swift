import Testing
@testable import DartBuddy

@Suite("Match config text", .tags(.unit, .history, .setupFlow, .regression))
struct MatchConfigTextTests {
    @Test
    func modeLabelsCoverEveryShippedMatchType() {
        for type in GameModeCatalog.all.filter({ $0.status == .shipped }).compactMap(\.matchType) {
            #expect(!MatchConfigText.modeLabel(for: type).isEmpty)
        }
    }

    @Test
    func modeLabelsCoverLegacyLeanSurfaceModes() {
        for type in [MatchType.x01, .cricket, .baseball, .killer, .shanghai] {
            #expect(!MatchConfigText.modeLabel(for: type).isEmpty)
        }
    }

    @Test
    func x01DetailPartsIncludeStartScoreAndCheckout() {
        let config = MatchConfigX01(
            startScore: 501,
            legsToWin: 3,
            setsEnabled: false,
            setsToWin: nil,
            checkoutMode: .doubleOut,
            checkInMode: .straightIn,
            legFormat: .firstTo
        )
        let parts = MatchConfigText.x01DetailParts(from: config)

        #expect(parts.contains("501"))
        #expect(parts.contains(config.checkoutMode.displayName))
        #expect(!parts.contains(config.checkInMode.displayName))
        #expect(parts.contains { $0.contains("3") })
    }

    @Test
    func x01DetailPartsIncludeCheckInWhenNotStraightIn() {
        let config = MatchConfigX01(
            startScore: 301,
            legsToWin: 1,
            setsEnabled: false,
            setsToWin: nil,
            checkoutMode: .singleOut,
            checkInMode: .doubleIn,
            legFormat: .firstTo
        )
        let parts = MatchConfigText.x01DetailParts(from: config)

        #expect(parts.contains(config.checkInMode.displayName))
    }

    @Test
    func x01CardConfigPrefixesModeLabel() {
        let config = MatchConfigX01(
            startScore: 501,
            legsToWin: 3,
            setsEnabled: false,
            setsToWin: nil,
            checkoutMode: .doubleOut
        )
        let text = MatchConfigText.x01CardConfig(from: config)

        #expect(text.contains(MatchConfigText.modeLabel(for: .x01)))
        #expect(text.contains("501"))
    }

    @Test
    func cricketNoScoreSubtitleUsesNoScoreCopy() {
        let config = MatchConfigCricket(pointsEnabled: false)
        #expect(MatchConfigText.cricketMatchSubtitle(from: config) == L10n.string("play.cricket.subtitle.noScore"))
    }

    @Test
    func cricketInlineConfigJoinsDetailParts() {
        let config = MatchConfigCricket(
            pointsEnabled: true,
            scoringMode: .cutThroat,
            legsToWin: 2,
            setsEnabled: false
        )
        let inline = MatchConfigText.cricketInlineConfig(from: config)
        #expect(inline.contains(config.scoringMode.displayName))
        #expect(inline.contains("·"))
    }

    @Test
    func cricketDetailPartsOmitScoringWhenPointsDisabled() {
        let config = MatchConfigCricket(pointsEnabled: false, legsToWin: 2, setsEnabled: false)
        let parts = MatchConfigText.cricketDetailParts(from: config)

        #expect(parts.contains(L10n.string("play.cricket.subtitle.noScore")))
        #expect(parts.allSatisfy { !$0.contains(L10n.string("play.cricket.mode.cutThroat")) })
    }

    @Test
    func playerNameFallsBackWhenNil() {
        #expect(MatchConfigText.playerName(nil) == L10n.string("common.playerFallback"))
        #expect(MatchConfigText.playerName("Alice") == "Alice")
    }

    @Test
    func playerNameForIndexIsOneBased() {
        #expect(MatchConfigText.playerName(forIndex: 0) == L10n.format("common.playerNumberFormat", 1))
        #expect(MatchConfigText.playerName(forIndex: 2) == L10n.format("common.playerNumberFormat", 3))
    }

    @Test
    func x01InlineConfigJoinsDetailPartsWithoutModePrefix() {
        let config = MatchConfigX01(
            startScore: 301,
            legsToWin: 2,
            setsEnabled: false,
            setsToWin: nil,
            checkoutMode: .singleOut
        )
        let inline = MatchConfigText.x01InlineConfig(from: config)

        #expect(inline.contains("301"))
        #expect(inline.contains(config.checkoutMode.displayName))
        #expect(!inline.contains(MatchConfigText.modeLabel(for: .x01)))
    }

    @Test
    func x01DetailPartsIncludeSetsWhenEnabled() {
        let config = MatchConfigX01(
            startScore: 501,
            legsToWin: 3,
            setsEnabled: true,
            setsToWin: 2,
            checkoutMode: .doubleOut
        )
        let parts = MatchConfigText.x01DetailParts(from: config)

        #expect(parts.contains { $0.contains("2") })
        #expect(parts.contains { $0.contains("3") })
    }

    @Test
    func cricketMatchSubtitleUsesStandardCopyWhenPointsEnabled() {
        let config = MatchConfigCricket(pointsEnabled: true, scoringMode: .standard)
        #expect(MatchConfigText.cricketMatchSubtitle(from: config) == L10n.string("play.cricket.subtitle.normal"))
    }

    @Test
    func cricketMatchSubtitleUsesCutThroatCopy() {
        let config = MatchConfigCricket(pointsEnabled: true, scoringMode: .cutThroat)
        #expect(MatchConfigText.cricketMatchSubtitle(from: config) == L10n.string("play.cricket.subtitle.cutThroatLowest"))
    }

    @Test
    func standingAccessibilityIncludesWinnerRole() {
        let winner = MatchConfigText.standingAccessibility(name: "Alice", isWinner: true, score: 0)
        let loser = MatchConfigText.standingAccessibility(name: "Bob", isWinner: false, score: 121)

        #expect(winner.contains("Alice"))
        #expect(winner.contains(L10n.string("history.standing.winnerRole")))
        #expect(!loser.contains(L10n.string("history.standing.winnerRole")))
        #expect(loser.contains("121"))
    }

    @Test
    func cricketDetailPartsIncludeSetsWhenEnabled() {
        let config = MatchConfigCricket(pointsEnabled: true, legsToWin: 2, setsEnabled: true, setsToWin: 3)
        let parts = MatchConfigText.cricketDetailParts(from: config)
        #expect(parts.contains { $0.contains("3") })
        #expect(parts.contains { $0.contains("2") })
    }

    @Test
    func x01DetailPartsUseSingularCopyForSingleSetAndLeg() {
        let config = MatchConfigX01(
            startScore: 501,
            legsToWin: 1,
            setsEnabled: true,
            setsToWin: 1,
            checkoutMode: .doubleOut
        )
        let parts = MatchConfigText.x01DetailParts(from: config)
        #expect(parts.filter { $0.contains("1") }.count >= 2)
    }
}

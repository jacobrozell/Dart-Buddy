import Foundation
import Testing
@testable import DartBuddy

@Suite("Match analytics", .tags(.unit, .logging, .regression))
struct MatchAnalyticsTests {
    @Test
    func metadataMergesConfigStartSourceAndBots() {
        let participants = [
            MatchParticipant(playerId: UUID(), displayNameAtMatchStart: "Jacob", turnOrder: 0),
            MatchParticipant(
                playerId: UUID(),
                displayNameAtMatchStart: "Bot",
                turnOrder: 1,
                botDifficultyRaw: BotDifficulty.hard.rawValue,
                botKindRaw: BotKind.preset.rawValue,
                botEffectiveTierRaw: BotDifficulty.hard.rawValue
            )
        ]

        let metadata = MatchAnalytics.metadata(
            for: .x01,
            config: .x01(
                MatchConfigX01(
                    startScore: 301,
                    legsToWin: 1,
                    setsEnabled: false,
                    setsToWin: nil,
                    checkoutMode: .singleOut
                )
            ),
            participantCount: participants.count,
            participants: participants,
            startSource: .rematch
        )

        #expect(metadata["gameModeId"] == "standard.x01")
        #expect(metadata["startSource"] == "rematch")
        #expect(metadata["configStartScore"] == "301")
        #expect(metadata["configCheckoutMode"] == "singleOut")
        #expect(metadata["botDifficulty"] == "hard")
    }

    @Test
    func sessionMetadataIncludesConfigAndLifecycleFields() throws {
        let session = try MatchLifecycleService.createMatch(
            type: .cricket,
            config: .cricket(
                MatchConfigCricket(pointsEnabled: true, scoringMode: .cutThroat)
            ),
            participants: [
                MatchParticipant(playerId: UUID(), displayNameAtMatchStart: "A", turnOrder: 0),
                MatchParticipant(playerId: UUID(), displayNameAtMatchStart: "B", turnOrder: 1)
            ]
        )

        let metadata = MatchAnalytics.metadata(for: session)

        #expect(metadata["gameModeId"] == "standard.cricket")
        #expect(metadata["configScoringMode"] == "cutThroat")
        #expect(metadata["status"] == MatchLifecycleStatus.inProgress.rawValue)
        #expect(metadata["eventCount"] == "0")
    }

    @Test
    func resumeMetadataUsesStartSourceAndMatchType() {
        let match = MatchSummary(
            id: UUID(),
            type: .x01,
            status: .inProgress,
            startedAt: Date(),
            endedAt: nil,
            winnerPlayerId: nil,
            currentTurnPlayerId: nil,
            currentLegIndex: 0,
            currentSetIndex: 0,
            eventCount: 4,
            createdAt: Date(),
            updatedAt: Date()
        )

        let metadata = MatchAnalytics.resumeMetadata(for: match, startSource: .deepLink)

        #expect(metadata["startSource"] == "deepLink")
        #expect(metadata["gameModeId"] == "standard.x01")
        #expect(metadata["status"] == MatchStatus.inProgress.rawValue)
    }
}

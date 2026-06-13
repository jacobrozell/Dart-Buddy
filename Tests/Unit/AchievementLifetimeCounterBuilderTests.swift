import Foundation
import Testing
@testable import DartBuddy

@Suite("Achievement lifetime counters", .tags(.unit, .achievements, .regression))
struct AchievementLifetimeCounterBuilderTests {
    @Test
    func humanPlayerIdsExcludesBots() throws {
        let humanId = UUID()
        let session = try MatchLifecycleService.createMatch(
            type: .x01,
            config: .x01(MatchConfigX01(
                startScore: 301,
                legsToWin: 1,
                setsEnabled: false,
                setsToWin: nil,
                checkoutMode: .singleOut
            )),
            participants: [
                MatchParticipant(playerId: humanId, displayNameAtMatchStart: "Human", turnOrder: 0),
                MatchParticipant(
                    playerId: UUID(),
                    displayNameAtMatchStart: "Bot",
                    turnOrder: 1,
                    botDifficultyRaw: BotDifficulty.medium.rawValue,
                    botKindRaw: BotKind.preset.rawValue
                )
            ]
        )

        let humanIds = AchievementLifetimeCounterBuilder.humanPlayerIds(in: session)

        #expect(humanIds == [humanId])
    }

    @Test
    func buildIncrementsCompletedMatchesAndWins() {
        let playerId = UUID()
        let match = MatchStatsInput(
            playedAt: Date(timeIntervalSince1970: 1_700_000_000),
            type: .x01,
            participantKeys: [playerId],
            winnerKey: playerId,
            events: [],
            isPartial: false
        )

        let counters = AchievementLifetimeCounterBuilder.build(
            completedMatches: [match],
            currentSession: nil,
            playerIds: [playerId]
        )

        #expect(counters[playerId]?.completedMatchesPlayed == 1)
        #expect(counters[playerId]?.matchWins == 1)
        #expect(counters[playerId]?.consecutiveMatchWins == 1)
    }

    @Test
    func buildCounts180VisitsForInProgressMatch() throws {
        let playerId = UUID()
        var session = try MatchLifecycleService.createMatch(
            type: .x01,
            config: .x01(MatchConfigX01(
                startScore: 501,
                legsToWin: 1,
                setsEnabled: false,
                setsToWin: nil,
                checkoutMode: .singleOut
            )),
            participants: [
                MatchParticipant(playerId: playerId, displayNameAtMatchStart: "Human", turnOrder: 0)
            ]
        )
        session = try MatchLifecycleService.submitX01Turn(session: session, enteredTotal: 180, darts: nil)

        let counters = AchievementLifetimeCounterBuilder.build(
            completedMatches: [],
            currentSession: session,
            playerIds: [playerId]
        )

        #expect(counters[playerId]?.lifetime180Visits == 1)
    }
}

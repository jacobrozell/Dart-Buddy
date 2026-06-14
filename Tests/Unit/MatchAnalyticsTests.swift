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
        #expect(metadata["eventCount"] == "4")
        #expect(metadata["participantCount"] == nil)
    }

    @Test
    func resumeMetadataUsesSessionConfigAndRosterWhenAvailable() throws {
        let matchId = UUID()
        let session = try MatchLifecycleService.createMatch(
            matchId: matchId,
            type: .x01,
            config: .x01(
                MatchConfigX01(
                    startScore: 301,
                    legsToWin: 1,
                    setsEnabled: false,
                    setsToWin: nil,
                    checkoutMode: .singleOut
                )
            ),
            participants: [
                MatchParticipant(playerId: UUID(), displayNameAtMatchStart: "A", turnOrder: 0),
                MatchParticipant(
                    playerId: UUID(),
                    displayNameAtMatchStart: "Bot",
                    turnOrder: 1,
                    botDifficultyRaw: BotDifficulty.easy.rawValue,
                    botKindRaw: BotKind.preset.rawValue,
                    botEffectiveTierRaw: BotDifficulty.easy.rawValue
                )
            ]
        )
        let match = MatchSummary(
            id: matchId,
            type: .x01,
            status: .inProgress,
            startedAt: Date(),
            endedAt: nil,
            winnerPlayerId: nil,
            currentTurnPlayerId: nil,
            currentLegIndex: 0,
            currentSetIndex: 0,
            eventCount: session.runtime.eventCount,
            createdAt: Date(),
            updatedAt: Date()
        )

        let metadata = MatchAnalytics.resumeMetadata(
            for: match,
            startSource: .resume,
            session: session
        )

        #expect(metadata["startSource"] == "resume")
        #expect(metadata["participantCount"] == "2")
        #expect(metadata["configStartScore"] == "301")
        #expect(metadata["botDifficulty"] == "easy")
    }

    @Test
    func metadataOmitsParticipantDisplayNames() {
        let humanName = "Jacob Rozell"
        let botRosterName = "Medium Bot"
        let participants = [
            MatchParticipant(playerId: UUID(), displayNameAtMatchStart: humanName, turnOrder: 0),
            MatchParticipant(
                playerId: UUID(),
                displayNameAtMatchStart: botRosterName,
                turnOrder: 1,
                botDifficultyRaw: BotDifficulty.medium.rawValue,
                botKindRaw: BotKind.preset.rawValue,
                botEffectiveTierRaw: BotDifficulty.medium.rawValue
            )
        ]

        let metadata = MatchAnalytics.metadata(
            for: .x01,
            config: .x01(
                MatchConfigX01(
                    startScore: 501,
                    legsToWin: 1,
                    setsEnabled: false,
                    setsToWin: nil,
                    checkoutMode: .doubleOut
                )
            ),
            participantCount: participants.count,
            participants: participants,
            startSource: .setup,
            extra: [
                "displayName": humanName,
                "playerName": humanName,
                "botName": botRosterName
            ]
        )

        for key in metadata.keys {
            #expect(!AnalyticsMetadataKeys.isBlockedPersonalDataKey(key))
        }
        for value in metadata.values {
            #expect(!value.contains(humanName))
            #expect(!value.contains(botRosterName))
        }
        #expect(metadata["botDifficulty"] == "medium")
    }

    @Test
    func forfeitMetadataIncludesResolutionAndDuration() throws {
        let session = try MatchLifecycleService.createMatch(
            type: .x01,
            config: .x01(
                MatchConfigX01(
                    startScore: 501,
                    legsToWin: 1,
                    setsEnabled: false,
                    setsToWin: nil,
                    checkoutMode: .doubleOut
                )
            ),
            participants: [
                MatchParticipant(playerId: UUID(), displayNameAtMatchStart: "A", turnOrder: 0),
                MatchParticipant(playerId: UUID(), displayNameAtMatchStart: "B", turnOrder: 1)
            ]
        )

        let metadata = MatchAnalytics.forfeitMetadata(
            for: session,
            resolution: "automatic",
            durationSeconds: 120
        )

        #expect(metadata["resolution"] == "automatic")
        #expect(metadata["durationSeconds"] == "120")
        #expect(metadata["eventCount"] == "0")
        #expect(metadata["participantCount"] == "2")
    }
}

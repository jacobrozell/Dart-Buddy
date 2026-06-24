import Foundation
import Testing
@testable import DartBuddy

@Suite("Default achievement service", .tags(.unit, .achievements, .regression))
struct DefaultAchievementServiceTests {
    @Test
    func evaluateAfterTurnReturnsEmptyWhenFlagDisabled() async throws {
        let playerId = UUID()
        let session = try makeHumanX01Session(playerId: playerId, afterTotals: [60])
        let achievementRepository = RecordingAchievementRepository()
        let service = DefaultAchievementService(
            achievementRepository: achievementRepository,
            matchRepository: EmptyHistoryMatchRepository(),
            statsRepository: EmptyStatsRepository(),
            featureFlags: StubFeatureFlags(flags: [.enableAchievements: false])
        )

        let presentations = try await service.evaluateAfterTurn(session: session)

        #expect(presentations.isEmpty)
        #expect(await achievementRepository.applyCount == 0)
    }

    @Test
    func evaluateAfterTurnReturnsEmptyForBotOnlyMatch() async throws {
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
                MatchParticipant(
                    playerId: UUID(),
                    displayNameAtMatchStart: "Bot",
                    turnOrder: 0,
                    botDifficultyRaw: BotDifficulty.medium.rawValue,
                    botKindRaw: BotKind.preset.rawValue
                )
            ]
        )
        let achievementRepository = RecordingAchievementRepository()
        let service = DefaultAchievementService(
            achievementRepository: achievementRepository,
            matchRepository: EmptyHistoryMatchRepository(),
            statsRepository: EmptyStatsRepository(),
            featureFlags: StubFeatureFlags(flags: [.enableAchievements: true])
        )

        let presentations = try await service.evaluateAfterTurn(session: session)

        #expect(presentations.isEmpty)
        #expect(await achievementRepository.applyCount == 0)
    }

    @Test
    func evaluateAfterTurnUnlocksT20WhenFlagEnabled() async throws {
        let playerId = UUID()
        var session = try makeHumanX01Session(playerId: playerId, afterTotals: [])
        session = try MatchLifecycleService.submitX01Turn(
            session: session,
            enteredTotal: 60,
            darts: [DartInput(multiplier: .triple, segment: .oneToTwenty(20))]
        )
        let achievementRepository = RecordingAchievementRepository()
        let service = DefaultAchievementService(
            achievementRepository: achievementRepository,
            matchRepository: EmptyHistoryMatchRepository(),
            statsRepository: EmptyStatsRepository(),
            featureFlags: StubFeatureFlags(flags: [.enableAchievements: true])
        )

        let presentations = try await service.evaluateAfterTurn(session: session)

        #expect(presentations.contains { $0.achievementId == "db.dart.first_t20" && $0.isNewUnlock })
        #expect(await achievementRepository.appliedAchievementIds.contains("db.dart.first_t20"))
    }
}

private func makeHumanX01Session(playerId: UUID, afterTotals: [Int]) throws -> MatchLifecycleSession {
    var session = try MatchLifecycleService.createMatch(
        type: .x01,
        config: .x01(MatchConfigX01(
            startScore: 301,
            legsToWin: 1,
            setsEnabled: false,
            setsToWin: nil,
            checkoutMode: .singleOut
        )),
        participants: [
            MatchParticipant(playerId: playerId, displayNameAtMatchStart: "Human", turnOrder: 0)
        ]
    )
    for total in afterTotals {
        session = try MatchLifecycleService.submitX01Turn(session: session, enteredTotal: total, darts: nil)
    }
    return session
}

private actor RecordingAchievementRepository: AchievementRepository {
    private(set) var applyCount = 0
    private(set) var appliedAchievementIds: [String] = []

    func fetchProgress(playerId _: UUID) async throws -> [PlayerAchievementProgress] { [] }

    func fetchProgress(playerIds _: [UUID]) async throws -> [UUID: [String: PlayerAchievementProgress]] { [:] }

    func apply(deltas: [AchievementDelta], matchId _: UUID) async throws -> [AchievementUnlockPresentation] {
        applyCount += 1
        appliedAchievementIds.append(contentsOf: deltas.map(\.achievementId))
        return deltas
            .filter { $0.kind == .unlock }
            .map { AchievementUnlockPresentation(playerId: $0.playerId, achievementId: $0.achievementId, isNewUnlock: true) }
    }
}

private actor EmptyHistoryMatchRepository: MatchRepository {
    func createMatch(type: MatchType, configPayload _: Data, participants _: [MatchParticipantSummary]) async throws -> MatchSummary {
        MatchSummary(
            id: UUID(),
            type: type,
            status: .inProgress,
            startedAt: Date(),
            endedAt: nil,
            winnerPlayerId: nil,
            forfeitedByPlayerId: nil,
            currentTurnPlayerId: nil,
            currentLegIndex: 0,
            currentSetIndex: 0,
            eventCount: 0,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
    func fetchActiveMatch() async throws -> MatchSummary? { nil }
    func fetchHistory(page _: Int, pageSize _: Int) async throws -> [MatchSummary] { [] }
    func fetchHistoryWithParticipants(page _: Int, pageSize _: Int, filter _: MatchHistoryFilter) async throws -> [MatchHistoryRecord] { [] }
    func updateMatch(_: MatchSummary) async throws {}
    func completeMatch(matchId _: UUID, endedAt _: Date, winnerPlayerId _: UUID?) async throws -> MatchSummary {
        fatalError("Not used in achievement service tests")
    }
    func appendEvent(matchId _: UUID, eventTypeRaw _: String, eventPayload _: Data) async throws -> MatchEventSummary {
        fatalError("Not used in achievement service tests")
    }
    func saveSnapshot(matchId _: UUID, snapshotVersion _: Int, snapshotPayload _: Data) async throws -> MatchSnapshotSummary {
        fatalError("Not used in achievement service tests")
    }
    func fetchLatestSnapshot(matchId _: UUID) async throws -> MatchSnapshotSummary? { nil }
    func fetchMatch(matchId _: UUID) async throws -> MatchSummary? { nil }
    func fetchParticipants(matchId _: UUID) async throws -> [MatchParticipantSummary] { [] }
    func deleteMatch(matchId _: UUID) async throws {}
}

private actor EmptyStatsRepository: StatsRepository {
    func fetchEvents(matchId _: UUID) async throws -> [MatchEventSummary] { [] }
    func fetchEvents(matchIds _: [UUID]) async throws -> [MatchEventSummary] { [] }
}

private struct StubFeatureFlags: FeatureFlagsProvider {
    let flags: [FeatureFlag: Bool]

    func isEnabled(_ flag: FeatureFlag) -> Bool {
        flags[flag] ?? false
    }
}

import Foundation
import SwiftData
import Testing
@testable import DartBuddy

@Suite("App bootstrapper", .tags(.integration, .migration, .swiftdata, .critical, .regression))
struct AppBootstrapperTests {
    @Test
    func diskBackedBootstrapSucceedsAfterX01AndCricketGames() async throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("dartbuddy-bootstrap-\(UUID().uuidString).sqlite")
        defer { try? FileManager.default.removeItem(at: url) }

        let container = try ModelContainerFactory.makeContainer(mode: .customURL(url))
        let matchRepo = SwiftDataMatchRepository(container: container)
        let statsRepo = SwiftDataStatsRepository(container: container)
        let playerRepo = SwiftDataPlayerRepository(
            container: container,
            matchRepository: matchRepo,
            statsRepository: statsRepo
        )

        let human = try await playerRepo.createPlayer(name: "You")
        let bot = try await playerRepo.createBot(difficulty: .easy)
        let roster = [human, bot]

        _ = try await BootstrapSimulationSupport.playX01PerDart(
            matchRepo: matchRepo,
            ordered: roster,
            turns: BootstrapSimulationSupport.first301
        )
        _ = try await BootstrapSimulationSupport.playCricket(
            matchRepo: matchRepo,
            ordered: roster
        )

        // Simulate a cold relaunch against the same on-disk store.
        let logger = DefaultAppLogger(minimumLevel: .fault, sink: BootstrapSilentLogSink())
        _ = try BootstrapStoreRecovery.openRecoveredContainer(mode: .customURL(url), logger: logger)
    }
}

private final class BootstrapSilentLogSink: LogSink, @unchecked Sendable {
    func write(_: LogEntry) {}
}

private enum BootstrapSimulationSupport {
    static func d(_ multiplier: DartMultiplier, _ value: Int) -> DartInput {
        DartInput(multiplier: multiplier, segment: .oneToTwenty(value))
    }

    static let first301: [[DartInput]] = [
        [d(.triple, 20), d(.triple, 20), d(.triple, 20)],
        [d(.triple, 20), d(.single, 20), d(.single, 20)],
        [d(.triple, 20), d(.triple, 20), d(.single, 1)]
    ]

    static let cricketSweep: [[DartInput]] = [
        [d(.triple, 20), d(.triple, 19), d(.triple, 18)],
        [DartInput(multiplier: .single, segment: .miss, isMiss: true),
         DartInput(multiplier: .single, segment: .miss, isMiss: true),
         DartInput(multiplier: .single, segment: .miss, isMiss: true)],
        [d(.triple, 17), d(.triple, 16), d(.triple, 15)],
        [DartInput(multiplier: .single, segment: .miss, isMiss: true),
         DartInput(multiplier: .single, segment: .miss, isMiss: true),
         DartInput(multiplier: .single, segment: .miss, isMiss: true)],
        [DartInput(multiplier: .single, segment: .innerBull), DartInput(multiplier: .single, segment: .innerBull)],
        [d(.triple, 20), d(.triple, 19), d(.triple, 18)],
        [DartInput(multiplier: .single, segment: .miss, isMiss: true),
         DartInput(multiplier: .single, segment: .miss, isMiss: true),
         DartInput(multiplier: .single, segment: .miss, isMiss: true)],
        [d(.triple, 17), d(.triple, 16), d(.triple, 15)],
        [DartInput(multiplier: .single, segment: .miss, isMiss: true),
         DartInput(multiplier: .single, segment: .miss, isMiss: true),
         DartInput(multiplier: .single, segment: .miss, isMiss: true)],
        [DartInput(multiplier: .single, segment: .innerBull), DartInput(multiplier: .single, segment: .innerBull)]
    ]

    static func playX01PerDart(
        matchRepo: SwiftDataMatchRepository,
        ordered: [PlayerSummary],
        turns: [[DartInput]]
    ) async throws {
        let payload = MatchConfigPayload.x01(
            MatchConfigX01(startScore: 301, legsToWin: 1, setsEnabled: false, setsToWin: nil, checkoutMode: .singleOut)
        )
        let matchId = try await createPersistedMatch(matchRepo: matchRepo, type: .x01, payload: payload, ordered: ordered)
        var session = try MatchLifecycleService.createMatch(
            matchId: matchId,
            type: .x01,
            config: payload,
            participants: lifecycleParticipants(ordered)
        )
        try await saveSnapshot(matchRepo: matchRepo, matchId: matchId, session: session)
        for darts in turns {
            session = try MatchLifecycleService.submitX01Turn(session: session, enteredTotal: nil, darts: darts)
            try await appendLastEvent(matchRepo: matchRepo, matchId: matchId, session: session, typeRaw: "x01Turn")
            try await saveSnapshot(matchRepo: matchRepo, matchId: matchId, session: session)
        }
        _ = try await finish(matchRepo: matchRepo, matchId: matchId, session: session)
    }

    static func playCricket(
        matchRepo: SwiftDataMatchRepository,
        ordered: [PlayerSummary]
    ) async throws {
        let payload = MatchConfigPayload.cricket(MatchConfigCricket())
        let matchId = try await createPersistedMatch(matchRepo: matchRepo, type: .cricket, payload: payload, ordered: ordered)
        var session = try MatchLifecycleService.createMatch(
            matchId: matchId,
            type: .cricket,
            config: payload,
            participants: lifecycleParticipants(ordered)
        )
        try await saveSnapshot(matchRepo: matchRepo, matchId: matchId, session: session)
        for darts in cricketSweep {
            session = try MatchLifecycleService.submitCricketTurn(session: session, darts: darts)
            try await appendLastEvent(matchRepo: matchRepo, matchId: matchId, session: session, typeRaw: "cricketTurn")
            try await saveSnapshot(matchRepo: matchRepo, matchId: matchId, session: session)
        }
        _ = try await finish(matchRepo: matchRepo, matchId: matchId, session: session)
    }

    private static func createPersistedMatch(
        matchRepo: SwiftDataMatchRepository,
        type: MatchType,
        payload: MatchConfigPayload,
        ordered: [PlayerSummary]
    ) async throws -> UUID {
        let encoded = try CodablePayloadCoder.encode(payload)
        let participantSummaries = ordered.enumerated().map { index, player in
            MatchParticipantSummary(
                id: UUID(),
                matchId: UUID(),
                playerId: player.id,
                turnOrder: index,
                displayNameAtMatchStart: player.name,
                avatarStyleAtMatchStart: nil
            )
        }
        let persisted = try await matchRepo.createMatch(type: type, configPayload: encoded, participants: participantSummaries)
        return persisted.id
    }

    private static func lifecycleParticipants(_ ordered: [PlayerSummary]) -> [MatchParticipant] {
        ordered.enumerated().map { index, player in
            MatchParticipant(playerId: player.id, displayNameAtMatchStart: player.name, turnOrder: index)
        }
    }

    private static func saveSnapshot(
        matchRepo: SwiftDataMatchRepository,
        matchId: UUID,
        session: MatchLifecycleSession
    ) async throws {
        _ = try await matchRepo.saveSnapshot(
            matchId: matchId,
            snapshotVersion: session.latestSnapshot.payloadVersion,
            snapshotPayload: session.latestSnapshot.payload
        )
    }

    private static func appendLastEvent(
        matchRepo: SwiftDataMatchRepository,
        matchId: UUID,
        session: MatchLifecycleSession,
        typeRaw: String
    ) async throws {
        guard let event = session.events.last else { return }
        _ = try await matchRepo.appendEvent(
            matchId: matchId,
            eventTypeRaw: typeRaw,
            eventPayload: try CodablePayloadCoder.encode(event)
        )
    }

    private static func finish(
        matchRepo: SwiftDataMatchRepository,
        matchId: UUID,
        session: MatchLifecycleSession
    ) async throws {
        #expect(session.runtime.status == .completed)
        _ = try await matchRepo.completeMatch(
            matchId: matchId,
            endedAt: Date(),
            winnerPlayerId: session.runtime.winnerPlayerId
        )
    }
}

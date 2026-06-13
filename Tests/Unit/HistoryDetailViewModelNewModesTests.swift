import Foundation
import Testing
@testable import DartBuddy

private struct HistoryModesFixture {
    let matchId: UUID
    let winner: UUID
    let loser: UUID
    let summary: MatchSummary
    let participants: [MatchParticipantSummary]
    let events: [MatchEventSummary]
    let snapshot: MatchSnapshotSummary
}

private func miss() -> DartInput {
    DartInput(multiplier: .single, segment: .miss, isMiss: true)
}

private func segment(_ multiplier: DartMultiplier, _ value: Int) -> DartInput {
    DartInput(multiplier: multiplier, segment: .oneToTwenty(value))
}

@MainActor
private func makeCompletedModeFixture(type: MatchType) throws -> HistoryModesFixture {
    let winner = UUID()
    let loser = UUID()
    let matchId = UUID()
    var session = try MatchLifecycleService.createMatch(
        matchId: matchId,
        type: type,
        config: MatchConfigDefaults.config(for: type),
        participants: [
            MatchParticipant(playerId: winner, displayNameAtMatchStart: "Winner", turnOrder: 0),
            MatchParticipant(playerId: loser, displayNameAtMatchStart: "Loser", turnOrder: 1)
        ]
    )
    session = try appendSampleTurns(to: session, type: type)

    let now = Date()
    let summary = MatchSummary(
        id: matchId,
        type: type,
        status: .completed,
        startedAt: now,
        endedAt: now,
        winnerPlayerId: winner,
        currentTurnPlayerId: nil,
        currentLegIndex: 0,
        currentSetIndex: 0,
        eventCount: session.events.count,
        createdAt: now,
        updatedAt: now
    )
    let participants = [
        MatchParticipantSummary(id: UUID(), matchId: matchId, playerId: winner, turnOrder: 0, displayNameAtMatchStart: "Winner", avatarStyleAtMatchStart: nil),
        MatchParticipantSummary(id: UUID(), matchId: matchId, playerId: loser, turnOrder: 1, displayNameAtMatchStart: "Loser", avatarStyleAtMatchStart: nil)
    ]
    let events = try session.events.map { envelope in
        MatchEventSummary(
            id: UUID(),
            matchId: matchId,
            eventIndex: envelope.eventIndex,
            eventTypeRaw: "turn",
            eventPayload: try CodablePayloadCoder.encode(envelope),
            createdAt: now
        )
    }
    let snapshot = MatchSnapshotSummary(
        id: UUID(),
        matchId: matchId,
        snapshotVersion: session.latestSnapshot.payloadVersion,
        snapshotPayload: session.latestSnapshot.payload,
        updatedAt: now
    )
    return HistoryModesFixture(
        matchId: matchId,
        winner: winner,
        loser: loser,
        summary: summary,
        participants: participants,
        events: events,
        snapshot: snapshot
    )
}

private func appendSampleTurns(
    to session: MatchLifecycleSession,
    type: MatchType
) throws -> MatchLifecycleSession {
    switch type {
    case .football:
        var updated = session
        updated = try MatchLifecycleService.submitFootballTurn(session: updated, darts: [miss(), miss(), miss()])
        updated = try MatchLifecycleService.submitFootballTurn(session: updated, darts: [miss(), miss(), miss()])
        return updated
    case .golf:
        var updated = session
        updated = try MatchLifecycleService.submitGolfTurn(
            session: updated,
            input: GolfTurnInput(darts: [segment(.double, 1)])
        )
        updated = try MatchLifecycleService.submitGolfTurn(
            session: updated,
            input: GolfTurnInput(darts: [segment(.double, 1)])
        )
        return updated
    case .englishCricket:
        var updated = session
        updated = try MatchLifecycleService.submitEnglishCricketTurn(session: updated, darts: [miss()])
        updated = try MatchLifecycleService.submitEnglishCricketTurn(session: updated, darts: [DartInput(multiplier: .single, segment: .innerBull)])
        return updated
    case .americanCricket:
        var updated = session
        updated = try MatchLifecycleService.submitAmericanCricketTurn(session: updated, darts: [segment(.double, 20)])
        updated = try MatchLifecycleService.submitAmericanCricketTurn(session: updated, darts: [miss()])
        return updated
    case .mulligan:
        var updated = session
        updated = try MatchLifecycleService.submitMulliganTurn(session: updated, darts: [miss(), miss(), miss()])
        updated = try MatchLifecycleService.submitMulliganTurn(session: updated, darts: [miss(), miss(), miss()])
        return updated
    case .knockout:
        var updated = session
        updated = try MatchLifecycleService.submitKnockoutTurn(session: updated, darts: [miss(), miss(), miss()])
        updated = try MatchLifecycleService.submitKnockoutTurn(session: updated, darts: [miss(), miss(), miss()])
        return updated
    case .nineLives:
        var updated = session
        updated = try MatchLifecycleService.submitNineLivesTurn(session: updated, darts: [miss()])
        updated = try MatchLifecycleService.submitNineLivesTurn(session: updated, darts: [miss()])
        return updated
    case .grandNational:
        return try MatchLifecycleService.submitGrandNationalTurn(session: session, darts: [miss()])
    default:
        return try MatchLifecycleService.submitKnockoutTurn(
            session: session,
            darts: [miss(), miss(), miss()]
        )
    }
}

private actor HistoryModesFakeMatchRepository: MatchRepository {
    let fixture: HistoryModesFixture
    init(fixture: HistoryModesFixture) { self.fixture = fixture }

    func createMatch(type _: MatchType, configPayload _: Data, participants _: [MatchParticipantSummary]) async throws -> MatchSummary { fixture.summary }
    func fetchActiveMatch() async throws -> MatchSummary? { nil }
    func fetchHistory(page _: Int, pageSize _: Int) async throws -> [MatchSummary] { [fixture.summary] }
    func fetchHistoryWithParticipants(page _: Int, pageSize _: Int, filter _: MatchHistoryFilter) async throws -> [MatchHistoryRecord] {
        [MatchHistoryRecord(summary: fixture.summary, participants: fixture.participants)]
    }
    func updateMatch(_: MatchSummary) async throws {}
    func completeMatch(matchId _: UUID, endedAt _: Date, winnerPlayerId _: UUID?) async throws -> MatchSummary { fixture.summary }
    func appendEvent(matchId _: UUID, eventTypeRaw _: String, eventPayload _: Data) async throws -> MatchEventSummary {
        throw AppError(code: .unsupportedOperation, layer: .data, severity: .warning, isRecoverable: true, userMessageKey: "error.repository.notImplemented")
    }
    func saveSnapshot(matchId _: UUID, snapshotVersion _: Int, snapshotPayload _: Data) async throws -> MatchSnapshotSummary {
        throw AppError(code: .unsupportedOperation, layer: .data, severity: .warning, isRecoverable: true, userMessageKey: "error.repository.notImplemented")
    }
    func fetchLatestSnapshot(matchId: UUID) async throws -> MatchSnapshotSummary? {
        matchId == fixture.matchId ? fixture.snapshot : nil
    }
    func fetchMatch(matchId: UUID) async throws -> MatchSummary? { matchId == fixture.matchId ? fixture.summary : nil }
    func fetchParticipants(matchId _: UUID) async throws -> [MatchParticipantSummary] { fixture.participants }
    func deleteMatch(matchId _: UUID) async throws {}
    func forfeitMatch(matchId _: UUID, endedAt _: Date, winnerPlayerId _: UUID?, forfeitedByPlayerId _: UUID) async throws -> MatchSummary { fixture.summary }
}

private actor HistoryModesFakeStatsRepository: StatsRepository {
    let events: [MatchEventSummary]
    init(events: [MatchEventSummary]) { self.events = events }
    func fetchEvents(matchId _: UUID) async throws -> [MatchEventSummary] { events }
    func fetchEvents(matchIds _: [UUID]) async throws -> [MatchEventSummary] { events }
}

@Suite("History detail — new modes", .tags(.unit, .history, .regression))
struct HistoryDetailViewModelNewModesTests {
    @Test
    @MainActor
    func footballHistoryBuildsTimelineAndStandings() async throws {
        let fixture = try makeCompletedModeFixture(type: .football)
        let vm = HistoryDetailViewModel(
            matchId: fixture.matchId,
            matchRepository: HistoryModesFakeMatchRepository(fixture: fixture),
            statsRepository: HistoryModesFakeStatsRepository(events: fixture.events)
        )
        await vm.onAppear()

        #expect(vm.state == "ready")
        #expect(vm.matchType == .football)
        #expect(vm.timeline.count == 2)
        #expect(vm.standings.count == 2)
        #expect(vm.standings.map(\.name).contains("Winner"))
        #expect(!vm.configText.isEmpty)
        #expect(vm.breakdowns.count == 2)
    }

    @Test
    @MainActor
    func golfHistoryBuildsBreakdowns() async throws {
        let fixture = try makeCompletedModeFixture(type: .golf)
        let vm = HistoryDetailViewModel(
            matchId: fixture.matchId,
            matchRepository: HistoryModesFakeMatchRepository(fixture: fixture),
            statsRepository: HistoryModesFakeStatsRepository(events: fixture.events)
        )
        await vm.onAppear()

        #expect(vm.matchType == .golf)
        #expect(vm.breakdowns.count == 2)
        #expect(vm.breakdowns.allSatisfy { $0.darts > 0 })
        #expect(vm.header?.modeSpecificSummaryText.isEmpty == false)
    }

    @Test
    @MainActor
    func englishCricketHistoryUsesGenericTurnSummary() async throws {
        let fixture = try makeCompletedModeFixture(type: .englishCricket)
        let vm = HistoryDetailViewModel(
            matchId: fixture.matchId,
            matchRepository: HistoryModesFakeMatchRepository(fixture: fixture),
            statsRepository: HistoryModesFakeStatsRepository(events: fixture.events)
        )
        await vm.onAppear()

        #expect(vm.matchType == .englishCricket)
        #expect(vm.timeline.count == 2)
        #expect(vm.header?.modeText == MatchConfigText.modeLabel(for: .englishCricket))
        #expect(vm.throwsRows.count == 2)
    }

    @Test
    @MainActor
    func americanCricketHistoryBuildsBreakdowns() async throws {
        let fixture = try makeCompletedModeFixture(type: .americanCricket)
        let vm = HistoryDetailViewModel(
            matchId: fixture.matchId,
            matchRepository: HistoryModesFakeMatchRepository(fixture: fixture),
            statsRepository: HistoryModesFakeStatsRepository(events: fixture.events)
        )
        await vm.onAppear()

        #expect(vm.matchType == .americanCricket)
        #expect(vm.breakdowns.count == 2)
        #expect(vm.timeline.count == 2)
    }

    @Test
    @MainActor
    func knockoutHistoryBuildsStandingsAndThrows() async throws {
        let fixture = try makeCompletedModeFixture(type: .knockout)
        let vm = HistoryDetailViewModel(
            matchId: fixture.matchId,
            matchRepository: HistoryModesFakeMatchRepository(fixture: fixture),
            statsRepository: HistoryModesFakeStatsRepository(events: fixture.events)
        )
        await vm.onAppear()

        #expect(vm.matchType == .knockout)
        #expect(vm.standings.count == 2)
        #expect(vm.throwsRows.allSatisfy { $0.throwCount > 0 })
    }

    @Test
    @MainActor
    func mulliganHistoryLoadsCompletedMatch() async throws {
        let fixture = try makeCompletedModeFixture(type: .mulligan)
        let vm = HistoryDetailViewModel(
            matchId: fixture.matchId,
            matchRepository: HistoryModesFakeMatchRepository(fixture: fixture),
            statsRepository: HistoryModesFakeStatsRepository(events: fixture.events)
        )
        await vm.onAppear()

        #expect(vm.state == "ready")
        #expect(vm.matchType == .mulligan)
        #expect(vm.breakdowns.count == 2)
    }

    @Test
    @MainActor
    func nineLivesHistoryBuildsTimeline() async throws {
        let fixture = try makeCompletedModeFixture(type: .nineLives)
        let vm = HistoryDetailViewModel(
            matchId: fixture.matchId,
            matchRepository: HistoryModesFakeMatchRepository(fixture: fixture),
            statsRepository: HistoryModesFakeStatsRepository(events: fixture.events)
        )
        await vm.onAppear()

        #expect(vm.matchType == .nineLives)
        #expect(vm.timeline.count == 2)
        #expect(vm.header?.winnerText == "Winner")
    }

    @Test
    @MainActor
    func grandNationalHistoryBuildsGenericSummary() async throws {
        let fixture = try makeCompletedModeFixture(type: .grandNational)
        let vm = HistoryDetailViewModel(
            matchId: fixture.matchId,
            matchRepository: HistoryModesFakeMatchRepository(fixture: fixture),
            statsRepository: HistoryModesFakeStatsRepository(events: fixture.events)
        )
        await vm.onAppear()

        #expect(vm.matchType == .grandNational)
        #expect(!vm.configText.isEmpty)
        #expect(vm.timeline.count == 1)
        #expect(vm.throwsRows.count == 2)
    }
}

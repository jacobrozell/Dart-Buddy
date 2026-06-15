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
    var participants = [
        MatchParticipant(playerId: winner, displayNameAtMatchStart: "Winner", turnOrder: 0),
        MatchParticipant(playerId: loser, displayNameAtMatchStart: "Loser", turnOrder: 1)
    ]
    if type == .killer {
        participants.append(MatchParticipant(playerId: UUID(), displayNameAtMatchStart: "Third", turnOrder: 2))
    }
    if type == .aroundTheClock {
        participants = [
            MatchParticipant(playerId: winner, displayNameAtMatchStart: "Winner", turnOrder: 0)
        ]
    }
    var session = try MatchLifecycleService.createMatch(
        matchId: matchId,
        type: type,
        config: MatchConfigDefaults.config(for: type),
        participants: participants
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
    let participantSummaries = participants.map {
        MatchParticipantSummary(
            id: UUID(),
            matchId: matchId,
            playerId: $0.playerId ?? UUID(),
            turnOrder: $0.turnOrder,
            displayNameAtMatchStart: $0.displayNameAtMatchStart,
            avatarStyleAtMatchStart: nil
        )
    }
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
        participants: participantSummaries,
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
    case .baseball:
        var updated = session
        updated = try MatchLifecycleService.submitBaseballTurn(session: updated, darts: [segment(.single, 1)])
        updated = try MatchLifecycleService.submitBaseballTurn(session: updated, darts: [segment(.single, 1)])
        return updated
    case .shanghai:
        var updated = session
        updated = try MatchLifecycleService.submitShanghaiTurn(session: updated, darts: [segment(.single, 1)])
        updated = try MatchLifecycleService.submitShanghaiTurn(session: updated, darts: [segment(.single, 1)])
        return updated
    case .aroundTheClock:
        var updated = session
        updated = try MatchLifecycleService.submitAroundTheClockTurn(session: updated, darts: [miss()])
        updated = try MatchLifecycleService.submitAroundTheClockTurn(session: updated, darts: [miss()])
        return updated
    case .killer:
        var updated = session
        updated = try MatchLifecycleService.submitKillerPick(session: updated, dart: segment(.single, 7))
        updated = try MatchLifecycleService.submitKillerPick(session: updated, dart: segment(.single, 12))
        updated = try MatchLifecycleService.submitKillerPick(session: updated, dart: segment(.single, 20))
        updated = try MatchLifecycleService.submitKillerTurn(session: updated, darts: [miss()])
        updated = try MatchLifecycleService.submitKillerTurn(session: updated, darts: [miss()])
        return updated
    default:
        return try MatchLifecycleService.submitKnockoutTurn(
            session: session,
            darts: [miss(), miss(), miss()]
        )
    }
}

private extension HistoryMatchRecord {
    init(_ fixture: HistoryModesFixture) {
        self.init(
            matchId: fixture.matchId,
            summary: fixture.summary,
            participants: fixture.participants,
            snapshot: fixture.snapshot
        )
    }
}

@Suite("History detail — new modes", .tags(.unit, .history, .regression))
struct HistoryDetailViewModelNewModesTests {
    @Test
    @MainActor
    func footballHistoryBuildsTimelineAndStandings() async throws {
        let fixture = try makeCompletedModeFixture(type: .football)
        let vm = HistoryDetailViewModel(
            matchId: fixture.matchId,
            matchRepository: FakeMatchRepositoryBuilder.historyDetail(record: HistoryMatchRecord(fixture)),
            statsRepository: FakeStatsRepositoryBuilder.unfiltered(events: fixture.events)
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
            matchRepository: FakeMatchRepositoryBuilder.historyDetail(record: HistoryMatchRecord(fixture)),
            statsRepository: FakeStatsRepositoryBuilder.unfiltered(events: fixture.events)
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
            matchRepository: FakeMatchRepositoryBuilder.historyDetail(record: HistoryMatchRecord(fixture)),
            statsRepository: FakeStatsRepositoryBuilder.unfiltered(events: fixture.events)
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
            matchRepository: FakeMatchRepositoryBuilder.historyDetail(record: HistoryMatchRecord(fixture)),
            statsRepository: FakeStatsRepositoryBuilder.unfiltered(events: fixture.events)
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
            matchRepository: FakeMatchRepositoryBuilder.historyDetail(record: HistoryMatchRecord(fixture)),
            statsRepository: FakeStatsRepositoryBuilder.unfiltered(events: fixture.events)
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
            matchRepository: FakeMatchRepositoryBuilder.historyDetail(record: HistoryMatchRecord(fixture)),
            statsRepository: FakeStatsRepositoryBuilder.unfiltered(events: fixture.events)
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
            matchRepository: FakeMatchRepositoryBuilder.historyDetail(record: HistoryMatchRecord(fixture)),
            statsRepository: FakeStatsRepositoryBuilder.unfiltered(events: fixture.events)
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
            matchRepository: FakeMatchRepositoryBuilder.historyDetail(record: HistoryMatchRecord(fixture)),
            statsRepository: FakeStatsRepositoryBuilder.unfiltered(events: fixture.events)
        )
        await vm.onAppear()

        #expect(vm.matchType == .grandNational)
        #expect(!vm.configText.isEmpty)
        #expect(vm.timeline.count == 1)
        #expect(vm.throwsRows.count == 2)
    }

    @Test
    @MainActor
    func baseballHistoryBuildsLineScoreAndTimeline() async throws {
        let fixture = try makeCompletedModeFixture(type: .baseball)
        let vm = HistoryDetailViewModel(
            matchId: fixture.matchId,
            matchRepository: FakeMatchRepositoryBuilder.historyDetail(record: HistoryMatchRecord(fixture)),
            statsRepository: FakeStatsRepositoryBuilder.unfiltered(events: fixture.events)
        )
        await vm.onAppear()

        #expect(vm.matchType == .baseball)
        #expect(vm.timeline.count == 2)
        #expect(vm.standings.count == 2)
        #expect(vm.header?.modeSpecificSummaryText.isEmpty == false)
    }

    @Test
    @MainActor
    func killerHistoryBuildsTimelineForThreePlayers() async throws {
        let fixture = try makeCompletedModeFixture(type: .killer)
        let vm = HistoryDetailViewModel(
            matchId: fixture.matchId,
            matchRepository: FakeMatchRepositoryBuilder.historyDetail(record: HistoryMatchRecord(fixture)),
            statsRepository: FakeStatsRepositoryBuilder.unfiltered(events: fixture.events)
        )
        await vm.onAppear()

        #expect(vm.matchType == .killer)
        #expect(vm.timeline.count >= 2)
        #expect(vm.standings.count == 3)
    }

    @Test
    @MainActor
    func shanghaiHistoryBuildsBreakdowns() async throws {
        let fixture = try makeCompletedModeFixture(type: .shanghai)
        let vm = HistoryDetailViewModel(
            matchId: fixture.matchId,
            matchRepository: FakeMatchRepositoryBuilder.historyDetail(record: HistoryMatchRecord(fixture)),
            statsRepository: FakeStatsRepositoryBuilder.unfiltered(events: fixture.events)
        )
        await vm.onAppear()

        #expect(vm.matchType == .shanghai)
        #expect(vm.breakdowns.count == 2)
        #expect(vm.timeline.count == 2)
    }

    @Test
    @MainActor
    func aroundTheClockHistoryBuildsSoloTimeline() async throws {
        let fixture = try makeCompletedModeFixture(type: .aroundTheClock)
        let vm = HistoryDetailViewModel(
            matchId: fixture.matchId,
            matchRepository: FakeMatchRepositoryBuilder.historyDetail(record: HistoryMatchRecord(fixture)),
            statsRepository: FakeStatsRepositoryBuilder.unfiltered(events: fixture.events)
        )
        await vm.onAppear()

        #expect(vm.matchType == .aroundTheClock)
        #expect(vm.timeline.count == 2)
        #expect(vm.standings.count == 1)
    }
}

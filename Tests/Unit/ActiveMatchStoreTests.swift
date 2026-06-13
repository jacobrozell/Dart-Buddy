import Foundation
import Testing
@testable import DartBuddy

@MainActor
@Suite("Active match store", .tags(.unit, .match, .regression))
struct ActiveMatchStoreTests {
    @Test
    func saveAndRetrieveSessionByMatchId() throws {
        let store = ActiveMatchStore()
        let session = try makeInProgressX01Session()
        store.save(session)

        #expect(store.session(for: session.runtime.matchId)?.runtime.matchId == session.runtime.matchId)
    }

    @Test
    func removeClearsSessionAndResumeHint() throws {
        let store = ActiveMatchStore()
        let session = try makeInProgressX01Session()
        let matchId = session.runtime.matchId
        store.save(session)
        store.setResumeHint(matchId: matchId, restoredDarts: [DartInput(multiplier: .single, segment: .oneToTwenty(20))])

        store.remove(matchId: matchId)

        #expect(store.session(for: matchId) == nil)
        #expect(store.consumeResumeHint(matchId: matchId) == nil)
    }

    @Test
    func resumeHintRoundTripsOnce() throws {
        let store = ActiveMatchStore()
        let matchId = UUID()
        let darts = [
            DartInput(multiplier: .triple, segment: .oneToTwenty(20)),
            DartInput(multiplier: .single, segment: .oneToTwenty(5))
        ]
        store.setResumeHint(matchId: matchId, restoredDarts: darts)

        #expect(store.consumeResumeHint(matchId: matchId) == darts)
        #expect(store.consumeResumeHint(matchId: matchId) == nil)
    }

    @Test
    func activeMatchSummaryReturnsInProgressSession() throws {
        let store = ActiveMatchStore()
        let session = try makeInProgressX01Session()
        store.save(session)

        let summary = store.activeMatchSummary()
        #expect(summary?.id == session.runtime.matchId)
        #expect(summary?.status == .inProgress)
        #expect(summary?.type == .x01)
    }

    @Test
    func activeMatchSummaryIgnoresCompletedSessions() throws {
        let store = ActiveMatchStore()
        var session = try makeInProgressX01Session()
        session.runtime.status = .completed
        session.runtime.endedAt = Date()
        store.save(session)

        #expect(store.activeMatchSummary() == nil)
    }

    @Test
    func completedSessionsSortsByEndedAtDescending() throws {
        let store = ActiveMatchStore()
        var older = try makeInProgressX01Session()
        var newer = try makeInProgressX01Session()
        older.runtime.status = .completed
        older.runtime.endedAt = Date(timeIntervalSince1970: 1_000)
        newer.runtime.status = .completed
        newer.runtime.endedAt = Date(timeIntervalSince1970: 2_000)
        store.save(older)
        store.save(newer)

        let completed = store.completedSessions()
        #expect(completed.count == 2)
        #expect(completed[0].runtime.matchId == newer.runtime.matchId)
    }

    @Test
    func clearAllRemovesEverySession() throws {
        let store = ActiveMatchStore()
        store.save(try makeInProgressX01Session())
        store.save(try makeInProgressX01Session())

        store.clearAll()

        #expect(store.activeMatchSummary() == nil)
        #expect(store.completedSessions().isEmpty)
    }
}

@MainActor
private func makeInProgressX01Session() throws -> MatchLifecycleSession {
    try MatchLifecycleService.createMatch(
        type: .x01,
        config: .x01(MatchConfigX01(startScore: 301, legsToWin: 1, setsEnabled: false, setsToWin: nil, checkoutMode: .singleOut)),
        participants: [
            MatchParticipant(playerId: UUID(), displayNameAtMatchStart: "A", turnOrder: 0),
            MatchParticipant(playerId: UUID(), displayNameAtMatchStart: "B", turnOrder: 1)
        ]
    )
}

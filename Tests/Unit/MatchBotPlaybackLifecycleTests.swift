import Foundation
import Testing
@testable import DartBuddy

@MainActor
@Suite("Match bot playback lifecycle", .tags(.unit, .match, .regression))
struct MatchBotPlaybackLifecycleTests {
    @Test
    func recoveryRestartsWhenBotTurnWasInterrupted() {
        var reconciled = false
        var scheduled = false
        MatchBotPlaybackRecovery.recoverIfNeeded(
            isBotTurn: true,
            isBotPlaying: false,
            reconcile: { reconciled = true },
            schedule: { scheduled = true }
        )
        #expect(reconciled)
        #expect(scheduled)
    }

    @Test
    func recoverySkipsWhenHumanIsUp() {
        var reconciled = false
        MatchBotPlaybackRecovery.recoverIfNeeded(
            isBotTurn: false,
            isBotPlaying: false,
            reconcile: { reconciled = true },
            schedule: {}
        )
        #expect(!reconciled)
    }

    @Test
    func recoverySkipsWhileBotIsAlreadyPlaying() {
        var scheduled = false
        MatchBotPlaybackRecovery.recoverIfNeeded(
            isBotTurn: true,
            isBotPlaying: true,
            reconcile: {},
            schedule: { scheduled = true }
        )
        #expect(!scheduled)
    }

    @Test
    func cancelInvokesReconcile() {
        let lifecycle = MatchBotPlaybackLifecycle()
        var reconciled = false
        lifecycle.schedule {
            try? await Task.sleep(nanoseconds: 200_000_000)
        }
        lifecycle.cancel { reconciled = true }
        #expect(reconciled)
    }

    @Test
    func remainingPlannedDartsResumesPartialVisit() {
        let fullPlan = [
            DartInput(multiplier: .single, segment: .oneToTwenty(20)),
            DartInput(multiplier: .single, segment: .oneToTwenty(19)),
            DartInput(multiplier: .single, segment: .oneToTwenty(18))
        ]
        #expect(BotVisitPlayback.remainingPlannedDarts(fullPlan: fullPlan, existingCount: 0) == fullPlan)
        #expect(BotVisitPlayback.remainingPlannedDarts(fullPlan: fullPlan, existingCount: 2).count == 1)
        #expect(BotVisitPlayback.remainingPlannedDarts(fullPlan: fullPlan, existingCount: 2).first?.segment == .oneToTwenty(18))
    }

    @Test
    func sessionSyncRefreshesStoredSessionIntoViewModel() throws {
        let store = ActiveMatchStore()
        let session = try MatchLifecycleService.createMatch(
            type: .x01,
            config: .x01(MatchConfigX01(startScore: 301, legsToWin: 1, setsEnabled: false, setsToWin: nil, checkoutMode: .singleOut)),
            participants: [
                MatchParticipant(playerId: UUID(), displayNameAtMatchStart: "A", turnOrder: 0),
                MatchParticipant(playerId: UUID(), displayNameAtMatchStart: "B", turnOrder: 1)
            ]
        )
        store.save(session)
        var boundSession: MatchLifecycleSession?
        MatchGameplaySessionSync.refreshStoredSession(
            matchId: session.runtime.matchId,
            store: store,
            into: &boundSession
        )
        #expect(boundSession?.runtime.matchId == session.runtime.matchId)
    }
}

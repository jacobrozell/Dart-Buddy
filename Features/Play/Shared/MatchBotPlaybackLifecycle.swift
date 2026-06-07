import Foundation

/// Owns the async bot throw chain so it is not tied to SwiftUI `.task` cancellation.
///
/// Save-and-exit, summary navigation, and tab switches disappear the match screen and
/// cancel its `.task`. Scheduling bot playback here and cancelling in `onDisappear`
/// keeps resume/reappear behavior deterministic.
@MainActor
final class MatchBotPlaybackLifecycle {
    private var playbackTask: Task<Void, Never>?

    func schedule(_ work: @escaping @MainActor () async -> Void) {
        let prior = playbackTask
        prior?.cancel()
        playbackTask = Task { @MainActor in
            if let prior {
                _ = await prior.value
            }
            guard !Task.isCancelled else { return }
            await work()
        }
    }

    func cancel(reconcile: () -> Void) {
        playbackTask?.cancel()
        reconcile()
    }
}

/// Shared rules for folding an in-progress visit into live scoreboard stats.
enum MatchVisitPreview {
    /// Whether `enteredDarts` for the active player should affect live UI totals.
    /// Human pads use `canHumanInput`; bot visits must also count when the bot is up
    /// even if `isBotPlaying` has not flipped on yet.
    static func includesActiveVisit(
        isActive: Bool,
        canHumanInput: Bool,
        isBotPlaying: Bool,
        isCurrentPlayerBot: Bool
    ) -> Bool {
        guard isActive else { return false }
        return canHumanInput || isBotPlaying || isCurrentPlayerBot
    }
}

@MainActor
enum MatchGameplaySessionSync {
    static func refreshStoredSession(
        matchId: UUID,
        store: ActiveMatchStore,
        into session: inout MatchLifecycleSession?
    ) {
        if let stored = store.session(for: matchId) {
            session = stored
        }
    }
}

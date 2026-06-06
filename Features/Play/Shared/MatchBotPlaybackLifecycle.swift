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
        playbackTask?.cancel()
        playbackTask = Task { await work() }
    }

    func cancel(reconcile: () -> Void) {
        playbackTask?.cancel()
        playbackTask = nil
        reconcile()
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

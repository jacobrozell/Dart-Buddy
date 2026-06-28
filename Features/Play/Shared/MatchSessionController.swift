import Foundation

struct MatchSessionErrorKeys {
    let sessionMissing: String
    let undoFailed: String
    let invalidTurn: String
}

/// Shared session lifecycle, undo, and bot-playback plumbing for standard match view models.
///
/// Mode VMs keep scoreboard mapping, engine submit closures, and post-turn UI state;
/// this type owns the duplicated store/repository/session-loader wiring.
@MainActor
final class MatchSessionController {
    let matchId: UUID
    let matchType: MatchType
    let store: ActiveMatchStore
    let logger: any AppLogger
    let matchRepository: any MatchRepository
    let feedbackPreferences: FeedbackPreferences
    let errorKeys: MatchSessionErrorKeys
    let screenAppearedMessage: String

    let turnSubmitter: MatchTurnSubmitter
    let botPlayback = MatchBotPlaybackLifecycle()

    let statsRepository: any StatsRepository

    init(
        matchId: UUID,
        matchType: MatchType,
        eventTypeRaw: String,
        store: ActiveMatchStore,
        logger: any AppLogger,
        matchRepository: any MatchRepository,
        statsRepository: any StatsRepository,
        feedbackPreferences: FeedbackPreferences = FeedbackPreferences(),
        errorKeys: MatchSessionErrorKeys,
        screenAppearedMessage: String
    ) {
        self.matchId = matchId
        self.matchType = matchType
        self.store = store
        self.logger = logger
        self.matchRepository = matchRepository
        self.statsRepository = statsRepository
        self.feedbackPreferences = feedbackPreferences
        self.errorKeys = errorKeys
        self.screenAppearedMessage = screenAppearedMessage
        self.turnSubmitter = MatchTurnSubmitter(
            matchId: matchId,
            matchType: matchType,
            eventTypeRaw: eventTypeRaw,
            store: store,
            logger: logger,
            matchRepository: matchRepository
        )
    }
}

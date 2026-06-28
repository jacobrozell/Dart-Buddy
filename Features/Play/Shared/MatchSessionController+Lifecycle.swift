import Foundation

extension MatchSessionController {
    func loadSessionIfNeeded(
        session: MatchLifecycleSession?,
        setSession: (MatchLifecycleSession?) -> Void,
        onError: (String) -> Void
    ) async {
        if session != nil { return }
        switch await MatchSessionLoader.load(
            matchId: matchId,
            matchType: matchType,
            store: store,
            logger: logger,
            matchRepository: matchRepository,
            statsRepository: statsRepository,
            sessionMissingFallbackKey: errorKeys.sessionMissing
        ) {
        case let .loaded(loaded):
            setSession(loaded)
        case .missing:
            break
        case let .failed(messageKey):
            onError(messageKey)
        }
    }

    func handleAppear(
        getSession: () -> MatchLifecycleSession?,
        setSession: (MatchLifecycleSession?) -> Void,
        onLoadError: (String) -> Void,
        reconcileAfterSummaryUndo: () async -> Bool,
        reconcileInterruptedBotPlayback: () -> Void,
        scheduleBotPlayback: () -> Void
    ) async {
        logger.matchInfo(
            matchId: matchId,
            matchType: matchType,
            category: .ui,
            eventName: "match_screen_appeared",
            message: screenAppearedMessage
        )
        var session = getSession()
        MatchGameplaySessionSync.refreshStoredSession(matchId: matchId, store: store, into: &session)
        setSession(session)
        if await reconcileAfterSummaryUndo() { return }
        await loadSessionIfNeeded(session: getSession(), setSession: setSession, onError: onLoadError)
        reconcileInterruptedBotPlayback()
        scheduleBotPlayback()
    }

    func handleDisappear(reconcileInterruptedBotPlayback: () -> Void) {
        botPlayback.cancel(reconcile: reconcileInterruptedBotPlayback)
    }

    func recoverBotPlaybackIfNeeded(
        isBotTurn: Bool,
        isBotPlaying: Bool,
        reconcileInterruptedBotPlayback: () -> Void,
        scheduleBotPlayback: () -> Void
    ) {
        MatchBotPlaybackRecovery.recoverIfNeeded(
            isBotTurn: isBotTurn,
            isBotPlaying: isBotPlaying,
            reconcile: reconcileInterruptedBotPlayback,
            schedule: scheduleBotPlayback
        )
    }

    func scheduleBotPlayback(_ playBotTurnIfNeeded: @escaping @MainActor () async -> Void) {
        botPlayback.schedule { await playBotTurnIfNeeded() }
    }

    /// Returns `true` when summary undo rewound an in-progress match back onto the play screen.
    func reconcileAfterSummaryUndo(
        isMatchCompleted: Bool,
        setSession: (MatchLifecycleSession?) -> Void,
        setEnteredDarts: ([DartInput]) -> Void,
        setBotPlaying: (Bool) -> Void,
        setReadyTurn: () -> Void,
        isCurrentPlayerBot: () -> Bool,
        scheduleBotPlayback: () -> Void
    ) async -> Bool {
        guard isMatchCompleted,
              let stored = store.session(for: matchId),
              stored.runtime.status == .inProgress else { return false }
        setSession(stored)
        setReadyTurn()
        var enteredDarts = store.consumeResumeHint(matchId: matchId) ?? []
        setBotPlaying(false)
        if isCurrentPlayerBot() {
            enteredDarts.removeAll()
        }
        setEnteredDarts(enteredDarts)
        if enteredDarts.isEmpty {
            scheduleBotPlayback()
        }
        return true
    }

    func reconcileInterruptedBotPlayback(
        session: MatchLifecycleSession?,
        setBotPlaying: (Bool) -> Void,
        clearEnteredDarts: () -> Void,
        shouldResetState: () -> Bool,
        resetState: () -> Void,
        beforeReset: () -> Void = {}
    ) {
        setBotPlaying(false)
        clearEnteredDarts()
        guard session?.runtime.status == .inProgress else { return }
        guard shouldResetState() else { return }
        beforeReset()
        resetState()
    }

    func applySubmitOutcome(
        _ outcome: MatchTurnSubmitter.Outcome,
        fromBotPlayback: Bool,
        setSession: (MatchLifecycleSession?) -> Void,
        clearEnteredDarts: () -> Void,
        setReadyTurn: () -> Void,
        setEntryInvalid: (String) -> Void,
        setError: (String) -> Void,
        handleSuccess: (MatchLifecycleSession, _ fromBotPlayback: Bool) async -> Void
    ) async {
        switch outcome {
        case .cancelled:
            setReadyTurn()
        case let .rejected(messageKey):
            setEntryInvalid(messageKey)
        case let .persistFailed(messageKey):
            setError(messageKey)
        case let .succeeded(updated):
            setSession(updated)
            await handleSuccess(updated, fromBotPlayback)
            clearEnteredDarts()
        }
    }
}

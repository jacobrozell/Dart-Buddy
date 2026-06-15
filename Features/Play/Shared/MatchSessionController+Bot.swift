import Foundation

extension MatchSessionController {
    /// Reveals a bot visit and submits it. Returns `false` when playback was cancelled.
    @discardableResult
    func playBotVisitAndSubmit(
        isReadyTurn: Bool,
        isBotPlaying: Bool,
        setBotPlaying: (Bool) -> Void,
        getEnteredDarts: () -> [DartInput],
        setEnteredDarts: ([DartInput]) -> Void,
        plannedDarts: [DartInput],
        submitFromBotPlayback: () async -> Void
    ) async -> Bool {
        guard isReadyTurn, isBotPlaying == false else { return false }

        setBotPlaying(true)
        defer { setBotPlaying(false) }

        setEnteredDarts([])
        var enteredDarts: [DartInput] = []
        let revealed = await BotVisitPlayback.revealVisit(
            plannedDarts,
            feedbackPreferences: feedbackPreferences,
            applyRevealedDarts: { revealed in
                enteredDarts = revealed
                setEnteredDarts(revealed)
            }
        )
        guard revealed else { return false }

        await submitFromBotPlayback()
        return true
    }

    func shouldContinueBotChain(
        session: MatchLifecycleSession?,
        isReadyTurn: Bool,
        isCurrentPlayerBot: () -> Bool
    ) -> Bool {
        guard session?.runtime.status != .completed else { return false }
        return isCurrentPlayerBot() && isReadyTurn
    }
}

import Foundation

extension MatchSessionController {
    func undoLastTurn(
        getSession: () -> MatchLifecycleSession?,
        setSession: (MatchLifecycleSession?) -> Void,
        setReadyTurn: () -> Void,
        setError: (String) -> Void,
        clearEnteredDarts: () -> Void,
        onSuccess: () async -> Void
    ) async {
        await loadSessionIfNeeded(session: getSession(), setSession: setSession, onError: setError)
        guard let current = getSession() else { return }
        do {
            let undone = try await MatchTurnSupport.undoLastTurn(
                session: current,
                matchId: matchId,
                store: store,
                matchRepository: matchRepository
            )
            setSession(undone)
            setReadyTurn()
            clearEnteredDarts()
            await onSuccess()
        } catch is CancellationError {
            setReadyTurn()
        } catch {
            setError(MatchTurnSupport.errorMessageKey(for: error, fallback: errorKeys.undoFailed))
        }
    }

    func undoLastDart(
        getSession: () -> MatchLifecycleSession?,
        getEnteredDarts: () -> [DartInput],
        setSession: (MatchLifecycleSession?) -> Void,
        setEnteredDarts: ([DartInput]) -> Void,
        setSelectedMultiplier: (DartMultiplier) -> Void,
        setReadyTurn: () -> Void,
        setError: (String) -> Void,
        onRestoredEmptyVisit: () async -> Void
    ) async {
        await loadSessionIfNeeded(session: getSession(), setSession: setSession, onError: setError)
        guard let current = getSession() else { return }
        let enteredDarts = getEnteredDarts()
        if !enteredDarts.isEmpty {
            var trimmed = enteredDarts
            trimmed.removeLast()
            setEnteredDarts(trimmed)
            setSelectedMultiplier(.single)
            return
        }
        do {
            let result = try await MatchTurnSupport.undoLastDart(
                session: current,
                matchId: matchId,
                store: store,
                matchRepository: matchRepository
            )
            setSession(result.session)
            setReadyTurn()
            setEnteredDarts(result.restoredDarts)
            if result.restoredDarts.isEmpty {
                await onRestoredEmptyVisit()
            }
        } catch is CancellationError {
            setReadyTurn()
        } catch {
            setError(MatchTurnSupport.errorMessageKey(for: error, fallback: errorKeys.undoFailed))
        }
    }
}

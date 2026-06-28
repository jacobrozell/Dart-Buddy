import Foundation
import SwiftUI

enum MatchForfeitFlowState: Equatable {
    case idle
    case pickPlayer
    case pickWinner
    case confirm
    case persisting
}

@MainActor
@Observable
final class MatchForfeitCoordinator {
    var flowState: MatchForfeitFlowState = .idle
    var forfeitingPlayerId: UUID?
    var winnerPlayerId: UUID?
    var tiedCandidates: [ForfeitCandidate] = []
    var errorMessageKey: String?

    private weak var host: (any MatchPlaySessionHost)?
    private let store: ActiveMatchStore
    private let matchRepository: any MatchRepository
    private let logger: any AppLogger
    private var winnerResolution: String = "automatic"
    private var onComplete: (() -> Void)?

    init(
        store: ActiveMatchStore,
        matchRepository: any MatchRepository,
        logger: any AppLogger
    ) {
        self.store = store
        self.matchRepository = matchRepository
        self.logger = logger
    }

    func configure(host: any MatchPlaySessionHost, onComplete: @escaping () -> Void) {
        self.host = host
        self.onComplete = onComplete
    }

    var canForfeit: Bool {
        (host?.session?.runtime.eventCount ?? 0) >= 1
    }

    func beginForfeitFlow() {
        guard let host, let session = host.session else { return }
        errorMessageKey = nil
        winnerResolution = "automatic"

        if session.runtime.participants.count >= 3 {
            flowState = .pickPlayer
            return
        }

        let humans = MatchForfeitParticipantSupport.humanParticipantIds(in: session)
        guard let forfeiter = humans.first else { return }
        selectForfeitingPlayer(forfeiter)
    }

    func selectForfeitingPlayer(_ playerId: UUID) {
        guard let host, let session = host.session else { return }
        forfeitingPlayerId = playerId
        do {
            let resolution = try MatchForfeitWinnerResolver.resolve(session: session, forfeitingPlayerId: playerId)
            switch resolution {
            case let .automatic(winnerId):
                winnerPlayerId = winnerId
                winnerResolution = "automatic"
                flowState = .confirm
            case let .chooseAmongTied(candidates):
                tiedCandidates = candidates
                winnerResolution = "user_picked"
                flowState = .pickWinner
            }
        } catch {
            errorMessageKey = MatchTurnSupport.errorMessageKey(for: error, fallback: "error.match.forfeit.invalid")
            flowState = .idle
        }
    }

    func selectWinner(_ playerId: UUID) {
        winnerPlayerId = playerId
        flowState = .confirm
    }

    func cancelFlow() {
        flowState = .idle
        forfeitingPlayerId = nil
        winnerPlayerId = nil
        tiedCandidates = []
        errorMessageKey = nil
    }

    func confirmForfeit() async {
        guard let host,
              let session = host.session,
              let forfeitingPlayerId else { return }
        flowState = .persisting
        do {
            _ = try await MatchForfeitSupport.persistForfeit(
                session: session,
                forfeitingPlayerId: forfeitingPlayerId,
                winnerPlayerId: winnerPlayerId,
                matchId: host.matchId,
                store: store,
                matchRepository: matchRepository,
                logger: logger,
                matchType: host.hostMatchType,
                resolution: winnerResolution
            )
            cancelFlow()
            onComplete?()
        } catch {
            errorMessageKey = MatchTurnSupport.errorMessageKey(for: error, fallback: "error.match.forfeit.failed")
            flowState = .confirm
            logger.matchError(
                matchId: host.matchId,
                matchType: host.hostMatchType,
                category: .appLifecycle,
                eventName: "match_forfeit_failed",
                message: "Forfeit persist failed.",
                metadata: forfeitFailureMetadata(for: host, error: error)
            )
        }
    }

    private func forfeitFailureMetadata(for host: any MatchPlaySessionHost, error: Error) -> [String: String] {
        var metadata = MatchTurnSupport.appErrorMetadata(for: error)
        metadata["resolution"] = winnerResolution
        if let session = host.session {
            metadata.merge(MatchAnalytics.metadata(for: session)) { _, new in new }
        }
        return metadata
    }

    var confirmMessageKey: String {
        guard let host, let session = host.session, let forfeitingPlayerId else {
            return "play.match.forfeit.confirm.solo.message"
        }
        if session.runtime.participants.count == 1 {
            return "play.match.forfeit.confirm.solo.message"
        }
        let forfeiter = MatchForfeitParticipantSupport.displayName(for: forfeitingPlayerId, in: session)
        let winner = winnerPlayerId.map {
            MatchForfeitParticipantSupport.displayName(for: $0, in: session)
        } ?? "—"
        return L10n.format("play.match.forfeit.confirm.message", forfeiter, winner)
    }
}

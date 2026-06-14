import Foundation

@MainActor
final class PlayHomeViewModel: ObservableObject {
    enum State: Equatable {
        case loading
        case readyNoActiveMatch
        case readyWithActiveMatch(MatchSummary)
        case error(messageKey: String)
    }

    @Published private(set) var state: State = .loading
    private let playerRepository: any PlayerRepository
    private let matchRepository: any MatchRepository
    private let logger: any AppLogger

    init(
        playerRepository: any PlayerRepository,
        matchRepository: any MatchRepository,
        logger: any AppLogger
    ) {
        self.playerRepository = playerRepository
        self.matchRepository = matchRepository
        self.logger = logger
    }

    func onAppear() async {
        state = .loading
        do {
            let players = try await playerRepository.fetchPlayers(includeArchived: false)
            if players.isEmpty {
                state = .readyNoActiveMatch
                return
            }

            let active = try await matchRepository.fetchActiveMatch()
            if let active, ProductSurface.isMatchTypeReachable(active.type) {
                logger.info(
                    .ui,
                    eventName: "play_home_active_match",
                    message: "Play home resolved with resumable match.",
                    metadata: [
                        "matchId": active.id.uuidString,
                        "matchType": active.type.rawValue
                    ],
                    correlationId: active.id.uuidString
                )
                state = .readyWithActiveMatch(active)
            } else {
                logger.info(.ui, eventName: "play_home_ready", message: "Play home ready without active match.")
                state = .readyNoActiveMatch
            }
        } catch {
            logger.error(
                .ui,
                eventName: "play_home_load_failed",
                message: "Failed to resolve play home state.",
                metadata: ["errorCode": "playHomeLoadFailed"]
            )
            state = .error(messageKey: "error.playHome.load")
        }
    }
}

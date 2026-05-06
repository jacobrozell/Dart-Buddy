import Foundation

@MainActor
final class PlayHomeViewModel: ObservableObject {
    enum State: Equatable {
        case loading
        case readyNoActiveMatch
        case readyWithActiveMatch(MatchSummary)
        case emptyNoPlayers
        case error(messageKey: String)
    }

    @Published private(set) var state: State = .loading
    private let playerRepository: any PlayerRepository
    private let matchRepository: any MatchRepository
    private let activeMatchStore: ActiveMatchStore
    private let logger: any AppLogger

    init(
        playerRepository: any PlayerRepository,
        matchRepository: any MatchRepository,
        activeMatchStore: ActiveMatchStore,
        logger: any AppLogger
    ) {
        self.playerRepository = playerRepository
        self.matchRepository = matchRepository
        self.activeMatchStore = activeMatchStore
        self.logger = logger
    }

    func onAppear() async {
        state = .loading
        do {
            let players = try await playerRepository.fetchPlayers(includeArchived: false)
            if players.isEmpty {
                state = .emptyNoPlayers
                return
            }

            let active = PerformanceMonitor.measure(.resumeMatch, logger: logger) {
                activeMatchStore.activeMatchSummary()
            } ?? (try await matchRepository.fetchActiveMatch())
            if let active {
                state = .readyWithActiveMatch(active)
            } else {
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

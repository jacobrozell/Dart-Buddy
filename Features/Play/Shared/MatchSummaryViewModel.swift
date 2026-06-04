import Foundation

@MainActor
final class MatchSummaryViewModel: ObservableObject {
    struct PlayerRow: Identifiable {
        let id: UUID
        let name: String
        let isWinner: Bool
        let stats: [(label: String, value: String)]
    }

    @Published private(set) var session: MatchLifecycleSession?
    @Published private(set) var isLoading = false
    @Published private(set) var isUndoing = false
    @Published private(set) var undoErrorKey: String?

    let matchId: UUID
    private let store: ActiveMatchStore
    private let matchRepository: any MatchRepository
    private let statsRepository: any StatsRepository

    init(
        matchId: UUID,
        store: ActiveMatchStore,
        matchRepository: any MatchRepository,
        statsRepository: any StatsRepository
    ) {
        self.matchId = matchId
        self.store = store
        self.matchRepository = matchRepository
        self.statsRepository = statsRepository
        self.session = store.session(for: matchId)
    }

    func refresh() {
        session = store.session(for: matchId)
    }

    func loadIfNeeded() async {
        if session != nil { return }
        if let existing = store.session(for: matchId) {
            session = existing
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            guard let rehydrated = try await MatchStatsLoader.rehydrateSession(
                matchId: matchId,
                matchRepository: matchRepository,
                statsRepository: statsRepository
            ) else {
                return
            }
            store.save(rehydrated)
            session = rehydrated
        } catch {
            return
        }
    }

    var hasResult: Bool { session != nil }

    var canUndoLastThrow: Bool {
        guard let session, !session.events.isEmpty else { return false }
        return session.runtime.status == .completed
    }

    /// Reverts the last accepted throw and returns restored in-progress darts, if any.
    func undoLastThrow() async -> [DartInput]? {
        undoErrorKey = nil
        guard canUndoLastThrow, let current = session else { return nil }
        isUndoing = true
        defer { isUndoing = false }

        do {
            let result = try await MatchTurnSupport.undoLastDart(
                session: current,
                matchId: matchId,
                store: store,
                matchRepository: matchRepository
            )
            session = result.session
            return result.restoredDarts
        } catch {
            undoErrorKey = MatchTurnSupport.errorMessageKey(for: error, fallback: "play.summary.undoFailed")
            return nil
        }
    }

    var typeLabel: String {
        guard let type = session?.runtime.type else { return "" }
        switch type {
        case .x01: return L10n.string("play.x01.title")
        case .cricket: return L10n.string("play.cricket.title")
        }
    }

    var winnerName: String? {
        guard let runtime = session?.runtime else { return nil }
        return runtime.participants.first {
            ($0.playerId ?? $0.id) == runtime.winnerPlayerId
        }?.displayNameAtMatchStart
    }

    var playerRows: [PlayerRow] {
        guard let session else { return [] }
        let runtime = session.runtime
        let nameById = Dictionary(
            runtime.participants.map { ($0.playerId ?? $0.id, $0.displayNameAtMatchStart) },
            uniquingKeysWith: { first, _ in first }
        )
        let input = MatchStatsInput(
            type: runtime.type,
            participantKeys: runtime.participants.map { $0.playerId ?? $0.id },
            winnerKey: runtime.winnerPlayerId,
            events: session.events
        )
        let breakdowns = StatsService.breakdowns(from: [input], nameById: nameById)
        return breakdowns.map { breakdown in
            PlayerRow(
                id: breakdown.playerId,
                name: breakdown.name,
                isWinner: breakdown.playerId == runtime.winnerPlayerId,
                stats: Self.stats(for: breakdown, runtime: runtime)
            )
        }
    }

    static func stats(for breakdown: PlayerStatBreakdown, runtime: MatchRuntimeState) -> [(label: String, value: String)] {
        switch runtime.type {
        case .x01:
            var rows: [(String, String)] = [
                (L10n.string("play.summary.stat.threeDartAvg"), String(format: "%.1f", breakdown.average3Dart))
            ]
            if runtime.x01State?.config.setsEnabled == true,
               let player = runtime.x01State?.players.first(where: { $0.playerId == breakdown.playerId }) {
                rows.append((L10n.string("play.summary.stat.sets"), "\(player.setsWon)"))
            }
            if let player = runtime.x01State?.players.first(where: { $0.playerId == breakdown.playerId }) {
                rows.append((L10n.string("play.summary.stat.legs"), "\(player.legsWon)"))
            }
            let bestOut = breakdown.highestCheckout > 0 ? "\(breakdown.highestCheckout)" : "—"
            rows.append((L10n.string("play.summary.stat.bestOut"), bestOut))
            return rows
        case .cricket:
            let score = runtime.cricketState?.players.first(where: { $0.playerId == breakdown.playerId })?.score ?? breakdown.points
            var rows: [(String, String)] = [
                (L10n.string("play.summary.stat.score"), "\(score)"),
                (L10n.string("play.summary.stat.darts"), "\(breakdown.darts)"),
                (L10n.string("stats.mpr"), String(format: "%.2f", breakdown.marksPerRound))
            ]
            if runtime.cricketState?.config.setsEnabled == true,
               let player = runtime.cricketState?.players.first(where: { $0.playerId == breakdown.playerId }) {
                rows.append((L10n.string("play.summary.stat.sets"), "\(player.setsWon)"))
            }
            if let player = runtime.cricketState?.players.first(where: { $0.playerId == breakdown.playerId }),
               (runtime.cricketState?.config.legsToWin ?? 1) > 1 || player.legsWon > 0 {
                rows.append((L10n.string("play.summary.stat.legs"), "\(player.legsWon)"))
            }
            return rows
        }
    }
}

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

    let matchId: UUID
    private let store: ActiveMatchStore

    init(matchId: UUID, store: ActiveMatchStore) {
        self.matchId = matchId
        self.store = store
        self.session = store.session(for: matchId)
    }

    func refresh() {
        session = store.session(for: matchId)
    }

    var hasResult: Bool { session != nil }

    var typeLabel: String {
        session?.runtime.type.rawValue.uppercased() ?? ""
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
                stats: stats(for: breakdown, runtime: runtime)
            )
        }
    }

    private func stats(for breakdown: PlayerStatBreakdown, runtime: MatchRuntimeState) -> [(label: String, value: String)] {
        switch runtime.type {
        case .x01:
            var rows: [(String, String)] = [("3-Dart Avg", String(format: "%.1f", breakdown.average3Dart))]
            if let player = runtime.x01State?.players.first(where: { $0.playerId == breakdown.playerId }) {
                if runtime.x01State?.config.setsEnabled == true {
                    rows.append(("Sets", "\(player.setsWon)"))
                }
                rows.append(("Legs", "\(player.legsWon)"))
            }
            if breakdown.highestCheckout > 0 {
                rows.append(("Best Out", "\(breakdown.highestCheckout)"))
            }
            return rows
        case .cricket:
            let score = runtime.cricketState?.players.first(where: { $0.playerId == breakdown.playerId })?.score ?? breakdown.points
            return [("Score", "\(score)"), ("Darts", "\(breakdown.darts)")]
        }
    }
}

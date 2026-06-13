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

    var isForfeited: Bool { session?.runtime.status == .forfeited }

    var canUndoLastThrow: Bool {
        guard let session, !session.events.isEmpty else { return false }
        return session.runtime.status == .completed
    }

    var canRematch: Bool {
        guard let runtime = session?.runtime, runtime.status == .completed else { return false }
        let participantCount = runtime.participants.count
        let minimum: Int = switch runtime.type {
        case .x01, .raid: 1
        default: 2
        }
        return participantCount >= minimum
    }

    var isCoopMatch: Bool {
        guard let type = session?.runtime.type else { return false }
        return type == .raid
    }

    var coopTeamVictory: Bool? {
        guard isCoopMatch, let state = session?.runtime.raidState, state.isComplete else { return nil }
        return state.teamVictory
    }

    var coopHeadlineKey: String {
        guard let victory = coopTeamVictory else { return "play.summary.result" }
        return victory ? "play.raid.victory" : "play.raid.defeat"
    }

    var coopSubheadline: String? {
        guard let state = session?.runtime.raidState else { return nil }
        let tier = L10n.string(state.config.bossTier.displayNameKey)
        if state.teamVictory {
            let hearts = state.heroes.reduce(0) { $0 + $1.hearts }
            return L10n.format("coop.summary.raidVictorySubheadFormat", tier, hearts)
        }
        return L10n.format("coop.summary.raidDefeatSubheadFormat", tier, state.bossHP)
    }

    var coopMvpName: String? {
        guard let state = session?.runtime.raidState else { return nil }
        guard let top = state.heroes.max(by: { $0.damageDealt < $1.damageDealt }), top.damageDealt > 0 else {
            return nil
        }
        return participantName(for: top.playerId)
    }

    var rematchTitleKey: String {
        session?.runtime.type == .raid ? "play.summary.raidRematch" : "play.summary.rematch"
    }

    private func participantName(for playerId: UUID) -> String? {
        session?.runtime.participants.first { ($0.playerId ?? $0.id) == playerId }?.displayNameAtMatchStart
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
        return MatchConfigText.modeLabel(for: type)
    }

    var winnerName: String? {
        guard let runtime = session?.runtime else { return nil }
        return runtime.participants.first {
            ($0.playerId ?? $0.id) == runtime.winnerPlayerId
        }?.displayNameAtMatchStart
    }

    var forfeiterName: String? {
        guard let runtime = session?.runtime, let forfeitedBy = runtime.forfeitedByPlayerId else { return nil }
        return runtime.participants.first {
            ($0.playerId ?? $0.id) == forfeitedBy
        }?.displayNameAtMatchStart
    }

    var playerRows: [PlayerRow] {
        guard let session else { return [] }
        let runtime = session.runtime
        if runtime.type == .raid, let raidState = runtime.raidState {
            return raidPlayerRows(raidState: raidState, runtime: runtime)
        }
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

    private func raidPlayerRows(raidState: RaidState, runtime: MatchRuntimeState) -> [PlayerRow] {
        let nameById = Dictionary(
            runtime.participants.map { ($0.playerId ?? $0.id, $0.displayNameAtMatchStart) },
            uniquingKeysWith: { first, _ in first }
        )
        return raidState.heroes.map { hero in
            PlayerRow(
                id: hero.playerId,
                name: nameById[hero.playerId] ?? L10n.string("play.raid.heroFallbackName"),
                isWinner: false,
                stats: [
                    (L10n.string("play.summary.stat.damage"), "\(hero.damageDealt)"),
                    (L10n.string("play.summary.stat.hearts"), "\(hero.hearts)")
                ]
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
        case .baseball:
            let runs = runtime.baseballState?.players.first(where: { $0.playerId == breakdown.playerId })?.cumulativeRuns ?? breakdown.points
            return [
                (L10n.string("play.summary.stat.runs"), "\(runs)"),
                (L10n.string("play.summary.stat.darts"), "\(breakdown.darts)")
            ]
        case .killer:
            let lives = runtime.killerState?.players.first(where: { $0.playerId == breakdown.playerId })?.lives ?? 0
            return [
                (L10n.string("play.summary.stat.lives"), "\(lives)"),
                (L10n.string("play.summary.stat.darts"), "\(breakdown.darts)")
            ]
        case .shanghai:
            let points = runtime.shanghaiState?.players.first(where: { $0.playerId == breakdown.playerId })?.cumulativePoints ?? breakdown.points
            return [
                (L10n.string("play.summary.stat.score"), "\(points)"),
                (L10n.string("play.summary.stat.darts"), "\(breakdown.darts)")
            ]
        default:
            return [
                (L10n.string("play.summary.stat.darts"), "\(breakdown.darts)")
            ]
        }
    }
}

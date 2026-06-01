import Foundation

struct SectorHit: Identifiable, Equatable {
    let sector: String
    let count: Int
    var id: String { sector }
}

@MainActor
final class StatisticsViewModel: ObservableObject {
    enum Period: String, CaseIterable, Identifiable {
        case today, d7, d30, all
        var id: String { rawValue }
        var title: String {
            switch self {
            case .today: return "Today"
            case .d7: return "7 Days"
            case .d30: return "30 Days"
            case .all: return "All time"
            }
        }
    }

    @Published var mode: MatchType = .x01
    @Published var period: Period = .all
    @Published private(set) var rows: [PlayerStatBreakdown] = []
    @Published private(set) var isLoading = false

    private let matchRepository: any MatchRepository
    private let statsRepository: any StatsRepository

    init(matchRepository: any MatchRepository, statsRepository: any StatsRepository) {
        self.matchRepository = matchRepository
        self.statsRepository = statsRepository
    }

    /// Sectors hit across all listed players, ordered by board value, for charting.
    var sectorHits: [SectorHit] {
        var totals: [String: Int] = [:]
        for row in rows {
            for (sector, count) in row.hitsBySector {
                totals[sector, default: 0] += count
            }
        }
        return totals
            .map { SectorHit(sector: $0.key, count: $0.value) }
            .sorted { StatsSectorOrder.rank($0.sector, mode: mode) < StatsSectorOrder.rank($1.sector, mode: mode) }
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let history = try await matchRepository.fetchHistoryWithParticipants(page: 0, pageSize: 1000)
            let cutoff = periodCutoff()
            var names: [UUID: String] = [:]
            var inputs: [MatchStatsInput] = []

            for record in history {
                let summary = record.summary
                guard summary.status == .completed, summary.type == mode else { continue }
                if let cutoff, summary.startedAt < cutoff { continue }

                var keys: [UUID] = []
                for participant in record.participants {
                    let key = participant.playerId ?? participant.id
                    names[key] = participant.displayNameAtMatchStart
                    keys.append(key)
                }
                let events = (try? await fetchEvents(matchId: summary.id)) ?? []
                inputs.append(
                    MatchStatsInput(
                        type: summary.type,
                        participantKeys: keys,
                        winnerKey: summary.winnerPlayerId,
                        events: events
                    )
                )
            }

            rows = StatsService.breakdowns(from: inputs, nameById: names)
        } catch {
            rows = []
        }
    }

    private func fetchEvents(matchId: UUID) async throws -> [MatchEventEnvelope] {
        let events = try await statsRepository.fetchEvents(matchId: matchId)
        return try events
            .map { try CodablePayloadCoder.decode(MatchEventEnvelope.self, from: $0.eventPayload) }
            .sorted { $0.eventIndex < $1.eventIndex }
    }

    private func periodCutoff() -> Date? {
        let calendar = Calendar.current
        switch period {
        case .all:
            return nil
        case .today:
            return calendar.startOfDay(for: Date())
        case .d7:
            return calendar.date(byAdding: .day, value: -7, to: Date())
        case .d30:
            return calendar.date(byAdding: .day, value: -30, to: Date())
        }
    }
}

enum StatsSectorOrder {
    /// Ordering for charting: bull last for X01, board values descending otherwise.
    static func rank(_ sector: String, mode: MatchType) -> Int {
        switch sector {
        case "innerBull": return 100
        case "outerBull", "bull": return 99
        default:
            if let value = Int(sector) { return 50 - value }
            return 200
        }
    }

    static func label(_ sector: String) -> String {
        switch sector {
        case "innerBull": return "Bull"
        case "outerBull": return "25"
        case "bull": return "Bull"
        default: return sector
        }
    }
}

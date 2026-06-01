import Foundation

struct PlayerStatRow: Identifiable, Equatable {
    let id: UUID
    let name: String
    let games: Int
    let wins: Int

    var winPercent: Double {
        games > 0 ? Double(wins) / Double(games) * 100 : 0
    }
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
    @Published private(set) var rows: [PlayerStatRow] = []
    @Published private(set) var isLoading = false

    private let matchRepository: any MatchRepository

    init(matchRepository: any MatchRepository) {
        self.matchRepository = matchRepository
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let history = try await matchRepository.fetchHistoryWithParticipants(page: 0, pageSize: 1000)
            let cutoff = periodCutoff()
            var games: [UUID: Int] = [:]
            var wins: [UUID: Int] = [:]
            var names: [UUID: String] = [:]

            for record in history {
                let summary = record.summary
                guard summary.status == .completed else { continue }
                guard summary.type == mode else { continue }
                if let cutoff, summary.startedAt < cutoff { continue }
                for participant in record.participants {
                    let key = participant.playerId ?? participant.id
                    names[key] = participant.displayNameAtMatchStart
                    games[key, default: 0] += 1
                    if summary.winnerPlayerId == key {
                        wins[key, default: 0] += 1
                    }
                }
            }

            rows = names.map { key, name in
                PlayerStatRow(id: key, name: name, games: games[key] ?? 0, wins: wins[key] ?? 0)
            }
            .sorted {
                if $0.wins != $1.wins { return $0.wins > $1.wins }
                if $0.games != $1.games { return $0.games > $1.games }
                return $0.name < $1.name
            }
        } catch {
            rows = []
        }
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

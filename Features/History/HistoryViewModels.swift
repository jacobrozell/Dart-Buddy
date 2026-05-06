import Foundation

struct HistoryListRow: Identifiable, Equatable {
    let summary: MatchSummary
    let participantNames: [String]
    let winnerName: String

    var id: UUID { summary.id }
}

struct HistoryDetailHeader: Equatable {
    let modeText: String
    let winnerText: String
    let dateText: String
    let durationText: String
    let participantsText: String
    let modeSpecificSummaryText: String
}

@MainActor
final class HistoryListViewModel: ObservableObject {
    enum ModeFilter: String, CaseIterable, Identifiable {
        case all
        case x01
        case cricket
        var id: String { rawValue }
    }

    enum DateFilter: String, CaseIterable, Identifiable {
        case d7
        case d30
        case all
        var id: String { rawValue }
    }

    @Published var modeFilter: ModeFilter = .all
    @Published var dateFilter: DateFilter = .all
    @Published var playerFilter: UUID?
    @Published private(set) var rows: [HistoryListRow] = []
    @Published private(set) var state: String = "loading"

    private let matchRepository: any MatchRepository
    private let logger: (any AppLogger)?

    init(matchRepository: any MatchRepository, logger: (any AppLogger)? = nil) {
        self.matchRepository = matchRepository
        self.logger = logger
    }

    func onAppear() async {
        await applyFilters()
    }

    func applyFilters() async {
        state = "loading"
        do {
            let mapped = try await PerformanceMonitor.measure(.historyLoad, logger: logger) {
                try await matchRepository.fetchHistory(page: 0, pageSize: 500)
            }
            let filtered = mapped.filter { summary in
                let modePass: Bool
                switch modeFilter {
                case .all: modePass = true
                case .x01: modePass = summary.type == .x01
                case .cricket: modePass = summary.type == .cricket
                }
                let datePass: Bool = {
                    switch dateFilter {
                    case .all:
                        return true
                    case .d7:
                        return summary.startedAt >= Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? .distantPast
                    case .d30:
                        return summary.startedAt >= Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? .distantPast
                    }
                }()
                let playerPass = playerFilter == nil || summary.winnerPlayerId == playerFilter
                return modePass && datePass && playerPass
            }
            var enriched: [HistoryListRow] = []
            for summary in filtered {
                let participants = try await matchRepository.fetchParticipants(matchId: summary.id)
                let names = participants.map(\.displayNameAtMatchStart)
                let winnerName = participants.first(where: { $0.playerId == summary.winnerPlayerId })?.displayNameAtMatchStart
                    ?? NSLocalizedString("common.unknown", comment: "")
                enriched.append(
                    HistoryListRow(
                        summary: summary,
                        participantNames: names,
                        winnerName: winnerName
                    )
                )
            }
            rows = enriched
            state = rows.isEmpty ? "emptyFiltered" : "readyFiltered"
        } catch {
            rows = []
            state = "error"
        }
    }
}

@MainActor
final class HistoryDetailViewModel: ObservableObject {
    @Published private(set) var header: HistoryDetailHeader?
    @Published private(set) var timeline: [String] = []
    @Published private(set) var state: String = "loading"
    private let matchId: UUID
    private let matchRepository: any MatchRepository
    private let statsRepository: any StatsRepository

    init(
        matchId: UUID,
        matchRepository: any MatchRepository,
        statsRepository: any StatsRepository
    ) {
        self.matchId = matchId
        self.matchRepository = matchRepository
        self.statsRepository = statsRepository
    }

    func onAppear() async {
        do {
            guard let match = try await matchRepository.fetchMatch(matchId: matchId) else {
                timeline = []
                state = "error"
                return
            }
            let participants = try await matchRepository.fetchParticipants(matchId: matchId)
            let events = try await statsRepository.fetchEvents(matchId: matchId)
            let envelopes = try events
                .map { try CodablePayloadCoder.decode(MatchEventEnvelope.self, from: $0.eventPayload) }
                .sorted { $0.eventIndex < $1.eventIndex }
            let participantNames = Dictionary(
                uniqueKeysWithValues: participants.map { ($0.playerId ?? $0.id, $0.displayNameAtMatchStart) }
            )
            timeline = envelopes.map { envelope in
                switch envelope.payload {
                case let .x01Turn(turn):
                    let name = participantNames[turn.playerId] ?? String(turn.playerId.uuidString.prefix(6))
                    return "Turn \(turn.turnIndex + 1): \(name) +\(turn.appliedTotal)"
                case let .cricketTurn(turn):
                    let name = participantNames[turn.playerId] ?? String(turn.playerId.uuidString.prefix(6))
                    return "Turn \(turn.turnIndex + 1): \(name) +\(turn.totalPointsAdded)"
                }
            }
            header = buildHeader(match: match, participants: participants, envelopes: envelopes)
            state = "ready"
        } catch {
            header = nil
            timeline = []
            state = "error"
        }
    }

    private func buildHeader(
        match: MatchSummary,
        participants: [MatchParticipantSummary],
        envelopes: [MatchEventEnvelope]
    ) -> HistoryDetailHeader {
        let winnerName = participants
            .first(where: { $0.playerId == match.winnerPlayerId })?
            .displayNameAtMatchStart ?? NSLocalizedString("common.unknown", comment: "")
        let modeText = match.type == .x01 ? "X01" : "Cricket"
        let dateText = DateFormatter.localizedString(from: match.startedAt, dateStyle: .medium, timeStyle: .short)
        let durationText: String = {
            guard let end = match.endedAt else { return NSLocalizedString("common.unknown", comment: "") }
            let minutes = Int(max(0, end.timeIntervalSince(match.startedAt)) / 60)
            return "\(minutes)m"
        }()
        let participantsText = participants.map(\.displayNameAtMatchStart).joined(separator: ", ")
        let modeSpecificSummaryText: String = {
            switch match.type {
            case .x01:
                let turns = envelopes.compactMap { envelope -> X01TurnEvent? in
                    if case let .x01Turn(turn) = envelope.payload { return turn }
                    return nil
                }
                let total = turns.reduce(0) { $0 + $1.appliedTotal }
                let busts = turns.filter(\.isBust).count
                return "Total scored: \(total) • Busts: \(busts)"
            case .cricket:
                let turns = envelopes.compactMap { envelope -> CricketTurnEvent? in
                    if case let .cricketTurn(turn) = envelope.payload { return turn }
                    return nil
                }
                let points = turns.reduce(0) { $0 + $1.totalPointsAdded }
                return "Total points: \(points) • Turns: \(turns.count)"
            }
        }()
        return HistoryDetailHeader(
            modeText: modeText,
            winnerText: winnerName,
            dateText: dateText,
            durationText: durationText,
            participantsText: participantsText,
            modeSpecificSummaryText: modeSpecificSummaryText
        )
    }
}

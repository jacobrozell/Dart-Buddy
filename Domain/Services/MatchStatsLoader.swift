import Foundation

public struct MatchStatsLoadRequest: Sendable {
    public var matchType: MatchType?
    public var startedAfter: Date?
    public var participantPlayerId: UUID?

    public init(matchType: MatchType? = nil, startedAfter: Date? = nil, participantPlayerId: UUID? = nil) {
        self.matchType = matchType
        self.startedAfter = startedAfter
        self.participantPlayerId = participantPlayerId
    }
}

public struct MatchStatsLoadResult: Sendable {
    public let inputs: [MatchStatsInput]
    public let namesById: [UUID: String]

    public init(inputs: [MatchStatsInput], namesById: [UUID: String]) {
        self.inputs = inputs
        self.namesById = namesById
    }
}

public struct PlayerListSummary: Equatable, Sendable {
    public var games: Int
    public var wins: Int
    public var lastPlayedAt: Date?

    public init(games: Int = 0, wins: Int = 0, lastPlayedAt: Date? = nil) {
        self.games = games
        self.wins = wins
        self.lastPlayedAt = lastPlayedAt
    }
}

public struct RecentMatchSummary: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let type: MatchType
    public let playedAt: Date
    public let didWin: Bool
    public let opponentLabel: String

    public init(id: UUID, type: MatchType, playedAt: Date, didWin: Bool, opponentLabel: String) {
        self.id = id
        self.type = type
        self.playedAt = playedAt
        self.didWin = didWin
        self.opponentLabel = opponentLabel
    }
}

public struct CompletedMatchPreview: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let type: MatchType
    public let playedAt: Date
    public let participantsLabel: String
    public let winnerName: String?

    public init(
        id: UUID,
        type: MatchType,
        playedAt: Date,
        participantsLabel: String,
        winnerName: String?
    ) {
        self.id = id
        self.type = type
        self.playedAt = playedAt
        self.participantsLabel = participantsLabel
        self.winnerName = winnerName
    }
}

public enum MatchStatsLoader {
    public static let defaultPageSize = 100

    public static func load(
        matchRepository: any MatchRepository,
        statsRepository: any StatsRepository,
        request: MatchStatsLoadRequest,
        pageSize: Int = defaultPageSize
    ) async throws -> MatchStatsLoadResult {
        let safePageSize = max(1, pageSize)
        let filter = MatchHistoryFilter(matchType: request.matchType, startedAfter: request.startedAfter)
        var page = 0
        var inputs: [MatchStatsInput] = []
        var namesById: [UUID: String] = [:]

        while true {
            let batch = try await matchRepository.fetchHistoryWithParticipants(
                page: page,
                pageSize: safePageSize,
                filter: filter
            )
            guard !batch.isEmpty else { break }

            var eligible: [MatchHistoryRecord] = []
            for record in batch {
                let keys = record.participants.map { $0.playerId ?? $0.id }
                if let participantPlayerId = request.participantPlayerId, !keys.contains(participantPlayerId) {
                    continue
                }
                for participant in record.participants {
                    let key = participant.playerId ?? participant.id
                    namesById[key] = participant.displayNameAtMatchStart
                }
                eligible.append(record)
            }

            if !eligible.isEmpty {
                let matchIds = eligible.map(\.summary.id)
                let eventSummaries = try await statsRepository.fetchEvents(matchIds: matchIds)
                let eventsByMatchId = Dictionary(grouping: eventSummaries, by: \.matchId)

                for record in eligible {
                    let keys = record.participants.map { $0.playerId ?? $0.id }
                    let envelopes = decodeEvents(eventsByMatchId[record.summary.id] ?? [])
                    inputs.append(
                        MatchStatsInput(
                            matchId: record.summary.id,
                            playedAt: record.summary.endedAt ?? record.summary.startedAt,
                            type: record.summary.type,
                            participantKeys: keys,
                            winnerKey: record.summary.winnerPlayerId,
                            events: envelopes
                        )
                    )
                }
            }

            page += 1
            if batch.count < safePageSize { break }
        }

        return MatchStatsLoadResult(inputs: inputs, namesById: namesById)
    }

    public static func buildPlayerSummaries(
        matchRepository: any MatchRepository,
        pageSize: Int = defaultPageSize
    ) async throws -> [UUID: PlayerListSummary] {
        let safePageSize = max(1, pageSize)
        var page = 0
        var summaries: [UUID: PlayerListSummary] = [:]

        while true {
            let batch = try await matchRepository.fetchHistoryWithParticipants(
                page: page,
                pageSize: safePageSize,
                filter: MatchHistoryFilter()
            )
            guard !batch.isEmpty else { break }

            for record in batch {
                let summary = record.summary
                let playedAt = summary.endedAt ?? summary.startedAt
                for participant in record.participants {
                    let key = participant.playerId ?? participant.id
                    var entry = summaries[key, default: PlayerListSummary()]
                    entry.games += 1
                    if summary.winnerPlayerId == key { entry.wins += 1 }
                    entry.lastPlayedAt = max(entry.lastPlayedAt ?? .distantPast, playedAt)
                    summaries[key] = entry
                }
            }

            page += 1
            if batch.count < safePageSize { break }
        }

        return summaries
    }

    public static func recentMatches(
        for playerId: UUID,
        matchRepository: any MatchRepository,
        limit: Int = 5,
        pageSize: Int = defaultPageSize
    ) async throws -> [RecentMatchSummary] {
        guard limit > 0 else { return [] }
        let safePageSize = max(1, pageSize)
        var page = 0
        var recent: [RecentMatchSummary] = []

        while recent.count < limit {
            let batch = try await matchRepository.fetchHistoryWithParticipants(
                page: page,
                pageSize: safePageSize,
                filter: MatchHistoryFilter()
            )
            guard !batch.isEmpty else { break }

            for record in batch {
                let keys = record.participants.map { $0.playerId ?? $0.id }
                guard keys.contains(playerId) else { continue }
                let opponents = record.participants
                    .filter { ($0.playerId ?? $0.id) != playerId }
                    .map(\.displayNameAtMatchStart)
                recent.append(
                    RecentMatchSummary(
                        id: record.summary.id,
                        type: record.summary.type,
                        playedAt: record.summary.endedAt ?? record.summary.startedAt,
                        didWin: record.summary.winnerPlayerId == playerId,
                        opponentLabel: opponents.joined(separator: ", ")
                    )
                )
                if recent.count >= limit { break }
            }

            page += 1
            if batch.count < safePageSize { break }
        }

        return recent
    }

    public static func recentCompletedMatches(
        matchRepository: any MatchRepository,
        limit: Int = 3,
        pageSize: Int = defaultPageSize
    ) async throws -> [CompletedMatchPreview] {
        guard limit > 0 else { return [] }
        let batch = try await matchRepository.fetchHistoryWithParticipants(
            page: 0,
            pageSize: max(limit, 1),
            filter: MatchHistoryFilter()
        )
        return batch.prefix(limit).map { record in
            let names = record.participants.map(\.displayNameAtMatchStart)
            let winnerName = record.participants.first(where: {
                ($0.playerId ?? $0.id) == record.summary.winnerPlayerId
            })?.displayNameAtMatchStart
            return CompletedMatchPreview(
                id: record.summary.id,
                type: record.summary.type,
                playedAt: record.summary.endedAt ?? record.summary.startedAt,
                participantsLabel: names.joined(separator: " vs "),
                winnerName: winnerName
            )
        }
    }

    public static func decodeEvents(_ summaries: [MatchEventSummary]) -> [MatchEventEnvelope] {
        (try? summaries
            .map { try CodablePayloadCoder.decode(MatchEventEnvelope.self, from: $0.eventPayload) }
            .sorted { $0.eventIndex < $1.eventIndex }) ?? []
    }
}

import Foundation

public struct MatchStatsLoadRequest: Sendable {
    public var matchType: MatchType?
    public var includedMatchTypes: [MatchType]?
    public var startedAfter: Date?
    public var participantPlayerId: UUID?

    public init(
        matchType: MatchType? = nil,
        includedMatchTypes: [MatchType]? = nil,
        startedAfter: Date? = nil,
        participantPlayerId: UUID? = nil
    ) {
        self.matchType = matchType
        self.includedMatchTypes = includedMatchTypes
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

public enum MatchStatsLoader {
    public static let defaultPageSize = 100

    public static func load(
        matchRepository: any MatchRepository,
        statsRepository: any StatsRepository,
        request: MatchStatsLoadRequest,
        pageSize: Int = defaultPageSize
    ) async throws -> MatchStatsLoadResult {
        let safePageSize = max(1, pageSize)
        let filter = MatchHistoryFilter(
            matchType: request.matchType,
            includedMatchTypes: request.includedMatchTypes,
            startedAfter: request.startedAfter
        )
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

    public static func rehydrateSession(
        matchId: UUID,
        matchRepository: any MatchRepository,
        statsRepository: any StatsRepository
    ) async throws -> MatchLifecycleSession? {
        guard let snapshotSummary = try await matchRepository.fetchLatestSnapshot(matchId: matchId) else {
            return nil
        }
        let runtime = try CodablePayloadCoder.decode(MatchRuntimeState.self, from: snapshotSummary.snapshotPayload)
        let events = try await statsRepository.fetchEvents(matchId: matchId)
        let envelopes = try events
            .map { try CodablePayloadCoder.decode(MatchEventEnvelope.self, from: $0.eventPayload) }
            .sorted { $0.eventIndex < $1.eventIndex }
        let tailEvents = envelopes.filter { $0.eventIndex >= runtime.eventCount }
        let snapshot = MatchSnapshot(
            payloadVersion: snapshotSummary.snapshotVersion,
            eventCount: runtime.eventCount,
            createdAt: snapshotSummary.updatedAt,
            payload: snapshotSummary.snapshotPayload
        )
        return try MatchLifecycleService.rehydrate(snapshot: snapshot, tailEvents: tailEvents)
    }

    public static func loadPartialActiveMatchInput(
        matchRepository: any MatchRepository,
        statsRepository: any StatsRepository,
        activeMatch: MatchSummary
    ) async throws -> MatchStatsLoadResult? {
        guard activeMatch.status == .inProgress else { return nil }
        guard let session = try await rehydrateSession(
            matchId: activeMatch.id,
            matchRepository: matchRepository,
            statsRepository: statsRepository
        ) else { return nil }

        let runtime = session.runtime
        var namesById: [UUID: String] = [:]
        let keys = runtime.participants.map { participant in
            let key = participant.playerId ?? participant.id
            namesById[key] = participant.displayNameAtMatchStart
            return key
        }
        let input = MatchStatsInput(
            matchId: activeMatch.id,
            playedAt: activeMatch.startedAt,
            type: runtime.type,
            participantKeys: keys,
            winnerKey: nil,
            events: session.events,
            isPartial: true
        )
        return MatchStatsLoadResult(inputs: [input], namesById: namesById)
    }

    public static func decodeEvents(_ summaries: [MatchEventSummary]) -> [MatchEventEnvelope] {
        (try? summaries
            .map { try CodablePayloadCoder.decode(MatchEventEnvelope.self, from: $0.eventPayload) }
            .sorted { $0.eventIndex < $1.eventIndex }) ?? []
    }
}

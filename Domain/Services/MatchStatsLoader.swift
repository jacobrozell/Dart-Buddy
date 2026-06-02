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

    public static func decodeEvents(_ summaries: [MatchEventSummary]) -> [MatchEventEnvelope] {
        (try? summaries
            .map { try CodablePayloadCoder.decode(MatchEventEnvelope.self, from: $0.eventPayload) }
            .sorted { $0.eventIndex < $1.eventIndex }) ?? []
    }
}

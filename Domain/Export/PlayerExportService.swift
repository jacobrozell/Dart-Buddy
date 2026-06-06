import Foundation

public struct PlayerExportMetadata: Sendable {
    public let producer: String
    public let producerVersion: String
    public let persistenceSchemaVersion: String

    public init(
        producer: String = Bundle.main.bundleIdentifier ?? "com.jacobrozell.DartBuddy",
        producerVersion: String = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0",
        persistenceSchemaVersion: String = "2.0.0"
    ) {
        self.producer = producer
        self.producerVersion = producerVersion
        self.persistenceSchemaVersion = persistenceSchemaVersion
    }
}

public enum PlayerExportService {
    public static let defaultPageSize = MatchStatsLoader.defaultPageSize

    public static func buildBundle(
        anchorPlayerId: UUID,
        matchRepository: any MatchRepository,
        statsRepository: any StatsRepository,
        playerRepository: any PlayerRepository,
        metadata: PlayerExportMetadata = PlayerExportMetadata(),
        pageSize: Int = defaultPageSize
    ) async throws -> PlayerExportBundle {
        let allPlayers = try await playerRepository.fetchPlayers(includeArchived: true)
        guard let anchor = allPlayers.first(where: { $0.id == anchorPlayerId }) else {
            throw AppError(
                code: .notFound,
                layer: .domain,
                severity: .warning,
                isRecoverable: true,
                userMessageKey: "players.detail.notFound",
                debugContext: ["playerId": anchorPlayerId.uuidString]
            )
        }

        let safePageSize = max(1, pageSize)
        let filter = MatchHistoryFilter(participantPlayerId: anchorPlayerId)
        var page = 0
        var matchBundles: [MatchExportBundle] = []
        var referencedPlayerIds = Set<UUID>()

        while true {
            let batch = try await matchRepository.fetchHistoryWithParticipants(
                page: page,
                pageSize: safePageSize,
                filter: filter
            )
            guard !batch.isEmpty else { break }

            let matchIds = batch.map(\.summary.id)
            let eventSummaries = try await statsRepository.fetchEvents(matchIds: matchIds)
            let eventsByMatchId = Dictionary(grouping: eventSummaries, by: \.matchId)

            for record in batch {
                let matchId = record.summary.id
                let events = (eventsByMatchId[matchId] ?? [])
                    .sorted { $0.eventIndex < $1.eventIndex }
                    .map(MatchEventExportRecord.init)
                let snapshot = try await matchRepository.fetchLatestSnapshot(matchId: matchId)
                    .map(MatchSnapshotExportRecord.init)
                let configPayload = try await matchRepository.fetchConfigPayload(matchId: matchId)

                for participant in record.participants {
                    if let playerId = participant.playerId, playerId != anchorPlayerId {
                        referencedPlayerIds.insert(playerId)
                    }
                }

                matchBundles.append(
                    MatchExportBundle(
                        match: MatchExportRecord(from: record.summary),
                        configPayload: configPayload,
                        participants: record.participants.map(MatchParticipantExportRecord.init),
                        events: events,
                        snapshot: snapshot
                    )
                )
            }

            page += 1
            if batch.count < safePageSize { break }
        }

        let referencedPlayers = allPlayers
            .filter { referencedPlayerIds.contains($0.id) }
            .map(PlayerExportRecord.init)
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }

        let bundle = PlayerExportBundle(
            dbpeVersion: PlayerExportBundle.supportedVersion,
            producer: metadata.producer,
            producerVersion: metadata.producerVersion,
            exportedAt: Date(),
            persistenceSchemaVersion: metadata.persistenceSchemaVersion,
            anchorPlayerId: anchorPlayerId,
            player: PlayerExportRecord(from: anchor),
            referencedPlayers: referencedPlayers,
            matches: matchBundles
        )
        try PlayerExportValidator.validate(bundle)
        return bundle
    }

    public static func writeExportFile(bundle: PlayerExportBundle, playerName: String) throws -> URL {
        let data = try PlayerExportBundleCoding.encode(bundle)
        let sanitized = sanitizeFileNameComponent(playerName)
        let fileName = "\(sanitized)-dartbuddy-export.dartbuddy.json"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        try data.write(to: url, options: .atomic)
        return url
    }

    public static func exportFile(
        anchorPlayerId: UUID,
        playerName: String,
        matchRepository: any MatchRepository,
        statsRepository: any StatsRepository,
        playerRepository: any PlayerRepository,
        metadata: PlayerExportMetadata = PlayerExportMetadata()
    ) async throws -> URL {
        let bundle = try await buildBundle(
            anchorPlayerId: anchorPlayerId,
            matchRepository: matchRepository,
            statsRepository: statsRepository,
            playerRepository: playerRepository,
            metadata: metadata
        )
        return try writeExportFile(bundle: bundle, playerName: playerName)
    }

    private static func sanitizeFileNameComponent(_ name: String) -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let fallback = trimmed.isEmpty ? "player" : trimmed
        let invalid = CharacterSet(charactersIn: "/\\?%*|\"<>:")
        return fallback
            .components(separatedBy: invalid)
            .joined(separator: "-")
            .replacingOccurrences(of: " ", with: "-")
    }
}

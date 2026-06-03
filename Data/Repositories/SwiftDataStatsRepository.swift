import Foundation
import SwiftData

public actor SwiftDataStatsRepository: StatsRepository {
    private let container: ModelContainer

    public init(container: ModelContainer) {
        self.container = container
    }

    public func fetchEvents(matchId: UUID) async throws -> [MatchEventSummary] {
        try await fetchEvents(matchIds: [matchId])
    }

    public func fetchEvents(matchIds: [UUID]) async throws -> [MatchEventSummary] {
        guard !matchIds.isEmpty else { return [] }
        return try dataCall {
            let context = ModelContext(container)
            let descriptor = FetchDescriptor<SchemaV1.MatchEventRecord>(
                predicate: #Predicate<SchemaV1.MatchEventRecord> { matchIds.contains($0.matchId) },
                sortBy: [SortDescriptor(\.eventIndex, order: .forward)]
            )
            return try context.fetch(descriptor).map(mapEvent)
        }
    }
}

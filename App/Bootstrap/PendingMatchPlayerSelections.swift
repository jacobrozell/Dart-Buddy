import Combine
import Foundation

/// Remembers player IDs created outside match setup so `MatchSetupViewModel` can include them once those players appear in the roster.
@MainActor
public final class PendingMatchPlayerSelections: ObservableObject {
    @Published public private(set) var changeCount = 0
    private var pending: Set<UUID> = []

    public init() {}

    public func enqueueForNextMatchSetup(_ playerId: UUID) {
        pending.insert(playerId)
        changeCount += 1
    }

    /// Removes from the queue and returns every pending ID that exists in `loadedPlayerIds`.
    public func dequeueIdsPresent(in loadedPlayerIds: Set<UUID>) -> Set<UUID> {
        let matched = pending.intersection(loadedPlayerIds)
        pending.subtract(matched)
        return matched
    }
}

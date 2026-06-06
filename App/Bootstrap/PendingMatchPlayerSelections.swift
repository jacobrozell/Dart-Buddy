import Combine
import Foundation

/// Mode chosen from the Modes tab to prefill Play setup on the next visit.
struct PendingModeSelection: Equatable {
    var setupCategory: PlaySetupCategory
    var mode: MatchSetupViewModel.SetupMode?
    var partyGame: PartyGame?
    var matchType: MatchType?
}

/// Remembers player IDs created outside match setup so `MatchSetupViewModel` can include them once those players appear in the roster.
@MainActor
public final class PendingMatchPlayerSelections: ObservableObject {
    @Published public private(set) var changeCount = 0
    @Published public private(set) var preferredMatchType: MatchType?
    @Published private(set) var pendingModeSelection: PendingModeSelection?
    private var pending: Set<UUID> = []

    public init() {}

    public func enqueueForNextMatchSetup(_ playerId: UUID) {
        pending.insert(playerId)
        changeCount += 1
    }

    public func enqueuePractice(humanId: UUID, trainingBotId: UUID, mode: MatchType) {
        pending.insert(humanId)
        pending.insert(trainingBotId)
        preferredMatchType = mode
        changeCount += 1
    }

    func enqueueModeSelection(_ selection: PendingModeSelection) {
        pendingModeSelection = selection
        changeCount += 1
    }

    func consumeModeSelection() -> PendingModeSelection? {
        defer { pendingModeSelection = nil }
        return pendingModeSelection
    }

    public func consumePreferredMatchType() -> MatchType? {
        defer { preferredMatchType = nil }
        return preferredMatchType
    }

    /// Removes from the queue and returns every pending ID that exists in `loadedPlayerIds`.
    public func dequeueIdsPresent(in loadedPlayerIds: Set<UUID>) -> Set<UUID> {
        let matched = pending.intersection(loadedPlayerIds)
        pending.subtract(matched)
        return matched
    }

    public func clearAll() {
        pending.removeAll()
        preferredMatchType = nil
        pendingModeSelection = nil
        changeCount += 1
    }
}

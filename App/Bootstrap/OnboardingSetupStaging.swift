import Foundation

/// Persists onboarding roster IDs until Play setup can stage them after the first-launch cover dismisses.
enum OnboardingSetupStaging {
    static let pendingPlayerIdsKey = "onboarding_pending_setup_player_ids"

    static func savePendingPlayerIds(_ ids: [UUID]) {
        UserDefaults.standard.set(ids.map(\.uuidString), forKey: pendingPlayerIdsKey)
    }

    static func peekPendingPlayerIds() -> [UUID] {
        guard let raw = UserDefaults.standard.stringArray(forKey: pendingPlayerIdsKey) else { return [] }
        return raw.compactMap(UUID.init(uuidString:))
    }

    static func consumePendingPlayerIds() -> [UUID] {
        defer { clearPendingPlayerIds() }
        return peekPendingPlayerIds()
    }

    static func clearPendingPlayerIds() {
        UserDefaults.standard.removeObject(forKey: pendingPlayerIdsKey)
    }
}

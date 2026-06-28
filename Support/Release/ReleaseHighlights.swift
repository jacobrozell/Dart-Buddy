import Foundation

/// One-time in-app promo for a shipped release slice (e.g. Party Pack 1.1).
struct ReleaseHighlight: Equatable, Sendable {
    struct Feature: Equatable, Sendable {
        let matchType: MatchType
        let catalogID: String
    }

    let version: String
    let features: [Feature]

    static let partyPack1_1 = ReleaseHighlight(
        version: "1.1.0",
        features: [
            Feature(matchType: .baseball, catalogID: "party.baseball"),
            Feature(matchType: .killer, catalogID: "party.killer"),
            Feature(matchType: .shanghai, catalogID: "party.shanghai"),
            Feature(matchType: .raid, catalogID: "coop.raid"),
            Feature(matchType: .aroundTheClock, catalogID: "practice.aroundTheClock"),
        ]
    )
}

enum ReleaseHighlights {
    static var current: ReleaseHighlight? {
        current(arguments: ProcessInfo.processInfo.arguments)
    }

    static func current(arguments: [String]) -> ReleaseHighlight? {
        let config = ProductSurface.configuration(for: arguments)
        guard config == .party1_1 else { return nil }
        return .partyPack1_1
    }
}

/// Persists which release highlight the user has dismissed.
struct ReleaseHighlightsStore: @unchecked Sendable {
    static let dismissedVersionKey = "release_highlights_dismissed_version"
    static let skipLaunchArgument = "-skip_release_highlights"

    let userDefaults: UserDefaults
    let isEnabled: Bool

    init(
        userDefaults: UserDefaults = .standard,
        isEnabled: Bool = ReleaseHighlightsStore.defaultIsEnabled
    ) {
        self.userDefaults = userDefaults
        self.isEnabled = isEnabled
    }

    static var defaultIsEnabled: Bool {
        let arguments = ProcessInfo.processInfo.arguments
        return !arguments.contains(skipLaunchArgument)
    }

    var dismissedVersion: String? {
        userDefaults.string(forKey: Self.dismissedVersionKey)
    }

    func shouldPresent(highlight: ReleaseHighlight) -> Bool {
        isEnabled && dismissedVersion != highlight.version
    }

    func markDismissed(version: String) {
        userDefaults.set(version, forKey: Self.dismissedVersionKey)
    }

    static func clearPersistedState(userDefaults: UserDefaults = .standard) {
        userDefaults.removeObject(forKey: dismissedVersionKey)
    }
}

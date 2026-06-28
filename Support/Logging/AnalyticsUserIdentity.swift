import FirebaseAnalytics
import FirebaseCrashlytics
import Foundation

/// Links Firebase identity for retention and crash attribution.
///
/// Phase 1 (offline / local-first): primary human `PlayerSummary.id` as lowercased UUID.
/// Phase 2 (Firebase Auth + online play): prefer authenticated Firebase UID when signed in;
/// keep local primary UUID as fallback until account linking is complete.
///
/// Per-event metadata never includes `playerId` or display names.
public enum AnalyticsUserIdentity {
    public static func resolveUserId(
        primaryPlayer: PlayerSummary?,
        authenticatedFirebaseUID: String? = nil
    ) -> String? {
        if let authenticatedFirebaseUID, !authenticatedFirebaseUID.isEmpty {
            return authenticatedFirebaseUID
        }
        guard let primaryPlayer, !primaryPlayer.isBot else { return nil }
        return primaryPlayer.id.uuidString.lowercased()
    }

    public static func sync(from repository: any PlayerRepository) async {
        let primary = try? await repository.fetchPrimaryPlayer()
        sync(userId: resolveUserId(primaryPlayer: primary))
    }

    public static func sync(
        primaryPlayer: PlayerSummary?,
        authenticatedFirebaseUID: String? = nil
    ) {
        sync(userId: resolveUserId(
            primaryPlayer: primaryPlayer,
            authenticatedFirebaseUID: authenticatedFirebaseUID
        ))
    }

    public static func sync(userId: String?) {
        guard FirebaseBootstrap.shouldConfigure else { return }

        if FirebaseBootstrap.isAnalyticsCollectionEnabled {
            Analytics.setUserID(userId)
        }
        if FirebaseBootstrap.isCrashlyticsCollectionEnabled {
            Crashlytics.crashlytics().setUserID(userId ?? "")
        }
    }

    /// Updates GA4 user properties for mode-level retention reporting.
    public static func syncLastGameMode(for matchType: MatchType) {
        guard FirebaseBootstrap.shouldConfigure, FirebaseBootstrap.isAnalyticsCollectionEnabled else { return }

        let metadata = GameModeAnalytics.metadata(for: matchType)
        Analytics.setUserProperty(matchType.rawValue, forName: "last_match_type")
        if let gameModeId = metadata["gameModeId"] {
            Analytics.setUserProperty(gameModeId, forName: "last_game_mode_id")
        }
        if let gameModeSection = metadata["gameModeSection"] {
            Analytics.setUserProperty(gameModeSection, forName: "last_game_mode_section")
        }
    }
}

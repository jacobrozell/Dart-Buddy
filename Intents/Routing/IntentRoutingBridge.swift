import AppIntents
import Foundation

/// Routes App Intent navigation through the shared deep-link spine.
///
/// Intents call `route(_:intentName:)` instead of navigating directly. When the app shell
/// is not ready (cold launch), destinations enqueue on `PendingAppDestination` — same path
/// as `.onOpenURL`. See `specs/AppIntentsSpec.md`.
@MainActor
enum IntentRoutingBridge {
    private static weak var pendingDeepLink: PendingAppDestination?
    private static var dependencies: AppDependencies?
    private static var routeActions: AppRouteRouter.Actions?
    static var featureFlagOverrides: [FeatureFlag: Bool] = [:]

    static var isEnabled: Bool {
        LocalFeatureFlagsProvider(overrides: featureFlagOverrides).isEnabled(.enableAppIntents)
    }

    static func setPendingDeepLink(_ pending: PendingAppDestination) {
        pendingDeepLink = pending
    }

    static func configure(dependencies: AppDependencies, actions: AppRouteRouter.Actions) {
        self.dependencies = dependencies
        routeActions = actions
    }

    static func clearRouteActions() {
        routeActions = nil
    }

    static func fetchActiveMatch() async -> MatchSummary? {
        guard let dependencies else { return nil }
        return try? await dependencies.matchRepository.fetchActiveMatch()
    }

    static func fetchResumableActiveMatch() async -> MatchSummary? {
        guard let match = await fetchActiveMatch(),
              ProductSurface.isMatchTypeReachable(match.type) else { return nil }
        return match
    }

    static var isRoutingReady: Bool {
        dependencies != nil && routeActions != nil
    }

    @discardableResult
    static func route(
        _ destination: AppDestination,
        intentName: String,
        succeeded: Bool = true
    ) async -> RouteOutcome {
        guard isEnabled else {
            log(intentName: intentName, eventName: "intent_failed", outcome: .failed(.unknownPath))
            return .failed(.unknownPath)
        }

        if let dependencies, let routeActions {
            let router = AppRouteRouter(dependencies: dependencies)
            let outcome = await router.handle(destination, actions: routeActions)
            let applied = succeeded && outcome == .applied
            let eventName = applied ? "intent_performed" : "intent_failed"
            log(intentName: intentName, eventName: eventName, outcome: outcome)
            return outcome
        }

        pendingDeepLink?.enqueue(destination)
        let eventName = succeeded ? "intent_performed" : "intent_failed"
        log(intentName: intentName, eventName: eventName, outcome: .applied)
        return .applied
    }

    private static func log(intentName: String, eventName: String, outcome: RouteOutcome) {
        var metadata = ["intentName": intentName]
        if case let .failed(error) = outcome, error == .unknownPath, intentName == ResumeActiveMatchIntent.intentName {
            metadata["path"] = "play/resume"
        }
        dependencies?.logger.info(
            .ui,
            eventName: eventName,
            message: "App intent routed.",
            metadata: metadata
        )
    }
}

enum IntentRoutingError: Error, CustomLocalizedStringResourceConvertible {
    case disabled

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .disabled:
            "intent.error.disabled"
        }
    }
}

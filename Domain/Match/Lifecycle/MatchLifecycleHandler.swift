import Foundation

/// Per-mode lifecycle plugin for turn submission and event replay.
protocol MatchLifecycleHandler {
    associatedtype TurnEvent: Sendable

    static var matchType: MatchType { get }

    static func submitTurn(
        session: MatchLifecycleSession,
        timestamp: Date
    ) throws -> MatchLifecycleSession

    static func replayEvent(
        _ event: TurnEvent,
        session: MatchLifecycleSession,
        timestamp: Date
    ) throws -> MatchLifecycleSession
}

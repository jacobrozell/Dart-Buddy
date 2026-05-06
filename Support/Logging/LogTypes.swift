import Foundation

public enum LogLevel: Int, Comparable, Sendable {
    case debug = 0
    case info = 1
    case warning = 2
    case error = 3
    case fault = 4

    public static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

public enum LogCategory: String, Sendable {
    case ui
    case scoring
    case persistence
    case migration
    case network
    case vision
    case watch
    case security
    case settings
    case appLifecycle
}

public struct LogEntry: Sendable {
    public let timestamp: Date
    public let level: LogLevel
    public let category: LogCategory
    public let eventName: String
    public let message: String
    public let metadata: [String: String]
    public let correlationId: String?
}

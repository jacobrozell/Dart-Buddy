import Foundation
import OSLog

public protocol LogSink: Sendable {
    func write(_ entry: LogEntry)
}

public struct ConsoleLogSink: LogSink {
    private let subsystem: String

    public init(subsystem: String = "com.darts-scoreboard.app") {
        self.subsystem = subsystem
    }

    public func write(_ entry: LogEntry) {
        let logger = Logger(subsystem: subsystem, category: entry.category.rawValue)
        logger.log(level: entry.level.osLogType, "\(formattedMessage(for: entry), privacy: .public)")
    }

    private func formattedMessage(for entry: LogEntry) -> String {
        let metadataPart = entry.metadata.isEmpty ? "" : " metadata=\(entry.metadata)"
        let correlationPart = entry.correlationId.map { " correlationId=\($0)" } ?? ""
        return "[\(entry.eventName)] \(entry.message)\(metadataPart)\(correlationPart)"
    }
}

private extension LogLevel {
    var osLogType: OSLogType {
        switch self {
        case .debug:
            return .debug
        case .info:
            return .info
        case .warning:
            return .default
        case .error:
            return .error
        case .fault:
            return .fault
        }
    }
}

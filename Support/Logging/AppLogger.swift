import Foundation

public protocol AppLogger: Sendable {
    func log(
        level: LogLevel,
        category: LogCategory,
        eventName: String,
        message: String,
        metadata: [String: String]?,
        correlationId: String?
    )
}

public extension AppLogger {
    func debug(
        _ category: LogCategory,
        eventName: String,
        message: String,
        metadata: [String: String]? = nil,
        correlationId: String? = nil
    ) {
        log(level: .debug, category: category, eventName: eventName, message: message, metadata: metadata, correlationId: correlationId)
    }

    func info(
        _ category: LogCategory,
        eventName: String,
        message: String,
        metadata: [String: String]? = nil,
        correlationId: String? = nil
    ) {
        log(level: .info, category: category, eventName: eventName, message: message, metadata: metadata, correlationId: correlationId)
    }

    func warning(
        _ category: LogCategory,
        eventName: String,
        message: String,
        metadata: [String: String]? = nil,
        correlationId: String? = nil
    ) {
        log(level: .warning, category: category, eventName: eventName, message: message, metadata: metadata, correlationId: correlationId)
    }

    func error(
        _ category: LogCategory,
        eventName: String,
        message: String,
        metadata: [String: String]? = nil,
        correlationId: String? = nil
    ) {
        log(level: .error, category: category, eventName: eventName, message: message, metadata: metadata, correlationId: correlationId)
    }

    func fault(
        _ category: LogCategory,
        eventName: String,
        message: String,
        metadata: [String: String]? = nil,
        correlationId: String? = nil
    ) {
        log(level: .fault, category: category, eventName: eventName, message: message, metadata: metadata, correlationId: correlationId)
    }
}

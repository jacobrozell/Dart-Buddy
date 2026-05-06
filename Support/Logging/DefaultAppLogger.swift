import Foundation

public struct DefaultAppLogger: AppLogger {
    private let minimumLevel: LogLevel
    private let sink: any LogSink
    private let redactionPolicy: any RedactionPolicy

    public init(
        minimumLevel: LogLevel,
        sink: any LogSink,
        redactionPolicy: any RedactionPolicy = DefaultRedactionPolicy()
    ) {
        self.minimumLevel = minimumLevel
        self.sink = sink
        self.redactionPolicy = redactionPolicy
    }

    public func log(
        level: LogLevel,
        category: LogCategory,
        eventName: String,
        message: String,
        metadata: [String: String]?,
        correlationId: String?
    ) {
        guard level >= minimumLevel else {
            return
        }
        let redactedMetadata = redactionPolicy.redact(metadata: metadata ?? [:])
        let entry = LogEntry(
            timestamp: Date(),
            level: level,
            category: category,
            eventName: eventName,
            message: message,
            metadata: redactedMetadata,
            correlationId: correlationId
        )
        sink.write(entry)
    }
}

public extension DefaultAppLogger {
    static func makeForCurrentBuild() -> DefaultAppLogger {
        #if DEBUG
        DefaultAppLogger(minimumLevel: .debug, sink: ConsoleLogSink())
        #else
        DefaultAppLogger(minimumLevel: .info, sink: ConsoleLogSink())
        #endif
    }
}

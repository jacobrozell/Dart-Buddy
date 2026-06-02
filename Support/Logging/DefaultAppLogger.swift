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
    static func makeForCurrentBuild(
        featureFlags: any FeatureFlagsProvider = LocalFeatureFlagsProvider()
    ) -> DefaultAppLogger {
        let console = ConsoleLogSink()
        let remoteSink: any RemoteAnalyticsLogSink =
            if featureFlags.isEnabled(.enableFirebaseAnalytics) {
                FirebaseAnalyticsLogSink(isCollectionEnabled: FirebaseBootstrap.isAnalyticsCollectionEnabled)
            } else {
                NoOpRemoteAnalyticsLogSink()
            }
        let remote = FilteredLogSink(minimumLevel: .info, wrapped: remoteSink)
        let sink = CompositeLogSink(sinks: [console, remote])
        #if DEBUG
        return DefaultAppLogger(minimumLevel: .debug, sink: sink)
        #else
        return DefaultAppLogger(minimumLevel: .info, sink: sink)
        #endif
    }
}

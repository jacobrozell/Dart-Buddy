import Foundation

public struct CompositeLogSink: LogSink {
    private let sinks: [any LogSink]

    public init(sinks: [any LogSink]) {
        self.sinks = sinks
    }

    public func write(_ entry: LogEntry) {
        for sink in sinks {
            sink.write(entry)
        }
    }
}

public struct FilteredLogSink: LogSink {
    private let minimumLevel: LogLevel
    private let wrapped: any LogSink

    public init(minimumLevel: LogLevel, wrapped: any LogSink) {
        self.minimumLevel = minimumLevel
        self.wrapped = wrapped
    }

    public func write(_ entry: LogEntry) {
        guard entry.level >= minimumLevel else { return }
        wrapped.write(entry)
    }
}

public struct NoOpLogSink: LogSink {
    public init() {}

    public func write(_ entry: LogEntry) {}
}

/// Adapter boundary for Bugsnag, Firebase Analytics, etc. Crashlytics uses `LogSink` directly (`FirebaseCrashlyticsLogSink`).
/// App code never references concrete SDK types; swap this sink when a provider is enabled.
public protocol RemoteAnalyticsLogSink: LogSink {}

public struct NoOpRemoteAnalyticsLogSink: RemoteAnalyticsLogSink {
    public init() {}

    public func write(_ entry: LogEntry) {}
}

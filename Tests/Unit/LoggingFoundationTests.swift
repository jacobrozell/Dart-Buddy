import Foundation
import Testing
@testable import DartBuddy

@Test(.tags(.unit, .logging, .regression, .critical))
func redactionPolicyAllowlistsMetadata() {
    let policy = DefaultRedactionPolicy(allowedMetadataKeys: ["errorCode", "token"])
    let output = policy.redact(metadata: [
        "errorCode": "migrationFailed",
        "matchId": "123",
        "token": "abc"
    ])

    #expect(output["errorCode"] == "migrationFailed")
    #expect(output["matchId"] == nil)
    #expect(output["token"] == "[REDACTED]")
}

@Test(.tags(.unit, .logging, .regression, .critical))
func loggerDropsEntriesBelowMinimumLevel() {
    let sink = RecordingSink()
    let logger = DefaultAppLogger(
        minimumLevel: .info,
        sink: sink,
        redactionPolicy: DefaultRedactionPolicy(allowedMetadataKeys: ["errorCode"])
    )

    logger.debug(.persistence, eventName: "debug_event", message: "drop me")
    logger.info(.persistence, eventName: "info_event", message: "keep me", metadata: ["errorCode": "ok"])

    #expect(sink.entries.count == 1)
    #expect(sink.entries.first?.eventName == "info_event")
}

@Test(.tags(.unit, .logging, .regression))
func compositeSinkForwardsToAllSinks() {
    let first = RecordingSink()
    let second = RecordingSink()
    let sink = CompositeLogSink(sinks: [first, second])
    let entry = LogEntry(
        timestamp: Date(),
        level: .info,
        category: .ui,
        eventName: "composite_event",
        message: "hello",
        metadata: [:],
        correlationId: nil
    )

    sink.write(entry)

    #expect(first.entries.count == 1)
    #expect(second.entries.count == 1)
}

@Test(.tags(.unit, .logging, .regression))
func filteredSinkDropsEntriesBelowThreshold() {
    let wrapped = RecordingSink()
    let sink = FilteredLogSink(minimumLevel: .warning, wrapped: wrapped)
    let logger = DefaultAppLogger(minimumLevel: .debug, sink: sink)

    logger.info(.ui, eventName: "info_event", message: "drop")
    logger.warning(.ui, eventName: "warning_event", message: "keep")

    #expect(wrapped.entries.count == 1)
    #expect(wrapped.entries.first?.eventName == "warning_event")
}

@Test(.tags(.unit, .logging, .regression))
func matchTracingAddsCorrelationMetadata() {
    let sink = RecordingSink()
    let logger = DefaultAppLogger(minimumLevel: .debug, sink: sink)
    let matchId = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!

    logger.matchInfo(
        matchId: matchId,
        matchType: .x01,
        eventName: "match_started",
        message: "Started."
    )

    #expect(sink.entries.count == 1)
    #expect(sink.entries.first?.correlationId == matchId.uuidString)
    #expect(sink.entries.first?.metadata["matchId"] == matchId.uuidString)
    #expect(sink.entries.first?.metadata["matchType"] == MatchType.x01.rawValue)
}

@Test(.tags(.unit, .logging, .performance, .regression))
func performanceMonitorReturnsSyncBlockResultAndLogsElapsedMs() {
    let sink = RecordingSink()
    let logger = DefaultAppLogger(minimumLevel: .debug, sink: sink)
    let result = PerformanceMonitor.measure(.submitTurn, logger: logger, metadata: ["matchType": "x01"]) {
        42
    }

    #expect(result == 42)
    #expect(sink.entries.count == 1)
    #expect(sink.entries.first?.eventName == "performance_metric")
    #expect(sink.entries.first?.metadata["operation"] == PerformanceOperation.submitTurn.rawValue)
    #expect(sink.entries.first?.metadata["matchType"] == "x01")
    #expect(Int(sink.entries.first?.metadata["elapsedMs"] ?? "") != nil)
}

@Test(.tags(.unit, .logging, .performance, .regression))
func performanceMonitorReturnsAsyncBlockResult() async throws {
    let result = try await PerformanceMonitor.measure(.historyLoad) {
        try await Task.sleep(nanoseconds: 1_000)
        return "done"
    }

    #expect(result == "done")
}

private final class RecordingSink: LogSink, @unchecked Sendable {
    var entries: [LogEntry] = []

    func write(_ entry: LogEntry) {
        entries.append(entry)
    }
}

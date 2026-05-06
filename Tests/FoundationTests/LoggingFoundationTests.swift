import Foundation
import Testing

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

private final class RecordingSink: LogSink, @unchecked Sendable {
    var entries: [LogEntry] = []

    func write(_ entry: LogEntry) {
        entries.append(entry)
    }
}

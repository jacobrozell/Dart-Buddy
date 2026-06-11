import Testing
@testable import DartBuddy

@Suite("App error", .tags(.unit, .regression))
struct AppErrorTests {
    @Test
    func migrationFailureWrapsUnderlyingError() {
        struct Sample: Error {}
        let underlying = Sample()
        let error = AppError.migrationFailure(underlying)

        #expect(error.code == .migrationFailed)
        #expect(error.layer == .data)
        #expect(error.severity == .fault)
        #expect(error.isRecoverable)
        #expect(error.userMessageKey == "error.migration.failed")
        #expect(error.underlyingError != nil)
    }

    @Test
    func initializerStoresDebugContext() {
        let error = AppError(
            code: .validationFailed,
            layer: .domain,
            severity: .warning,
            isRecoverable: true,
            userMessageKey: "error.validation",
            debugContext: ["field": "name"]
        )
        #expect(error.debugContext["field"] == "name")
        #expect(error.underlyingError == nil)
    }

    @Test
    func errorCodeCoversCommonFailureModes() {
        let codes: [ErrorCode] = [
            .validationFailed, .invalidGameState, .ruleViolation, .unsupportedOperation,
            .notFound, .conflict, .serializationFailed, .migrationFailed, .storageUnavailable,
            .unknown, .cancelled
        ]
        #expect(codes.count == 11)
        for code in codes {
            #expect(!code.rawValue.isEmpty)
        }
    }
}

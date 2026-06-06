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
}

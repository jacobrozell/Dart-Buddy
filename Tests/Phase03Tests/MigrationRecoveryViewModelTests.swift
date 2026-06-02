import Foundation
import Testing
@testable import DartsScoreboard

@MainActor
private func waitUntil(
    timeout: Duration = .seconds(2),
    _ condition: @MainActor () -> Bool
) async {
    let deadline = ContinuousClock.now + timeout
    while ContinuousClock.now < deadline {
        if condition() { return }
        try? await Task.sleep(for: .milliseconds(25))
    }
}

@MainActor
@Test(.tags(.unit, .regression))
func migrationRecoveryRetrySuccessReturnsToReady() async {
    var retryCount = 0
    let vm = MigrationRecoveryViewModel(
        context: sampleMigrationContext(),
        retryHandler: {
            retryCount += 1
            return true
        },
        resetHandler: { false }
    )

    vm.tapRetry()
    await waitUntil { vm.state == .ready }

    #expect(retryCount == 1)
    #expect(vm.state == .ready)
}

@MainActor
@Test(.tags(.unit, .regression))
func migrationRecoveryRetryFailureSurfacesRetryFailed() async {
    let vm = MigrationRecoveryViewModel(
        context: sampleMigrationContext(),
        retryHandler: { false },
        resetHandler: { false }
    )

    vm.tapRetry()
    await waitUntil { vm.state == .retryFailed }

    #expect(vm.state == .retryFailed)
}

@MainActor
@Test(.tags(.unit, .regression))
func migrationRecoveryResetSuccessMarksCompleted() async {
    var resetCount = 0
    let vm = MigrationRecoveryViewModel(
        context: sampleMigrationContext(),
        retryHandler: { false },
        resetHandler: {
            resetCount += 1
            return true
        }
    )

    vm.tapResetLocalData()
    await waitUntil { vm.state == .resetCompleted }

    #expect(resetCount == 1)
    #expect(vm.state == .resetCompleted)
}

@MainActor
@Test(.tags(.unit, .regression))
func migrationRecoveryResetFailureReturnsToReady() async {
    let vm = MigrationRecoveryViewModel(
        context: sampleMigrationContext(),
        retryHandler: { false },
        resetHandler: { false }
    )

    vm.tapResetLocalData()
    await waitUntil { vm.state != .resetInProgress }

    #expect(vm.state == .ready)
}

@MainActor
@Test(.tags(.unit, .regression))
func migrationRecoveryExportDiagnosticsWritesFile() async {
    let vm = MigrationRecoveryViewModel(
        context: sampleMigrationContext(),
        retryHandler: { false },
        resetHandler: { false }
    )

    vm.tapExportDiagnostics()
    await waitUntil {
        if case .exportCompleted = vm.state { return true }
        return false
    }

    if case let .exportCompleted(path) = vm.state {
        #expect(FileManager.default.fileExists(atPath: path))
        let contents = try? String(contentsOfFile: path, encoding: .utf8)
        #expect(contents?.contains("migration_error_key=error.migration.failed") == true)
    } else {
        Issue.record("Expected exportCompleted state")
    }
}

private func sampleMigrationContext() -> MigrationRecoveryContext {
    MigrationRecoveryContext(
        error: AppError(
            code: .migrationFailed,
            layer: .data,
            severity: .error,
            isRecoverable: true,
            userMessageKey: "error.migration.failed"
        )
    )
}

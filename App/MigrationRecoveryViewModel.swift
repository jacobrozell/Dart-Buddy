import Foundation

@MainActor
final class MigrationRecoveryViewModel: ObservableObject {
    enum State: Equatable {
        case ready
        case retryInProgress
        case retryFailed
        case exportInProgress
        case exportCompleted(String)
        case resetInProgress
        case resetCompleted
    }

    @Published private(set) var state: State = .ready
    let context: MigrationRecoveryContext
    private let retryHandler: @MainActor () async -> Bool
    private let resetHandler: @MainActor () async -> Bool

    init(
        context: MigrationRecoveryContext,
        retryHandler: @escaping @MainActor () async -> Bool,
        resetHandler: @escaping @MainActor () async -> Bool
    ) {
        self.context = context
        self.retryHandler = retryHandler
        self.resetHandler = resetHandler
    }

    func tapRetry() {
        Task {
            state = .retryInProgress
            let success = await retryHandler()
            state = success ? .ready : .retryFailed
        }
    }

    func tapExportDiagnostics() {
        Task {
            state = .exportInProgress
            let text = """
            migration_error_key=\(context.error.userMessageKey)
            code=\(context.error.code.rawValue)
            layer=\(context.error.layer.rawValue)
            severity=\(context.error.severity.rawValue)
            recoverable=\(context.error.isRecoverable)
            """
            let fileURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("DartsScoreboard-Migration-Diagnostics.txt")
            do {
                try text.write(to: fileURL, atomically: true, encoding: .utf8)
                state = .exportCompleted(fileURL.path)
            } catch {
                state = .ready
            }
        }
    }

    func tapResetLocalData() {
        Task {
            state = .resetInProgress
            let success = await resetHandler()
            state = success ? .resetCompleted : .ready
        }
    }
}

import Foundation

public struct MigrationRecoveryOptions: Sendable {
    public let canRetry: Bool
    public let canExportDiagnostics: Bool
    public let canResetData: Bool

    public init(
        canRetry: Bool = true,
        canExportDiagnostics: Bool = true,
        canResetData: Bool = true
    ) {
        self.canRetry = canRetry
        self.canExportDiagnostics = canExportDiagnostics
        self.canResetData = canResetData
    }
}

public struct MigrationRecoveryContext: Sendable {
    public let error: AppError
    public let options: MigrationRecoveryOptions

    public init(error: AppError, options: MigrationRecoveryOptions = MigrationRecoveryOptions()) {
        self.error = error
        self.options = options
    }
}

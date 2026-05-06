import Foundation

public enum ErrorLayer: String, Sendable {
    case domain
    case data
    case integration
    case system
}

public enum ErrorSeverity: String, Sendable {
    case info
    case warning
    case error
    case fault
}

public enum ErrorCode: String, Sendable {
    case validationFailed
    case invalidGameState
    case ruleViolation
    case unsupportedOperation
    case notFound
    case conflict
    case serializationFailed
    case migrationFailed
    case storageUnavailable
    case unknown
    case cancelled
}

public struct AppError: Error, Sendable {
    public let code: ErrorCode
    public let layer: ErrorLayer
    public let severity: ErrorSeverity
    public let isRecoverable: Bool
    public let userMessageKey: String
    public let debugContext: [String: String]
    public let underlyingError: Error?

    public init(
        code: ErrorCode,
        layer: ErrorLayer,
        severity: ErrorSeverity,
        isRecoverable: Bool,
        userMessageKey: String,
        debugContext: [String: String] = [:],
        underlyingError: Error? = nil
    ) {
        self.code = code
        self.layer = layer
        self.severity = severity
        self.isRecoverable = isRecoverable
        self.userMessageKey = userMessageKey
        self.debugContext = debugContext
        self.underlyingError = underlyingError
    }
}

public extension AppError {
    static func migrationFailure(_ error: Error) -> AppError {
        AppError(
            code: .migrationFailed,
            layer: .data,
            severity: .fault,
            isRecoverable: true,
            userMessageKey: "error.migration.failed",
            debugContext: [:],
            underlyingError: error
        )
    }
}

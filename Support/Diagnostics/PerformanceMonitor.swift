import Foundation

enum PerformanceOperation: String {
    case submitTurn
    case resumeMatch
    case completeMatch
    case historyLoad
}

enum PerformanceMonitor {
    @discardableResult
    static func measure<T>(
        _ operation: PerformanceOperation,
        logger: (any AppLogger)? = nil,
        metadata: [String: String] = [:],
        _ block: () throws -> T
    ) rethrows -> T {
        let start = ContinuousClock.now
        let result = try block()
        let elapsed = start.duration(to: .now)
        let millis = elapsed.components.seconds * 1000 + elapsed.components.attoseconds / 1_000_000_000_000_000
        var merged = metadata
        merged["operation"] = operation.rawValue
        merged["elapsedMs"] = String(millis)
        logger?.debug(.ui, eventName: "performance_metric", message: "Measured operation latency.", metadata: merged)
        return result
    }
}

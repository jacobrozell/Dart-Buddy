import Foundation

public protocol RedactionPolicy: Sendable {
    func redact(metadata: [String: String]) -> [String: String]
}

public struct DefaultRedactionPolicy: RedactionPolicy {
    private let allowedMetadataKeys: Set<String>
    private let sensitiveKeyFragments: [String]

    public init(
        allowedMetadataKeys: Set<String> = AnalyticsMetadataKeys.defaultRedactionAllowed,
        sensitiveKeyFragments: [String] = [
            "token",
            "secret",
            "password",
            "credential",
            "note",
            "payload"
        ]
    ) {
        self.allowedMetadataKeys = allowedMetadataKeys
        self.sensitiveKeyFragments = sensitiveKeyFragments
    }

    public func redact(metadata: [String: String]) -> [String: String] {
        metadata.reduce(into: [:]) { partialResult, pair in
            let lowercasedKey = pair.key.lowercased()
            guard allowedMetadataKeys.contains(pair.key) else {
                return
            }
            if sensitiveKeyFragments.contains(where: { lowercasedKey.contains($0) }) {
                partialResult[pair.key] = "[REDACTED]"
            } else {
                partialResult[pair.key] = pair.value
            }
        }
    }
}

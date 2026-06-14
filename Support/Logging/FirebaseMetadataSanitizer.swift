import Foundation

enum FirebaseMetadataSanitizer {
    static func sanitize(
        _ metadata: [String: String],
        allowedKeys: Set<String>,
        maxValueLength: Int = 100
    ) -> [String: String] {
        metadata.reduce(into: [:]) { result, pair in
            guard allowedKeys.contains(pair.key) else { return }
            guard !AnalyticsMetadataKeys.isBlockedPersonalDataKey(pair.key) else { return }
            let value = String(pair.value.prefix(maxValueLength))
            guard !value.isEmpty else { return }
            result[pair.key] = value
        }
    }
}

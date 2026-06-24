import Foundation

/// Applies `AppleLanguages` / `AppleLocale` from the UI-test launch environment before SwiftUI resolves strings.
enum UITestLocaleOverride {
    static func applyIfNeeded() {
        let environment = ProcessInfo.processInfo.environment
        guard let languagesRaw = environment["AppleLanguages"], !languagesRaw.isEmpty else { return }

        let codes = parseLanguageCodes(from: languagesRaw)
        guard !codes.isEmpty else { return }

        UserDefaults.standard.set(codes, forKey: "AppleLanguages")
        if let locale = environment["AppleLocale"], !locale.isEmpty {
            UserDefaults.standard.set(locale, forKey: "AppleLocale")
        }
    }

    private static func parseLanguageCodes(from raw: String) -> [String] {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasPrefix("("), trimmed.hasSuffix(")") {
            let inner = trimmed.dropFirst().dropLast()
            return inner
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
        }
        if trimmed.contains(",") {
            return trimmed
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
        }
        return [trimmed]
    }
}

import Foundation
import Testing
@testable import DartBuddy

@Suite("Localization parity", .tags(.unit, .localization, .regression))
struct LocalizationParityTests {
    // Matches `%%` (literal) plus the standard C/Foundation conversion forms,
    // including flag/width/precision runs such as `% d`, `%.1f`, and positional
    // `%1$@`. Capturing `%%` first prevents a literal percent from being mistaken
    // for a stray conversion specifier.
    private static let specifierPattern = #/%%|%(?:\d+\$)?[-+ 0#]*\d*(?:\.\d+)?(?:l{0,2}[diouxX]|[@fFgGeEcsp])/#

    @Test("Localized strings share the same keys as English", arguments: ["de", "es", "nl"])
    func localizedKeysMatchEnglish(locale: String) throws {
        let enKeys = try Self.keys(from: "en")
        let localeKeys = try Self.keys(from: locale)
        #expect(enKeys == localeKeys)
    }

    @Test("Format specifiers match per key between English and locale", arguments: ["de", "es", "nl"])
    func formatSpecifiersMatch(locale: String) throws {
        let en = try Self.entries(from: "en")
        let localized = try Self.entries(from: locale)
        for (key, enValue) in en {
            let localizedValue = try #require(localized[key])
            #expect(
                Self.specifiers(in: enValue) == Self.specifiers(in: localizedValue),
                "Specifier mismatch for \(key): en=\(enValue) \(locale)=\(localizedValue)"
            )
        }
    }

    private static func entries(from locale: String) throws -> [String: String] {
        let url = try stringsURL(for: locale)
        let text = try String(contentsOf: url, encoding: .utf8)
        return Dictionary(uniqueKeysWithValues: parseEntries(text))
    }

    private static func keys(from locale: String) throws -> Set<String> {
        Set(try entries(from: locale).keys)
    }

    private static func stringsURL(for locale: String) throws -> URL {
        let bundle = Bundle(for: BundleMarker.self)
        if let url = bundle.url(
            forResource: "Localizable",
            withExtension: "strings",
            subdirectory: "\(locale).lproj"
        ) {
            return url
        }
        // Fallback when running without copied resources (local file lookup).
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let path = root.appendingPathComponent("Resources/\(locale).lproj/Localizable.strings")
        guard FileManager.default.fileExists(atPath: path.path) else {
            throw LocalizationTestError.missingStrings(locale: locale)
        }
        return path
    }

    private static func parseEntries(_ text: String) -> [(String, String)] {
        let pattern = #/^"([^"]+)"\s*=\s*"(.*)";\s*$/#
        return text.split(separator: "\n", omittingEmptySubsequences: false).compactMap { line in
            let line = String(line)
            guard let match = line.firstMatch(of: pattern) else { return nil }
            return (String(match.1), String(match.2))
        }
    }

    private static func specifiers(in value: String) -> [String] {
        value.matches(of: specifierPattern).map { String(value[$0.range]) }
    }
}

private enum LocalizationTestError: Error {
    case missingStrings(locale: String)
}

private final class BundleMarker {}

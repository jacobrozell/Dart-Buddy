import Foundation
import Testing
@testable import DartBuddy

@Suite("Brand title", .tags(.unit, .localization, .regression))
struct BrandTitleTests {
    @Test("English brand title is Dart Buddy")
    func englishBrandTitle() {
        #expect(L10n.string("app.brandTitle") == "Dart Buddy")
    }

    @Test("Legacy scoreboard title key is removed", .tags(.regression))
    func legacyScoreboardTitleKeyRemoved() throws {
        let url = try LocalizationParityTestsSupport.englishStringsURL()
        let text = try String(contentsOf: url, encoding: .utf8)
        #expect(text.contains("\"play.home.appTitle\"") == false)
    }
}

/// Test-only access to localization file paths shared with parity tests.
enum LocalizationParityTestsSupport {
    static func englishStringsURL() throws -> URL {
        let bundle = Bundle(for: BundleMarker.self)
        if let url = bundle.url(
            forResource: "Localizable",
            withExtension: "strings",
            subdirectory: "en.lproj"
        ) {
            return url
        }
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let path = root.appendingPathComponent("Resources/en.lproj/Localizable.strings")
        guard FileManager.default.fileExists(atPath: path.path) else {
            throw BrandTitleTestError.missingEnglishStrings
        }
        return path
    }
}

private enum BrandTitleTestError: Error {
    case missingEnglishStrings
}

private final class BundleMarker {}

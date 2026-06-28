import Testing
@testable import DartBuddy

@Suite("App links", .tags(.unit))
struct AppLinksTests {
    @Test("Hosted pages use English path when German is not bundled")
    func hostedPagesEnglishWhenGermanNotBundled() {
        let url = AppLinks.hostedPage(
            named: "privacy.html",
            bundledLocaleCodes: ["en"],
            preferredLanguage: "de-DE"
        )
        #expect(url.absoluteString == "https://jacobrozell.github.io/Dart-Buddy/privacy.html")
    }

    @Test("Hosted pages use German path when bundled and preferred")
    func hostedPagesGermanWhenBundledAndPreferred() {
        let url = AppLinks.hostedPage(
            named: "privacy.html",
            bundledLocaleCodes: ["en", "de"],
            preferredLanguage: "de-DE"
        )
        #expect(url.absoluteString == "https://jacobrozell.github.io/Dart-Buddy/de/privacy.html")
    }

    @Test("Hosted pages fall back to English when German is bundled but not preferred")
    func hostedPagesEnglishWhenGermanNotPreferred() {
        let url = AppLinks.hostedPage(
            named: "support.html",
            bundledLocaleCodes: ["en", "de"],
            preferredLanguage: "en-US"
        )
        #expect(url.absoluteString == "https://jacobrozell.github.io/Dart-Buddy/support.html")
    }
}

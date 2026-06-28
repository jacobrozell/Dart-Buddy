import Foundation

// Verified literal URLs — the documented force-unwrap exception in CONTRIBUTING.md.
// swiftlint:disable force_unwrapping
enum AppLinks {
    /// App Store Connect app ID — used when iTunes lookup does not return `trackViewUrl`.
    static let appStoreAppID = "6775713346"
    static let appStore = URL(string: "https://apps.apple.com/app/id\(appStoreAppID)")!

    static let pagesBase = "https://jacobrozell.github.io/Dart-Buddy"

    static var support: URL { hostedPage(named: "support.html") }
    static var privacy: URL { hostedPage(named: "privacy.html") }
    static var accessibility: URL { hostedPage(named: "accessibility.html") }
    static let appStoreReview = URL(string: "https://apps.apple.com/app/id\(appStoreAppID)?action=write-review")!

    /// Set when your tip page is live (Buy Me a Coffee, Ko-fi, etc.). Leave nil to hide the Settings link.
    static let buyDeveloperCoffee: URL? = URL(string: "https://buymeacoffee.com/jacobrozelq")

    /// GitHub Pages URL for legal/support content, localized when the user's language is bundled (e.g. `de` in 1.2).
    static func hostedPage(
        named page: String,
        bundledLocaleCodes: [String] = ProductSurface.bundledLocaleCodes,
        preferredLanguage: String? = Locale.preferredLanguages.first
    ) -> URL {
        let prefix = hostedPagesLanguagePrefix(
            bundledLocaleCodes: bundledLocaleCodes,
            preferredLanguage: preferredLanguage
        )
        let path = prefix.isEmpty
            ? "\(pagesBase)/\(page)"
            : "\(pagesBase)/\(prefix)/\(page)"
        return URL(string: path)!
    }

    static func hostedPagesLanguagePrefix(
        bundledLocaleCodes: [String],
        preferredLanguage: String?
    ) -> String {
        guard bundledLocaleCodes.contains("de"),
              let preferredLanguage else { return "" }
        let code = Locale(identifier: preferredLanguage).language.languageCode?.identifier ?? ""
        return code == "de" ? "de" : ""
    }
}
// swiftlint:enable force_unwrapping

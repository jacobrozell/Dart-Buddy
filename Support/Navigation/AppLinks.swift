import Foundation

// Verified literal URLs — the documented force-unwrap exception in CONTRIBUTING.md.
// swiftlint:disable force_unwrapping
enum AppLinks {
    /// App Store Connect app ID — used when iTunes lookup does not return `trackViewUrl`.
    static let appStoreAppID = "6775713346"
    static let appStore = URL(string: "https://apps.apple.com/app/id\(appStoreAppID)")!

    static let support = URL(string: "https://jacobrozell.github.io/Dart-Buddy/support.html")!
    static let privacy = URL(string: "https://jacobrozell.github.io/Dart-Buddy/privacy.html")!
    static let accessibility = URL(string: "https://jacobrozell.github.io/Dart-Buddy/accessibility.html")!
    static let appStoreReview = URL(string: "https://apps.apple.com/app/id\(appStoreAppID)?action=write-review")!

    /// Set when your tip page is live (Buy Me a Coffee, Ko-fi, etc.). Leave nil to hide the Settings link.
    static let buyDeveloperCoffee: URL? = URL(string: "https://buymeacoffee.com/jacobrozelq")
}
// swiftlint:enable force_unwrapping

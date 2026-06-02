import Foundation

enum AppLinks {
    static let support = URL(string: "https://jacobrozell.github.io/Dart-Buddy/support.html")!
    static let privacy = URL(string: "https://jacobrozell.github.io/Dart-Buddy/privacy.html")!

    /// Set when your tip page is live (Buy Me a Coffee, Ko-fi, etc.). Leave nil to hide the Settings link.
    static let buyDeveloperCoffee: URL? = URL(string: "https://buymeacoffee.com/jacobrozelq")
}

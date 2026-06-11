import Foundation

enum AppSupport {
    static let feedbackEmail = "jacob.rozell83@gmail.com"

    static var installedVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
    }

    static var versionLabel: String {
        L10n.format("settings.about.versionFormat", installedVersion)
    }

    static var feedbackMailtoURL: URL {
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = feedbackEmail
        components.queryItems = [
            URLQueryItem(name: "subject", value: "Dart Buddy Feedback"),
            URLQueryItem(
                name: "body",
                value: """
                App version: \(installedVersion)

                """
            )
        ]
        return components.url ?? URL(string: "mailto:\(feedbackEmail)")!
    }
}

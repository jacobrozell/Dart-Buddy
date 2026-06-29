import Foundation
#if canImport(UIKit)
import UIKit
#endif
#if canImport(MessageUI)
import MessageUI
#endif

enum AppSupport {
    static let feedbackEmail = "jacob.rozell83@gmail.com"

    static var installedVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
    }

    static var installedBuild: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
    }

    static var versionLabel: String {
        L10n.format("settings.about.versionFormat", installedVersion)
    }

    static var canSendMail: Bool {
        #if canImport(MessageUI)
        MFMailComposeViewController.canSendMail()
        #else
        false
        #endif
    }

    static var feedbackMailtoURL: URL {
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = feedbackEmail
        components.queryItems = [
            URLQueryItem(
                name: "subject",
                value: L10n.string("settings.support.feedbackEmailSubject")
            ),
            URLQueryItem(
                name: "body",
                value: L10n.format("settings.support.feedbackEmailBodyFormat", installedVersion)
            )
        ]
        // Fallback built from a verified literal constant.
        // swiftlint:disable:next force_unwrapping
        return components.url ?? URL(string: "mailto:\(feedbackEmail)")!
    }

    static func mailSubject(for draft: FeedbackDraft) -> String {
        let item = draft.specificItem.trimmingCharacters(in: .whitespacesAndNewlines)
        if item.isEmpty {
            return "[Dart Buddy] \(draft.category.subjectTag) — \(draft.trimmedSummary)"
        }
        return "[Dart Buddy] \(draft.category.subjectTag) — \(item)"
    }

    static func mailBody(for draft: FeedbackDraft) -> String {
        let item = draft.specificItem.trimmingCharacters(in: .whitespacesAndNewlines)
        let details = draft.details.trimmingCharacters(in: .whitespacesAndNewlines)

        var lines: [String] = [
            "Most wanted upcoming feature: \(draft.mostWantedFeature.mailLabel)",
            "Category: \(draft.category.label)",
        ]
        if !item.isEmpty {
            lines.append("\(draft.category.specificItemLabel): \(item)")
        }
        lines.append("Summary: \(draft.trimmedSummary)")
        lines.append("")
        lines.append("Details:")
        lines.append(details.isEmpty ? "(none provided)" : details)
        lines.append("")
        lines.append("---")
        lines.append(deviceDiagnostics)
        return lines.joined(separator: "\n")
    }

    static var deviceDiagnostics: String {
        #if canImport(UIKit)
        let device = UIDevice.current
        return """
        App: Dart Buddy \(installedVersion) (\(installedBuild))
        Device: \(device.model)
        iOS: \(device.systemVersion)
        """
        #else
        return "App: Dart Buddy \(installedVersion) (\(installedBuild))"
        #endif
    }

    static func mailtoURL(for draft: FeedbackDraft) -> URL {
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = feedbackEmail
        components.queryItems = [
            URLQueryItem(name: "subject", value: mailSubject(for: draft)),
            URLQueryItem(name: "body", value: mailBody(for: draft)),
        ]
        // Fallback built from a verified literal constant.
        // swiftlint:disable:next force_unwrapping
        return components.url ?? URL(string: "mailto:\(feedbackEmail)")!
    }
}

import Foundation
import Testing
@testable import DartBuddy

@Suite("App support", .tags(.unit, .settings, .regression))
struct AppSupportTests {
    @Test
    func feedbackEmailIsConfigured() {
        #expect(AppSupport.feedbackEmail.contains("@"))
    }

    @Test
    func installedVersionFallsBackWhenMissing() {
        #expect(!AppSupport.installedVersion.isEmpty)
    }

    @Test
    func versionLabelIncludesInstalledVersion() {
        #expect(AppSupport.versionLabel.contains(AppSupport.installedVersion))
    }

    @Test
    func feedbackMailtoURLUsesConfiguredRecipient() throws {
        let url = AppSupport.feedbackMailtoURL
        #expect(url.scheme == "mailto")
        #expect(url.absoluteString.contains(AppSupport.feedbackEmail))

        let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))
        let subject = components.queryItems?.first(where: { $0.name == "subject" })?.value
        let body = components.queryItems?.first(where: { $0.name == "body" })?.value
        #expect(subject == L10n.string("settings.support.feedbackEmailSubject"))
        #expect(body?.contains(AppSupport.installedVersion) == true)
    }
}

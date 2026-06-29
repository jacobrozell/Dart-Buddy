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

    @Test
    func mailSubjectIncludesCategoryTag() {
        let draft = FeedbackDraft(
            mostWantedFeature: .moreCoopGameModes,
            category: .gameMode,
            specificItem: "Halve It",
            summary: "Add to catalog",
            details: ""
        )
        let subject = AppSupport.mailSubject(for: draft)
        #expect(subject.contains("[Dart Buddy]"))
        #expect(subject.contains("Game mode"))
        #expect(subject.contains("Halve It"))
    }

    @Test
    func mailSubjectFallsBackToTrimmedSummaryWhenItemBlank() {
        let draft = FeedbackDraft(
            mostWantedFeature: .notSure,
            category: .improvement,
            specificItem: "   ",
            summary: "  Faster Play setup  ",
            details: ""
        )

        #expect(AppSupport.mailSubject(for: draft) == "[Dart Buddy] Improvement — Faster Play setup")
    }

    @Test
    func mailBodyIncludesMostWantedFeatureSummaryAndDiagnostics() {
        let draft = FeedbackDraft(
            mostWantedFeature: .autoScoring,
            category: .scoringRules,
            specificItem: "501 double-out",
            summary: "Fix bust on double miss",
            details: "Happens after checkout suggestion"
        )
        let body = AppSupport.mailBody(for: draft)
        #expect(body.contains("Most wanted upcoming feature: Camera auto-scoring"))
        #expect(body.contains("Summary: Fix bust on double miss"))
        #expect(body.contains("Scoring or checkout rules"))
        #expect(body.contains("App: Dart Buddy"))
    }

    @Test
    func mailtoURLForDraftUsesConfiguredRecipient() throws {
        let draft = FeedbackDraft(
            mostWantedFeature: .notSure,
            category: .bug,
            specificItem: "X01 match",
            summary: "Score stuck",
            details: ""
        )
        let url = AppSupport.mailtoURL(for: draft)
        #expect(url.scheme == "mailto")
        #expect(url.absoluteString.contains(AppSupport.feedbackEmail))

        let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))
        let subject = components.queryItems?.first(where: { $0.name == "subject" })?.value
        #expect(subject?.contains("Bug") == true)
    }

    @Test
    func invalidDraftWhenSummaryEmpty() {
        let draft = FeedbackDraft(
            mostWantedFeature: .notSure,
            category: .other,
            specificItem: "",
            summary: "   ",
            details: ""
        )
        #expect(!draft.isValid)
    }

    @Test
    func validDraftTrimsSummaryWhitespace() {
        let draft = FeedbackDraft(
            mostWantedFeature: .morePracticeGameModes,
            category: .other,
            specificItem: "",
            summary: "  Useful idea  ",
            details: ""
        )
        #expect(draft.isValid)
        #expect(draft.trimmedSummary == "Useful idea")
    }
}

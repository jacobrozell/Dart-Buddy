import Testing
@testable import DartBuddy

@Suite("Onboarding copy", .tags(.unit, .regression))
struct OnboardingCopyTests {
    @Test("Welcome copy avoids marketing version in English title")
    func welcomeTitleIsVersionAgnostic() {
        let hero = OnboardingCopy.hero
        #expect(hero.welcomeTitleKey == "onboarding.welcome.title")
        let title = L10n.string(hero.welcomeTitleKey)
        #expect(!title.localizedCaseInsensitiveContains("1.0"))
        #expect(!title.localizedCaseInsensitiveContains("1.1"))
    }

    @Test("Support body avoids marketing version in English copy")
    func supportBodyIsVersionAgnostic() {
        let body = L10n.string(OnboardingCopy.hero.supportBodyKey)
        #expect(!body.localizedCaseInsensitiveContains("1.0"))
        #expect(!body.localizedCaseInsensitiveContains("1.1"))
    }
}

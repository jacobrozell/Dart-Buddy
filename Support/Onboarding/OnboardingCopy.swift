import Foundation

/// First-launch onboarding hero copy slices.
///
/// **How to iterate:** Add or edit a `HeroSlice` and return it from `hero(arguments:)` for the
/// current release (same pattern as `ReleaseHighlights`). Update matching keys in
/// `Resources/en.lproj/Localizable.strings` and `Scripts/locale_data/*.json`, then run
/// `python3 Scripts/generate_localizable.py de` (etc.) for bundled locales.
enum OnboardingCopy {
    struct HeroSlice: Sendable, Equatable {
        let welcomeTitleKey: String
        let welcomeBodyKey: String
        let supportBodyKey: String
    }

    /// Version-agnostic welcome — no marketing version in the title.
    static let `default` = HeroSlice(
        welcomeTitleKey: "onboarding.welcome.title",
        welcomeBodyKey: "onboarding.welcome.body",
        supportBodyKey: "onboarding.support.body"
    )

    static var hero: HeroSlice {
        hero(arguments: ProcessInfo.processInfo.arguments)
    }

    static func hero(arguments: [String]) -> HeroSlice {
        // Return a release-specific slice here when welcome copy changes (e.g. partyPack1_1).
        `default`
    }
}

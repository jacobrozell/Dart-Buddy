import XCTest

/// Smoke tests with Spanish locale; functional UI tests keep English via default launch.
/// Lean 1.0 bundles English only — see `project.yml` and skip until 1.2+ locale restore.
final class SpanishLocalizationSmokeUITests: DartBuddyUITestCase {
    private var leanLocalesUnavailable: String {
        "Lean 1.0 bundles English resources only; restore de/es/nl in project.yml for 1.2+."
    }

    func testLeanTabBarUsesSpanishLabels() throws {
        throw XCTSkip(leanLocalesUnavailable)
    }

    func testFullSurfaceTabBarUsesSpanishLabels() throws {
        throw XCTSkip(leanLocalesUnavailable)
    }

    func testPlaySetupUsesSpanishChrome() throws {
        throw XCTSkip(leanLocalesUnavailable)
    }

    func testSettingsUsesSpanishSectionLabels() throws {
        throw XCTSkip(leanLocalesUnavailable)
    }
}

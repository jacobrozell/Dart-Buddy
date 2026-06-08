import XCTest

/// Smoke tests with German locale; functional UI tests keep English via default launch.
/// Lean 1.0 bundles English only — see `project.yml` and skip until 1.2+ locale restore.
final class GermanLocalizationSmokeUITests: DartBuddyUITestCase {
    private var leanLocalesUnavailable: String {
        "Lean 1.0 bundles English resources only; restore de/es/nl in project.yml for 1.2+."
    }

    func testLeanTabBarUsesGermanLabels() throws {
        throw XCTSkip(leanLocalesUnavailable)
    }

    func testFullSurfaceTabBarUsesGermanLabels() throws {
        throw XCTSkip(leanLocalesUnavailable)
    }

    func testPlaySetupUsesGermanChrome() throws {
        throw XCTSkip(leanLocalesUnavailable)
    }

    func testSettingsUsesGermanSectionLabels() throws {
        throw XCTSkip(leanLocalesUnavailable)
    }
}

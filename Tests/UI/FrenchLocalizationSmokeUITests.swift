import XCTest

/// Smoke tests with French locale; functional UI tests keep English via default launch.
/// Lean 1.0 bundles English only — see `project.yml` and skip until 1.2+ locale restore.
final class FrenchLocalizationSmokeUITests: DartBuddyUITestCase {
    private var leanLocalesUnavailable: String {
        "Lean 1.0 bundles English resources only; restore de/es/nl/fr in project.yml for 1.2+."
    }

    func testLeanTabBarUsesFrenchLabels() throws {
        throw XCTSkip(leanLocalesUnavailable)
    }

    func testFullSurfaceTabBarUsesFrenchLabels() throws {
        throw XCTSkip(leanLocalesUnavailable)
    }

    func testPlaySetupUsesFrenchChrome() throws {
        throw XCTSkip(leanLocalesUnavailable)
    }

    func testSettingsUsesFrenchSectionLabels() throws {
        throw XCTSkip(leanLocalesUnavailable)
    }
}

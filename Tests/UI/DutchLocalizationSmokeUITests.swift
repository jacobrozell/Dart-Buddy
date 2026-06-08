import XCTest

/// Smoke tests with Dutch locale; functional UI tests keep English via default launch.
/// Lean 1.0 bundles English only — see `project.yml` and skip until 1.2+ locale restore.
final class DutchLocalizationSmokeUITests: DartBuddyUITestCase {
    private var leanLocalesUnavailable: String {
        "Lean 1.0 bundles English resources only; restore de/es/nl in project.yml for 1.2+."
    }

    func testLeanTabBarUsesDutchLabels() throws {
        throw XCTSkip(leanLocalesUnavailable)
    }

    func testFullSurfaceTabBarUsesDutchLabels() throws {
        throw XCTSkip(leanLocalesUnavailable)
    }

    func testPlaySetupUsesDutchChrome() throws {
        throw XCTSkip(leanLocalesUnavailable)
    }

    func testSettingsUsesDutchSectionLabels() throws {
        throw XCTSkip(leanLocalesUnavailable)
    }
}

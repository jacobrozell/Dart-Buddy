import XCTest

/// Smoke tests with Simplified Chinese locale; functional UI tests keep English via default launch.
/// Lean 1.0 bundles English only — see `project.yml` and skip until 1.2+ locale restore.
final class ChineseLocalizationSmokeUITests: DartBuddyUITestCase {
    private var leanLocalesUnavailable: String {
        "Lean 1.0 bundles English resources only; restore de/es/nl/zh-Hans in project.yml for 1.2+."
    }

    func testLeanTabBarUsesChineseLabels() throws {
        throw XCTSkip(leanLocalesUnavailable)
    }

    func testFullSurfaceTabBarUsesChineseLabels() throws {
        throw XCTSkip(leanLocalesUnavailable)
    }

    func testPlaySetupUsesChineseChrome() throws {
        throw XCTSkip(leanLocalesUnavailable)
    }

    func testSettingsUsesChineseSectionLabels() throws {
        throw XCTSkip(leanLocalesUnavailable)
    }
}

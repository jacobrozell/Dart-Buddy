import Testing
@testable import DartsScoreboard

extension Tag {
    @Tag static var unit: Self
    @Tag static var integration: Self
    @Tag static var migration: Self

    @Tag static var swiftdata: Self
    @Tag static var logging: Self
    @Tag static var performance: Self
    @Tag static var security: Self

    @Tag static var player: Self
    @Tag static var match: Self
    @Tag static var x01: Self
    @Tag static var cricket: Self
    @Tag static var history: Self
    @Tag static var settings: Self
    @Tag static var stats: Self
    @Tag static var scoringInput: Self
    @Tag static var navigation: Self
    @Tag static var setupFlow: Self

    @Tag static var accessibility: Self
    @Tag static var localization: Self
    @Tag static var offline: Self

    @Tag static var smoke: Self
    @Tag static var regression: Self
    @Tag static var critical: Self
}

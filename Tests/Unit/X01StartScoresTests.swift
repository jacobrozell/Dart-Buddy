import Testing
@testable import DartBuddy

@Suite("X01 start scores", .tags(.unit, .setupFlow, .x01, .regression))
struct X01StartScoresTests {
    @Test
    func supportedStartScoresAreAscending() {
        #expect(X01StartScores.all == [101, 201, 301, 401, 501, 601])
    }

    @Test
    func defaultSetupStartScoreIsSupported() {
        #expect(X01StartScores.all.contains(501))
    }
}

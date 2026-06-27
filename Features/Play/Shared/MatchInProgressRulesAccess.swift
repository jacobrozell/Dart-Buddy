import SwiftUI

private struct PresentMatchRulesKey: EnvironmentKey {
    static let defaultValue: (() -> Void)? = nil
}

extension EnvironmentValues {
    /// When set, match chrome can present the in-progress rules sheet for the active mode.
    var presentMatchRules: (() -> Void)? {
        get { self[PresentMatchRulesKey.self] }
        set { self[PresentMatchRulesKey.self] = newValue }
    }
}

/// Presents the mode rules sheet during an active match and exposes a header action via environment.
struct MatchInProgressRulesAccess<Content: View>: View {
    let matchType: MatchType
    @ViewBuilder var content: () -> Content
    @State private var showRules = false

    var body: some View {
        content()
            .environment(
                \.presentMatchRules,
                GameRulesCatalog.hasGuide(for: matchType) ? { showRules = true } : nil
            )
            .sheet(isPresented: $showRules) {
                GameRulesGuideView(initialMode: matchType)
            }
    }
}

extension PlayRoute {
    /// Match type for in-progress gameplay routes that expose a rules guide.
    var inProgressRulesMatchType: MatchType? {
        switch self {
        case .setup, .matchSummary, .historyDetail:
            return nil
        case .x01Match:
            return .x01
        case .cricketMatch:
            return .cricket
        case .baseballMatch:
            return .baseball
        case .killerMatch:
            return .killer
        case .shanghaiMatch:
            return .shanghai
        case .americanCricketMatch:
            return .americanCricket
        case .mickeyMouseMatch:
            return .mickeyMouse
        case .mulliganMatch:
            return .mulligan
        case .englishCricketMatch:
            return .englishCricket
        case .blindKillerMatch:
            return .blindKiller
        case .knockoutMatch:
            return .knockout
        case .suddenDeathMatch:
            return .suddenDeath
        case .fiftyOneByFivesMatch:
            return .fiftyOneByFives
        case .golfMatch:
            return .golf
        case .footballMatch:
            return .football
        case .grandNationalMatch:
            return .grandNational
        case .hareAndHoundsMatch:
            return .hareAndHounds
        case .followTheLeaderMatch:
            return .followTheLeader
        case .loopMatch:
            return .loop
        case .prisonerMatch:
            return .prisoner
        case .scamMatch:
            return .scam
        case .snookerMatch:
            return .snooker
        case .ticTacToeMatch:
            return .ticTacToe
        case .aroundTheClockMatch:
            return .aroundTheClock
        case .aroundTheClock180Match:
            return .aroundTheClock180
        case .chaseTheDragonMatch:
            return .chaseTheDragon
        case .nineLivesMatch:
            return .nineLives
        case .fleetMatch:
            return .fleet
        case .raidMatch:
            return .raid
        case .bobs27Match:
            return .bobs27
        case .halveItMatch:
            return .halveIt
        }
    }
}

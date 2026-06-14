import SwiftUI

private struct MatchLayoutPlayerCountKey: EnvironmentKey {
    /// Assume a sparse match so pads default to stacked layout outside `MatchScoringBody`.
    static let defaultValue = 2
}

extension EnvironmentValues {
    /// Player count for the active match; drives sidebar vs stacked scoring layout.
    var matchLayoutPlayerCount: Int {
        get { self[MatchLayoutPlayerCountKey.self] }
        set { self[MatchLayoutPlayerCountKey.self] = newValue }
    }
}

/// Routes match gameplay to the standard or accessibility scoring shell.
struct MatchScoringBody<Active: View, Scoreboard: View, PadChrome: View, Pad: View>: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var playerCount: Int
    var showsActiveBand: Bool = true
    var scoreboardSharesBottomRow: Bool = true
    var scoreboardFillsRemainingHeight: Bool = true
    @ViewBuilder var active: () -> Active
    @ViewBuilder var scoreboard: () -> Scoreboard
    @ViewBuilder var padChrome: () -> PadChrome
    @ViewBuilder var pad: () -> Pad

    var body: some View {
        Group {
            if GameplayLayout.usesAccessibilityMatchScoringLayout(dynamicTypeSize: dynamicTypeSize) {
                AccessibilityMatchScoringBody(
                    playerCount: playerCount,
                    showsActiveBand: showsActiveBand,
                    scoreboardSharesBottomRow: scoreboardSharesBottomRow,
                    scoreboardFillsRemainingHeight: scoreboardFillsRemainingHeight,
                    active: active,
                    scoreboard: scoreboard,
                    padChrome: padChrome,
                    pad: pad
                )
            } else {
                StandardMatchScoringBody(
                    playerCount: playerCount,
                    showsActiveBand: showsActiveBand,
                    scoreboardSharesBottomRow: scoreboardSharesBottomRow,
                    scoreboardFillsRemainingHeight: scoreboardFillsRemainingHeight,
                    active: active,
                    scoreboard: scoreboard,
                    padChrome: padChrome,
                    pad: pad
                )
            }
        }
        .environment(\.matchLayoutPlayerCount, playerCount)
    }
}

extension MatchScoringBody where Active == EmptyView {
    init(
        playerCount: Int,
        scoreboard: @escaping () -> Scoreboard,
        padChrome: @escaping () -> PadChrome,
        pad: @escaping () -> Pad
    ) {
        self.playerCount = playerCount
        self.showsActiveBand = false
        self.active = { EmptyView() }
        self.scoreboard = scoreboard
        self.padChrome = padChrome
        self.pad = pad
    }
}

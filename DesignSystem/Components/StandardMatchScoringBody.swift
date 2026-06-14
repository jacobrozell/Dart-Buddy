import SwiftUI

/// Default match scoring shell: active band on top, scoreboard above a bottom-docked pad.
struct StandardMatchScoringBody<Active: View, Scoreboard: View, PadChrome: View, Pad: View>: View {
    var playerCount: Int
    var showsActiveBand: Bool = true
    var scoreboardSharesBottomRow: Bool = true
    var scoreboardFillsRemainingHeight: Bool = true
    @ViewBuilder var active: () -> Active
    @ViewBuilder var scoreboard: () -> Scoreboard
    @ViewBuilder var padChrome: () -> PadChrome
    @ViewBuilder var pad: () -> Pad

    var body: some View {
        VStack(spacing: DS.Spacing.s2) {
            if showsActiveBand {
                active()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            bottomRegion
                .frame(maxHeight: .infinity)
        }
        .padding(.horizontal, DS.Spacing.s4)
        .padding(.bottom, DS.Spacing.s2)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var bottomRegion: some View {
        VStack(spacing: DS.Spacing.s2) {
            if scoreboardSharesBottomRow {
                scoreboardScroll
            }
            padChrome()
                .frame(maxWidth: .infinity)
            if !scoreboardFillsRemainingHeight {
                Spacer(minLength: 0)
            }
            pad()
                .frame(maxWidth: .infinity, alignment: .top)
        }
    }

    @ViewBuilder
    private var scoreboardScroll: some View {
        let scroll = ScrollView {
            scoreboard()
                .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .scrollIndicators(.hidden)

        if scoreboardFillsRemainingHeight {
            scroll.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        } else {
            scroll.frame(maxWidth: .infinity, alignment: .topLeading)
        }
    }
}

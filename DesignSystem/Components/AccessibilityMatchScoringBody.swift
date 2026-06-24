import SwiftUI

/// Score-first match shell at accessibility text sizes (AX1–AX5) on iPhone and iPad.
/// Active score stays pinned above the pad; opponents scroll between score and pad.
struct AccessibilityMatchScoringBody<Active: View, Scoreboard: View, PadChrome: View, Pad: View>: View {
    var playerCount: Int
    var showsActiveBand: Bool = true
    var scoreboardSharesBottomRow: Bool = true
    var scoreboardFillsRemainingHeight: Bool = true
    @ViewBuilder var active: () -> Active
    @ViewBuilder var scoreboard: () -> Scoreboard
    @ViewBuilder var padChrome: () -> PadChrome
    @ViewBuilder var pad: () -> Pad

    private var scrollsInactiveScoreboard: Bool {
        showsActiveBand && scoreboardSharesBottomRow
    }

    var body: some View {
        VStack(spacing: DS.Spacing.s2) {
            if showsActiveBand {
                active()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            if scrollsInactiveScoreboard {
                ScrollView {
                    scoreboard()
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                }
                .scrollIndicators(.hidden)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            } else if !showsActiveBand {
                ScrollView {
                    scoreboard()
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                }
                .scrollIndicators(.hidden)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            } else {
                Spacer(minLength: 0)
            }

            VStack(spacing: DS.Spacing.s2) {
                padChrome()
                    .frame(maxWidth: .infinity)
                pad()
                    .frame(maxWidth: .infinity, alignment: .top)
            }
        }
        .padding(.horizontal, DS.Spacing.s4)
        .padding(.bottom, DS.Spacing.s2)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

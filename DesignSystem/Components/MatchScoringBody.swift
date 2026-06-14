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

/// Match gameplay layout: active player/board full width, inactive scoreboard scrolls beside a
/// bottom-docked pad column (checkout and feedback banners sit directly above the pad).
struct MatchScoringBody<Active: View, Scoreboard: View, PadChrome: View, Pad: View>: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var playerCount: Int
    var showsActiveBand: Bool = true
    /// When false, the pad and chrome span the full width under the active band (solo matches).
    var scoreboardSharesBottomRow: Bool = true
    /// When false, the inactive scoreboard only grows to fit its content; checkout stays adjacent and the pad docks to the bottom.
    var scoreboardFillsRemainingHeight: Bool = true
    @ViewBuilder var active: () -> Active
    @ViewBuilder var scoreboard: () -> Scoreboard
    @ViewBuilder var padChrome: () -> PadChrome
    @ViewBuilder var pad: () -> Pad

    var body: some View {
        Group {
            if GameplayLayout.usesAccessibilityMatchScoringLayout(dynamicTypeSize: dynamicTypeSize) {
                accessibilityBody
            } else {
                standardBody
            }
        }
        .environment(\.matchLayoutPlayerCount, playerCount)
    }

    private var accessibilityBody: some View {
        ScrollView {
            VStack(spacing: DS.Spacing.s2) {
                if showsActiveBand {
                    active()
                }
                padChrome()
                pad()
                scoreboard()
            }
            .padding(.horizontal, DS.Spacing.s4)
            .padding(.bottom, DS.Spacing.s2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var standardBody: some View {
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

    @ViewBuilder
    private var bottomRegion: some View {
        if usesFullWidthPadColumn {
            VStack(spacing: DS.Spacing.s2) {
                if scoreboardSharesBottomRow {
                    scoreboardScroll
                }
                padChrome()
                if !scoreboardFillsRemainingHeight {
                    Spacer(minLength: 0)
                }
                pad()
            }
        } else {
            GeometryReader { geometry in
                HStack(alignment: .top, spacing: DS.Spacing.s3) {
                    ScrollView {
                        scoreboard()
                            .frame(
                                maxWidth: .infinity,
                                minHeight: geometry.size.height,
                                alignment: .topLeading
                            )
                    }
                    .scrollIndicators(.hidden)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

                    VStack(spacing: DS.Spacing.s2) {
                        Spacer(minLength: 0)
                        padChrome()
                        pad()
                    }
                    .frame(width: padColumnWidth)
                    .frame(maxHeight: .infinity, alignment: .top)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
            .frame(maxHeight: .infinity)
        }
    }

    /// Full-width pad below the scoreboard — iPhone and solo matches. iPad keeps a sidebar pad.
    private var usesFullWidthPadColumn: Bool {
        guard scoreboardSharesBottomRow else { return true }
        return !GameplayLayout.usesSideBySideBottomScoringRegion(
            horizontalSizeClass: horizontalSizeClass,
            verticalSizeClass: verticalSizeClass,
            playerCount: playerCount
        )
    }

    private var padColumnWidth: CGFloat {
        GameplayLayout.bottomScoringPadColumnWidth(
            horizontalSizeClass: horizontalSizeClass,
            verticalSizeClass: verticalSizeClass
        )
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

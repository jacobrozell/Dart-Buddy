import SwiftUI

/// Match gameplay layout: active player/board full width, inactive scoreboard scrolls beside a
/// bottom-docked pad column (checkout and feedback banners sit directly above the pad).
struct MatchScoringBody<Active: View, Scoreboard: View, PadChrome: View, Pad: View>: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var showsActiveBand: Bool = true
    /// When false, the pad and chrome span the full width under the active band (solo matches).
    var scoreboardSharesBottomRow: Bool = true
    @ViewBuilder var active: () -> Active
    @ViewBuilder var scoreboard: () -> Scoreboard
    @ViewBuilder var padChrome: () -> PadChrome
    @ViewBuilder var pad: () -> Pad

    var body: some View {
        if GameplayLayout.usesAccessibilityMatchScoringLayout(dynamicTypeSize: dynamicTypeSize) {
            accessibilityBody
        } else {
            standardBody
        }
    }

    private var accessibilityBody: some View {
        ScrollView {
            VStack(spacing: DS.Spacing.s2) {
                if showsActiveBand {
                    active()
                }
                scoreboard()
                padChrome()
                pad()
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
                    ScrollView {
                        scoreboard()
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                    }
                    .scrollIndicators(.hidden)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                }
                padChrome()
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
            verticalSizeClass: verticalSizeClass
        )
    }

    private var padColumnWidth: CGFloat {
        GameplayLayout.bottomScoringPadColumnWidth(
            horizontalSizeClass: horizontalSizeClass,
            verticalSizeClass: verticalSizeClass
        )
    }
}

extension MatchScoringBody where Active == EmptyView {
    init(
        scoreboard: @escaping () -> Scoreboard,
        padChrome: @escaping () -> PadChrome,
        pad: @escaping () -> Pad
    ) {
        self.showsActiveBand = false
        self.active = { EmptyView() }
        self.scoreboard = scoreboard
        self.padChrome = padChrome
        self.pad = pad
    }
}

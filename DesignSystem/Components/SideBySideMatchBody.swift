import SwiftUI

/// Scoreboard (scroll) beside pad + actions on iPad portrait and iPhone landscape.
struct SideBySideMatchBody<Board: View, Controls: View>: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @ViewBuilder var board: () -> Board
    @ViewBuilder var controls: () -> Controls

    var body: some View {
        Group {
            if usesSideBySide {
                if usesPhoneLandscapeLayout {
                    phoneLandscapeBody
                } else {
                    tabletSideBySideBody
                }
            } else {
                portraitPhoneBody
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var portraitPhoneBody: some View {
        VStack(spacing: 0) {
            ScrollView {
                board()
                    .padding(.bottom, DS.Spacing.s2)
            }
            controls()
        }
        .padding(.horizontal, DS.Spacing.s4)
        .safeAreaPadding(.bottom, DS.Spacing.s4)
    }

    private var phoneLandscapeBody: some View {
        GeometryReader { proxy in
            HStack(alignment: .center, spacing: DS.Spacing.s4) {
                ScrollView {
                    board()
                        .frame(minHeight: proxy.size.height, alignment: .center)
                        .frame(maxWidth: .infinity)
                }
                .scrollIndicators(.hidden)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                VStack {
                    Spacer(minLength: 0)
                    controls()
                    Spacer(minLength: 0)
                }
                .frame(width: GameplayLayout.regularWidthScoringPadWidth)
                .frame(maxHeight: .infinity)
            }
            .padding(.horizontal, DS.Spacing.s4)
            .padding(.vertical, DS.Spacing.s2)
        }
    }

    private var tabletSideBySideBody: some View {
        HStack(alignment: .top, spacing: DS.Spacing.s2) {
            ScrollView {
                board()
            }
            .scrollIndicators(.hidden)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

            VStack(spacing: DS.Spacing.s2) {
                controls()
            }
            .frame(
                width: GameplayLayout.scoringPadFixedWidth(
                    horizontalSizeClass: horizontalSizeClass,
                    verticalSizeClass: verticalSizeClass
                ),
                alignment: .top
            )
        }
        .padding(.horizontal, DS.Spacing.s4)
        .padding(.bottom, DS.Spacing.s2)
    }

    private var usesSideBySide: Bool {
        GameplayLayout.usesSideBySideMatchScoringLayout(
            horizontalSizeClass: horizontalSizeClass,
            verticalSizeClass: verticalSizeClass
        )
    }

    private var usesPhoneLandscapeLayout: Bool {
        GameplayLayout.usesLandscapeMatchScoringLayout(verticalSizeClass: verticalSizeClass)
            && horizontalSizeClass == .compact
    }
}

extension View {
    /// Centers content in the readable iPad column used by list-style root screens.
    func readableRootContentWidth(_ horizontalSizeClass: UserInterfaceSizeClass?) -> some View {
        frame(maxWidth: GameplayLayout.contentMaxWidth(horizontalSizeClass: horizontalSizeClass))
            .frame(maxWidth: .infinity)
    }
}

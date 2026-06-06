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
            } else {
                VStack(spacing: 0) {
                    ScrollView {
                        board()
                            .padding(.bottom, DS.Spacing.s2)
                    }
                    controls()
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.horizontal, DS.Spacing.s4)
        .padding(.bottom, DS.Spacing.s2)
    }

    private var usesSideBySide: Bool {
        GameplayLayout.usesSideBySideMatchScoringLayout(
            horizontalSizeClass: horizontalSizeClass,
            verticalSizeClass: verticalSizeClass
        )
    }
}

extension View {
    /// Centers content in the readable iPad column used by list-style root screens.
    func readableRootContentWidth(_ horizontalSizeClass: UserInterfaceSizeClass?) -> some View {
        frame(maxWidth: GameplayLayout.contentMaxWidth(horizontalSizeClass: horizontalSizeClass))
            .frame(maxWidth: .infinity)
    }
}

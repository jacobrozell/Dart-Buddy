import SwiftUI

/// Scoreboard scroll beside a bottom-docked pad for table-style match screens.
struct SideBySideMatchBody<Board: View, PadChrome: View, Controls: View>: View {
    @ViewBuilder var board: () -> Board
    @ViewBuilder var padChrome: () -> PadChrome
    @ViewBuilder var controls: () -> Controls

    var body: some View {
        MatchScoringBody(
            scoreboard: board,
            padChrome: padChrome,
            pad: controls
        )
    }
}

extension SideBySideMatchBody where PadChrome == EmptyView {
    init(
        @ViewBuilder board: @escaping () -> Board,
        @ViewBuilder controls: @escaping () -> Controls
    ) {
        self.board = board
        self.padChrome = { EmptyView() }
        self.controls = controls
    }
}

extension View {
    /// Centers content in the readable iPad column used by list-style root screens.
    func readableRootContentWidth(_ horizontalSizeClass: UserInterfaceSizeClass?) -> some View {
        frame(maxWidth: GameplayLayout.contentMaxWidth(horizontalSizeClass: horizontalSizeClass))
            .frame(maxWidth: .infinity)
    }
}

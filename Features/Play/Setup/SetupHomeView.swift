import SwiftUI

struct SetupHomeView: View {
    @ObservedObject var homeViewModel: PlayHomeViewModel
    @ObservedObject var setupViewModel: MatchSetupViewModel
    @ObservedObject var pendingMatchPlayerSelections: PendingMatchPlayerSelections
    let onResumeMatch: (MatchSummary) -> Void
    let onStartRoute: (PlayRoute) -> Void
    let onChangeMode: () -> Void

    var body: some View {
        SetupHomeSheetHost(
            homeViewModel: homeViewModel,
            setupViewModel: setupViewModel,
            pendingMatchPlayerSelections: pendingMatchPlayerSelections,
            onResumeMatch: onResumeMatch,
            onStartRoute: onStartRoute,
            onChangeMode: onChangeMode
        )
    }
}

import SwiftUI

struct SetupAmericanCricketOptionChips: View {
    @ObservedObject var setupViewModel: MatchSetupViewModel
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

@ViewBuilder
    var body: some View {
        americanCricketPointsChip
    }

    private var americanCricketPointsChip: some View {
        SetupOptionChipHelpers.chip(titleKey: "play.americanCricket.setup.points", color: Brand.amber, dynamicTypeSize: dynamicTypeSize) {
            Menu {
                Button(L10n.string("play.americanCricket.setup.pointsOn")) {
                    setupViewModel.americanCricketPointsEnabled = true
                    setupViewModel.revalidate()
                }
                Button(L10n.string("play.americanCricket.setup.pointsOff")) {
                    setupViewModel.americanCricketPointsEnabled = false
                    setupViewModel.revalidate()
                }
            } label: {
                SetupOptionChipHelpers.chipBox(
                    setupViewModel.americanCricketPointsEnabled
                        ? L10n.string("play.americanCricket.setup.pointsOn")
                        : L10n.string("play.americanCricket.setup.pointsOff"),
                    color: Brand.amber,
                    dynamicTypeSize: dynamicTypeSize, showsMenuIndicator: true
                )
            }
            .accessibilityIdentifier("setup_americanCricketPointsChip")
        }
    }
}

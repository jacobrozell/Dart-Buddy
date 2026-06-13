import SwiftUI

extension SetupHomeView {
    @ViewBuilder
    var americanCricketChipsGrid: some View {
        americanCricketPointsChip
    }

    private var americanCricketPointsChip: some View {
        chip(titleKey: "play.americanCricket.setup.points", color: Brand.amber) {
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
                chipBox(
                    setupViewModel.americanCricketPointsEnabled
                        ? L10n.string("play.americanCricket.setup.pointsOn")
                        : L10n.string("play.americanCricket.setup.pointsOff"),
                    color: Brand.amber,
                    showsMenuIndicator: true
                )
            }
            .accessibilityIdentifier("setup_americanCricketPointsChip")
        }
    }
}

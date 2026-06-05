import SwiftUI

extension SetupHomeView {
    @ViewBuilder
    var killerChipsGrid: some View {
        HStack(spacing: DS.Spacing.s3) {
            killerLivesChip
        }
    }

    private var killerLivesChip: some View {
        chip(title: "play.killer.setup.lives", color: Brand.red) {
            Menu {
                ForEach([3, 4, 5], id: \.self) { lives in
                    Button(L10n.format("play.killer.setup.livesValueFormat", lives)) {
                        setupViewModel.killerStartingLives = lives
                        setupViewModel.revalidate()
                    }
                }
            } label: {
                chipBox(
                    L10n.format("play.killer.setup.livesValueFormat", setupViewModel.killerStartingLives),
                    color: Brand.red,
                    showsMenuIndicator: true
                )
            }
            .accessibilityIdentifier("setup_killerLivesChip")
        }
    }
}

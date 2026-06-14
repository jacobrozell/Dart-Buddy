import SwiftUI

struct SetupKillerOptionChips: View {
    @ObservedObject var setupViewModel: MatchSetupViewModel
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

@ViewBuilder
    var body: some View {
        HStack(spacing: DS.Spacing.s3) {
            killerLivesChip
        }
    }

    private var killerLivesChip: some View {
        SetupOptionChipHelpers.chip(titleKey: "play.killer.setup.lives", color: Brand.red, dynamicTypeSize: dynamicTypeSize) {
            Menu {
                ForEach([3, 4, 5], id: \.self) { lives in
                    Button(L10n.format("play.killer.setup.livesValueFormat", lives)) {
                        setupViewModel.killerStartingLives = lives
                        setupViewModel.revalidate()
                    }
                }
            } label: {
                SetupOptionChipHelpers.chipBox(
                    L10n.format("play.killer.setup.livesValueFormat", setupViewModel.killerStartingLives),
                    color: Brand.red,
                    dynamicTypeSize: dynamicTypeSize, showsMenuIndicator: true
                )
            }
            .accessibilityIdentifier("setup_killerLivesChip")
        }
    }
}

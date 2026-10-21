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
        let value = L10n.format("play.killer.setup.livesValueFormat", setupViewModel.killerStartingLives)
        return SetupOptionChipHelpers.chip(titleKey: "play.killer.setup.lives", color: Brand.key, dynamicTypeSize: dynamicTypeSize) {
            Menu {
                ForEach([3, 4, 5], id: \.self) { lives in
                    Button(L10n.format("play.killer.setup.livesValueFormat", lives)) {
                        setupViewModel.killerStartingLives = lives
                        setupViewModel.revalidate()
                    }
                }
            } label: {
                SetupOptionChipHelpers.chipBox(
                    value,
                    color: Brand.key,
                    dynamicTypeSize: dynamicTypeSize, showsMenuIndicator: true
                )
            }
            .accessibilityLabel(SetupOptionChipHelpers.chipAccessibilityLabel("play.killer.setup.lives", value))
            .accessibilityIdentifier("setup_killerLivesChip")
        }
    }
}

import SwiftUI

struct SetupSuddenDeathOptionChips: View {
    @ObservedObject var setupViewModel: MatchSetupViewModel
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

@ViewBuilder
    var body: some View {
        if dynamicTypeSize.isAccessibilitySize {
            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: DS.Spacing.s3), GridItem(.flexible(), spacing: DS.Spacing.s3)],
                spacing: DS.Spacing.s3
            ) {
                suddenDeathEliminateAllTiedChip
                suddenDeathVisitsPerRoundChip
            }
        } else {
            HStack(spacing: DS.Spacing.s3) {
                suddenDeathEliminateAllTiedChip
                suddenDeathVisitsPerRoundChip
            }
        }
    }

    private var suddenDeathEliminateAllTiedChip: some View {
        let value = setupViewModel.suddenDeathEliminateAllTied
            ? L10n.string("common.on")
            : L10n.string("common.off")
        return SetupOptionChipHelpers.chip(titleKey: "play.suddenDeath.setup.eliminateAllTied", color: Brand.key, dynamicTypeSize: dynamicTypeSize) {
            Button {
                setupViewModel.suddenDeathEliminateAllTied.toggle()
                setupViewModel.revalidate()
            } label: {
                SetupOptionChipHelpers.chipBox(
                    value,
                    color: Brand.key,
                    dynamicTypeSize: dynamicTypeSize, showsMenuIndicator: false
                )
            }
            .accessibilityLabel(
                SetupOptionChipHelpers.chipAccessibilityLabel("play.suddenDeath.setup.eliminateAllTied", value)
            )
            .accessibilityIdentifier("setup_suddenDeathEliminateAllTiedChip")
        }
    }

    private var suddenDeathVisitsPerRoundChip: some View {
        let value = L10n.format("play.suddenDeath.setup.visitsPerRoundValueFormat", setupViewModel.suddenDeathVisitsPerRound)
        return SetupOptionChipHelpers.chip(titleKey: "play.suddenDeath.setup.visitsPerRound", color: Brand.key, dynamicTypeSize: dynamicTypeSize) {
            Menu {
                ForEach([1, 2], id: \.self) { count in
                    Button(L10n.format("play.suddenDeath.setup.visitsPerRoundValueFormat", count)) {
                        setupViewModel.suddenDeathVisitsPerRound = count
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
            .accessibilityLabel(
                SetupOptionChipHelpers.chipAccessibilityLabel("play.suddenDeath.setup.visitsPerRound", value)
            )
            .accessibilityIdentifier("setup_suddenDeathVisitsPerRoundChip")
        }
    }
}

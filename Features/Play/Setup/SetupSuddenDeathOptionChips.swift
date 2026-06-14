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
        SetupOptionChipHelpers.chip(titleKey: "play.suddenDeath.setup.eliminateAllTied", color: Brand.amber, dynamicTypeSize: dynamicTypeSize) {
            Button {
                setupViewModel.suddenDeathEliminateAllTied.toggle()
                setupViewModel.revalidate()
            } label: {
                SetupOptionChipHelpers.chipBox(
                    setupViewModel.suddenDeathEliminateAllTied
                        ? L10n.string("common.on")
                        : L10n.string("common.off"),
                    color: Brand.amber,
                    dynamicTypeSize: dynamicTypeSize, showsMenuIndicator: false
                )
            }
            .accessibilityIdentifier("setup_suddenDeathEliminateAllTiedChip")
        }
    }

    private var suddenDeathVisitsPerRoundChip: some View {
        SetupOptionChipHelpers.chip(titleKey: "play.suddenDeath.setup.visitsPerRound", color: Brand.key, dynamicTypeSize: dynamicTypeSize) {
            Menu {
                ForEach([1, 2], id: \.self) { count in
                    Button(L10n.format("play.suddenDeath.setup.visitsPerRoundValueFormat", count)) {
                        setupViewModel.suddenDeathVisitsPerRound = count
                        setupViewModel.revalidate()
                    }
                }
            } label: {
                SetupOptionChipHelpers.chipBox(
                    L10n.format("play.suddenDeath.setup.visitsPerRoundValueFormat", setupViewModel.suddenDeathVisitsPerRound),
                    color: Brand.key,
                    dynamicTypeSize: dynamicTypeSize, showsMenuIndicator: true
                )
            }
            .accessibilityIdentifier("setup_suddenDeathVisitsPerRoundChip")
        }
    }
}

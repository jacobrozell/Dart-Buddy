import SwiftUI

extension SetupHomeView {
    @ViewBuilder
    var suddenDeathChipsGrid: some View {
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
        chip(titleKey: "play.suddenDeath.setup.eliminateAllTied", color: Brand.amber) {
            Button {
                setupViewModel.suddenDeathEliminateAllTied.toggle()
                setupViewModel.revalidate()
            } label: {
                chipBox(
                    setupViewModel.suddenDeathEliminateAllTied
                        ? L10n.string("common.on")
                        : L10n.string("common.off"),
                    color: Brand.amber,
                    showsMenuIndicator: false
                )
            }
            .accessibilityIdentifier("setup_suddenDeathEliminateAllTiedChip")
        }
    }

    private var suddenDeathVisitsPerRoundChip: some View {
        chip(titleKey: "play.suddenDeath.setup.visitsPerRound", color: Brand.key) {
            Menu {
                ForEach([1, 2], id: \.self) { count in
                    Button(L10n.format("play.suddenDeath.setup.visitsPerRoundValueFormat", count)) {
                        setupViewModel.suddenDeathVisitsPerRound = count
                        setupViewModel.revalidate()
                    }
                }
            } label: {
                chipBox(
                    L10n.format("play.suddenDeath.setup.visitsPerRoundValueFormat", setupViewModel.suddenDeathVisitsPerRound),
                    color: Brand.key,
                    showsMenuIndicator: true
                )
            }
            .accessibilityIdentifier("setup_suddenDeathVisitsPerRoundChip")
        }
    }
}

import SwiftUI

extension SetupHomeView {
    @ViewBuilder
    var shanghaiChipsGrid: some View {
        if dynamicTypeSize.isAccessibilitySize {
            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: DS.Spacing.s3), GridItem(.flexible(), spacing: DS.Spacing.s3)],
                spacing: DS.Spacing.s3
            ) {
                shanghaiRoundsChip
                shanghaiBonusChip
            }
        } else {
            HStack(spacing: DS.Spacing.s3) {
                shanghaiRoundsChip
                shanghaiBonusChip
            }
        }
    }

    private var shanghaiRoundsChip: some View {
        chip(titleKey: "play.shanghai.setup.rounds", color: Brand.key) {
            Menu {
                ForEach([7, 10, 20], id: \.self) { count in
                    Button(L10n.format("play.shanghai.setup.roundsValueFormat", count)) {
                        setupViewModel.shanghaiRoundCount = count
                        setupViewModel.revalidate()
                    }
                }
            } label: {
                chipBox(
                    L10n.format("play.shanghai.setup.roundsValueFormat", setupViewModel.shanghaiRoundCount),
                    color: Brand.key,
                    showsMenuIndicator: true
                )
            }
            .accessibilityIdentifier("setup_shanghaiRoundsChip")
        }
    }

    private var shanghaiBonusChip: some View {
        chip(titleKey: "play.shanghai.setup.bonusRule", color: Brand.amber) {
            Menu {
                ForEach(ShanghaiBonusRule.allCases, id: \.rawValue) { rule in
                    Button(rule.displayName) {
                        setupViewModel.shanghaiBonusRule = rule
                        setupViewModel.revalidate()
                    }
                }
            } label: {
                chipBox(
                    setupViewModel.shanghaiBonusRule.displayName,
                    color: Brand.amber,
                    showsMenuIndicator: true
                )
            }
            .accessibilityIdentifier("setup_shanghaiBonusChip")
        }
    }
}

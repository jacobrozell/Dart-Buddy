import SwiftUI

struct SetupShanghaiOptionChips: View {
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
        SetupOptionChipHelpers.chip(titleKey: "play.shanghai.setup.rounds", color: Brand.key, dynamicTypeSize: dynamicTypeSize) {
            Menu {
                ForEach([7, 10, 20], id: \.self) { count in
                    Button(L10n.format("play.shanghai.setup.roundsValueFormat", count)) {
                        setupViewModel.shanghaiRoundCount = count
                        setupViewModel.revalidate()
                    }
                }
            } label: {
                SetupOptionChipHelpers.chipBox(
                    L10n.format("play.shanghai.setup.roundsValueFormat", setupViewModel.shanghaiRoundCount),
                    color: Brand.key,
                    dynamicTypeSize: dynamicTypeSize, showsMenuIndicator: true
                )
            }
            .accessibilityIdentifier("setup_shanghaiRoundsChip")
        }
    }

    private var shanghaiBonusChip: some View {
        SetupOptionChipHelpers.chip(titleKey: "play.shanghai.setup.bonusRule", color: Brand.amber, dynamicTypeSize: dynamicTypeSize) {
            Menu {
                ForEach(ShanghaiBonusRule.allCases, id: \.rawValue) { rule in
                    Button(rule.displayName) {
                        setupViewModel.shanghaiBonusRule = rule
                        setupViewModel.revalidate()
                    }
                }
            } label: {
                SetupOptionChipHelpers.chipBox(
                    setupViewModel.shanghaiBonusRule.displayName,
                    color: Brand.amber,
                    dynamicTypeSize: dynamicTypeSize, showsMenuIndicator: true
                )
            }
            .accessibilityIdentifier("setup_shanghaiBonusChip")
        }
    }
}

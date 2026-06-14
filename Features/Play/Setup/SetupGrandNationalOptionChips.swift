import SwiftUI

struct SetupGrandNationalOptionChips: View {
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
                grandNationalRulesetChip
                grandNationalLapsChip
            }
        } else {
            HStack(spacing: DS.Spacing.s3) {
                grandNationalRulesetChip
                grandNationalLapsChip
            }
        }
    }

    private var grandNationalRulesetChip: some View {
        SetupOptionChipHelpers.chip(titleKey: "play.grandNational.setup.ruleset", color: Brand.key, dynamicTypeSize: dynamicTypeSize) {
            Menu {
                ForEach(GrandNationalRuleset.allCases, id: \.rawValue) { ruleset in
                    Button(ruleset.displayName) {
                        setupViewModel.grandNationalRuleset = ruleset
                        setupViewModel.revalidate()
                    }
                }
            } label: {
                SetupOptionChipHelpers.chipBox(
                    setupViewModel.grandNationalRuleset.displayName,
                    color: Brand.key,
                    dynamicTypeSize: dynamicTypeSize, showsMenuIndicator: true
                )
            }
            .accessibilityIdentifier("setup_grandNationalRulesetChip")
        }
    }

    private var grandNationalLapsChip: some View {
        SetupOptionChipHelpers.chip(titleKey: "play.grandNational.setup.laps", color: Brand.amber, dynamicTypeSize: dynamicTypeSize) {
            Menu {
                ForEach([1, 2, 3], id: \.self) { count in
                    Button(L10n.format("play.grandNational.setup.lapsValueFormat", count)) {
                        setupViewModel.grandNationalLaps = count
                        setupViewModel.revalidate()
                    }
                }
            } label: {
                SetupOptionChipHelpers.chipBox(
                    L10n.format("play.grandNational.setup.lapsValueFormat", setupViewModel.grandNationalLaps),
                    color: Brand.amber,
                    dynamicTypeSize: dynamicTypeSize, showsMenuIndicator: true
                )
            }
            .accessibilityIdentifier("setup_grandNationalLapsChip")
        }
    }
}

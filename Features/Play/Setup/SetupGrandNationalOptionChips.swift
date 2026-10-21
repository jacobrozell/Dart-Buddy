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
        let value = setupViewModel.grandNationalRuleset.displayName
        return SetupOptionChipHelpers.chip(titleKey: "play.grandNational.setup.ruleset", color: Brand.key, dynamicTypeSize: dynamicTypeSize) {
            Menu {
                ForEach(GrandNationalRuleset.allCases, id: \.rawValue) { ruleset in
                    Button(ruleset.displayName) {
                        setupViewModel.grandNationalRuleset = ruleset
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
                SetupOptionChipHelpers.chipAccessibilityLabel("play.grandNational.setup.ruleset", value)
            )
            .accessibilityIdentifier("setup_grandNationalRulesetChip")
        }
    }

    private var grandNationalLapsChip: some View {
        let value = L10n.format("play.grandNational.setup.lapsValueFormat", setupViewModel.grandNationalLaps)
        return SetupOptionChipHelpers.chip(titleKey: "play.grandNational.setup.laps", color: Brand.key, dynamicTypeSize: dynamicTypeSize) {
            Menu {
                ForEach([1, 2, 3], id: \.self) { count in
                    Button(L10n.format("play.grandNational.setup.lapsValueFormat", count)) {
                        setupViewModel.grandNationalLaps = count
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
                SetupOptionChipHelpers.chipAccessibilityLabel("play.grandNational.setup.laps", value)
            )
            .accessibilityIdentifier("setup_grandNationalLapsChip")
        }
    }
}

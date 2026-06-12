import SwiftUI

extension SetupHomeView {
    @ViewBuilder
    var grandNationalChipsGrid: some View {
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
        chip(title: "play.grandNational.setup.ruleset", color: Brand.key) {
            Menu {
                ForEach(GrandNationalRuleset.allCases, id: \.rawValue) { ruleset in
                    Button(ruleset.displayName) {
                        setupViewModel.grandNationalRuleset = ruleset
                        setupViewModel.revalidate()
                    }
                }
            } label: {
                chipBox(
                    setupViewModel.grandNationalRuleset.displayName,
                    color: Brand.key,
                    showsMenuIndicator: true
                )
            }
            .accessibilityIdentifier("setup_grandNationalRulesetChip")
        }
    }

    private var grandNationalLapsChip: some View {
        chip(title: "play.grandNational.setup.laps", color: Brand.amber) {
            Menu {
                ForEach([1, 2, 3], id: \.self) { count in
                    Button(L10n.format("play.grandNational.setup.lapsValueFormat", count)) {
                        setupViewModel.grandNationalLaps = count
                        setupViewModel.revalidate()
                    }
                }
            } label: {
                chipBox(
                    L10n.format("play.grandNational.setup.lapsValueFormat", setupViewModel.grandNationalLaps),
                    color: Brand.amber,
                    showsMenuIndicator: true
                )
            }
            .accessibilityIdentifier("setup_grandNationalLapsChip")
        }
    }
}

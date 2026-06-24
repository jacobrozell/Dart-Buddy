import SwiftUI

struct SetupAroundTheClock180OptionChips: View {
    @ObservedObject var setupViewModel: MatchSetupViewModel
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

@ViewBuilder
    var body: some View {
        if dynamicTypeSize.isAccessibilitySize {
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: DS.Spacing.s3),
                    GridItem(.flexible(), spacing: DS.Spacing.s3),
                ],
                spacing: DS.Spacing.s3
            ) {
                atc180ParScoreChip
            }
        } else {
            HStack(spacing: DS.Spacing.s3) {
                atc180ParScoreChip
            }
        }
    }

    private var atc180ParScoreChip: some View {
        SetupOptionChipHelpers.chip(titleKey: "play.aroundTheClock180.setup.parScore", color: Brand.amber, dynamicTypeSize: dynamicTypeSize) {
            Menu {
                Button(L10n.string("play.aroundTheClock180.setup.parScore.none")) {
                    setupViewModel.aroundTheClock180ParScoreEnabled = false
                    setupViewModel.revalidate()
                }
                ForEach([60, 75, 80, 100, 120, 150], id: \.self) { value in
                    Button(L10n.format("play.aroundTheClock180.setup.parScoreValueFormat", value)) {
                        setupViewModel.aroundTheClock180ParScore = value
                        setupViewModel.aroundTheClock180ParScoreEnabled = true
                        setupViewModel.revalidate()
                    }
                }
            } label: {
                SetupOptionChipHelpers.chipBox(
                    setupViewModel.aroundTheClock180ParScoreEnabled
                        ? L10n.format(
                            "play.aroundTheClock180.setup.parScoreValueFormat",
                            setupViewModel.aroundTheClock180ParScore
                        )
                        : L10n.string("play.aroundTheClock180.setup.parScore.none"),
                    color: Brand.amber,
                    dynamicTypeSize: dynamicTypeSize, showsMenuIndicator: true
                )
            }
            .accessibilityIdentifier("setup_aroundTheClock180ParScoreChip")
        }
    }
}

import SwiftUI

struct SetupHalveItOptionChips: View {
    @ObservedObject var setupViewModel: MatchSetupViewModel
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private static let startingScoreOptions = [0, 100, 301, 501]

    var body: some View {
        SetupOptionChipHelpers.chip(
            titleKey: "play.halveIt.setup.startingScore",
            color: Brand.amber,
            dynamicTypeSize: dynamicTypeSize
        ) {
            Menu {
                ForEach(Self.startingScoreOptions, id: \.self) { score in
                    Button(L10n.format("play.halveIt.setup.startingScoreValueFormat", score)) {
                        setupViewModel.halveItStartingScore = score
                        setupViewModel.revalidate()
                    }
                }
            } label: {
                SetupOptionChipHelpers.chipBox(
                    L10n.format(
                        "play.halveIt.setup.startingScoreValueFormat",
                        setupViewModel.halveItStartingScore
                    ),
                    color: Brand.amber,
                    dynamicTypeSize: dynamicTypeSize,
                    showsMenuIndicator: true
                )
            }
            .accessibilityIdentifier("setup_halveItStartingScoreChip")
        }
    }
}

import SwiftUI

struct SetupEnglishCricketOptionChips: View {
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
                englishCricketWicketsChip
                englishCricketEndEarlyChip
            }
        } else {
            HStack(spacing: DS.Spacing.s3) {
                englishCricketWicketsChip
                englishCricketEndEarlyChip
            }
        }
    }

    private var englishCricketWicketsChip: some View {
        SetupOptionChipHelpers.chip(titleKey: "play.englishCricket.setup.wicketsPerInnings", color: Brand.key, dynamicTypeSize: dynamicTypeSize) {
            Menu {
                ForEach([5, 7, 10], id: \.self) { count in
                    Button(L10n.format("play.englishCricket.setup.wicketsValueFormat", count)) {
                        setupViewModel.englishCricketWicketsPerInnings = count
                        setupViewModel.revalidate()
                    }
                }
            } label: {
                SetupOptionChipHelpers.chipBox(
                    L10n.format("play.englishCricket.setup.wicketsValueFormat", setupViewModel.englishCricketWicketsPerInnings),
                    color: Brand.key,
                    dynamicTypeSize: dynamicTypeSize, showsMenuIndicator: true
                )
            }
            .accessibilityIdentifier("setup_englishCricketWicketsChip")
        }
    }

    private var englishCricketEndEarlyChip: some View {
        SetupOptionChipHelpers.chip(titleKey: "play.englishCricket.setup.endWhenTargetPassed", color: Brand.amber, dynamicTypeSize: dynamicTypeSize) {
            Button {
                setupViewModel.englishCricketEndWhenTargetPassed.toggle()
                setupViewModel.revalidate()
            } label: {
                SetupOptionChipHelpers.chipBox(
                    setupViewModel.englishCricketEndWhenTargetPassed
                        ? L10n.string("common.on")
                        : L10n.string("common.off"),
                    color: Brand.amber,
                    dynamicTypeSize: dynamicTypeSize, showsMenuIndicator: false
                )
            }
            .accessibilityIdentifier("setup_englishCricketEndEarlyChip")
        }
    }
}

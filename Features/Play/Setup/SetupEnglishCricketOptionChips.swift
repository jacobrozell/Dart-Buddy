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
        let value = L10n.format("play.englishCricket.setup.wicketsValueFormat", setupViewModel.englishCricketWicketsPerInnings)
        return SetupOptionChipHelpers.chip(titleKey: "play.englishCricket.setup.wicketsPerInnings", color: Brand.key, dynamicTypeSize: dynamicTypeSize) {
            Menu {
                ForEach([5, 7, 10], id: \.self) { count in
                    Button(L10n.format("play.englishCricket.setup.wicketsValueFormat", count)) {
                        setupViewModel.englishCricketWicketsPerInnings = count
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
                SetupOptionChipHelpers.chipAccessibilityLabel("play.englishCricket.setup.wicketsPerInnings", value)
            )
            .accessibilityIdentifier("setup_englishCricketWicketsChip")
        }
    }

    private var englishCricketEndEarlyChip: some View {
        let value = setupViewModel.englishCricketEndWhenTargetPassed
            ? L10n.string("common.on")
            : L10n.string("common.off")
        return SetupOptionChipHelpers.chip(titleKey: "play.englishCricket.setup.endWhenTargetPassed", color: Brand.key, dynamicTypeSize: dynamicTypeSize) {
            Button {
                setupViewModel.englishCricketEndWhenTargetPassed.toggle()
                setupViewModel.revalidate()
            } label: {
                SetupOptionChipHelpers.chipBox(
                    value,
                    color: Brand.key,
                    dynamicTypeSize: dynamicTypeSize, showsMenuIndicator: false
                )
            }
            .accessibilityLabel(
                SetupOptionChipHelpers.chipAccessibilityLabel("play.englishCricket.setup.endWhenTargetPassed", value)
            )
            .accessibilityIdentifier("setup_englishCricketEndEarlyChip")
        }
    }
}

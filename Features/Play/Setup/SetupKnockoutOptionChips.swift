import SwiftUI

struct SetupKnockoutOptionChips: View {
    @ObservedObject var setupViewModel: MatchSetupViewModel
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

@ViewBuilder
    var body: some View {
        if dynamicTypeSize.isAccessibilitySize {
            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: DS.Spacing.s3)],
                spacing: DS.Spacing.s3
            ) {
                knockoutStrikesChip
            }
        } else {
            HStack(spacing: DS.Spacing.s3) {
                knockoutStrikesChip
            }
        }
    }

    private var knockoutStrikesChip: some View {
        SetupOptionChipHelpers.chip(titleKey: "play.knockout.setup.strikesToEliminate", color: Brand.red, dynamicTypeSize: dynamicTypeSize) {
            Menu {
                ForEach([1, 2, 3, 4, 5], id: \.self) { count in
                    Button(L10n.format("play.knockout.setup.strikesValueFormat", count)) {
                        setupViewModel.knockoutStrikesToEliminate = count
                        setupViewModel.revalidate()
                    }
                }
            } label: {
                SetupOptionChipHelpers.chipBox(
                    L10n.format("play.knockout.setup.strikesValueFormat", setupViewModel.knockoutStrikesToEliminate),
                    color: Brand.red,
                    dynamicTypeSize: dynamicTypeSize, showsMenuIndicator: true
                )
            }
            .accessibilityIdentifier("setup_knockoutStrikesChip")
        }
    }
}

import SwiftUI

struct SetupBaseballOptionChips: View {
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
                baseballInningsChip
                baseballTieBreakerChip
                baseballStretchChip
            }
        } else {
            HStack(spacing: DS.Spacing.s3) {
                baseballInningsChip
                baseballTieBreakerChip
                baseballStretchChip
            }
        }
    }

    private var baseballInningsChip: some View {
        let value = L10n.string("play.baseball.setup.inningsValue")
        return SetupOptionChipHelpers.chip(titleKey: "play.baseball.setup.innings", color: Brand.key, dynamicTypeSize: dynamicTypeSize) {
            SetupOptionChipHelpers.chipBox(value, color: Brand.key, dynamicTypeSize: dynamicTypeSize, showsMenuIndicator: false)
                .accessibilityLabel(SetupOptionChipHelpers.chipAccessibilityLabel("play.baseball.setup.innings", value))
                .accessibilityIdentifier("setup_baseballInningsChip")
        }
    }

    private var baseballTieBreakerChip: some View {
        let selectedLabel = setupViewModel.baseballTieBreaker.displayName
        return SetupOptionChipHelpers.chip(titleKey: "play.baseball.setup.tieBreaker", color: Brand.key, dynamicTypeSize: dynamicTypeSize) {
            Menu {
                ForEach(BaseballTieBreaker.allCases, id: \.rawValue) { option in
                    Button(option.displayName) {
                        setupViewModel.baseballTieBreaker = option
                        setupViewModel.revalidate()
                    }
                }
            } label: {
                SetupOptionChipHelpers.chipBox(
                    selectedLabel,
                    color: Brand.key,
                    dynamicTypeSize: dynamicTypeSize, showsMenuIndicator: true
                )
            }
            .accessibilityLabel(
                SetupOptionChipHelpers.chipAccessibilityLabel("play.baseball.setup.tieBreaker", selectedLabel)
            )
            .accessibilityIdentifier("setup_baseballTieBreakerChip")
        }
    }

    private var baseballStretchChip: some View {
        let value = setupViewModel.baseballSeventhInningStretch
            ? L10n.string("play.baseball.stretch.on")
            : L10n.string("play.baseball.stretch.off")
        return SetupOptionChipHelpers.chip(titleKey: "play.baseball.setup.stretch", color: Brand.key, dynamicTypeSize: dynamicTypeSize) {
            Menu {
                Button(L10n.string("play.baseball.stretch.off")) {
                    setupViewModel.baseballSeventhInningStretch = false
                    setupViewModel.revalidate()
                }
                Button(L10n.string("play.baseball.stretch.on")) {
                    setupViewModel.baseballSeventhInningStretch = true
                    setupViewModel.revalidate()
                }
            } label: {
                SetupOptionChipHelpers.chipBox(
                    value,
                    color: Brand.key,
                    dynamicTypeSize: dynamicTypeSize, showsMenuIndicator: true
                )
            }
            .accessibilityLabel(SetupOptionChipHelpers.chipAccessibilityLabel("play.baseball.setup.stretch", value))
            .accessibilityIdentifier("setup_baseballStretchChip")
        }
    }
}

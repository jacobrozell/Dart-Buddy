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
        SetupOptionChipHelpers.chip(titleKey: "play.baseball.setup.innings", color: Brand.key, dynamicTypeSize: dynamicTypeSize) {
            SetupOptionChipHelpers.chipBox(L10n.string("play.baseball.setup.inningsValue"), color: Brand.key, dynamicTypeSize: dynamicTypeSize, showsMenuIndicator: false)
                .accessibilityIdentifier("setup_baseballInningsChip")
        }
    }

    private var baseballTieBreakerChip: some View {
        SetupOptionChipHelpers.chip(titleKey: "play.baseball.setup.tieBreaker", color: Brand.red, dynamicTypeSize: dynamicTypeSize) {
            Menu {
                ForEach(BaseballTieBreaker.allCases, id: \.rawValue) { value in
                    Button(value.displayName) {
                        setupViewModel.baseballTieBreaker = value
                        setupViewModel.revalidate()
                    }
                }
            } label: {
                SetupOptionChipHelpers.chipBox(
                    setupViewModel.baseballTieBreaker.displayName,
                    color: Brand.red,
                    dynamicTypeSize: dynamicTypeSize, showsMenuIndicator: true
                )
            }
            .accessibilityIdentifier("setup_baseballTieBreakerChip")
        }
    }

    private var baseballStretchChip: some View {
        SetupOptionChipHelpers.chip(titleKey: "play.baseball.setup.stretch", color: Brand.amber, dynamicTypeSize: dynamicTypeSize) {
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
                    setupViewModel.baseballSeventhInningStretch
                        ? L10n.string("play.baseball.stretch.on")
                        : L10n.string("play.baseball.stretch.off"),
                    color: Brand.amber,
                    dynamicTypeSize: dynamicTypeSize, showsMenuIndicator: true
                )
            }
            .accessibilityIdentifier("setup_baseballStretchChip")
        }
    }
}

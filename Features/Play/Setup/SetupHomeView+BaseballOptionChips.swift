import SwiftUI

extension SetupHomeView {
    @ViewBuilder
    var baseballChipsGrid: some View {
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
        chip(title: "play.baseball.setup.innings", color: Brand.key) {
            chipBox(L10n.string("play.baseball.setup.inningsValue"), color: Brand.key, showsMenuIndicator: false)
                .accessibilityIdentifier("setup_baseballInningsChip")
        }
    }

    private var baseballTieBreakerChip: some View {
        chip(title: "play.baseball.setup.tieBreaker", color: Brand.red) {
            Menu {
                ForEach(BaseballTieBreaker.allCases, id: \.rawValue) { value in
                    Button(value.displayName) {
                        setupViewModel.baseballTieBreaker = value
                        setupViewModel.revalidate()
                    }
                }
            } label: {
                chipBox(
                    setupViewModel.baseballTieBreaker.displayName,
                    color: Brand.red,
                    showsMenuIndicator: true
                )
            }
            .accessibilityIdentifier("setup_baseballTieBreakerChip")
        }
    }

    private var baseballStretchChip: some View {
        chip(title: "play.baseball.setup.stretch", color: Brand.amber) {
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
                chipBox(
                    setupViewModel.baseballSeventhInningStretch
                        ? L10n.string("play.baseball.stretch.on")
                        : L10n.string("play.baseball.stretch.off"),
                    color: Brand.amber,
                    showsMenuIndicator: true
                )
            }
            .accessibilityIdentifier("setup_baseballStretchChip")
        }
    }
}

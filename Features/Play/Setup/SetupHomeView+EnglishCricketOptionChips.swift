import SwiftUI

extension SetupHomeView {
    @ViewBuilder
    var englishCricketChipsGrid: some View {
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
        chip(titleKey: "play.englishCricket.setup.wicketsPerInnings", color: Brand.key) {
            Menu {
                ForEach([5, 7, 10], id: \.self) { count in
                    Button(L10n.format("play.englishCricket.setup.wicketsValueFormat", count)) {
                        setupViewModel.englishCricketWicketsPerInnings = count
                        setupViewModel.revalidate()
                    }
                }
            } label: {
                chipBox(
                    L10n.format("play.englishCricket.setup.wicketsValueFormat", setupViewModel.englishCricketWicketsPerInnings),
                    color: Brand.key,
                    showsMenuIndicator: true
                )
            }
            .accessibilityIdentifier("setup_englishCricketWicketsChip")
        }
    }

    private var englishCricketEndEarlyChip: some View {
        chip(titleKey: "play.englishCricket.setup.endWhenTargetPassed", color: Brand.amber) {
            Button {
                setupViewModel.englishCricketEndWhenTargetPassed.toggle()
                setupViewModel.revalidate()
            } label: {
                chipBox(
                    setupViewModel.englishCricketEndWhenTargetPassed
                        ? L10n.string("common.on")
                        : L10n.string("common.off"),
                    color: Brand.amber,
                    showsMenuIndicator: false
                )
            }
            .accessibilityIdentifier("setup_englishCricketEndEarlyChip")
        }
    }
}

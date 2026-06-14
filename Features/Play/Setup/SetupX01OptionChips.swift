import SwiftUI

struct SetupX01OptionChips: View {
    @ObservedObject var setupViewModel: MatchSetupViewModel
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

// Cricket has no per-match options, so this cluster only renders for `.x01`.

    @ViewBuilder
    var body: some View {
        if dynamicTypeSize.isAccessibilitySize {
            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: DS.Spacing.s3), GridItem(.flexible(), spacing: DS.Spacing.s3)],
                spacing: DS.Spacing.s3
            ) {
                pointsChip
                checkoutChip
                setsChip
                legFormatChip
                checkInChip
                legsChip
            }
        } else if horizontalSizeClass == .regular {
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: DS.Spacing.s3),
                    GridItem(.flexible(), spacing: DS.Spacing.s3),
                    GridItem(.flexible(), spacing: DS.Spacing.s3)
                ],
                spacing: DS.Spacing.s3
            ) {
                pointsChip
                checkoutChip
                setsChip
                legFormatChip
                checkInChip
                legsChip
            }
        } else {
            VStack(spacing: DS.Spacing.s3) {
                HStack(spacing: DS.Spacing.s3) {
                    pointsChip
                    checkoutChip
                    setsChip
                }
                HStack(spacing: DS.Spacing.s3) {
                    legFormatChip
                    checkInChip
                    legsChip
                }
            }
        }
    }

    private var pointsChip: some View {
        SetupOptionChipHelpers.chip(titleKey: "play.setup.chip.points", color: Brand.key, dynamicTypeSize: dynamicTypeSize) {
            Menu {
                ForEach(X01StartScores.all, id: \.self) { score in
                    Button("\(score)") {
                        setupViewModel.x01StartScore = score
                        setupViewModel.revalidate()
                    }
                    .accessibilityIdentifier("setup_startScoreOption_\(score)")
                }
            } label: {
                SetupOptionChipHelpers.chipBox("\(setupViewModel.x01StartScore)", color: Brand.key, dynamicTypeSize: dynamicTypeSize, showsMenuIndicator: true)
            }
            .accessibilityLabel(SetupOptionChipHelpers.chipAccessibilityLabel("play.setup.chip.points", "\(setupViewModel.x01StartScore)"))
            .accessibilityIdentifier("setup_startScoreChip")
        }
    }

    private var checkoutChip: some View {
        SetupOptionChipHelpers.chip(titleKey: "play.setup.chip.checkOut", color: Brand.key, dynamicTypeSize: dynamicTypeSize) {
            Menu {
                ForEach(X01CheckoutMode.allCases, id: \.rawValue) { value in
                    Button(value.displayName) {
                        setupViewModel.x01CheckoutMode = value
                        setupViewModel.revalidate()
                    }
                    .accessibilityIdentifier("setup_checkoutOption_\(value.rawValue)")
                }
            } label: {
                SetupOptionChipHelpers.chipBox(setupViewModel.x01CheckoutMode.displayName, color: Brand.key, dynamicTypeSize: dynamicTypeSize, showsMenuIndicator: true)
            }
            .accessibilityLabel(SetupOptionChipHelpers.chipAccessibilityLabel("play.setup.chip.checkOut", setupViewModel.x01CheckoutMode.displayName))
            .accessibilityIdentifier("setup_checkoutChip")
        }
    }

    private var checkInChip: some View {
        SetupOptionChipHelpers.chip(titleKey: "play.setup.chip.checkIn", color: Brand.key, dynamicTypeSize: dynamicTypeSize) {
            Menu {
                ForEach(X01CheckInMode.allCases, id: \.rawValue) { value in
                    Button(value.displayName) {
                        setupViewModel.x01CheckInMode = value
                        setupViewModel.revalidate()
                    }
                }
            } label: {
                SetupOptionChipHelpers.chipBox(setupViewModel.x01CheckInMode.displayName, color: Brand.key, dynamicTypeSize: dynamicTypeSize, showsMenuIndicator: true)
            }
            .accessibilityLabel(SetupOptionChipHelpers.chipAccessibilityLabel("play.setup.chip.checkIn", setupViewModel.x01CheckInMode.displayName))
            .accessibilityIdentifier("setup_checkInChip")
        }
    }

    private var legFormatChip: some View {
        SetupOptionChipHelpers.chip(titleKey: "play.setup.chip.setLeg", color: Brand.key, dynamicTypeSize: dynamicTypeSize) {
            Menu {
                ForEach(X01LegFormat.allCases, id: \.rawValue) { value in
                    Button(value.displayName) {
                        setupViewModel.x01LegFormat = value
                        setupViewModel.revalidate()
                    }
                }
            } label: {
                SetupOptionChipHelpers.chipBox(setupViewModel.x01LegFormat.displayName, color: Brand.key, dynamicTypeSize: dynamicTypeSize, showsMenuIndicator: true)
            }
            .accessibilityLabel(SetupOptionChipHelpers.chipAccessibilityLabel("play.setup.chip.setLeg", setupViewModel.x01LegFormat.displayName))
            .accessibilityIdentifier("setup_setLegChip")
        }
    }

    private var setsChip: some View {
        SetupOptionChipHelpers.chip(titleKey: "play.setup.chip.sets", color: Brand.key, dynamicTypeSize: dynamicTypeSize) {
            Menu {
                ForEach(1 ... 5, id: \.self) { value in
                    Button("\(value)") {
                        setupViewModel.x01SetsToWin = value
                        setupViewModel.x01SetsEnabled = value > 1
                        setupViewModel.revalidate()
                    }
                }
            } label: {
                SetupOptionChipHelpers.chipBox("\(setupViewModel.x01SetsEnabled ? setupViewModel.x01SetsToWin : 1)", color: Brand.key, dynamicTypeSize: dynamicTypeSize, showsMenuIndicator: true)
            }
            .accessibilityLabel(SetupOptionChipHelpers.chipAccessibilityLabel("play.setup.chip.sets", "\(setupViewModel.x01SetsEnabled ? setupViewModel.x01SetsToWin : 1)"))
            .accessibilityIdentifier("setup_setsChip")
        }
    }

    private var legsChip: some View {
        SetupOptionChipHelpers.chip(titleKey: "play.setup.chip.legs", color: Brand.key, dynamicTypeSize: dynamicTypeSize) {
            Menu {
                ForEach(1 ... 9, id: \.self) { value in
                    Button("\(value)") {
                        setupViewModel.x01LegsToWin = value
                        setupViewModel.revalidate()
                    }
                    .accessibilityIdentifier("setup_legsOption_\(value)")
                }
            } label: {
                SetupOptionChipHelpers.chipBox("\(setupViewModel.x01LegsToWin)", color: Brand.key, dynamicTypeSize: dynamicTypeSize, showsMenuIndicator: true)
            }
            .accessibilityLabel(SetupOptionChipHelpers.chipAccessibilityLabel("play.setup.chip.legs", "\(setupViewModel.x01LegsToWin)"))
            .accessibilityIdentifier("setup_legsChip")
        }
    }
}

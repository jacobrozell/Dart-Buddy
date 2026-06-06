import SwiftUI

// X01 game-option chips (points, check-in/out, set/leg format, sets, legs).
// Cricket has no per-match options, so this cluster only renders for `.x01`.
extension SetupHomeView {
    @ViewBuilder
    var chipsGrid: some View {
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
        chip(title: L10n.setupChipPoints, color: Brand.key) {
            Menu {
                ForEach(X01StartScores.all, id: \.self) { score in
                    Button("\(score)") {
                        setupViewModel.x01StartScore = score
                        setupViewModel.revalidate()
                    }
                    .accessibilityIdentifier("setup_startScoreOption_\(score)")
                }
            } label: {
                chipBox("\(setupViewModel.x01StartScore)", color: Brand.key, showsMenuIndicator: true)
            }
            .accessibilityLabel(chipAccessibilityLabel("play.setup.chip.points", "\(setupViewModel.x01StartScore)"))
            .accessibilityIdentifier("setup_startScoreChip")
        }
    }

    private var checkoutChip: some View {
        chip(title: L10n.setupChipCheckOut, color: Brand.key) {
            Menu {
                ForEach(X01CheckoutMode.allCases, id: \.rawValue) { value in
                    Button(value.displayName) {
                        setupViewModel.x01CheckoutMode = value
                        setupViewModel.revalidate()
                    }
                    .accessibilityIdentifier("setup_checkoutOption_\(value.rawValue)")
                }
            } label: {
                chipBox(setupViewModel.x01CheckoutMode.displayName, color: Brand.key, showsMenuIndicator: true)
            }
            .accessibilityLabel(chipAccessibilityLabel("play.setup.chip.checkOut", setupViewModel.x01CheckoutMode.displayName))
            .accessibilityIdentifier("setup_checkoutChip")
        }
    }

    private var checkInChip: some View {
        chip(title: L10n.setupChipCheckIn, color: Brand.key) {
            Menu {
                ForEach(X01CheckInMode.allCases, id: \.rawValue) { value in
                    Button(value.displayName) {
                        setupViewModel.x01CheckInMode = value
                        setupViewModel.revalidate()
                    }
                }
            } label: {
                chipBox(setupViewModel.x01CheckInMode.displayName, color: Brand.key, showsMenuIndicator: true)
            }
            .accessibilityLabel(chipAccessibilityLabel("play.setup.chip.checkIn", setupViewModel.x01CheckInMode.displayName))
            .accessibilityIdentifier("setup_checkInChip")
        }
    }

    private var legFormatChip: some View {
        chip(title: L10n.setupChipSetLeg, color: Brand.key) {
            Menu {
                ForEach(X01LegFormat.allCases, id: \.rawValue) { value in
                    Button(value.displayName) {
                        setupViewModel.x01LegFormat = value
                        setupViewModel.revalidate()
                    }
                }
            } label: {
                chipBox(setupViewModel.x01LegFormat.displayName, color: Brand.key, showsMenuIndicator: true)
            }
            .accessibilityLabel(chipAccessibilityLabel("play.setup.chip.setLeg", setupViewModel.x01LegFormat.displayName))
            .accessibilityIdentifier("setup_setLegChip")
        }
    }

    private var setsChip: some View {
        chip(title: L10n.setupChipSets, color: Brand.key) {
            Menu {
                ForEach(1 ... 5, id: \.self) { value in
                    Button("\(value)") {
                        setupViewModel.x01SetsToWin = value
                        setupViewModel.x01SetsEnabled = value > 1
                        setupViewModel.revalidate()
                    }
                }
            } label: {
                chipBox("\(setupViewModel.x01SetsEnabled ? setupViewModel.x01SetsToWin : 1)", color: Brand.key, showsMenuIndicator: true)
            }
            .accessibilityLabel(chipAccessibilityLabel("play.setup.chip.sets", "\(setupViewModel.x01SetsEnabled ? setupViewModel.x01SetsToWin : 1)"))
            .accessibilityIdentifier("setup_setsChip")
        }
    }

    private var legsChip: some View {
        chip(title: L10n.setupChipLegs, color: Brand.key) {
            Menu {
                ForEach(1 ... 9, id: \.self) { value in
                    Button("\(value)") {
                        setupViewModel.x01LegsToWin = value
                        setupViewModel.revalidate()
                    }
                    .accessibilityIdentifier("setup_legsOption_\(value)")
                }
            } label: {
                chipBox("\(setupViewModel.x01LegsToWin)", color: Brand.key, showsMenuIndicator: true)
            }
            .accessibilityLabel(chipAccessibilityLabel("play.setup.chip.legs", "\(setupViewModel.x01LegsToWin)"))
            .accessibilityIdentifier("setup_legsChip")
        }
    }

    func chip<Content: View>(title: LocalizedStringKey, color: Color, @ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(Brand.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            content()
        }
        .frame(maxWidth: .infinity)
    }

    func chipBox(_ text: String, color: Color, showsMenuIndicator: Bool = false) -> some View {
        Text(text)
            .font(.headline.weight(.bold))
            // Chips use solid bright brand fills; dark ink keeps the value legible in dark mode
            // where adaptive white text would fail AA. Light mode is unchanged.
            .foregroundStyle(Brand.textPrimary)
            .lineLimit(2)
            .minimumScaleFactor(0.6)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, minHeight: dynamicTypeSize.isAccessibilitySize ? 56 : 52)
            .padding(.horizontal, 4)
            .background(color, in: RoundedRectangle(cornerRadius: DS.Radius.sm))
            .overlay(alignment: .topTrailing) {
                if showsMenuIndicator {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(Brand.textSecondary)
                        .padding(5)
                }
            }
    }

    func chipAccessibilityLabel(_ titleKey: String, _ value: String) -> String {
        L10n.format("play.setup.chip.accessibilityFormat", L10n.string(titleKey), value)
    }
}

import SwiftUI

extension SetupHomeView {
    @ViewBuilder
    var cricketChipsGrid: some View {
        if dynamicTypeSize.isAccessibilitySize {
            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: DS.Spacing.s3), GridItem(.flexible(), spacing: DS.Spacing.s3)],
                spacing: DS.Spacing.s3
            ) {
                cricketPointsChip
                cricketModeChip
                cricketLegFormatChip
                cricketSetsChip
                cricketLegsChip
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
                cricketPointsChip
                cricketModeChip
                cricketLegFormatChip
                cricketSetsChip
                cricketLegsChip
            }
        } else {
            VStack(spacing: DS.Spacing.s3) {
                HStack(spacing: DS.Spacing.s3) {
                    cricketPointsChip
                    cricketModeChip
                    cricketLegFormatChip
                }
                HStack(spacing: DS.Spacing.s3) {
                    Spacer(minLength: 0)
                    cricketSetsChip
                    cricketLegsChip
                    Spacer(minLength: 0)
                }
            }
        }
    }

    private var cricketPointsChip: some View {
        chip(title: L10n.setupChipPoints, color: Brand.key) {
            Picker(
                selection: Binding(
                    get: { setupViewModel.cricketPointsEnabled },
                    set: { isEnabled in
                        setupViewModel.cricketPointsEnabled = isEnabled
                        if !isEnabled {
                            setupViewModel.cricketScoringMode = .standard
                        }
                        setupViewModel.revalidate()
                    }
                )
            ) {
                Text(L10n.string("play.cricket.points.on"))
                    .tag(true)
                    .accessibilityIdentifier("setup_cricketPointsOption_on")
                Text(L10n.string("play.cricket.points.off"))
                    .tag(false)
                    .accessibilityIdentifier("setup_cricketPointsOption_off")
            } label: {
                chipBox(
                    setupViewModel.cricketPointsEnabled
                        ? L10n.string("play.cricket.points.on")
                        : L10n.string("play.cricket.points.off"),
                    color: Brand.key,
                    showsMenuIndicator: true
                )
            }
            .pickerStyle(.menu)
            .accessibilityLabel(
                chipAccessibilityLabel(
                    "play.setup.chip.points",
                    setupViewModel.cricketPointsEnabled
                        ? L10n.string("play.cricket.points.on")
                        : L10n.string("play.cricket.points.off")
                )
            )
            .accessibilityIdentifier("setup_cricketPointsChip")
        }
    }

    private var cricketModeChip: some View {
        chip(title: L10n.setupChipMode, color: Brand.red) {
            Menu {
                ForEach(CricketScoringMode.allCases, id: \.rawValue) { value in
                    Button(value.displayName) {
                        setupViewModel.cricketScoringMode = value
                        setupViewModel.revalidate()
                    }
                    .accessibilityIdentifier("setup_cricketModeOption_\(value.rawValue)")
                }
            } label: {
                chipBox(
                    setupViewModel.cricketScoringMode.displayName,
                    color: Brand.red,
                    showsMenuIndicator: setupViewModel.cricketPointsEnabled
                )
                .opacity(setupViewModel.cricketPointsEnabled ? 1 : 0.45)
            }
            .disabled(!setupViewModel.cricketPointsEnabled)
            .accessibilityLabel(
                chipAccessibilityLabel("play.setup.chip.mode", setupViewModel.cricketScoringMode.displayName)
            )
            .accessibilityIdentifier("setup_cricketModeChip")
        }
    }

    private var cricketLegFormatChip: some View {
        chip(title: L10n.setupChipSetLeg, color: Brand.key) {
            Menu {
                ForEach(X01LegFormat.allCases, id: \.rawValue) { value in
                    Button(value.displayName) {
                        setupViewModel.cricketLegFormat = value
                        setupViewModel.revalidate()
                    }
                }
            } label: {
                chipBox(setupViewModel.cricketLegFormat.displayName, color: Brand.key, showsMenuIndicator: true)
            }
            .accessibilityLabel(
                chipAccessibilityLabel("play.setup.chip.setLeg", setupViewModel.cricketLegFormat.displayName)
            )
            .accessibilityIdentifier("setup_cricketSetLegChip")
        }
    }

    private var cricketSetsChip: some View {
        chip(title: L10n.setupChipSets, color: Brand.key) {
            Menu {
                ForEach(1 ... 5, id: \.self) { value in
                    Button("\(value)") {
                        setupViewModel.cricketSetsToWin = value
                        setupViewModel.cricketSetsEnabled = value > 1
                        setupViewModel.revalidate()
                    }
                }
            } label: {
                chipBox(
                    "\(setupViewModel.cricketSetsEnabled ? setupViewModel.cricketSetsToWin : 1)",
                    color: Brand.key,
                    showsMenuIndicator: true
                )
            }
            .accessibilityLabel(
                chipAccessibilityLabel(
                    "play.setup.chip.sets",
                    "\(setupViewModel.cricketSetsEnabled ? setupViewModel.cricketSetsToWin : 1)"
                )
            )
            .accessibilityIdentifier("setup_cricketSetsChip")
        }
    }

    private var cricketLegsChip: some View {
        chip(title: L10n.setupChipLegs, color: Brand.key) {
            Menu {
                ForEach(1 ... 9, id: \.self) { value in
                    Button("\(value)") {
                        setupViewModel.cricketLegsToWin = value
                        setupViewModel.revalidate()
                    }
                    .accessibilityIdentifier("setup_cricketLegsOption_\(value)")
                }
            } label: {
                chipBox("\(setupViewModel.cricketLegsToWin)", color: Brand.key, showsMenuIndicator: true)
            }
            .accessibilityLabel(chipAccessibilityLabel("play.setup.chip.legs", "\(setupViewModel.cricketLegsToWin)"))
            .accessibilityIdentifier("setup_cricketLegsChip")
        }
    }
}

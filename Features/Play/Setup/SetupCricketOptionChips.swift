import SwiftUI

struct SetupCricketOptionChips: View {
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
        SetupOptionChipHelpers.chip(titleKey: "play.setup.chip.points", color: Brand.key, dynamicTypeSize: dynamicTypeSize) {
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
                SetupOptionChipHelpers.chipBox(
                    setupViewModel.cricketPointsEnabled
                        ? L10n.string("play.cricket.points.on")
                        : L10n.string("play.cricket.points.off"),
                    color: Brand.key,
                    dynamicTypeSize: dynamicTypeSize, showsMenuIndicator: true
                )
            }
            .pickerStyle(.menu)
            .accessibilityLabel(
                SetupOptionChipHelpers.chipAccessibilityLabel(
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
        SetupOptionChipHelpers.chip(titleKey: "play.setup.chip.mode", color: Brand.red, dynamicTypeSize: dynamicTypeSize) {
            Menu {
                ForEach(CricketScoringMode.allCases, id: \.rawValue) { value in
                    Button(value.displayName) {
                        setupViewModel.cricketScoringMode = value
                        setupViewModel.revalidate()
                    }
                    .accessibilityIdentifier("setup_cricketModeOption_\(value.rawValue)")
                }
            } label: {
                SetupOptionChipHelpers.chipBox(
                    setupViewModel.cricketScoringMode.displayName,
                    color: Brand.red,
                    dynamicTypeSize: dynamicTypeSize, showsMenuIndicator: setupViewModel.cricketPointsEnabled
                )
                .opacity(setupViewModel.cricketPointsEnabled ? 1 : 0.45)
            }
            .disabled(!setupViewModel.cricketPointsEnabled)
            .accessibilityLabel(
                SetupOptionChipHelpers.chipAccessibilityLabel("play.setup.chip.mode", setupViewModel.cricketScoringMode.displayName)
            )
            .accessibilityIdentifier("setup_cricketModeChip")
        }
    }

    private var cricketLegFormatChip: some View {
        SetupOptionChipHelpers.chip(titleKey: "play.setup.chip.setLeg", color: Brand.key, dynamicTypeSize: dynamicTypeSize) {
            Menu {
                ForEach(X01LegFormat.allCases, id: \.rawValue) { value in
                    Button(value.displayName) {
                        setupViewModel.cricketLegFormat = value
                        setupViewModel.revalidate()
                    }
                }
            } label: {
                SetupOptionChipHelpers.chipBox(setupViewModel.cricketLegFormat.displayName, color: Brand.key, dynamicTypeSize: dynamicTypeSize, showsMenuIndicator: true)
            }
            .accessibilityLabel(
                SetupOptionChipHelpers.chipAccessibilityLabel("play.setup.chip.setLeg", setupViewModel.cricketLegFormat.displayName)
            )
            .accessibilityIdentifier("setup_cricketSetLegChip")
        }
    }

    private var cricketSetsChip: some View {
        SetupOptionChipHelpers.chip(titleKey: "play.setup.chip.sets", color: Brand.key, dynamicTypeSize: dynamicTypeSize) {
            Menu {
                ForEach(1 ... 5, id: \.self) { value in
                    Button("\(value)") {
                        setupViewModel.cricketSetsToWin = value
                        setupViewModel.cricketSetsEnabled = value > 1
                        setupViewModel.revalidate()
                    }
                }
            } label: {
                SetupOptionChipHelpers.chipBox(
                    "\(setupViewModel.cricketSetsEnabled ? setupViewModel.cricketSetsToWin : 1)",
                    color: Brand.key,
                    dynamicTypeSize: dynamicTypeSize, showsMenuIndicator: true
                )
            }
            .accessibilityLabel(
                SetupOptionChipHelpers.chipAccessibilityLabel(
                    "play.setup.chip.sets",
                    "\(setupViewModel.cricketSetsEnabled ? setupViewModel.cricketSetsToWin : 1)"
                )
            )
            .accessibilityIdentifier("setup_cricketSetsChip")
        }
    }

    private var cricketLegsChip: some View {
        SetupOptionChipHelpers.chip(titleKey: "play.setup.chip.legs", color: Brand.key, dynamicTypeSize: dynamicTypeSize) {
            Menu {
                ForEach(1 ... 9, id: \.self) { value in
                    Button("\(value)") {
                        setupViewModel.cricketLegsToWin = value
                        setupViewModel.revalidate()
                    }
                    .accessibilityIdentifier("setup_cricketLegsOption_\(value)")
                }
            } label: {
                SetupOptionChipHelpers.chipBox("\(setupViewModel.cricketLegsToWin)", color: Brand.key, dynamicTypeSize: dynamicTypeSize, showsMenuIndicator: true)
            }
            .accessibilityLabel(SetupOptionChipHelpers.chipAccessibilityLabel("play.setup.chip.legs", "\(setupViewModel.cricketLegsToWin)"))
            .accessibilityIdentifier("setup_cricketLegsChip")
        }
    }
}

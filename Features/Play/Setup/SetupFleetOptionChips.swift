import SwiftUI

struct SetupFleetOptionChips: View {
    @ObservedObject var setupViewModel: MatchSetupViewModel
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

@ViewBuilder
    var body: some View {
        if dynamicTypeSize.isAccessibilitySize {
            LazyVGrid(columns: [GridItem(.flexible(), spacing: DS.Spacing.s3)], spacing: DS.Spacing.s3) {
                fleetPresetChip
                fleetShipCountChip
                fleetShipHealthChip
                fleetBullChip
                fleetCallModeChip
                fleetSonarChip
            }
        } else {
            VStack(spacing: DS.Spacing.s3) {
                HStack(spacing: DS.Spacing.s3) {
                    fleetPresetChip
                    fleetShipCountChip
                }
                HStack(spacing: DS.Spacing.s3) {
                    fleetShipHealthChip
                    fleetBullChip
                }
                HStack(spacing: DS.Spacing.s3) {
                    fleetCallModeChip
                    fleetSonarChip
                }
            }
        }
    }

    private var fleetPresetChip: some View {
        let value = L10n.string(FleetSetupPreferences.loadPreset().titleKey)
        return SetupOptionChipHelpers.chip(titleKey: "play.fleet.setup.preset", color: Brand.key, dynamicTypeSize: dynamicTypeSize) {
            Menu {
                ForEach(FleetSetupPreferences.Preset.allCases, id: \.rawValue) { preset in
                    Button(L10n.string(preset.titleKey)) {
                        FleetSetupPreferences.save(preset: preset)
                        setupViewModel.revalidate()
                    }
                }
            } label: {
                SetupOptionChipHelpers.chipBox(value, color: Brand.key, dynamicTypeSize: dynamicTypeSize, showsMenuIndicator: true)
            }
            .accessibilityLabel(
                SetupOptionChipHelpers.chipAccessibilityLabel("play.fleet.setup.preset", value)
            )
            .accessibilityIdentifier("setup_fleetPresetChip")
        }
    }

    private var fleetShipCountChip: some View {
        let value = "\(FleetSetupPreferences.loadShipCount().count)"
        return SetupOptionChipHelpers.chip(titleKey: "play.fleet.setup.shipCountLabel", color: Brand.key, dynamicTypeSize: dynamicTypeSize) {
            Menu {
                ForEach(FleetShipCount.allCases, id: \.rawValue) { count in
                    Button("\(count.count)") {
                        FleetSetupPreferences.save(shipCount: count)
                        setupViewModel.revalidate()
                    }
                }
            } label: {
                SetupOptionChipHelpers.chipBox(value, color: Brand.key, dynamicTypeSize: dynamicTypeSize, showsMenuIndicator: true)
            }
            .accessibilityLabel(
                SetupOptionChipHelpers.chipAccessibilityLabel("play.fleet.setup.shipCountLabel", value)
            )
            .accessibilityIdentifier("setup_fleetShipCountChip")
        }
    }

    private var fleetShipHealthChip: some View {
        let health = FleetSetupPreferences.loadShipHealth()
        let value = health == .fragile
            ? L10n.string("play.fleet.setup.shipHealth.fragile")
            : L10n.string("play.fleet.setup.shipHealth.armored")
        return SetupOptionChipHelpers.chip(titleKey: "play.fleet.setup.shipHealth", color: Brand.key, dynamicTypeSize: dynamicTypeSize) {
            Menu {
                Button(L10n.string("play.fleet.setup.shipHealth.fragile")) {
                    FleetSetupPreferences.save(shipHealth: .fragile)
                }
                Button(L10n.string("play.fleet.setup.shipHealth.armored")) {
                    FleetSetupPreferences.save(shipHealth: .armored)
                }
            } label: {
                SetupOptionChipHelpers.chipBox(value, color: Brand.key, dynamicTypeSize: dynamicTypeSize, showsMenuIndicator: true)
            }
            .accessibilityLabel(
                SetupOptionChipHelpers.chipAccessibilityLabel("play.fleet.setup.shipHealth", value)
            )
            .accessibilityIdentifier("setup_fleetShipHealthChip")
        }
    }

    private var fleetBullChip: some View {
        let value = FleetSetupPreferences.loadBullAllowed() ? L10n.string("common.on") : L10n.string("common.off")
        return SetupOptionChipHelpers.chip(titleKey: "play.fleet.setup.bullAllowed", color: Brand.key, dynamicTypeSize: dynamicTypeSize) {
            Menu {
                Button(L10n.string("common.on")) { FleetSetupPreferences.save(bullAllowed: true) }
                Button(L10n.string("common.off")) { FleetSetupPreferences.save(bullAllowed: false) }
            } label: {
                SetupOptionChipHelpers.chipBox(
                    value,
                    color: Brand.key,
                    dynamicTypeSize: dynamicTypeSize, showsMenuIndicator: true
                )
            }
            .accessibilityLabel(
                SetupOptionChipHelpers.chipAccessibilityLabel("play.fleet.setup.bullAllowed", value)
            )
            .accessibilityIdentifier("setup_fleetBullChip")
        }
    }

    private var fleetCallModeChip: some View {
        let mode = FleetSetupPreferences.loadCallMode()
        let value = mode == .strict
            ? L10n.string("play.fleet.setup.callMode.strict")
            : L10n.string("play.fleet.setup.callMode.callOnly")
        return SetupOptionChipHelpers.chip(titleKey: "play.fleet.setup.callMode", color: Brand.key, dynamicTypeSize: dynamicTypeSize) {
            Menu {
                Button(L10n.string("play.fleet.setup.callMode.strict")) {
                    FleetSetupPreferences.save(callMode: .strict)
                }
                Button(L10n.string("play.fleet.setup.callMode.callOnly")) {
                    FleetSetupPreferences.save(callMode: .callOnly)
                }
            } label: {
                SetupOptionChipHelpers.chipBox(value, color: Brand.key, dynamicTypeSize: dynamicTypeSize, showsMenuIndicator: true)
            }
            .accessibilityLabel(
                SetupOptionChipHelpers.chipAccessibilityLabel("play.fleet.setup.callMode", value)
            )
            .accessibilityIdentifier("setup_fleetCallModeChip")
        }
    }

    private var fleetSonarChip: some View {
        let value = FleetSetupPreferences.loadSonarEnabled() ? L10n.string("common.on") : L10n.string("common.off")
        return SetupOptionChipHelpers.chip(titleKey: "play.fleet.setup.sonarEnabled", color: Brand.key, dynamicTypeSize: dynamicTypeSize) {
            Menu {
                Button(L10n.string("common.on")) { FleetSetupPreferences.save(sonarEnabled: true) }
                Button(L10n.string("common.off")) { FleetSetupPreferences.save(sonarEnabled: false) }
            } label: {
                SetupOptionChipHelpers.chipBox(
                    value,
                    color: Brand.key,
                    dynamicTypeSize: dynamicTypeSize, showsMenuIndicator: true
                )
            }
            .accessibilityLabel(
                SetupOptionChipHelpers.chipAccessibilityLabel("play.fleet.setup.sonarEnabled", value)
            )
            .accessibilityIdentifier("setup_fleetSonarChip")
        }
    }
}

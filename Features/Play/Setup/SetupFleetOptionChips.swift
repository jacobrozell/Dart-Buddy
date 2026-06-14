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
        SetupOptionChipHelpers.chip(titleKey: "play.fleet.setup.preset", color: Brand.proBot, dynamicTypeSize: dynamicTypeSize) {
            Menu {
                ForEach(FleetSetupPreferences.Preset.allCases, id: \.rawValue) { preset in
                    Button(L10n.string(preset.titleKey)) {
                        FleetSetupPreferences.save(preset: preset)
                        setupViewModel.revalidate()
                    }
                }
            } label: {
                SetupOptionChipHelpers.chipBox(L10n.string(FleetSetupPreferences.loadPreset().titleKey), color: Brand.proBot, dynamicTypeSize: dynamicTypeSize, showsMenuIndicator: true)
            }
            .accessibilityIdentifier("setup_fleetPresetChip")
        }
    }

    private var fleetShipCountChip: some View {
        SetupOptionChipHelpers.chip(titleKey: "play.fleet.setup.shipCountLabel", color: Brand.key, dynamicTypeSize: dynamicTypeSize) {
            Menu {
                ForEach(FleetShipCount.allCases, id: \.rawValue) { count in
                    Button("\(count.count)") {
                        FleetSetupPreferences.save(shipCount: count)
                        setupViewModel.revalidate()
                    }
                }
            } label: {
                SetupOptionChipHelpers.chipBox("\(FleetSetupPreferences.loadShipCount().count)", color: Brand.key, dynamicTypeSize: dynamicTypeSize, showsMenuIndicator: true)
            }
            .accessibilityIdentifier("setup_fleetShipCountChip")
        }
    }

    private var fleetShipHealthChip: some View {
        SetupOptionChipHelpers.chip(titleKey: "play.fleet.setup.shipHealth", color: Brand.amber, dynamicTypeSize: dynamicTypeSize) {
            Menu {
                Button(L10n.string("play.fleet.setup.shipHealth.fragile")) {
                    FleetSetupPreferences.save(shipHealth: .fragile)
                }
                Button(L10n.string("play.fleet.setup.shipHealth.armored")) {
                    FleetSetupPreferences.save(shipHealth: .armored)
                }
            } label: {
                let health = FleetSetupPreferences.loadShipHealth()
                let label = health == .fragile
                    ? L10n.string("play.fleet.setup.shipHealth.fragile")
                    : L10n.string("play.fleet.setup.shipHealth.armored")
                SetupOptionChipHelpers.chipBox(label, color: Brand.amber, dynamicTypeSize: dynamicTypeSize, showsMenuIndicator: true)
            }
            .accessibilityIdentifier("setup_fleetShipHealthChip")
        }
    }

    private var fleetBullChip: some View {
        SetupOptionChipHelpers.chip(titleKey: "play.fleet.setup.bullAllowed", color: Brand.green, dynamicTypeSize: dynamicTypeSize) {
            Menu {
                Button(L10n.string("common.on")) { FleetSetupPreferences.save(bullAllowed: true) }
                Button(L10n.string("common.off")) { FleetSetupPreferences.save(bullAllowed: false) }
            } label: {
                SetupOptionChipHelpers.chipBox(
                    FleetSetupPreferences.loadBullAllowed() ? L10n.string("common.on") : L10n.string("common.off"),
                    color: Brand.green,
                    dynamicTypeSize: dynamicTypeSize, showsMenuIndicator: true
                )
            }
            .accessibilityIdentifier("setup_fleetBullChip")
        }
    }

    private var fleetCallModeChip: some View {
        SetupOptionChipHelpers.chip(titleKey: "play.fleet.setup.callMode", color: Brand.orange, dynamicTypeSize: dynamicTypeSize) {
            Menu {
                Button(L10n.string("play.fleet.setup.callMode.strict")) {
                    FleetSetupPreferences.save(callMode: .strict)
                }
                Button(L10n.string("play.fleet.setup.callMode.callOnly")) {
                    FleetSetupPreferences.save(callMode: .callOnly)
                }
            } label: {
                let mode = FleetSetupPreferences.loadCallMode()
                let label = mode == .strict
                    ? L10n.string("play.fleet.setup.callMode.strict")
                    : L10n.string("play.fleet.setup.callMode.callOnly")
                SetupOptionChipHelpers.chipBox(label, color: Brand.orange, dynamicTypeSize: dynamicTypeSize, showsMenuIndicator: true)
            }
            .accessibilityIdentifier("setup_fleetCallModeChip")
        }
    }

    private var fleetSonarChip: some View {
        SetupOptionChipHelpers.chip(titleKey: "play.fleet.setup.sonarEnabled", color: Brand.proBot, dynamicTypeSize: dynamicTypeSize) {
            Menu {
                Button(L10n.string("common.on")) { FleetSetupPreferences.save(sonarEnabled: true) }
                Button(L10n.string("common.off")) { FleetSetupPreferences.save(sonarEnabled: false) }
            } label: {
                SetupOptionChipHelpers.chipBox(
                    FleetSetupPreferences.loadSonarEnabled() ? L10n.string("common.on") : L10n.string("common.off"),
                    color: Brand.proBot,
                    dynamicTypeSize: dynamicTypeSize, showsMenuIndicator: true
                )
            }
            .accessibilityIdentifier("setup_fleetSonarChip")
        }
    }
}

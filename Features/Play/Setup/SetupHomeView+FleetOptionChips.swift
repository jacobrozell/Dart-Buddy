import SwiftUI

extension SetupHomeView {
    @ViewBuilder
    var fleetChipsGrid: some View {
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
        chip(titleKey: "play.fleet.setup.preset", color: Brand.proBot) {
            Menu {
                ForEach(FleetSetupPreferences.Preset.allCases, id: \.rawValue) { preset in
                    Button(L10n.string(preset.titleKey)) {
                        FleetSetupPreferences.save(preset: preset)
                        setupViewModel.revalidate()
                    }
                }
            } label: {
                chipBox(L10n.string(FleetSetupPreferences.loadPreset().titleKey), color: Brand.proBot, showsMenuIndicator: true)
            }
            .accessibilityIdentifier("setup_fleetPresetChip")
        }
    }

    private var fleetShipCountChip: some View {
        chip(titleKey: "play.fleet.setup.shipCountLabel", color: Brand.key) {
            Menu {
                ForEach(FleetShipCount.allCases, id: \.rawValue) { count in
                    Button("\(count.count)") {
                        FleetSetupPreferences.save(shipCount: count)
                        setupViewModel.revalidate()
                    }
                }
            } label: {
                chipBox("\(FleetSetupPreferences.loadShipCount().count)", color: Brand.key, showsMenuIndicator: true)
            }
            .accessibilityIdentifier("setup_fleetShipCountChip")
        }
    }

    private var fleetShipHealthChip: some View {
        chip(titleKey: "play.fleet.setup.shipHealth", color: Brand.amber) {
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
                chipBox(label, color: Brand.amber, showsMenuIndicator: true)
            }
            .accessibilityIdentifier("setup_fleetShipHealthChip")
        }
    }

    private var fleetBullChip: some View {
        chip(titleKey: "play.fleet.setup.bullAllowed", color: Brand.green) {
            Menu {
                Button(L10n.string("common.on")) { FleetSetupPreferences.save(bullAllowed: true) }
                Button(L10n.string("common.off")) { FleetSetupPreferences.save(bullAllowed: false) }
            } label: {
                chipBox(
                    FleetSetupPreferences.loadBullAllowed() ? L10n.string("common.on") : L10n.string("common.off"),
                    color: Brand.green,
                    showsMenuIndicator: true
                )
            }
            .accessibilityIdentifier("setup_fleetBullChip")
        }
    }

    private var fleetCallModeChip: some View {
        chip(titleKey: "play.fleet.setup.callMode", color: Brand.orange) {
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
                chipBox(label, color: Brand.orange, showsMenuIndicator: true)
            }
            .accessibilityIdentifier("setup_fleetCallModeChip")
        }
    }

    private var fleetSonarChip: some View {
        chip(titleKey: "play.fleet.setup.sonarEnabled", color: Brand.proBot) {
            Menu {
                Button(L10n.string("common.on")) { FleetSetupPreferences.save(sonarEnabled: true) }
                Button(L10n.string("common.off")) { FleetSetupPreferences.save(sonarEnabled: false) }
            } label: {
                chipBox(
                    FleetSetupPreferences.loadSonarEnabled() ? L10n.string("common.on") : L10n.string("common.off"),
                    color: Brand.proBot,
                    showsMenuIndicator: true
                )
            }
            .accessibilityIdentifier("setup_fleetSonarChip")
        }
    }
}

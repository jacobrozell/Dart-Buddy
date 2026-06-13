import SwiftUI

extension SetupHomeView {
    @ViewBuilder
    var raidChipsGrid: some View {
        if dynamicTypeSize.isAccessibilitySize {
            LazyVGrid(columns: [GridItem(.flexible(), spacing: DS.Spacing.s3)], spacing: DS.Spacing.s3) {
                raidBossTierChip
                raidHeroHeartsChip
                raidEnrageChip
            }
        } else {
            HStack(spacing: DS.Spacing.s3) {
                raidBossTierChip
                raidHeroHeartsChip
                raidEnrageChip
            }
        }
    }

    private var raidBossTierChip: some View {
        chip(titleKey: "play.raid.setup.bossTier", color: Brand.amber) {
            Menu {
                ForEach(RaidBossTier.allCases, id: \.rawValue) { tier in
                    Button(L10n.string(tier.displayNameKey)) {
                        RaidSetupPreferences.save(bossTier: tier)
                        setupViewModel.revalidate()
                    }
                }
            } label: {
                chipBox(L10n.string(RaidSetupPreferences.loadBossTier().displayNameKey), color: Brand.amber, showsMenuIndicator: true)
            }
            .accessibilityIdentifier("setup_raidBossTierChip")
        }
    }

    private var raidHeroHeartsChip: some View {
        chip(titleKey: "play.raid.setup.heroHearts", color: Brand.redAccent) {
            Menu {
                ForEach([3, 4, 5], id: \.self) { hearts in
                    Button("\(hearts)") {
                        RaidSetupPreferences.save(heroHearts: hearts)
                        setupViewModel.revalidate()
                    }
                }
            } label: {
                chipBox("\(RaidSetupPreferences.loadHeroHearts())", color: Brand.redAccent, showsMenuIndicator: true)
            }
            .accessibilityIdentifier("setup_raidHeroHeartsChip")
        }
    }

    private var raidEnrageChip: some View {
        chip(titleKey: "play.raid.setup.enrageEnabled", color: Brand.orange) {
            Menu {
                Button(L10n.string("common.on")) { RaidSetupPreferences.save(enrageEnabled: true) }
                Button(L10n.string("common.off")) { RaidSetupPreferences.save(enrageEnabled: false) }
            } label: {
                chipBox(
                    RaidSetupPreferences.loadEnrageEnabled() ? L10n.string("common.on") : L10n.string("common.off"),
                    color: Brand.orange,
                    showsMenuIndicator: true
                )
            }
            .accessibilityIdentifier("setup_raidEnrageChip")
        }
    }
}

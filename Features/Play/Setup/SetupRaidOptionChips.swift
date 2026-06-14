import SwiftUI

struct SetupRaidOptionChips: View {
    @ObservedObject var setupViewModel: MatchSetupViewModel
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

@ViewBuilder
    var body: some View {
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
        SetupOptionChipHelpers.chip(titleKey: "play.raid.setup.bossTier", color: Brand.amber, dynamicTypeSize: dynamicTypeSize) {
            Menu {
                ForEach(RaidBossTier.allCases, id: \.rawValue) { tier in
                    Button(L10n.string(tier.displayNameKey)) {
                        RaidSetupPreferences.save(bossTier: tier)
                        setupViewModel.revalidate()
                    }
                }
            } label: {
                SetupOptionChipHelpers.chipBox(L10n.string(RaidSetupPreferences.loadBossTier().displayNameKey), color: Brand.amber, dynamicTypeSize: dynamicTypeSize, showsMenuIndicator: true)
            }
            .accessibilityIdentifier("setup_raidBossTierChip")
        }
    }

    private var raidHeroHeartsChip: some View {
        SetupOptionChipHelpers.chip(titleKey: "play.raid.setup.heroHearts", color: Brand.redAccent, dynamicTypeSize: dynamicTypeSize) {
            Menu {
                ForEach([3, 4, 5], id: \.self) { hearts in
                    Button("\(hearts)") {
                        RaidSetupPreferences.save(heroHearts: hearts)
                        setupViewModel.revalidate()
                    }
                }
            } label: {
                SetupOptionChipHelpers.chipBox("\(RaidSetupPreferences.loadHeroHearts())", color: Brand.redAccent, dynamicTypeSize: dynamicTypeSize, showsMenuIndicator: true)
            }
            .accessibilityIdentifier("setup_raidHeroHeartsChip")
        }
    }

    private var raidEnrageChip: some View {
        SetupOptionChipHelpers.chip(titleKey: "play.raid.setup.enrageEnabled", color: Brand.orange, dynamicTypeSize: dynamicTypeSize) {
            Menu {
                Button(L10n.string("common.on")) { RaidSetupPreferences.save(enrageEnabled: true) }
                Button(L10n.string("common.off")) { RaidSetupPreferences.save(enrageEnabled: false) }
            } label: {
                SetupOptionChipHelpers.chipBox(
                    RaidSetupPreferences.loadEnrageEnabled() ? L10n.string("common.on") : L10n.string("common.off"),
                    color: Brand.orange,
                    dynamicTypeSize: dynamicTypeSize, showsMenuIndicator: true
                )
            }
            .accessibilityIdentifier("setup_raidEnrageChip")
        }
    }
}

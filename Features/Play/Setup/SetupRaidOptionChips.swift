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
        let value = L10n.string(RaidSetupPreferences.loadBossTier().displayNameKey)
        return SetupOptionChipHelpers.chip(titleKey: "play.raid.setup.bossTier", color: Brand.key, dynamicTypeSize: dynamicTypeSize) {
            Menu {
                ForEach(RaidBossTier.allCases, id: \.rawValue) { tier in
                    Button(L10n.string(tier.displayNameKey)) {
                        RaidSetupPreferences.save(bossTier: tier)
                        setupViewModel.revalidate()
                    }
                }
            } label: {
                SetupOptionChipHelpers.chipBox(value, color: Brand.key, dynamicTypeSize: dynamicTypeSize, showsMenuIndicator: true)
            }
            .accessibilityLabel(SetupOptionChipHelpers.chipAccessibilityLabel("play.raid.setup.bossTier", value))
            .accessibilityIdentifier("setup_raidBossTierChip")
        }
    }

    private var raidHeroHeartsChip: some View {
        let value = "\(RaidSetupPreferences.loadHeroHearts())"
        return SetupOptionChipHelpers.chip(titleKey: "play.raid.setup.heroHearts", color: Brand.key, dynamicTypeSize: dynamicTypeSize) {
            Menu {
                ForEach([3, 4, 5], id: \.self) { hearts in
                    Button("\(hearts)") {
                        RaidSetupPreferences.save(heroHearts: hearts)
                        setupViewModel.revalidate()
                    }
                }
            } label: {
                SetupOptionChipHelpers.chipBox(value, color: Brand.key, dynamicTypeSize: dynamicTypeSize, showsMenuIndicator: true)
            }
            .accessibilityLabel(SetupOptionChipHelpers.chipAccessibilityLabel("play.raid.setup.heroHearts", value))
            .accessibilityIdentifier("setup_raidHeroHeartsChip")
        }
    }

    private var raidEnrageChip: some View {
        let value = RaidSetupPreferences.loadEnrageEnabled()
            ? L10n.string("common.on")
            : L10n.string("common.off")
        return SetupOptionChipHelpers.chip(titleKey: "play.raid.setup.enrageEnabled", color: Brand.key, dynamicTypeSize: dynamicTypeSize) {
            Menu {
                Button(L10n.string("common.on")) {
                    RaidSetupPreferences.save(enrageEnabled: true)
                    setupViewModel.revalidate()
                }
                Button(L10n.string("common.off")) {
                    RaidSetupPreferences.save(enrageEnabled: false)
                    setupViewModel.revalidate()
                }
            } label: {
                SetupOptionChipHelpers.chipBox(value, color: Brand.key, dynamicTypeSize: dynamicTypeSize, showsMenuIndicator: true)
            }
            .accessibilityLabel(SetupOptionChipHelpers.chipAccessibilityLabel("play.raid.setup.enrageEnabled", value))
            .accessibilityIdentifier("setup_raidEnrageChip")
        }
    }
}

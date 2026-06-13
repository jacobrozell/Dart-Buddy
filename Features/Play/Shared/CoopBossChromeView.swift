import SwiftUI

struct CoopBossChromeView: View {
    let bossHP: Int
    let bossMaxHP: Int
    let phase: RaidPhase
    let enrageActive: Bool
    let heroes: [CoopHeroHeartRow]

    struct CoopHeroHeartRow: Identifiable {
        let id: UUID
        let name: String
        let hearts: Int
        let maxHearts: Int
        let isDown: Bool
        let isActive: Bool
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s2) {
            bossHPBar
            HStack(spacing: DS.Spacing.s2) {
                phaseBanner
                if enrageActive {
                    enrageBadge
                }
                Spacer(minLength: 0)
            }
            heroHeartsStrip
        }
        .padding(DS.Spacing.s3)
        .background(Brand.cardElevated, in: RoundedRectangle(cornerRadius: DS.Radius.md))
    }

    private var bossHPBar: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(L10n.format("play.raid.bossHPFormat", bossHP, bossMaxHP))
                .font(.caption.weight(.semibold))
                .foregroundStyle(Brand.textPrimary)
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: DS.Radius.xs)
                        .fill(Brand.card)
                    RoundedRectangle(cornerRadius: DS.Radius.xs)
                        .fill(Brand.redAccent)
                        .frame(width: proxy.size.width * CGFloat(bossHP) / CGFloat(max(bossMaxHP, 1)))
                }
            }
            .frame(height: 12)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(L10n.format("play.raid.bossHPAccessibilityFormat", bossHP, bossMaxHP))
        .accessibilityIdentifier("coop_boss_hp_bar")
    }

    private var phaseBanner: some View {
        HStack(spacing: 4) {
            Image(systemName: phase == .shield ? "shield.fill" : "scope")
                .accessibilityHidden(true)
            Text(phase == .shield ? L10n.string("play.raid.phase.shield") : L10n.string("play.raid.phase.expose"))
                .font(.caption.weight(.semibold))
        }
        .foregroundStyle(Brand.textPrimary)
        .padding(.horizontal, DS.Spacing.s2)
        .padding(.vertical, DS.Spacing.s1)
        .background(Brand.amber.opacity(0.2), in: Capsule())
        .accessibilityIdentifier("coop_boss_phase_banner")
    }

    private var enrageBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "flame.fill")
                .accessibilityHidden(true)
            Text(L10n.string("play.raid.phase.enrage"))
                .font(.caption.weight(.semibold))
        }
        .foregroundStyle(Brand.orange)
        .padding(.horizontal, DS.Spacing.s2)
        .padding(.vertical, DS.Spacing.s1)
        .background(Brand.orange.opacity(0.16), in: Capsule())
    }

    private var heroHeartsStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DS.Spacing.s3) {
                ForEach(heroes) { hero in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(hero.name)
                            .font(.caption2.weight(hero.isActive ? .bold : .regular))
                            .foregroundStyle(hero.isDown ? Brand.textSecondary : Brand.textPrimary)
                            .strikethrough(hero.isDown)
                        HStack(spacing: 2) {
                            Image(systemName: hero.isDown ? "heart.slash" : "heart.fill")
                                .font(.caption2)
                                .foregroundStyle(hero.isDown ? Brand.textSecondary : Brand.redAccent)
                            Text(L10n.format("play.raid.heartsAccessibilityFormat", hero.hearts, hero.maxHearts))
                                .font(.caption2)
                                .foregroundStyle(hero.isDown ? Brand.textSecondary : Brand.textPrimary)
                        }
                    }
                    .padding(.horizontal, DS.Spacing.s2)
                    .padding(.vertical, DS.Spacing.s1)
                    .background(hero.isActive ? Brand.green.opacity(0.12) : Color.clear, in: RoundedRectangle(cornerRadius: DS.Radius.xs))
                }
            }
        }
        .accessibilityIdentifier("coop_hero_hearts")
    }
}

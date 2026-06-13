# Raid Match

| Field | Value |
|-------|-------|
| Screen ID | `raid-match` |
| Primary source | `Features/Play/Raid/RaidMatchScreen.swift`, `Features/Play/Shared/CoopBossChromeView.swift` |
| Core flow | Yes (co-op boss fight; shipped via `coop.raid`) |
| Last verified | 2026-06-12 |
| Screen status | `Partial` |

## Criterion checklist

| ID | Status | Implementation notes | Evidence |
|----|--------|----------------------|----------|
| P-1.1.1 | Partial | Boss HP bar, phase banner, hero hearts, full-board pad, submit/undo | `coop_boss_hp_bar`, `coop_boss_phase_banner`, `coop_hero_hearts` |
| P-1.3.1 | Partial | Boss HP and hearts use formatted accessibility labels | `play.raid.bossHPAccessibilityFormat`, `play.raid.heartsAccessibilityFormat` |
| P-1.3.2 | Partial | Boss chrome above pad; manual VO order pending | |
| P-1.3.4 | Untested | One-screen fit on phone | |
| P-1.4.1 | Partial | Phase banner uses icon + text (Shield / Expose / Enrage) | |
| P-1.4.3 | Partial | Brand semantic colors on gameplay shell | |
| P-1.4.4 | Untested | Dynamic Type on boss chrome and pad | |
| P-1.4.10 | Untested | Scroll on compact heights | |
| P-1.4.11 | Partial | Pad keys meet 44pt target | |
| O-2.4.3 | Partial | AX structure OK; manual VO pending | |
| O-2.4.4 | Pass | Undo + submit localized labels | |
| O-2.5.3 | Partial | Phase change and enrage announcements posted to VoiceOver | |
| DBX-TARGET-44 | Partial | Pad keys 52pt | |
| U-3.1.1 | Pass | Turn header announces current hero and boss HP | |
| U-3.3.1 | Pass | Team victory/defeat announcements on match end | |
| U-3.3.2 | Partial | Enrage strike announcement | |
| R-4.1.2 | Pass | `coop_boss_hp_bar`, `coop_boss_phase_banner`, `coop_hero_hearts` | |
| DBX-CONTRAST-MODES | Partial | Amber co-op accent + Brand tokens | |

## Co-op summary (post-match)

| Element | Identifier | Notes |
|---------|------------|-------|
| Team headline | `matchSummaryCoopHeadline` | No trophy; team outcome only |
| Subheadline | `matchSummaryCoopSubheadline` | Boss tier + hearts or HP left |
| MVP row | `matchSummaryCoopMVP` | Optional when damage dealt |
| Rematch CTA | `matchSummaryRematch` | Label: "Raid again" |

## Open work

- [ ] Manual VoiceOver pass — shield vs expose pad hints (`accessibility/Manual_todo.md`)
- [ ] AXXXL + landscape boss chrome readability
- [ ] UI test smoke for raid match identifiers

## Verification log

| Date | Verifier | Result | Notes |
|------|----------|--------|-------|
| 2026-06-12 | Agent | Partial | Initial screen doc at Raid ship |

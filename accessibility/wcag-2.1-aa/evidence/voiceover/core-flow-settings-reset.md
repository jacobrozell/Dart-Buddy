# Core flow — Settings destructive reset

Repeatable VoiceOver QA script. Pair with [`settings-reset-ax-spotcheck-2026-06-06.md`](settings-reset-ax-spotcheck-2026-06-06.md).

## Preconditions

- Test device or simulator with seeded data (`-seed_players` or `-seed_demo`)  
- VoiceOver enabled (or Accessibility Inspector)

## Steps

| # | Action | Expected announcement |
|---|--------|------------------------|
| 1 | Open Settings tab | “Settings, tab, one of five” |
| 2 | Swipe through sections | Headers: Appearance → Starting Mode → Match Defaults → X01 Defaults → During Play → Bot Opponents → Data → About |
| 3 | Find Reset all data | “Reset all data, button” (not the long visible title) |
| 4 | Double-tap reset | Alert: “Reset all local data?” + message listing players, matches, settings, preferences, welcome tour |
| 5 | Swipe actions | Cancel, then Reset Data (destructive tone on device) |
| 6 | Double-tap Cancel | Alert dismisses; focus on Settings |
| 7 | (Optional destructive) Repeat → Reset Data | App resets; Play tab or onboarding appears; no crash |

## Pass criteria

- [ ] Destructive action never fires without confirmation  
- [ ] Message states full scope of data loss  
- [ ] Cancel is reachable before Reset Data  
- [ ] No focus trap in alert  
- [ ] Post-reset state is navigable with VoiceOver

## Locales to spot-check

| Locale | Settings tab | Reset row (VO) | Confirm button |
|--------|--------------|----------------|----------------|
| en | Settings | Reset all data | Reset Data |
| de | Einstellungen | Alle Daten zurücksetzen | Daten zurücksetzen |
| es | Ajustes | Restablecer todos los datos | Restablecer datos |
| nl | Instellingen | Alle gegevens wissen | Gegevens wissen |

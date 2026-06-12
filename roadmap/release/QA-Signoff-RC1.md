# QA Sign-off (RC1)

**Ship checklist:** [`../../docs/release/1.0.0-ship-checklist.md`](../../docs/release/1.0.0-ship-checklist.md) · **Nutrition labels script:** [`../../accessibility/1.0-nutrition-label-checklist.md`](../../accessibility/1.0-nutrition-label-checklist.md)

## Candidate
- Version: `1.0.0-rc1`
- Build: `TBD`
- Device(s): `TBD - minimum 1 physical iPhone + 1 simulator`
- iOS version(s): `18.x minimum` (ship target) + latest GA + **iOS 26 simulator** (Liquid Glass nav spot-check)
- Execution owner: `TBD`
- Execution date: `TBD`

## Evidence Rules
- Mark each check as `Pass`, `Fail`, or `Blocked` (do not leave `Pending` once executed).
- For each `Fail`/`Blocked`, add a defect ID and owner in the Defects section.
- Record screenshot/video/log reference for each matrix group.

## Core Flow Matrix
- Setup -> X01 -> Summary: **Pending execution**
- Setup -> Cricket -> Summary: **Pending execution**
- Resume active match: **Pending execution**
- Undo flow (X01/Cricket): **Pending execution**
- History list/detail: **Pending execution**
- Statistics tab (filters + table): **Pending execution**
- Players archive/delete guard: **Pending execution**
- Settings reset flow: **Pending execution**

## Core Flow Execution Log
- Setup -> X01 -> Summary: status=`Pending`, evidence=`TBD`, notes=`TBD`
- Setup -> Cricket -> Summary: status=`Pending`, evidence=`TBD`, notes=`TBD`
- Resume active match: status=`Pending`, evidence=`TBD`, notes=`TBD`
- Undo flow (X01/Cricket): status=`Pending`, evidence=`TBD`, notes=`TBD`
- History list/detail: status=`Pending`, evidence=`TBD`, notes=`TBD`
- Statistics tab: status=`Pending`, evidence=`TBD`, notes=`TBD`
- Players archive/delete guard: status=`Pending`, evidence=`TBD`, notes=`TBD`
- Settings reset flow: status=`Pending`, evidence=`TBD`, notes=`TBD`

## iOS 26 Liquid Glass (navigation chrome — P1, non-blocking for 18+ ship)

Simulator on **iOS 26+**; policy: `SystemNavigationPolicy`. Evidence: `accessibility/wcag-2.1-aa/evidence/ios26-liquid-glass/`.

- Tab bar renders system glass (not opaque override) on all five tabs: **Partial** — 2026-06-11 iPhone 17 Pro, iOS 26.4: `tab-play`, `tab-players`, `tab-activity`, `tab-settings` (lean surface; Modes tab N/A)
- Settings pushed flows / sheets: nav chrome acceptable: **Pending execution**
- Reduce Transparency: tab bar + Settings usable (automated: `testSettingsPassesAuditsWithReduceTransparency`): **Pending execution**
- Scoreboard tabs remain opaque on `Brand.background` (no `.glassEffect` on content): **Partial** — Play/Players/Activity screenshots show opaque brand layer above translucent tab bar

## Appearance and Orientation
- Portrait + Light: **Pending execution**
- Portrait + Dark: **Pending execution**
- Landscape + Light: **Pending execution**
- Landscape + Dark: **Pending execution**

## Appearance Matrix Evidence
- Portrait + Light: status=`Pending`, screenshot=`TBD`
- Portrait + Dark: status=`Pending`, screenshot=`TBD`
- Landscape + Light: status=`Pending`, screenshot=`TBD`
- Landscape + Dark: status=`Pending`, screenshot=`TBD`

## Accessibility
- VoiceOver core flow pass: **Pending execution**
- Dynamic Type critical content pass: **Pending execution**
- Non-color critical meaning pass: **Pending execution**

## Accessibility Evidence
- VoiceOver core flow pass: status=`Pending`, evidence=`TBD`
- Dynamic Type critical content pass: status=`Pending`, evidence=`TBD`
- Non-color critical meaning pass: status=`Pending`, evidence=`TBD`

## Defects
- P0:
  - Missing completed RC manual evidence for required release gates.
  - Migration recovery operational validation incomplete.
- P1:
  - Performance target measurements not yet recorded on target device.
  - Orientation and accessibility matrix evidence incomplete.
- P2:
  - None currently logged.

## Sign-off
- QA owner: `TBD`
- Date: `TBD`
- Go/No-Go: **NO-GO until all P0 closed**

# VoiceOver & accessibility audit

**Date:** 2026-06-13  
**Auditor:** Cursor agent (simulator MCP + codebase review)  
**App build:** Dart Buddy on iPhone 17 simulator (`22114A58-1110-4FC7-8431-F7B84B6C7465`)  
**Launch args:** `-ui_test_reset`, `-disable_firebase_analytics`, `-seed_players`  
**Overall status:** **Not compliant** for release — see [`wcag-2.1-aa/SUMMARY.md`](../wcag-2.1-aa/SUMMARY.md). Engineering pass is strong on core X01/Cricket; manual VoiceOver and AXXXL evidence still open ([`Manual_todo.md`](../Manual_todo.md)).

---

## Method

| Source | What it checked |
|--------|-----------------|
| iOS Simulator MCP `ui_describe_all` | Full AX tree (labels, roles, identifiers, hints) |
| XcodeBuildMCP `snapshot_ui` | Actionable targets, scroll areas, ghost elements |
| WCAG tracker + source review | Known gaps, identifier contracts, less-is-more VO work |
| `WCAGAccessibilityUITests` | **Blocked** — project did not compile (`StatsService.swift` errors) |

**Screens exercised live:** Match Setup, X01 Match, Match Exit sheet, Settings (partial scroll).

**Related evidence (prior passes):**

- [`wcag-2.1-aa/evidence/voiceover/setup-home-ax-spotcheck-2026-06-02.md`](../wcag-2.1-aa/evidence/voiceover/setup-home-ax-spotcheck-2026-06-02.md)
- [`wcag-2.1-aa/evidence/voiceover/x01-less-is-more-ax-spotcheck-2026-06-10.md`](../wcag-2.1-aa/evidence/voiceover/x01-less-is-more-ax-spotcheck-2026-06-10.md)
- [`wcag-2.1-aa/evidence/voiceover/cricket-less-is-more-ax-spotcheck-2026-06-11.md`](../wcag-2.1-aa/evidence/voiceover/cricket-less-is-more-ax-spotcheck-2026-06-11.md)

---

## Executive summary

Core gameplay accessibility is in good shape: combined score-card labels, spoken pad names with modifiers, header actions, and setup CTAs largely meet R-4.1.2 / O-2.5.3. The highest-impact gaps are **VoiceOver verbosity on turn-order rows**, an **unlabeled duplicate Sets switch in Settings**, **missing identifiers** on a few setup/exit controls, and **duplicate `scoreCard` IDs** for inactive X01 players. Automated regression tests could not run due to a compile break.

---

## Findings by severity

### Critical / high

#### 1. Turn order list is too verbose for VoiceOver (Match Setup)

When players are selected, each row creates many separate focus stops instead of one combined element:

| Element | Spoken label | Identifier |
|---------|--------------|------------|
| Row summary | "Throwing position 1, Alice" | `setup_selected_Alice` |
| Position badge | "P1" | *(none)* |
| Avatar icon | "Flame" | `flame.fill` |
| Name | "Alice" | *(none)* |
| Reorder handle | "Reorder Throwing position 1" | *(none)* |
| Remove | **"Close"** | `setup_remove_Alice` |

**Impact:** A 3-player setup can require 15+ swipes through turn order alone. Remove buttons announce as "Close" instead of "Remove from match" despite `accessibilityHidden(true)` on the visible X button in source.

**Location:** `Features/Play/Setup/SetupHomeView+Roster.swift` — `selectedRosterRow` + SwiftUI `List` edit mode.

**Suggested fix:** Collapse each row to one accessibility element; hide decorative P1 / avatar / name children; rely on `accessibilityAction` for remove (partially implemented); apply `.accessibilityElement(children: .ignore)` on the outer row container.

---

#### 2. Unlabeled duplicate switch in Settings (R-4.1.2)

On Settings, the Sets toggle appears twice in the AX tree:

```
switch  "Sets"  value=0  id=settings_defaultSetsToggle
switch  ""      value=0  id=(none)
```

**Impact:** VoiceOver users encounter a silent switch — fails Name, Role, Value (WCAG 4.1.2).

**Location:** `Features/Settings/SettingsRootView.swift` — SwiftUI `Toggle` inside `Form`.

**Suggested fix:** `.accessibilityElement(children: .combine)` on the toggle row, or hide the duplicate native switch node (common SwiftUI Form workaround).

---

#### 3. Missing accessibility identifiers on setup controls

| Control | Label | Identifier |
|---------|-------|------------|
| Random order toggle | "Random order" | **Missing** |
| Add Bot menu | "Add Bot" | **Missing** |
| Ghost button | *(empty)* | **Missing** |

Roster/setup contract covers `setup_addPlayer`, `select_*`, etc., but random order and Add Bot are not in the identifier contract.

**Location:** `Features/Play/Setup/SetupHomeView+Roster.swift` — `randomOrderToggle`, bot `Menu`.

**Suggested fix:** Add `setup_randomOrderToggle`, `setup_addBot` (or equivalent); investigate empty-label button (likely Menu chrome artifact).

---

#### 4. Duplicate `scoreCard` identifiers (X01 Match)

Inactive player cards for Bob and Carol both expose `AXUniqueId: scoreCard` with distinct labels ("Bob, 501 remaining" / "Carol, 501 remaining").

**Impact:** UI tests and VoiceOver rotor cannot distinguish inactive cards by identifier. Active card correctly uses `scoreCard_active`.

**Location:** `Features/Play/X01/PlayerScoreCard.swift` (line ~59).

**Suggested fix:** Per-player IDs, e.g. `scoreCard_<name>` or `scoreCard_inactive_<index>`.

---

### Medium

#### 5. Match exit sheet — "Save & Exit" has no identifier

Exit confirmation at runtime:

| Button | Label | Identifier |
|--------|-------|------------|
| Save & Exit | "Save & Exit" | **Missing** |
| Abandon Match | "Abandon Match" | `match_exit_abandon` |

`match_exit_save_and_forfeit` is attached only to the forfeit path when `canForfeit` is true, not to "Save & Exit".

**Location:** `Features/Play/Shared/MatchLifecycleChrome.swift`.

---

#### 6. Pad key hit targets may be narrow (DBX-TARGET-44)

Number pad keys measured ~**47×52 pt** on iPhone 17. Height meets guidance; width is below the 44 pt minimum on a 7-column grid.

**Impact:** May fail automated hit-region audits; harder for motor-accessibility users.

**Location:** `Features/Play/X01/DartNumberPad.swift`, `DesignSystem/Components/ScoringPadStyle.swift`.

---

#### 7. X01 config line is a separate static text node

"501, Double Out, First to 3 Legs" is exposed without an identifier, separate from the "X01" nav title. Adds an extra VoiceOver swipe before score cards.

---

### Low / tracked elsewhere

| Gap | Tracker reference |
|-----|-------------------|
| Manual VoiceOver on all core flows | [`Manual_todo.md`](../Manual_todo.md) |
| AXXXL Dynamic Type on gameplay typography | `wcag-2.1-aa/SUMMARY.md` — P-1.4.4 Partial |
| Liquid Glass Settings contrast (iOS 26) | Tests intentionally suppress automated contrast failures |
| Party modes (Killer, Shanghai, Baseball) | Screen trackers Partial; limited UI test coverage |
| `DBX-DESIGN-SYSTEM` | Fail on `_shared-components.md` — no default a11y API on DS primitives |
| Automated regression suite | Blocked until `StatsService.swift` compiles |

---

## What passed (MCP-verified)

| Area | Runtime observation |
|------|---------------------|
| Active score card | `"Alice, 501 remaining. Your turn"` — concise combined label |
| Pad semantics | Single: `"20"`; armed double: `"Double 20"`; bull: `"Outer Bull"` / `"Double Bull"`; miss: `"Miss"` (not `"0"`) |
| Modifier keys | `pad_double` hint: "Next number will be doubled." when armed |
| Header actions | `match_exit` → "Leave match"; `match_undo` → "Undo Last Throw" |
| START CTA | Disabled hint when roster invalid; enables when players selected |
| Settings pickers | Theme, Mode, Legs, Points, Check-Out labeled + identified |
| Tab bar | Play / Players / Activity / Settings spoken labels |

Less-is-more VO trimming (2026-06-10/11) is reflected in runtime behavior for score cards and pads.

---

## Priority fix list

1. Turn order row — one VO stop per player; fix "Close" → remove action; hide decorative children  
2. Settings Sets toggle — eliminate unlabeled duplicate switch  
3. Add identifiers — `setup_randomOrderToggle`, `setup_addBot`, `match_exit_save_and_exit`  
4. Unique inactive score card IDs — replace duplicate `scoreCard`  
5. Investigate ghost empty button on setup (Menu chrome)  
6. Pad key width — 6-column grid or wider min width at default Dynamic Type  
7. Unblock build — fix `StatsService.swift` so `WCAGAccessibilityUITests` runs in CI  

---

## Manual verification still required

AX-tree tools cannot replace these ([`Manual_todo.md`](../Manual_todo.md)):

- Focus order: score cards → checkout → pad → header (X01 / Cricket)
- Bust / checkout / leg-won **announcements** (banners are visual-only by design)
- Bot-turn pad disable + "Bot throwing…" banner
- Reduce Motion on match summary trophy animation
- End-to-end: setup → match → summary (X01 and Cricket)
- Settings reset destructive flow (audio pass)
- AXXXL on setup, X01, Cricket, history, settings, players

---

## Changelog

| Date | Change |
|------|--------|
| 2026-06-13 | Engineering fixes: turn-order VO collapse, Sets toggle combine, setup/exit IDs, per-player scoreCard IDs, 44pt pad min width |

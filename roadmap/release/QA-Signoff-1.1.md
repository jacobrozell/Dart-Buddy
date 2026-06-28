# QA Sign-off (1.1.0 Party Pack)

**Ship checklist:** [`../../docs/release/1.1.0-ship-checklist.md`](../../docs/release/1.1.0-ship-checklist.md) · **RC runbook:** [`../../docs/release/1.1.0-testflight-rc-plan.md`](../../docs/release/1.1.0-testflight-rc-plan.md)

## Candidate

| Field | Value |
|-------|-------|
| Version | `1.1.0` |
| Build | `TBD` |
| Branch / commit | `release/1.1.0` @ `TBD` |
| Device(s) | Physical **iPhone** required |
| iOS version(s) | Ship target + latest GA |
| Execution owner | `TBD` |
| Execution date | `TBD` |

## Scope (lean 1.1 — locked 2026-06-23)

**In:** X01, Cricket, Baseball, Killer, Shanghai, Around the Clock · 4 tabs · preset + custom bots · English  
**Out:** Raid, Training Partner, Modes tab, export, bundled locales, App Intents

## Evidence rules

- Mark each check `Pass`, `Fail`, or `Blocked` — no `Pending` after execution.
- For `Fail`/`Blocked`, add defect ID and owner below.
- TestFlight or Release archive on device; **no launch args**.

---

## §4 Fast gate (~15 min)

| Check | Status | Evidence | Notes |
|-------|--------|----------|-------|
| App launches; four tabs; no Modes | Pending | | |
| Change mode → six modes only | Pending | | |
| English UI with device language de/es/nl | Pending | | |
| No Training Partner / export affordances | Pending | | |

**Decision:** [ ] PASS · [ ] FAIL

---

## §5 Core regression (1.0 carry-forward)

| Check | Status | Evidence | Notes |
|-------|--------|----------|-------|
| X01: start → score → undo → leg → summary | Pending | | |
| Cricket Normal + Cut Throat | Pending | | |
| Activity: History + Statistics + filters | Pending | | |
| Settings: toggle persists; reset all local data | Pending | | |
| Resume active X01 from Play home | Pending | | |
| Custom bot in Add Bot menu | Pending | | |

---

## §6 New 1.1 modes (P0)

### Baseball (2+ players)

| Check | Status | Evidence | Notes |
|-------|--------|----------|-------|
| Setup → full match → summary | Pending | | |
| Undo mid-match | Pending | | |
| History detail (line score) | Pending | | |
| Statistics filter Baseball | Pending | | |
| Resume mid-match | Pending | | |

### Killer (3+ players)

| Check | Status | Evidence | Notes |
|-------|--------|----------|-------|
| Setup enforces 3+ humans | Pending | | |
| Pick phase → elimination → summary | Pending | | |
| Undo during scoring | Pending | | |
| Resume mid-match | Pending | | |
| History + stats filter Killer | Pending | | |

### Shanghai (2+ players)

| Check | Status | Evidence | Notes |
|-------|--------|----------|-------|
| Full match → summary | Pending | | |
| Undo mid-match | Pending | | |
| Resume mid-match | Pending | | |
| History + stats filter Shanghai | Pending | | |

### Around the Clock (solo)

| Check | Status | Evidence | Notes |
|-------|--------|----------|-------|
| Solo setup (no roster step) | Pending | | |
| Progression → finish | Pending | | |
| Undo mid-match | Pending | | |
| Summary + history + stats filter | Pending | | |

### Cross-mode

| Check | Status | Evidence | Notes |
|-------|--------|----------|-------|
| Forfeit party match → FORFEIT history row | Pending | | |
| Firebase: match_started / match_completed for new mode | Pending | | |
| Resume leak: hidden mode in DB → setup not gameplay | Pending | | |
| What's New sheet → Try New Modes → Baseball prefill | Pending | | |

---

## §7 Accessibility spot check

| Check | Status | Evidence | Notes |
|-------|--------|----------|-------|
| VoiceOver: Baseball or Shanghai match start | Pending | | |
| VoiceOver: Around the Clock start | Pending | | |
| Dynamic Type AXXXL: setup + in-match | Pending | | |

Evidence path: `accessibility/wcag-2.1-aa/evidence/`

---

## Defects

| ID | Severity | Summary | Owner | Status |
|----|----------|---------|-------|--------|
| | | | | |

---

## Sign-off

| Role | Go / No-Go | Date | Notes |
|------|------------|------|-------|
| Engineering | [ ] | | Allowlist + CI |
| Device QA | [ ] | | §4–§6 on TestFlight |
| Release | [ ] | | Metadata honest |

**Overall:** [ ] **Go** · [ ] **No-Go**

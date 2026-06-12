# The Vault Game Specification

## 1. Purpose

Define **The Vault** — a cooperative heist where **2–4 humans** share a dart pool and open **5 locks** by hitting ordered segment combos. Wrong hits reset individual locks; repeated failures trigger an alarm.

**Status:** Planned (`party.theVault`).  
**Brainstorm origin:** [`FutureIdeas/custom-games-brainstorm.md`](../../../FutureIdeas/custom-games-brainstorm.md) §20.

**Related specs:**
- [`RaidGameSpec.md`](RaidGameSpec.md) — co-op summary variant, shared meter UI
- [`SoloPracticeMatchSummarySupplement.md`](../../SoloPracticeMatchSummarySupplement.md) — co-op stars (darts remaining)
- [`MatchSpec.md`](../../MatchSpec.md) — lifecycle, resume, abandon
- [`ScoringInputSpec.md`](../../ScoringInputSpec.md) — per-dart pad entry

---

## 2. Catalog metadata

| Field | Value |
|-------|-------|
| **Section** | Party |
| **UI template** | G — Phase race (`phaseRace`) + shared combo chrome |
| **Stat kind** | `coopHeist` (locks cleared, darts remaining, alarms) |
| **Ruleset (v1)** | `the_vault_standard` |
| **Catalog id** | `party.theVault` |
| **MatchType** | `theVault` (when implemented) |

**Display name:** The Vault  
**Marketing blurb:** "Crack five locks together — before the alarm ends the run."

---

## Player count

| Question | Answer |
|----------|--------|
| **Solo?** | **Yes** — 1 human, full dart pool |
| **Minimum** | 1 human |
| **Recommended** | 2–4 |
| **App maximum** | 4 humans |

### Brainstorm
- No bots in v1 — humans only.
- Solo uses same rules; stars compare darts remaining on local bests.
- Alternating **one dart** per player (not full visits) — pub coordination.

---

## 3. MVP Scope

### In scope (v1)

| Item | Default | Configurable |
|------|---------|--------------|
| Locks | **5** | 3 (Quick) / 5 / 7 (Nightmare) |
| Team dart pool | **36** (12 per lock avg) | 24 / 36 / 48 |
| Turn structure | **1 dart** per player, rotate | Fixed v1 |
| Combo length | **3 segments** per lock | 2 / 3 / 4 |
| Wrong segment | **Reset current lock only** | Fixed v1 |
| Alarm | After **3** total lock resets, next miss **ends run** | 2 / 3 / off |
| Lock generation | Seeded random from segment pool incl. bull | Difficulty tier |
| Undo | Undo last dart | — |
| History | Co-op summary — stars from darts remaining | — |

### Out of scope (v1)
- PvP vault race
- Bot guards / Heist Crew variant
- Checkout-style combos (Lockpick preset — v2)
- Persistent heist progression

---

## 4. Product goals

| Goal | How The Vault delivers |
|------|------------------------|
| **Co-op puzzle** | Table debates order ("save bull for lock 4") |
| **Fast follow to Raid** | Reuses co-op summary; no boss AI |
| **Low rules load** | One combo visible at a time |
| **Dart Buddy exclusive** | Structured co-op combos on a phone |

---

## 5. Rules Engine (`TheVaultEngine`)

### 5.1 Config (`MatchConfigTheVault`, payload v1)

| Field | Type | Default |
|-------|------|---------|
| `lockCount` | Int | `5` |
| `teamDartPool` | Int | `36` |
| `comboLength` | Int | `3` |
| `alarmThreshold` | Int | `3` |
| `difficulty` | `standard` \| `hard` | `standard` |

`hard`: combos may require specific rings (D/T); bull in pool.

### 5.2 Lock structure

Each lock:

```text
Lock {
  id: 1...N
  combo: [SegmentTarget]  // e.g. T20, D12, bull
  progressIndex: 0        // next required hit
  resetCount: 0           // times this lock was reset
}
```

**Hit:** advance `progressIndex`. When `progressIndex == combo.count`, lock **opens**.

**Wrong segment** (any dart not matching `combo[progressIndex]`): reset `progressIndex` to 0; increment `totalResets`; increment lock `resetCount`.

### 5.3 Alarm

When `totalResets >= alarmThreshold`, `alarmArmed = true`.

On alarm armed: next **wrong** dart or **miss** (outside board) → **immediate loss**.

Correct hits still progress while alarm armed.

### 5.4 Win / lose

| Outcome | Condition |
|---------|-----------|
| **Win** | All locks open |
| **Lose** | Darts exhausted OR alarm trip |
| **Stars** | 3★ = win with ≥12 darts left; 2★ = ≥6; 1★ = win |

### 5.5 State

```text
locks[]
currentLockIndex        // active lock (sequential v1)
dartsRemaining
totalResets
alarmArmed
currentPlayerIndex
turnHistory[]
```

v1: locks must open **in order** (1 → 5). v2: parallel locks optional.

---

## 6. UI notes

- Vault meter 0→100% = locks opened / total.
- Combo chips light up left-to-right on progress; shake animation on reset.
- Alarm banner: pulsing red when armed.

---

## 7. Localization (draft)

| Key | EN (draft) |
|-----|------------|
| `play.rules.theVault.title` | The Vault |
| `play.rules.theVault.summary` | Hit combo sequences to open five locks — shared darts, shared fate. |
| `play.vault.lock` | Lock {n} |
| `play.vault.alarm` | Alarm armed — next miss ends the run |

---

## 8. Open questions

1. Sequential vs parallel locks in v1?
2. Ring-required combos in standard difficulty or hard-only?
3. Share `CoopPvEModesSpec` platform doc with Raid before implementation?

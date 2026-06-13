# Solo Practice — Catalog Stub Registration Guide

## 1. Purpose
Copy-paste reference for adding **solo-only** practice modes to [`GameModeCatalog.swift`](../../../Features/Modes/GameModeCatalog.swift) before and after they ship. Shared rules: [`SoloPracticeModesSpec.md`](../../SoloPracticeModesSpec.md).

**Status:** Planned

---

## 2. When to add a catalog row

Add a **planned** row as soon as the mode has an authoritative `*GameSpec.md` — enables Modes tab "coming soon" card without an engine.

Promote to **shipped** when `MatchType`, engine, UI, and history integration land.

---

## 3. Required fields checklist

| Field | Solo-only rule |
|-------|----------------|
| `id` | `"practice.{camelCase}"` — stable forever |
| `name` | English fallback; localize via `modes.catalog.{id}.name` |
| `blurb` | One line; `modes.catalog.{id}.blurb` |
| `section` | `.practice` |
| `status` | `.planned` → `.shipped` |
| `minimumPlayers` | `1` |
| `maximumPlayers` | `1` |
| `matchType` | `nil` (planned) · set when shipped |
| `uiTemplate` | `.soloChallenge` or `.voiceDrill` |
| `statKind` | See §5 |
| `iconSystemName` | Unique SF Symbol; id-keyed accent fallback |

---

## 4. Stub rows (planned — copy into catalog)

### Call & Hit (not yet in catalog code)

```swift
GameModeCatalogEntry(
    id: "practice.callAndHit",
    name: "Call & Hit",
    blurb: "Called targets — hit or miss, track accuracy",
    section: .practice,
    status: .planned,
    minimumPlayers: 1,
    maximumPlayers: 1,
    matchType: nil,
    uiTemplate: .voiceDrill,  // add enum case Template J
    statKind: .practiceAccuracy,  // add enum case
    iconSystemName: "waveform.circle.fill"
)
```

**Shipped promotion:** `status: .shipped`, `matchType: .callAndHit`.

### Guided Practice (not yet in catalog code)

```swift
GameModeCatalogEntry(
    id: "practice.guidedPractice",
    name: "Guided Practice",
    blurb: "Called targets with a guide — built for VoiceOver",
    section: .practice,
    status: .planned,
    minimumPlayers: 1,
    maximumPlayers: 1,
    matchType: nil,
    uiTemplate: .voiceDrill,
    statKind: .practiceAccuracy,
    iconSystemName: "ear.and.waveform"
)
```

**Shipped promotion:** `status: .shipped`, `matchType: .guidedPractice`. Display **before** Call & Hit in Practice section (accessibility-first discovery).

**Naming:** User-facing **Guided Practice** — not "Blind mode" (conflicts with Blind Killer party game).

### Bob's 27 (exists — reference)

```swift
GameModeCatalogEntry(
    id: "practice.bobs27",
    name: "Bob's 27",
    blurb: "Doubles checkout drill",
    section: .practice,
    status: .planned,
    minimumPlayers: 1,
    maximumPlayers: 1,
    matchType: nil,
    uiTemplate: .soloChallenge,
    statKind: .soloScore,
    iconSystemName: "scope"
)
```

### Halve-It (exists — reference)

```swift
GameModeCatalogEntry(
    id: "practice.halveIt",
    name: "Halve-It",
    blurb: "Miss the target, halve your score",
    section: .practice,
    status: .planned,
    minimumPlayers: 1,
    maximumPlayers: 1,
    matchType: nil,
    uiTemplate: .soloChallenge,
    statKind: .soloScore,
    iconSystemName: "divide.circle.fill"
)
```

---

## 5. Stat kind picker

| Mode shape | `ModeStatKind` |
|------------|----------------|
| Hit/miss accuracy drill | `practiceAccuracy` |
| Running score vs par | `soloScore` |
| Timed sequence completion | `sequence` (usually **not** `maximumPlayers: 1`) |

Add new enum case + `StatsService` reducer when none fit ([`StatsSpec.md`](../../StatsSpec.md) §12).

---

## 6. UI template picker

| Mode shape | `GameplayUITemplate` |
|------------|------------------------|
| Dart pad + computed scoring | `soloChallenge` (F) |
| Callout + Hit/Miss honor report | `voiceDrill` (J) |
| Sequence chip trail + pad | `sequenceProgress` (E) — typically multiplayer-capable |

---

## 7. Enum additions for Call & Hit ship

| Enum | New case |
|------|----------|
| `MatchType` | `callAndHit` |
| `GameplayUITemplate` | `voiceDrill` |
| `ModeStatKind` | `practiceAccuracy` |
| `PlayRoute` | `.callAndHitMatch` |

Register accent/icon in `GameModeAccent` keyed on catalog id `practice.callAndHit` until `MatchType` exists, then dual-key like other modes.

---

## 8. Localization keys (every new stub)

Add to `Resources/en.lproj/Localizable.strings` (and de/es/nl when promoting):

```
"modes.catalog.practice.{id}.name" = "...";
"modes.catalog.practice.{id}.blurb" = "...";
```

Section header (once): `modes.section.practice`

---

## 9. Tests to update on each new solo stub

| Test | File |
|------|------|
| `soloModesUseSoloPlayerCountLabel` | `GameModeCatalogEntryTests` |
| `soloOnlyModesUseAllowedSoloTemplates` | rename from `onlySoloChallengeDrillsAreSinglePlayerCapped` |
| Catalog count / planned list | `GameModeCatalogTests` |
| Feature inventory row | manual |

---

## 10. Display order

Insert new Practice modes in `GameModeCatalog.all` **Practice MARK** in product priority order:

1. **Guided Practice** — accessibility-first onboarding (recommended first slot when stub added)
2. **Call & Hit** — sighted voice drill
3. Around the Clock / sequence modes
4. Bob's 27 / Halve-It

Rationale: voice drill has lowest rules friction; sequence and scored drills follow.

---

## 11. Verification
| Field | Value |
|-------|--------|
| **Status** | Planned |

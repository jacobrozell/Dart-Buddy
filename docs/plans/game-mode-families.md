# Game Mode Families — UI & Catalog Plan

Plan for grouping related rulesets under **family cards** in the Modes tab and Play setup picker, without collapsing engines, `MatchType`, or persistence.

**Status:** Approved direction · **Not implemented**  
**Companion:** [`specs/ModesTabSpec.md`](../../specs/ModesTabSpec.md) (addendum § Game mode families) · [`docs/full-game-catalog-ui.md`](../full-game-catalog-ui.md) · [`Features/Modes/GameModeCatalog.swift`](../../Features/Modes/GameModeCatalog.swift)

**Branch context:** Experimental dev branch with full product surface (all shipped modes visible). Lean 1.0 picker constraints are out of scope for this plan.

---

## 1. Problem

The catalog treats every ruleset as a top-level card. Several mark-board games are cricket variants or share a template, which creates picker noise and hides the relationship users already know (e.g. Cut Throat is a chip on Cricket; Mickey Mouse is "cricket variant" in copy).

Today there are **two patterns**:

| Pattern | Example | Layer |
|---------|---------|-------|
| **Config variant** | Cut Throat on Standard Cricket | Setup chip (`CricketScoringMode`), same `MatchType.cricket` |
| **Sibling catalog entry** | American Cricket, Mickey Mouse | Separate `MatchType`, engine, screen, catalog card |

This plan unifies **discovery and setup IA** while keeping Pattern B engines separate.

---

## 2. Goal

- One **family card** per related group in Modes / mode picker.
- **Variant sheet** on tap for ruleset forks.
- **Scoring toggles** remain setup chips (Cut Throat precedent).
- **`MatchType` + per-mode config** unchanged in persistence.
- **App Intents** continue to target concrete `MatchType` values (e.g. Start Mickey Mouse).

---

## 3. Cricket marks family (v1)

### 3.1 In the family

| Variant | `MatchType` | Default? | Setup notes |
|---------|-------------|----------|-------------|
| Standard Cricket | `.cricket` | Yes | Cut Throat = chip (`CricketScoringMode`), not a variant row |
| American Cricket | `.americanCricket` | No | Points on/off chip |
| Mickey Mouse | `.mickeyMouse` | No | Race ruleset; descending targets |

**Catalog placement:** One card in **Standard** (`family: cricketMarks`). Blurb lists variants: *Standard · American · Mickey Mouse*.

### 3.2 Standalone (not nested)

| Mode | Decision | Rationale |
|------|----------|-----------|
| **Mulligan** | Own card | Random targets + triples-only closing is a large rules delta; subtitle *Mark-board · random targets* signals template without nesting |
| **English Cricket** | Own card | Different game (`checkoutScore` template, batter/bowler). Keep display name **English Cricket** — well-known alias *Wickets & Runs*; use in blurb/search only |

#### English Cricket naming (resolved)

Sources ([darts501.com](https://darts501.com/Games.html), [darts-oche.com](https://darts-oche.com/dartboard-games-cricket-wickets-and-runs.html), [DolfDarts](https://dolfdarts.com/games/english-cricket)) use **English Cricket** or **Cricket (Wickets & Runs)** to distinguish from American mark-board Cricket. Keep **English Cricket** as the title. Optional blurb suffix: *Wickets & runs · 2 players*.

#### Mulligan section (resolved)

Web sources frame Mulligan as an **advanced, practice-oriented Cricket variation** (triples-only, sequential close) — skill test, not a pub-league standard or party-night social game ([GLD Products](https://gldproducts.com/blogs/all/how-to-play-mulligan-darts), [DolfDarts](https://dolfdarts.com/games/mulligan), [Decent Darts](https://decentdarts.com/mulligan-darts/)).

**Placement: Practice** — aligns with catalog mental model (*solo/training / harder drills*). Precedent: `practice.nineLives` is 2+ players in Practice. Move catalog `section` from Party → Practice when implementing.

**English Cricket** stays in **Party** — 2-player batter/bowler specialty; not mark-board cricket and not a drill.

### 3.3 Engines / screens (unchanged)

- `CricketMatchScreen` — 20–15 + bull, overflow scoring
- `AmericanCricketMatchScreen` — same board shape, different config
- `MickeyMouseMatchScreen` — descending strip, race logic

Long-term optional: single `MarkBoardMatchScreen` driven by a ruleset protocol — not a prerequisite for family UI.

---

## 4. Catalog data model (additive)

```swift
enum GameModeFamily: String, Hashable {
    case cricketMarks
    // future: aroundTheClock, killer, …
}

struct GameModeVariant: Identifiable, Hashable {
    let id: String              // e.g. "cricket.standard"
    let matchType: MatchType
    let isDefault: Bool
}

// On GameModeCatalogEntry:
var family: GameModeFamily?
var variants: [GameModeVariant]?   // non-nil ⇒ one picker card; sheet lists variants
var searchAliases: [String]        // e.g. ["wickets", "runs", "mickey", "american"]
```

**Rules:**

- Family with `variants.count > 1` → **one card** in section; tap opens variant sheet.
- `family == nil` → normal single card (Mulligan, English Cricket, Killer, …).
- Display entry for a family resolves from `variants.first(where: \.isDefault)` or first variant.
- **Persistence:** still `MatchType` + per-mode config payloads. Family is browse/setup metadata only.

---

## 5. UI flows

### 5.1 Modes tab / mode picker

```
┌─────────────────────────────────────────────┐
│ [⊞] Cricket                          2–8 pl │
│     Standard · American · Mickey Mouse      │
│                              [Learn rules ▾] │
└─────────────────────────────────────────────┘
        tap ↓
┌─────────────────────────────────────────────┐
│ Choose ruleset                              │
│  ● Standard Cricket   20–15 + bull          │
│  ○ American Cricket   20→15 + bull          │
│  ○ Mickey Mouse       Race 20→12 + bull     │
└─────────────────────────────────────────────┘
```

- **Learn rules** per variant (existing `GameRulesCatalog` / `MatchType`).
- **Mulligan** — standalone card in **Practice**. **English Cricket** — standalone card in **Party** (2-player specialty).

### 5.2 Play setup

- Header: `Cricket · American` (family · variant).
- Variant-specific chips from catalog metadata (not scattered `MatchType` switches in `SetupHomeView`).
- Cut Throat: only when variant is Standard Cricket; unchanged chip behavior.

### 5.3 Activity / history

- Filter: grouped menu — `Cricket ▸ Standard / American / Mickey Mouse`.
- History badge: `Cricket · Mickey Mouse` when variant ≠ default.

### 5.4 Search

Aliases resolve to family + variant pre-selection:

| Query | Lands on |
|-------|----------|
| mickey, american | Cricket family + variant |
| cut throat | Cricket family + Standard; highlight scoring chip in setup |
| wickets, runs | English Cricket card |
| mulligan | Mulligan card (Practice) |

---

## 6. App Intents / deep links

**Requirement:** Per-`MatchType` intents keep working (`Start Mickey Mouse`, resume by type, etc.).

- Intents target **`MatchType`** directly — no API change.
- Family grouping is **browse-layer only**.
- Future `GameModeEntity` / `GameModeIntentEnum` derive from `GameModeCatalog.available` but still resolve to a concrete `MatchType` for start/resume ([`specs/AppIntentsSpec.md`](../../specs/AppIntentsSpec.md)).

---

## 7. Future families (same pattern)

| Family | Variants | Priority | Notes |
|--------|----------|----------|-------|
| Around the Clock | ATC, 180 ATC, Chase the Dragon | High | All `sequenceProgress`; Practice section |
| X01 | 301/501/…, in/out, sets/legs | Done | Already one card + chips |
| Killer | Killer, Blind Killer (planned) | Medium | Evaluate interaction deltas before merging |

---

## 8. Phased rollout

| Phase | Work | Engine changes |
|-------|------|----------------|
| 1 | Catalog metadata + family card + variant sheet | None |
| 2 | Setup header `Family · Variant`; chip routing from catalog | None |
| 3 | Activity grouped filters; history badge copy | None |
| 4 | Mulligan `section` → Practice; English Cricket blurb aliases | Catalog only |
| 5 (optional) | `MarkBoardMatchScreen` unification | If duplication hurts |

---

## 9. Resolved decisions

| # | Decision |
|---|----------|
| 1 | Mulligan — standalone card, not under Cricket family |
| 2 | English Cricket — keep name; blurb/search alias *Wickets & Runs* |
| 3 | Mulligan section — **Practice**; English Cricket stays **Party** |
| 4 | App Intents — per-`MatchType`; family is browse-only |
| 5 | Product surface — full catalog on experimental branch; lean constraints out of scope |

---

## 10. Open items

- English Cricket **section** — **Party** (resolved); blurb includes *Wickets & Runs* for search disambiguation.
- When to collapse `AmericanCricketMatchScreen` / `MickeyMouseMatchScreen` into a shared mark-board shell.
- Variant sheet accessibility identifiers for UI tests (`modePicker_variant_*`).

---

## Verification

| Field | Value |
|-------|--------|
| **Last verified** | 2026-06-12 |
| **Status** | Plan only — no implementation on branch |

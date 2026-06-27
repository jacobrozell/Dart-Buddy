**Estimated release:** `1.5`

# Throw History Heatmap Specification

## 1. Purpose
Define a **throw-history heatmap** on the standard dartboard: each recorded dart appears as a colored marker on a board face, with period filtering and a companion “most hit numbers” chart.

Primary inspiration: competitor-style player analytics (dartboard scatter + sector bar chart). Dart Buddy’s v1 uses **existing dart events** (segment + multiplier + miss) — no camera coordinates required.

**Primary surface:** [`PlayerSpec.md`](PlayerSpec.md) §5.3 — **Player Detail** (`PlayerStatsDetailView`).  
**Data policy:** [`StatsSpec.md`](StatsSpec.md). **Board geometry:** [`VisualDartboardInputSpec.md`](VisualDartboardInputSpec.md) / `BoardHitResolver`.

---

## 2. Terminology

| Term | Meaning |
|------|---------|
| **Throw map** | UI section title; board + legend + optional sector bars |
| **Heatmap marker** | Semi-transparent dot on the board face representing one dart |
| **Synthetic placement** | Marker position derived from segment/multiplier/miss via shared board geometry — not a photographed impact point |
| **Ring class** | `single` \| `double` \| `triple` \| `miss` — drives marker color and legend buckets |

---

## 3. Scope

### In scope (v1 — `1.5`)
| Item | Detail |
|------|--------|
| **Surface** | Player Detail only (human players + training/custom bots that expose stats) |
| **Modes (data)** | **X01** and **Cricket** completed matches (v1); loader keyed by `MatchType` |
| **Mode filter** | Menu or segment: **All** \| **X01** \| **Cricket** — only options where player has ≥1 qualifying dart; hidden when exactly one mode qualifies |
| **Period filter** | Today \| 7 days \| 30 days \| All — same cutoffs as [`StatisticsTabSpec.md`](StatisticsTabSpec.md) §4 |
| **Board** | Reuse `DartboardFace` styling (`VisualDartboardMetrics`, `BoardHitResolver`) |
| **Markers** | One dot per dart; color by ring class |
| **Legend** | Counts: Single / Double / Triple / Miss |
| **Sector bars** | Top hit numbers (horizontal bars, top 8 by count) — reuses `hitsBySector` semantics |
| **Expand** | Tap board → full-screen sheet with larger board (pinch optional post-v1) |
| **Empty state** | Section hidden when zero qualifying darts for current filters; no placeholder board |
| **`SectorHitsChart`** | **Kept** in each per-mode stat block (alongside Throw map — not replaced in v1) |

### Out of scope (v1)
| Item | Notes |
|------|-------|
| Activity → Statistics tab mirror | Future; Player Detail is authoritative v1 home |
| Party / practice catalog modes | Defer until `StatsService` sector reducers exist per mode; extend mode filter when shipped |
| True impact coordinates | Requires schema change — see §8 |
| Checkout-only or training-drill filters | Future segment |
| Export / share image | Future |
| Bot preset opponents (non-linked) | Preset bots have no persistent player detail |

---

## 4. Product Behavior

### 4.1 Section placement (Player Detail)

**One consolidated Throw map section** — not duplicated under each per-mode stat block.

Insert **after** the Training Partner block (when shown) and **before** the per-mode stat breakdowns (X01 / Cricket `modeSection` blocks):

```text
Identity card
Training Partner (optional)
Throw map  ← single section; mode + period filters
  X01 stat tiles + trend + SectorHitsChart (when x01.games > 0)
  Cricket stat tiles + SectorHitsChart (when cricket.games > 0)
Recent matches
```

**Cricket-only players:** Throw map appears once (mode filter hidden; data scoped to Cricket). X01 block absent — unchanged.

**X01-only players:** Throw map once (mode filter hidden; data scoped to X01).

**Both modes:** mode filter visible with **All | X01 | Cricket**.

Per-mode blocks below retain stat tiles, X01 trend, and **`SectorHitsChart`** — Throw map does **not** replace the sector bar chart in v1 (see §13).

### 4.2 Filters

Throw map owns **two independent controls** (local VM state — does not change Activity → Statistics filters).

#### Mode filter

| Value | Data included |
|-------|----------------|
| `all` | X01 + Cricket darts merged on one board (when player has both) |
| `x01` | X01 matches only |
| `cricket` | Cricket matches only |

| UI state | Behavior |
|----------|----------|
| Player has one qualifying mode | Filter **hidden**; implicit scope to that mode |
| Player has X01 + Cricket | Segmented control or menu; default **`all`** |
| Filter change | Reload markers, legend, sector bars |

`StatsSectorOrder` for sector bars uses `.x01` ranking when `all` or `x01`; `.cricket` when `cricket` only.

**Future:** append catalog modes with board-sector stats (e.g. Around the Clock, Shanghai) as filter options when reducers ship — same control pattern.

#### Period filter

| Value | Cutoff |
|-------|--------|
| `today` | Start of local calendar day |
| `d7` | Now − 7 days |
| `d30` | Now − 30 days |
| `all` | No cutoff |

**Default: `d30`** (lighter first load for heavy histories). Segment shows all four options; user can switch to **All** anytime.

Reload markers and sector bars when either filter changes.

**Match eligibility:** `status == completed` only (same as Statistics). Abandoned and in-progress matches excluded.

**Filter persistence (locked):** Save `heatmapModeFilter` + `heatmapPeriodFilter` on the player profile when the user changes either control. Restore on next Player Detail open. First visit or no saved prefs → **All + 30d** (or hidden mode when single-mode player).

### 4.3 Board card layout
```text
+--------------------------------------------------+
| ZONES HIT                          80 darts      |
| [ All | X01 | Cricket ]   [ 30d ▾ period ]       |
|--------------------------------------------------|
|              (dartboard + markers)               |
|--------------------------------------------------|
| ● Single 46   ● Double 3   ● Triple 23   ● Miss 8|
|           Tap to enlarge                         |
+--------------------------------------------------+
| MOST HIT NUMBERS                                 |
| 20  ████████████████████  21                     |
|  1  ████████               8                     |
|  3  ██████                 6                     |
+--------------------------------------------------+
```

- Filter row: mode segment (when ≥2 modes) + period segment on one line (wrap on narrow width).
- Header trailing count: total darts for **current mode + period** filters.
- Footer hint: `players.detail.heatmap.expandHint` (“Tap to enlarge”).
- Card uses `Brand.card`, `DS.Radius.md`, spacing tokens from [`DesignSystemSpec.md`](DesignSystemSpec.md).

### 4.4 Marker appearance
| Ring class | Color token | Includes |
|------------|-------------|----------|
| Single | `Brand.blue` or semantic info | Inner/outer single, both bulls (25/50) |
| Double | `Brand.green` | Double ring hits |
| Triple | `Brand.red` | Triple ring hits |
| Miss | `Brand.textSecondary` @ 50% | `wasMiss == true` and off-board zeros |

- Dot diameter: ~6 pt at default Dynamic Type; scale with board size, not with marker count.
- Opacity: ~0.55 default; slightly higher when count &lt; 20 for readability.
- Overlap is expected and honest (synthetic placement clusters within zones).

### 4.5 Full-screen sheet
- Trigger: tap anywhere on the board card (excluding period segment).
- Presentation: `.sheet` with navigation title `players.detail.heatmap.fullscreenTitle`.
- Content: larger `ThrowHeatmapBoard` (max width/height), same markers + legend; sector bars optional below on iPad regular width.
- Dismiss: standard drag + Close toolbar button.
- VoiceOver: announce total dart count on open.

### 4.6 Most hit numbers
- Source: aggregated `hitsBySector` for the same player, **mode filter**, and period.
- Sort: descending count; tie-break with [`StatsSectorOrder`](../../Features/Statistics/StatisticsViewModel.swift) rank (see §4.2 mode filter).
- Show top **8** sectors; omit section if empty.
- Miss bucket (`0`) excluded from this chart (shown only in legend).
- Bull keys (`innerBull`, `outerBull`) merge to one **Bull** row for display.

---

## 5. Synthetic Placement Algorithm

Dart events store **segment + multiplier + miss**, not tap coordinates. v1 markers are **synthetic** but deterministic.

### 5.1 Inputs
Per dart, from event replay (`X01TurnEvent.reconstructedDarts`, Cricket dart touches, etc.):
- `segmentRaw` / parsed `DartSegment`
- `multiplierRaw` / `DartMultiplier`
- `wasMiss`
- Stable key: `{turnEventId}-{dartOrder}` (or equivalent per mode)

### 5.2 Geometry (shared with visual input)
Use `BoardHitResolver.segmentOrder`, `RingBounds`, and `VisualDartboardMetrics.layout(in:)`:
1. Resolve ring + wedge from `DartInput` (mirror `BoardHitResolver.dartInput` inverse — map segment/multiplier → ring enum).
2. Compute annular sector centroid for that ring/wedge in **normalized board coordinates** (origin center, radius = 1).
3. Apply **deterministic jitter** inside the zone:  
   `offset = hash(stableKey) → (dx, dy)` capped to ±35% of zone annulus width so dots spread but stay in-zone.
4. Misses: place in a fixed **miss band** just outside the double ring (consistent clock position from hash — e.g. 4 o’clock) so misses are visible without implying a segment.

### 5.3 Rules
- Same event key → same position across reloads (tests must assert stability).
- Bulls: inner vs outer bull use distinct sub-zones.
- Cricket non-scoring wedges (1–14) still plot at the tapped segment — they are real throws.
- **Do not** claim pixel accuracy in UI copy or accessibility strings.

### 5.4 Performance cap
When dart count &gt; **750** in filter:
- Render the **most recent 750** markers (by turn timestamp).
- Show subtitle: `players.detail.heatmap.truncatedFormat` — “Showing latest 750 of 1,240 darts”.
- Legend and sector bars use **full** dataset (cheap aggregates).

---

## 6. Architecture

| Piece | Location |
|-------|----------|
| Reducer | `Domain/Services/ThrowHeatmapService.swift` — pure functions |
| DTOs | `ThrowHeatmapSnapshot`, `ThrowHeatmapMarker`, `ThrowHeatmapLegend`, `ThrowHeatmapSectorRow` |
| Loader | Extend `MatchStatsLoader` or add `ThrowHeatmapLoader` calling match repo + event decode |
| VM | `PlayerDetailViewModel` — `@Published var throwHeatmap`, `heatmapModeFilter`, `heatmapPeriodFilter` |
| Views | `Features/Players/ThrowHeatmapSection.swift`, `ThrowHeatmapBoard.swift` (Canvas overlay on `DartboardFace`) |

**Dependency rule:** Views consume snapshots only; no formula logic in SwiftUI (per [`StatsSpec.md`](StatsSpec.md) §6).

### 6.1 Loader request
```swift
enum ThrowHeatmapModeFilter: Sendable, Equatable {
    case all
    case matchType(MatchType) // .x01 | .cricket in v1
}

struct ThrowHeatmapLoadRequest: Sendable, Equatable {
    let modeFilter: ThrowHeatmapModeFilter
    let participantPlayerId: UUID
    let period: StatsPeriodFilter
}
```

When `modeFilter == .all`, loader merges dart events from all v1-supported `MatchType` values the player has played. Returns `ThrowHeatmapSnapshot` or empty when no darts.

### 6.2 Reuse
- Event iteration: same paths as `StatsService.breakdowns` / `HitsBySectorKeys` (do not fork sector key rules).
- Board drawing: extract or share `DartboardFace` from `VisualDartboardInput.swift` if not already public.

---

## 7. Localization
Keys under `players.detail.heatmap.*` in all shipped locales (`LocalizationSpec.md`).

| Key | EN example |
|-----|------------|
| `players.detail.heatmap.title` | Zones hit |
| `players.detail.heatmap.dartCountFormat` | `%d darts` |
| `players.detail.heatmap.legend.single` | Single |
| `players.detail.heatmap.legend.double` | Double |
| `players.detail.heatmap.legend.triple` | Triple |
| `players.detail.heatmap.legend.miss` | Miss |
| `players.detail.heatmap.legend.format` | `%1$@ %2$d` |
| `players.detail.heatmap.expandHint` | Tap to enlarge |
| `players.detail.heatmap.fullscreenTitle` | Throw map |
| `players.detail.heatmap.mostHitTitle` | Most hit numbers |
| `players.detail.heatmap.truncatedFormat` | Showing latest %1$d of %2$d darts |
| `players.detail.heatmap.accessibility.summary` | `%1$d darts: %2$d singles, %3$d doubles, %4$d triples, %5$d misses` |
| `players.detail.heatmap.mode.all` | All games |
| `players.detail.heatmap.mode.x01` | X01 |
| `players.detail.heatmap.mode.cricket` | Cricket |

Period segment reuses existing `stats.period.*` keys. Mode filter reuses `stats.mode.*` or dedicated keys above when Statistics labels differ.

---

## 8. Future — True Coordinates (post-v1)

Optional fields on dart payloads (additive, backward compatible):

| Field | When populated |
|-------|----------------|
| `boardNormX: Double?` | Visual dartboard tap ([`VisualDartboardInputSpec.md`](VisualDartboardInputSpec.md)) |
| `boardNormY: Double?` | Same |
| `visionConfidence: Double?` | [`AutoScoringVisionSpec.md`](AutoScoringVisionSpec.md) |

When present, marker placement prefers stored coordinates; synthetic fallback otherwise. Vision/board and pad-entered darts may coexist in one heatmap.

---

## 9. Accessibility
- Mode filter: `playerDetail_heatmapModeFilter` (when visible).
- Period segment: `playerDetail_heatmapPeriodSegment`.
- Board card: combined label from `accessibility.summary`; markers themselves are decorative (`accessibilityHidden`).
- Legend: each row is a static text element (not color-only — label includes word + count).
- Sector bars: reuse `SectorHitsChart` accessibility pattern (sector label + count).
- Reduce Motion: no marker entrance animation in v1.
- Manual checklist row: add to `accessibility/wcag-2.1-aa/screens/players-detail.md` at implementation.

---

## 10. Testing

### Unit
- `ThrowHeatmapServiceTests` — placement stability, ring class bucketing, period cutoffs, 750-cap, bull merge
- `ThrowHeatmapLoaderTests` — completed-only, player filter, mode filter (all / x01 / cricket), period default `d30`
- Regression: legend counts match `StatsService` double/triple/miss totals for same fixture

### UI
- Player detail smoke: section visible when games &gt; 0; sheet opens
- Snapshot: board + legend at light/dark (`Brand` tokens)

---

## 11. Cross-References
| Spec | Relationship |
|------|----------------|
| [`PlayerSpec.md`](PlayerSpec.md) §5.3 | Section list — add Throw map |
| [`StatsSpec.md`](StatsSpec.md) | Formulas, event authority, no schema change v1 |
| [`StatisticsTabSpec.md`](StatisticsTabSpec.md) | Period filter parity; post-1.5 optional roster-wide Throw map mirror (§13 #6) |
| [`VisualDartboardInputSpec.md`](VisualDartboardInputSpec.md) | Shared board geometry |
| [`UIBlueprintSpec.md`](UIBlueprintSpec.md) §4.9 | Wireframe update when implemented |

---

## 12. Verification
| Field | Value |
|-------|--------|
| **Estimated release** | `1.5` |
| **Last verified** | — |
| **Commit** | — |
| **Code** | — (planned) |

---

## 13. Decisions (locked 2026-06-26)

| # | Question | Decision |
|---|----------|----------|
| 1 | Remove `SectorHitsChart` when Throw map ships? | **Keep** sector bar chart in each per-mode stat block for v1. Throw map is complementary, not a replacement. Revisit deduplication post-1.5 if redundant in user testing. |
| 2 | Default period | **`d30`**. Full segment still offers Today, 7d, 30d, and All. |
| 3 | Cricket-only / X01-only players | **Yes** — single Throw map section; mode filter hidden when only one mode has data. Cricket-only players never see an empty X01 block. |
| 4 | Game mode filter | **Yes** — consolidated Throw map section includes mode filter (**All \| X01 \| Cricket** when both played). Default **`all`** when multiple modes qualify. Extend filter options as party/practice modes gain sector reducers. |
| 5 | Remember filters | **Yes** — persist last mode + period per player (`PlayerRecord` optional fields or equivalent). Restores on next Player Detail visit; helps single-mode / practice-focused players. Defaults remain **All + 30d** when no saved preference. |
| 6 | Activity → Statistics mirror | **Future (post-1.5)** — duplicate Throw map on Statistics tab when product wants **cross-player** view (all players + bots aggregate). Player Detail stays primary per-player home in v1. |

---

## 14. Future polish (post-v1)

- Remove duplicate `SectorHitsChart` from Player Detail if Throw map + most-hit bars subsume it.
- Mode filter entries for shipped party/practice modes (Around the Clock, Shanghai, …) per [`StatsSpec.md`](StatsSpec.md) §12.
- **Statistics tab Throw map** — roster-wide heatmap with existing player filter (+ bots where applicable); see decision §13 #6.

# In-Visit Sequence Progression Supplement

Cross-cutting contract for game modes where a player may hit **multiple successive sequence targets within one 3-dart visit** (house rule: e.g. hit 1, 2, and 3 on the same turn).

Referenced by individual mode specs in §4 (engine) and §5 (UI). Implementation: [`DartNumberPad`](../../Features/Play/X01/DartNumberPad.swift), per-mode `*MatchViewModel.lockedSegment`.

---

## 1. Applicable modes

| Mode | Match type | Pad locking | Notes |
|------|------------|-------------|-------|
| Around the Clock | `.aroundTheClock` | Segment lock | Shipped; reference implementation |
| Nine Lives | `.nineLives` | Segment lock | ATC variant with lives |
| Hare and Hounds | `.hareAndHounds` | Segment lock | Clockwise **course** segment, not numeric 1→20 |
| Chase the Dragon | `.chaseTheDragon` | Treble/bull pad (no segment lock) | Qualifying hit per step; pad uses modifiers |

## 2. Explicit exclusions

These modes keep **one active target for the entire visit**. The pad must **not** re-lock to the next target mid-entry.

| Mode | Reason |
|------|--------|
| Around the Clock 180 | All three darts score against the **current number**; advance after the visit |
| Grand National | One **course position** per visit; any hit clears the hurdle once |
| Golf | Strokes recorded for the **current hole** segment |
| Shanghai | All darts score against the **current round** number |
| Baseball | All darts score against the **current inning** segment |
| Mickey Mouse / Mulligan | Marks accumulate on the **current closure target** |

When adding a new sequence mode, decide up front: **per-visit multi-advance** (this supplement) vs **single target per visit** (exclusion table).

---

## 3. Engine contract

1. Process darts in throw order within the visit.
2. Evaluate each dart against the **current** target **after** prior qualifying hits in the same visit.
3. Each qualifying hit advances exactly **one** step along that mode's sequence or course.
4. End-of-visit policies (reset, life loss, elimination) use whether **any** advance occurred, unless the mode defines per-target miss counting (e.g. Around the Clock `resetOnThreeMisses` counts misses against the target active when each dart was thrown).
5. Mid-visit **match completion** (e.g. hitting 20 without bull finish) is valid; remaining dart slots accept misses only.

### Reference (Around the Clock)

```text
Visit: hit(1), hit(2), hit(3)  →  targetIndex 0 → 3
Visit: hit(1), miss, miss     →  targetIndex 0 → 1
Visit: miss, miss, miss       →  no advance; reset policy may apply
```

---

## 4. Scoring pad contract (`DartNumberPad`)

For modes that pass `lockedSegment`:

1. **Effective target** — project session state through `enteredDarts` using the same hit rules as the engine (shared helper or engine static).
2. **`lockedSegment`** — effective target segment value (1–20). `nil` when the active step is bull-only.
3. **`scoringSegmentsDisabled`** — `true` when the player has completed the sequence mid-visit; only miss (`0`) and undo remain enabled.
4. **Header / accessibility** — current-target copy uses the effective target during entry so the label matches the enabled pad key.
5. **Submit** — unchanged: visit submits when three darts are entered (or mode-specific early-end).

### Accessibility

- Locked-segment hint (`play.{mode}.pad.lockedSegmentHint`) should describe the **effective** target, not only the target at turn start.
- After a qualifying hit, VoiceOver users hear the updated target via the projected header label.

---

## 5. Bot playback

Bots in multi-advance modes should attempt successive targets within a visit when skill profile allows (not stop after the first hit). Until updated, bots may under-utilize multi-advance; human pad behavior is authoritative.

---

## 6. Testing

Per mode:

- **Engine:** visit with `[hit(n), hit(n+1), hit(n+2)]` advances three steps.
- **View model:** `lockedSegment` / `currentTarget` updates after each dart appended to `enteredDarts`.
- **Pad:** after first hit, next segment key is enabled (UI test or unit projection).

---

## 7. Localization / How to Play

Mode overview copy must **not** say "first hit only" when this supplement applies. Preferred phrasing:

> Three darts per turn. Each dart that hits the **current** target moves you to the **next** target for the rest of the visit.

Update `play.rules.{mode}.overview.body` (and spec § How to Play) when promoting or revising a mode.

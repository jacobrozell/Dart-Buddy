# Additional Game Modes — R&D Index

Post-1.0 exploration of dart formats listed on [Target Darts — What Dart Games Can I Play?](https://www.target-darts.co.uk/dart-games). Lighter assessments for unshipped practice/party modes live in [`party-practice-modes.md`](party-practice-modes.md).

**Status:** R&D only for **planned** modes — not governed by `specs/SpecGovernance.md` until promoted to `specs/*GameSpec.md`.

---

## Shipped in Dart Buddy

| Target name | Dart Buddy | Authoritative spec |
|-------------|------------|-------------------|
| 501 | X01 (301 / 501) | [`specs/X01GameSpec.md`](../specs/X01GameSpec.md) |
| Cricket | Cricket (incl. Cut Throat) | [`specs/CricketSpec.md`](../specs/CricketSpec.md) |
| Baseball | Baseball | [`specs/BaseballGameSpec.md`](../specs/BaseballGameSpec.md) |
| Killer | Killer | [`specs/KillerGameSpec.md`](../specs/KillerGameSpec.md) |
| Shanghai | Shanghai | `Domain/Engines/ShanghaiEngine.swift` + `Features/Play/Shanghai/` (promote to `specs/ShanghaiGameSpec.md` when scheduled) |

Shared lifecycle: [`specs/MatchSpec.md`](../specs/MatchSpec.md). `MatchType` today: `x01` \| `cricket` \| `baseball` \| `killer` \| `shanghai` (`Domain/Models/RepositoryModels.swift`). Catalog: [`Features/Modes/GameModeCatalog.swift`](../Features/Modes/GameModeCatalog.swift) (5 shipped + 24 planned).

---

## Candidate modes (not yet shipped)

| Game | Doc | Priority | Players | Complexity | Notes |
|------|-----|----------|---------|------------|-------|
| Bob's 27 | [`party-practice-modes.md`](party-practice-modes.md) | P2 | 1 | Low | Solo practice; doubles 1→20 + bull |
| Around the Clock | [`party-practice-modes.md`](party-practice-modes.md) | P2 | 1+ | Low–Med | Sequential 1→20 + bull; progress reset rules vary |
| Halve-It | [`party-practice-modes.md`](party-practice-modes.md) | P3 | 1+ | Med | Descending score targets; house rules heavy |
| **Golf** | [`party-practice-modes.md`](party-practice-modes.md) | P2 | 2+ | Med | 9/18 holes on segments 1→9/18; lowest strokes wins; last-dart-counts |

Plus 23 additional **planned** catalog entries (Mickey Mouse, Golf, Football, …) in `GameModeCatalog` — see [`docs/full-game-catalog-ui.md`](../docs/full-game-catalog-ui.md).

---

## Shared implementation strategy

### 1. Extend match platform (not one-off screens)

Follow existing split:

```
Features/Play          → setup, resume, history shell
Features/<Mode>Feature → board + VM
Domain/<Mode>Engine    → pure rules
Data                   → events + snapshots per specs/SwiftData.md
```

Each new mode needs:

- `MatchType` case + versioned `configPayload`
- Pure `*Engine` with `submitTurn` / `undoLastTurn`
- Turn + dart events (or mode-specific mark events) for stats/history
- Setup row in [`specs/SetupFlowSpec.md`](../specs/SetupFlowSpec.md) (when promoted)
- Stats/history filters (optional v1)

### 2. Scoring input reuse

| Mode | Input model |
|------|-------------|
| Golf | Dart-by-dart on **current hole target**; last dart counts; optional early turn end |
| Practice modes | Often total-per-turn or strict sequence — see party doc |

Reference: [`specs/ScoringInputSpec.md`](../specs/ScoringInputSpec.md). Shipped party modes (Baseball, Killer, Shanghai) already follow per-dart / segment-locked patterns.

### 3. Schema impact (when shipping)

- `MatchRecord.type` enum extension + migration bump in `specs/SwiftData.md`
- Mode-specific event tables (mirror `X01DartEvent` / `CricketDartTouch`)
- History detail UI branch in Play/History features

### 4. Bots & stats

| Mode | Bot feasibility | Stats v1 |
|------|-----------------|----------|
| Golf | Moderate (segment aim; stop on double) | Strokes per hole, 9/18 total |
| Solo practice | N/A or training bot | High scores, streaks |

### 5. Suggested delivery order

1. **Around the Clock / Bob's 27** — solo/training; catalog stubs exist  
2. **Golf** — reuses per-round segment flow; last-dart UX is the main new surface  
3. **Halve-It** — after practice-mode patterns exist  
4. Remaining **planned catalog** modes per [`docs/full-game-catalog-ui.md`](../docs/full-game-catalog-ui.md) priority  

---

## Promotion checklist (R&D → `specs/`)

- [ ] Default rules + named variants locked (house rules documented)
- [ ] Engine unit tests listed in feature spec §Testing
- [ ] Data events defined; cross-link `DataSchemaSpec` / `SwiftData.md`
- [ ] Setup options and `MatchType` raw value
- [ ] UI blueprint wireframe or `UIImplementationSpec` section
- [ ] Accessibility: lives/innings not color-only
- [ ] Localization key prefix (`play.golf.*`, `play.practice.*`)
- [ ] Entry in `specs/README.md` Feature Specs
- [ ] `docs/release/todo.md` item if scheduled

---

## References

- [Target Darts — dart games](https://www.target-darts.co.uk/dart-games) (product marketing summaries)
- Shipped party rules: [GLD Killer](https://gldproducts.com/blogs/all/how-to-play-killer-darts), [GLD Baseball](https://gldproducts.com/blogs/all/how-to-play-baseball-darts)

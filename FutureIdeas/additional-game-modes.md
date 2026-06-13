# Additional Game Modes — R&D Index

Post-1.0 exploration of dart formats listed on [Target Darts — What Dart Games Can I Play?](https://www.target-darts.co.uk/dart-games). Lighter assessments for unshipped practice/party modes live in [`party-practice-modes.md`](party-practice-modes.md).

**Status:** R&D index. **Planned modes now have authoritative specs** in [`specs/game-modes/planned/`](../specs/game-modes/planned/) (see [`specs/game-modes/README.md`](../specs/game-modes/README.md)). This file remains a delivery-strategy index.

---

## Shipped in Dart Buddy

| Target name | Dart Buddy | Authoritative spec |
|-------------|------------|-------------------|
| 501 | X01 (301 / 501) | [`specs/game-modes/implemented/X01GameSpec.md`](../specs/game-modes/implemented/X01GameSpec.md) |
| Cricket | Cricket (incl. Cut Throat) | [`specs/game-modes/implemented/CricketSpec.md`](../specs/game-modes/implemented/CricketSpec.md) |
| Baseball | Baseball | [`specs/game-modes/implemented/BaseballGameSpec.md`](../specs/game-modes/implemented/BaseballGameSpec.md) |
| Killer | Killer | [`specs/game-modes/implemented/KillerGameSpec.md`](../specs/game-modes/implemented/KillerGameSpec.md) |
| Shanghai | Shanghai | [`specs/game-modes/implemented/ShanghaiGameSpec.md`](../specs/game-modes/implemented/ShanghaiGameSpec.md) |

Shared lifecycle: [`specs/MatchSpec.md`](../specs/MatchSpec.md). `MatchType` today: `x01` \| `cricket` \| `baseball` \| `killer` \| `shanghai` (`Domain/Models/RepositoryModels.swift`). Catalog: [`Features/Modes/GameModeCatalog.swift`](../Features/Modes/GameModeCatalog.swift) (5 shipped + 24 planned).

---

## Candidate modes (not yet shipped)

| Game | Spec | Priority | Players | Complexity | Notes |
|------|------|----------|---------|------------|-------|
| Bob's 27 | [`specs/game-modes/planned/Bobs27GameSpec.md`](../specs/game-modes/planned/Bobs27GameSpec.md) | P2 | 1 | Low | Solo practice; doubles 1→20 + bull |
| Around the Clock | [`specs/game-modes/planned/AroundTheClockGameSpec.md`](../specs/game-modes/planned/AroundTheClockGameSpec.md) | P2 | 1+ | Low–Med | Sequential 1→20 + bull; reset policy in spec |
| Halve-It | [`specs/game-modes/planned/HalveItGameSpec.md`](../specs/game-modes/planned/HalveItGameSpec.md) | P3 | 1+ | Med | Curated sequence in v1 spec |
| **Golf** | [`specs/game-modes/planned/GolfGameSpec.md`](../specs/game-modes/planned/GolfGameSpec.md) | P2 | 2+ | Med | 9/18 holes; GLD last-dart ruleset |

All 24 planned catalog entries have specs — see [`specs/README.md`](../specs/README.md) § Planned game modes and [`docs/full-game-catalog-ui.md`](../docs/full-game-catalog-ui.md).

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

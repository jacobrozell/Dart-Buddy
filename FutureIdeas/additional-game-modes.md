# Additional Game Modes — R&D Index

Post-1.0 exploration of dart formats listed on [Target Darts — What Dart Games Can I Play?](https://www.target-darts.co.uk/dart-games). Deep specs for **Killer** and **Baseball** live in sibling files; lighter assessments for practice/party modes are in [`party-practice-modes.md`](party-practice-modes.md).

**Status:** R&D only — not governed by `specs/SpecGovernance.md` until promoted to `specs/*GameSpec.md`.

---

## Already in Dart Buddy (1.0)

| Target name | Dart Buddy | Authoritative spec |
|-------------|------------|-------------------|
| 501 | X01 (301 / 501) | [`specs/X01GameSpec.md`](../specs/X01GameSpec.md) |
| Cricket | Cricket | [`specs/CricketSpec.md`](../specs/CricketSpec.md) |

Shared lifecycle: [`specs/MatchSpec.md`](../specs/MatchSpec.md). `MatchType` today is `x01` \| `cricket` only (`Domain/Models/RepositoryModels.swift`).

---

## Candidate modes (Target list)

| Game | Doc | Priority | Players | Complexity | Notes |
|------|-----|----------|---------|------------|-------|
| **Killer** | [`killer-darts.md`](killer-darts.md) | **P0** | 3+ | Medium | Party elimination; unique UI (lives, killer status, number assignment) |
| **Baseball** | [`baseball-darts.md`](baseball-darts.md) | **P0** | 2+ | Medium | Inning-based runs; reuses dart-entry patterns |
| Bob's 27 | [`party-practice-modes.md`](party-practice-modes.md) | P2 | 1 | Low | Solo practice; doubles 1→20 + bull |
| Around the Clock | [`party-practice-modes.md`](party-practice-modes.md) | P2 | 1+ | Low–Med | Sequential 1→20 + bull; progress reset rules vary |
| Shanghai | [`party-practice-modes.md`](party-practice-modes.md) | P2 | 2+ | Med | Per-round target + S/D/T bonus |
| Halve-It | [`party-practice-modes.md`](party-practice-modes.md) | P3 | 1+ | Med | Descending score targets; house rules heavy |

---

## Shared implementation strategy

### 1. Extend match platform (not one-off screens)

Follow existing split:

```
Features/Play          → setup, resume, history shell
Features/KillerFeature → (new) board + VM
Domain/KillerEngine    → pure rules
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
| Killer | Dart-by-dart on **assigned segment** (per player number); assignment phase may be 1-dart flow |
| Baseball | Dart-by-dart on **current inning target**; same `ScoringInputPad` segment + S/D/T as X01 |
| Practice modes | Often total-per-turn or strict sequence — see party doc |

Reference: [`specs/ScoringInputSpec.md`](../specs/ScoringInputSpec.md).

### 3. Schema impact (when shipping)

- `MatchRecord.type` enum extension + migration bump in `specs/SwiftData.md`
- Mode-specific event tables (mirror `X01DartEvent` / `CricketDartTouch`)
- History detail UI branch in Play/History features

### 4. Bots & stats

| Mode | Bot feasibility | Stats v1 |
|------|-----------------|----------|
| Killer | Hard (social targeting); defer or “random target” bot | Lives remaining, kills dealt |
| Baseball | Moderate (segment aim by skill tier) | Runs per inning, 9-inning total |
| Solo practice | N/A or training bot | High scores, streaks |

Align bot policy with [`FutureIdeas/backlog.md`](backlog.md) (custom bot metrics).

### 5. Suggested delivery order

1. **Baseball** — clearest rules, closest to existing turn + 3-dart flow  
2. **Killer** — higher UX cost (assignment, lives, killer flag, 3+ players)  
3. **Around the Clock / Bob's 27** — solo/training tab or “Practice” entry  
4. **Shanghai / Halve-It** — after party-mode patterns exist  

---

## Promotion checklist (R&D → `specs/`)

- [ ] Default rules + named variants locked (house rules documented)
- [ ] Engine unit tests listed in feature spec §Testing
- [ ] Data events defined; cross-link `DataSchemaSpec` / `SwiftData.md`
- [ ] Setup options and `MatchType` raw value
- [ ] UI blueprint wireframe or `UIImplementationSpec` section
- [ ] Accessibility: lives/innings not color-only
- [ ] Localization key prefix (`play.killer.*`, `play.baseball.*`)
- [ ] Entry in `specs/README.md` Feature Specs
- [ ] `docs/release/todo.md` item if scheduled

---

## References

- [Target Darts — dart games](https://www.target-darts.co.uk/dart-games) (product marketing summaries)
- Killer: [GLD Products](https://gldproducts.com/blogs/all/how-to-play-killer-darts), [Dart Scout](https://thedartscout.com/dart-rules-explained/)
- Baseball: [GLD Products](https://gldproducts.com/blogs/all/how-to-play-baseball-darts), [Dartspin](https://dartspin.com/baseball-dart-game/)

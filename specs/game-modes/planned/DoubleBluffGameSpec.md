# Double Bluff Game Specification

## 1. Purpose

Define **Double Bluff** — a **2-player** mind game where both players **simultaneously commit** a target segment (and ring intent), then reveal. Matching picks → throw at shared target; clashing picks → throw at opponent's committed segment. First to **11** points wins.

**Status:** Planned (`party.doubleBluff`).  
**Brainstorm origin:** [`FutureIdeas/custom-games-brainstorm.md`](../../../FutureIdeas/custom-games-brainstorm.md) §24.

**Related specs:**
- [`FleetGameSpec.md`](FleetGameSpec.md) — simultaneous hidden commit patterns
- [`MatchSpec.md`](../../MatchSpec.md) — lifecycle, resume, abandon

---

## 2. Catalog metadata

| Field | Value |
|-------|-------|
| **Section** | Party |
| **UI template** | R — Role split (`roleSplit`) — simultaneous commit |
| **Stat kind** | `bluffPoints` (new; match/clash wins) |
| **Ruleset (v1)** | `double_bluff_standard` |
| **Catalog id** | `party.doubleBluff` |
| **MatchType** | `doubleBluff` (when implemented) |

**Display name:** Double Bluff  
**Marketing blurb:** "Commit your target — match or clash, then throw."

---

## Player count

| Question | Answer |
|----------|--------|
| **Solo?** | No |
| **Minimum** | 2 |
| **Recommended** | 2 |
| **App maximum** | 2 |

---

## 3. MVP Scope

### In scope (v1)

| Item | Default | Configurable |
|------|---------|--------------|
| Win score | **11** | 7 / 11 / 15 |
| Commit timer | **15s** | 10 / 15 / 20 |
| Commit fields | Segment + ring intent S/D/T | — |
| Bull wildcard | Commit bull → copy opponent segment after reveal | On / off |
| Match resolution | Both throw at shared segment — higher ring wins **2** pts | — |
| Clash resolution | Each throws at **opponent's** segment — higher ring wins **2** pts | — |
| Tie on throw | **0** points; same thrower starts next commit | — |
| Darts per throw phase | **1** each | Fixed v1 |
| Pass-and-play | Hidden commit with privacy curtain | — |
| Undo | Undo last throw phase only | — |
| History | Points, match vs clash ratio | — |

### Out of scope (v1)
- 3+ players
- Best-of-3 throws per phase

---

## 4. Product goals

| Goal | How Double Bluff delivers |
|------|---------------------------|
| **Poker at the oche** | Reading opponent favorites |
| **Quick party** | 10–15 min sessions |
| **Hidden commit UX** | Reuse Fleet pass-and-play patterns |
| **Dart Buddy exclusive** | Simultaneous segment poker |

---

## 5. Rules Engine (`DoubleBluffEngine`)

### 5.1 Config (`MatchConfigDoubleBluff`, payload v1)

| Field | Type | Default |
|-------|------|---------|
| `pointsToWin` | Int | `11` |
| `commitSeconds` | Int | `15` |
| `bullWildcard` | Bool | `true` |

### 5.2 Commit phase

Each player secretly selects:
```text
Commit { segment: 1...20|bull, ringIntent: S|D|T }
```

If timer expires: random legal commit.

### 5.3 Reveal & mode

| Condition | Mode |
|-----------|------|
| Same `segment` (ring may differ) | **Match** |
| Different `segment` | **Clash** |
| Bull wildcard + one bull commit | Bull player copies opponent's segment → then Match/Clash |

### 5.4 Throw phase

| Mode | Throw at |
|------|----------|
| Match | Shared segment |
| Clash | Opponent's committed segment |

Each player throws **1 dart**.

**Ring rank:** T > D > S > miss (0).

Higher rank wins **2** points. Tie → 0 points.

### 5.5 State

```text
scores: [PlayerId: Int]
phase: commit | reveal | throw | complete
commits: [PlayerId: Commit?]
throwResults: [PlayerId: DartHit?]
```

---

## 6. UI notes

- Commit: segment grid + S/D/T picker; lock-in button; timer bar.
- Reveal: dramatic flip; Match vs Clash banner.
- Pass-and-play: `FleetPassDeviceCurtain` between commits.

---

## 7. Localization (draft)

| Key | EN (draft) |
|-----|------------|
| `play.rules.doubleBluff.title` | Double Bluff |
| `play.rules.doubleBluff.summary` | Commit a target in secret — match or clash decides what you throw. |
| `play.bluff.match` | Match! |
| `play.bluff.clash` | Clash! |

---

## 8. Open questions

1. Bull wildcard on by default?
2. 2 points per win vs 1 (race to 11 length)?

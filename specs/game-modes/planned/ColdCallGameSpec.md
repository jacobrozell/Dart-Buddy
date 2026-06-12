# Cold Call Game Specification

## 1. Purpose

Define **Cold Call** — a practice drill where the app picks a **secret segment** and gives **hot/cold** TTS feedback after each dart based on board-graph distance. Lower dart count wins.

**Status:** Planned (`practice.coldCall`).  
**Brainstorm origin:** [`FutureIdeas/custom-games-brainstorm.md`](../../../FutureIdeas/custom-games-brainstorm.md) §25.

**Related specs:**
- [`CallAndHitGameSpec.md`](CallAndHitGameSpec.md) — voice drill shell
- [`VoiceDrillUITemplateSpec.md`](VoiceDrillUITemplateSpec.md) — Template J
- [`CalloutVoicesSpec.md`](../../CalloutVoicesSpec.md) — temperature phrases
- [`SoloPracticeModesSpec.md`](../../SoloPracticeModesSpec.md) — solo platform

---

## 2. Catalog metadata

| Field | Value |
|-------|-------|
| **Section** | Practice |
| **UI template** | J — Voice drill (`voiceDrill`) |
| **Stat kind** | `practiceAccuracy` (darts to find, avg temperature) |
| **Ruleset (v1)** | `cold_call_standard` |
| **Catalog id** | `practice.coldCall` |
| **MatchType** | `coldCall` (when implemented) |

**Display name:** Cold Call  
**Marketing blurb:** "Find the secret wedge — hotter or colder after every dart."

---

## Player count

| Question | Answer |
|----------|--------|
| **Solo?** | **Yes** — primary |
| **Minimum** | 1 |
| **Recommended** | 1 |
| **App maximum** | 2 (alternating darts on same secret — v2); v1 solo |

---

## 3. MVP Scope

### In scope (v1)

| Item | Default | Configurable |
|------|---------|--------------|
| Secret target | Random **segment** 1–20 + bull | Singles only |
| Ring sensitivity | **Off** — segment distance only | Segment / Segment+ring (v2) |
| Dart cap | **15** | 10 / 15 / unlimited |
| Feedback tiers | 5 levels (see §5.3) | — |
| Input | Standard dart pad | — |
| Callout | TTS temperature after each dart | Voice picker |
| Rounds per session | **3** secrets | 1 / 3 / 5 |
| 2-player (v2) | Alternate darts; first hit wins round | — |
| History | Darts per secret, session average | — |

### Out of scope (v1)
- Competitive 2p in v1
- Visual heat map reveal before solve
- Vision verify

---

## 4. Product goals

| Goal | How Cold Call delivers |
|------|------------------------|
| **Phone magic** | Impossible offline |
| **Fast ship** | Reuses Call & Hit stack |
| **Practice fun** | Wordle geography on a dartboard |
| **Dart Buddy exclusive** | Board-graph distance + TTS |

---

## 5. Rules Engine (`ColdCallEngine`)

### 5.1 Config (`MatchConfigColdCall`, payload v1)

| Field | Type | Default |
|-------|------|---------|
| `dartCap` | Int | `15` |
| `roundCount` | Int | `3` |
| `distanceMode` | `segment` \| `segmentAndRing` | `segment` |

### 5.2 Distance metric (`BoardGraph`)

Precomputed undirected graph on segments (clock adjacency) + bull as hub.

`distance(a, b)` = shortest path edge count (bull to any segment = 1).

If `segmentAndRing`: add ring penalty (same segment different ring = +0; adjacent ring = +1).

### 5.3 Temperature tiers

| Distance | Label | TTS phrase key |
|----------|-------|----------------|
| 0 | Exact | `coldCall.exact` |
| 1 | Burning | `coldCall.burning` |
| 2 | Hot | `coldCall.hot` |
| 3–4 | Warm | `coldCall.warm` |
| 5–6 | Cold | `coldCall.cold` |
| 7+ | Freezing | `coldCall.freezing` |

### 5.4 Round flow

1. Draw secret segment (hidden).
2. Player throws; compute distance from landed segment to secret.
3. Announce temperature; increment dart count.
4. **Exact hit:** round ends; record darts used.
5. **Cap reached:** round DNF; record cap as score.
6. After `roundCount` rounds: session score = sum of darts (lower better).

---

## 6. UI notes

- No target shown — only temperature label + thermometer animation.
- On solve: reveal secret with celebration.
- Pad shows last landed segment for player reference.

---

## 7. Localization (draft)

| Key | EN (draft) |
|-----|------------|
| `play.rules.coldCall.title` | Cold Call |
| `play.rules.coldCall.summary` | Find the secret segment — listen for hotter or colder. |
| `coldCall.freezing` | Freezing |
| `coldCall.burning` | Burning! |
| `coldCall.exact` | You found it! |

---

## 8. Open questions

1. Ship 2p alternating in v1 or defer?
2. Ring-aware distance default on or off?

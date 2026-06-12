# Whisper Cricket Game Specification

## 1. Purpose

Define **Whisper Cricket** — standard cricket with **per-player hidden marks** on 20→15 + bull until a player closes a number, at which point their marks flip public and points apply normally.

**Status:** Planned (`party.whisperCricket`).  
**Brainstorm origin:** [`FutureIdeas/custom-games-brainstorm.md`](../../../FutureIdeas/custom-games-brainstorm.md) §2.

**Related specs:**
- [`CricketSpec.md`](../implemented/CricketSpec.md) — mark math, close/points rules
- [`FleetGameSpec.md`](FleetGameSpec.md) — per-participant hidden state patterns
- [`MatchSpec.md`](../../MatchSpec.md) — lifecycle, resume, abandon
- [`MatchForfeitSpec.md`](../../MatchForfeitSpec.md) — points standings

---

## 2. Catalog metadata

| Field | Value |
|-------|-------|
| **Section** | Party |
| **UI template** | B — Mark board (`markBoard`) + hidden layer |
| **Stat kind** | `cricket` (extends with `hiddenReveal` stat supplements) |
| **Ruleset (v1)** | `whisper_cricket_standard` |
| **Catalog id** | `party.whisperCricket` |
| **MatchType** | `whisperCricket` (when implemented) |

**Display name:** Whisper Cricket  
**Marketing blurb:** "Your marks stay secret until you close a number."

---

## Player count

| Question | Answer |
|----------|--------|
| **Solo?** | No |
| **Minimum** | 2 |
| **Recommended** | 2–4 |
| **App maximum** | 4 |

---

## 3. MVP Scope

### In scope (v1)

| Item | Default | Configurable |
|------|---------|--------------|
| Scoring mode | **Standard** cricket points | Standard / Cut Throat |
| Segments | 20, 19, 18, 17, 16, 15, bull | Fixed |
| Marks to close | **3** | Fixed |
| Visibility | Hidden until **close** on that segment | Fixed v1 |
| Reveal scope | On close, all marks on that segment for that player go public | — |
| Turn structure | Full 3-dart visits | — |
| Bots | Preset bots (hidden marks server-side) | — |
| Undo | Undo last dart | — |
| History | Full cricket stats + reveal count | — |

### Out of scope (v1)
- Partial reveal on 2 marks
- Pass-and-play privacy curtain (digital hidden — each player has own view in v1; pass-and-play uses handoff)
- Online multi-device hidden state

---

## 4. Product goals

| Goal | How Whisper Cricket delivers |
|------|------------------------------|
| **Hidden information** | Impossible on shared chalkboard |
| **Cricket reuse** | Same engine after reveal |
| **Mind games** | Stack marks secretly or fake weakness |
| **Dart Buddy exclusive** | Per-device fog on mark board |

---

## 5. Rules Engine (`WhisperCricketEngine`)

Extends cricket engine with visibility layer.

### 5.1 Config (`MatchConfigWhisperCricket`, payload v1)

| Field | Type | Default |
|-------|------|---------|
| `scoringMode` | `standard` \| `cutThroat` | `standard` |

All other fields inherit [`CricketSpec`](../implemented/CricketSpec.md) defaults.

### 5.2 Visibility model

Per participant, per segment:

```text
SegmentState {
  marks: Int           // 0...3
  visibility: hidden | public
  closedBy: ParticipantId?
}
```

- On hit: increment marks (cap 3). If marks reach 3 **and** segment not closed globally → **close** for that player.
- **On close:** set `visibility = public` for that player's marks on that segment; apply standard cricket point rules to opponents' open segments.
- Opponents see **unknown** mark count (?) on hidden segments — not zero.

### 5.3 Opponent view

| State | Opponent UI |
|-------|-------------|
| Hidden, 0–2 marks | `?` or whisper icon |
| Hidden, closed by owner | Public marks + CLOSED badge |
| Public | Standard cricket display |

### 5.4 Cut Throat

When `cutThroat`: on reveal, points flow per cut-throat rules using true mark counts at reveal time.

---

## 6. UI notes

- Reveal animation: flip card on segment row when closed.
- Accessibility: VoiceOver on opponent device must **not** speak hidden mark counts (announce "unknown marks" only).

---

## 7. Localization (draft)

| Key | EN (draft) |
|-----|------------|
| `play.rules.whisperCricket.title` | Whisper Cricket |
| `play.rules.whisperCricket.summary` | Cricket with secret marks until you close a wedge. |
| `play.whisper.hidden` | Hidden marks |
| `play.whisper.reveal` | {name} closed {segment}! |

---

## 8. Open questions

1. Pass-and-play on one phone — privacy handoff required?
2. Show opponents "activity" hint (segment glow on hit without count)?

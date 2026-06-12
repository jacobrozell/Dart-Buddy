# Echo Game Specification

## 1. Purpose

Define **Echo** — a competitive voice-only duel where the app calls targets via TTS and players throw without seeing a scoreboard. Opponents verify hits on-device (honor system) or via Guided Play Companion.

**Status:** Planned (`party.echo`).  
**Brainstorm origin:** [`FutureIdeas/custom-games-brainstorm.md`](../../../FutureIdeas/custom-games-brainstorm.md) §1.

**Related specs:**
- [`CallAndHitGameSpec.md`](CallAndHitGameSpec.md) — voice drill shell, hit/miss input
- [`VoiceDrillUITemplateSpec.md`](VoiceDrillUITemplateSpec.md) — Template J chrome
- [`CalloutVoicesSpec.md`](../../CalloutVoicesSpec.md) — TTS phrases
- [`GuidedPlayCompanionSpec.md`](../../GuidedPlayCompanionSpec.md) — sighted verifier (optional v1)
- [`GuidedPlayAccessibilitySpec.md`](../../GuidedPlayAccessibilitySpec.md) — blind-play profile
- [`MatchSpec.md`](../../MatchSpec.md) — lifecycle, resume, abandon
- [`MatchForfeitSpec.md`](../../MatchForfeitSpec.md) — lives-based standings

---

## 2. Catalog metadata

| Field | Value |
|-------|-------|
| **Section** | Party |
| **UI template** | J — Voice drill (`voiceDrill`) + lives chrome |
| **Stat kind** | `voiceDuel` (new; hits verified / lives remaining) |
| **Ruleset (v1)** | `echo_standard` |
| **Catalog id** | `party.echo` |
| **MatchType** | `echo` (when implemented) |

**Display name:** Echo  
**Marketing blurb:** "Close your eyes — the app is the only scoreboard."

---

## Player count

| Question | Answer |
|----------|--------|
| **Solo?** | No — verification requires an opponent |
| **Minimum** | 2 humans |
| **Recommended** | 2 |
| **App maximum** | 4 (round-robin or bracket optional v2; v1 = 2) |

### Brainstorm
- v1 ships **2-player** elimination; 3–4 player support deferred.
- Thrower may use Guided Play profile (reduced visual chrome); verifier always sees Hit/Miss controls.
- No dart pad segment entry in v1 — honor scoring only.

---

## 3. MVP Scope

### In scope (v1)

| Item | Default | Configurable |
|------|---------|--------------|
| Lives | **3** each | 3 / 5 |
| Target pool | **Doubles** | Singles / Doubles / Triples / Mixed |
| Targets per round | **1** (call → throw → verify) | Fixed v1 |
| Callout | TTS + large on-screen label for verifier only | Voice picker |
| Verification | **Opponent tap** Hit / Miss | Companion link (optional) |
| Wrong verify penalty | Off in v1 | — |
| Turn order | Alternating rounds | — |
| Undo | Undo last verify decision (both players confirm) | — |
| History | Full `MatchRecord` | — |

### Out of scope (v1)
- Vision auto-verify of landed segment
- Segment pad entry by thrower
- Bots as verifier
- Team Echo / relay roles (see Buddy Relay)
- Achievements

---

## 4. Product goals

| Goal | How Echo delivers |
|------|-------------------|
| **Accessibility flagship** | Auditory darts as a competitive mode, not just practice |
| **Pub novelty** | Eyes-closed throws with phone as referee |
| **Guided Play story** | Natural upsell to Companion verifier for mixed-sight groups |
| **Dart Buddy exclusive** | No major dart app ships voice-only PvP |

---

## 5. Rules Engine (`EchoEngine`)

Pure domain — no SwiftUI.

### 5.1 Config (`MatchConfigEcho`, payload v1)

| Field | Type | Default |
|-------|------|---------|
| `lives` | Int | `3` |
| `targetKind` | `singles` \| `doubles` \| `triples` \| `mixed` | `doubles` |
| `verificationMode` | `opponentTap` \| `companion` | `opponentTap` |

### 5.2 Round flow

1. App draws target from pool (no repeat until pool exhausted, then reshuffle).
2. TTS announces target to **both** devices; thrower's screen may hide label per Guided Play.
3. Thrower throws (up to **3 darts**; first successful hit ends round early — verifier decides).
4. Verifier taps **Hit** or **Miss**.
5. **Miss** (or wrong target hit): thrower loses **1 life**.
6. **Hit**: no life loss; rotate to next thrower.
7. Last player with lives > 0 wins.

### 5.3 State

```text
participants[]: { id, lives }
currentThrowerIndex
targetPool, targetIndex
roundHistory[]: { thrower, target, outcome, verifierId }
```

### 5.4 Edge cases

| Case | Rule |
|------|------|
| Tie on simultaneous elimination | Sudden-death round — same target, fewer lives (1 each) |
| Dispute | Either player may request **re-throw** once per match; costs requester 1 life if original Miss upheld |
| Abandon | Standard forfeit — most lives wins |

---

## 6. UI notes

- **Verifier layout:** large Hit (green) / Miss (red); target shown at top.
- **Thrower layout:** minimal — "Listen" + optional haptic on call; no running score for thrower (optional lives count only).
- VoiceOver: announce target on thrower device when Guided Play enabled.

---

## 7. Localization (draft)

| Key | EN (draft) |
|-----|------------|
| `play.rules.echo.title` | Echo |
| `play.rules.echo.summary` | Voice-only duel — hit called targets; miss costs a life. |
| `play.echo.verifier.prompt` | Did they hit {target}? |
| `play.echo.lives` | {n} lives |

---

## 8. History & stats

- `ModeStatKind.voiceDuel`: rounds played, hit rate (verified), avg darts per hit.
- History card: winner, target kind, lives remaining margin.

---

## 9. Open questions

1. Ship 2p only in v1, or 3–4 round-robin?
2. Is Companion required for App Store accessibility narrative, or opponent tap sufficient?
3. Should thrower see opponent lives count?

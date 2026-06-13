# Guided Practice Game Specification

## 1. Purpose
Define **Guided Practice** — the first Guided Play surface: audio-led target practice for blind and low-vision players, with optional sighted guide verification. Shares the Call & Hit rules engine; differs in defaults, companion role, landing feedback, and accessibility chrome.

**Status:** **WIP / R&D** — draft spec; not scheduled. See [`FutureIdeas/guided-play-blind-darts.md`](../../../FutureIdeas/guided-play-blind-darts.md).

**Parent platform:** [`GuidedPlayAccessibilitySpec.md`](../../GuidedPlayAccessibilitySpec.md)

**Engine / voice / solo platform:**
- [`CallAndHitGameSpec.md`](CallAndHitGameSpec.md) — rules, presets, persistence
- [`CalloutVoicesSpec.md`](../../CalloutVoicesSpec.md) — TTS
- [`VoiceDrillUITemplateSpec.md`](VoiceDrillUITemplateSpec.md) — Template J
- [`GuidedPlayCompanionSpec.md`](../../GuidedPlayCompanionSpec.md) — guide role
- [`SoloPracticeModesSpec.md`](../../SoloPracticeModesSpec.md)

**Not to be confused with:** [Blind Killer](BlindKillerGameSpec.md) (`party.blindKiller`) — unrelated party game.

---

## 2. Catalog metadata

| Field | Value |
|-------|-------|
| **Section** | Practice |
| **Display name** | Guided Practice |
| **Catalog id** | `practice.guidedPractice` |
| **UI template** | J — Voice drill (Guided profile) |
| **Stat kind** | `practiceAccuracy` (same as Call & Hit; fingerprint includes `guidedPlay: true`) |
| **Ruleset** | `guided_practice_v1` (extends `call_and_hit_standard`) |
| **MatchType** | `guidedPractice` (recommended) or shared `callAndHit` with profile flag |

**Blurb:** *“Called targets with a guide or on your own — built for VoiceOver.”*

---

## 3. Player count & roles

| Shape | Supported |
|-------|-----------|
| Solo self-report | Yes — thrower uses VoiceOver Hit/Miss |
| Thrower + guide (one device) | Yes — primary intended flow from field research |
| Guide only (no thrower profile) | No |

| Question | Answer |
|----------|--------|
| **Solo?** | Yes (`maximumPlayers: 1` on roster; guide is not a roster participant) |
| **Minimum** | 1 human thrower |
| **App maximum** | 1 roster seat |

Guide is a **session role**, not a `MatchParticipantRecord` in v1.

---

## 4. MVP scope

### In scope (v1)
| Item | Guided Practice default | Call & Hit contrast |
|------|-------------------------|---------------------|
| Target pools | Singles / doubles / triples | Same |
| Session presets | **Guided Standard** (50·3·singles), **Guided Sharp** (50·1) | Standard / Sharp |
| Callouts | On, slower rate | On, default rate |
| Result speech | **On** (“Hit”, “Miss”, + detail) | Off by default |
| Haptics on result | **On** for thrower feedback | Optional |
| Guide role | **Setup choice** | N/A |
| Landing detail | Guide optional chips | N/A |
| History | Full match parity | Same |
| Entry | Modes → Practice + Settings → Guided Play | Modes only |

### Out of scope (v1)
- Two-device guide sync
- Vision auto-detect
- Competitive Guided X01

---

## 5. Setup flow

Reachable from:
1. **Modes tab** → Practice → **Guided Practice**
2. **Settings → Accessibility → Guided Play** → Start practice
3. VoiceOver first-run prompt → Guided Practice

| Control | Options | Default |
|---------|---------|---------|
| **Session role** | I'm throwing · I'm the guide · Solo self-report | I'm throwing |
| Preset | Guided Standard · Guided Sharp · Custom | Guided Standard |
| Target kind | Singles · Doubles · Triples | Singles |
| Target count / darts | Same as Call & Hit | 50 / 3 |
| Callout voice | Guided voice preset (slower) | Accessibility default |
| Thrower audio | Speaker · This device · (guide device only) | Speaker |

**Guide role setup copy:** *“You'll confirm each throw after the callout. The thrower can listen without touching the phone.”*

**Thrower role copy:** *“Use headphones or stand near the phone. You'll hear the target and result.”*

---

## 6. Active session — thrower experience

Thrower may never touch the phone (guide holds it):

1. Hear target callout (TTS).
2. Throw.
3. Hear result: *“Hit, sixteen”* or *“Miss, sixteen. Single five.”* (detail when guide adds it).
4. Feel haptic: long = hit, double short = miss (if device reachable or Watch future).

Solo self-report: same callout → thrower finds Hit/Miss via VoiceOver.

---

## 7. Active session — guide experience

When role = guide, UI emphasizes **verifier** layout ([`GuidedPlayCompanionSpec.md`](../../GuidedPlayCompanionSpec.md)):

- Large current target (already called — guide can repeat via button)
- After throw: **Hit** · **Miss** · **Add detail** (optional)
- Detail quick chips: single adjacent segments, *“Wide left”*, *“Wire”*, *“Bounce out”*
- **Repeat callout** button for thrower
- **Pause** / **End session**

Guide does not need VoiceOver for v1 happy path — large touch targets, high contrast.

---

## 8. Landing detail (guide optional)

When guide taps **Add detail** after Miss (or Hit with wrong bed):

| Chip category | Examples | Spoken to thrower |
|---------------|----------|-------------------|
| Adjacent single | S5, S9 (contextual to target 16) | “Miss. Single five.” |
| Directional | Wide left, wide right, low, high | “Miss. Wide left.” |
| Wire / bounce | Wire, fell out | “Miss. Wire.” |

Stored in `CallAndHitTargetEvent.guideDetailRaw` for history timeline — not scored separately in v1.

---

## 9. Rules engine

**Reuse `CallAndHitEngine`** with extended config:

```swift
// MatchConfigGuidedPractice v1 (extends CallAndHit)
guidedPlayProfile: true
sessionRole: thrower | guide | soloSelfReport
resultSpeechEnabled: true  // default true
calloutSpeechRate: slow | default
hapticFeedbackEnabled: true
```

Events: same as Call & Hit + optional `guideDetail` string on target event.

---

## 10. Summary & history

Same solo summary shell ([`SoloPracticeMatchSummarySupplement.md`](../../SoloPracticeMatchSummarySupplement.md)).

History timeline row examples:
- `#12 — Sixteen — Hit`
- `#13 — Double sixteen — Miss — Single ten`

History filter: **Guided Practice** distinct from Call & Hit if separate `MatchType`; otherwise badge *Guided* on card.

Stats fingerprint includes `guidedPlay: true` so Guided sessions don't mix with sighted Call & Hit comparisons unless user opts in.

---

## 11. Config presets

| Preset | Targets | Darts | Kind | Notes |
|--------|---------|-------|------|-------|
| **Guided Standard** | 50 | 3 | Singles | Default onboarding |
| **Guided Sharp** | 50 | 1 | Singles | Reactive |
| **Guided Doubles** | 50 | 3 | Doubles | Checkout beds |

---

## 12. Localization

**Catalog:** `modes.catalog.practice.guidedPractice.name`, `.blurb`

**Setup:** `play.guidedPractice.setup.role.thrower|guide|solo`, `.throwerAudio`, `.guidedStandard`, …

**Gameplay:** `play.guidedPractice.repeatCallout`, `play.guidedPractice.addDetail`, `play.guidedPractice.detail.singleFormat`, `.detail.wideLeft`, …

**How to play:** `play.rules.guidedPractice.overview|roles|guide|solo`

---

## 13. Analytics

Extends Guided Play events ([`GuidedPlayAccessibilitySpec.md`](../../GuidedPlayAccessibilitySpec.md) §9):
- `guided_practice_detail_added` — count only, no segment text in payload
- `guided_practice_role` — `guide` | `thrower` | `solo`

Always attach `isVoiceOverRunning` at session start from `ClientEnvironment`.

---

## 14. Testing

- VO-only solo completion (3 targets smoke)
- Guide flow: callout → miss + detail → thrower TTS mock asserts phrase
- Fingerprint separates guided vs callAndHit stats
- Blind Killer catalog search does not route to Guided Practice

---

## 15. Verification
| Field | Value |
|-------|--------|
| **Status** | WIP / R&D |

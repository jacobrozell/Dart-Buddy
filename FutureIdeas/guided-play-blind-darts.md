# Guided Play — Blind & Low-Vision Darts (R&D Brief)

**Status:** WIP / R&D — **not scheduled for implementation.** Documenting intent and dependencies only.

**Inspiration:** Sighted guide calls targets; blind player throws; guide verifies landing and informs result (YouTube / community practice pattern).

**Authoritative specs (draft — subject to change):**
- [`specs/GuidedPlayAccessibilitySpec.md`](../specs/GuidedPlayAccessibilitySpec.md)
- [`specs/game-modes/planned/GuidedPracticeSpec.md`](../specs/game-modes/planned/GuidedPracticeSpec.md)
- [`specs/GuidedPlayCompanionSpec.md`](../specs/GuidedPlayCompanionSpec.md)

**Related shipped foundation:** VoiceOver context analytics (`ClientEnvironment.isVoiceOverRunning`, `client_environment_changed`) — helps measure accessibility usage if/when this ships; not a dependency for R&D.

**Do not confuse with:** [Blind Killer](../specs/game-modes/planned/BlindKillerGameSpec.md) — unrelated party game.

---

## Problem

Standard Dart Buddy flows assume the player can see the scoreboard, segment pad, and board UI. Blind and low-vision players need:

1. **Audible target callouts** before each throw  
2. **Verification** of where the dart landed (today: human guide or honor system)  
3. **Talk-back** — spoken confirmation of hit/miss and corrective detail  
4. Eventually **camera assist** so a sighted guide is optional  

---

## Proposed experience (north star)

| Step | v0 (human guide) | v1 (partial auto) | v2 (north star) |
|------|------------------|-------------------|-----------------|
| Call target | App TTS or guide voice | App TTS | App TTS |
| Throw | Player at oche | Same | Same |
| Verify | Guide taps Hit/Miss on phone | Camera **suggests** segment; guide confirms | Camera + high confidence auto; user can correct |
| Inform | TTS + haptics to thrower | Same | Same + optional **voice reply** (“yes” / “miss”) |
| Summary | Activity history | Same | Same |

---

## Major dependencies (all WIP)

### 1. Talk-back caller (TTS + optional STT)

| Piece | Status | Notes |
|-------|--------|-------|
| **Outbound TTS** (call target, read result) | Spec’d | [`CalloutVoicesSpec.md`](../specs/CalloutVoicesSpec.md) — shares work with Call & Hit |
| **Inbound voice** (thrower says “hit” / “miss”) | **Not spec’d** | Requires speech recognition, oche noise handling, push-to-talk vs always-on |
| **Mic permission** | **Not implemented** | `NSMicrophoneUsageDescription` + Settings copy; privacy review |
| **Audio session** | Partial | `FeedbackAudioSession` today is TTS/output-oriented; duplex recording + playback TBD |

**Open R&D questions:**
- Push-to-talk button vs hands-free listen after callout?  
- Works with AirPods / Bluetooth at 2+ meters from board?  
- Locale support (en first)?  
- Fallback when STT fails → guide tap or large Hit/Miss only?

### 2. AI camera assist

| Piece | Status | Notes |
|-------|--------|-------|
| Board calibration + segment detect | R&D | [`AutoScoringVisionSpec.md`](../specs/AutoScoringVisionSpec.md) Phase A — assistive suggest, not auto-commit |
| **Camera permission** | Not in app | `NSCameraUsageDescription`; calibration UX; low-light pub scenario |
| Guided Play integration | Spec’d conceptually | Vision proposes landing; **human confirm required** in Guided Play profile (never silent auto-score for accessibility trust) |
| On-device vs cloud ML | Undecided | Privacy, latency, offline pub |

**Open R&D questions:**
- Phone mount position (tripod behind oche)?  
- Single dart vs 3-dart bed visibility?  
- Who confirms when vision + guide disagree?

### 3. Human guide path (no AI)

Lowest technical bar — documented in [`GuidedPlayCompanionSpec.md`](../specs/GuidedPlayCompanionSpec.md). Could ship **before** camera/mic if product prioritizes accessibility without ML. **Not decided.**

### 4. Shared practice engine

Call & Hit engine ([`CallAndHitGameSpec.md`](../specs/game-modes/planned/CallAndHitGameSpec.md)) is the likely rules core. Guided Practice = profile + audio/companion chrome. **Blocked on product decision**, not engine complexity.

---

## Permissions matrix (future)

| Permission | Purpose | When prompted |
|------------|---------|---------------|
| **Microphone** | Voice hit/miss (STT); optional ambient level for oche noise gate | First use of talk-back |
| **Camera** | Board calibration + dart landing assist | First vision session |
| **Speech recognition** | On-device / server per iOS API choice | Bundled with mic flow |

Privacy policy and App Store nutrition label updates required before ship.

---

## Analytics (already partially in place)

- `isVoiceOverRunning` on `client_environment_changed` and session start (when built)  
- Helps understand **accessibility context** of the user base — not surveillance  
- Guided Play–specific events remain **draft** in [`FirebaseBackendAnalyticsSpec.md`](../specs/FirebaseBackendAnalyticsSpec.md) until feature is committed  

---

## Relationship to Call & Hit

| | Call & Hit | Guided Play |
|---|------------|-------------|
| Audience | General practice | Blind / low-vision + guides |
| Verification | Self-report Hit/Miss | Guide and/or camera + talk-back |
| Permissions | None extra | Mic + camera (future) |
| Status | Planned practice mode | **WIP R&D** |

May merge into one catalog entry with presets later — **undecided.**

---

## Suggested research order (when resuming)

1. **Human guide only** prototype — validate UX with Call & Hit + Companion spec (no new permissions)  
2. **TTS caller** — CalloutVoices platform  
3. **Mic + STT spike** — push-to-talk hit/miss in noisy room  
4. **Vision assist spike** — AutoScoringVision Phase A suggest-only  
5. **Combine** — camera suggest + guide confirm + talk-back result  

---

## Decisions explicitly deferred

- [ ] Separate Modes card vs Call & Hit preset  
- [ ] Guide detail chips on Hit vs Miss only  
- [ ] VoiceOver first-run prompt  
- [ ] Blind player external testing budget  
- [ ] Ship human-guide path without AI  
- [ ] Talk-back required vs optional  

---

## References

- [`FutureIdeas/party-practice-modes.md`](party-practice-modes.md) — Call & Hit effort notes  
- [`specs/AutoScoringVisionSpec.md`](../specs/AutoScoringVisionSpec.md)  
- [`specs/SecurityPrivacySpec.md`](../specs/SecurityPrivacySpec.md) — update when permissions land  

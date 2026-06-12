# Guided Play — Accessibility Specification

## 1. Purpose
Define **Guided Play** — an accessibility-first play experience for blind and low-vision dart players, modeled on real-world practice where a sighted guide calls targets, observes throws, and confirms results. The phone can act as **caller**, **scorekeeper**, or both; a human guide can replace or augment app speech.

**Product name:** **Guided Play** (Settings label). Avoid user-facing copy **“Blind mode”** — confuses with the party game [Blind Killer](game-modes/planned/BlindKillerGameSpec.md) (`party.blindKiller`).

**Status:** **WIP / R&D** — documented for future exploration; **not scheduled for implementation.** Product decisions (human guide only vs camera + talk-back) are **open.**

**R&D brief:** [`FutureIdeas/guided-play-blind-darts.md`](../FutureIdeas/guided-play-blind-darts.md) — dependencies, permissions, deferred decisions.

**Blocked on (when pursuing full vision):**
- Talk-back caller (TTS + optional STT) and **microphone** permission
- AI **camera assist** ([`AutoScoringVisionSpec.md`](AutoScoringVisionSpec.md) Phase A suggest-only)
- Privacy / App Store copy for mic + camera

**May ship incrementally:** human guide + TTS only (no new permissions) — see R&D brief § Suggested research order. **Not committed.**

**Builds on (when resumed):** Call & Hit engine ([`CallAndHitGameSpec.md`](game-modes/planned/CallAndHitGameSpec.md)), callout platform ([`CalloutVoicesSpec.md`](CalloutVoicesSpec.md)).

**Motivation:** Blind players at the oche cannot rely on visual scoreboards, segment pads, or board diagrams. Guided Play prioritizes **audio, VoiceOver, haptics, and optional human guide** over sighted-assumptive UI.

**Related:**
- [`GuidedPracticeSpec.md`](game-modes/planned/GuidedPracticeSpec.md) — first shipped surface (practice drill)
- [`GuidedPlayCompanionSpec.md`](GuidedPlayCompanionSpec.md) — sighted guide / verifier role
- [`AccessibilitySpec.md`](AccessibilitySpec.md)
- [`SoloPracticeModesSpec.md`](SoloPracticeModesSpec.md)
- [`FirebaseBackendAnalyticsSpec.md`](FirebaseBackendAnalyticsSpec.md) — `client_environment_changed`, `isVoiceOverRunning`
- Code: `ClientEnvironment`, `ClientEnvironmentMonitor` in `Support/Diagnostics/`

---

## 2. Real-world model (reference)

Observed practice pattern (sighted guide + blind thrower):

1. Guide calls the target (“sixteen”, “double sixteen”).
2. Thrower throws at the board.
3. Guide verifies where the dart landed relative to the called target.
4. Guide informs thrower: hit, miss, or corrective detail (“single five”, “wide left”).
5. Repeat; summary at end.

Guided Play digitizes steps **1, 4, and 5** in software; step **3** is human guide (v1) or honor self-report (solo), with vision assist deferred ([`AutoScoringVisionSpec.md`](AutoScoringVisionSpec.md)).

---

## 3. Product goals

| Goal | Approach |
|------|----------|
| Play without reading the screen | TTS callouts + VoiceOver + haptics |
| Optional sighted partner | Companion verifier screen ([`GuidedPlayCompanionSpec.md`](GuidedPlayCompanionSpec.md)) |
| Honest training loop | Hit/Miss + optional landing detail for learning |
| Measure blind-player usage | VoiceOver context on session analytics (privacy-safe) |
| Path to competitive play | Deferred — X01/Cricket guided overlay is Phase 4+ R&D |

---

## 4. Scope phases

> **Note:** All phases below are R&D targets. None are committed to a release train.

### Phase 0 — Documentation only (current)
- Specs + R&D brief; VoiceOver analytics in production for general accessibility insight

### Phase 1 — Guided Practice (human guide + TTS)
- Catalog entry: `practice.guidedPractice` or profile flag on Call & Hit
- Thrower solo OR thrower + guide (one device)
- Same target engine as Call & Hit; Guided Play UI/audio profile
- Full match history + solo summary ([`SoloPracticeMatchSummarySupplement.md`](SoloPracticeMatchSummarySupplement.md))

### Phase 2 — Talk-back (microphone + STT)
- Thrower speaks “hit” / “miss” after throw (push-to-talk or gated listen)
- Requires `NSMicrophoneUsageDescription`, speech recognition API choice, oche noise QA
- Fallback to guide tap or on-screen Hit/Miss when STT unavailable

### Phase 3 — Camera assist (AI suggest)
- Vision proposes segment landing; guide or thrower **confirms** ([`AutoScoringVisionSpec.md`](AutoScoringVisionSpec.md))
- Requires camera permission + calibration UX
- Never silent auto-commit in Guided Play profile

### Phase 4 — Guided overlay on scored modes
- VoiceOver-first **reduced scoring pad** for X01 (segment announce on focus, submit confirmation)
- Optional guide confirms each dart for thrower who cannot see pad
- Feature flag `enableGuidedPlayOverlay`

### Out of scope until R&D completes
- Two-phone real-time sync
- Automatic hit detection without human confirm
- Replacing WCAG baseline VoiceOver on standard screens

---

## 5. Guided Play profile (Settings)

Global preference **`guidedPlayEnabled`** (Settings → Accessibility → Guided Play).

When enabled:

| Behavior | Change |
|----------|--------|
| Default entry | Surfaces Guided Practice prominently (Modes card + Settings link) |
| Callouts | **On** by default; slower speech rate preset |
| Hit/Miss feedback | Spoken confirmation **on** by default |
| Haptics | Distinct Hit/Miss patterns on thrower feedback |
| Visual target hero | Still rendered (sighted guide, partial vision) but not required |
| VoiceOver | **Less-is-more** announcements; focus order optimized for practice loop |
| Reduce Motion | All transitions instant |

**Auto-suggest:** On first launch with `UIAccessibility.isVoiceOverRunning == true`, show one-time sheet explaining Guided Practice (dismissible; not nagging on every launch).

Does **not** hide standard X01/Cricket — users choose their path.

---

## 6. Session roles

| Role | Who | Phone interaction |
|------|-----|-------------------|
| **Thrower** | Blind/low-vision player at oche | Minimal or none — listens via speaker/AirPods |
| **Guide** | Sighted partner | Holds phone; confirms Hit/Miss + optional detail |
| **Solo self-report** | Thrower alone | VoiceOver to Hit/Miss after callout |

Setup picker: **I'm throwing · I'm guiding · Solo (self-report)** — see Companion spec for guide layout.

Single-device v1: guide holds phone throughout; thrower does not need to touch device between targets.

---

## 7. Audio architecture

Layers (all can be active):

| Layer | Source | Purpose |
|-------|--------|---------|
| **Callout TTS** | [`CalloutVoiceService`](CalloutVoicesSpec.md) | Speaks target before throw |
| **Result TTS** | Guided Play extension | “Hit”, “Miss”, optional detail phrase |
| **VoiceOver** | System | Focus order, button labels when user navigates UI |
| **Haptics** | `FeedbackPreferences` | Hit = long pulse; Miss = two short pulses |

**Priority:** Incoming callout cancels previous speech. Guide tap triggers result TTS even when VoiceOver is running (uses TTS channel, not VO interrupt).

**Bluetooth:** Document recommendation for thrower AirPods + guide holding phone in Companion flow.

Phrase catalog extension: [`CalloutVoicesSpec.md`](CalloutVoicesSpec.md) § Guided Play phrases.

---

## 8. VoiceOver requirements (Guided Play screens)

Beyond [`AccessibilitySpec.md`](AccessibilitySpec.md):

- **First focus** on active target announcement element after each advance
- Hit/Miss: labels include target context — *“Hit, sixteen”* / *“Miss, sixteen”*
- Progress: *“Target 12 of 50”* — not color-only streak
- Guide landing chips: full words (*“Single five”*, not *“S5”*)
- No dart grid on Template J — already VO-friendly
- Rotor actions (future): “Repeat target”, “Skip guide detail”

Manual evidence: [`accessibility/wcag-2.1-aa/screens/guided-practice-match.md`](../accessibility/wcag-2.1-aa/screens/guided-practice-match.md)

---

## 9. Analytics & privacy

Leverage existing **`ClientEnvironmentSnapshot.isVoiceOverRunning`** ([`ClientEnvironment.swift`](../Support/Diagnostics/ClientEnvironment.swift)):

| Event | When | Metadata |
|-------|------|----------|
| `client_environment_changed` | VO toggled | `changedSignals` includes `voiceover` |
| `guided_practice_started` | Session start | `role` (thrower/guide/solo), `isVoiceOverRunning`, `guidedPlayEnabled`, `dartsPerTarget`, `targetKind` |
| `guided_practice_completed` | Session end | `accuracy_bucket`, `hadGuide`, `isVoiceOverRunning` |
| `guided_play_settings_enabled` | User enables profile | `source` (settings/vo_prompt) |

**Privacy rules:**
- Never log player name, guide name, or landing-detail text
- `isVoiceOverRunning` is boolean context only — not used for paywalls or reduced features
- Use aggregate data to prioritize blind-player UX investments

Add events to [`FirebaseBackendAnalyticsSpec.md`](FirebaseBackendAnalyticsSpec.md) §12 allowlist when enabling.

---

## 10. Relationship to Call & Hit

| Aspect | Call & Hit | Guided Practice |
|--------|------------|-----------------|
| Engine | `CallAndHitEngine` | **Same** |
| MatchType | `callAndHit` or shared | `guidedPractice` **or** `callAndHit` + `guidedPlayProfile: true` (implementation TBD) |
| UI profile | Standard Template J | Template J + `GuidedPlayChrome` |
| Default callouts | On | On + slower rate |
| Result speech | Off by default | **On** |
| Guide role | No | **Yes** |
| Landing detail | No | Optional chips |
| Settings entry | Modes card | Modes + Accessibility + VO prompt |

**Recommendation:** Single engine, two catalog entries OR one entry with Guided Play preset chip — product prefers **dedicated Modes card** (`practice.guidedPractice`) so blind players find it without hunting Call & Hit options.

---

## 11. Localization

Key prefix: `guidedPlay.*`, `settings.guidedPlay.*`, `modes.catalog.practice.guidedPractice.*`

- Plain language; avoid “blind” in UI strings
- Guide role: *“Guide”* / *“Verifier”* — localized
- Landing detail chips: full segment names for TTS clarity

---

## 12. Testing

### Unit
- Guided profile merges correct defaults into `MatchConfigCallAndHit`
- Analytics payload includes `isVoiceOverRunning` at start

### UI / accessibility
- VoiceOver traversal: setup → 3 targets → summary without sighted assistance
- Companion flow: guide confirms hit + detail → thrower hears result (mock TTS)
- Haptic firing when thrower role selected and guide reports

### Manual
- Blind player advisory session (external tester) before ship
- AirPods + phone speaker scenarios

---

## 13. Future improvements
- Guided X01 with audio checkout hints
- Watch haptics for thrower when guide uses phone
- Live sync second device for guide
- Community-recorded caller voice packs
- Integration with Switch Control for Hit/Miss

---

## 14. Verification
| Field | Value |
|-------|--------|
| **Status** | WIP / R&D |
| **R&D brief** | [`FutureIdeas/guided-play-blind-darts.md`](../FutureIdeas/guided-play-blind-darts.md) |

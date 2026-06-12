# Callout Voices Specification

## 1. Purpose
Define how Dart Buddy speaks **practice target callouts** and related in-session announcements. Covers voice catalog, user configuration, phrase templates, accessibility, and integration with existing turn-total speech ([`SettingsSpec.md`](SettingsSpec.md) § During Play).

**Status:** Planned — ships with Call & Hit ([`game-modes/planned/CallAndHitGameSpec.md`](game-modes/planned/CallAndHitGameSpec.md)); reusable for future modes (Around the Clock prompts, checkout drills, full "180!" caller). **Guided Practice** extends phrases and defaults — see §6 Guided Play.

**Related:**
- [`GuidedPlayAccessibilitySpec.md`](GuidedPlayAccessibilitySpec.md) — Guided Practice consumer
- [`SettingsSpec.md`](SettingsSpec.md) — global preferences surface
- [`AccessibilitySpec.md`](AccessibilitySpec.md) — WCAG expectations
- [`LocalizationSpec.md`](LocalizationSpec.md) — string key policy
- Code today: `SpeechTurnTotalCallerService`, `TurnTotalCallerService`, `FeedbackPreferences` in `Support/Services/FeedbackServices.swift`

---

## 2. Product goals
- **Hands-free at the oche** — player hears the target without reading the phone
- **Personality without gimmick** — distinct voices, clear diction, pub-appropriate volume behavior
- **Configurable** — user picks voice; can disable speech per session or globally
- **Accessible** — visual target always shown; speech is additive
- **Separate concerns** — practice callouts ≠ visit-total caller (different phrases, may share voice preference)

---

## 3. Scope

### Phase 1 — Call & Hit (v1)
- `CalloutVoiceService` protocol + `AVSpeechSynthesizer` implementation
- Bundled **voice catalog** (metadata JSON + system voice identifiers)
- Settings: default callout voice, callouts master toggle, preview button
- Per-match override: voice id + callouts on/off in Call & Hit setup
- Phrase templates for singles, doubles, triples, bull
- Session confirmation utterances optional (Hit/Miss feedback) — **default off**

### Phase 2 — Shared caller platform
- Unify turn-total caller and callout voice picker where sensible
- Optional bundled premium voices (if licensing allows)
- Rate / pitch presets per voice ("Steady", "Urgent")

### Out of scope (v1)
- Custom user-recorded voices
- Cloud voice download
- Third-party TTS APIs
- Shouting "180!" on X01 visits (separate post-1.0 feature — see `docs/release/todo.md`)

---

## 4. Voice catalog

### Catalog file
`Resources/CalloutVoices/voices.json` — versioned array consumed at launch.

```json
{
  "version": 1,
  "defaultVoiceId": "system.en-US.standard",
  "voices": [
    {
      "id": "system.en-US.standard",
      "displayNameKey": "settings.calloutVoice.standard.name",
      "descriptionKey": "settings.calloutVoice.standard.description",
      "source": "system",
      "avVoiceIdentifier": null,
      "languageCode": "en-US",
      "quality": "default",
      "previewPhraseKey": "settings.calloutVoice.previewPhrase"
    }
  ]
}
```

### Voice sources (v1)

| Source | Description |
|--------|-------------|
| `system` | `AVSpeechSynthesisVoice` from device — filter by app-supported locales (`en`, `de`, `es`, `nl`) |
| `systemEnhanced` | Enhanced quality system voices when installed |
| `bundled` | Reserved — pre-rendered clips or embedded voice configs (Phase 2) |

**Minimum shipped catalog:** 3–5 curated system voices per primary locale (e.g. US English: neutral, lower pitch, higher energy). Device shows only voices matching current app locale or device language fallback chain per [`LocalizationSpec.md`](LocalizationSpec.md).

### Selection persistence
| Key | Storage | Default |
|-----|---------|---------|
| `defaultCalloutVoiceId` | `SettingsRecord` | Catalog `defaultVoiceId` |
| `calloutsEnabled` | `SettingsRecord` | `true` |
| `calloutConfirmHitMiss` | `SettingsRecord` | `false` |
| Per-match `calloutVoiceId` | `MatchConfigCallAndHit` payload | nil → settings default |
| Per-match `calloutsEnabled` | `MatchConfigCallAndHit` payload | `true` |

Turn-total caller (`turnTotalCallerEnabled`) remains independent unless Phase 2 merges pickers.

---

## 5. Service architecture

```
CalloutVoiceService (protocol)
├── AVCalloutVoiceService      — AVSpeechSynthesizer, voice lookup from catalog
├── GatedCalloutVoiceService   — respects calloutsEnabled + soundEnabled + silent switch
└── NoopCalloutVoiceService    — tests, UI previews off
```

### API
```swift
protocol CalloutVoiceService: Sendable {
    func announceTarget(_ target: CallAndHitTarget, voiceId: String?)
    func stopSpeaking()
    func previewVoice(voiceId: String, phrase: String)
}
```

- **Single utterance queue** — new target cancels in-flight speech
- **Main-thread synthesis** — same pattern as `SpeechTurnTotalCallerService`
- **Audio session** — reuse `FeedbackAudioSession` (ambient; respects silent switch)
- **Dependency injection** — register in `AppDependencies` alongside `turnTotalCallerService`

### Gating order
1. Master `soundEnabled` (Settings)
2. `calloutsEnabled` (Settings or match override)
3. Silent switch / audio session route

Visual target display is **never** gated.

---

## 6. Phrase catalog

Spoken strings are **localized** — TTS uses the phrase in the active app language, not English-only digit reading.

### Target announcements

| Kind | Pattern (en example) | Key suffix |
|------|----------------------|------------|
| Single | "Sixteen" | `callout.target.single.{segment}` |
| Double | "Double sixteen" | `callout.target.double.{segment}` |
| Triple | "Triple twenty" | `callout.target.triple.{segment}` |
| Bull | "Bull" | `callout.target.bull` |

**Segments:** `1`…`20` — use word forms in each locale (not raw digits) for clarity at the oche.

**Implementation note:** Prefer `String(localized:)` per segment over runtime number formatting so translators control diction ("double top" regional variants deferred — use neutral "double twenty").

### Session phrases (optional v1)

| Event | Default | Key |
|-------|---------|-----|
| Preview (Settings) | "Sixteen" | `settings.calloutVoice.previewPhrase` |
| Hit confirm | Off | `callout.confirm.hit` |
| Miss confirm | Off | `callout.confirm.miss` |
| Session start | Off | `callout.session.start` |
| Session complete | Off | `callout.session.complete` |

### Timing
| Parameter | Default |
|-----------|---------|
| Pre-speak delay after target appears | 400 ms |
| Speech rate | `AVSpeechUtteranceDefaultSpeechRate` |
| Post-speak buffer before Hit/Miss enabled | 0 ms (buttons active immediately; speech non-blocking) |

### Guided Play phrases (Guided Practice)

Used when `guidedPlayProfile == true` ([`GuidedPlayAccessibilitySpec.md`](GuidedPlayAccessibilitySpec.md)). Result speech **on by default**.

| Event | Pattern (en) | Key |
|-------|--------------|-----|
| Hit result | "Hit, {target phrase}" | `callout.guided.result.hitFormat` |
| Miss result | "Miss, {target phrase}" | `callout.guided.result.missFormat` |
| Miss + detail | "Miss, {target}. {detail}." | `callout.guided.result.missDetailFormat` |
| Detail: adjacent single | "Single ten" | `callout.guided.detail.single.{segment}` |
| Detail: directional | "Wide left" | `callout.guided.detail.wideLeft` (etc.) |
| Detail: wire | "Wire" | `callout.guided.detail.wire` |

**Speech rate:** Guided Play preset uses `AVSpeechUtteranceDefaultSpeechRate * 0.85` (configurable). Pauses slightly longer between callout and result.

**VoiceOver coexistence:** Result TTS uses `CalloutVoiceService`; does not cancel VoiceOver focus but may speak over — guide flow assumes thrower is not navigating VO during throw.

---

## 7. Settings UI

New subsection under **During Play** (or **Practice** when section grows):

| Control | Type | Behavior |
|---------|------|----------|
| Callout voice | Navigation → picker list | Shows catalog display names; checkmark on selection |
| Preview | Button on picker row | Speaks preview phrase with highlighted voice |
| Enable callouts | Toggle | Master off → all practice modes visual-only |
| Confirm Hit/Miss | Toggle | Optional spoken feedback after each report |

**Picker row layout:** Name · optional quality badge · Preview button (accessibility: "Preview voice").

Match setup duplicates **Callout voice** and **Callouts on** when starting Call & Hit — pre-filled from Settings, editable for that session only.

---

## 8. Accessibility

| Requirement | Approach |
|-------------|----------|
| Deaf / HoH | Target always on screen; callouts optional |
| VoiceOver | Announce target on appear (`UIAccessibility.post`) in addition to TTS |
| Reduce Motion | No reliance on motion for target reveal |
| Cognitive | Short phrases; no overlapping speech |
| WCAG 1.1.1 | Non-text target diagram has accessibility label matching spoken phrase |

Manual evidence path: `accessibility/wcag-2.1-aa/screens/settings-callout-voice.md` (create at implementation).

---

## 9. Localization

Key prefix: `settings.calloutVoice.*`, `callout.*`

- All phrase keys in `Resources/{locale}.lproj/Localizable.strings`
- Catalog `displayNameKey` / `descriptionKey` per voice
- QA: spot-check DE/ES/NL TTS with system voices for those locales

---

## 10. Testing

### Unit
- Catalog decode; default voice fallback when id missing
- Gated service respects toggles
- Phrase resolver for each `CallAndHitTarget` kind
- `stopSpeaking()` on target advance

### UI
- Settings picker + preview
- Setup override persists into match config
- Call & Hit session fires announce on target change (inject recording mock)

### Manual
- Silent switch behavior
- Bluetooth speaker routing
- Long German compound number words intelligibility

---

## 11. Analytics

When Firebase enabled (allowlist in [`FirebaseBackendAnalyticsSpec.md`](FirebaseBackendAnalyticsSpec.md)):
- `callout_voice_changed` — `voice_id` (hashed or catalog id, not raw AVFoundation identifier)
- `callout_preview_played`

No logging of spoken target content.

---

## 12. Future improvements
- **Regional caller packs** — "Double top", "Tops" as optional phrase style toggle
- **180 / checkout caller** for X01 using same service + expanded phrase set
- **Watch haptic + text** callout companion
- **Vision mode** — speak suggested hit before player confirms
- Bundled recorded human caller clips for flagship voices

---

## 13. Verification
| Field | Value |
|-------|--------|
| **Status** | Planned |
| **Blocked by** | None (can land voice platform before Call & Hit UI) |
| **Primary consumer** | [`CallAndHitGameSpec.md`](game-modes/planned/CallAndHitGameSpec.md) |

# Firebase Backend and Analytics Specification

## 1. Purpose
Define how Firebase will be introduced for backend and analytics in a phased way without destabilizing the local-first 1.0 architecture.

---

## 2. Product Positioning
- 1.0 remains fully playable offline with local persistence as source of truth.
- 1.0 ships **Firebase Analytics** and **Firebase Crashlytics** in **Release** only, wired through `AppLogger` sinks (see `specs/LoggingSpec.md`). Debug, CI, UI tests, and placeholder plist stay off.
- Additional Firebase services are introduced incrementally for:
  - optional sync and online services
  - future online match infrastructure ([`OnlinePlaySpec.md`](OnlinePlaySpec.md))
  - future online tournaments ([`TournamentSpec.md`](TournamentSpec.md) P2)

---

## 3. Firebase Services Roadmap

## Phase 1 (1.0 — shipped)
- Firebase Analytics (privacy-safe allowlisted product-health events)
- Firebase Crashlytics (native crashes + allowlisted non-fatal logger events)

## Phase 2 (Post-1.0)
- Firebase Authentication (anonymous first, upgrade path later)
- Firestore for cloud profile/sync metadata

## Phase 3
- Cloud Functions for trusted server-side validation and online orchestration
- Optional App Check for abuse protection
- **Online play + online tournaments** — consumes Auth + Firestore + Functions; see [`OnlinePlaySpec.md`](OnlinePlaySpec.md) and [`TournamentSpec.md`](TournamentSpec.md) (P2)

---

## 4. iOS SDK Dependencies (SPM)
Installed per phase in `project.yml`:

**Phase 1 (1.0):**
- `FirebaseCore`
- `FirebaseAnalytics`
- `FirebaseCrashlytics`

**Future phases:**
- `FirebaseAuth`
- `FirebaseFirestore`
- `FirebaseFunctions`

Rules:
- Add only what is needed per phase; do not install all SDKs upfront.
- New Firebase products require spec update and explicit phase approval.

---

## 5. Architecture Integration Rules
- Firebase access is isolated behind repository/service interfaces.
- Domain engines remain Firebase-agnostic.
- Online command/event contracts remain the same regardless of backend provider.
- Local store remains canonical for offline matches; cloud sync reconciles into local models.

---

## 6. Analytics Event Design
- Track product-health events, not personal behavior profiling.
- Core event categories:
  - match lifecycle (`match_started`, `match_completed`)
  - scoring flow reliability (`turn_submitted`, `undo_used`)
  - feature adoption (`vision_session_started`, `watch_input_used`)
- Include minimal metadata only:
  - mode (`x01`, `cricket`)
  - checkout mode
  - app version
  - anonymous installation/session ids

Do not include:
- precise location
- ad identifiers
- freeform personal notes

---

## 7. Privacy and Compliance
- Respect App Tracking Transparency boundaries (no tracking profile usage).
- Maintain clear privacy disclosure updates before enabling each Firebase service.
- Support opt-out path for non-essential diagnostics where required.

---

## 8. Data Sync Strategy (Future)
- Use event timestamps + monotonic indices for conflict resolution.
- Preserve immutable match history semantics.
- Conflicts never silently overwrite completed match outcomes.

---

## 9. Operations
- Separate Firebase environments:
  - `dev`
  - `staging`
  - `prod`
- Gate release on environment correctness and analytics/crash smoke checks.

---

## 10. Testing
- Emulator-based integration tests where feasible.
- Verify offline-first behavior when Firebase is unavailable.
- Validate analytics event schema (names/params) in CI lint checks.

---

## 11. Implementation Guardrails
- Never call Firebase SDKs directly from SwiftUI views.
- Keep feature flags for Firebase-powered paths.
- Roll out each Firebase capability independently to reduce regression risk.

---

## 12. Event Catalog (Authoritative)

Source of truth in code:
- Analytics allowlist: `Support/Logging/FirebaseAnalyticsEventMapping.swift`
- Crashlytics allowlist: `Support/Logging/FirebaseCrashlyticsEventMapping.swift`
- Unit tests: `Tests/Unit/FirebaseAnalyticsEventMappingTests.swift`, `FirebaseCrashlyticsEventMappingTests.swift`

**Rule:** New product-health telemetry must update this section, the allowlist in code, and mapping tests in the same PR.

### Firebase Analytics (Release allowlist)

| Log `eventName` | Firebase name | Typical feature | Notes |
|-----------------|---------------|-----------------|-------|
| `app_bootstrap_ready` | `app_open` | App shell | Successful launch |
| `match_started` | `match_started` | Setup / match | After persist + route |
| `match_setup_baseball` | `match_setup_baseball` | Party setup | Baseball start from setup |
| `match_completed` | `match_completed` | X01 / Cricket / Baseball | Engine reports complete |
| `turn_submitted` | `turn_submitted` | X01 / Cricket | Accepted turn |
| `turn_undone` | `undo_used` | X01 / Cricket | Full turn undo |
| `dart_undone` | `undo_used` | X01 / Cricket | Single-dart undo |
| `match_abandoned` | `match_abandoned` | Match lifecycle | Replace-active / abandon |
| `match_start_failed` | `match_start_failed` | Setup | Start errors |
| `turn_persist_failed` | `turn_persist_failed` | Match | Persistence failure |
| `bootstrap_store_open_failed` | `bootstrap_store_open_failed` | Bootstrap | Store open/migration failure (auto-repair) |
| `deep_link_received` | `deep_link_received` | Deep links | Parsed link applying |
| `deep_link_applied` | `deep_link_applied` | Deep links | Route succeeded |
| `deep_link_deferred` | `deep_link_deferred` | Deep links | Queued during onboarding |
| `deep_link_failed` | `deep_link_failed` | Deep links | Parse/route failure |
| `intent_performed` | `intent_performed` | App Intents | Shortcut/Siri route succeeded |
| `intent_failed` | `intent_failed` | App Intents | Flag off, no active match, route error |
| `client_environment_changed` | `client_environment_changed` | App shell | Accessibility/display context change (VoiceOver, Reduce Motion, orientation, etc.) |
| `guided_practice_started` | `guided_practice_started` | Guided Play | Guided Practice session start |
| `guided_practice_completed` | `guided_practice_completed` | Guided Play | Guided Practice session complete |
| `guided_play_settings_enabled` | `guided_play_settings_enabled` | Settings | User enabled Guided Play profile |

Allowlisted metadata keys: `matchType`, `errorCode`, `layer`, `status`, `participantCount`, `operation`, `schemaVersion`, `fromSchema`, `toSchema`, `legIndex`, `setIndex`, `source`, `isBot`, `path`, `version`, `intentName`, plus client-environment keys (`deviceClass`, `isVoiceOverRunning`, `isSwitchControlRunning`, `isBoldTextEnabled`, `isReduceMotionEnabled`, `isScreenCaptured`, `isExternalDisplayConnected`, `interfaceOrientation`, `trigger`, `changedSignals`), Guided Play keys (`sessionRole`, `targetKind`, `dartsPerTarget`, `targetCount`, `hadGuide`, `accuracyBucket`, `guidedPlayEnabled`), and `app_version`, `log_category` injected by mapper.

### Firebase Crashlytics (non-fatal allowlist)

| Log `eventName` | Feature |
|-----------------|---------|
| `bootstrap_store_open_failed` | Bootstrap store recovery |
| `match_start_failed` | Setup |
| `turn_persist_failed` | Match |
| `match_session_load_failed` | X01 / Cricket resume |
| `play_home_load_failed` | Play home |
| `active_match_lookup_failed` | Setup conflict check |
| `active_match_replace_failed` | Setup replace active |
| `turn_undo_failed` | Undo |
| `x01_abandon_failed` | X01 abandon |
| `cricket_abandon_failed` | Cricket abandon |
| `settings_reset_failed` | Settings → Reset All Local Data |

### Log-only (not Analytics allowlist yet)

Use `AppLogger` for debugging; add to Analytics allowlist only with product approval.

| `eventName` | Feature spec |
|-------------|----------------|
| `settings_reset_all_data` | `SettingsSpec.md` — successful reset; log-only (no Analytics) |
| `play_home_active_match`, `play_home_ready` | `PlayHomeSpec.md` |
| `active_match_conflict`, `active_match_replaced` | `SetupFlowSpec.md` |
| `match_setup_start` | `SetupFlowSpec.md` |
| `match_setup_baseball` | `BaseballGameSpec.md`, `SetupFlowSpec.md` |
| `match_screen_appeared`, `bot_turn_started` | `BotOpponentSpec.md`, `game-modes/implemented/X01GameSpec.md`, `game-modes/implemented/CricketSpec.md` |
| `turn_submit_rejected`, `turn_bust` | `game-modes/implemented/X01GameSpec.md` |
| `training_bot_created`, `training_bot_match_started` | `TrainingBotSpec.md` (planned Analytics — wire allowlist when shipping) |
| `deep_link_*`, `intent_*` | [`DeepLinkSpec.md`](DeepLinkSpec.md), [`AppIntentsSpec.md`](AppIntentsSpec.md) |
| `settings_seeded`, `settings_seed_skipped` | `SettingsSpec.md` |

Feature specs link here for analytics subsections; do not duplicate full tables.

---

## 13. Verification (§12 telemetry audit)
| Field | Value |
|-------|--------|
| **Last verified** | 2026-06-11 |
| **Commit** | `340f788` |
| **Code** | `FirebaseAnalyticsEventMapping.swift`, `FirebaseCrashlyticsEventMapping.swift` |

# Firebase Backend and Analytics Specification

## 1. Purpose
Define how Firebase will be introduced for backend and analytics in a phased way without destabilizing the local-first 1.0 architecture.

---

## 2. Product Positioning
- 1.0 remains fully playable offline with local persistence as source of truth.
- 1.0 uses only the custom console-first logger (see `specs/LoggingSpec.md`), with no Firebase runtime SDKs.
- Firebase is introduced incrementally for:
  - analytics and crash visibility
  - optional sync and online services
  - future online match infrastructure

---

## 3. Firebase Services Roadmap

## Phase 1 (Post-1.0, low risk)
- Firebase Analytics (privacy-safe event telemetry)
- Firebase Crashlytics (crash diagnostics)

## Phase 2
- Firebase Authentication (anonymous first, upgrade path later)
- Firestore for cloud profile/sync metadata

## Phase 3
- Cloud Functions for trusted server-side validation and online orchestration
- Optional App Check for abuse protection

---

## 4. iOS SDK Dependencies (SPM)
Recommended when phase starts:
- `FirebaseAnalytics`
- `FirebaseCrashlytics`
- `FirebaseAuth`
- `FirebaseFirestore`
- `FirebaseFunctions`

Rules:
- Add only what is needed per phase; do not install all SDKs upfront.
- Keep Firebase dependencies out of 1.0 runtime unless that phase is approved.

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

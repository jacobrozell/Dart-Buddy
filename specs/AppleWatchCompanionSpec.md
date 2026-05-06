# Apple Watch Companion Specification (Future)

## 1. Purpose
Document a future watch companion app so wrist-based scoring can be added without major iPhone app rewrites.

---

## 2. Product Goal
- Let players input and view scores from Apple Watch during live play.
- Keep iPhone as the canonical match host for local/offline and early watch releases.
- Once online mode exists, canonical authority moves to server for online matches (see `specs/OnlinePlaySpec.md`).

---

## 3. Release Scope Recommendation

## Phase A (first watch release)
- Watch companion for active match only
- Show current player, remaining score/marks, quick scoring controls
- Send scoring commands to iPhone
- iPhone validates and persists all events

## Phase B
- Temporary offline queue on watch when phone unreachable
- Conflict-safe replay when reconnected

---

## 4. Architecture Requirements to Prepare Now
- Keep domain engines platform-agnostic (already planned).
- Keep repository interfaces free of UIKit/SwiftUI/watch types.
- Represent score changes as command/event DTOs, not view state blobs.
- Treat iPhone as source of truth for match history and stats.

---

## 5. Connectivity Strategy (Future)
- Use Apple `WatchConnectivity` framework (no third-party package).
- Define compact command payloads:
  - `SubmitTurnCommand`
  - `UndoLastTurnCommand`
  - `RequestMatchStateCommand`
- Include idempotency key per command to avoid duplicate application.

---

## 6. Data and Consistency
- Persist final accepted events only on iPhone store.
- Add optional event metadata now for future companion tracing:
  - `originDeviceType` (`iphone`, `watch`)
  - `originDeviceSessionId`
- Match engine remains deterministic regardless of input origin.

---

## 7. UX Notes (Future)
- Large tap targets for quick throws (`S/D/T`, common scores).
- Low-friction undo request.
- Haptic acknowledgement for accepted/rejected actions.
- Keep watch UI glanceable and minimal; deep detail stays on phone.

---

## 8. Security and Privacy
- Use authenticated WCSession pairing only.
- No cloud dependency required for first watch release.
- No ad/analytics tracking changes required.

---

## 9. Testing Strategy
- Command idempotency tests
- Reconnect/replay tests
- Duplicate message handling tests
- End-to-end active match flow from watch input to iPhone persistence

---

## 10. Decisions Locked for Current Implementation
- Do not couple scoring logic to iPhone-only UI concerns.
- Keep event payload schema extensible for `originDeviceType`.
- Keep command handling centralized so new clients (watch) can plug in later.

# Online Play Specification (Future)

## 1. Purpose
Define a future online multiplayer mode that is fair, low-latency, and compatible with manual, watch, and vision-based scoring inputs.

---

## 2. Product Goals
- Real-time head-to-head play
- Reduced honor-system dependence
- Clear dispute resolution and match auditability

---

## 3. Release Strategy

## Phase A: Live Sync, Manual Verified
- Real-time score sync between players
- Command/event authoritative model
- Host/referee controls and rematch flows

## Phase B: Device-Backed Verification
- Apple Watch command origin metadata
- Vision confidence metadata and calibration status

## Phase C: Competitive Integrity
- Signed events
- Anti-replay and anomaly detection
- Ranked mode eligibility rules

---

## 4. Architecture Direction
- Server-authoritative event stream
- Clients submit scoring commands, not state mutations
- Deterministic rules engine shared by server and client
- Match timeline is append-only with versioned event schema
- For non-online/local matches, iPhone remains source of truth (consistent with watch and vision specs).

Dependencies:
- `specs/AppleWatchCompanionSpec.md`
- `specs/AutoScoringVisionSpec.md`
- `specs/RepositorySpec.md`
- `specs/FirebaseBackendAnalyticsSpec.md`

---

## 5. Command and Event Model

## Commands
- `SubmitTurn`
- `UndoRequest`
- `ApproveUndo` / `RejectUndo`
- `PauseMatch` / `ResumeMatch`

## Events
- `TurnAccepted`
- `TurnRejected`
- `UndoApplied`
- `MatchCompleted`
- `IntegrityFlagRaised`

Required event metadata:
- `originDeviceType` (`iphone`, `watch`, `vision`)
- `originSessionId`
- `clientTimestamp`
- `serverTimestamp`
- `eventSignature` (future)

---

## 6. Fair Play and Integrity
- Turn lock: only active player can submit scoring command
- Idempotency key per command
- Drift checks for out-of-order command arrival
- Confidence thresholds for vision-originated auto events
- Manual override and dispute flow always available

---

## 7. UX Requirements
- Connection quality indicator
- Opponent turn state and action confirmations
- Explicit pending/accepted/rejected command states
- Reconnect and rejoin match flow

---

## 8. Data and Retention
- Store online and local event timelines compatibly
- Preserve event provenance for audits
- Keep post-match integrity summary in history detail

---

## 9. Testing
- Real-time conflict tests (simultaneous actions)
- Reconnect and backfill tests
- Idempotency/replay tests
- Determinism tests across client/server rule engine

---

## 10. Out of Scope (Early Online)
- Voice/video chat
- Tournaments and ladders
- Public matchmaking MMR system

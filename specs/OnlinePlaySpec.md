# Online Play Specification (Future)

## 1. Purpose

Define future **online multiplayer** — real-time head-to-head legs, server-authoritative sync, and (in **P2**) **online tournaments** hosted on Firebase — fair, low-latency, and compatible with manual, watch, and vision-based scoring inputs.

**Status:** Future / post-1.0. Not blocking lean 1.0 ship.

**Product priority (shared with [`TournamentSpec.md`](TournamentSpec.md)):**

| Priority | Scope | Firebase | Spec |
|----------|-------|----------|------|
| **P1** | **Local tournaments** — one device, pass-and-play brackets | Analytics + Crashlytics only (1.0) | [`TournamentSpec.md`](TournamentSpec.md) §4 P1 |
| **P2** | **Online head-to-head** + **online tournaments** | Auth, Firestore, Functions (see §4) | This spec + [`TournamentSpec.md`](TournamentSpec.md) §14 |

P1 ships **without** online play or Firebase backend services. P2 requires this spec **and** [`FirebaseBackendAnalyticsSpec.md`](FirebaseBackendAnalyticsSpec.md) Phases 2–3.

**Related specs:**
- [`TournamentSpec.md`](TournamentSpec.md) — bracket platform; local P1, online P2 extension
- [`FirebaseBackendAnalyticsSpec.md`](FirebaseBackendAnalyticsSpec.md) — Auth / Firestore / Functions roadmap
- [`MatchSpec.md`](MatchSpec.md) — leg lifecycle; online `visibility` + event timeline
- [`FeatureFlagConfigSpec.md`](FeatureFlagConfigSpec.md) — `enableOnlinePlay`, `enableOnlineTournaments`
- [`AppleWatchCompanionSpec.md`](AppleWatchCompanionSpec.md) — command origin metadata
- [`AutoScoringVisionSpec.md`](AutoScoringVisionSpec.md) — vision confidence metadata
- [`RepositorySpec.md`](RepositorySpec.md) — local/cloud reconciliation

---

## 2. Product goals

- Real-time head-to-head play across devices
- Reduced honor-system dependence vs pass-and-play
- Clear dispute resolution and match auditability
- **P2:** Online tournaments competitive with [DartCounter](https://dartcounter.net/press/online-tournaments) — register, check-in, live bracket, remote legs
- **P2:** Reuse [`TournamentSpec.md`](TournamentSpec.md) orchestrator + `TournamentConfigPayload` — only transport and discovery change

---

## 3. Cross-spec roadmap

```text
1.0 ship          P1 (post-1.0)              P2 (future)
─────────         ─────────────              ────────────
Local matches     Local tournaments          Online 1v1 legs
Firebase A+C      Tournament hub + bracket   Firebase Auth + Firestore
(no online)       (no Firebase backend)      Cloud Functions orchestrator
                  Remix / KO presets         Online tournaments
                                             Spectate + check-in
```

### 3.1 What P1 delivers (no online)

From [`TournamentSpec.md`](TournamentSpec.md):

- Local knockout / remix / gauntlet on **one phone**
- `TournamentOrchestrator` + `TournamentRecord` in SwiftData
- Flag: `enableLocalTournaments`
- **Design for P2:** `schemaVersion`, `visibility: local | online`, stable `tournamentId` / `nodeId` UUIDs

### 3.2 What P2 adds (this spec + Firebase)

| Layer | Deliverable |
|-------|-------------|
| **Online leg** | Remote 1v1 sync (Phase A–C below) |
| **Online tournament** | Server bracket, registration, check-in, spectate |
| **Firebase** | Auth → Firestore state → Functions validation |
| **Flags** | `enableOnlinePlay` → `enableOnlineTournaments` (gated on online play) |

**Dependency rule:** Do **not** ship online tournaments until **online head-to-head Phase A** is stable (remote `SubmitTurn` + reconnect). Tournaments are N concurrent online legs + bracket coordinator.

---

## 4. Firebase alignment ([`FirebaseBackendAnalyticsSpec.md`](FirebaseBackendAnalyticsSpec.md))

| Firebase phase | Online play capability | Tournament capability |
|----------------|------------------------|------------------------|
| **Phase 1 (1.0)** | Analytics / Crashlytics only | — |
| **Phase 2** | Firebase **Auth** (anonymous → upgrade); **Firestore** user + invite metadata | — |
| **Phase 3** | **Cloud Functions** — authoritative match command validation; optional **App Check** | **Online tournament** bracket writes, check-in, advance |
| **Phase 4+** | Signed events, anti-replay (integrity) | Public discovery index, min-average gates |

### 4.1 Firestore collections (P2 draft)

| Collection | Document | Purpose |
|------------|----------|---------|
| `tournaments/{id}` | `TournamentRecord` mirror | Bracket, config, status, host |
| `tournaments/{id}/participants/{uid}` | `ParticipantState` | registered / checked_in / ready / … |
| `tournaments/{id}/nodes/{nodeId}` | Bracket node | matchup, leg refs, status |
| `matches/{id}` | Online leg | Links to `tournamentId` + `nodeId` when applicable |
| `matches/{id}/events/{seq}` | Append-only events | Same schema as local timeline |

**Local canonical rule:** Client caches server state; completed legs reconcile into SwiftData `MatchRecord` + `TournamentRecord` per [`FirebaseBackendAnalyticsSpec.md`](FirebaseBackendAnalyticsSpec.md) §5.

### 4.2 Cloud Functions (P2)

| Function | Trigger | Role |
|----------|---------|------|
| `validateTurn` | HTTPS / callable | Run shared rules engine; emit `TurnAccepted` |
| `advanceTournamentNode` | On `MatchCompleted` | Update bracket; open next node |
| `processCheckIn` | Callable | Registration window + ready flags |
| `withdrawParticipant` | Callable | Safe bracket repair (see Tournament §8.3) |

Domain engines stay Firebase-agnostic; Functions import shared validation package or duplicate-tested logic.

---

## 5. Release strategy — online legs

Progressive integrity for **single online matches** (prerequisite for tournament legs).

### Phase A — Live sync, manual verified (P2 entry)

- Real-time score sync between two devices
- Command/event authoritative model (§6)
- Host/referee controls and rematch flows
- Reconnect and rejoin single match
- **Flag:** `enableOnlinePlay`

### Phase B — Device-backed verification

- Apple Watch command origin metadata
- Vision confidence metadata and calibration status

### Phase C — Competitive integrity

- Signed events
- Anti-replay and anomaly detection
- Ranked mode eligibility rules (optional; separate from tournaments)

---

## 6. Release strategy — online tournaments (P2)

Requires **Phase A** online legs + **Firebase Phase 3** Functions.

Maps to [`TournamentSpec.md`](TournamentSpec.md) online feature set:

| Milestone | Features |
|-----------|----------|
| **T-A** | Host creates online event; share **short code** / link; closed roster |
| **T-B** | Registration + **check-in window**; one-tap ready (DartCounter parity) |
| **T-C** | **Live bracket** sync; participation list; spectate leg (read-only) |
| **T-D** | Min 3-dart average gate; moderator force advance / DQ / reports |
| **T-E** | Public tournament discovery (optional; defer if abuse risk) |

**Flag:** `enableOnlineTournaments` (default `false`; requires `enableOnlinePlay == true`).

**Reuse:** Same `TournamentOrchestrator` as local P1; `OnlineTournamentTransport` implements bracket read/write against Firestore + Functions.

---

## 7. Architecture direction

- **Server-authoritative** event stream for online legs
- Clients submit **commands**, not state mutations
- Deterministic rules engine shared by Cloud Functions and client (or verified client hash)
- Match timeline append-only with versioned event schema
- **Local / P1 tournaments:** iPhone remains source of truth
- **Online / P2:** server source of truth during active leg; reconcile to local on complete

Dependencies:

- [`AppleWatchCompanionSpec.md`](AppleWatchCompanionSpec.md)
- [`AutoScoringVisionSpec.md`](AutoScoringVisionSpec.md)
- [`RepositorySpec.md`](RepositorySpec.md)
- [`FirebaseBackendAnalyticsSpec.md`](FirebaseBackendAnalyticsSpec.md)
- [`TournamentSpec.md`](TournamentSpec.md) — `TournamentConfigPayload`, orchestrator protocol

---

## 8. Command and event model

### 8.1 Match commands (online leg)

| Command | Description |
|---------|-------------|
| `SubmitTurn` | Active player scores dart(s) |
| `UndoRequest` | Request undo |
| `ApproveUndo` / `RejectUndo` | Opponent / host |
| `PauseMatch` / `ResumeMatch` | Pause flow |
| `ForfeitMatch` | Early end ([`MatchForfeitSpec.md`](MatchForfeitSpec.md)) |

### 8.2 Tournament commands (P2 — online only)

| Command | Description |
|---------|-------------|
| `CreateTournament` | Host publishes config snapshot |
| `RegisterParticipant` | Join open event |
| `CheckIn` / `MarkReady` | Check-in window |
| `StartTournament` | Host closes registration |
| `ClaimNextNode` | Player accepts assigned matchup |
| `ReportLegDispute` | Flag for moderator |
| `ModeratorAdvance` | Force WO / DQ / rematch |
| `WithdrawFromTournament` | Safe exit ([`TournamentSpec.md`](TournamentSpec.md) §8.3) |

Local P1 tournaments use **host UI actions** (same semantics, no network commands).

### 8.3 Events

| Event | Description |
|-------|-------------|
| `TurnAccepted` / `TurnRejected` | Leg scoring |
| `UndoApplied` | Undo resolved |
| `MatchCompleted` | Leg done → may trigger `advanceTournamentNode` |
| `IntegrityFlagRaised` | Dispute / anomaly |
| `TournamentNodeUpdated` | Bracket changed |
| `ParticipantStateChanged` | Check-in / ready / eliminated |
| `TournamentCompleted` | Champion declared |

Required metadata: `originDeviceType`, `originSessionId`, `clientTimestamp`, `serverTimestamp`, `tournamentId?`, `nodeId?`, `eventSignature` (Phase C).

---

## 9. Fair play and integrity

- Turn lock: only active player submits scoring command
- Idempotency key per command
- Drift checks for out-of-order arrival
- Vision confidence thresholds for auto events
- Manual override and dispute flow always available
- **Tournament:** one active leg per player; withdraw cannot corrupt bracket (server transaction)
- **Spectate:** read-only; join-next uses queue (avoid DartCounter spectate→join races)

---

## 10. UX requirements

### 10.1 Online leg

- Connection quality indicator
- Opponent turn state and action confirmations
- Pending / accepted / rejected command states
- Reconnect and rejoin match flow

### 10.2 Online tournament (P2)

- Browse / enter code / invite link
- Check-in countdown + ready list
- Live bracket + participation tab ([`TournamentSpec.md`](TournamentSpec.md) §11)
- Push notification: “Your match is up” (Firebase Cloud Messaging — optional sub-phase)
- Post-leg stats drill-down (Activity)

---

## 11. Data and retention

- Online and local event timelines use **compatible schema**
- Preserve provenance for audits
- Post-match integrity summary in history detail
- `TournamentRecord` with `visibility: online` links to Firestore doc id
- Deleting local leg must **not** orphan online bracket without repair (DartCounter bug class)

---

## 12. Analytics (P2 allowlist — draft)

Add to [`FirebaseBackendAnalyticsSpec.md`](FirebaseBackendAnalyticsSpec.md) §12 when shipping:

| Event | When |
|-------|------|
| `online_match_started` | Remote leg begins |
| `online_match_completed` | Remote leg ends |
| `online_reconnect` | Successful rejoin |
| `tournament_created_online` | Host publishes |
| `tournament_check_in` | Participant ready |
| `tournament_online_completed` | Champion |

Tournament local events remain in [`TournamentSpec.md`](TournamentSpec.md) §13.

---

## 13. Testing

### Online legs

- Real-time conflict (simultaneous actions)
- Reconnect and backfill
- Idempotency / replay
- Client ↔ Functions rules determinism

### Online tournaments (P2)

- Register → check-in → start → full bracket
- Concurrent legs on different nodes
- Withdraw mid-event → bracket repair
- Spectator read-only cannot submit turns
- Local P1 bracket tests unchanged (orchestrator unit tests shared)

---

## 14. Out of scope (early online)

| Item | Defer to |
|------|----------|
| Voice / video chat | — |
| Public matchmaking MMR | Ladder spec (future) |
| Prize money / payments | — |
| In-tournament host chat | Tournament §8.2 Phase 5+ |

### In scope (explicit)

| Item | Priority |
|------|----------|
| **Local tournaments** | **P1** — [`TournamentSpec.md`](TournamentSpec.md); no Firebase backend |
| **Online head-to-head** | **P2** — Phase A–C |
| **Online tournaments** | **P2** — §6; requires Phase A + Firebase Phase 3 |

---

## 15. Open questions

1. Anonymous Auth sufficient for P2 tournaments or require email/Apple sign-in?
2. Short code length / TTL for join links?
3. `enableOnlineTournaments` separate flag or sub-flag of `enableOnlinePlay`?
4. Firestore real-time listeners vs polling for bracket UI?
5. Ultimate-style paywall on online tournaments (DartCounter model)?

---

## 16. Index

| Doc | Role |
|-----|------|
| This spec | Online legs + Firebase transport; P2 tournaments |
| [`TournamentSpec.md`](TournamentSpec.md) | Bracket platform; P1 local, P2 online extension |
| [`FirebaseBackendAnalyticsSpec.md`](FirebaseBackendAnalyticsSpec.md) | Firebase phased rollout |
| [`RemixNightGameSpec.md`](game-modes/planned/RemixNightGameSpec.md) | Preset usable in local or online tournament |

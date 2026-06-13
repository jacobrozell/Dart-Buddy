# Online Play Specification (Future)

## 1. Purpose

Define future **online multiplayer** — real-time head-to-head legs, server-authoritative sync, and (in **P2**) **online tournaments** hosted on Firebase — fair, low-latency, and compatible with manual, watch, and vision-based scoring inputs.

**Status:** Future / post-1.0. Not blocking lean 1.0 ship.
**Estimated release:** `2.0+`

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
- [`AutoScoringVisionSpec.md`](AutoScoringVisionSpec.md) — vision confidence metadata; **skill verification** (§10.4)
- [`BotOpponentSpec.md`](BotOpponentSpec.md) — verification bot tiers (§10.4)
- [`PlayerSpec.md`](PlayerSpec.md) — display-name validation; offensive-name policy (§10.5)
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
| `users/{uid}` | Online profile | `displayName`, `displayNamePendingReview`, report counters |
| `nameReports/{reportId}` | Name-report queue | Moderation workflow (§10.6) |

**Local canonical rule:** Client caches server state; completed legs reconcile into SwiftData `MatchRecord` + `TournamentRecord` per [`FirebaseBackendAnalyticsSpec.md`](FirebaseBackendAnalyticsSpec.md) §5.

### 4.2 Cloud Functions (P2)

| Function | Trigger | Role |
|----------|---------|------|
| `validateTurn` | HTTPS / callable | Run shared rules engine; emit `TurnAccepted` |
| `advanceTournamentNode` | On `MatchCompleted` | Update bracket; open next node |
| `processCheckIn` | Callable | Registration window + ready flags |
| `withdrawParticipant` | Callable | Safe bracket repair (see Tournament §8.3) |
| `submitPlayerNameReport` | Callable | Validate report, dedupe, enqueue, optional auto-flag (§10.6) |
| `resolveNameReport` | Callable (moderator) | Approve / rename / ban; audit trail |

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

### Phase D — Open lobbies (post–Phase A)

Requires Firebase Auth + Firestore presence. **Not** full ladder/MMR (see §14).

| Milestone | Features |
|-----------|----------|
| **L-A** | Host creates **open lobby** (mode, format, max seats); share code or browse public list |
| **L-B** | **Skill band** on lobby (host filter + join preview) — see §10.3 |
| **L-C** | **Verified skill badge** gates high-trust lobbies — see §10.4 |
| **L-D** | Report player / kick / lobby moderation hooks |

**Dependency rule:** Do **not** ship public open lobbies until **display-name moderation** (§10.5) is enforced server-side for online profiles.

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

### 10.3 Open lobbies and skill matching

**Product intent:** Let anyone discover and join casual online games without a pre-arranged invite, while reducing gross skill mismatch and honor-system lying about averages.

**Lobby model (draft):**

| Field | Purpose |
|-------|---------|
| `mode` / `format` | Same as local setup (`MatchType`, legs, checkout rules) |
| `visibility` | `invite` \| `open` |
| `maxSeats` | 2 for v1 open lobbies; party modes later |
| `skillBand` | Optional filter — see below |
| `requiresVerifiedSkill` | When true, only **Verified** players may join (§10.4) |
| `hostUid` | Firebase Auth uid |

**Skill band options (host-selected, joiner-visible before join):**

| Band | Meaning | Trust source |
|------|---------|--------------|
| **Open** | No gate | — |
| **Casual** | Self-reported rolling 3-dart average bracket (e.g. &lt; 40, 40–55, 55+) | Local stats mirror on profile — honor system |
| **Verified only** | Must hold active **Verified** credential | Camera-verified bot challenge (§10.4) |
| **Host pick** | Host approves each join request | Manual |

**Design notes:**

- Self-reported averages are **allowed for casual open lobbies** but labeled honestly in UI (“self-reported”) so players can leave before starting.
- Tournament min-average gates ([`TournamentSpec.md`](TournamentSpec.md) §6.5) reuse the same profile fields; **Verified** attestation satisfies competitive gates without trusting local-only stats.
- Full **MMR / ranked matchmaking** stays out of scope until a dedicated ladder spec exists (§14).

### 10.4 Verified skill (“Veteran”) — camera-backed bot challenge

**Naming:** Online trust tier **`Verified`** (working title). Do **not** conflate with the local achievement badge [`db.play.250` *Veteran*](AchievementCatalogPhase1.md) (250 completed games). UI copy must distinguish “Verified skill” vs “Veteran achievement.”

**Problem:** Players can inflate local stats or pick offensive names before joining strangers. Honor-system averages are insufficient for skill-gated or ranked-adjacent lobbies.

**Proposed path:**

1. Player starts **Verification Match** from online profile or lobby gate.
2. **Vision scoring required** — [`AutoScoringVisionSpec.md`](AutoScoringVisionSpec.md) Phase B+ (auto-commit with confidence threshold). Manual-only verification does **not** grant Verified status.
3. Opponent is a **preset bot** at a fixed tier (draft: **`Hard`** minimum; **`Pro`** for upper competitive band). See [`BotOpponentSpec.md`](BotOpponentSpec.md).
4. Format (draft): single X01 leg, standard double-out; player must **win** the leg.
5. Server receives append-only turn events with `originDeviceType: vision`, confidence metadata, and calibration snapshot id.
6. Cloud Function validates: vision coverage threshold met, no manual override on winning visits, bot tier satisfied → issue **`VerifiedSkillCredential`** on Firebase profile.

**Credential (Firestore draft):**

| Field | Purpose |
|-------|---------|
| `verifiedAt` | Server timestamp |
| `botTier` | e.g. `hard` \| `pro` |
| `attestedThreeDartAverage` | Derived from verified leg(s), not self-reported |
| `expiresAt` | Optional refresh window (e.g. 90 days) — TBD |
| `revoked` | Moderator / anomaly flag |

**Unlocks (when credential active):**

- Join `requiresVerifiedSkill` lobbies
- Display **Verified** badge next to name in lobby, leg, and tournament roster
- Satisfy tournament **min 3-dart average** gate when attested average ≥ host minimum (online P2)

**Out of scope for first Verified ship:**

- Continuous re-verification every match
- Proving identity across devices without Auth upgrade
- Storing raw camera frames (see [`SecurityPrivacySpec.md`](SecurityPrivacySpec.md) §6)

### 10.5 Display-name moderation (online + pre-online hygiene)

**Requirement:** Offensive, slur, and harassing **display names must not appear to other players** in any online surface (lobby list, leg UI, tournament bracket, spectate).

**Phased policy:**

| Phase | When | Requirement |
|-------|------|-------------|
| **Pre-online (recommended 1.x)** | Before P2 | Client-side blocklist on player create/edit ([`PlayerSpec.md`](PlayerSpec.md) §4). Blocks obvious slurs locally; no server yet. |
| **Online P2 (mandatory)** | Before Phase D lobbies or any cross-user name display | **Server-side** validation on Firebase profile write / lobby join; reject or sanitize; audit log without storing rejected string in analytics |
| **Online P2+** | After first reports | Report name → moderator queue; temporary rename to generic fallback (`Player ####`) pending review |

**Implementation direction (draft):**

- **Do not use naive substring matching.** A name like `Assassin` must pass; blocking any string that *contains* `ass` is unacceptable.
- **Match whole tokens on word boundaries** after normalization — e.g. reject standalone slur tokens, not substrings inside unrelated words.
- Normalize before tokenize: trim, lowercase, NFKC, leetspeak homoglyph folding, split on non-alphanumeric boundaries.
- **Blocklist:** curated **slur and hate-speech tokens only** (small, reviewed list) — not a generic “profanity dictionary” that flags `class`, `Scunthorpe`, etc.
- **Allowlist:** explicit exceptions for known false positives (e.g. `Dickens`, `Assassin`, `Classic`) — maintained alongside blocklist; unit tests per allowlist entry.
- **Client and server both check** — server is authoritative for online
- Local-only pass-and-play: blocklist still recommended so names are not already toxic when user later enables online

**False-positive policy:** When in doubt, **allow** locally (1.x) and rely on **report + moderator** online (P2+). Prefer missing a borderline name over blocking a legitimate one. Rejection copy should be neutral (“This name isn’t allowed”) — no repeating the flagged substring.

### 10.5.1 Multilingual limitation (honest scope)

**Player display names are free text** — they are **not** tied to the app UI language. A user with English UI can enter a German, Spanish, or Chinese name; shipped locales (`de`, `es`, `nl`, `fr`, `zh-Hans` per [`LocalizationSpec.md`](LocalizationSpec.md)) do **not** imply the team maintains equivalent slur lists for each.

**Reality:** A small English-first team **cannot** curate complete, accurate offensive-token lists for every language and script. Attempting to do so without native review risks both **false blocks** (innocent names in another language) and **false allows** (slurs the team does not recognize).

**Locked strategy:**

| Layer | Scope | Owner |
|-------|--------|-------|
| **1.x client (optional)** | English slur tokens + language-agnostic obfuscation checks (leet, zero-width, mixed-script spam) | App bundle; conservative |
| **Online P2 server** | Re-run same English + obfuscation rules; add **third-party text moderation API** evaluation before open lobbies (vendor TBD — Perspective, Azure Content Moderator, or similar) | Cloud Function; budget + privacy review |
| **Primary backstop (online)** | **Report name** → hide from reporter → moderator queue → rename / ban | Required before Phase D lobbies |
| **Not in scope (v1 filter)** | Hand-maintained blocklists for `de` / `es` / `nl` / `fr` / `zh-Hans` | Defer unless native-speaking contributor or vendor list is licensed |

**Product copy (online help / moderation FAQ):** State plainly that automated filters are **best-effort** and that reporting inappropriate names is the reliable path. Do not claim “all languages” coverage.

**Privacy note:** Sending display names to a third-party moderation API requires disclosure in privacy policy and App Store nutrition labels when online ships ([`SecurityPrivacySpec.md`](SecurityPrivacySpec.md)).

**Decision (locked for spec):** Ship **client-side** offensive-name filtering in 1.x as hygiene; **do not** launch open lobbies or public online profiles without **server-side** enforcement **and** a working **report** flow (§10.6).

### 10.6 Player name reports (Firebase — online P2)

**Yes — this is a Firebase integration.** Requires [`FirebaseBackendAnalyticsSpec.md`](FirebaseBackendAnalyticsSpec.md) **Phase 2** (Auth + Firestore) and **Phase 3** (Cloud Functions). Not shipped in 1.x local-only play.

**Why Firebase:** Reports must be **server-authoritative** (anti-spam, dedupe, moderator queue, global rename). Clients must not write moderation state directly.

#### User flow

| Step | Behavior |
|------|----------|
| 1 | Reporter taps **Report name** on an online player (lobby row, opponent card, tournament roster, post-match summary) |
| 2 | Sheet: reason **`offensiveName`** (primary), **`harassment`**, **`other`**; optional note (max 200 chars, no required essay) |
| 3 | Confirm → callable **`submitPlayerNameReport`** |
| 4 | Success toast: neutral copy (“Thanks — we’ll review this.”) |
| 5 | **Immediately:** reported display name hidden **for this reporter only** (local cache + server preference) |
| 6 | **Moderator / auto:** see queue below |

**Auth:** Firebase Auth required — **anonymous Auth is sufficient** for P2 (ties report to `reporterUid`). Upgrade to Apple sign-in optional later for ban appeals.

**Not reportable in 1.x:** Local pass-and-play names on one device — no strangers, no Firebase path.

#### Firestore model (draft)

**`nameReports/{reportId}`** (append-only queue; clients read **none** — moderators via admin tool / Function)

| Field | Type | Notes |
|-------|------|-------|
| `reportId` | string | Auto id |
| `reporterUid` | string | Auth uid |
| `reportedUid` | string | Target profile |
| `reportedDisplayNameSnapshot` | string | Name **at report time** (for audit); not echoed in analytics |
| `reason` | enum | `offensiveName` \| `harassment` \| `other` |
| `note` | string? | Optional reporter note |
| `context` | map | `lobbyId?`, `matchId?`, `tournamentId?` — no PII beyond ids |
| `status` | enum | `open` \| `resolved` \| `dismissed` |
| `createdAt` | timestamp | Server |
| `resolvedAt` | timestamp? | Moderator action |
| `resolution` | enum? | `noAction` \| `renamed` \| `banned` |

**`users/{uid}`** (online profile extension)

| Field | Purpose |
|-------|---------|
| `displayName` | Public name |
| `displayNamePendingReview` | When true, clients show fallback label globally |
| `displayNameFallback` | e.g. `Player 7F3A` while pending |
| `nameReportCount` | Distinct reporters (maintained by Function) |
| `nameReportWindowStartedAt` | Rolling window for auto-flag threshold |

#### Cloud Function: `submitPlayerNameReport`

1. Require Auth + **App Check** (when enabled).
2. Reject self-reports, missing `reportedUid`, or blank snapshot.
3. **Dedupe:** one open report per `(reporterUid, reportedUid)` per 24h.
4. Rate-limit: max **10 reports / reporter / day** (configurable).
5. Write `nameReports/{id}` with `status: open`.
6. Increment distinct-reporter count on `users/{reportedUid}` (transaction).
7. **Auto-flag (draft):** if **≥ 3 distinct reporters** in 7 days → set `displayNamePendingReview: true`, assign `displayNameFallback`, notify moderator (email / Slack webhook — ops TBD).
8. Return `{ success: true }` — never return why a name was flagged to clients.

#### Moderator resolution (v1 ops)

| Option | Implementation |
|--------|----------------|
| **Founder-only (P2 launch)** | Firebase **custom claim** `moderator: true`; callable `resolveNameReport`; or Firebase Console + script |
| **In-app queue (later)** | Hidden Settings flag / internal build — list open reports |
| **Outcomes** | Dismiss → restore name; **Rename** → force generic name + warn user; **Ban** → disable online join (uid block list) |

Reuse tournament **Review report** pattern ([`TournamentSpec.md`](TournamentSpec.md) §8.2) — one moderation queue can serve leg disputes and name reports in Activity (future unified **Reports** tab).

#### Security rules (draft)

- Clients **cannot** create/read `nameReports` directly.
- Clients **read** other users’ `displayName` or `displayNameFallback` only (not report counts).
- Moderator writes only via Cloud Functions.

#### Privacy

- Do **not** include reported names or reporter uids in Firebase Analytics ([`SecurityPrivacySpec.md`](SecurityPrivacySpec.md) §6.1).
- Allowlisted event: `name_report_submitted` with `{ reason_category }` only.
- Retention: resolve or dismiss reports within **90 days**; ban records kept per abuse policy.

#### UI considerations (iOS — spec only)

No implementation in 1.x. When online P2 ships, follow [`DesignSystemSpec.md`](DesignSystemSpec.md) and existing sheet/menu patterns (`PlayerEditSheet`, `MatchLifecycleChrome`).

**Design principles**

| Principle | Rule |
|-----------|------|
| **Discrete entry** | Report lives in a **secondary menu** (⋯) — never a primary gameplay CTA |
| **No echo** | Do **not** repeat the reported name in the report sheet, success toast, or error copy after submit |
| **Not destructive** | Use standard confirmation emphasis — reporting is reversible for the reporter (local unhide later, optional) |
| **Immediate relief** | Hide the name for the reporter **before** network completes (optimistic local hide) |
| **Neutral tone** | Copy avoids repeating slurs, judging intent, or promising instant global action |

**Entry points (online surfaces only)**

| Surface | Placement | Notes |
|---------|-----------|-------|
| **Active online leg** | Opponent score card → **⋯** menu → `Report name…` | Below pause/forfeit items; separator before destructive leg actions |
| **Open lobby** | Participant row → trailing **⋯** | Not on host’s own row |
| **Tournament roster / check-in** | Participant row → **⋯** | Same component as lobby |
| **Online match summary** | Opponent result row → **⋯** | Only when `visibility == online` |
| **Hidden** | Local Players tab, pass-and-play setup, bot rows | No report action — not strangers |

Gate all entry points on `enableOnlineNameReports` + signed-in Auth.

**Report sheet** (`ReportPlayerNameSheet` — working title)

Presentation: **medium detent** sheet (same family as `PlayerEditSheet` / rules sheets).

```
┌─────────────────────────────────────┐
│  Report name                    ✕   │
├─────────────────────────────────────┤
│  If this name is offensive or         │
│  inappropriate, let us know.          │
│                                       │
│  Reason                               │
│  ○ Offensive name          (default)  │
│  ○ Harassment                           │
│  ○ Other                                │
│                                       │
│  Additional details (optional)        │
│  ┌─────────────────────────────────┐  │
│  │                                 │  │
│  └─────────────────────────────────┘  │
│  0 / 200                              │
│                                       │
│  [ Cancel ]        [ Submit report ]  │
└─────────────────────────────────────┘
```

| Element | Spec |
|---------|------|
| **Title** | `online.reportName.title` — e.g. “Report name” |
| **Body** | `online.reportName.body` — one short neutral sentence; no quoted player name |
| **Reason** | Single-select list or `Picker` / radio group; **`offensiveName` pre-selected** |
| **Note** | Optional `TextEditor`; max **200** chars with live counter; not required |
| **Submit** | Primary button; disabled while submitting or if dedupe says already reported |
| **Cancel** | Dismiss without side effects |

**Submit flow**

1. Tap **Submit** → inline progress on button (no full-screen blocker).
2. On success → dismiss sheet → brief **toast/banner** (`online.reportName.success`).
3. **Optimistic hide:** replace displayed name on all visible surfaces for this `reportedUid` with `online.reportName.hiddenLabel` (e.g. “Hidden player”) until server sync provides `displayNameFallback`.
4. On failure → inline error on sheet with **Retry**; keep local hide (reporter preference still applied).

**Already reported (24h dedupe)**

- If client knows dedupe applies: disable Submit; show `online.reportName.alreadyReported` footnote.
- Menu item may show **Report name…** still, or **Name reported** (disabled) — prefer former for discoverability.

**How hidden names render (reporter view)**

| Context | Display |
|---------|---------|
| Score card / lobby row | Generic label + existing avatar chip if present |
| VoiceOver | `online.reportName.a11y.hiddenPlayer` — e.g. “Hidden player” — **never** speak the stored offensive string |
| Global auto-flag (3+ reports) | All clients show `displayNameFallback` from Firestore — same visual treatment |

**Accessibility**

- Menu action: `online.reportName.a11y.action` — “Report player name as inappropriate”.
- Reason options: each option is a button with label + optional hint.
- Success: post `UIAccessibility.post(notification: .announcement, …)`.
- Reduce Motion: sheet presentation only — no celebratory animation on submit.

**Localization keys (draft)**

| Key | Example (en) |
|-----|----------------|
| `online.reportName.title` | Report name |
| `online.reportName.body` | If this name is offensive or inappropriate, let us know. |
| `online.reportName.reason.offensiveName` | Offensive name |
| `online.reportName.reason.harassment` | Harassment |
| `online.reportName.reason.other` | Other |
| `online.reportName.note.placeholder` | Additional details (optional) |
| `online.reportName.submit` | Submit report |
| `online.reportName.success` | Thanks — we’ll review this. |
| `online.reportName.alreadyReported` | You already reported this player recently. |
| `online.reportName.error.generic` | Couldn’t send report. Try again. |
| `online.reportName.error.rateLimit` | Too many reports today. Try again later. |
| `online.reportName.hiddenLabel` | Hidden player |

Ship keys in **all** locales per [`LocalizationSpec.md`](LocalizationSpec.md); copy stays neutral (no language-specific slur examples).

**Settings / help (P2+, lightweight)**

- Settings → Online → link **Community guidelines** / **How reporting works** (`online.reportName.help` static sheet).
- Optional later: list locally hidden players with **Show name again** (clears reporter-only hide, not global moderation).

**Out of scope (UI)**

- In-app moderator review queue (founder uses backend tools first — see Moderator resolution above).
- Report flow for leg disputes (separate tournament dispute UI — may share sheet chrome later).
- Screenshot or camera attach on report.

#### iOS integration (sketch)

- `OnlineModerationService` behind protocol; impl calls `Functions.httpsCallable("submitPlayerNameReport")`.
- Feature flag: `enableOnlineNameReports` (default `false` until Phase D / first cross-user name display).
- Local hide list: `UserDefaults` or SwiftData keyed by `reportedUid` for immediate reporter UX offline.

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
| `name_report_submitted` | User filed name report | `{ reason_category }` only — no names/uids |

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

### Name reports (P2)

- Dedupe: second report same pair within 24h rejected
- Rate limit: 11th report in a day rejected
- Auto-flag at 3 distinct reporters → global fallback name
- Reporter-local hide persists after relaunch
- Non-moderator cannot call `resolveNameReport`

---

## 14. Out of scope (early online)

| Item | Defer to |
|------|----------|
| Voice / video chat | — |
| **MMR / ranked ladder / Elo** | Ladder spec (future) — distinct from §10.3 open lobbies |
| Prize money / payments | — |
| In-tournament host chat | Tournament §8.2 Phase 5+ |

### In scope (explicit)

| Item | Priority |
|------|----------|
| **Local tournaments** | **P1** — [`TournamentSpec.md`](TournamentSpec.md); no Firebase backend |
| **Online head-to-head** | **P2** — Phase A–C |
| **Open lobbies** | **P2** — Phase D (§5); after name moderation + Auth |
| **Verified skill (camera bot challenge)** | **P2** — §10.4; requires Vision Phase B+ |
| **Player name reports** | **P2** — §10.6; Auth + Functions; required before open lobbies |
| **Online tournaments** | **P2** — §6; requires Phase A + Firebase Phase 3 |

---

## 15. Open questions

1. Anonymous Auth sufficient for P2 tournaments or require email/Apple sign-in?
2. Short code length / TTL for join links?
3. `enableOnlineTournaments` separate flag or sub-flag of `enableOnlinePlay`?
4. Firestore real-time listeners vs polling for bracket UI?
5. Ultimate-style paywall on online tournaments (DartCounter model)?
6. Verified credential TTL — permanent vs 90-day refresh?
7. Minimum bot tier for Verified: Hard only, or Pro for upper band?
8. Open lobby browse: global list vs friends-of-friends vs geo — abuse surface?
9. Blocklist maintenance: ship bundled list vs Remote Config updates?
10. Third-party moderation vendor for online (privacy, cost, multilingual coverage)?
11. Moderator staffing: founder-only vs community volunteers vs deferred auto-hide on N reports?
12. Auto-flag threshold: 3 distinct reporters in 7 days — tune before launch?
13. Unified Activity **Reports** tab vs name-only queue for P2?

---

## 16. Index

| Doc | Role |
|-----|------|
| This spec | Online legs + Firebase transport; P2 tournaments |
| [`TournamentSpec.md`](TournamentSpec.md) | Bracket platform; P1 local, P2 online extension |
| [`FirebaseBackendAnalyticsSpec.md`](FirebaseBackendAnalyticsSpec.md) | Firebase phased rollout |
| [`RemixNightGameSpec.md`](game-modes/planned/RemixNightGameSpec.md) | Preset usable in local or online tournament |

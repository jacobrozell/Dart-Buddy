# Tournament Platform Specification (Future)

## 1. Purpose

Define **Tournaments** — a cross-cutting platform for running **multi-match competitions** with brackets, standings, check-in, and a single champion, independent of any one game mode.

Remix Night ([`RemixNightGameSpec.md`](game-modes/planned/RemixNightGameSpec.md)) is a **preset tournament format** (random multi-mode mini-legs, leg-win scoring), not the tournament system itself. This spec covers the shell: create, register, draw, progression, host/moderator tools, spectate (online), and history — reusable for pub knockouts, mode-mixed gauntlets, and remote events.

**Status:** Future / post-1.0 R&D. Not blocking lean 1.0 ship.
**Estimated release:** `2.0+`

### Product priority (shared with [`OnlinePlaySpec.md`](OnlinePlaySpec.md))

| Priority | Scope | Firebase | Detail |
|----------|-------|----------|--------|
| **P1** | **Local tournaments** | None (Analytics/Crashlytics only — 1.0) | §4 P1 — one device, pass-and-play |
| **P2** | **Online tournaments** | Auth + Firestore + Functions | §14 — requires [`OnlinePlaySpec.md`](OnlinePlaySpec.md) online legs first |

Implement **`TournamentOrchestrator` and local hub in P1** with online-ready IDs (`schemaVersion`, `visibility`). P2 adds Firebase transport — not a bracket rewrite.

**Related specs:**
- [`RemixNightGameSpec.md`](game-modes/planned/RemixNightGameSpec.md) — preset: `format: remix_night`
- [`CampaignSpec.md`](CampaignSpec.md) — solo Journey arcs; not bracket tournaments
- [`MatchSpec.md`](MatchSpec.md) — child leg lifecycle + `tournamentId` linkage
- [`MatchSummarySpec.md`](MatchSummarySpec.md) — leg summary; defers to tournament hub
- [`MatchForfeitSpec.md`](MatchForfeitSpec.md) — leg forfeit; host may force advance (§8)
- [`HistorySpec.md`](HistorySpec.md) — parent `TournamentRecord` + leg refs
- [`SetupFlowSpec.md`](SetupFlowSpec.md) — roster picker at create
- [`StatisticsTabSpec.md`](StatisticsTabSpec.md) — min-average gates from local stats (P2 online)
- [`CalloutVoicesSpec.md`](CalloutVoicesSpec.md) — match / throw-first ceremony TTS
- [`OnlinePlaySpec.md`](OnlinePlaySpec.md) — **P2** online legs + Firebase + online tournaments (§3–§6)
- [`FirebaseBackendAnalyticsSpec.md`](FirebaseBackendAnalyticsSpec.md) — Auth / Firestore / Functions phases for P2
- [`FeatureFlagConfigSpec.md`](FeatureFlagConfigSpec.md) — `enableLocalTournaments` (P1), `enableOnlinePlay` + `enableOnlineTournaments` (P2)
- [`FutureIdeas/custom-games-brainstorm.md`](../FutureIdeas/custom-games-brainstorm.md) — Remix Night §8

---

## 2. Competitive reference — DartCounter

[DartCounter](https://dartcounter.net/) shipped **online tournaments** as a flagship 2025 feature: register or host, bracket view, live participation list, post-round stats, and entry gates (min 3-dart average). It is one of the most cited reasons players stay on the platform.

Sources: [press release](https://dartcounter.net/press/online-tournaments), [v8.6.0](https://dartcounter.net/release-notes/release-notes-dartcounter-v8-6-0), [v8.8.0](https://dartcounter.net/release-notes/release-notes-dartcounter-v8-8-0), [v9.0.9](https://dartcounter.net/release-notes/release-notes-dartcounter-v9-0-9), [Jan](https://dartcounter.net/updates/january-dev-update) / [Apr 2025 dev updates](https://dartcounter.net/updates/april-dev-update), [user feedback #2214](https://requests.dartcounter.net/2214) (per-round formats).

### 2.1 DartCounter — observed feature set

| Area | Behavior (observed / documented) |
|------|----------------------------------|
| **Discovery** | Browse / join public tournaments; host creates own event |
| **Registration** | Join before start; account required for online |
| **Check-in** | Timed window; **one-tap auto check-in** on join during window (v8.6) |
| **Entry gate** | Host sets **minimum 3-dart average** |
| **Format lock** | **One game format for entire event** (301/501, Cricket/Tactics, etc.) |
| **Match shape** | **Best-of legs**; **odd leg count only** (even legs disallowed — v8.6) |
| **Bracket** | Visual bracket + participation list; live progress |
| **Throw first** | Bull (incl. Omni); **rethrow on tie** (v8.8 fix) |
| **Ceremony** | MasterCaller audio on match start / throw-first |
| **Spectate** | Watch live matches; join-next while spectating was buggy (2025 fixes) |
| **Stats** | Per-round detailed stats after each match |
| **Moderation** | Host/moderator role evolving: check-in, direct player handling, reports via Activity (v9.0.9) |
| **Integrity** | Leaving mid-tournament could corrupt bracket (fixed v9.0.9); deleting a leg from stats could break event access (fixed v8.6) |
| **Pain points** | Players **dropped for not responding in time**; moderators want more control; **no per-round format change** (top feedback #2214, status: Future plan); host→player messaging requested (#2191) |
| **Monetization** | Free: limited online play; Ultimate: unlimited online + more modes |
| **Roadmap** | More tournament formats; deeper tournament performance analytics |

### 2.2 DartCounter gaps → Dart Buddy opportunities

| Gap / pain (DartCounter) | Dart Buddy response |
|--------------------------|---------------------|
| Single format for whole event | **Per-round / per-bracket-tier leg map** native (§6.3) — e.g. R1 301 DI/D0 → SF 501 SI/DO → Final Cricket |
| Online-only / account required for real events | **Local pub tournament** on one phone — no Wi‑Fi, no login (**P1**) |
| Timed check-in drops players | Local: host-controlled start; online (**P2**): generous ready window + host override (§7) |
| Bracket corruption on leave | **Withdraw locks bracket node** + host repair tools (§8.4) |
| Mostly X01 / Cricket brackets | **Multi-mode presets** — Remix Night, gauntlet, mode-mixed KO (**P1.2**) |
| No structured pub “league night” offline | Templates: “Tuesday 501 KO”, export results card (**P1.3**) |

### 2.3 Parity matrix (what Dart Buddy should match)

| Feature | P1 (local) | P2 (online) | Notes |
|---------|------------|-------------|-------|
| Create / host event | ✓ | ✓ | |
| Join / register | ✓ (on-device roster) | ✓ | P2: code / link |
| Check-in / ready | ✓ (simple) | ✓ | Avoid aggressive auto-drop |
| Bracket view | ✓ | ✓ | List fallback + a11y |
| Participation list + live state | ✓ | ✓ | |
| Best-of legs (odd only) | ✓ | ✓ | Shared rule §6.4 |
| Bull throw-first + rethrow tie | ✓ | ✓ | Reuse match chrome |
| Min average entry gate | — | ✓ | From local stats |
| Per-round format config | P1.2+ | ✓ | **Differentiator** |
| Spectate | — | ✓ | Read-only leg sync |
| Post-leg stats drill-down | P1.2+ | ✓ | Link to Activity leg |
| Moderator: force result / DQ | P1.2+ | ✓ | |
| Host messaging | — | defer | Push; low priority |
| Action replay / share | — | defer | Not tournament-core |

---

## 3. Product positioning

| Principle | Rule |
|-----------|------|
| **Platform, not a mode** | Tournament is a **container**; legs use existing `MatchType` engines. |
| **Local-first v1** | One device, pass-and-play — pub night without accounts or Wi‑Fi. |
| **Multi-mode is the moat** | Per-round leg configs + Remix / gauntlet presets (DartCounter’s #1 requested tournament feature). |
| **Host at the oche** | Creator runs the event from their phone; moderator tools grow with online. |
| **Free play ungated** | Tournaments optional; Play/Modes unchanged. |
| **Bracket integrity** | Withdraw / DQ / delete never silently corrupt tree — repair or freeze node. |
| **Online later** | IDs and payload versioning designed for sync from day one (§14). |

---

## 4. Scope by phase

### P1 — Local tournaments (post-1.0, no Firebase backend)

P1 is split into incremental delivery slices. All P1 work uses SwiftData + on-device orchestrator only.

#### P1.1 — Local tournament shell (MVP)

| Item | Detail |
|------|--------|
| **Entry** | Play home → **Tournament** → Create or Resume |
| **Formats** | Single elimination; double elimination (optional v1.1) |
| **Players** | 2–16 humans; pass-and-play on one device |
| **Leg config** | Single `MatchType` + config for **all** rounds (DartCounter parity) |
| **Match shape** | Best-of **1 / 3 / 5** legs (odd only); applies to each bracket node |
| **Seeding** | Random or manual drag-order |
| **Hub** | Bracket + participation list; **Next match** CTA |
| **Throw first** | Bull + rethrow on tie per leg |
| **History** | `TournamentRecord` parent + child `MatchLegRef[]` |
| **Flag** | `enableLocalTournaments` |

#### P1.2 — Multi-mode & host tools

| Item | Detail |
|------|--------|
| **Per-round leg map** | Different `LegDefinition` per bracket tier (QF / SF / F) or round index |
| **Presets** | Remix Night, X01 KO, Cricket KO, **Custom gauntlet** |
| **Round robin → KO** | Groups of 4–6, top 2 advance |
| **Orchestrator** | Shared `TournamentOrchestrator` with Remix Night |
| **Moderator (local)** | Mark walkover, replace player, restart leg |
| **Post-leg stats** | Leg summary card + link to full Activity detail |
| **Co-op exhibition** | Raid / Vault legs — table score only, no elimination |

#### P1.3 — Templates & polish

| Item | Detail |
|------|--------|
| **Saved templates** | “Pub 501 KO”, “Mixed format night” |
| **Handicap** | Start score offset per player tier |
| **Export** | Bracket PNG + results text share sheet |
| **Player stats** | Tournament wins, legs won, format breakdown |
| **Achievements** | Champion / finalist badges |
| **Bronze match** | Optional 3rd-place node |

### P2 — Online tournaments ([`OnlinePlaySpec.md`](OnlinePlaySpec.md) + Firebase)

**Prerequisites:** Online head-to-head Phase A ([`OnlinePlaySpec.md`](OnlinePlaySpec.md) §5) + Firebase Auth/Firestore/Functions ([`FirebaseBackendAnalyticsSpec.md`](FirebaseBackendAnalyticsSpec.md) Phases 2–3).

| Item | Detail |
|------|--------|
| **Hosted online** | Create event, share link / short code |
| **Registration** | Open / closed; max players; min average gate |
| **Check-in window** | Scheduled start −15 min → start; one-tap ready |
| **Live bracket** | Server-authoritative; multi-device |
| **Remote legs** | Turn sync via [`OnlinePlaySpec.md`](OnlinePlaySpec.md) command model |
| **Spectate** | Read-only leg view; cannot block join-next |
| **Reports** | Flag leg; host review queue (Activity) |
| **Integrity** | Cannot leave mid-event without withdraw flow |
| **Flags** | `enableOnlinePlay` + `enableOnlineTournaments` |

See [`OnlinePlaySpec.md`](OnlinePlaySpec.md) §4 (Firestore), §6 (tournament milestones T-A–T-E), §8.2 (tournament commands).

### Out of scope (early)

- Prize money / payments
- WDF/ADO sanctioning
- Multi-board venue commissaire mode
- Public global MMR ladder (see [`OnlinePlaySpec.md`](OnlinePlaySpec.md))
- In-tournament chat (host broadcast defer)

---

## 5. Tournament formats

Formats are **recipes** — configuration presets, not separate engines.

| Format id | Name | Structure | Scoring |
|-----------|------|-----------|---------|
| `single_elim` | Knockout | Power-of-2 bracket + byes | Advance winner |
| `double_elim` | Double elimination | Winners + losers bracket | Advance / drop to losers |
| `round_robin` | Round robin | All play all | Points table |
| `group_knockout` | Groups → KO | RR groups then single elim | Group points → bracket |
| `remix_night` | Remix Night | No bracket | **Most leg wins** ([`RemixNightGameSpec.md`](game-modes/planned/RemixNightGameSpec.md)) |
| `gauntlet` | Gauntlet | Fixed leg sequence | Cumulative or final-leg winner |

**Remix Night:** Catalog quick-start or Play → Tournament → Remix preset. Uses `scoringMode: legWins`, not bracket advancement.

---

## 6. Configuration model

### 6.1 Create wizard (host)

| Step | Fields | DartCounter analog |
|------|--------|-------------------|
| 1. **Basics** | Title, format, player cap (2–16 local) | Event name, format |
| 2. **Roster** | Pick players (reuse Setup roster UI); drag seed order | Registration list |
| 3. **Leg rules** | Default `LegDefinition` OR per-tier map (**P1.2**) | Single X01/Cricket config |
| 4. **Match shape** | Best-of 1 / 3 / 5 (odd); optional per-tier override | Best-of legs |
| 5. **Options** | Third-place match, random seed, throw-first method | — |
| 6. **Review** | Bracket preview, leg cheat sheet | Bracket preview |
| 7. **Start** | Lock roster → `status: active` | Check-in closes / start |

Online P2 inserts **Schedule** (start time, check-in open, min average) before Start.

### 6.2 `LegDefinition`

```text
LegDefinition {
  matchType: MatchType              // x01, cricket, shanghai, …
  configSnapshot: Data            // encoded MatchConfig*
  label: String?                  // "Semi-final — 501"
  bestOfLegs: Int?                // override tournament default; must be odd
}
```

### 6.3 Per-round leg map (differentiator)

`roundLegMap` keys bracket **tier** or **round index** to a `LegDefinition`.

**Example — “Mixed format KO” (8 players):**

| Tier | Leg definition |
|------|------------------|
| Round 1 (QF) | 301, double in / double out, best-of 1 |
| Round 2 (SF) | 501, straight in / double out, best-of 3 |
| Final | Standard cricket, best-of 1 |
| Bronze (optional) | 301 sudden death, best-of 1 |

DartCounter users currently plan this in a **second app** ([feedback #2214](https://requests.dartcounter.net/2214)); Dart Buddy makes it first-class.

**Remix preset:** `roundLegMap` unused; `legDefinitions[]` holds 3 drawn random modes (see Remix spec).

### 6.4 Best-of legs rules

| Rule | Detail |
|------|--------|
| **Odd only** | 1, 3, 5, 7 — no even best-of (DartCounter v8.6; prevents tied series) |
| **Leg winner** | Child engine decides per leg |
| **Node winner** | First to `(bestOf / 2).floor + 1` leg wins |
| **Cricket 3+ players** | Best-of **not** used — single leg or points-based only (DartCounter restriction) |
| **Tiebreaker** | Extra leg at same config; then bull sudden death |

### 6.5 Entry gates (P2 online)

| Gate | Source |
|------|--------|
| Min 3-dart average | `StatisticsTabSpec` rolling average |
| Max players | Host cap |
| Account verified | Auth policy |
| Ultimate tier | Product decision — defer paywall on local |

---

## 7. Participant lifecycle

```text
invited → registered → checked_in → ready → playing → { advanced | eliminated | withdrawn | dq }
```

| State | P1 (local) | P2 (online) |
|-------|---------------|----------------|
| **registered** | On create roster | Joined via code/link |
| **checked_in** | Host taps “Everyone here” | Auto on join during window OR manual ready |
| **ready** | Implicit at start | Explicit ready flag |
| **playing** | In active leg | In synced leg |
| **eliminated** | Lost bracket node | Same |
| **withdrawn** | Host marks left early | Player withdraw flow — **never** silent bracket corrupt |
| **dq** | Host disqualify | Moderator + report trail |

### Check-in policy (learn from DartCounter pain)

DartCounter’s **timed auto-drop** for non-response is a top complaint ([Jan 2025 dev update](https://dartcounter.net/updates/january-dev-update)).

Dart Buddy defaults:

| Surface | Policy |
|---------|--------|
| **Local** | No timeout — host starts when pub is ready |
| **Online** | Check-in window with **push reminders**; host can **mark ready** or **replace** player; auto-drop only after host confirms or 2× reminder (configurable) |

---

## 8. Host & moderator tools

### 8.1 Local (P1.2+)

| Action | Effect |
|--------|--------|
| **Start / pause tournament** | Hub frozen; legs cannot start when paused |
| **Mark walkover** | Advance opponent; leg recorded as WO |
| **Replace player** | Swap player on node before leg starts; reseed if needed |
| **Restart leg** | Abandon current leg record; replay same node (audit log) |
| **Edit seed** | Before first leg only |
| **Abandon event** | `status: abandoned`; partial history kept |

### 8.2 Online (P2)

| Action | Effect |
|--------|--------|
| All local actions | Server-authoritative |
| **Force advance** | Moderator resolves disputed leg |
| **Review report** | Activity queue (DartCounter v9.0.9 pattern) |
| **Message players** | Push template (“Final on board 1”) — Phase 5 |

### 8.3 Bracket integrity (DartCounter lessons)

| Failure | Dart Buddy rule |
|---------|-----------------|
| Player leaves mid-event | **Withdraw** flow; opponent may advance; bracket snapshot versioned |
| Delete leg from History | **Block** or cascade repair tournament node; never orphan bracket ([DC v8.6 fix](https://dartcounter.net/release-notes/release-notes-dartcounter-v8-6-0)) |
| Simultaneous legs | One **active node** per player; hub enforces |
| Spectator join-next race | Queue “next match” claim; fixed in DC Apr 2025 — mirror in online design |

### 8.4 Walkover / BYE

- **BYE:** auto-advance top seed when bracket size < power of 2.
- **WO:** host declares no-show; advancing player gets leg-win credit without playing.

---

## 9. Data model

### 9.1 `TournamentRecord`

```text
TournamentRecord {
  id: UUID
  title: String
  format: TournamentFormat
  status: draft | check_in | active | paused | complete | abandoned
  visibility: local | online
  createdAt, scheduledStartAt?, startedAt?, completedAt?
  hostPlayerId: UUID?
  participantIds: [UUID]              // frozen at start
  seedOrder: [UUID]
  config: TournamentConfigPayload     // JSON v1
  participantStates: [UUID: ParticipantState]
  legRefs: [MatchLegRef]
  standings: TournamentStandings
  schemaVersion: Int
}
```

### 9.2 `TournamentConfigPayload` (v1)

| Field | Type | Notes |
|-------|------|-------|
| `format` | enum | §5 |
| `playerCap` | Int | 2–16 local; higher online later |
| `defaultLeg` | `LegDefinition` | Fallback for all nodes |
| `roundLegMap` | `[RoundKey: LegDefinition]` | P1.2 — per-tier configs |
| `defaultBestOf` | Int | Odd; 1 / 3 / 5 |
| `scoringMode` | `bracket` \| `legWins` \| `aggregatePoints` | Remix = `legWins` |
| `tiebreakerLeg` | `LegDefinition?` | Default 301 D-out |
| `thirdPlaceMatch` | Bool | default false |
| `throwFirstMethod` | `bull` \| `random` \| `alternate` | Default bull |
| `minThreeDartAverage` | Double? | Online only |
| `checkInOpensMinutesBefore` | Int? | Online; default 15 |

### 9.3 `TournamentStandings`

```text
bracketNodes[]: {
  id, round, slot,
  playerA?, playerB?,
  winnerId?, status: pending | ready | in_progress | complete | walkover,
  legRefs: [UUID],
  legsWon: [PlayerId: Int]
}
roundRobinTable: { wins, losses, legDiff }   // RR formats
legWins: [PlayerId: Int]                     // remix / gauntlet
eliminated: Set<PlayerId>
placement: [PlayerId: Int]                   // 1st, 2nd, 3rd…
```

### 9.4 Match linkage

Each leg → normal `MatchRecord` with:

```text
tournamentId: UUID
tournamentNodeId: UUID
tournamentLegIndex: Int          // leg 1 of best-of-3
```

Activity: collapsible 🏆 row → legs grouped by round. **Deleting a tournament leg** requires host confirm + bracket repair (§8.3).

---

## 10. Rules engine — `TournamentOrchestrator`

Pure coordinator — no scoring of its own.

### 10.1 Responsibilities

| Responsibility | Owner |
|----------------|-------|
| Bracket generation & BYE placement | Orchestrator |
| Resolve `LegDefinition` for node (map lookup) | Orchestrator |
| Hydrate child engine | Orchestrator → `MatchType` engine |
| Leg / node win detection | Child engine |
| Advance bracket | Orchestrator |
| Remix leg-win tally | Orchestrator |
| Tiebreaker injection | Orchestrator |
| Undo | Child engine only; bracket rollback host-only P1.2 |

### 10.2 Bracket generation (single elim)

- `n` players → bracket size = next power of 2.
- BYEs: lowest seeds (or random if unseeded).
- Winner propagates; loser `eliminated` unless double elim.

### 10.3 Node → leg flow

1. Hub highlights **ready** node (both players free).
2. Resolve leg config + best-of for node.
3. **Throw first** mini-phase (bull) → child match.
4. On leg complete → update `legsWon`; if node complete → advance bracket.
5. Return to hub with celebration + **Next match**.

### 10.4 Session flow (local)

```text
Create → Review bracket → [Check-in] → Start → Hub ⟷ Legs → Champion ceremony → History
```

Pass-and-play: privacy handoff optional between opponents on shared device.

---

## 11. UX specification

### 11.1 Tournament hub (persistent shell)

| Element | Behavior |
|---------|----------|
| **Header** | Title, format, round label (“Semi-final”), players remaining |
| **Next match** | Primary CTA — shows matchup + leg config summary |
| **Bracket tab** | Pinch-zoom tree; compact list on SE / a11y |
| **Players tab** | Participation list with state chips (DartCounter-style live list) |
| **Standings tab** | RR table or placement |
| **Rules** | Cheat sheet for **current** leg config |
| **Host menu** | Walkover, pause, abandon (gated) |

### 11.2 Bracket node card

| Field | Example |
|-------|---------|
| Matchup | Alex vs Jordan |
| Config | 501 · Best of 3 |
| Status | 1–0 · Alex leads |
| CTA | Play leg 2 |

### 11.3 Between legs

- Leg summary strip (winner, avg, checkout).
- “Return to tournament” — never dump to Play home mid-event.
- Optional TTS: “Game on” / throw-first callout ([`CalloutVoicesSpec.md`](CalloutVoicesSpec.md)).

### 11.4 Champion ceremony

- Podium (1st / 2nd / 3rd if bronze).
- Share card: event title, bracket mini, final scores.
- Links to each leg in Activity.

### 11.5 Quick starts (Play home)

| Preset | Format | Config |
|--------|--------|--------|
| **501 Knockout** | `single_elim` | 501 D-out, BO1, 8 players |
| **501 Best of 3** | `single_elim` | 501, BO3 |
| **Remix Night** | `remix_night` | 3 random legs, 2–4 players |
| **Mixed format KO** | `single_elim` | Per-round map (P1.2) |

### 11.6 Accessibility

- Bracket **list mode** for VoiceOver (round → match → status).
- Dynamic Type: participation list primary; tree decorative.
- Throw-first fully announced.

---

## 12. History & statistics

| Stat / record | Detail |
|---------------|--------|
| Tournaments hosted | Per profile |
| Tournaments won | Per profile |
| Leg win rate (tournament) | Per profile, per mode |
| Event duration | Analytics |
| Per-leg averages in event | Drill-down like DartCounter post-round stats |

**History card:** 🏆 title, format, champion, player count, date, duration.

**Filter:** Activity → Tournaments only.

---

## 13. Analytics (Firebase)

| Event | When |
|-------|------|
| `tournament_created` | format, player_count, visibility |
| `tournament_started` | |
| `tournament_leg_completed` | match_type, round_tier, best_of |
| `tournament_completed` | winner_id, duration, leg_count |
| `tournament_abandoned` | reason |

---

## 14. P2 — Online extension (Firebase + [`OnlinePlaySpec.md`](OnlinePlaySpec.md))

Online tournaments are **P2**. They reuse P1 `TournamentOrchestrator`, `TournamentConfigPayload`, and hub UX — with an `OnlineTournamentTransport` writing bracket state to Firestore.

### 14.1 Prerequisites

| Prerequisite | Spec |
|--------------|------|
| Online 1v1 leg sync | [`OnlinePlaySpec.md`](OnlinePlaySpec.md) Phase A |
| Firebase Auth | [`FirebaseBackendAnalyticsSpec.md`](FirebaseBackendAnalyticsSpec.md) Phase 2 |
| Firestore + Functions | Firebase Phase 3 |
| Stable local orchestrator | This spec P1.1+ |

### 14.2 Local → online mapping

| P1 (local) | P2 (online) |
|------------|-------------|
| `TournamentRecord` in SwiftData | Firestore `tournaments/{id}` + local cache |
| Roster on create | Registration + check-in ([`OnlinePlaySpec.md`](OnlinePlaySpec.md) §8.2) |
| Pass-and-play leg | Remote leg via `SubmitTurn` |
| Bracket node | Server-authoritative node doc |
| Host menu actions | `ModeratorAdvance`, `WithdrawFromTournament` commands |
| `visibility: local` | `visibility: online` |

### 14.3 Firestore (summary)

Full collection layout: [`OnlinePlaySpec.md`](OnlinePlaySpec.md) §4.1. Cloud Functions: `advanceTournamentNode`, `processCheckIn`, `withdrawParticipant`.

### 14.4 Spectator & integrity

- Read-only leg event stream; explicit join-next queue (DartCounter lesson).
- `TournamentConfigPayload.schemaVersion` + match event timeline compatible with [`MatchSpec.md`](MatchSpec.md) for audit replay.
- Deleting a local copy of an online leg triggers repair flow — never silent bracket orphan.

### 14.5 Feature flags

| Flag | Phase |
|------|-------|
| `enableLocalTournaments` | P1 |
| `enableOnlinePlay` | P2 (prerequisite) |
| `enableOnlineTournaments` | P2 (requires online play) |

---

## 15. Testing strategy

| Area | Cases |
|------|-------|
| Bracket math | 2, 3, 5, 8, 9, 16 players; BYE placement |
| Best-of | BO1/3/5; reject BO2/4; node win at correct leg count |
| Per-round map | QF 301 vs Final 501 resolves correct config |
| Advancement | Single + double elim paths |
| Walkover / withdraw | Bracket remains consistent |
| Delete leg | Repair or block; no frozen bracket |
| Remix preset | Leg-win tie → sudden-death |
| Resume | Hub restores active node mid-tournament |
| Orchestrator | Roster frozen; child undo isolated |
| a11y | List bracket navigable |

---

## 16. Open questions

1. **Tab placement:** Play home card vs dedicated Tournament tab?
2. **Remix catalog row:** Keep `party.remixNight` or Tournament quick-start only?
3. **Bots:** Fill BYEs with bots in local KO?
4. **Minimum players:** 2-player BO tournament or 4+ for knockout branding?
5. **Online paywall:** Free local always; online tournaments Ultimate-only?
6. **Per-round map in P1.1** or P1.2 only?
7. **Naming:** “Tournament” vs “Event” vs “League night” for pub marketing?

---

## 17. Promotion path

1. Define `TournamentOrchestrator` protocol + `TournamentConfigPayload` v1 in domain (**online-ready IDs**).
2. **P1.1:** Local single-elim + hub UI; flag `enableLocalTournaments`.
3. Extract Remix Night as first `legWins` consumer; align [`RemixNightGameSpec.md`](game-modes/planned/RemixNightGameSpec.md).
4. **P1.2:** `roundLegMap` — ship before P2 to establish DartCounter differentiation.
5. **P2:** Ship [`OnlinePlaySpec.md`](OnlinePlaySpec.md) Phase A (online 1v1) + Firebase Phases 2–3.
6. **P2:** `OnlineTournamentTransport` + `enableOnlineTournaments`; wire Firestore/Functions per [`OnlinePlaySpec.md`](OnlinePlaySpec.md) §4–§6.

---

## 18. Index

| Doc | Role |
|-----|------|
| This spec | Platform — lifecycle, brackets, host tools, DC parity matrix |
| [`RemixNightGameSpec.md`](game-modes/planned/RemixNightGameSpec.md) | Preset — random 3-leg leg-win |
| [`CampaignSpec.md`](CampaignSpec.md) | Solo Journey — not tournaments |
| [`OnlinePlaySpec.md`](OnlinePlaySpec.md) | P2 online legs + Firebase + online tournaments |
| [`FirebaseBackendAnalyticsSpec.md`](FirebaseBackendAnalyticsSpec.md) | Firebase phased rollout for P2 |
| [DartCounter press](https://dartcounter.net/press/online-tournaments) | Competitive reference |
| [DC feedback #2214](https://requests.dartcounter.net/2214) | Per-round format demand |

# Intents

Siri, Shortcuts, Apple Intelligence, and future system-surface integrations for Dart Buddy.

**Authoritative spec:** [`specs/AppIntentsSpec.md`](../specs/AppIntentsSpec.md) — intent inventory, entities, Apple Intelligence roadmap (§13), testing ladder (§10).

## Current state (Phase 1)

Navigation shortcuts only. Siri can **open** or **resume** the app; it does not yet understand players, matches, or scores.

| Intent | File |
|---|---|
| Open Play | `Actions/OpenPlayIntent.swift` |
| Resume Active Match | `Actions/ResumeActiveMatchIntent.swift` |
| Shortcuts provider | `Providers/DartBuddyShortcutsProvider.swift` |
| Routing bridge | `Routing/IntentRoutingBridge.swift` |

Gated by `enableAppIntents` (launch argument `-enable_app_intents`). See spec §6.

## Target module map

```
Intents/
  Actions/       AppIntent perform() — navigation, start, scoring (phased)
  Entities/      AppEntity types (planned — Phase 1b/2)
  Enums/         AppEnum for mode picker in Shortcuts (planned)
  Queries/       Read-only query intents (planned — Phase 2)
  Providers/     AppShortcutsProvider (Siri phrases)
  Routing/       IntentRoutingBridge → AppRouteRouter / PendingAppDestination
```

## Quick start (local development)

1. Add launch argument `-enable_app_intents` (Xcode → Edit Scheme → Run → Arguments).
2. Build and run.
3. Open the **Shortcuts** app or ask Siri using the registered phrases (see spec §4.1).

## Adding a navigation intent (Phase 1 pattern)

1. Read [`specs/AppIntentsSpec.md`](../specs/AppIntentsSpec.md) and [`specs/DeepLinkSpec.md`](../specs/DeepLinkSpec.md).
2. Add an `AppIntent` in `Actions/` that calls `IntentRoutingBridge.route(_:intentName:)`.
3. Register phrases in `DartBuddyShortcutsProvider` (keep total pinned shortcuts ≤ 5 in early phases).
4. Add localization keys to **all** locale files (`en`, `de`, `es`, `nl`).
5. Add unit tests for bridge routing and analytics allowlist.
6. Update `AppIntentsSpec.md` intent inventory (§4).

## Adding entities or query intents (Phase 2+ pattern)

Follow spec §4.5–4.9 and §13 before coding:

1. **Define `AppEntity`** types that wrap existing domain models (`PlayerSummary`, `MatchSummary`) — do not invent parallel persistence.
2. **Add entity queries** so Siri can resolve spoken names to entities.
3. **Prefer `IndexedEntity`** for local match history and player roster (semantic search).
4. **Query intents** return dialogs or values without routing when possible (`openAppWhenRun = false`).
5. **Annotate views** on gameplay / summary / history with the same entity types for “this game” context.
6. Test in order: unit tests → `AppIntentsTesting` → Shortcuts → Spotlight → Siri (spec §10).

Dart Buddy uses **custom intents**, not Apple App Schema domains (messages, mail, etc.) — see spec §4.9.

## Do not

- Navigate by setting `@State` tab selection from intent code.
- Create matches or submit scores without going through existing ViewModel / `MatchCommandService` boundaries.
- Duplicate URL path definitions — use `AppDestination` and reference `DeepLinkSpec.md`.
- Log player names, UUIDs, or scores in intent analytics metadata.

## Further reading

- [`specs/AppIntentsSpec.md`](../specs/AppIntentsSpec.md) §13 — Apple Intelligence platform model and phrase maturity table
- [`.cursor/plans/app_intents_brainstorm_174c8c15.plan.md`](../.cursor/plans/app_intents_brainstorm_174c8c15.plan.md) — brainstorm catalog and priority matrix

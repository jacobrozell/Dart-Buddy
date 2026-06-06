# Intents

Siri, Shortcuts, and future system-surface integrations for Dart Buddy.

**Authoritative spec:** [`specs/AppIntentsSpec.md`](../specs/AppIntentsSpec.md)

## Quick start (local development)

1. Add launch argument `-enable_app_intents` (Xcode → Edit Scheme → Run → Arguments).
2. Build and run.
3. Open the **Shortcuts** app or ask Siri using the registered phrases (see spec §4.1).

## Module map

```
Intents/
  Actions/       AppIntent perform() implementations
  Providers/     AppShortcutsProvider (Siri phrases)
  Routing/       IntentRoutingBridge → AppRouteRouter / PendingAppDestination
```

## Adding a new intent

1. Read [`specs/AppIntentsSpec.md`](../specs/AppIntentsSpec.md) and [`specs/DeepLinkSpec.md`](../specs/DeepLinkSpec.md).
2. Add an `AppIntent` in `Actions/` that calls `IntentRoutingBridge.route(_:intentName:)`.
3. Register phrases in `DartBuddyShortcutsProvider` (keep total pinned shortcuts ≤ 5 in early phases).
4. Add localization keys to **all** locale files (`en`, `de`, `es`, `nl`).
5. Add unit tests for bridge routing and analytics allowlist.
6. Update `AppIntentsSpec.md` intent inventory.

## Do not

- Navigate by setting `@State` tab selection from intent code.
- Create matches or submit scores without going through existing ViewModel / `MatchCommandService` boundaries.
- Duplicate URL path definitions — use `AppDestination` and reference `DeepLinkSpec.md`.

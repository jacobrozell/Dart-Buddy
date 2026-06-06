# Deep Links

Versioned custom URL scheme (`dartbuddy://v1/…`) and typed in-app routing.

**Authoritative spec:** [`specs/DeepLinkSpec.md`](../specs/DeepLinkSpec.md)

## Module map

```
Support/DeepLinks/
  DartBuddyURL.swift           URL builders (single source of truth for producers)
  DeepLinkParser.swift         URL → AppDestination
  AppDestination.swift         Typed navigation targets
  DeepLinkError.swift          Parse failures
  PendingAppDestination.swift  Deferred delivery through bootstrap/onboarding

App/Navigation/
  AppRouteRouter.swift         AppDestination → tab/stack actions
```

## Consumers

| Consumer | How it routes |
|---|---|
| `.onOpenURL` in `DartBuddyApp` | Parser → pending queue → `MainTabView` consumes |
| App Intents | `IntentRoutingBridge` → same router (see [`Intents/README.md`](../Intents/README.md)) |
| Play reminders (future) | `DartBuddyURL.play()` in notification payload |
| Widgets (future) | `DartBuddyURL.resumeActiveMatch()` tap targets |

## Adding a new path

1. Add builder to `DartBuddyURL`.
2. Extend `DeepLinkParser.parseV1` and `AppDestination` if needed.
3. Implement handler in `AppRouteRouter`.
4. Register path in [`specs/DeepLinkSpec.md`](../specs/DeepLinkSpec.md) URL table.
5. Add parser + router unit tests.

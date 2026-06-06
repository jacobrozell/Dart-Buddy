# Deep Link Specification

## 1. Purpose

Versioned, typed deep links unify navigation from notifications, App Intents, widgets, and future Universal Links into a single routing spine.

**MVP scope (Phase 1):** custom scheme only, core Play and tab routes.

---

## 2. URL registry — v1 (MVP)

Base: `dartbuddy://v1/{path}`

| Path | Maps to | Status |
|---|---|---|
| `/tab/{play\|modes\|players\|activity\|settings}` | `.tab(...)` | Shipped |
| `/play` | `.play(.home)` | Shipped |
| `/play/resume` | `.play(.resumeActive)` | Shipped |
| `/play/setup` | `.play(.setup(...))` | Planned |
| `/play/match/{uuid}` | `.play(.activeMatch)` | Planned |
| `/activity/history/match/{uuid}` | `.activity(.historyDetail)` | Planned |
| `/players/{uuid}` | `.players(.detail)` | Planned |

**Aliases:**

- `dartbuddy://play` → `dartbuddy://v1/play`

---

## 3. AppDestination schema

```swift
enum AppDestination {
    case tab(TabDestination)
    case play(PlayDeepLink)
    case activity(ActivityDeepLink)
    case players(PlayersDeepLink)
    case settings(SettingsDeepLink)
}
```

Destinations express navigation intent only. Match creation stays in `MatchSetupViewModel`.

---

## 4. Router behavior (MVP)

| Destination | Action |
|---|---|
| `.tab(...)` | Select root tab |
| `.play(.home)` | Select Play tab; reset Play navigation stack |
| `.play(.resumeActive)` | Select Play tab; fetch active match → resume or log failure |

Implementation: `AppRouteRouter` in `App/Navigation/AppRouteRouter.swift`.

---

## 5. Deferred delivery

`PendingAppDestination` queues links until:

1. Bootstrap is ready (app shell visible)
2. Onboarding is dismissed

Links received during onboarding log `deep_link_deferred` and apply after `onFinished`.

---

## 6. Versioning policy

- `v1` paths are stable once shipped; new paths are additive.
- Unknown versions return `unsupportedVersion` and log `deep_link_unsupported_version`.

---

## 7. Universal Links (future)

| Custom scheme | Universal Link |
|---|---|
| `dartbuddy://v1/play/resume` | `https://dartbuddy.app/v1/play/resume` |

Same path parser; scheme/host layer expands in `DeepLinkParser`.

---

## 8. Cross-references

- [`NavigationSpec.md`](NavigationSpec.md) — typed route enums
- [`AppIntentsSpec.md`](AppIntentsSpec.md) — Siri/Shortcuts consumers call `AppRouteRouter` via `IntentRoutingBridge`
- [App Intents plan](../.cursor/plans/app_intents_brainstorm_174c8c15.plan.md) — phased roadmap
- Play reminders (future) — notification `userInfo["url"]` uses `DartBuddyURL.play()`

---

## 9. Consumers

| Consumer | Entry point | Spec |
|---|---|---|
| Custom URL / `.onOpenURL` | `DeepLinkParser` → `PendingAppDestination` | This document |
| App Intents (Siri/Shortcuts) | `IntentRoutingBridge.route` | [`AppIntentsSpec.md`](AppIntentsSpec.md) |
| Play reminders (future) | `DartBuddyURL.play()` in notification payload | [`FutureIdeas/play-reminders.md`](../FutureIdeas/play-reminders.md) |
| Widgets (future) | `DartBuddyURL` tap targets | [`AppIntentsSpec.md`](AppIntentsSpec.md) §11 |

App Intents and deep links share `AppRouteRouter` and `PendingAppDestination` — do not add parallel routers.

---

## 10. Testing

- `Tests/Unit/DeepLinkParserTests.swift` — parse MVP paths, aliases, rejections, round-trips
- `Tests/Unit/AppRouteRouterTests.swift` — tab selection, play home reset, resume with/without active match, unimplemented routes
- `Tests/Unit/PendingAppDestinationTests.swift` — deferred delivery through bootstrap/onboarding
- `Tests/Unit/FirebaseAnalyticsEventMappingTests.swift` — allowlisted deep link analytics events

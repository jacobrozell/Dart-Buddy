---
name: App Intents test launch args
overview: Enable `-enable_app_intents` on the unit-test host via XcodeGen schemes so DartBuddyShortcutsProvider and intent perform() paths are covered in CI/local DartBuddyTests without flipping the production default or adding UI tests.
todos:
  - id: scheme-args
    content: Add `-enable_app_intents` and `-disable_firebase_analytics` to DartBuddyCI.test and DartBuddy.scheme.test in project.yml; run xcodegen generate
    status: pending
  - id: shortcuts-tests
    content: Update AppIntentsCoverageTests — assert 2 shortcuts when host-enabled; keep explicit flag-off test via LocalFeatureFlagsProvider(arguments: [])
    status: pending
  - id: open-play-intent-tests
    content: Add OpenPlayIntentTests — perform() routes .play(.home) when bridge configured; throws when featureFlagOverrides disable intents
    status: pending
  - id: resume-intent-tests
    content: Add ResumeActiveMatchIntentTests — active match, no match (routing ready), and cold enqueue branches
    status: pending
  - id: verify-ci
    content: Run DartBuddyCI unit tests and regenerate coverage-summary.txt (local artifact; gitignored)
    status: pending
  - id: docs
    content: Update specs/AppIntentsSpec.md §10, FeatureFlagConfigSpec.md, and Intents/README.md with scheme arg policy
    status: pending
isProject: false
---

# Plan: Enable App Intents launch args for unit tests

## Problem today

| Component | How it reads the flag | Unit test today |
|-----------|----------------------|-----------------|
| `LocalFeatureFlagsProvider()` | `ProcessInfo.processInfo.arguments` | No `-enable_app_intents` on test scheme → **off** |
| `DartBuddyShortcutsProvider` | `LocalFeatureFlagsProvider()` directly | Always returns `[]` in CI/local test runs |
| `OpenPlayIntent` / `ResumeActiveMatchIntent` | `IntentRoutingBridge.isEnabled` | Bridge tests use `featureFlagOverrides`; **`perform()` never runs** |
| `IntentRoutingBridgeTests` | `featureFlagOverrides` | Works, but doesn’t cover intent types or shortcuts provider |

`IntentRoutingBridge` already has a test override path; **shortcuts and `perform()` do not**. Launch args are the right fix for those, matching `specs/AppIntentsSpec.md` §6 and `Intents/README.md`.

## Goals (and non-goals)

**Goals**

- CI and local **DartBuddyTests** run with `-enable_app_intents` on the test host
- Deterministic tests for `DartBuddyShortcutsProvider`, `OpenPlayIntent.perform()`, and `ResumeActiveMatchIntent.perform()` branches
- Flag-off behavior still tested explicitly (not via global ProcessInfo)
- Docs/specs updated so the pattern is obvious

**Non-goals (this pass)**

- Default `enableAppIntents` to **on** in Release (still post-QA per release plan)
- `AppIntentsTesting` framework (spec §10 layer 2 — later)
- UI tests invoking Siri/Shortcuts
- New UI tests

## Scheme & CI changes (single source of truth)

Project is **XcodeGen**-driven (`project.yml`). Add test launch args there, then `xcodegen generate`.

**Recommended test argument bundle** (DartBuddyCI + local DartBuddy test action):

```yaml
test:
  commandLineArguments:
    "-enable_app_intents": true
    "-disable_firebase_analytics": true
```

| Scheme | Change |
|--------|--------|
| **DartBuddyCI** | `test.commandLineArguments` as above (CI already uses this scheme) |
| **DartBuddy** (target scheme) | Same args on `scheme.test` so Xcode **Test** locally matches CI |

**Do not** add `-enable_app_intents` to Release/archive configs or UI test `app.launchArguments` unless explicitly desired later.

## Test architecture

### Two explicit test styles

| Style | When to use | Pattern |
|-------|-------------|---------|
| **Host-enabled** | Assert real production wiring | `LocalFeatureFlagsProvider().isEnabled(.enableAppIntents)` → expect `true` |
| **Explicit override** | Assert flag-off or isolated behavior | `LocalFeatureFlagsProvider(arguments: [])` or `IntentRoutingBridge.featureFlagOverrides` |

**Rule:** Never assert “flag is off” using bare `LocalFeatureFlagsProvider()` once CI enables the arg.

### New / updated test files

| File | Tests |
|------|-------|
| **AppIntentsCoverageTests** | Split enabled (count == 2) + disabled via `arguments: []` |
| **OpenPlayIntentTests** (new) | `perform()` routing + disabled throw |
| **ResumeActiveMatchIntentTests** (new) | Active match / no match / cold enqueue |
| **FeatureFlagsTests** | No change (injected `arguments:`) |
| **IntentRoutingBridgeTests** | No change (`defer` reset overrides) |

### `perform()` test harness

Mirror `IntentRoutingBridgeTests`:

```swift
@MainActor
defer {
    IntentRoutingBridge.clearRouteActions()
    IntentRoutingBridge.featureFlagOverrides = [:]
}
IntentRoutingBridge.configure(dependencies: ..., actions: ...)
_ = try await OpenPlayIntent().perform()
```

For disabled tests: `IntentRoutingBridge.featureFlagOverrides = [.enableAppIntents: false]` even when launch arg is on.

## Implementation sequence

1. `project.yml` — add `commandLineArguments` to `DartBuddyCI.test` and `DartBuddy.scheme.test`
2. `xcodegen generate`
3. Implement / update tests per table above
4. Verify `xcodebuild test -scheme DartBuddyCI`
5. Regenerate `coverage-summary.txt` (gitignored local artifact)
6. Update `specs/AppIntentsSpec.md` §10, `FeatureFlagConfigSpec.md`, `Intents/README.md`

## Validation checklist

- [ ] `LocalFeatureFlagsProvider().isEnabled(.enableAppIntents)` is `true` under DartBuddyCI test run
- [ ] `DartBuddyShortcutsProvider.appShortcuts.count == 2`
- [ ] `OpenPlayIntent().perform()` routes when bridge configured; throws when override disabled
- [ ] `ResumeActiveMatchIntent` all three routing branches covered
- [ ] `FeatureFlagsTests` still pass (injected args)
- [ ] `IntentRoutingBridgeTests` still pass (`defer` reset overrides)
- [ ] `-disable_firebase_analytics` present on test scheme
- [ ] Release build does **not** include `-enable_app_intents`

## Risks & mitigations

| Risk | Mitigation |
|------|------------|
| Tests assuming flag off via `ProcessInfo` break | Audit `LocalFeatureFlagsProvider()` without `arguments:`; use explicit `[]` for off cases |
| `featureFlagOverrides` leak between tests | `defer { reset }` in every suite that sets overrides |
| XcodeGen regen drift | Change `project.yml`, run `xcodegen`, commit if tracked |
| Future default-on in Release | Keep launch-arg tests for explicit opt-in documentation |

## Later (optional)

- **AppIntentsTesting** for entity/query intents (spec §10 layer 2)
- Dedicated Xcode test plan with intents **off** for negative-path CI matrix
- UI smoke via `simctl openurl` resume deep link

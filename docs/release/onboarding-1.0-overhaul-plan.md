# Onboarding & Support Overhaul — 1.0.0

Phased plan to align first-launch onboarding with lean **1.0.0** (X01 + Cricket, 4 tabs, local-first) and close the support/feedback gap between web pages and in-app Settings.

**Status:** Implemented (Phases A–C)  
**Target:** `1.0.0`  
**Companions:** [`lean-1.0-implementation-plan.md`](lean-1.0-implementation-plan.md) · [`ongoing-release-plan.md`](ongoing-release-plan.md) · [`AppShellSpec.md`](../../specs/AppShellSpec.md) §6

---

## Goals

1. Set clear **1.0 expectations** — what ships today, what is coming later.
2. **Tour the app shell** — Play, Players, Activity, Settings before first match.
3. **Build trust** — local data, privacy, how to get help.
4. **Close the support loop** — Settings and onboarding share the same support story.
5. **Keep scope shippable** — polish the funnel; no in-app feedback forms.

---

## Proposed flow

```text
Welcome → Experience → Preferences (experienced) or Learn (beginner)
       → App tour → Support & feedback → Ready → Play tab

Welcome → Skip → Ready → Play tab
```

| Step | Experienced | Beginner |
|------|-------------|----------|
| 1 | Welcome | Welcome |
| 2 | Experience question | Experience question |
| 3 | Quick setup (prefs) | Learn (X01 + Cricket rules) |
| 4 | App tour | App tour |
| 5 | Support & feedback | Support & feedback |
| 6 | Ready — Start a Match | Ready — Start a Match |

---

## Phase A — Ship blockers (Settings + copy)

**Goal:** Users can reach support/privacy from Settings; version reflects the bundle; copy matches 1.0.

| Task | Files |
|------|-------|
| Add **Help & Feedback** section (Support, Send Feedback, Rate, Privacy) | `SettingsRootView.swift`, `L10n.swift`, `Localizable.strings` |
| Dynamic version from `CFBundleShortVersionString` | `AppSupport.swift`, `SettingsRootView.swift` |
| Shared mailto + review URL helpers | `AppSupport.swift`, `AppLinks.swift` |
| Update welcome / learn / ready copy for 1.0 | `Localizable.strings` |
| Rename legacy `settings.feedback` section label → “Sound & Haptics” | `Localizable.strings` |

**Rules gating:** `GameRulesCatalog.supportedMatchTypes` already respects `ProductSurface` — no code change required for lean 1.0.

**Exit criteria**

- [x] Settings rows open support, privacy, feedback mailto, and App Store review URL
- [x] Version row shows installed bundle version (e.g. `1.0.0`)
- [x] Welcome and ready copy mention 1.0 scope

---

## Phase B — Onboarding narrative

**Goal:** Six-step funnel with progress, back navigation, app tour, and support step.

| Task | Files |
|------|-------|
| Extend `OnboardingStep` (`appTour`, `support`) + progress/back helpers | `OnboardingStepChrome.swift` |
| Step progress + back in chrome | `OnboardingStepChrome.swift`, step views |
| New **App tour** step (4 tab cards + roadmap footnote) | `OnboardingAppTourStepView.swift` |
| New **Support & feedback** step | `OnboardingSupportStepView.swift` |
| Wire navigation in flow | `OnboardingFlowView.swift` |
| Skip from Welcome → Ready (not straight to Play) | `OnboardingFlowView.swift` |
| Ready CTA → **Start a Match** + replay hint | `OnboardingReadyStepView.swift` |

**Exit criteria**

- [x] Both paths traverse tour + support before Ready
- [x] Back works from step 2 onward
- [x] Step indicator shows “Step N of 6”
- [x] Skip lands on Ready; Get Started lands on Play tab

---

## Phase C — Tests, specs, polish

**Goal:** Regression coverage and small behavioral wins.

| Task | Files |
|------|-------|
| Update onboarding UI tests for new steps | `OnboardingUITests.swift` |
| Add Settings support-link UI test | `SettingsUITests.swift` |
| Unit tests for step back-navigation | `OnboardingStepTests.swift` |
| Persist X01 default for beginner path | `OnboardingFlowView.swift` |
| Update App Shell spec §6 | `specs/AppShellSpec.md` |

**Exit criteria**

- [x] UI tests pass for skip, beginner, experienced, and Settings replay
- [x] `savedExperience == .beginner` sets default match type to X01
- [x] Spec documents new flow

---

## Phase D — Post-1.0 (backlog)

Not in scope for initial implementation:

- `SKStoreReviewController.requestReview` after N completed matches
- Per-version “What’s New” sheet
- Illustrated onboarding art (beyond SF Symbols)
- In-app bug report share sheet with diagnostics
- Localize new strings when de/es/nl ship (1.2+)
- Marketing screenshots for tour + support steps

---

## Future messaging (release train)

| Version | Hint in tour/support copy |
|---------|---------------------------|
| **1.0** | X01, Cricket, players, activity, bots |
| **1.1** | Party modes (Baseball, Killer, Shanghai) |
| **1.2** | Training bots, export, more locales |
| **1.3+** | Modes tab, expanded catalog |

Do **not** show the 29-mode catalog or unreleased tabs in onboarding.

---

## Success criteria (1.0 done)

- [x] First-time user reaches Play in ≤ 8 taps (beginner) or ≤ 6 taps (experienced, excluding optional back)
- [x] Support, Privacy, and Feedback reachable from Settings **and** onboarding
- [x] Version in Settings matches bundle (`1.0.0`)
- [x] UI tests cover both paths through new finale
- [ ] Lean 1.0 QA item: cold launch → onboarding → land Play (manual device QA)

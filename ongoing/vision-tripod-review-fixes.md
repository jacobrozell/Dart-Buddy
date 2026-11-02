# Vision tripod review-lane fixes

**Goal:** Find ship-risk bugs in the tripod experiment. This does not unfreeze 1.2.  
**Repo:** `/Users/jrozell/Desktop/personal/apps/DartBuddy`  
**Branch:** `experiment/vision-tripod-test` vs `master`  
**Reviewed:** 2026-11-01  
**Status legend:** `[ ]` not started · `[~]` in progress · `[x]` done · `[>]` deferred

**Last updated:** 2026-11-01

The branch marketing version is 1.2.0. 1.2 stays frozen. The App Store vision flag stays off. Camera scoring on this branch is the experiment scheme only.

---

## Review bundle

Uncommitted tripod polish on top of checkpoint `07a3a17` (dim-room lock, visit tray, dismissed tally) is outside this bundle.

```
/var/folders/tr/5n87vlz57n1_1f_v75h710vm0000gr/T/personal-review/DartBuddy-experiment_vision-tripod-test..master
```

256 files · +24194 / −2535 vs `master`. Lanes: Bugbot, Tests, Security.

| Lane | Verdict | Ingested |
|------|---------|----------|
| Bugbot | **Block** as found — two highs. Loop pass ([#2](#2-loop-pass)) and Bob's 27 rounds ([#3](#3-bobs-27-rounds)). Follow-up [Bugbot](b5d79660-ce1f-4e61-a431-47b9d137a5d5) added the opening-target announcement ([#5](#5-loop-opening-flag)) and dropped one finding. Both passes read 51 of 257 files and skipped the vision sources. | [x] |
| Tests | **Pass with gaps** — DartBuddyTests 1,865/1,865 on iPhone 17 Pro, iOS 26.5, scheme `DartBuddyCI`, unsigned. Includes the 84 vision tests. UI suite not run ([#4](#4-ui-tests)). [Run test suite](97c1597a-fc93-4547-9755-83f2676662e2). | [x] |
| Security | **Ready with nits** — no camera upload, secret, or analytics PII issue. Do not archive this branch for the App Store ([#1](#1-internal-release-flag)). [Security Review](89f9cd4e-2618-45e8-ad6b-dbff19163dc0) read 51 of 257 files. | [x] |

---

## Lane status

| Lane | Verdict | Ingested |
|------|---------|----------|
| Bugbot | **Block** as found — two highs, plus a low on the Loop opening announcement (2026-11-01). | [x] |
| Security | **Ready with nits** — vision stays off without `-enable_vision_scoring` (2026-11-01). | [x] |
| Accessibility | | [ ] |
| Architecture | | [ ] |
| Code smells | | [ ] |
| Tests (runner) | **Pass with gaps** — 1,865/1,865. UI suite not run (2026-11-01). | [x] |
| Store policy | — (skipped: 1.2 frozen, not a submit) | [x] |
| Data integrity | | [ ] |

---

## Sprint order

| # | Item | Lane | Severity | Effort | Status |
|---|------|------|----------|--------|--------|
| 1 | [Do not archive this branch for the App Store](#1-internal-release-flag) | Security | Medium | S | [>] |
| 2 | [Loop pass never offered](#2-loop-pass) | Bugbot | High | S | [ ] |
| 3 | [Bob's 27 rounds stall after a bust](#3-bobs-27-rounds) | Bugbot | High | S | [ ] |
| 4 | [UI coverage for the camera button and the visit tally](#4-ui-tests) | Tests | Low | M | [>] |
| 5 | [Loop opening throw announces a match](#5-loop-opening-flag) | Bugbot | Low | S | [ ] |

---

## 1. Do not archive this branch for the App Store

**Lane:** Security · Medium only if this branch is archived · 2026-11-01 [Security Review](89f9cd4e-2618-45e8-ad6b-dbff19163dc0)

Release sets `DART_BUDDY_INTERNAL_BUILD`, which turns on the internal catalog, achievements, App Intents, and the visual dartboard. It does not turn on camera scoring. Camera frames stay on device. Analytics for vision stays on the allowlist (scores and counts, not names or frames).

**Location:** `project.yml:153-154`

**Deliverables:**
- [x] Leave the flag on this experiment branch
- [ ] Archive for the App Store only from a branch that omits `DART_BUDDY_INTERNAL_BUILD`

## 2. Loop pass never offered

**Lane:** Bugbot · High · 2026-11-01 [Bugbot](8bef7474-0b9f-42ca-9707-3f8c1e49cbb9)

`shouldOfferPassDecision` requires every active player, including the target setter, to be in `missedPlayerIdsSinceTargetSet`. The setter is cleared out of that list when they set or match the target, so the pass prompt never appears. Follow the Leader excludes the setter.

**Location:** `Domain/Engines/LoopEngine.swift:530-535`

**Deliverables:**
- [ ] Offer the pass once every other active player has missed, matching Follow the Leader

## 3. Bob's 27 rounds stall after a bust

**Lane:** Bugbot · High · 2026-11-01 [Bugbot](8bef7474-0b9f-42ca-9707-3f8c1e49cbb9)

`roundIndex` increments only when the next active player is index 0. After player 0 busts out, the remaining player is never index 0, so the match stays on the same double.

**Location:** `Domain/Engines/Bobs27Engine.swift:220-224`

**Deliverables:**
- [ ] Advance the round when the turn order wraps past the last active player, including when index 0 is already out

## 4. UI coverage for the camera button and the visit tally

**Lane:** Tests · Low · 2026-11-01 [Run test suite](97c1597a-fc93-4547-9755-83f2676662e2)

Unit tests cover four-tap lock, exact/changed/dismissed, takeout, and `visionAutoScoringDisabledByDefault`. Nothing checks that `vision_scoring_button` stays hidden when the flag is off, that the tally survives leaving the camera session, or that the tap guide works on screen. The UI suite was skipped because another `xcodebuild` held the simulators.

**Deliverables:**
- [ ] Run the UI suite when a simulator is free
- [ ] Assert the camera button stays hidden unless `-enable_vision_scoring` is set

## 5. Loop opening throw announces a match

**Lane:** Bugbot · Low · 2026-11-01 [Bugbot](b5d79660-ce1f-4e61-a431-47b9d137a5d5)

`submitVisit` sets `setOpeningTarget` and also sets `matched`, but the visit event leaves `setOpeningTarget` at its default `false`. VoiceOver then announces a target match on the opening throw. Follow the Leader passes the flag through.

**Location:** `Domain/Engines/LoopEngine.swift:446-456` · read by `Features/Play/Loop/LoopMatchViewModel.swift:457`

**Deliverables:**
- [ ] Pass `setOpeningTarget` on the visit event

## Out of scope

1.2 checklist, Duo, and turning the vision flag on for the App Store. The real-board session stays with the owner.

---

## Pending lanes

Bugbot, Tests, and Security are ingested (2026-11-01). A second Bugbot pass skipped the vision sources again, so no third pass was started. Accessibility, Architecture, Code smells, and Data integrity wait for a full run.

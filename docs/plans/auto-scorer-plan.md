# Auto Scorer Plan

**Status:** Not started · future R&D · do not pull into the 1.2 train  
**Created:** 2026-10-27  
**Goal:** Make single-phone scoring good enough that a mounted phone and a player who steps out of frame can finish an X01 match with corrections only on wires and tight clusters.

**Behavior spec:** [`specs/AutoScoringVisionSpec.md`](../../specs/AutoScoringVisionSpec.md) (Phase A is implemented behind `enableVisionAutoScoring`). This file is the execution roadmap. When a phase changes behavior, update the spec in the same change. Do not let this plan become a second spec.

**Context (2026-10-27):** DartCounter’s Auto Scorer is why people download that app and why a subscription feels justified. Players stay for online matches and saved stats. Matching their scorer does not move a league player off their lobby. Build this because hands-free scoring is worth having in Dart Buddy, and keep the flag off until the eval gates below are met.

Dedicated multi-camera rigs (Scolia, Autodarts) are a higher accuracy ceiling and a worse setup. This plan stays on one frontal phone camera.

---

## Agent query (copy-paste)

Use this prompt to begin the next session. Run **one phase**, then stop.

```
Continue the Dart Buddy auto scorer. Start at the first phase in
`docs/plans/auto-scorer-plan.md` whose exit criteria are not checked.

## Read first
- `docs/plans/auto-scorer-plan.md` (this plan — product rules and phase order)
- `specs/AutoScoringVisionSpec.md`
- `Domain/Vision/` (geometry, calibration, impact detector, session)
- `Features/Play/Vision/` (camera, frame analyzer, sheet, view model)
- `Tests/Unit/VisionScoringSessionTests.swift`

## Constraints
- Flag `enableVisionAutoScoring` stays off. Launch arg remains `-enable_vision_scoring`.
- X01 only. Match engine stays the source of truth. Vision only proposes commands.
- Score the sisal entry point. Map that point through calibration into `DartboardGeometry`. Do not add a segment classifier.
- `VisionScoringPolicy.assistive` keeps `autoCommitEnabled == false` until the Phase 5 eval gate is met on a real labeled set. Do not flip it in code “for later”.
- No network upload of frames or labels. No App Store copy, screenshots, or review notes that claim camera scoring.
- No Core ML model until Phase 1 has produced the label-count gate (2,000 impacts). Do not train on synthetic images and call it done.
- Do not start the next phase in the same session unless the current phase’s exit criteria are checked and unit tests are green.
- Do not commit unless asked.

## Exit
Check the boxes for the phase you finished, in this plan, and list anything you could not verify on a device.
```

---

## Product rules

| Rule | Detail |
|------|--------|
| **Tip, then geometry** | The scored point is where the point enters the sisal. Flights and barrels sit in front of the board and parallax onto the wrong segment. `ImpactDetector`’s luma centroid is a “something changed” gate, not a score. |
| **Wire calls confirm** | A dart within **2 mm** of a ring boundary or a wedge wire is always a confirmation, including after auto-commit exists. 2 mm is `2 / 170` in board-plane units (`DartboardGeometry` outer double radius = 170 mm). |
| **Fat beds may auto-commit later** | Only a point more than 2 mm from every boundary, above the confidence threshold, with the player out of frame. |
| **Corrections are the dataset** | Every accept, edit, and reject is a label. That flywheel is the gap with DartCounter, not the homography math. |
| **Honest failure** | Drift, darkness, blur, or a person in frame pauses or drops the proposal. A wrong silent score is worse than typing. |
| **One phone** | No second camera, no external rig requirement. |

---

## What already exists

| Piece | Where | Use it as |
|-------|--------|-----------|
| WDF ring radii and wedge wheel | `Domain/Vision/DartboardGeometry.swift` | The only segment mapper |
| Homography type; calibration is still circle-fit | `Domain/Vision/BoardCalibration.swift` (`PerspectiveTransform.circleFit`) | Phase 3 replaces the fit, not the type |
| Luma-grid change detector (64×64) | `Domain/Vision/ImpactDetector.swift` | Stability / arrival gate only |
| Assistive session, confirm, correct, reject | `Domain/Vision/VisionScoringSession.swift` | Keep. Policy tests live in `Tests/Unit/VisionScoringSessionTests.swift` |
| Contour circle fit + impact plumbing | `Features/Play/Vision/DartboardFrameAnalyzer.swift` | Board lock today; too coarse to call a treble |
| X01 sheet behind the flag | `Features/Play/X01/X01MatchScreen.swift`, `Features/Play/Vision/` | Stay X01-only |

Treble and double bands are each 8 mm wide (`99…107` mm and `162…170` mm). At a typical framed board the sensor has enough pixels. The error is localizing the flight instead of the tip, and a circle fit that ignores perspective.

---

## How a bot iterates

A bot can only keep a change when a command prints a number it did not invent. The iOS Simulator has no dartboard camera, so the loop calls `Domain/Vision` and `DartboardFrameAnalyzer` on fixtures. It does not launch the app and look at the preview.

Do this inside one agent session. A timer or a scheduled automation that “keeps improving vision” is the wrong shape: it will chase whatever score is easy to raise.

### Loop A — geometry fuzz (Phase 0, no images)

After the hand-written wire tests exist, add a property test that draws board-plane points and checks invariants of `DartboardGeometry`. The expected value comes from the invariant, not from a second call to the function under test.

- A point on a ring boundary has ring distance 0.
- Rotating a non-bull point by 18° changes the segment number by exactly one step on `segmentWheel`, and the ring stays the same.
- Crossing `tripleOuter` at a fixed angle changes triple to single and nothing else.
- `requiresConfirm` is true for every point within 2 mm of a boundary and false for a point in the middle of a single bed.

The bot runs the vision unit tests, fixes the geometry when an invariant fails, and stops when they pass. Three green runs in a row with new random seeds ends the loop. It does not move on to a model.

### Loop B — still-image scoreboard (Phases 2–5)

Independent ground truth is a tip pixel plus the segment a human scored. The analyzer must not be the source of the expected segment.

Layout, checked in only when someone has actually labeled them:

```
Tests/Fixtures/Vision/<id>.jpg
Tests/Fixtures/Vision/<id>.json   # imageX, imageY, segment, multiplier, board id, lighting
```

One test loads every pair, runs calibration and the tip localizer, and prints a scoreboard:

| Gate | Keep a change only if |
|------|------------------------|
| Wire slice (label within 2 mm of a boundary) | 0 auto-commits. This gate never trades off. |
| Fat-bed slice (label more than 4 mm from every wire) | Segment-exact does not drop |
| Tip error | Mean distance from prediction to labeled tip does not rise |

The bot changes the localizer, re-runs the scoreboard, and reverts the patch when any gate fails. It stops after three tries that do not improve tip error while holding the other gates. Then it writes one line in the Eval log and waits for harder photos. Adding those photos is a person at a board, not the bot.

Synthetic renders may sit in the fixture folder as a regression set for homography. They do not count toward the 200-throw Phase 5 gate or the 2,000-label model gate.

---

## Phase order

```
Phase 0  wire-confirm policy (domain, no camera)
Phase 1  on-device label capture
Phase 2  frozen-frame tip tap (the localizer until a model exists)
Phase 3  board pose beyond circle-fit
Phase 4  visit grouping
Phase 5  measured auto-commit  ← spec Phase B
```

Spec Phase C (signed online verification) is out of scope.

### Phase 0 — Wire-confirm policy

Domain only. No camera, no UI.

1. Add a pure function on `DartboardGeometry` (or a sibling type in `Domain/Vision/`) that, for a `BoardPoint`, returns the board-plane distance to the nearest ring boundary and the nearest wedge wire.
2. Ring boundaries: `innerBull`, `outerBull`, `tripleInner`, `tripleOuter`, `doubleInner`, `doubleOuter`. Points inside the outer bull have no wedge wire (the bull is a circle). Points outside `doubleOuter` still measure distance to that edge (double vs miss).
3. Wedge distance is the perpendicular distance at the point’s radius to the nearest 18° boundary, in the same board-plane units.
4. `func requiresConfirm(_ point: BoardPoint) -> Bool` is true when either distance is ≤ `2 / 170`.
5. Do not call it from `VisionScoringSession` yet, and do not enable auto-commit. Phase 5 is the caller. Shipping the predicate now keeps the rule unit-tested before any model exists.
6. Add the 2 mm rule to `AutoScoringVisionSpec.md` §8 in the same change.

**Tests** (Swift Testing, `.tags(.unit, .vision)`):

- Center of the treble-20 bed (radius ~103 mm, angle 0) does not require confirm.
- 1 mm inside the treble-20 / single-20 boundary requires confirm.
- 1 mm off the 20/1 wedge wire at treble radius requires confirm.
- Bull center does not require confirm. 1 mm off the inner-bull edge does.
- 1 mm outside the double ring requires confirm.

**Exit**

- [ ] Predicate and tests exist
- [ ] Spec §8 mentions the 2 mm confirm zone
- [ ] `autoCommitEnabled` still defaults to false
- [ ] Unit tests green

### Phase 1 — Label capture

Persist corrections locally so later phases have something to train and to eval. No uploader.

Append-only JSONL under Application Support, written only while vision scoring is enabled. Do not put frames or labels in the match event store.

Each line:

| Field | Source |
|-------|--------|
| `visionSessionId`, `frameTimestamp` | Existing `DetectedThrow` |
| `imageX`, `imageY` | `DetectThrowCommand` |
| `calibration` | `BoardCalibration` at propose time |
| `proposedDart` | Mapped dart |
| `correctedDart` | `ConfirmDetectedThrowCommand.correctedDart`, or null when the user accepted the proposal |
| `rejected` | true on `RejectDetectedThrowCommand` |

Hook the write in the vision view model where confirm and reject already run (`VisionScoringViewModel`), not in the match engine.

**Exit**

- [ ] A confirmed, corrected, and rejected throw each append one record
- [ ] Records stay on device
- [ ] Unit test covers the record encoding without a camera
- [ ] Spec §7 notes the local label log

### Phase 2 — Frozen-frame tip tap

The centroid is the wrong point. Until a model exists, the user is the tip localizer, and every tap is a Phase 1 label.

1. On a stable impact, freeze the analyzed frame.
2. Show the proposed point. Dragging it updates `imageX`/`imageY` and re-runs calibration → `DartboardGeometry` live.
3. Confirm stores the **final** point as the label’s image point (the tap), and the pre-drag point as the proposal.
4. `ImpactDetector` still decides that a dart arrived and that the scene is still. It does not decide the segment.

**Exit**

- [ ] Dragging across a ring boundary changes the proposed segment
- [ ] Saved label uses the released point
- [ ] Flag still required to open the sheet

Device check: one real board, one dart in a fat single, one dart on a wire. Record whether the drag is understandable. Do not claim accuracy beyond that session.

### Phase 3 — Board pose

`PerspectiveTransform` can hold a full homography. Calibration currently builds a similarity from a circle and a rotation (`circleFit`). A phone below the board turns the double ring into an ellipse and rotates wedges.

1. Estimate a homography from the outer double wire (contour samples) plus the bull as the origin, with the 20 wedge up.
2. Keep circle-fit as the fallback when the contour is too sparse, and surface that in fit quality so a poor pose cannot look “locked”.
3. Re-check during play. Existing drift pause (`BoardCalibration.hasDrifted`) stays the failure path.

**Exit**

- [ ] A unit test with a known perspective maps a synthetic treble-20 point back to treble 20
- [ ] Circle-fit fallback still locks on a frontal circle
- [ ] Spec §5 lists homography as the preferred calibration output

### Phase 4 — Visit grouping

Steel tip is three darts, then a hand clears the board.

1. After three accepted impacts, ignore further impacts until a large scene change resets the baseline (the detector already treats a big luma change as “not a dart”).
2. A third dart whose changed region overlaps an earlier dart in the same visit always `requiresConfirm`, even in a fat bed. Overlap is the cluster case a single camera cannot see through.
3. Removing darts must not score negative impacts.

**Exit**

- [ ] Session tests: fourth detection in a visit is ignored until reset
- [ ] Overlapping third dart is marked requires-confirm
- [ ] A full-frame change resets the visit

### Phase 5 — Measured auto-commit (spec Phase B)

Do not start this phase because the policy flag exists. Start it when a **held-out** label set exists with all of:

- at least 200 throws
- more than one physical board
- more than one lighting setup
- labels from Phase 1 / Phase 2 (human tip points), not synthetic renders

Gates, all required:

| Slice | Gate |
|-------|------|
| True point **more than 4 mm** from every wire | ≥ 98% segment-exact (number and ring) |
| True point **within 2 mm** of a wire | 100% routed to confirm, zero auto-commits |
| Player in frame, dark, or drifted calibration | zero auto-commits |

Wire the Phase 0 predicate into `VisionScoringSession.handle` so a point that `requiresConfirm` can never take the `autoCommitted` path, regardless of confidence. Keep `VisionScoringPolicy.assistive` as the shipping default. A separate policy value, used only in a test or a debug override, may enable auto-commit after the gates pass.

**Exit**

- [ ] Session test: high confidence on a wire point still proposes
- [ ] Session test: high confidence on a fat-bed point auto-commits only when the policy allows it
- [ ] Eval notes (counts, not a model binary) checked into this plan under a “Eval log” heading
- [ ] Spec Phase B checkbox updated to match what actually shipped

There is no Core ML step in this phase unless the label-count gate below is already met and a model’s tip error is what is being measured. A model that classifies segments directly is out of spec.

---

## Model gate (only after Phase 1)

Do not add a Core ML target, and do not train, until the JSONL log contains at least **2,000** labeled impacts across more than one board and more than one room. The model’s only output is an image-space tip point. `DartboardGeometry` remains the segment function.

If the log is short of that, stop. Collecting labels is the work.

---

## Out of scope

- Spec Phase C, anti-cheat, and online match verification
- A second camera or a required mount SKU
- Android (`DartBuddy-Android`)
- Game modes other than X01
- Turning the feature flag on by default
- Store listing, screenshots, or release notes that mention camera scoring
- Replacing manual scoring, or treating auto score as the reason someone would leave DartCounter

---

## Eval log

_Empty until Phase 5. Append dated rows: set size, boards, lighting, segment-exact on the >4 mm slice, confirm-rate on the ≤2 mm slice. Do not paste frames or personal data._

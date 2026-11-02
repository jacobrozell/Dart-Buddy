# Camera Scoring — Usability and Accuracy Plan

Make camera scoring something a player can set up once and then throw against from the oche without walking back to the phone.

**Status:** In progress. Phase 4 first pass and Phase 3 wire-crossing points are on the branch (2026-10-30), awaiting device testing. See §7 for the pipeline map and alternate paths.
**Branch:** `experiment/vision-tripod-test` (flag stays off)
**Companion:** [`specs/AutoScoringVisionSpec.md`](../../specs/AutoScoringVisionSpec.md) · [`Features/Play/Vision/`](../../Features/Play/Vision/) · [`Domain/Vision/`](../../Domain/Vision/)

---

## 1. Problems from the first device sessions (2026-10-30)

| Problem | Cause |
|---------|-------|
| Proposals with no throw | Static baseline drifted with exposure; scattered and off-board changes counted. **Fixed on branch** (rolling baseline, exposure/focus/white-balance lock, board-region mask, compact-cluster gate). Re-test pending. |
| Calibration taps landed on the triple ring | One-line instruction, no picture, and the old points (middle of a segment) had no visual landmark. **Partly fixed** (example board, caption, wire-crossing points). Still blind tapping on a small preview. |
| 5 → 13, 5 → 18, T18 → 0, 20s → 1/T18 | Score came from the centroid of the change, which is the flight, not the tip. **First pass on branch** (Phase 4). |
| Walking back to dismiss | One proposal at a time; darts thrown while it's pending are ignored. Review has to happen at the phone after every dart. |

---

## 1b. Prior art (researched 2026-10-30)

| Project | How it finds the dart | Calibration | License (can we reuse?) |
|---------|----------------------|-------------|-------------------------|
| [DeepDarts](https://github.com/wmcnally/deep-darts) (CVSports 2021) | YOLOv4-tiny detects each dart **tip** as a keypoint | Same model detects 4 points on the outer double wire at wire crossings (5/20, 13/6, 17/3, 8/11) | Code: no license (ideas only). **Dataset: CC-BY** on IEEE DataPort, 16k labeled images; trainable with attribution |
| [DartSense](https://github.com/bnww/dart-sense) | YOLOv8n tip + calibration keypoints on phone video | Auto (model) with manual override | Non-commercial, non-distributable. Ideas only |
| Autodarts (commercial, documented) | Low-res motion diff finds the change, then **full-resolution ROI**, fits a line to the barrel, infers the tip | 4 points, auto or dragged on the camera image | Closed. Ideas only |
| [LarsG21/Darts_Project](https://github.com/LarsG21/Darts_Project) | Reference diff, contour, fit a **triangle**, tip = corner opposite the shortest side | ArUco + circle fit | No license. Ideas only |
| [opencv-steel-darts](https://github.com/hanneshoettinger/opencv-steel-darts), [OpenDartboard](https://github.com/OpenDartboard/OpenDartboard) | Diff + corner features; waits ~0.2 s for vibration before diffing | Ellipse + segment lines | GPL-3.0. Ideas only |

Reported accuracy: DeepDarts 94.7% visits correct face-on, 84% multi-angle. DartSense 88% per image.

**Where we differ (and why it scores the flight):**
1. We diff a **64×64 thumbnail** of the whole frame (each cell ≈ 20×11 px). Everyone else localizes at full resolution.
2. We score the **blob center**. Others find the **tip**: keypoint model, barrel line fit, or triangle corner.
3. Our calibration asks for the **middle of a segment** on the outer wire, which has no visual landmark. Others use **wire crossings**, or detect the points automatically.
4. We handle one dart at a time. DartSense keeps up to 3 darts per visit, commits a dart once it's seen in 3 of the last 5 frames, and ends the visit when the board reads empty (takeout). Same shape as our Phase 2.

**ML caveat:** Ultralytics YOLO is AGPL-3.0, including trained weights, unless you buy an enterprise license. To ship a model, train an Apache/MIT architecture or Create ML on the CC-BY DeepDarts data plus our captures, then export to Core ML.

---

## 2. Target experience

1. **Place the phone.** A setup screen shows where to mount it and checks the picture live: board fills enough of the frame, angle is acceptable.
2. **Line up the board.** Drag four handles onto the outer double wire (they start roughly in place). A full ring-and-wedge overlay draws on the camera image as you drag, so a wrong ring is obvious before you lock.
3. **Throw a visit.** From the oche the screen reads clearly: big "Ready" state, each dart appears in a 3-slot tray with a marker on the image where it landed, plus a short sound.
4. **Walk up, review once.** Pulling darts (large motion) ends the visit. At the board, the player checks the three slots, taps any to fix, and submits the visit in one tap. Missed detections are added from the same tray.

---

## 3. Phases

### Phase 1 — Capture what the detector sees (enables tuning)

Every later phase needs real frames to tune against instead of guessing.

- Debug builds only: on each detection, save baseline grid, arrival grid, changed-cell mask, chosen point, calibration, and the user's final answer (exact / changed / dismissed / added) to `Documents/vision-captures/`.
- Pull with `xcrun devicectl device copy from …` and replay offline.
- Add a replay test target that loads captured fixtures and asserts the scored dart, so detector changes are measured against real throws.
- Log tip/centroid positions and cluster size in `vision_throw_detected`.

**Done when:** one 30-dart session produces fixtures that replay in a unit test.

### Phase 2 — Visit tray (fixes walking back) — **Done** (2026-03-29)

Visit submit is **manual** ("Submit visit"); no auto-submit after takeout.

Domain (`VisionScoringSession`):
- Replace `pendingProposal` with `pendingVisit: [DetectedThrow]`, capped at the darts left in the visit (match passes `dartsRemainingInVisit`; a bust or checkout ends it early).
- New commands: `EditVisitDart(index, dart)`, `RemoveVisitDart(index)`, `AddMissedDart(dart)`, `SubmitVisit`.
- Large-motion event after ≥1 dart marks the visit `readyForReview`; detections stop until submit.
- Tally gains `missed` (darts the player added by hand).

UI (`VisionScoringSheet`):
- Three slots under the preview; each shows score, confidence tint, and a matching numbered marker on the camera image.
- States readable from 2.4 m: **Ready — throw**, **Dart 2 of 3**, **Pull your darts**, **Review visit**, **Paused**.
- Optional detection chime (respects existing sound settings).
- "Submit visit" sends the darts through `onDartConfirmed` in order.

**Done when:** a full 3-dart visit is thrown, reviewed, and submitted with one trip to the phone.

### Phase 3 — Setup and calibration

- **Placement step** before calibration with an illustration: phone on a stand, as square-on to the board as the room allows, board filling at least ~40% of the frame width. Use `videoZoomFactor` if the board is small.
- **Live placement check:** from the board contour (or the locked homography), estimate board size in frame and viewing angle (ellipse axis ratio). Show Good / Move closer / Too angled.
- ~~**Wire-crossing points**~~ **Done:** taps are now where the 5|20, 13|6, 17|3, and 8|11 wires meet the outer double wire (the DeepDarts points). A crossing is a visible corner; the middle of a segment is not.
- **Draggable handles** instead of blind taps, seeded from the contour fit when available, with a magnifier loupe while dragging.
- **Overlay preview:** draw rings and wedge lines through the current homography; "Looks right" locks. Replaces the tap-order instructions.
- **Saved setup:** remember the last calibration; on reopen, check drift and offer "Use last setup".

**Done when:** a first-time user locks a correct calibration without instructions beyond the screen, and the overlay visibly matches the board.

### Phase 4 — Score the tip, not the dart (Autodarts-style, no ML)

**First pass on branch:**
- **Two resolutions:** the 64×64 grid only detects arrival. The analyzer keeps a full-resolution luma copy of the detector's baseline frame; on arrival it diffs that against the settled frame inside the changed region (ROI), widened to include the expected tip.
- **Dart pixels:** threshold, keep the largest 8-connected blob.
- **Tip:** fit the blob's principal axis. If the blob is a line spanning most of a dart, the tip is the end in the camera-pose flight-to-tip direction (or the narrow end without a pose). If it's compact or short (flight only), step one expected dart length from its center.

**Still to do:**
- Wait ~0.2 s after arrival for board vibration (currently 3 still frames ≈ 0.1 s).
- Light blur before thresholding; tune `pixelChangeThreshold` against Phase 1 captures.
- Confidence from tip certainty (line fit quality, end-width ratio), not coarse cluster size.

**Done when:** Phase 1 fixtures show a clear exact-rate gain over centroid scoring, e.g. ≥80% exact on segment.

### Phase 5 (optional) — Model path

- Train a tip + calibration keypoint model on DeepDarts (CC-BY) plus Phase 1 captures; permissive architecture, Core ML export.
- Gives auto-calibration (no taps) and works without a clean reference frame.

---

## 4. Order and sizing

| Phase | Size | Why this order |
|-------|------|----------------|
| 1 Capture | S | Every tuning decision after this uses real data |
| 2 Visit tray | M | Biggest daily-use pain; independent of accuracy |
| 3 Setup + calibration | M | Removes setup errors that make accuracy look worse than it is |
| 4 Tip scoring | M | Main accuracy gain; needs Phase 1 fixtures to tune |
| 5 Model | L | Only if Phase 4 plateaus; needs training infra |

Phases 2 and 3 can run in parallel after Phase 1.

---

## 5. Open questions

1. Where does the phone live in your room: beside the oche, on the floor below the board, or off to one side near the board? This decides the default placement illustration and zoom.
2. ~~Should high-confidence visits ever auto-submit~~ **Resolved:** manual "Submit visit" only on this branch (2026-03-29).
3. Spoken score on detection (reuse the caller voice) or chime only?

---

## 6. Out of scope

- Multi-camera setups.
- Online-play verification (spec Phase C).

---

## 7. For future agents

### Pipeline today (per camera frame, capture queue)

| Step | Where | What it does |
|------|-------|--------------|
| Capture | `VisionCameraService` | 1280×720 420f, back wide camera. Exposure, focus, and white balance **lock** once calibration locks. |
| Coarse grid | `DartboardFrameAnalyzer.lumaGrid` | 64×64 luma grid, each cell averages 4×4 samples. |
| Arrival | `ImpactDetector` | Rolling baseline (absorbs drift), board-region mask, compact-cluster gate, 3-frame persistence, large motion resets. Reports cluster bounds plus a coarse tip. |
| Fine tip | `DartTipLocator` | Full-res diff in ROI, largest blob, principal axis, tip end. Falls back to the coarse point when it returns `nil`. |
| Pose | `BoardCalibration.dartTipOffset` | Board pose from the 4-tap homography + `videoFieldOfView`; gives the image vector flight center → tip (assumes 0.7 board radii ≈ 120 mm). Logged as `tip_offset` on `vision_calibration_locked`. |
| Scoring | `VisionScoringSession` / `BoardCalibration.dartInput` | Homography to board plane; outside the double ring up to 2.5 radii scores a miss, beyond that is ignored. |

Coordinates: grid and detector use per-axis normalized units; calibration and impacts use **width units** (x 0…1, y 0…height/width). The buffer is landscape; taps convert via `captureDevicePointConverted`.

### Edge cases

Handled:
- **Surround or floor miss:** detection zone is 2.5 board radii (`maxDetectionRadius`); anything outside the double ring scores a miss.
- **Dart settles or droops after impact:** a second report within 1 s and about 14 mm of a tray dart is ignored (`.duplicate`).
- **Takeout vs. a passing shadow:** `TakeoutDetector` needs 10 moving frames in about 1 s, and only arms after a dart lands, so walking back after "Keep throwing" doesn't close the visit.
- **Turn changes with the sheet open:** the X01 turn key (set, leg, turn, player) changes, and the tray is cleared.
- **Checkout or bust mid-visit:** collection stops when the match says the visit is over; "Keep throwing" is blocked; extra darts are trimmed on submit.
- **Every dart missed the camera:** "Done throwing" works on an empty tray, then "Submit visit" sends misses.

Not handled yet:
- **Bounce-out with nothing left in frame:** no persistent change, so no detection. Use "Add dart" or submit with misses. A dart that lands on the floor inside the zone does score a miss.
- **Robin Hood or stacked darts:** one blob; fix in the tray.
- **Black darts on black beds:** below the change threshold; see the alternate paths below.
- **App backgrounded mid-visit:** the scene change on return reads as motion; recalibrate if the phone moved.

### Tuning knobs (tune with captures, not guesses)

`ImpactDetector.Configuration` (`cellChangeThreshold` 0.1, `maxClusterSpread` 0.15, `persistenceFramesRequired` 3), `DartTipLocator.Configuration` (`pixelChangeThreshold` 28, `minimumElongation` 2, `wholeDartSpanFraction` 0.6), `BoardCalibration.dartTipToFlightLength` 0.7, `maxImpactRadius` 1.5.

### Alternate paths if this stalls

| If… | Try | Notes |
|-----|-----|-------|
| Tip still off by a segment after Phase 4 tuning | Triangle fit (LarsG21): tip = corner opposite the shortest side, nudged inward | Better than PCA when the flight is seen edge-on |
| Thin or dark barrels never register | Lower `pixelChangeThreshold` inside the ROI only; diff on chroma too (colored flights/shafts); higher capture resolution (1920×1080) for the ROI | Autodarts notes black darts on black segments fail; contrast matters |
| Camera can only sit head-on | Pose offset → 0, tip ≈ flight center; accept lower accuracy or move camera off-axis ~30–45° | DeepDarts still got 94.7% face-on, but with a model, not diffing |
| Calibration taps remain the main error | Auto-detect the 4 crossings (ellipse + wire-line fit like opencv-steel-darts, or a keypoint model) and let the user drag-correct | Overlay preview makes errors visible either way |
| Heuristics plateau below ~80% exact | Phase 5 model on DeepDarts (CC-BY) + own captures | Avoid Ultralytics (AGPL incl. weights) unless licensed; Create ML or an Apache/MIT detector → Core ML |
| One camera can't resolve occluded/stacked darts | Out of scope; that's why Autodarts uses 3 cameras | Fall back to manual edit in the visit tray |

# Camera auto-scoring: how it works

Reference for the camera scoring pipeline in X01: what each stage does, which
strategy it uses, what else was considered, and which numbers to tune.

**Spec and device test plan:** [`specs/AutoScoringVisionSpec.md`](../specs/AutoScoringVisionSpec.md) §12–13
**Domain logic (pure Swift, unit-tested):** `Domain/Vision/`
**Camera and UI:** `Features/Play/Vision/`
**Feature flag:** `enableVisionAutoScoring`, on in Debug builds, `-enable_vision_scoring` elsewhere
**Tests:** `Tests/Unit/BoardDetectorTests.swift`, `ImpactDetectorTests.swift`, `BoardCalibrationTests.swift`, `VisionScoringSessionTests.swift`

No ML model and no third-party code. Everything is classical image processing on
camera frames, so it runs on any iPhone and every step can be checked in a unit test.

---

## The pipeline at a glance

```
Camera (720p, 4:2:0)                        VisionCameraService
   │  frames rotated upright for the current interface orientation
   ▼
DartboardFrameAnalyzer  (capture queue, never main thread)
   │
   ├─ SEARCHING (every 5th frame) ──► BoardDetector ──► BoardDetection
   │                                                        │ 4 consistent hits
   │                                                        ▼
   │                                               BoardCalibration (homography + pose)
   │                                                        │ lock exposure/focus/WB
   │                                                        ▼
   └─ TRACKING (every frame) ──► ImpactDetector ──► .dart(tip) / .boardCleared
        └─ every 30th frame ──► BoardDetector.agreement (drift check)
   ▼
VisionScoringViewModel (main actor)
   │  DetectThrowCommand ──► VisionScoringSession + VisionScoringPolicy
   ▼
X01MatchScreen: append dart / submit visit when the board is cleared
```

Coordinates: everything in the image is in **width units**, where x runs `0…1`
across the upright frame and y runs down at the same scale (`0…height/width`), so
distances are the same in both directions. The board plane uses **board units**:
the bull is the origin, y points up towards the 20, and `1.0` is the outer edge of
the double ring (170 mm).

---

## Stage 1: find the board (`BoardDetector`)

**Goal:** turn one frame into the four image points where the outer double wire
crosses the middle of the 20, 6, 3 and 11 wedges (`BoardControlPoints`). Four
points fix a perspective homography, so this works with the camera at an angle.

**Strategy: colour, not edges.** The red and green beds are the most distinctive
thing on a board and survive dim light, blur and clutter much better than wire
edges do.

1. **Classify pixels** as red, green or neither (`ringColor`). Thresholds sit on
   saturation and hue, not brightness, so dim rooms and warm or cool lighting
   still work. Sisal, the black beds and typical flight colours classify as neither.
2. **Find the ring blob.** Dilate the mask, label connected components and try the
   three largest. The double ring is one big annulus.
3. **Trace its outer edge.** Take the farthest ring pixel in each of 180
   directions, then refine each to sub-pixel precision from how quickly colour
   fades into the dark surround. This refinement roughly halved landmark error.
4. **Fit an ellipse** (`EllipseFit`): algebraic least squares, then drop points far
   from the fit and refit, up to five times. Darts, hands and the number ring
   crossing the edge get discarded as outliers. At least 60% of points must agree.
5. **Find the bull**: the red/green centroid near the middle of the ellipse,
   refined once. Under perspective the bull is *not* at the ellipse centre, and it
   is the true image of the board centre. If no bull is found the ellipse centre
   is used as a fallback (slightly off at steep angles).
6. **Ellipse + centre → homography** (pole–polar construction). A chord through
   the centre's image is the image of a diameter. The tangents at its ends meet at
   the *pole* of that chord, and the line from the centre to the pole is the image
   of the perpendicular diameter. That gives four board points (up, right, down,
   left) for an unknown spin.
7. **Resolve the spin** from colour. Sample the double and treble rings every
   half degree (+1 red, −1 green) and correlate with a red/green square wave of
   18° wedges. The best phase, with its peak interpolated between samples, lines
   the wedges up. The **20 is taken to be the red wedge nearest the top of the
   image**, which holds for any board hung the normal way up.

The correlation score (`agreement`, `0…1`) doubles as the calibration's quality
measure and, later, as the drift check.

**Locking.** The view model needs **4 detections in a row** whose landmarks move
less than `0.012` width units between them, an agreement of at least `0.6`, and a
board radius between `0.10` and `0.60` width units. It averages those detections
into the final calibration, then locks camera exposure, focus and white balance so
the image only changes when the scene does.

**Manual fallback: Adjust.** If auto-detection fails or picks the wrong 20, the
player drags four handles onto the outer wire at 20, 6, 3 and 11 and can rotate
the numbering a wedge at a time. Hand-placed calibrations are trusted as-is.

### Alternatives considered

| Approach | Why not (for now) |
|---|---|
| Circle fit to a contour (the previous implementation) | Only correct head-on; the board is an ellipse from any real camera position, so segments drift off by several mm. |
| Wire/edge detection with Hough lines | Thin wires vanish at 720p and under motion blur; spider wires and numbers create many false lines. Colour is far more robust. |
| Ask the user to tap four points every time | Slow and fiddly. Kept as the **Adjust** fallback instead. |
| ML keypoint model | Needs a labelled dataset and a Core ML model to maintain. The geometric approach already lands within about 1% of the radius on synthetic views; worth revisiting only if real-world footage shows the colour approach failing often. |

---

## Stage 2: camera pose (`BoardPose`)

The homography only describes the board *face*. A dart sticks out of the face
towards the thrower, so which way a dart leans in the image depends on where the
camera is. `BoardPose` decomposes the homography into a camera rotation and
translation, assuming square pixels and a centred principal point.

- **Focal length** comes from the homography's orthogonality constraints when the
  camera is tilted enough for them to be well-conditioned.
- **Near head-on** those constraints degenerate, so it falls back to a typical
  iPhone wide lens (62° along the long side). The exact value barely matters there.
- `project(x:y:height:)` answers "where in the image is the point 0.85 board
  radii out of the face above this tip?" That is where the flight should appear.
- `tiltDegrees` drives the **angle the camera** hint when the camera is under 12°
  off-axis.

---

## Stage 3: detect darts (`ImpactDetector`)

**Goal:** report each new dart's tip in image coordinates, once, and notice when
the board is cleared.

**Strategy: background subtraction against the board as it was before the throw.**

The analyzer resamples the board region (a square 1.45× the board radius, box
filtered so thin dart parts are not skipped) to a **320×320 luma/chroma grid**,
about 1.5 mm of board per cell. Each frame goes through this state machine:

1. **Wait for stillness.** A frame is "still" when fewer than 0.3% of sampled
   pixels changed by more than `0.07` since the last frame. After 8 still frames
   the empty-board **reference** is captured.
2. **Settle, then evaluate.** After any movement (a dart arriving, a hand) the
   detector waits 4 still frames, then compares against the reference, and
   re-checks every 8 frames while still.
3. **Difference** = |Δluma| + |ΔCb| + |ΔCr|, with:
   - global **exposure compensation** (frame mean / reference mean, clamped to 0.7–1.4);
   - **shadow attenuation**: a darkening without a colour shift counts half.
4. **Group changes with hysteresis.** Pixels over `0.07` can join a blob; a blob
   only counts if it holds at least 6 pixels over `0.16`. The faint steel point
   stays attached to the obvious barrel and flight.
5. **Reject non-darts:**
   - over 30% of the region changed → the scene changed (lights, camera bump,
     someone standing in view). Ignored; if it persists for 60 still frames the
     reference is rebuilt so the detector does not stay blind;
   - blob over 4% of the region, or over 1.5% and touching the region's edge →
     an arm or body, not a dart;
   - tip maps more than 1.45 board radii from the centre → not on the board;
   - blob touching the region's edge with its tip outside the number ring → something poking in.
6. **Find the tip** (see below), report `.dart`, and **absorb the dart into the
   reference**. The next dart is then isolated on its own, even if it lands
   touching the first.
7. **Takeout.** While darts are in the board, the frame is also compared with the
   *empty-board* reference. When nothing differs from it, `.boardCleared` fires.
   A blob that looks like the empty board means a single dart was pulled or fell
   out: the reference is updated and nothing is scored.
8. **Slow drift.** When nothing dart-like is in view, references blend 15% towards
   the current frame to follow gradual lighting change.

### Tip strategies: which end of the blob is the point?

A dart blob is long and thin; the tip is one end of its principal axis. The ends
are found from the blob's second moments, pulled in by up to 0.75 px for blur, and
each end's lateral position is averaged so the tip sits on the dart's centreline.
Choosing **which** end is the hard part. Several cues are combined, strongest first:

| # | Strategy | Idea | When it is used | Confidence |
|---|---|---|---|---|
| 1 | **Pose prior** | Project 0.85 board radii out of the face from each candidate end. The real tip's projection points along the blob towards the other end. | Pose available, predicted flight offset is at least 30% of the blob length and 8% of the board radius, and the best alignment (cosine) ≥ 0.75 | 0.92; 0.7 if shape disagrees; capped at 0.6 for stubby blobs (elongation < 1.6) |
| 2 | **Mass asymmetry** | The flight is the bulk of the silhouette, so the centroid sits towards it. | End-to-centroid distances differ by ≥ 10% of the length | 0.5–0.8; capped at 0.55 if pose weakly disagrees |
| 3 | **Width** | The flight end is wider than the point. | Elongated blob and widths differ by ≥ 25% | 0.5–0.8 |
| 4 | **End caps** | Count pixels in the last sliver of each end: a point ends in a few, a flight in many. Works for short, compact blobs where 2 and 3 are weak. | Caps differ by ≥ 40% | 0.5–0.8 |
| 5 | **Weak pose** | Pose has an opinion but the blob does not point the way it predicts. | Pose available, no decisive shape cue | 0.5 |
| 6 | **Centroid** | Looking straight down the dart, the flight hides the tip; the middle is the least-bad guess. | Nothing else applies | 0.45 |

Cues 2–4 together are the "shape" vote. With the camera off to one side, the pose
prior settles almost every dart; with a head-on camera, shape carries it and
confidence drops, which is why the app asks for an angled camera.

On synthetic scenes the tip lands within about **0.5–1.5 mm** when the camera is
20°–45° off-axis, and within about 1–4 mm head-on.

### Alternatives considered

| Approach | Why not (for now) |
|---|---|
| Centroid of changed cells (the previous implementation) | Reports the middle of the dart, often 30+ mm from the tip and in the wrong segment. |
| Tap to confirm every dart | Accurate but not "auto". Kept as the `assistive` policy. |
| Frame-to-frame differencing only | Misses darts that land during motion and cannot tell a throw from a pull. The two-reference approach handles both. |
| Two or three cameras with triangulation (as commercial systems do) | Most accurate, but needs extra hardware. The single-camera pose prior gets most of the benefit. |
| ML tip detector | Promising for occlusion and odd lighting, but needs training data. The `ImpactDetector` interface (`Impact` with `tip`, `tail`, `confidence`) is shaped so a model could replace the tip step alone. |

---

## Stage 4: scoring policy (`VisionScoringSession`, `VisionScoringPolicy`)

The match engine stays the source of truth: vision only proposes darts.
`VisionScoringSession` maps each tip through the calibration to a segment and
applies a policy.

| Policy | Behaviour | Used by |
|---|---|---|
| `assistive` | Every detection becomes a pending proposal; nothing scores until confirmed. | Available, not wired to the UI now |
| `automatic` | Every detection scores immediately. Below `0.7` confidence it is still scored but flagged `needsReview` (orange outline in the visit bar). Below `0.3` it is dropped. | X01 camera sheet |

**Wire caution.** A tip within **4 mm** of any ring or wedge wire loses confidence,
down to 60% of its value on the wire itself. A small tip error there would change
the score, so those darts get flagged.

The automatic policy flags uncertain darts rather than holding them, so play never
stalls waiting for a tap, and the player is never *silently* given a doubtful score
(spec §8).

---

## Stage 5: the match flow (`VisionScoringViewModel`, `X01MatchScreen`)

States: `calibrating → arming → ready`, plus `adjusting` and `paused(drift)`.

- **arming:** board locked, waiting for the empty-board reference ("keep it clear").
- **ready:** each `.dart` is appended to the visit if the match can take it; if
  not (bot turn, visit full) the caption says so.
- **Visit submission:** with the camera sheet open, normal auto-submit is held back
  so a misread dart can be fixed while it is still in the board. On
  `.boardCleared`, a finished visit (three darts, bust or checkout) is submitted.
  A shorter visit waits for **Submit visit**, since a dart may have been missed.
- **Corrections:** tap any dart in the visit bar for a keypad; **Miss** and
  **Undo** are always there.
- **Drift:** about once a second the locked calibration's colour agreement is
  re-measured. Three checks in a row below 60% of its locked value pause scoring
  with **Recalibrate** / **Keep calibration**.
- **Rotation:** rotating the phone changes image coordinates, so it triggers recalibration.
- The sheet is half height (60%) so the scoreboard stays visible and usable behind it.

---

## Tuning reference

Values most likely to need adjusting after real-device testing:

| Setting | Where | Default | Raise it if… | Lower it if… |
|---|---|---|---|---|
| `ringColor` saturation/hue gates | `BoardDetector` | sat > 0.38, red ±25°, green 75°–175° | non-board objects classify as ring colour | the board isn't found in dim or tinted light |
| `minimumFitConfidence` | `CalibrationQuality` | 0.6 | wrong boards lock | real boards never lock |
| `stableDetectionsRequired` | `VisionScoringViewModel` | 4 | calibration locks while still moving | locking feels slow |
| `seedThreshold` / `growThreshold` | `ImpactDetector.Configuration` | 0.16 / 0.07 | noise or shadows create false darts | darts are missed or tips come out short |
| `motionFractionLimit` | same | 0.003 | detection never settles (noisy sensor) | darts are scored while still wobbling |
| `settleFrames` | same | 4 | wobbling darts give wrong tips | scoring feels laggy |
| `maximumBlobFraction` | same | 0.04 | close-up cameras miss darts | arms get scored |
| `dartLengthBoardUnits` | same | 0.85 | long darts give wrong tip ends | short darts give wrong tip ends |
| `autoCommitConfidenceThreshold` | `VisionScoringPolicy.automatic` | 0.7 | too many wrong darts go unflagged | too many correct darts get flagged |
| `wireCautionDistanceMM` | same | 4 | wire darts are misread unflagged | too many flags near wires |

Each `vision_throw_detected` log event records confidence, `needs_review` and
whether the match accepted the dart, and `vision_calibration_locked` records
agreement, source (auto/manual) and camera tilt. Those are the numbers to compare
when tuning.

---

## How it is tested

`Tests/Unit/VisionSyntheticScene.swift` renders a regulation board, with optional
darts (point, barrel, shaft, flight), through a pinhole camera at any yaw, pitch,
roll and distance, with 2×2 supersampling. Tests then run the real pipeline on
those frames against known ground truth:

- **Calibration:** six camera poses up to ~45° (portrait and landscape), dim light,
  no-board frames, and drift detection. Landmarks must land within 1.2% of the
  board radius, and 99% of probe points across every bed must score correctly.
- **Detection:** single darts, tip-vs-flight ambiguity in the bull, three touching
  darts then takeout, pulling one dart, wobble, a body or arm in view, gradual
  exposure change, sensor noise, near misses and head-on cameras.
- **Policy:** auto-commit, review flags, wire caution and drift pause/resume.

**Not yet tested on real hardware.** Synthetic scenes have no specular glare,
worn boards, rolling-shutter or real sensor noise. The thresholds above are
first-principles defaults; expect to tune them from device footage.

---

## Known limitations and next steps

- **Head-on cameras** hide the tip behind the flight. Accuracy drops and a hint asks
  for an angled camera.
- **Bounce-outs and complete misses** are not detected: use **Miss**.
- **Hidden darts:** a dart landing entirely behind another dart's flight is invisible.
- **Non red/green boards** (some soft-tip or novelty boards) need **Adjust**.
- **X01 only** for now; the sheet's `Actions` interface is game-agnostic, so other
  modes need only their own wiring.

Possible next steps, roughly in order of value:

1. Record real throws with ground-truth scores and replay them through the
   detectors to tune thresholds.
2. Optional second camera (another phone or an iPad) and triangulate tips.
3. A small Core ML model to refine the tip within the blob found here.
4. Bounce-out detection: a dart-shaped transient that never settles.

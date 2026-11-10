**Estimated release:** `dev-only`

# Auto-Scoring Vision Specification (Future R&D)

> **Implementation status:** Phases A and B are implemented for X01 behind
> `enableVisionAutoScoring` (on in Debug builds; `-enable_vision_scoring` elsewhere).
> Domain logic lives in `Domain/Vision/` (board detection, perspective calibration,
> camera pose, dart-tip detection, session state machine); capture/UI in
> `Features/Play/Vision/`. See §12 for how it works and §13 for the device test plan;
> the full walkthrough of each stage, strategy and tuning value is in
> [`docs/vision-auto-scoring.md`](../docs/vision-auto-scoring.md).
> Phase C remains future work.

## 1. Purpose
Define a future camera-based auto-scoring system where players start a session, point the camera at a dartboard, and scores are detected automatically.

---

## 2. Product Value
- Faster, hands-free scoring
- Lower entry errors vs manual input
- Foundation for non-honor-system online play verification

---

## 3. Release Strategy

## Phase A: Guided Calibration + Assistive Detection
- Camera alignment guidance overlay
- Board calibration workflow before game starts
- Detection suggestions shown to user for confirm/edit

## Phase B: Auto-Commit with Confidence Threshold
- Auto-accept throws above confidence threshold
- Fallback confirm flow for ambiguous detections

## Phase C: Verified Online Match Signals
- Signed detection events with confidence metadata
- Anti-spoof checks and replay detection

---

## 4. User Flow
1. Start `Vision Session` from match setup.
2. App shows camera guidance lines and board fit overlay.
3. User aligns board until calibration quality is acceptable.
4. During play, app detects dart impacts and proposes/commits throws.
5. User can undo or correct if needed.

---

## 5. Camera Guidance Requirements
- Board circle/edge overlay with live fit quality indicator
- Required distance and angle hints
- Brightness/blur warnings
- Lock orientation and frame region after calibration

Calibration must output:
- Board center
- Board radius
- Segment orientation reference
- Perspective transform matrix

---

## 6. Technical Approach (Future)
- `AVFoundation` for camera capture/session management
- `Vision` for board and dart detection primitives
- Optional Core ML model for dart tip localization and segment classification
- Deterministic board mapping layer:
  - image-space point -> board coordinates -> segment/multiplier

No third-party runtime package required for baseline implementation.

---

## 7. Domain and Data Contracts

## New Command/Event Types
- `DetectThrowCommand`
- `ConfirmDetectedThrowCommand`
- `RejectDetectedThrowCommand`

## Event Metadata (extend existing payloads)
- `inputMethod = visionAuto | visionConfirmed | manual`
- `visionConfidence: Double?`
- `visionSessionId: UUID?`
- `frameTimestamp: Date?`

Keep iPhone match engine as source of truth; vision only proposes/feeds commands.

---

## 8. Accuracy and Safety Constraints
- Never silently auto-score below threshold
- Always allow undo/correction
- Pause or downgrade to manual if calibration drift exceeds tolerance
- Record detection confidence for post-game diagnostics

---

## 9. Online Play Implications (Future)
- Vision evidence stream can reduce honor-system issues:
  - tie throw events to live camera session
  - include confidence and device signatures
  - require periodic re-calibration checks

This is not anti-cheat complete by itself; combine with server-side validation later.

---

## 10. Testing and R&D Plan
- Synthetic board image regression set
- Lighting and angle stress tests
- Device matrix performance tests
- False-positive/false-negative tracking by segment
- End-to-end latency budget from throw detection to UI update

---

## 11. Decisions to Make Now (to stay future-ready)
- Keep scoring command model transport-agnostic (`manual`, `watch`, `vision`)
- Preserve event metadata extensibility in payload schemas
- Avoid UI-coupled scoring writes; always route through command/service boundary

---

## 12. Implemented Pipeline (Phases A + B)

No ML model and no third-party code: classical computer vision on `AVFoundation` frames.

**Board calibration (`BoardDetector`)** — fully automatic, any camera angle:
1. Classify saturated red/green pixels (the double/treble beds and bull).
2. Fit an ellipse to the outer edge of the double ring (sub-pixel edge, outlier rejection).
3. Find the bull; it is the image of the board centre. Ellipse + centre fix the
   perspective homography up to a spin (pole–polar construction).
4. Resolve the spin from the red/green alternation around the double and treble
   rings; the red wedge nearest the top of the image is the 20.
5. Lock after several consistent detections, then freeze exposure, focus and white balance.

Output is four landmarks (`BoardControlPoints`: outer double wire at 20, 6, 3, 11), which
also drive the manual fine-tune UI (**Adjust**: drag the four dots, rotate the numbering).

**Dart detection (`ImpactDetector`)** — runs on a 320×320 resample of the board region:
1. Capture an empty-board reference once the scene is still.
2. Difference each settled frame against the reference (luma + chroma, exposure
   compensated, soft shadows attenuated) and group changes with hysteresis.
3. A dart is a long thin blob. Its tip is one end of the principal axis, chosen from
   camera pose (`BoardPose`: the flight is displaced from the tip in a predictable
   direction because the dart sticks out of the board) and shape (the flight is wider
   and heavier than the point).
4. Map the tip through the homography to a segment; absorb the dart into the reference.
5. When the scene returns to the empty-board reference, report `boardCleared` (takeout).

**Scoring policy (`VisionScoringPolicy.automatic`)** — every detection is scored
immediately so no throw is lost. Detections that are uncertain (ambiguous tip, or within
4 mm of a wire) are flagged `needsReview` and outlined in the visit bar; tapping any dart
opens a correction keypad. With the camera sheet open, the visit is submitted when the
darts are pulled (three darts, bust or checkout); shorter visits wait for **Submit visit**.

**Drift** — the calibration is re-verified against ring colours about once a second;
a sustained drop pauses scoring and offers *Recalibrate* / *Keep calibration*.

### Verification status
- `Domain/Vision` is covered by unit tests that render synthetic boards and darts through
  a pinhole camera (`Tests/Unit/VisionSyntheticScene.swift`): calibration lands within
  ~1% of the board radius across yaw/pitch/roll up to ~45°, and dart tips within ~1–3 mm.
- **Not yet verified on real hardware.** Thresholds (colour classification, difference
  thresholds, settle timing) are first-principles defaults and will need tuning from
  device footage.

## 13. Device Test Plan

Setup: phone on a tripod or stand, 1–2 m from the board, **off to one side or below**
(20°–45° from straight on), whole board in frame, even lighting, no darts in the board.

1. Start an X01 match (Debug build) → **Camera scoring**.
2. Calibration: green wires should snap onto the real wires and "20" should label the 20.
   If not, tap **Adjust** and drag the four dots / rotate the numbering.
3. Wait for "Watching for darts", throw, and compare each scored dart with the board.
4. Pull the darts and confirm the visit submits and the next visit starts clean.

Worth recording when something is wrong: camera position, lighting, board/dart colours,
and whether the red marker (detected tip) sat on the real tip.

### Known limitations
- Head-on cameras hide the tip behind the flight; accuracy drops (a hint is shown).
- Bounce-outs and darts that miss the board entirely are not detected (use **Miss**).
- A dart landing fully hidden behind another dart's flight is not detected.
- Boards without red/green beds (e.g. some soft-tip or novelty boards) need **Adjust**.
- Camera scoring is wired into X01 only.


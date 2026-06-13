# Auto-Scoring Vision Specification (Future R&D)

> **Implementation status:** Phase A (guided calibration + assistive detection) is
> implemented for X01 behind `enableVisionAutoScoring` (local QA: `-enable_vision_scoring`).
> Domain logic lives in `Domain/Vision/` (geometry mapping, calibration, impact
> detection, session state machine + commands); capture/UI in `Features/Play/Vision/`.
> Phases B and C remain future work.

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

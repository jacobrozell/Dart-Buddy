# Animation Specification

## 1. Purpose

Define where motion adds value in DartBuddy, how to implement it safely, and how to disable it for accessibility. This spec prioritizes **low-risk, high-value** opportunities — polish that reinforces state users already understand, without slowing gameplay or hiding information behind motion alone.

**Authoritative for:** motion policy, duration/curve tokens, reduce-motion rules, and the animation backlog.

**Related specs:**
- Visual tokens and haptics baseline: [`DesignSystemSpec.md`](DesignSystemSpec.md) §4.6
- WCAG and system a11y: [`AccessibilitySpec.md`](AccessibilitySpec.md)
- Performance budgets: [`PerformanceSpec.md`](PerformanceSpec.md)
- Per-screen behavior: feature specs (e.g. [`MatchSummarySpec.md`](MatchSummarySpec.md), [`PlayHomeSpec.md`](PlayHomeSpec.md))

---

## 2. Principles

1. **Motion reinforces, never replaces.** Turn ownership, scores, busts, and wins must be readable instantly with motion off.
2. **Gameplay speed wins.** Animations on the scoring hot path must stay under the perceived-submit budget (see [`PerformanceSpec.md`](PerformanceSpec.md) §2).
3. **One motion per moment.** Do not stack trophy spring + banner pulse + score tween on the same event.
4. **Centralize policy.** Reuse shared duration/curve tokens and a single “should animate?” gate (§5).
5. **Native first.** Prefer opacity, scale ≤ 1.05, and short cross-fades over custom particle systems or long springs.
6. **Theme-aware fills.** Animated overlays use semantic `Brand` colors with appearance-dependent opacity (see §6).

---

## 3. Motion taxonomy

| Class | Purpose | Reduce Motion | Examples |
|-------|---------|---------------|----------|
| **A — Ambient** | Brand atmosphere; no state meaning | Skip entirely | Launch splash dots, `DartboardWedgeBackdrop` drift |
| **B — Entrance** | Draw attention to new non-critical UI | Instant final state | Resume banner, validation hint, error banner |
| **C — State echo** | Confirm a change user already caused | Instant or cross-fade only | Active player highlight, cricket closure scale |
| **D — Celebration** | Reward completion | Instant final state | Match summary trophy, leg-win banner pulse |
| **E — Continuous** | Loading / waiting | Static indicator | Progress views, bot “thinking” (pacing is separate) |

**Risk rule:** Class **A** and **D** are optional polish. Class **C** on the scoring screen requires the strictest review — must not delay pad input or obscure scores.

---

## 4. Current inventory (shipped patterns)

| Location | Class | Motion | Reduce Motion guard |
|----------|-------|--------|---------------------|
| `LaunchSplashView` | A + B | Hero scale/opacity, dot pulse | Yes (`accessibilityReduceMotion`) |
| `DartBuddyApp` splash dismiss | B | Cross-fade to main shell | Yes (`UIAccessibility.isReduceMotionEnabled`) |
| `MatchSummaryScreen` | D | Trophy spring + `sensoryFeedback` | Yes |
| `MatchFeedbackBanner` | D / C | Bust shake; leg/closure pulse | Yes; opacity varies by `colorScheme` |
| `CricketBoardView` | C | Closure column scale | Yes |
| `MatchHistoryDetailScreen` | B | Timeline expand/collapse | **Gap** — add reduce-motion guard |

Use these as reference implementations when extending motion.

---

## 5. Accessibility — disabling motion

### 5.1 System Reduce Motion (required)

All custom animation must respect **`accessibilityReduceMotion`** (view layer) or **`UIAccessibility.isReduceMotionEnabled`** (app/delegate layer).

**When Reduce Motion is on:**
- Skip Class A entirely.
- Class B/D: show **final layout immediately** (no opacity-from-zero, scale-from-small, shake, or spring).
- Class C: allow **instant** state change or a **single cross-fade ≤ 150ms** with no scale/bounce.
- Do not rely on motion to reveal targets, checkout paths, or turn order.

`ClientEnvironmentMonitor` already reports `reduceMotion` changes for diagnostics — no extra analytics required for MVP.

**Bot throw pacing** is separate from UI motion policy. System Reduce Motion may optionally force instant bot turns per [`InstantBotTurnsSpec.md`](InstantBotTurnsSpec.md) §5; it does not today affect `BotTurnPacing` without that spec implemented.

### 5.2 Reduce Transparency (required for glass/backdrops)

Decorative backgrounds (`DartboardWedgeBackdrop`, future ambient layers) must also respect **`accessibilityReduceTransparency`**. When on, omit translucent/decorative layers entirely (see `LaunchSplashView`).

### 5.3 In-app “Reduce animations” toggle (post-1.0, optional)

MVP relies on the **system** setting only (matches Apple HIG and existing WCAG tests).

If product adds an in-app toggle later:
- Place under **Settings → Appearance** (alongside theme).
- Key: `animationsEnabled` on `SettingsRecord`; default `true`.
- Effective policy: `shouldAnimate = animationsEnabled && !accessibilityReduceMotion`.
- Mirror change in [`SettingsSpec.md`](SettingsSpec.md) and seed/migration specs.

Do **not** duplicate haptics/sound toggles; motion is independent of [`SettingsSpec.md`](SettingsSpec.md) `hapticsEnabled`.

### 5.4 VoiceOver and Dynamic Type

- Animated elements that are decorative: `accessibilityHidden(true)` (e.g. launch dots).
- Celebration must not delay accessibility focus order — summary header identifiers (`matchSummaryHeader`) must be present in final state immediately when Reduce Motion is on.
- Animations must not cause layout jump that clips score text at accessibility sizes.

### 5.5 Engineering gate (recommended helper)

Add `DesignSystem/Tokens/MotionPolicy.swift` (name TBD) with:

```swift
enum MotionPolicy {
    static func shouldAnimate(reduceMotion: Bool, animationsEnabled: Bool = true) -> Bool {
        animationsEnabled && !reduceMotion
    }
}
```

Views inject `@Environment(\.accessibilityReduceMotion)` and pass into policy. **Never** animate without checking policy in gameplay and summary flows.

---

## 6. Light / dark mode

### 6.1 Color rules

- Animated fills use **`Brand`** semantic colors, not hardcoded `Color.white` / `.black`.
- Overlay opacity should vary by scheme (pattern from `MatchFeedbackBanner`):

| Token | Light opacity | Dark opacity |
|-------|---------------|--------------|
| Success / leg win (`Brand.green`) | ~0.22 | ~0.32 |
| Warning / closure (`Brand.amber`) | ~0.22 | ~0.32 |
| Error / bust (`Brand.red`) | ~0.22 | ~0.32 |

- Avoid full-screen flashes: entrance animations should tween **opacity of content**, not swap background color.
- Primary text on animated banners stays **`Brand.textPrimary`** or **`Brand.textOnAccent`** on solid `Brand.redAccent` — never low-contrast accent-on-accent.

### 6.2 iOS 26 Liquid Glass

System navigation chrome may animate glass independently. **Brand content layer** stays opaque on `Brand.background` / `Brand.card` (see `DesignSystem/README.md`). Do not add custom `.glassEffect` on scoreboard content to “match” system motion.

### 6.3 Verification matrix

Any new animation requires manual check in **portrait + landscape** × **light + dark** × **Reduce Motion on/off**. Log evidence in `accessibility/wcag-2.1-aa/screens/` when touching celebration or gameplay feedback.

---

## 7. Motion tokens

Canonical curves (extend [`DesignSystemSpec.md`](DesignSystemSpec.md) §4.6):

| Token | Duration | Curve | Use |
|-------|----------|-------|-----|
| `motion/fast` | 150–180ms | `.easeOut` | Hints, banner enter, opacity toggles |
| `motion/standard` | 200–220ms | `.easeInOut` | Turn highlight, section expand |
| `motion/emphasis` | 350–500ms | `.spring(response: 0.35–0.5, dampingFraction: 0.55–0.6)` | Trophy, leg win (once per event) |
| `motion/shake` | 450ms | linear + `GeometryEffect` | Bust only; never on success paths |

**Haptics pairing** (when `hapticsEnabled`):
- Turn switch: light impact (optional, post-1.0)
- Checkout / leg win: medium + Class D visual
- Bust / invalid: warning + shake (existing)

---

## 8. Low-risk, high-value backlog

Prioritized by **value ÷ (risk × effort)**. Implement top-down; each item is independently shippable.

### Tier 1 — Ship first (low risk, clear UX win)

| # | Surface | Class | Proposal | Status |
|---|---------|-------|----------|--------|
| 1 | **Setup validation hint** (`SetupValidationHint`) | B | Fade + slight slide on appear | **Done** — `motionBannerEntrance()` |
| 2 | **Error banner** (`ErrorBanner`) | B | Same entrance as setup hint | **Done** — `motionBannerEntrance()` |
| 3 | **Resume banner** (Play home) | B | Gentle opacity on appear | **Done** — `SetupHomeView.resumeBanner` |
| 4 | **Active player card** (X01, Cricket) | C | Cross-fade when `isActive` changes | **Done** — `PlayerScoreCard`, `CricketBoardPlayerColumn` |
| 5 | **History timeline** (`MatchHistoryDetailScreen`) | B | Guard `withAnimation` with Reduce Motion | **Done** — `MotionPolicy.animateIfAllowed` |
| 6 | **Tab empty → content** | B | Opacity when first load completes | **Done** — History, Statistics, Activity, Players |

**Infrastructure:** `MotionPolicy`, `Motion` tokens, `MotionEntrance` modifiers (`motionBannerEntrance`, `motionTabContentReveal`).

### Tier 2 — Nice polish (medium effort, still safe)

| # | Surface | Class | Proposal | Status |
|---|---------|-------|----------|--------|
| 7 | **X01 remaining score** | C | Numeric text transition on committed turn only | **Done** — `motionNumericScore`, skips mid-visit preview |
| 8 | **Cricket mark increment** | C | Brief scale on mark chip when count increases | **Done** — `motionMarkIncrementPulse` (≤ 1.03) |
| 9 | **Checkout suggestion banner** | B | Fade when suggestion appears/disappears | **Done** — `motionBannerEntrance` + opacity transition |
| 10 | **Onboarding steps** | B | Horizontal cross-fade between pages | **Done** — `MotionTransition.onboardingStep`, RTL-aware |
| 11 | **Modes search filter** | B | Opacity when filter changes | **Done** — animate on `searchText` |
| 12 | **Match summary stat rows** | B | Staggered fade-in after trophy (40ms/row) | **Done** — `motionStaggeredReveal`, instant when Reduce Motion |

### Tier 3 — Defer or mode-specific

| Item | Why defer |
|------|-----------|
| Scoring pad key press scale | Adds perceived latency; haptics already sufficient |
| Particle/confetti | High maintenance; contrast risk in light mode |
| Slot-machine / flip reveals | Planned party modes — spec per game (`RemixNightGameSpec`, etc.) |
| Chart draw animations (Statistics) | Low traffic; verify performance on long series first |
| Bot avatar motion | `BotTurnPacing` owns timing; visual motion is redundant — see [`InstantBotTurnsSpec.md`](InstantBotTurnsSpec.md) for app-wide instant bot playback |
| Navigation push customization | System transitions are adequate |

---

## 9. Gameplay guardrails

**Never animate on the scoring hot path when:**
- `submitTurn` is in flight (`submittingTurn`)
- Bot is playing (`isBotPlaying`)
- User is mid-visit dart entry (X01 `enteredDarts` non-empty)

**Allowed during play:**
- Feedback banners after state is committed
- Active player highlight after turn advance
- Cricket board closure echo (existing)

**Performance:** Class C/D on match screens must not allocate per-frame views across full scoreboards. Prefer `animation(_:value:)` on isolated subviews.

---

## 10. Feature spec hooks

When implementing Tier 1–2 items, add a short **Motion** subsection to the owning feature spec (do not duplicate full policy):

| Feature spec | Motion note |
|--------------|-------------|
| [`PlayHomeSpec.md`](PlayHomeSpec.md) | Resume banner entrance (Tier 1 #3) |
| [`SetupFlowSpec.md`](SetupFlowSpec.md) | Validation hint entrance (Tier 1 #1) |
| [`MatchSummarySpec.md`](MatchSummarySpec.md) | Trophy celebration already specified; add stat row stagger if pursued |
| [`HistorySpec.md`](HistorySpec.md) | Timeline expand reduce-motion (Tier 1 #5) |
| [`game-modes/implemented/X01GameSpec.md`](game-modes/implemented/X01GameSpec.md) | Active card + optional score tween |
| [`game-modes/implemented/CricketSpec.md`](game-modes/implemented/CricketSpec.md) | Mark increment echo (extends existing closure) |
| [`MatchForfeitSpec.md`](MatchForfeitSpec.md) | **No** trophy animation on forfeit (already required) |

---

## 11. Testing

### Unit
- `MotionPolicy.shouldAnimate` truth table (`reduceMotion` × future `animationsEnabled`).

### UI / accessibility
- Extend `WCAGAccessibilityUITests` patterns: with `preferences.reduceMotion = true`, assert critical identifiers visible without waiting on animation delays.
- Manual: Reduce Motion on device — launch, complete leg, open summary, expand history timeline.

### Performance
- No regression on `submitTurn` p95 ([`PerformanceSpec.md`](PerformanceSpec.md) §4).
- Profile one match with Tier 1 #4 active-card animation on iPhone SE class device before wide rollout.

---

## 12. Definition of done (per animation)

- [ ] Class and tier identified in PR description
- [ ] `accessibilityReduceMotion` (and transparency if decorative) handled
- [ ] Light + dark opacity/contrast checked on animated fills
- [ ] No new information conveyed by motion alone
- [ ] UI test identifiers unchanged unless intentional
- [ ] Feature spec Motion subsection updated if user-visible behavior changes

---

## 13. Out of scope (1.0.0)

- Custom navigation transitions
- Lottie / Rive assets
- Parallax on scroll in gameplay
- In-app animations toggle (unless promoted from §5.3)
- Watch companion motion ([`AppleWatchCompanionSpec.md`](AppleWatchCompanionSpec.md))

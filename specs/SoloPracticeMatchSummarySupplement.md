# Solo Practice — Match Summary Supplement

## 1. Purpose
Define the **solo practice variant** of [`MatchSummarySpec.md`](../../MatchSummarySpec.md): layout, CTAs, stat presentation, and undo behavior when there is no opponent or winner ceremony.

**Parent:** [`SoloPracticeModesSpec.md`](../../SoloPracticeModesSpec.md)  
**Status:** Planned

---

## 2. Design principle

Solo practice completion should feel like **"here's how you did"**, not **"you beat someone."** Reuse `MatchSummaryScreen` infrastructure with a `summaryStyle: .soloPractice` branch — do not fork a separate navigation destination.

---

## 3. Layout wireframe

```text
+--------------------------------------------------+
| Match Summary                                    |
|--------------------------------------------------|
| [Mode badge: Call & Hit]                         |
| Duration · date                                  |
|--------------------------------------------------|
| ┌──────────────────────────────────────────────┐ |
| │           68%                                 │ |  ← performance hero
| │        34 of 50 hits                          │ |
| │     Longest streak: 7                         │ |
| └──────────────────────────────────────────────┘ |
| Alice                                    [avatar] |  ← participant strip (no trophy)
|--------------------------------------------------|
| [ Segment breakdown · collapsible ]              |  ← mode-specific body
| [ Config recap: Singles · 3 darts · 50 ]        |
| [ Personal best: 72% ↑ ]                       |
|--------------------------------------------------|
| [ Practice again ]          (primary)            |
| [ View in History ]         (secondary)          |
| [ Undo last target ]        (tertiary, if allowed)|
| [ Done ]                    (tertiary)           |
+--------------------------------------------------+
```

### Performance hero variants by stat kind

| Stat kind | Hero primary | Hero secondary |
|-----------|--------------|----------------|
| `practiceAccuracy` | `68%` | `34 / 50 hits` |
| `soloScore` | `847` | `Personal best: 912` or `Game over at round 14` |
| `sequence` | `18:42` or `Completed` | `Darts thrown: 64` |

Mode provides content via `SoloPracticeSummaryContent` protocol (conceptual).

---

## 4. Components

| Component | Shared? | Notes |
|-----------|---------|-------|
| `SoloPracticePerformanceHero` | Yes | Large metric typography, accessible summary label |
| `SoloPracticeParticipantStrip` | Yes | Name + avatar; **no** winner badge |
| `SoloPracticeConfigRecap` | Yes | Chips from match config payload |
| `SoloPracticePersonalBestRow` | Yes | Compares within config fingerprint when applicable |
| Mode breakdown view | Per mode | Call & Hit segment grid; Bob's 27 round log |

**Explicitly omitted:** trophy icon, confetti, "Winner" headline, second participant row.

---

## 5. CTAs

| Button | Action | Primary? |
|--------|--------|----------|
| **Practice again** | Pop to setup with config prefill; same catalog mode | Yes |
| **View in History** | Push history detail for `matchId` | Secondary |
| **Undo last …** | Mode-specific undo; pop to active match | Tertiary; hidden when ineligible |
| **Done** | Pop Play stack to setup home or Modes tab (product TBD — default setup home) | Tertiary |

Replace multiplayer **New Match** label with **Practice again** for all `isSolo` completions.

---

## 6. Undo behavior by mode

| Mode | Summary undo label | Restores |
|------|-------------------|----------|
| Call & Hit | Undo last target | Previous target + Hit/Miss cleared |
| Bob's 27 | Undo last round | Previous round score state |
| Halve-It | Undo last round | Previous round score |

Undo reopens match as `inProgress`; summary aggregates roll back per [`StatsSpec.md`](../../StatsSpec.md) recompute policy.

Honor-scored modes: undo removes last **reported** outcome, not darts (none recorded).

---

## 7. Architecture sketch

```swift
enum MatchSummaryStyle {
    case competitive   // winner card — X01, Cricket, …
    case soloPractice(SoloPracticeSummaryContent)
}

protocol SoloPracticeSummaryContent {
    var performancePrimary: String { get }
    var performanceSecondary: String? { get }
    var personalBestText: String? { get }
    @ViewBuilder var breakdown: AnyView { get }
    var undoLabelKey: String? { get }
    var canUndo: Bool { get }
}
```

`MatchSummaryViewModel` selects style from `MatchType` + catalog entry `isSolo`.

---

## 8. Accessibility

| Element | Requirement |
|---------|-------------|
| Performance hero | `"68 percent accuracy, 34 of 50 hits, Call and Hit practice"` |
| Personal best | Include direction (↑ improved / ↓ below best) in spoken label |
| Practice again | `accessibilityIdentifier`: `match_summary_practice_again` |
| No winner | Do not announce "winner" for solo sessions |

Manual doc: extend [`match-summary.md`](../../accessibility/wcag-2.1-aa/screens/match-summary.md) with solo section at implementation.

---

## 9. Campaign / achievements layer

When enabled post-1.0, achievement toasts attach **below** performance hero — same slot as competitive summary ([`MatchSummarySpec.md`](../../MatchSummarySpec.md) §2 post-1.0). Solo modes use achievement predicates that do not assume a win (e.g. "complete 10 Call & Hit sessions").

---

## 10. Testing

- Unit: VM selects `.soloPractice` for `callAndHit` completed match
- Unit: no winner row model for solo
- UI: Practice again prefill smoke
- UI: Personal best row hidden on first-ever session

---

## 11. Verification
| Field | Value |
|-------|--------|
| **Status** | Planned |

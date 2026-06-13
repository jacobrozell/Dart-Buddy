# Badges Specification (Profile Presentation)

## 1. Purpose

Define how **local achievements** render on player profiles: medal components, gallery layout, empty states, and accessibility — without duplicating achievement rules (those live in [`AchievementsSpec.md`](AchievementsSpec.md)).

**Related specs:** Achievement domain — [`AchievementsSpec.md`](AchievementsSpec.md). Player screens — [`PlayerSpec.md`](PlayerSpec.md). Design tokens — [`DesignSystemSpec.md`](DesignSystemSpec.md). Campaign collectibles — [`CampaignSpec.md`](CampaignSpec.md) §9 (campaign badges, later phase).

**Status:** Post-1.0 R&D — ships with local achievements; campaign-specific badge art is a later add-on.

---

## 2. Scope

### In scope
- `BadgeMedal` design-system component (locked, unlocked, in-progress)
- Achievement gallery on **Player Detail**
- Summary unlock row styling (shared component with summary screen)
- Light/dark mode, Dynamic Type, VoiceOver labels
- Localization of visible names/descriptions (in-app; not ASC metadata)

### Out of scope
- Achievement evaluation logic — [`AchievementsSpec.md`](AchievementsSpec.md)
- Game Center `GKAchievementViewController` — future
- Campaign stars on map nodes — [`CampaignSpec.md`](CampaignSpec.md)

---

## 3. Terminology

| Term | Meaning |
|------|---------|
| **Achievement** | Domain object with `achievementId`, rules, progress |
| **Badge** | Visual representation of an achievement (or campaign collectible) on a profile |
| **Medal** | The `BadgeMedal` component instance |

Campaign may add **campaign badges** (boss defeated, act cleared) that are not Game Center achievements — same gallery component, different `source` enum.

---

## 4. UI Surfaces

### 4.1 Player Detail — Achievement gallery

**Location:** `PlayerDetail` below stats summary (or dedicated section).

**Layout:**
- Section header: localized **Achievements** with count subtitle (`12 / 48`)
- Grid: adaptive columns (3 on iPhone portrait, more on iPad regular)
- Sort: unlocked first (by `unlockedAt` desc), then in-progress, then locked
- Locked: silhouette / desaturated medal; no spoiler text for **hidden** achievements (show “Hidden achievement”)
- In-progress incremental: ring or percent label on medal

**Empty state:** “No achievements yet — play a match to start earning.”

**Guest players:** Same gallery as any human — guests earn local achievements per [`AchievementsSpec.md`](AchievementsSpec.md).

### 4.2 Match Summary — unlock strip

When achievements unlock at match end, show a horizontal or vertical list of `BadgeMedal` + title above primary CTAs.

- Uses same medal asset/tokens as gallery
- Tapping a medal is optional v1 (no navigation required); v2 may push filtered gallery

### 4.3 Campaign summary (future)

Campaign match summary may show **campaign badge** unlock in addition to generic achievements — reuse `BadgeMedal` with `campaignSecondary` accent. Specified in [`CampaignSpec.md`](CampaignSpec.md).

---

## 5. `BadgeMedal` Component

**Proposed path:** `DesignSystem/Components/BadgeMedal.swift`

| State | Visual |
|-------|--------|
| `locked` | Muted fill, lock or question glyph for hidden |
| `inProgress` | Full-color rim; percent badge |
| `unlocked` | Full color + optional date caption on detail only |

**Tokens:** Use mode-accent pattern from `GameModeAccent` — identity only, not win/loss status ([`DesignSystemSpec.md`](DesignSystemSpec.md)). Achievement tier may map to rim color (common / rare / legendary) — define in `AchievementDefinition.tier`.

**Sizes:**
- `summary` — 44pt min touch target wrapper
- `gallery` — 56–72pt medal
- `detail` — 96pt hero optional

Register in `DesignSystem/README.md` when shipped.

---

## 6. Accessibility

- VoiceOver: `"{name}, unlocked {date}"` / `"{name}, {percent} percent"` / `"Hidden achievement, locked"`
- Gallery grid: accessibility rotor or list fallback at AXXXL if grid truncates — mirror [`CampaignSpec.md`](CampaignSpec.md) list-fallback pattern for consistency
- Reduce Motion: no unlock particle effects
- Contrast: medal on `Brand.card` must pass WCAG AA ([`AccessibilitySpec.md`](AccessibilitySpec.md))

---

## 7. Localization

- In-app strings: `achievement.{id}.name`, `achievement.{id}.description` in all ship locales ([`LocalizationSpec.md`](LocalizationSpec.md))
- Hidden achievements: generic locked string until unlocked
- Do not duplicate full catalog in spec — keys follow `achievementId` with dots → underscores

---

## 8. Data Flow

```
PlayerDetailViewModel
  → AchievementRepository.achievements(for: playerId)
  → [AchievementDisplayModel] (id, name, state, percent, unlockedAt)
  → BadgeMedal grid
```

No business logic in views; locked/hidden rules come from repository + definition catalog.

---

## 9. Testing

- Snapshot / preview: all medal states light + dark
- VoiceOver labels unit-tested on display models
- Player detail UI test: seeded unlocked achievement visible

---

## 10. Verification

| Field | Value |
|-------|--------|
| **Last verified** | 2026-06-11 |
| **Commit** | (spec authoring — no implementation yet) |
| **Code** | (planned) `BadgeMedal.swift`, Player detail views |

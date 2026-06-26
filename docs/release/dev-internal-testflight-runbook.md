# Dart Buddy — Internal TestFlight runbook (`dev`)

**Purpose:** Ship a **full-surface** build from `dev` to **internal TestFlight** for dogfooding — all 22 playable modes, 5 tabs, Training Partner, export, achievements, App Intents, visual dartboard, and bundled locales.

**Not for App Store submit.** Store releases use `release/*` branches without `DART_BUDDY_INTERNAL_BUILD`.

| | |
|--|--|
| **Branch** | `dev` |
| **Version** | `1.2.0` (bump `CURRENT_PROJECT_VERSION` per RC iteration) |
| **Build flag** | `DART_BUDDY_INTERNAL_BUILD` (Release only — see `project.yml`) |
| **Companion** | [`branch-strategy.md`](branch-strategy.md) · [`feature-inventory.md`](../feature-inventory.md) |

---

## What this build includes

| Area | Reachable |
|------|-----------|
| **Tabs** | Play · **Modes** · Players · Activity · Settings |
| **Game modes** | All **22 shipped** engines (standard, party, co-op Raid, practice) |
| **Bots** | Preset · custom · **Training Partner** |
| **Players** | CRUD · **export** (DBPE) |
| **Achievements** | On — summary unlocks + player gallery + detail sheet |
| **Locales** | en, de, es, nl, fr, zh-Hans, it (system locale) |
| **Flags on** | App Intents · visual dartboard input |

**Still out of scope:** 12 catalog stubs (no engine), campaign, online play, Game Center, watch/widgets.

---

## Pre-flight (engineering)

- [ ] On branch `dev`, latest commit pushed
- [ ] `xcodegen generate`
- [ ] **CI green:** `xcodebuild test -scheme DartBuddyCI -destination 'platform=iOS Simulator,name=iPhone 17'`
- [ ] `MARKETING_VERSION` = `1.2.0` in [`project.yml`](../../project.yml)
- [ ] `CURRENT_PROJECT_VERSION` bumped for this upload (must exceed last TestFlight build)
- [ ] Real `GoogleService-Info.plist` for Release / Xcode Cloud secret set
- [ ] Confirm **Release** config still sets `DART_BUDDY_INTERNAL_BUILD` in `project.yml` (do not archive from `release/*` for this runbook)

---

## Cut the build

### Option A — Xcode Cloud (recommended)

1. Push `dev` to `origin`
2. GitHub Actions → **Trigger TestFlight** → Run workflow  
   - Branch: `dev`  
   - Or start **Release** workflow in App Store Connect → Xcode Cloud
3. Verify log: `xcodegen`, Firebase plist, archive, upload OK
4. Build status → **Ready to Test** on **internal** group

See [`xcode-cloud.md`](xcode-cloud.md) for API secrets and workflow ID.

### Option B — Local archive

```bash
cd Dart-Buddy
xcodegen generate
xcodebuild archive \
  -scheme DartBuddy \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -archivePath build/DartBuddy-internal.xcarchive
```

Upload via Xcode Organizer → Distribute App → TestFlight.

---

## TestFlight metadata

**What to Test** (paste for internal testers):

```
Internal full-surface build from dev (1.2.0).

Please exercise:
• All 5 tabs — especially Modes catalog and co-op Raid
• Training Partner create + practice match
• Player export
• Achievements: finish a match → summary unlocks; check player profile gallery
• One party mode you haven’t tried (e.g. Killer, Golf, Fleet)
• Optional: switch device language to de/es/nl for a quick smoke

Report crashes and P0 UX breaks in your usual channel. This is not store scope.
```

---

## Device QA matrix (~45 min)

**Build:** TestFlight internal · **physical iPhone** preferred · **no launch args**

### §1 Fast gate (~10 min)

- [ ] App launches; **five tabs** visible (including **Modes**)
- [ ] Play → Change mode → party / co-op / practice sections appear
- [ ] Modes tab → browse → quick-start one mode → setup opens
- [ ] Settings → no debug-only junk visible

**Decision:** [ ] PASS · [ ] FAIL

### §2 Core regression (~10 min)

- [ ] X01: start → score → undo → complete → summary
- [ ] Cricket Normal: full match → summary
- [ ] Resume active match from Play home
- [ ] Activity: history detail + statistics filter
- [ ] Custom bot in X01 match

### §3 Full-surface spot checks (~15 min)

Pick **one path each** (complete match or meaningful progress):

| Path | Check |
|------|-------|
| **Party** | Killer (3+ humans) or Baseball — pick phase / scoring / summary |
| **Co-op** | Raid — start → boss UI → finish or forfeit → summary |
| **Practice** | Around the Clock solo — progression → summary |
| **Training Partner** | Player detail → create (if eligible) → practice X01 |
| **Export** | Player detail → Export → share sheet appears |

### §4 Achievements (~10 min)

- [ ] Play a human X01 match → on summary, **Achievements unlocked** section if applicable (e.g. first match)
- [ ] **NEW** badge on fresh unlocks
- [ ] Players → human → **Achievements** grid → tap medal → detail sheet
- [ ] Undo last throw from summary → achievement section clears/reconciles (no ghost unlocks)

### §5 Optional polish

- [ ] Visual dartboard: Settings toggle + in-match on X01/Cricket
- [ ] Siri shortcut: Open Play (if Shortcuts app shows Dart Buddy intents)
- [ ] Locale smoke: device language `de` or `es` → tab labels localized

---

## Sign-off

| Role | Go | Date | Notes |
|------|-----|------|-------|
| Engineering | [ ] | | CI + archive |
| Device QA | [ ] | | §1–§4 on TestFlight |
| Owner | [ ] | | Ready to widen store train or file fixes |

---

## If something breaks

| Symptom | Likely cause |
|---------|----------------|
| Only X01 + Cricket, 4 tabs | Archived from `release/*` or lean launch arg — rebuild from `dev` Release |
| No achievements | `enableAchievements` off — confirm `DART_BUDDY_INTERNAL_BUILD` in archive log |
| Crashlytics missing | Placeholder `GoogleService-Info.plist` — fix secret / local plist |
| Mode missing in picker | Engine bug or `ProductSurface` — file issue on `dev` |

**Do not** cherry-pick `DART_BUDDY_INTERNAL_BUILD` onto store release branches without a deliberate scope decision.

---

**Last reviewed:** 2026-06-26

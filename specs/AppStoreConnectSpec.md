# App Store Connect Specification

## 1. Purpose
Define App Store presence, branding, naming, metadata, and launch assets for the darts app so release execution is consistent and high quality.

---

## 2. Product Positioning
- Free darts scorekeeper for iPhone
- For beginners and garage nights with friends
- No ads, no account
- Fast scoring for X01, Cricket, and simple party games
- Local-first reliability
- Accessible, clean Apple-native UI

Primary audience:
- Beginners learning the game
- Friends playing in a garage or at home
- Casual players who want a simple scorekeeper

---

## 3. App Naming

## Recommended Name (Primary)
- **Dart Buddy**

Why:
- Distinctive and memorable
- Matches App Store display name (`CFBundleDisplayName`)
- Strong keyword relevance via subtitle and keywords (`darts`, `scoreboard`)

## Backup Name Candidates
- `Dart Buddy: X01 & Cricket`
- `Dart Buddy Scorekeeper`
- `Dart Buddy — Darts Scorer`

Naming rules:
- Keep final name <= 30 characters when possible
- Avoid trademark conflicts
- Keep subtitle responsible for feature detail, not name bloat

---

## 4. Brand Direction

## Brand Attributes
- Clean
- Fast
- Trustworthy
- Friendly
- Competitive but non-gimmicky

## Visual Direction
- Dark-mode friendly scoreboard aesthetic
- High-contrast score typography
- Minimal chrome around core scoring surfaces

## Icon Direction
- Simple dartboard + score motif
- No tiny detail that gets lost at small icon sizes
- Consistent with accessibility contrast expectations

---

## 5. App Store Metadata

## App Name
- `Dart Buddy` (subject to availability)

## Subtitle (≤30 chars)
- **Canonical:** `Garage nights for beginners` (27)
- **Alternate:** `Beginner darts with friends` (27)

The subtitle is who it is for. Search terms (`darts`, `scorekeeper`, `x01`, `cricket`) stay in keywords.

**App Store rule (Guideline 2.3.7):** Do **not** use pricing or monetization language in the **name** or **subtitle** — including `free`, `no ads`, discounts, or price comparisons. Those claims belong in **promotional text** and the **description** only.

## Keywords (≤100, comma-separated, no spaces)
- `darts,scorekeeper,x01,cricket,beginner,garage,friends,501,301,party,casual,counter,practice`

Rules:
- Keep keyword list focused; avoid irrelevant stuffing
- Revisit after real search analytics data

## App Store Connect identifiers
- **Bundle ID:** `com.jacobrozell.DartBuddy`
- **App Store Connect app ID:** `6777507161` (canonical in `AppLinks.appStoreAppID`)
- **Public listing URL:** `https://apps.apple.com/app/id6777507161`

## In-app update availability
- Shipped in 1.x: optional update prompt on main tab load — see [`AppShellSpec.md`](AppShellSpec.md) §6.
- Uses Apple’s public iTunes Lookup API; no third-party SDK.
- Prompt appears only after a **released** App Store version is newer than the installed build (TestFlight-only builds do not trigger it).

## Promotional Text (≤170, editable on the live version)
- `For beginners and garage nights with friends. Score X01, Cricket, and easy party games. Free, no ads, no account.`

## Description
```
Dart Buddy is a free darts scorekeeper for beginners and garage nights with friends. Pass the phone around, tap in each dart, and get back to throwing. No ads, no account, and your matches stay on your device.

• X01 (301 and 501), with checkout suggestions
• Cricket, Normal and Cut Throat
• Baseball, Killer, and Shanghai for a group
• Raid, a co-op game for one to three people
• Around the Clock, solo practice from 1 to bull
• Add friends or a bot, reorder turns, and start in one tap
• Match history and stats
• VoiceOver, Dynamic Type, and Light or Dark mode

Your scores stay on your phone.
```

---

## 6. Privacy and Compliance Metadata
- Reflect local-first behavior in privacy disclosures
- No ad tracking
- Keep diagnostics disclosures aligned with actual enabled services
- Re-audit privacy labels before enabling Firebase phases

## 6.1 Accessibility URL (App Store Connect)
- **URL:** `https://jacobrozell.github.io/Dart-Buddy/accessibility.html`
- **Source:** `docs/accessibility.html` (GitHub Pages, same host as privacy/support)
- **In-app:** Settings → Help & Feedback → **Accessibility** (`AppLinks.accessibility`)
- Enter under App Store Connect → App → **App Accessibility** → **Manage the accessibility URL**
- Keep page content aligned with declared Accessibility Nutrition Labels

---

## 7. Category, Age Rating, and Pricing
- Category: `Sports`
- Age rating: expected `4+` unless future social features change scope
- Price: `Free`
- Ads: `None`
- In-app purchases: `None` for 1.0.0

---

## 8. Screenshots and Preview Assets

## Screenshot Priorities (iPhone)
1. X01 gameplay with large score UI
2. Cricket board view
3. New match setup simplicity
4. Match history summary
5. Player stats/profile snapshot

Asset guidance:
- Use real in-app UI, not concept mockups
- Keep text overlays short and benefit-driven
- Include dark/light examples if useful

Portrait upload sizes (App Store Connect):
- **6.5" Display:** 1284×2778 or 1242×2688 portrait; 2778×1284 or 2688×1242 landscape (no device bezels). Capture script resizes from iPhone 17 Pro simulator output; landscape files use `-landscape` suffix. See `marketing-screenshots/README.md`.
- **6.9" Display:** 1320×2868 or 1290×2796 when required — use iPhone 17 Pro Max with `APP_STORE_RESIZE=0`, or upload scaled assets per Connect UI.
- **iPad 12.9" / 13":** 2064×2752 or 2048×2732 portrait; 2752×2064 or 2732×2048 landscape (`./Scripts/capture-ipad-marketing-screenshots.sh` → `marketing-screenshots/ipad/raw/`).

---

## 9. App Store Presence and Launch Plan

## Pre-Launch
- Reserve app name
- Prepare icon + screenshots
- Finalize privacy details and support URL
- Prepare concise release notes

## Launch Week
- Monitor reviews and crash reports daily
- Track conversion metrics and keyword performance
- Patch critical UX issues quickly

## Post-Launch Iteration
- A/B test subtitle and screenshot order over time
- Refine keywords from observed discoverability

---

## 10. Localization Strategy for Store Listing
- Start with English listing
- Expand store metadata localization as app localization grows
- Prioritize markets where darts is popular for early localization waves

---

## 11. Risks and Mitigations
- Name unavailable -> keep backup names ready
- Weak discoverability -> improve subtitle/keywords/screenshots iteratively
- Misaligned privacy labels -> strict release checklist validation

---

## 12. Ownership and Governance
- Product/PM owns positioning and messaging
- Design owns icon/screenshot visual quality
- Engineering confirms metadata truthfulness vs app behavior
- Release owner verifies final App Store Connect checklist

# StoreKit Tip Jar Plan

**Status:** Not started · approved direction for post-1.0  
**Created:** 2026-06-18  
**Target release:** 1.2+ (after 1.0 App Store approval)  
**Goal:** Replace the removed external “Buy Developer a Coffee” link with **optional consumable In-App Purchases** that comply with [App Store Review Guideline 3.1.1](https://developer.apple.com/app-store/review/guidelines/#payments).

**Context:** App Review rejected builds that linked to Buy Me a Coffee from Settings → About. Tips tied to a free app that delivers digital scoring are considered payments for digital content/services and must use IAP on all storefronts (external browser links are only available under separate US entitlements for qualifying apps — not planned here).

**Related:** [`specs/SettingsSpec.md`](../../specs/SettingsSpec.md) · [`Support/Navigation/AppLinks.swift`](../../Support/Navigation/AppLinks.swift) (`buyDeveloperCoffee` must stay `nil`) · [`docs/feature-inventory.md`](../feature-inventory.md)

---

## 1. Product rules

| Rule | Detail |
|------|--------|
| **Optional** | Never gate gameplay, stats, bots, or modes behind a tip. |
| **Consumable only** | Each tip is a one-time thank-you; no subscriptions or non-consumables. |
| **No unlocks** | Do not grant badges, themes, or features after purchase — avoids “unlockable digital content” ambiguity and keeps restore logic trivial. |
| **Copy** | Frame as “Support development” / “Tip the developer,” not “donate” with implied tax receipt. |
| **Restore** | Consumables are not restorable; UI must not promise “Restore Purchases” for tips. A brief thank-you after purchase is enough. |
| **Analytics** | Log `tip_jar_purchase_completed` (product id only) on allowlist if tips ship — no revenue amounts in Analytics. |

---

## 2. App Store Connect

Create **Consumable** IAP products (suggested tiers — adjust before submit):

| Product ID | Display name | Suggested price (USD) |
|------------|--------------|------------------------|
| `com.jacobrozell.DartBuddy.tip.small` | Small Tip | $0.99 |
| `com.jacobrozell.DartBuddy.tip.medium` | Medium Tip | $2.99 |
| `com.jacobrozell.DartBuddy.tip.large` | Large Tip | $4.99 |

**Connect checklist:**

- [ ] Paid Applications Agreement active
- [ ] Bank / tax forms complete
- [ ] Each product: localized display name + description (“Optional tip to support Dart Buddy development.”)
- [ ] Review screenshot: Settings → About tip sheet (no external URLs)
- [ ] App privacy: declare “Purchases” if not already covered
- [ ] Pricing: same tier across primary storefronts or set per territory
- [ ] Submit IAP products **with** the app binary that implements them

---

## 3. Architecture (Dart Buddy conventions)

```
Support/StoreKit/
  TipJarProductIDs.swift      // static product id constants
  TipJarStore.swift           // @Observable / actor: load products, purchase, transaction listener
  TipJarStoreConfiguration.swift  // DEBUG: StoreKit test file name

Features/Settings/
  TipJarSheet.swift           // tier buttons, loading/error, thank-you state
  SettingsRootView.swift      // replace external Link with sheet/button when tips enabled
```

**StoreKit 2 surface:**

- `Product.products(for: TipJarProductIDs.all)` on appear
- `product.purchase()` → `VerificationResult` → `Transaction.finish()`
- `Transaction.updates` listener at app launch (same pattern as `AppDelegate` bootstrap) for interrupted purchases
- Feature flag: `ProductSurface.showsTipJar` (default `false` until Connect products approved)

**Do not** reintroduce `AppLinks.buyDeveloperCoffee` for payment. Keep property `nil`; optional redirect to marketing site without payment CTA is out of scope.

---

## 4. UI

**Placement:** Settings → About (same section as version + replay onboarding).

**Interaction:**

1. Row: “Support development” (`cup.and.saucer.fill`) — reuse or supersede `settings.support.buyCoffee` L10n keys.
2. Presents `TipJarSheet` with 3 tier buttons showing localized `displayPrice`.
3. Footer: “Optional tip to support development. Processed by Apple.”
4. Success: lightweight thank-you alert or inline checkmark; dismiss sheet.
5. Failure / cancel: non-blocking; no guilt copy.

**Accessibility:** VoiceOver labels include tier name + price; `accessibilityIdentifier` prefix `settings_tipJar_*` (new — do not reuse `settings_buyDeveloperCoffeeLink`).

**Remove when shipping:** Any `Link` to Buy Me a Coffee / Ko-fi / PayPal in app or App Store metadata.

---

## 5. Phased implementation

| Phase | Work | Exit criteria |
|-------|------|----------------|
| **0** | StoreKit Configuration file (`.storekit`) in Xcode with 3 consumables; unit tests for product id list | Configuration loads in Simulator |
| **1** | `TipJarStore` + transaction listener; no UI | Sandbox purchase in debug harness |
| **2** | `TipJarSheet` + Settings entry behind `ProductSurface.showsTipJar` | Manual purchase on device (Sandbox account) |
| **3** | Connect products + flag on in Release; localized strings via `Scripts/locale_data/` | TestFlight internal QA |
| **4** | App Review notes + privacy label update | Approved with IAP |

---

## 6. Testing

| Layer | What |
|-------|------|
| **StoreKit Testing** | Xcode scheme → StoreKit Configuration; fast UI iteration |
| **Sandbox** | Dedicated Sandbox Apple ID; verify all three tiers |
| **Unit** | `TipJarProductIDs` ordering; store error mapping; flag gating |
| **UI** | Optional smoke: open sheet, assert products visible (mock configuration in UI tests) |
| **Regression** | With flag off, About section has **no** tip row and **no** external payment URLs |

---

## 7. App Review notes (template)

> Dart Buddy includes optional consumable tips in Settings → About → Support development. Tips do not unlock features or content. The app has no subscriptions or external payment links.

---

## 8. Out of scope

- US External Purchase Link entitlement (Buy Me a Coffee in Safari)
- Tip badges, supporter themes, or “remove analytics for tippers”
- `SubscriptionStoreView` / recurring support
- Server-side receipt validation (unnecessary for consumable tips with no entitlements)

---

## 9. Open decisions (owner)

| Decision | Options |
|----------|---------|
| **Ship version** | 1.1 vs 1.2 — after stable 1.0 |
| **Tier count** | 3 (above) vs single $2.99 tip |
| **Thank-you UX** | Alert vs confetti vs silent |
| **Flag default** | Off until Connect approved (recommended) |

# Security and Privacy Specification

## 1. Purpose
Define security, privacy, and data-protection requirements for MVP and future networked features.

---

## 2. MVP Security Baseline
- Local-only persistence by default
- No ad SDKs
- No third-party tracking identifiers
- Minimal personal data (display names only)

---

## 3. Privacy Requirements
- Clear in-app privacy summary
- Explicit settings for optional diagnostics (future)
- Data reset capability with confirmation — see [`DeleteAllDataSpec.md`](DeleteAllDataSpec.md)
- No silent data export

---

## 4. Data Protection Controls
- Use iOS protected file storage defaults
- Avoid storing sensitive secrets in plain persistence
- Any future credentials/tokens stored in Keychain only

---

## 5. Event Integrity (Future Online)
- Signed command/event model
- Anti-replay via nonce/idempotency keys
- Time-window validation for command acceptance

---

## 6. Vision/Watch Considerations
- Camera frames not persisted unless user explicitly opts into diagnostics
- Watch connectivity limited to paired authenticated devices
- Provenance metadata stored for auditability without storing unnecessary raw media
- **Verified skill challenges** ([`OnlinePlaySpec.md`](OnlinePlaySpec.md) §10.4): store confidence + event metadata only; no raw video retention for verification

## 6.1 User-generated display names (online)
- Offensive-name blocklist enforced client-side (pre-online) and server-side before any cross-user display — [`OnlinePlaySpec.md`](OnlinePlaySpec.md) §10.5, [`PlayerSpec.md`](PlayerSpec.md) §4.1
- **Multilingual:** 1.x filter is English + obfuscation only; do not claim full locale coverage — [`OnlinePlaySpec.md`](OnlinePlaySpec.md) §10.5.1
- Rejected names must not appear in analytics payloads or Crashlytics breadcrumbs
- Report / moderation flows (online): [`OnlinePlaySpec.md`](OnlinePlaySpec.md) §10.6 — Firestore queue + Cloud Functions; clients never write reports directly
- Third-party text moderation (online): privacy-label and DPA review before enabling

---

## 7. Testing and Verification
- Threat modeling pass before online release
- Privacy label review before each App Store submission
- Security checklist in release gate

---

## 8. Firebase-Specific Privacy Notes
- Firebase adoption must follow `specs/FirebaseBackendAnalyticsSpec.md`.
- Enable only required Firebase products per phase.
- Re-validate App Store privacy disclosures each time a Firebase service is added.

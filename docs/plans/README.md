# Engineering plans

Long-horizon architecture and implementation plans that span multiple releases. **Active index:** [`ongoing/README.md`](../../ongoing/README.md). Authoritative **feature behavior** for custom bots lives in [`specs/CustomBotSpec.md`](../../specs/CustomBotSpec.md); these documents are the execution roadmap.

| Plan | Status | Summary |
|------|--------|---------|
| [`../../roadmap/solo-companion.md`](../../roadmap/solo-companion.md) | Draft · roadmap | Record the games; play alone or with friends. 1.2 copy, then bot stats, then a Solo shelf. 1.2 feature scope stays locked |
| [`duo-dynamic-layout-release-plan.md`](duo-dynamic-layout-release-plan.md) | Draft · proposed 1.3 | Size-class + window width for iPhone Duo and resizable iPad; drop idiom from layout |
| [`coop-mode-grouping.md`](coop-mode-grouping.md) | Phase 0–1 done · Raid shipped | Co-op catalog + Raid playable; Phase 2 extraction + a11y close-out |
| [`game-mode-families.md`](game-mode-families.md) | Approved direction · not implemented | Cricket family card + variant sheet; Mulligan/English Cricket standalone; catalog model |
| [`custom-bot-architecture-ui-plan.md`](custom-bot-architecture-ui-plan.md) | Approved direction · not fully implemented | Bot protocol stack, persistence, template resolution, phased UI |
| [`ui-screenshot-iteration-plan.md`](ui-screenshot-iteration-plan.md) | In progress | Screenshot audit fixes: layout, AXXXL, tokens, gameplay polish |
| [`swiftui-view-extraction-master-plan.md`](swiftui-view-extraction-master-plan.md) | In progress · Phases 0–7 done | Split remaining oversized SwiftUI views into child structs; match screens + history/stats open |
| [`release-build-view-decomposition-plan.md`](release-build-view-decomposition-plan.md) | Implemented (2026-06-14) | Split oversized SwiftUI views so Release whole-module builds pass without `singlefile` workaround |
| [`tier-1-scalability-refactor-plan.md`](tier-1-scalability-refactor-plan.md) | Not started · Phase 0 ready | Test fakes, lifecycle plugins, match VM core, setup config registry — reduce linear-growth hotspots |
| [`storekit-tip-jar-plan.md`](storekit-tip-jar-plan.md) | Not started · post-1.0 | Optional consumable IAP tips in Settings → About (replaces rejected external coffee link) |
| [`auto-scorer-plan.md`](auto-scorer-plan.md) | Not started · future R&D | Single-phone tip scoring: wire-confirm policy, on-device labels, then measured auto-commit. Flag stays off |

Release-scoped plans: [`../release/README.md`](../release/README.md).

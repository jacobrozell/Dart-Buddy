# Engineering plans

Long-horizon architecture and implementation plans that span multiple releases. Authoritative **feature behavior** for custom bots lives in [`specs/CustomBotSpec.md`](../../specs/CustomBotSpec.md); these documents are the execution roadmap.

| Plan | Status | Summary |
|------|--------|---------|
| [`coop-mode-grouping.md`](coop-mode-grouping.md) | Phase 0–1 done · Raid shipped | Co-op catalog + Raid playable; Phase 2 extraction + a11y close-out |
| [`game-mode-families.md`](game-mode-families.md) | Approved direction · not implemented | Cricket family card + variant sheet; Mulligan/English Cricket standalone; catalog model |
| [`custom-bot-architecture-ui-plan.md`](custom-bot-architecture-ui-plan.md) | Approved direction · not fully implemented | Bot protocol stack, persistence, template resolution, phased UI |
| [`ui-screenshot-iteration-plan.md`](ui-screenshot-iteration-plan.md) | In progress | Screenshot audit fixes: layout, AXXXL, tokens, gameplay polish |
| [`release-build-view-decomposition-plan.md`](release-build-view-decomposition-plan.md) | Approved direction · not implemented | Split oversized SwiftUI views so Release whole-module builds pass without `singlefile` workaround |

Release-scoped plans: [`../release/README.md`](../release/README.md).

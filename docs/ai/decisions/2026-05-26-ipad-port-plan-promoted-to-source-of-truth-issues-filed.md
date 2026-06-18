---
date: 2026-05-26
repo: drumrot
tags: [decision, drumrot]
---

# iPad port plan promoted to source of truth + issues filed

- Compared the two parallel planning passes ([claudes-ios-plan.md](claudes-ios-plan.md), Mac Catalyst; [codex-ios-plan.md](codex-ios-plan.md), iPad-first + iPad-on-Mac). They are ~95% identical; the only material divergence is the platform/Mac strategy. **Codex's plan wins** because it matches the locked 2026-05-21 direction; Claude's Catalyst plan would re-open a settled call.
- **Promoted Codex's plan into `docs/ai/current-plan.md`** as the canonical current plan, superseding the v0.3 card-system plan. The two planning passes are preserved as historical artifacts. Grafted from Claude's plan: the explicit Info.plist usage-description detail (`NSBluetoothAlwaysUsageDescription` / `NSLocalNetworkUsageDescription` / `NSBonjourServices`) and the "no audio-input usage description / no recording entitlement" exclusion line. **Dropped** Claude's Catalyst-only macOS sandbox entitlements (`app-sandbox`, `device.usb`, `network.client`, etc.) — they don't apply to an iPad-only target; noted for a possible v1.1 Mac/Catalyst target.
- **Filed all 41 issues** (plan IDs #20–#60) on GitHub. The repo's shared issue/PR sequence was already at #11, so GitHub assigned **#12–#52** (offset −8 from plan IDs). Crosswalk table lives at the top of `current-plan.md`; filed issue bodies express dependencies in live GitHub numbers.
- Trade-off: plan IDs in the docs (#20–#60) differ from GitHub numbers (#12–#52). Kept plan IDs in the issue table for readability and pinned the crosswalk so the two never drift.
- **Ambiguity A1 resolved:** user is already enrolled in the Apple Developer Program; App Store Connect API key + Developer ID certificates exist locally outside the repo. Never commit signing material — load into CI/TestFlight as secrets.
- **Ambiguities A2–A5 addressed (2026-05-26):**
  - A2 — audio re-synthesized in AVAudioEngine (no WAV licensing); confirms D6.
  - A3 — generate a fresh icon/asset set in the SP-808 voxel style; icon must be an original mascot, no third-party character; also closes web favicon #6.
  - A4 — portraits are AI-generated (gemini-2.5-flash-image via OpenRouter) and treated as owned, **but** the generator edits a `parodyImg` source and keeps it "recognizable as a parody," making each a derivative work. Before Phase 10: verify model commercial terms + source-image rights, retain prompts/seeds.
  - A5 — direction (not legal advice): treat drumrots as parody/derivative; original icon/brand; pre-submission content review to scrub specific trademarked characters (e.g. Skibidi); IP-counsel check on borderline names. Parody is a fact-specific copyright defense, weaker under trademark, and Apple (Guideline 5.2) can reject regardless. Weird Al *licenses* his parodies rather than relying on fair use.

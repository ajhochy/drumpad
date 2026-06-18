---
date: 2026-05-26
repo: drumrot
tags: [decision, drumrot]
---

# Native app rebranded SP808Killa → Drumrot; Skibidi scrubbed (A5)

- The implemented Xcode project/target/module/folders/Info.plist/test target were renamed **`SP808Killa` → `Drumrot`** (scheme `Drumrot`, `ios/Drumrot.xcodeproj`, `@main DrumrotApp`, `@testable import Drumrot`). User-facing display name is **`drumrot`** (`CFBundleDisplayName`); bundle id unchanged (`com.visaliacrc.drumrot`). Historical planning docs (`current-plan.md`, `codex-ios-plan.md`, `claudes-ios-plan.md`, `generated-issues/*`) still say "SP808Killa" — left as the planning record; operational docs (runbook, handoff, manual-smoke) + project-state use the live `Drumrot` name.
- Codex started the rename (renamed files on disk) but left the `project.pbxproj` + shared scheme pointing at the old name; completed here via a `SP808Killa→Drumrot` substitution. **Verified: `xcodebuild test` green (8 suites), app launches with display name "drumrot" + Bonjour key present.**
- **A5 — Skibidi card resolved:** `skibidi_tomtomlet` → `trono_tomtomlet` ("Trono Tomtomlet", 👑🥁) renamed across iOS `Drumrots.json`, web `js/drumrots.js`, asset catalog. Codex's first pass renamed labels only — the rendered art was still a drum-ified Skibidi Toilet. **Now fixed: `art/drumrots/trono_tomtomlet.webp` + its iOS imageset were regenerated as an original crowned porcelain-tom-drum design (no toilet/face/character)** via a text-to-image call (gemini-2.5-flash-image, key from the Statement Automator `.env`), and the `brainrots/OG/Skibidi_Toilet.png` source was deleted. **Decision (2026-05-26): other portraits handled reactively.** Every other portrait is a drum-ified meme source too, but the user chose NOT to pre-emptively review/redraw them — ship as-is and only address specific portraits **if Apple App Review flags them**. Skibidi was fixed because it's a clear named-trademark case; the rest are "Italian brainrot" genre pastiche (lower risk). Do not re-raise a blanket content review. Also added `ITSAppUsesNonExemptEncryption=false` (export-compliance) and BpmStepper a11y labels.
- **CI recovery:** `BuildView.swift` was missing from git after the Phase 7 commit (built locally but a clean CI checkout would fail); committed separately. Lesson: confirm `git status` shows no untracked source after each commit, not just a green local build.

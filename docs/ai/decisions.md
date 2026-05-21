# Decisions

## 2026-05-21 — Virtual MIDI test source over mocks (PR #10)
- Chose `node-midi` virtual port over mocking `navigator.requestMIDIAccess`. A real CoreMIDI/ALSA-visible port exercises the full receive chain — enumeration, dropdown rendering, channel decoding in `js/midi-device.js`, GM-map → lane translation. Mocks would only have tested the JS path, not the OS/browser boundary.
- Trade-off: pulls in a native dep (`midi` npm package, RtMIDI binding). Devs on Linux need `libasound2-dev`; Windows can't create virtual ports via this binding (documented in README; loopMIDI is the workaround).
- Kept `package.json` minimal: `midi` is the only dep, no lockfile committed, repo stays "static site you can open in a browser" first, "dev tools available if you want them" second.

## 2026-05-21 — Portrait-rendering regression (PR #8)
- User caught blank-portrait regression after PR #5 merged: revealed cards showed chrome but no character art.
- Cause: `loading="lazy"` on the img + `content-visibility: auto` on `.cell` interacted badly inside the opacity-0 reveal overlay — image element existed but never entered a paintable state.
- Decision: drop `loading="lazy"` and `content-visibility: auto` from the card path entirely. Always emit emoji creature behind the image as a defensive z-index-0 fallback. HTTP 200 is no longer accepted as evidence the portrait is visible — pixel checks are now required in `docs/testing/manual-smoke.md`.
- Trade-off: Pi-perf hooks (lazy + content-visibility) gone. If perf regresses on actual hardware, re-add ONLY on Drops-grid cells, never on reveal-popup cards. The blank-portrait failure mode is worse than slower scrolling.

## 2026-05-21 — v0.3 card system merged
- PR #5 squash-merged to `main` (`f0927d31`). Issues #1–#4 closed.
- Three commits in the run branch: bootstrap docs, `#1+#3` (data + renderer in one file), `#2+#4` (CSS chrome + polish in CSS/HTML/README).
- Smoke verified by Playwright + computer-control before merge; favicon 404 spun out as #6. Portrait regression caught after merge — see PR #8 entry above.

## 2026-05-20 — Drumrot v0.3 adoption
- Primary key stays `id` (snake_case). No `slug`. Maps 1:1 to image filename.
- Tier key renamed `drumrot_god` → `god` everywhere.
- Emoji field renamed `art` → `emoji`.
- Stats remain numeric in data. `∞` / `MAX` are render-time conventions: bpm/groove `99` → `∞` only for OG; power `99` → `MAX` for `god` or `og`.
- Inline `<symbol>` SVG sprite from v0.3 is intentionally skipped — use `drumrotImg` or emoji fallback only.
- v0.3 wording (name/sub/flavor) wins on every conflict with the legacy roster.

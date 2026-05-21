# Project state

## Current focus
Idle — Drumrot v0.3 card system shipped to `main`.

## Branch
`main`. Last merges: PR #5 (v0.3 card system, `f0927d31`) and PR #8 (portrait-rendering fix, `5fff600`).

## Recently completed (2026-05-20 → 2026-05-21)
- **PR #5** — Issues #1–#4, v0.3 card system:
  - #1 DRUMROTS migrated to v0.3 schema (`drumrot_god` → `god`, `art` → `emoji`, v0.3 wording, numeric stats with 99 sentinel).
  - #2 `css/cards.css` ports v0.3 card chrome; `index.html` head adds IBM Plex Mono + `cards.css`.
  - #3 `renderDrumrotCard` rewritten for v0.3 markup, OG `∞/MAX` rules, locked variant, grapheme emoji fallback.
  - #4 Dead `.dc-*` CSS removed, reveal entry animation, OG holofoil hover sweep, `prefers-reduced-motion` guards, README docs.
- **PR #8** — Post-merge regression: revealed portraits were blank. Cause: `loading="lazy"` + `content-visibility: auto` interaction inside the opacity-0 reveal overlay. Fix: drop both, plus always emit emoji creature behind the image as defensive fallback. Smoke contract tightened to require pixel painting (not just HTTP 200). Postmortem `.agent-stack/postmortems/2026-05-21-portrait-blank-after-pr5.json`.

## In progress
n/a

## Risks / known gaps
- **#6 (favicon 404)** — open follow-up filed from PR #5 smoke. Single console error on hard load; not user-facing.
- **Pi hardware perf check** — `content-visibility: auto` was removed in PR #8 to fix the blank-portrait regression. The Pi `≥30 fps` gate has not been re-verified after that removal. If perf regresses on the actual Pi, reintroduce `content-visibility: auto` only on the Drops grid cells (not on reveal-popup cards) and re-check.
- **Playwright smoke** still does not assert pixel painting on portraits — only the manual smoke checklist does. Worth adding a Playwright spec that asserts `naturalWidth > 0` and `rect.width > 0` on `.portrait-img` after the reveal animation.

## Next step
When ready, pick up #6 (favicon) or strengthen the Playwright smoke to catch pixel-paint regressions. No active workflow run.

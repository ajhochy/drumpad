# Project state

## Current focus
Idle — Drumrot v0.3 card system shipped to `main`.

## Branch
`main`. Last run branch `workflow/run-2026-05-20` merged via PR #5 (squash, commit `f0927d31`) and deleted.

## Recently completed (2026-05-20 → 2026-05-21)
- Issues #1–#4 (v0.3 card system) merged to `main`:
  - #1 — DRUMROTS migrated to v0.3 schema (`drumrot_god` → `god`, `art` → `emoji`, v0.3 wording, numeric stats with 99 sentinel).
  - #2 — `css/cards.css` ports v0.3 card chrome; `index.html` head adds IBM Plex Mono + `cards.css`.
  - #3 — `renderDrumrotCard` rewritten for v0.3 markup, OG `∞/MAX` rules, locked variant, grapheme emoji fallback.
  - #4 — Dead `.dc-*` CSS removed, reveal entry animation, OG holofoil hover sweep, `prefers-reduced-motion` guards, Pi-perf hooks (`content-visibility: auto`, lazy images), README docs.
- Playwright + computer-control smoke: all acceptance criteria PASS. Drops scroll ~94 fps locally; portrait assets all 200; reveal/OG/god-tier display rules verified.

## In progress
n/a

## Risks / known gaps
- **#6 (favicon 404)** — open follow-up filed from PR #5 smoke. Single console error on hard load; not user-facing.
- **Pi hardware perf check** — code hooks are in place but ≥30 fps gate on the physical Pi has not been re-verified on hardware post-merge. Procedure documented in `docs/testing/manual-smoke.md`.

## Next step
When ready, pick up #6 (favicon) or any newly filed work. No active workflow run.

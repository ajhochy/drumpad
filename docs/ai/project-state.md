# Project state

## Current focus
Workflow run 2026-05-20: implement issues #1–#4 — migrate Drumrot card system to v0.3 schema, chrome, and renderer; polish pass.

## Branch
`workflow/run-2026-05-20` → PR to `main` (manual merge).

## Recently completed
- Card v0.3 schema migration (issue #1)
- v0.3 chrome CSS port (issue #2)
- renderDrumrotCard rewrite (issue #3)
- Polish pass (issue #4)

## In progress
n/a

## Risks / known gaps
- Pi performance check (issue #4 task 5) requires actual Pi hardware — not exercised by an agent. Tagged as manual smoke item.
- No automated test runner; verification is by `node` import-shape check + manual browser smoke.

## Next step
Manual smoke + merge.

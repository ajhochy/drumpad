# Agent guide — drumrot / SP-808 KILLA

Static web app: vanilla JS modules, no build step, no test runner. Opened directly via `index.html`.

## First files to read
- `index.html` — shell, tabs, reveal overlay.
- `js/main.js` — bootstraps modules.
- `js/drumrots.js` — collection roster, tier config, drop roll, card renderer.
- `css/main.css` — historic stylesheet (chassis + cards).
- `css/cards.css` — v0.3 card chrome (post-issue-#2).

## Data safety
- Do not commit anything in `art/.DS_Store`, `.DS_Store`, generated images outside `art/drumrots/` and `brainrots/`, or any user data.

## Testing
- No automated test runner. Validation is a smoke pass: open `index.html` in a browser, switch tabs, trigger a drop via achievement, check the Drops tab.
- For data shape changes, sanity-check with `node --input-type=module -e "import('./js/drumrots.js').then(m => console.log(m.DRUMROTS.length))"`.

## Git / merge
- Feature branch per workflow run (`workflow/run-YYYY-MM-DD`). Never commit to `main` directly.
- Merge is a manual human step after manual smoke.

## Memory updates
After verified work, update `docs/ai/project-state.md` with what changed and the current status.

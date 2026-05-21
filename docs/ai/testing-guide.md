# Testing guide

No automated test runner is configured.

## Quick checks
- Shape sanity for the roster module:
  ```bash
  node --input-type=module -e "import('./js/drumrots.js').then(m => console.log('count=', m.DRUMROTS.length, 'sample=', m.DRUMROTS[0]))"
  ```
- Lint: not configured.

## Manual smoke
1. Open `index.html` in a modern browser.
2. Confirm all tabs load without console errors.
3. Click Drops — collection grid renders 31 cells (locked + collected).
4. Trigger an achievement (or fake it via DevTools by calling `showDrumrotReveal`).
5. Observe v0.3 card chrome: screws, banner with tier label + `#NNN` number, portrait image, stats footer.
6. OG draw shows `∞ / ∞ / MAX` stats and `#NNN/OG` number.

## Pi target
Performance must be verified on hardware (Pi 4 or earlier). Not exercised by automated agents.

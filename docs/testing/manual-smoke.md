# Manual smoke checklist

Open `index.html` directly in a modern browser.

- [ ] Page loads without console errors.
- [ ] Tabs Play / Library / Progress / Build / Drops all switch cleanly.
- [ ] Drops tab renders 31 cells. Uncollected cells show the locked variant (`???`).
- [ ] Force-show a card: `import('./js/drumrots.js').then(m => m.showDrumrotReveal(m.DRUMROTS[0], 'common', 'first_hit'))` in DevTools — card animates in.
- [ ] Force an OG card: replace `'common'` with `'og'` and pick an OG entry. Stats display `∞ / ∞ / MAX`. Banner reads `#024/OG`.
- [ ] `tamburino_cosmico` (god tier) — power displays as `MAX`.
- [ ] Hovering an OG card shows the holofoil sweep. `prefers-reduced-motion` disables animation.
- [ ] No 404s on portrait images in the network tab.
- [ ] Pi target: collection scrolls at ≥30 fps across all 31 cards. (Verify on actual hardware.)

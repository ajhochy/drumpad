# Manual smoke checklist

> Two surfaces: the **web app** (this top section) and the **native iPadOS app**
> (bottom section, added 2026-05-26). The web app is frozen at v0.3.

## Web app

Open `index.html` directly in a modern browser.

- [ ] Page loads without console errors.
- [ ] Tabs Play / Library / Progress / Build / Drops all switch cleanly.
- [ ] Drops tab renders 31 cells. Uncollected cells show the locked variant (`???`).
- [ ] Force-show a card: `import('./js/drumrots.js').then(m => m.showDrumrotReveal(m.DRUMROTS[0], 'common', 'first_hit'))` in DevTools — card animates in.
- [ ] Force an OG card: replace `'common'` with `'og'` and pick an OG entry. Stats display `∞ / ∞ / MAX`. Banner reads `#024/OG`.
- [ ] `tamburino_cosmico` (god tier) — power displays as `MAX`.
- [ ] Hovering an OG card shows the holofoil sweep. `prefers-reduced-motion` disables animation.
- [ ] No 404s on portrait images in the network tab.
- [ ] **Portrait pixel check** (not just network 200): inspect a reveal-popup card with DevTools, confirm `img.portrait-img` has `getBoundingClientRect().width > 0`, `complete === true`, `naturalWidth > 0`. A 200 response does **not** prove the image was painted. Repeat for at least one Drops-grid card.
- [ ] Pi target: collection scrolls at ≥30 fps across all 31 cards. (Verify on actual hardware.)

## MIDI input loopback (optional)

In a second terminal:
```bash
npm run midi:pulse
```
Then in the running app:
- [ ] Library / MIDI dropdown lists `Drumrot Test Source`.
- [ ] Selecting it on Play tab causes the highway pads to light on each pulse hit (backbeat kick on 1 & 3, snare on 2 & 4, hi-hat sixteenths).
- [ ] Stopping the script (`Ctrl-C`) removes the port from the dropdown after the next refresh.

---

# Native iPadOS app (SP-808 KILLA)

Run on a real iPad (primary) and, where available, the iPad app on an Apple
silicon Mac. The simulator covers UI/logic but **not** audio latency, MIDI
hardware, BLE, or VoiceOver — those rows are device-only.

Launch (dev): open `ios/SP808Killa.xcodeproj`, scheme `SP808Killa`, run on an
iPad (A16+) sim or a connected device. Debug args: `--play`, `--demo`,
`--reveal`, `--library/--progress/--build/--drops`.

## Shell & navigation
- [ ] Launches landscape-locked; 5 tabs switch; gear opens Settings.
- [ ] Hardware keyboard: Cmd+1..5 tabs, Cmd+, settings.

## Play
- [ ] Library lesson loads into Play and auto-starts; count-in plays 8 clicks.
- [ ] Notes scroll the highway to the strike line; pad tap plays the right voice (device: latency feels tight, ≤~10ms).
- [ ] Hits score perfect/great/good; score/combo/accuracy update; loop saves passes; non-loop finishes.
- [ ] Space/Cmd+R restart, L loop, C click.

## MIDI (device-only)
- [ ] USB-C/camera-kit controller fires highway pads; MIDI LED pulses.
- [ ] Network MIDI source appears in Settings → MIDI and drives the highway.
- [ ] BLE "Pair Bluetooth MIDI" pairs + registers notes; reconnects after relaunch.
- [ ] GM mapping correct (kick 36 / snare 38 / hihat 42 / crash 49 / tom 45 / ride 51).

## Library / Progress / Build
- [ ] Library shows stars/high + New/Played after playing.
- [ ] Import `.mid` → custom lesson loads; SMPTE file shows an error.
- [ ] Progress: streak, 14-day calendar, sessions/best/accuracy, achievement grid update.
- [ ] Build: 16/32 grid → Load into Play creates "My Groove"; Export `.mid` shares a file; Creator/Coach unlock.

## Drops / achievements
- [ ] Achievement unlock → toast → drop reveal (NEW/UPGRADED/FIRST OG).
- [ ] Drops shows N/31, locked `???`, collected portraits; OG shows ∞/MAX.

## Accessibility (device-only)
- [ ] VoiceOver reads cards/pads/controls; logical order.
- [ ] Reduce Motion cross-fades reveal/pad animations; Dynamic Type (AX3) no clipping.

## iPad app on Apple silicon Mac (where available)
- [ ] Runs as the iPad app; landscape intact; audio + shortcuts behave; MIDI verified separately.

> After every native manual smoke (pass or fail), run `failure-postmortem`.

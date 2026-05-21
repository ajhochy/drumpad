# Architecture

Static web app served from disk. ES modules; no bundler.

- `index.html` defines tabs (Play, Library, Progress, Build, Drops) and a global drumrot-reveal overlay.
- `js/main.js` wires the tab system and module bootstrap.
- `js/drumrots.js` owns the collection lifecycle: roster, drop roll (5% OG flat bonus + tier weight table), localStorage persistence, card markup, drops grid, reveal queue.
- Other modules handle the drum trainer proper (audio, MIDI, scoring, highway).

External deps: Google Fonts (Space Grotesk, Major Mono Display, IBM Plex Mono, Permanent Marker, Special Elite, Bungee, Inter); Tabler Icons CDN.

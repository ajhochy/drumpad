---
date: 2026-05-21
repo: drumrot
tags: [decision, drumrot]
---

# Portrait-rendering regression (PR #8)

- User caught blank-portrait regression after PR #5 merged: revealed cards showed chrome but no character art.
- Cause: `loading="lazy"` on the img + `content-visibility: auto` on `.cell` interacted badly inside the opacity-0 reveal overlay — image element existed but never entered a paintable state.
- Decision: drop `loading="lazy"` and `content-visibility: auto` from the card path entirely. Always emit emoji creature behind the image as a defensive z-index-0 fallback. HTTP 200 is no longer accepted as evidence the portrait is visible — pixel checks are now required in `docs/testing/manual-smoke.md`.
- Trade-off: Pi-perf hooks (lazy + content-visibility) gone. If perf regresses on actual hardware, re-add ONLY on Drops-grid cells, never on reveal-popup cards. The blank-portrait failure mode is worse than slower scrolling.

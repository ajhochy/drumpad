# Current plan — Drumrot v0.3 card system

## Goal
Move the Drumrot collection from the legacy in-house card to the v0.3 chrome that ships in `/Users/ajhochhalter/Downloads/roster-v0.3/SP-808 KILLA Roster.html`. Keep data ergonomics (numeric stats, snake_case ids, preserved parody fields) while adopting v0.3 visuals.

## Phases (= GitHub issues)
1. Issue #1 — Migrate DRUMROTS data to v0.3 schema (copy/stats/tier key).
2. Issue #2 — Port v0.3 card chrome CSS into the live app (`css/cards.css` + font links).
3. Issue #3 — Rewrite `renderDrumrotCard()` to emit v0.3 markup.
4. Issue #4 — Polish: dead CSS, drop transitions, OG holofoil, Pi perf, README.

## Validation
- Module import returns 31 entries with the v0.3 fields.
- Browser smoke shows the new card across all tiers, including OG and locked variants.
- Pi perf check is a manual gate.

## Non-goals
- Adding new drumrots.
- Generating new images.
- Touching `rollDrumrot` weights or OG bonus.
- Inline SVG sprite fallback (skipped entirely).

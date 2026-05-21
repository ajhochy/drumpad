# Decisions

## 2026-05-21 — v0.3 card system merged
- PR #5 squash-merged to `main` (`f0927d31`). Issues #1–#4 closed.
- Three commits in the run branch: bootstrap docs, `#1+#3` (data + renderer in one file), `#2+#4` (CSS chrome + polish in CSS/HTML/README).
- Smoke verified by Playwright + computer-control before merge; favicon 404 spun out as #6.

## 2026-05-20 — Drumrot v0.3 adoption
- Primary key stays `id` (snake_case). No `slug`. Maps 1:1 to image filename.
- Tier key renamed `drumrot_god` → `god` everywhere.
- Emoji field renamed `art` → `emoji`.
- Stats remain numeric in data. `∞` / `MAX` are render-time conventions: bpm/groove `99` → `∞` only for OG; power `99` → `MAX` for `god` or `og`.
- Inline `<symbol>` SVG sprite from v0.3 is intentionally skipped — use `drumrotImg` or emoji fallback only.
- v0.3 wording (name/sub/flavor) wins on every conflict with the legacy roster.

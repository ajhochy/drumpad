---
date: 2026-05-20
repo: drumrot
tags: [decision, drumrot]
---

# Drumrot v0.3 adoption

- Primary key stays `id` (snake_case). No `slug`. Maps 1:1 to image filename.
- Tier key renamed `drumrot_god` → `god` everywhere.
- Emoji field renamed `art` → `emoji`.
- Stats remain numeric in data. `∞` / `MAX` are render-time conventions: bpm/groove `99` → `∞` only for OG; power `99` → `MAX` for `god` or `og`.
- Inline `<symbol>` SVG sprite from v0.3 is intentionally skipped — use `drumrotImg` or emoji fallback only.
- v0.3 wording (name/sub/flavor) wins on every conflict with the legacy roster.

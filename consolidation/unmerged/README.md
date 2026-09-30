# Unmerged from the 2026-09-29 consolidation

## wip-drumpad-work-release-ios16-only-docs.patch
Single WIP-snapshot commit (0be3745) taken from the `~/Documents/drumpad-work` clone, whose checkout is
`release/ios16-only` (the permanent iOS 16 fork, never merged into `main` or this branch). It holds
uncommitted edits made on that fork after its last push:

- `docs/ai/decisions.md` — 2026-06-01 decision: snapshot tests advisory on `release/ios16-only` (PR #76)
- `docs/ai/project-state.md` — PR #76 CI-green note and the four-fix repair loop
- `ios/build/ExportOptions.plist` — deletion of a stale tracked build artifact (same deletion as on mega)

Not folded because it sits on the ios16 lineage. To keep the docs, apply on `release/ios16-only`:

    git checkout release/ios16-only && git am consolidation/unmerged/wip-drumpad-work-release-ios16-only-docs.patch

# Reduced Motion + Dynamic Type pass

> Plan ID #52 · GitHub #44 · Phase 9

## Goal
Honor `accessibilityReduceMotion`; cross-fades replace motion; verify AX3 text scaling end-to-end

## Likely files
- (all feature views)

## Acceptance criteria / tests
- [ ] Manual: toggle Reduce Motion → animations cross-fade; toggle AX3 → no clipping

## Dependencies
Depends on: #43

## Notes
- Manual merge only; branch per workflow run.
- Data safety: do not commit `.DS_Store`, Xcode user state, derived data, signing files, or generated images outside the asset catalog.

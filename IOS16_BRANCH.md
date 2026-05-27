# ⚠️ iOS 16 compatibility branch — DO NOT MERGE TO MAIN

This branch (`release/ios16-only`) is a **parallel, long-lived build** of drumrot
for older iPads that cannot run iPadOS 17. **It is intentionally divergent from
`main` and must never be merged.**

## Why a parallel branch?

The primary App Store build (`main`) uses **SwiftData**, which is iOS 17+ only.
Older iPads (iPad mini 4, iPad 5th gen, iPad Pro 9.7", iPad Pro 10.5", iPad
6th gen, iPad Air 3rd gen, iPad Pro 12.9" 1st/2nd gen) cap out at iOS 16.x and
cannot run SwiftData at runtime.

To support those devices we forked off `main` and replaced the entire
persistence layer with a `UserDefaults`-backed Codable store
(`Drumrot/Data/PersistenceStore.swift`). The deployment target was lowered
from 17.0 to 16.6.

This is **not** a feature in progress. It is a separate distribution track
for legacy hardware.

## What's different from `main`

| | `main` | `release/ios16-only` |
|---|---|---|
| Deployment target | iOS 17.0 | iOS 16.6 |
| Persistence | SwiftData (`@Model`, `@Query`, `ModelContainer`) | `PersistenceStore` (Codable + `UserDefaults`) |
| Data models | `@Model` classes (reference types) | Codable structs |
| Data files | `Data/AppModelContainer.swift`, `Data/AppSettings.swift`, `Data/PersistenceService.swift`, `Data/Models/PersistenceModels.swift` | `Data/PersistenceStore.swift` (single file) |
| Wiring | `.modelContainer(...)` + `@Environment(\.modelContext)` | `.environmentObject(PersistenceStore)` |
| `onChange(of:)` | iOS-17 two-param closure | iOS-16 single-param closure |
| `Text.foregroundStyle` | iOS-17 (used) | iOS-16 `foregroundColor` (used on Text concatenations) |
| Storage scope | App Group / SwiftData store | `UserDefaults.standard` (same set of keys mirroring `localStorage`) |

User data does **not** sync between the two builds. They use different storage
backends entirely.

## Branch policy

- **Never `git merge` this into `main`** — the SwiftData removal would
  regress the primary App Store build.
- Bug fixes that apply to both branches should be **landed on `main` first**,
  then **cherry-picked** here (avoiding the SwiftData call sites). Always
  one-way: main → here.
- New features should land on `main`. They flow here only if they don't
  require iOS 17 APIs, via cherry-pick.
- TestFlight uploads from this branch must always use a build number
  ≥ the latest from any branch — App Store Connect uses a single shared
  build-number namespace per app record.

## TestFlight history (this branch)

| Build | Date | Delivery UUID | Notes |
|---|---|---|---|
| 2 | 2026-05-27 | `a579f25c-7ffb-44a1-972a-09df147821ff` | First iOS 16 build. PersistenceStore refactor. |

(Build 1 is the iOS 17 build from `workflow/run-2026-05-27`.)

## If you found this branch via the GitHub branches list

You're probably looking for **`main`** instead. This branch exists only to
serve older hardware and is not the canonical drumrot source.

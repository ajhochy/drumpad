# TestFlight External Testers + Final Smoke (Issue #52)

## Status
Build 1 has been uploaded to TestFlight. This guide covers the remaining
steps to complete external testing acceptance criteria.

## Step 1: Enable External Testing group
1. In App Store Connect → TestFlight → External Testing.
2. Click **+** to create a group (e.g. "External Beta").
3. Add the uploaded build to the group.
4. Submit for Beta App Review (required for external testers — usually 24–48 h).

## Step 2: Add ≥3 external testers
Option A — **Public Link** (simplest):
1. In the external group settings, enable "Enable Public Link".
2. Copy the link and share it with 3+ testers.
3. They install TestFlight, tap the link, download the build.

Option B — **Manual invite**:
1. Click **+** next to Testers.
2. Enter each tester's email address.
3. They receive an email invitation.

## Step 3: Smoke test checklist
Each tester should confirm the following on a physical iPad:

- [ ] App installs and launches without crash
- [ ] Play tab: a lesson auto-loads; tapping pads produces sound
- [ ] Audio latency feels < 100 ms on wired headphones
- [ ] Library tab: built-in lessons visible; tap a card → loads into Play
- [ ] Builder tab: toggle a few step cells; tap Load into Play → Play opens
- [ ] Drops tab: collection visible; drumrot cards render correctly
- [ ] Progress tab: streak calendar renders; achievements listed
- [ ] Settings: audio latency offset slider moves and persists across relaunch

## Step 4: Collect smoke notes
Ask each tester to note:
- Any crashes (include device model + iOS version)
- Any audio dropout or latency issues
- Any layout problems on their iPad size

## Acceptance criteria checklist (Issue #52)
- [ ] External testing group created in App Store Connect
- [ ] Build submitted for and cleared Beta App Review
- [ ] ≥3 external testers have completed a session (session count visible in TestFlight)
- [ ] No P0/P1 bugs reported by testers
- [ ] Smoke notes documented in `docs/testing/smoke-notes.md`

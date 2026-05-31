# App Store Screenshots + 30 s Preview Guide (Issue #51)

## Status
App Store Connect record is created and build 1 is uploaded. This guide
covers the remaining steps to reach "Ready for Review" state.

## Required screenshot sizes
Apple requires screenshots for each device class you target. For an iPad-only
app (TARGETED_DEVICE_FAMILY = 2) the required sizes are:

| Device class           | Size (pt)        | Scale | Required |
|------------------------|------------------|-------|----------|
| iPad 12.9" (6th gen)   | 2048 × 2732 px   | @2x   | Yes      |
| iPad 12.9" (2nd gen)   | 2048 × 2732 px   | @2x   | Yes      |
| iPad Pro 11"           | 1668 × 2388 px   | @2x   | Yes      |

You need **4–6 screenshots per device class** showing key features.

## Recommended screenshot sequence
1. **Play screen in action** — highway active, combo counter non-zero, pads visible.
2. **Library tab** — grid of lesson cards showing BPM + star badges.
3. **Builder tab** — sequencer grid with a filled pattern.
4. **Drops tab** — collection crates with an OG card partially visible.
5. **Progress tab** — streak calendar + achievement tiles (some unlocked).
6. **(Optional)** Settings pane showing the audio-latency offset slider.

## Capture workflow (Simulator)
```bash
# Boot simulator
xcrun simctl boot "iPad Pro 11-inch (M4)"

# Open the app, navigate to the desired screen, then capture:
xcrun simctl io booted screenshot ~/Desktop/drumrot-play.png
```

Or use Xcode's **Window > Devices and Simulators > Take Screenshot** button.

## 30-second app preview video
- Record at 1080p (Simulator > Video Recording or QuickTime Player on device).
- Show: start the app → Play tab auto-starts a groove → hit a few pads →
  combo counter climbs → lesson completes → drumrot drop reveal.
- Total: 30 s maximum.
- Export as `.m4v` (H.264, no letterboxing, no device chrome).

## Uploading in App Store Connect
1. Log in to appstoreconnect.apple.com.
2. My Apps → drumrot → App Store → iPad (set version as needed).
3. Drag-and-drop screenshots into each device slot.
4. Upload the `.m4v` preview in the "App Preview" slot.
5. Click **Save**, then **Add for Review** → submit.

## Acceptance criteria checklist (Issue #51)
- [ ] 4–6 screenshots uploaded for iPad 12.9" Gen 6 slot
- [ ] 4–6 screenshots uploaded for iPad 12.9" Gen 2 slot
- [ ] 4–6 screenshots uploaded for iPad Pro 11" slot
- [ ] 30 s preview video uploaded (at least one device class)
- [ ] All text metadata (description, keywords, support URL) filled in
- [ ] Record reaches "Ready for Review" state in App Store Connect

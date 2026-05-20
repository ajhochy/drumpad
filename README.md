# SP-808 KILLA — Drum Lesson Trainer

A falling-note drum lesson trainer for Raspberry Pi, running in Chromium via a Python HTTP server.

## Requirements

- Raspberry Pi (any model with a desktop environment)
- Chromium browser
- Python 3
- Optional: USB MIDI drum controller

## Setup

```bash
git clone <repo-url> edrum-lessons
cd edrum-lessons
sudo bash scripts/install.sh
sudo reboot
```

On reboot, the app launches automatically in Chromium kiosk mode.

## Manual start

```bash
bash scripts/start.sh
```

Then open `http://localhost:8080` in any browser.

## Keyboard controls

| Key | Drum |
|-----|------|
| A   | Crash |
| S   | Hi-Hat |
| D   | Snare |
| F   | Kick |
| J   | Tom |
| K   | Ride |
| Space | Play / Pause |

## Features

- 8 built-in lessons (Rock, Disco, Hip-Hop, Jazz, Punk, Funk, and more)
- Falling-note highway with hit detection and scoring
- Combo + streak system
- Metronome click with BPM control
- Loop mode
- Web MIDI API support for hardware drum pads
- **Library tab**: browse all lessons, load MIDI files as custom lessons
- **Progress tab**: session history, badges, calendar heatmap
- **Build tab**: 16/32-step pattern editor with MIDI export

## Adding MIDI beats

Drop `.mid` files into `data/beats/` or use the **Load MIDI File** button in the Library tab. The parser reads Type 0 and Type 1 MIDI files, maps GM drum notes to lanes, and uses the app BPM for playback timing.

## Build tab

Use the pattern editor to compose beats, then:
- **Save MIDI** — downloads a `.mid` file of the current pattern
- **Load into Player** — sends the pattern directly to the Play tab

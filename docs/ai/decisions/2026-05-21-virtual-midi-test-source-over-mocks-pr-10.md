---
date: 2026-05-21
repo: drumrot
tags: [decision, drumrot]
---

# Virtual MIDI test source over mocks (PR #10)

- Chose `node-midi` virtual port over mocking `navigator.requestMIDIAccess`. A real CoreMIDI/ALSA-visible port exercises the full receive chain — enumeration, dropdown rendering, channel decoding in `js/midi-device.js`, GM-map → lane translation. Mocks would only have tested the JS path, not the OS/browser boundary.
- Trade-off: pulls in a native dep (`midi` npm package, RtMIDI binding). Devs on Linux need `libasound2-dev`; Windows can't create virtual ports via this binding (documented in README; loopMIDI is the workaround).
- Kept `package.json` minimal: `midi` is the only dep, no lockfile committed, repo stays "static site you can open in a browser" first, "dev tools available if you want them" second.

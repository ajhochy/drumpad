#!/usr/bin/env node
// =============================================================================
// midi-pulse.mjs — virtual MIDI source for testing the app's MIDI input path.
//
// Opens an OS-visible virtual MIDI output port. Chrome's Web MIDI API
// enumerates it like any USB drum controller, and the app's Library → MIDI
// dropdown picks it up. Sends a kick/snare/hi-hat groove at a configurable
// BPM so you can verify the highway responds.
//
// Usage:
//   npm install                              # one-time, installs `midi` native dep
//   node scripts/midi-pulse.mjs              # default 90 BPM, basic backbeat
//   BPM=120 node scripts/midi-pulse.mjs      # custom tempo
//   PORT_NAME='My Test Source' node ...      # custom port name
//   PATTERN=fourfloor node ...               # different pattern
//
// Ctrl-C to stop. The virtual port disappears when the process exits.
//
// macOS: works out of the box (CoreMIDI).
// Linux: needs ALSA. `apt install libasound2-dev` before `npm install`.
// Windows: virtual ports not supported by the underlying RtMIDI on Windows;
// use loopMIDI or a similar tool instead.
// =============================================================================

import { createRequire } from 'node:module';
const require = createRequire(import.meta.url);

let midi;
try {
  midi = require('midi');
} catch (e) {
  console.error('FAIL: the `midi` package is not installed.');
  console.error('Run `npm install` from the repo root, then re-run this script.');
  process.exit(2);
}

const portName = process.env.PORT_NAME || 'Drumrot Test Source';
const bpm = Number(process.env.BPM || 90);
const pattern = process.env.PATTERN || 'backbeat';

if (!Number.isFinite(bpm) || bpm < 30 || bpm > 240) {
  console.error(`FAIL: BPM must be between 30 and 240 (got ${process.env.BPM})`);
  process.exit(2);
}

// GM drum notes (channel 10 is conventional; the app accepts any channel).
const NOTE = {
  kick: 36, snare: 38, closedHat: 42, openHat: 46,
  ride: 51, crash: 49, lowTom: 41, midTom: 45, highTom: 48,
};

// 16-step patterns. Each entry is { step: 0–15, note: NOTE.*, vel: 1–127 }.
const PATTERNS = {
  backbeat: [
    { step: 0,  note: NOTE.kick,      vel: 110 },
    { step: 0,  note: NOTE.closedHat, vel: 80  },
    { step: 2,  note: NOTE.closedHat, vel: 70  },
    { step: 4,  note: NOTE.snare,     vel: 105 },
    { step: 4,  note: NOTE.closedHat, vel: 80  },
    { step: 6,  note: NOTE.closedHat, vel: 70  },
    { step: 8,  note: NOTE.kick,      vel: 110 },
    { step: 8,  note: NOTE.closedHat, vel: 80  },
    { step: 10, note: NOTE.closedHat, vel: 70  },
    { step: 12, note: NOTE.snare,     vel: 105 },
    { step: 12, note: NOTE.closedHat, vel: 80  },
    { step: 14, note: NOTE.closedHat, vel: 70  },
  ],
  fourfloor: Array.from({ length: 8 }, (_, i) => [
    { step: i * 2,     note: NOTE.kick,      vel: 110 },
    { step: i * 2,     note: NOTE.closedHat, vel: 75  },
  ]).flat(),
  fills: [
    { step: 0,  note: NOTE.kick,    vel: 110 },
    { step: 4,  note: NOTE.snare,   vel: 105 },
    { step: 8,  note: NOTE.kick,    vel: 110 },
    { step: 12, note: NOTE.snare,   vel: 105 },
    { step: 13, note: NOTE.lowTom,  vel: 100 },
    { step: 14, note: NOTE.midTom,  vel: 100 },
    { step: 15, note: NOTE.highTom, vel: 100 },
  ],
  pulse: Array.from({ length: 16 }, (_, i) => ({
    step: i, note: NOTE.kick, vel: 100,
  })),
};

const events = PATTERNS[pattern];
if (!events) {
  console.error(`FAIL: unknown pattern "${pattern}". Available: ${Object.keys(PATTERNS).join(', ')}`);
  process.exit(2);
}

const output = new midi.Output();
try {
  output.openVirtualPort(portName);
} catch (e) {
  console.error(`FAIL: could not open virtual MIDI port: ${e.message}`);
  console.error('On Linux this usually means libasound2 is missing. On Windows virtual ports are not supported by node-midi.');
  process.exit(3);
}

// Beat math: 16 steps per bar = sixteenth notes. At BPM, a quarter = 60/BPM s,
// so a sixteenth = 60/BPM/4 s = 15/BPM s.
const stepMs = (15 / bpm) * 1000;
const noteOnMs = stepMs * 0.6; // gate length

// Channel 10 (index 9) for GM drums. Status byte 0x99 = note-on ch 10.
const NOTE_ON = 0x99;
const NOTE_OFF = 0x89;

console.log(`✓ virtual MIDI port open: "${portName}"`);
console.log(`  bpm=${bpm}  pattern=${pattern}  step=${stepMs.toFixed(1)}ms  events/bar=${events.length}`);
console.log(`  open the app, Library → MIDI dropdown should show this port.`);
console.log(`  Ctrl-C to stop.`);

let step = 0;
let beats = 0;
const timer = setInterval(() => {
  for (const ev of events) {
    if (ev.step !== step) continue;
    output.sendMessage([NOTE_ON, ev.note, ev.vel]);
    setTimeout(() => output.sendMessage([NOTE_OFF, ev.note, 0]), noteOnMs);
  }
  step = (step + 1) % 16;
  if (step === 0) {
    beats++;
    if (beats % 4 === 0) process.stdout.write(`. bar ${beats / 4}\n`);
  }
}, stepMs);

function shutdown() {
  clearInterval(timer);
  // Send all-notes-off as a courtesy, then close the port.
  try { output.sendMessage([0xB9, 123, 0]); } catch {}
  try { output.closePort(); } catch {}
  console.log('\n✓ virtual MIDI port closed');
  process.exit(0);
}
process.on('SIGINT', shutdown);
process.on('SIGTERM', shutdown);

#!/usr/bin/env node
// =============================================================================
// midi-list.mjs — enumerate MIDI inputs and outputs visible to this machine.
// Used to verify that midi-pulse.mjs's virtual port is system-visible.
//
// Usage: node scripts/midi-list.mjs
// Exits 0 with the lists printed; exits 1 if the midi package isn't installed.
// =============================================================================

import { createRequire } from 'node:module';
const require = createRequire(import.meta.url);

let midi;
try {
  midi = require('midi');
} catch (e) {
  console.error('the `midi` package is not installed. Run `npm install` first.');
  process.exit(1);
}

const inp = new midi.Input();
const out = new midi.Output();

console.log('MIDI inputs:');
for (let i = 0; i < inp.getPortCount(); i++) {
  console.log(`  [${i}] ${inp.getPortName(i)}`);
}
if (inp.getPortCount() === 0) console.log('  (none)');

console.log('MIDI outputs:');
for (let i = 0; i < out.getPortCount(); i++) {
  console.log(`  [${i}] ${out.getPortName(i)}`);
}
if (out.getPortCount() === 0) console.log('  (none)');

inp.closePort();
out.closePort();

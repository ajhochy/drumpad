// ===========================================================================
// Web MIDI API — device input, GM drum map
// ===========================================================================
import { State } from './state.js';
import { hitPad } from './highway.js';

// General MIDI drum map (channel 10 / note numbers)
export const MIDI_TO_LANE = {
  35: 3, 36: 3,
  38: 2, 40: 2, 37: 2, 39: 2,
  42: 1, 44: 1, 46: 1,
  41: 4, 43: 4, 45: 4, 47: 4, 48: 4, 50: 4,
  49: 0, 52: 0, 55: 0, 57: 0,
  51: 5, 53: 5, 59: 5, 56: 5,
};

function onMidiMessage(msg){
  const [status, note, vel] = msg.data;
  if ((status & 0xF0) === 0x90 && vel > 0){
    const lane = MIDI_TO_LANE[note];
    if (lane !== undefined){
      const led = document.getElementById('midiLed');
      if (led){ led.classList.add('active'); setTimeout(() => led.classList.remove('active'), 80); }
      hitPad(lane);
    }
  }
}

export function refreshMidiInputs(){
  const sel = document.getElementById('midiSel');
  if (!sel || !State.midiAccess) return;
  const inputs = [];
  State.midiAccess.inputs.forEach(inp => inputs.push(inp));
  State.midiInputs = inputs;
  if (inputs.length === 0){
    sel.innerHTML = '<option value="">— no devices —</option>';
    return;
  }
  sel.innerHTML = inputs.map(inp =>
    `<option value="${inp.id}">${inp.name}</option>`
  ).join('');
  inputs.forEach(inp => { inp.onmidimessage = onMidiMessage; });
  State.midiSelectedId = sel.value;
}

export async function initMIDI(){
  const sel = document.getElementById('midiSel');
  const led = document.getElementById('midiLed');
  const pwrLed = document.getElementById('midiPwrLed');

  if (!navigator.requestMIDIAccess){
    if (sel) sel.innerHTML = '<option>— not supported —</option>';
    return;
  }
  try {
    const access = await navigator.requestMIDIAccess({ sysex: false });
    State.midiAccess = access;
    State.midiEnabled = true;
    if (led) led.classList.add('on');
    if (pwrLed){ pwrLed.classList.remove('red'); pwrLed.classList.add('green'); }
    refreshMidiInputs();
    access.onstatechange = refreshMidiInputs;
  } catch (err) {
    if (sel) sel.innerHTML = '<option>— denied —</option>';
  }
}

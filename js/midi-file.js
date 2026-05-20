// ===========================================================================
// Minimal MIDI file parser — no external dependencies
// ===========================================================================

/**
 * Parse a MIDI file ArrayBuffer.
 * Returns { ppq, events: [{tick, midiNote, velocity}] }
 */
export function parseMidiFile(arrayBuffer){
  const data = new DataView(arrayBuffer);
  const bytes = new Uint8Array(arrayBuffer);
  let pos = 0;

  function readUint32(){ const v = data.getUint32(pos, false); pos += 4; return v; }
  function readUint16(){ const v = data.getUint16(pos, false); pos += 2; return v; }
  function readByte(){ return bytes[pos++]; }

  function readVLQ(){
    let value = 0;
    let b;
    do {
      b = readByte();
      value = (value << 7) | (b & 0x7F);
    } while (b & 0x80);
    return value;
  }

  // Header chunk
  const headerMagic = readUint32();
  if (headerMagic !== 0x4D546864) throw new Error('Not a MIDI file');
  const headerLen = readUint32(); // should be 6
  const format = readUint16();
  const ntrks = readUint16();
  const timeDivision = readUint16();

  if (timeDivision & 0x8000) throw new Error('SMPTE time division not supported');
  const ppq = timeDivision;

  const allEvents = [];

  for (let t = 0; t < ntrks; t++){
    const trackMagic = readUint32();
    if (trackMagic !== 0x4D54726B) {
      // skip unknown chunk
      const len = readUint32();
      pos += len;
      continue;
    }
    const trackLen = readUint32();
    const trackEnd = pos + trackLen;

    let tick = 0;
    let runningStatus = 0;

    while (pos < trackEnd){
      const delta = readVLQ();
      tick += delta;

      let statusByte = bytes[pos];

      if (statusByte & 0x80){
        // real status byte
        runningStatus = statusByte;
        pos++;
      } else {
        // running status — use last status
        statusByte = runningStatus;
        // don't advance pos, the data byte is next
      }

      const type = statusByte & 0xF0;
      const channel = statusByte & 0x0F;

      if (type === 0xFF){
        // meta event
        const metaType = readByte();
        const metaLen = readVLQ();
        pos += metaLen;
        runningStatus = 0; // meta events reset running status
      } else if (statusByte === 0xF0 || statusByte === 0xF7){
        // sysex
        const sysexLen = readVLQ();
        pos += sysexLen;
        runningStatus = 0;
      } else if (type === 0x90){
        // note on
        const note = readByte();
        const vel = readByte();
        if (vel > 0){
          allEvents.push({ tick, midiNote: note, velocity: vel });
        }
        // note on with vel=0 treated as note off — ignore for drums
      } else if (type === 0x80){
        // note off — skip
        pos += 2;
      } else if (type === 0xA0){
        // aftertouch
        pos += 2;
      } else if (type === 0xB0){
        // control change
        pos += 2;
      } else if (type === 0xC0){
        // program change
        pos += 1;
      } else if (type === 0xD0){
        // channel pressure
        pos += 1;
      } else if (type === 0xE0){
        // pitch bend
        pos += 2;
      } else {
        // unknown — try to skip safely by breaking
        break;
      }
    }

    pos = trackEnd;
  }

  allEvents.sort((a, b) => a.tick - b.tick);
  return { ppq, events: allEvents };
}

/**
 * GM drum map: map MIDI note to lane index 0-5
 * 0=crash, 1=hihat, 2=snare, 3=kick, 4=tom, 5=ride
 */
export function midiNoteToLane(note){
  // kick
  if (note === 35 || note === 36) return 3;
  // snare
  if (note === 38 || note === 40 || note === 37 || note === 39) return 2;
  // hihat
  if (note === 42 || note === 44 || note === 46) return 1;
  // toms
  if (note === 41 || note === 43 || note === 45 || note === 47 || note === 48 || note === 50) return 4;
  // crash
  if (note === 49 || note === 52 || note === 55 || note === 57) return 0;
  // ride
  if (note === 51 || note === 53 || note === 56 || note === 59) return 5;
  return undefined;
}

/**
 * Export a pattern as a MIDI file ArrayBuffer (Type 0, channel 10, GM drums).
 * pattern: array of {lane, steps[]} where steps is boolean[]
 * stepsPerBeat: 2 (eighth notes per quarter note)
 * ppq: 96
 */
export function exportMidiFile(lanePatterns, steps, bpm){
  const ppq = 96;
  // 8th note = 1 step = ppq/2 ticks
  const ticksPerStep = ppq / 2;
  const microsecondsPerBeat = Math.round(60000000 / bpm);

  // GM note numbers per lane: crash=49, hihat=42, snare=38, kick=36, tom=45, ride=51
  const GM_NOTES = [49, 42, 38, 36, 45, 51];

  // Collect all events [{tick, note, type}] type: 'on'|'off'
  const rawEvents = [];

  lanePatterns.forEach((pattern, laneIdx) => {
    const note = GM_NOTES[laneIdx];
    pattern.forEach((on, stepIdx) => {
      if (on){
        const tick = stepIdx * ticksPerStep;
        rawEvents.push({ tick, note, type: 'on', vel: 100 });
        rawEvents.push({ tick: tick + Math.floor(ticksPerStep * 0.5), note, type: 'off', vel: 0 });
      }
    });
  });

  rawEvents.sort((a, b) => a.tick - b.tick || (a.type === 'off' ? -1 : 1));

  // Encode variable-length quantity
  function encodeVLQ(value){
    if (value === 0) return [0];
    const bytes = [];
    bytes.unshift(value & 0x7F);
    value >>= 7;
    while (value > 0){
      bytes.unshift((value & 0x7F) | 0x80);
      value >>= 7;
    }
    return bytes;
  }

  // Build track data
  const trackBytes = [];

  // Tempo meta event: FF 51 03 tt tt tt
  trackBytes.push(...encodeVLQ(0)); // delta 0
  trackBytes.push(0xFF, 0x51, 0x03);
  trackBytes.push((microsecondsPerBeat >> 16) & 0xFF);
  trackBytes.push((microsecondsPerBeat >> 8) & 0xFF);
  trackBytes.push(microsecondsPerBeat & 0xFF);

  // Note events
  let currentTick = 0;
  rawEvents.forEach(ev => {
    const delta = ev.tick - currentTick;
    currentTick = ev.tick;
    trackBytes.push(...encodeVLQ(delta));
    // Channel 10 (index 9): 0x99 = note-on ch10, 0x89 = note-off ch10
    if (ev.type === 'on'){
      trackBytes.push(0x99, ev.note, ev.vel);
    } else {
      trackBytes.push(0x89, ev.note, ev.vel);
    }
  });

  // End of track: FF 2F 00
  trackBytes.push(...encodeVLQ(0));
  trackBytes.push(0xFF, 0x2F, 0x00);

  // Assemble file
  const totalLen = 14 + 8 + trackBytes.length;
  const buf = new ArrayBuffer(totalLen);
  const view = new DataView(buf);
  let offset = 0;

  function writeUint32(v){ view.setUint32(offset, v, false); offset += 4; }
  function writeUint16(v){ view.setUint16(offset, v, false); offset += 2; }
  function writeBytes(arr){ arr.forEach(b => { view.setUint8(offset, b); offset++; }); }

  // Header
  writeUint32(0x4D546864); // 'MThd'
  writeUint32(6);          // header length
  writeUint16(0);          // format 0
  writeUint16(1);          // 1 track
  writeUint16(ppq);        // ppq

  // Track chunk
  writeUint32(0x4D54726B); // 'MTrk'
  writeUint32(trackBytes.length);
  writeBytes(trackBytes);

  return buf;
}

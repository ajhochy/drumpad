// ===========================================================================
// Lesson data + helpers
// ===========================================================================

export const LANES = ['crash','hihat','snare','kick','tom','ride'];
export const LANE_LABEL = ['CR','HH','SN','KK','TM','RD'];
export const LANE_COLORS = [
  'var(--sticker-pink)',
  'var(--led-green)',
  '#dde2ea',
  'var(--led-red)',
  'var(--led-amber)',
  'var(--sticker-cyan)',
];

// Build a note set from a per-lane pattern string ('x . x . x . x .')
function pat(line){
  return line.replace(/\s+/g,'').split('').map(c=> c==='x' || c==='X');
}

export function lessonFromPatterns(name, bpm, tip, patterns, bars=2){
  const notes = [];
  const len = patterns[0].pattern.replace(/\s+/g,'').length;
  for (let bar=0; bar<bars; bar++){
    patterns.forEach(p=>{
      const arr = pat(p.pattern);
      arr.forEach((on,i)=>{
        if (on) notes.push({lane:LANES.indexOf(p.lane), beat: i + bar*len});
      });
    });
  }
  notes.sort((a,b)=> a.beat-b.beat || a.lane-b.lane);
  return {
    name, bpm, tip,
    bars, beatsPerBar: len,
    patterns,
    notes
  };
}

/**
 * Convert parsed MIDI events to lesson format.
 * events: [{tick, lane}] (lane already mapped from midiNote)
 * ppq: pulses per quarter note from MIDI header
 * The app BPM controls actual ms timing; we just store "beat" as eighth-note index.
 * halfBeat = ppq / 2 ticks per eighth note
 */
export function lessonFromMidiEvents(name, events, ppq){
  const halfBeat = ppq / 2;
  const notes = events
    .filter(e => e.lane !== undefined)
    .map(e => ({
      lane: e.lane,
      beat: Math.round(e.tick / halfBeat),
    }));
  notes.sort((a,b)=> a.beat-b.beat || a.lane-b.lane);

  // Calculate total length in beats
  const lastBeat = notes.length ? notes[notes.length-1].beat : 0;
  // Round up to nearest 16-beat bar
  const totalBeats = Math.max(16, Math.ceil((lastBeat + 1) / 16) * 16);

  // Build synthetic pattern strings per lane for notation display
  const patterns = LANES.map((lane, laneIdx) => {
    const arr = new Array(Math.min(totalBeats, 16)).fill('.');
    notes.forEach(n => {
      if (n.lane === laneIdx && n.beat < arr.length) arr[n.beat] = 'x';
    });
    return { lane, pattern: arr.join('') };
  }).filter(p => p.pattern.includes('x'));

  return {
    name,
    bpm: 80, // default; user controls BPM
    tip: `MIDI file: ${name}`,
    bars: Math.ceil(totalBeats / 16),
    beatsPerBar: 16,
    patterns: patterns.length ? patterns : [{ lane: 'kick', pattern: 'x...............' }],
    notes,
  };
}

// Each lesson: 16-char patterns (16 eighth-note steps = 2 bars of 4/4), bars=1
// so loopLengthBeats = bars * beatsPerBar = 1 * 16 = 16 ✓
function lesson(name, bpm, tip, patterns, difficulty, genre){
  const L = lessonFromPatterns(name, bpm, tip, patterns, 1);
  L.meta = { difficulty, genre };
  return L;
}

export const LESSONS = [
  lesson(
    'Rock Beat 101', 80,
    'Keep the hi-hat steady on every eighth note. Snare locks in on beats 2 and 4 — that\'s what makes it groove.',
    [
      { lane: 'hihat', pattern: 'xxxxxxxxxxxxxxxx' },
      { lane: 'snare', pattern: '..x...x...x...x.' },
      { lane: 'kick',  pattern: 'x...x...x...x...' },
    ],
    'Beginner', 'Rock'
  ),
  lesson(
    'Disco Pulse', 100,
    'Hi-hat hits on the off-beats (the "ands"). That upbeat pulse is what drives disco and funk.',
    [
      { lane: 'hihat', pattern: '.x.x.x.x.x.x.x.' },
      { lane: 'snare', pattern: '..x...x...x...x.' },
      { lane: 'kick',  pattern: 'x...x...x...x...' },
    ],
    'Beginner', 'Disco'
  ),
  lesson(
    'Half-Time Slap', 72,
    'The snare only hits once per bar, giving a big heavy feel. Kick fills the space — listen for where beat 1 lands.',
    [
      { lane: 'hihat', pattern: 'xxxxxxxxxxxxxxxx' },
      { lane: 'snare', pattern: '....x.......x...' },
      { lane: 'kick',  pattern: 'x..x....x..x....' },
    ],
    'Intermediate', 'Funk'
  ),
  lesson(
    'Tom Fill', 90,
    'First half is straight time, second half explodes into toms. Keep the kick locked in when the toms come in.',
    [
      { lane: 'hihat', pattern: 'xxxxxxxx........' },
      { lane: 'snare', pattern: '....x...........' },
      { lane: 'kick',  pattern: 'x...x...........' },
      { lane: 'tom',   pattern: '........xxxxxxxx' },
    ],
    'Intermediate', 'Rock'
  ),
  lesson(
    'Crash & Ride', 95,
    'Crash on beat 1 signals the top of the form. Ride carries the pulse. Listen to how the crash and ride work together.',
    [
      { lane: 'crash', pattern: 'x...............' },
      { lane: 'ride',  pattern: '.x.x.x.x.x.x.x.' },
      { lane: 'snare', pattern: '..x...x...x...x.' },
      { lane: 'kick',  pattern: 'x...x...........' },
    ],
    'Intermediate', 'Jazz'
  ),
  lesson(
    'Shuffle', 110,
    'The shuffle uses a "long-short" pattern on the hi-hat. Feel the triplet swing — it\'s what separates blues from rock.',
    [
      { lane: 'hihat', pattern: 'x.xx.xx.x.xx.xx.' },
      { lane: 'snare', pattern: '..x...x...x...x.' },
      { lane: 'kick',  pattern: 'x...x...........' },
    ],
    'Intermediate', 'Blues'
  ),
  lesson(
    'Punk Bash', 160,
    'Fast and aggressive. Hi-hat never lets up. The snare stutters between backbeats — stay relaxed, keep your wrist loose.',
    [
      { lane: 'hihat', pattern: 'xxxxxxxxxxxxxxxx' },
      { lane: 'snare', pattern: '..x.x.x...x.x.x.' },
      { lane: 'kick',  pattern: 'x...x...x...x...' },
    ],
    'Advanced', 'Punk'
  ),
  lesson(
    'Funk Pocket', 96,
    'Ghost notes and syncopated kick define the pocket. Every hit matters — listen for the spaces between the notes.',
    [
      { lane: 'hihat', pattern: 'xxxxxxxxxxxxxxxx' },
      { lane: 'snare', pattern: '..x.x..x....x...' },
      { lane: 'kick',  pattern: 'x..x.x..x..x....' },
    ],
    'Advanced', 'Funk'
  ),
];

export const LESSON_META = LESSONS.map(L => L.meta);

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

export const LESSON_META = [
  { difficulty:'Easy', genre:'Rock' },
  { difficulty:'Easy', genre:'Dance' },
  { difficulty:'Easy', genre:'Hip-Hop' },
  { difficulty:'Med', genre:'Fills' },
  { difficulty:'Med', genre:'Rock' },
  { difficulty:'Med', genre:'Jazz' },
  { difficulty:'Hard', genre:'Punk' },
  { difficulty:'Hard', genre:'Funk' },
];

export const LESSONS = [
  lessonFromPatterns(
    'Rock Beat 101',
    80,
    'Hi-hat plays straight eighths. Snare lands on 2 and 4. Kick is your heartbeat on 1 and 3. The whole foundation of rock is right here.',
    [
      { lane:'hihat', pattern:'x x x x x x x x' },
      { lane:'snare', pattern:'....x.......x...' },
      { lane:'kick',  pattern:'x.......x.......' }
    ]
  ),
  lessonFromPatterns(
    'Disco Pulse',
    100,
    'Every quarter note kick — this is the four-on-the-floor that powers disco, house, and most dance music. Open hi-hat on the upbeats gives it that "tsst" lift.',
    [
      { lane:'hihat', pattern:'.x.x.x.x.x.x.x.x' },
      { lane:'snare', pattern:'....x.......x...' },
      { lane:'kick',  pattern:'x...x...x...x...' }
    ]
  ),
  lessonFromPatterns(
    'Half-Time Slap',
    72,
    'Snare moves to beat 3 only. Slower-feeling but actually the same tempo. This is the hip-hop / J Dilla pocket — let it breathe.',
    [
      { lane:'hihat', pattern:'x x x x x x x x' },
      { lane:'snare', pattern:'........x.......' },
      { lane:'kick',  pattern:'x..x............' }
    ]
  ),
  lessonFromPatterns(
    'Tom Fill Workout',
    90,
    'Four bars of groove, then a tom fill takes you home. Hit toms in quick succession on the last beat. Don\'t rush — fills should land on time.',
    [
      { lane:'hihat', pattern:'x x x x x x x x . . . . . . . .' },
      { lane:'snare', pattern:'....x...........' },
      { lane:'kick',  pattern:'x.....x.........' },
      { lane:'tom',   pattern:'........xxxxxxxx' }
    ]
  ),
  lessonFromPatterns(
    'Crash & Ride Groove',
    95,
    'Open the crash on beat 1 — it\'s your downbeat exclamation point. Ride takes over the timekeeping. Snare on 2 and 4 keeps it grounded.',
    [
      { lane:'crash', pattern:'x...............' },
      { lane:'ride',  pattern:'.x.x.x.x.x.x.x.x' },
      { lane:'snare', pattern:'....x.......x...' },
      { lane:'kick',  pattern:'x.......x.......' }
    ]
  ),
  lessonFromPatterns(
    'Shuffle Groove',
    110,
    'Triplet feel — count "1-and-a 2-and-a". The shuffle is jazz, blues, and rockabilly all rolled in. Swing those eighths!',
    [
      { lane:'hihat', pattern:'x.xx.xx.xx.xx.x.' },
      { lane:'snare', pattern:'....x.......x...' },
      { lane:'kick',  pattern:'x.......x.......' }
    ]
  ),
  lessonFromPatterns(
    'Punk Bash',
    160,
    'Eighth notes on the hi-hat, BASH the snare on the upbeats too. Fast and loose. Don\'t overthink — feel the riot.',
    [
      { lane:'hihat', pattern:'x x x x x x x x' },
      { lane:'snare', pattern:'..x.x.x...x.x.x.' },
      { lane:'kick',  pattern:'x...x...x...x...' }
    ]
  ),
  lessonFromPatterns(
    'Funk Pocket',
    96,
    'Ghost notes on the snare give funk its sneaky pulse. Hi-hat stays steady. Lock that kick into the bassline pocket.',
    [
      { lane:'hihat', pattern:'x x x x x x x x' },
      { lane:'snare', pattern:'..x.x..x....x...' },
      { lane:'kick',  pattern:'x..x.x..x..x....' }
    ]
  ),
];

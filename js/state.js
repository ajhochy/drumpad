// ===========================================================================
// Shared mutable state
// ===========================================================================
export const State = {
  currentLesson: 0,
  playing: false,
  score: 0, combo: 0, maxCombo: 0,
  hits: 0, misses: 0, streak: 0,
  STREAK_MAX: 10,
  notes: [], noteEls: [], noteStates: [], shadowNoteEls: [],
  startTime: null, animFrameId: null,
  bpm: 80,
  halfBeatMs: 60000 / 80 / 2,
  metronome: false,
  loop: true,
  scores: JSON.parse(localStorage.getItem('drum.scores') || '{}'),
  midiEnabled: false,
  midiAccess: null,
  midiInputs: [],
  midiSelectedId: null,
  // extra lessons — persisted across reloads
  extraLessons: JSON.parse(localStorage.getItem('drum.extraLessons') || '[]'),
  // builder
  builderPattern: null,  // 6 x N boolean grid
  builderSteps: 16,
  // loop / count-in
  loopLengthBeats: 16,   // eighth-note grid length of current groove
  loopIteration: 0,      // which loop pass we're on (0 = first)
  countInBeats: 8,       // 8 eighth-notes = 4 quarter-note count-in
  // achievements
  consecutiveAccuratePasses: 0,
};

export function saveExtraLessons(){
  localStorage.setItem('drum.extraLessons', JSON.stringify(State.extraLessons));
}

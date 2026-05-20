// ===========================================================================
// Shared mutable state
// ===========================================================================
export const State = {
  currentLesson: 0,
  playing: false,
  score: 0, combo: 0, maxCombo: 0,
  hits: 0, misses: 0, streak: 0,
  STREAK_MAX: 10,
  notes: [], noteEls: [], noteStates: [],
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
  // extra lessons loaded from MIDI files
  extraLessons: [],
  // builder
  builderPattern: null,  // 6 x N boolean grid
  builderSteps: 16,
};

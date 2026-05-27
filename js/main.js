// ===========================================================================
// drumrot — App entry point
// ===========================================================================
import { State } from './state.js';
import { LESSONS, LANE_LABEL, LANES } from './lessons.js';
import { getAC } from './audio.js';
import { initMIDI } from './midi-device.js';
import {
  clearHighway, buildNotes, buildStreak, renderStreak,
  hitPad, startPlay, stopPlay, togglePlay,
} from './highway.js';
import { resetStats } from './scoring.js';
import { refreshLibrary, refreshProgress, highlightLibrary, initLibraryMidiLoad } from './library.js';
import { initBuilder } from './builder.js';
import { initDropsTab } from './drumrots.js';

// ===========================================================================
// Helpers
// ===========================================================================
function setText(id, v){ const e = document.getElementById(id); if (e) e.textContent = v; }

function allLessons(){
  return [...LESSONS, ...State.extraLessons];
}

// ===========================================================================
// Tab switching
// ===========================================================================
function switchTab(name){
  document.querySelectorAll('.tab').forEach(t => t.classList.toggle('active', t.dataset.tab === name));
  document.querySelectorAll('.panel').forEach(p => p.classList.toggle('active', p.id === 'panel-' + name));
  if (name === 'library') refreshLibrary();
  if (name === 'progress') refreshProgress();
  if (name === 'drops') initDropsTab();
}

// ===========================================================================
// Lesson loading
// ===========================================================================
function renderNotation(L){
  const el = document.getElementById('notation');
  if (!el) return;
  el.innerHTML = '';
  function pat(line){ return line.replace(/\s+/g,'').split('').map(c => c==='x'||c==='X'); }
  L.patterns.forEach(p => {
    const row = document.createElement('div');
    row.className = 'row';
    const laneIdx = LANES.indexOf(p.lane);
    const lbl = LANE_LABEL[laneIdx] || p.lane.toUpperCase().slice(0,2);
    row.innerHTML = `<span class="lbl">${lbl}</span><span class="cells"></span>`;
    const cells = row.querySelector('.cells');
    const arr = pat(p.pattern);
    arr.forEach((on, i) => {
      const c = document.createElement('span');
      c.className = 'cell' + (on ? ' on' : '') + (i % 4 === 0 ? ' beat' : '');
      c.textContent = on ? 'x' : '·';
      cells.appendChild(c);
    });
    el.appendChild(row);
  });
}

export function loadLesson(idx){
  const lessons = allLessons();
  if (idx < 0 || idx >= lessons.length) return;
  State.currentLesson = idx;
  const L = lessons[idx];
  // Respect user BPM override — only reset if lesson BPM changes
  State.bpm = L.bpm;
  State.halfBeatMs = 60000 / State.bpm / 2;
  State.notes = L.notes.map(n => ({ ...n }));
  State.loopLengthBeats = L.loopLengthBeats || (L.bars * L.beatsPerBar) || 16;

  setText('hdrName', L.name);
  const num = String(idx + 1).padStart(2, '0');
  setText('hdrChip', num);
  setText('tipText', L.tip);

  renderNotation(L);
  resetStats();
  clearHighway();
  buildNotes();
  highlightLibrary();

  const bpmI = document.getElementById('bpmInput');
  if (bpmI) bpmI.value = L.bpm;
  const bpmB = document.getElementById('builderBpm');
  if (bpmB) bpmB.value = L.bpm;
}

// ===========================================================================
// Toggle helper
// ===========================================================================
function wireToggle(id, key, onChange){
  const el = document.getElementById(id);
  if (!el) return;
  if (State[key]) el.classList.add('on');
  el.addEventListener('click', () => {
    State[key] = !State[key];
    el.classList.toggle('on', State[key]);
    if (onChange) onChange(State[key]);
  });
}

// ===========================================================================
// Keyboard input
// ===========================================================================
const KEY_MAP = { 'a':0, 's':1, 'd':2, 'f':3, 'j':4, 'k':5 };

function onKeyDown(e){
  if (e.target.tagName === 'INPUT') return;
  const k = e.key.toLowerCase();
  if (KEY_MAP[k] !== undefined){ e.preventDefault(); hitPad(KEY_MAP[k]); }
  if (e.key === ' '){ e.preventDefault(); togglePlay(); }
}

// ===========================================================================
// Init
// ===========================================================================
function init(){
  // Tab buttons
  document.querySelectorAll('.tab').forEach(t => {
    t.addEventListener('click', () => switchTab(t.dataset.tab));
  });

  // Pad click listeners
  document.querySelectorAll('.pad').forEach(p => {
    p.addEventListener('click', () => hitPad(+p.dataset.lane));
  });

  // Transport buttons
  document.getElementById('btnPlay')?.addEventListener('click', togglePlay);
  document.getElementById('btnRestart')?.addEventListener('click', () => {
    stopPlay();
    loadLesson(State.currentLesson);
  });
  document.getElementById('btnNext')?.addEventListener('click', () => {
    const lessons = allLessons();
    stopPlay();
    loadLesson((State.currentLesson + 1) % lessons.length);
  });

  // BPM input
  const bpmI = document.getElementById('bpmInput');
  if (bpmI) bpmI.addEventListener('input', e => {
    const v = Math.max(40, Math.min(200, +e.target.value || 80));
    State.bpm = v;
    State.halfBeatMs = 60000 / v / 2;
    const bpmB = document.getElementById('builderBpm');
    if (bpmB) bpmB.value = v;
  });

  // Metronome toggle
  wireToggle('metToggle', 'metronome');

  // Loop toggle — default on
  State.loop = true;
  wireToggle('loopToggle', 'loop');
  document.getElementById('loopToggle')?.classList.add('on');

  // MIDI device select change
  document.getElementById('midiSel')?.addEventListener('change', e => {
    State.midiSelectedId = e.target.value;
  });

  // Keyboard
  document.addEventListener('keydown', onKeyDown);

  // Streak dots
  buildStreak();
  renderStreak();

  // Load initial lesson only if one exists
  if (allLessons().length > 0) loadLesson(0);

  // Library
  refreshLibrary();
  initLibraryMidiLoad();

  // MIDI device
  initMIDI();

  // Beat builder — init, then restore last saved pattern if one exists
  initBuilder();
  const savedBuilderLesson = State.extraLessons.find(l => l._builderLesson);
  if (savedBuilderLesson){
    import('./builder.js').then(m => m.loadBuilderPattern(savedBuilderLesson));
  }

  // Listen for loadLesson events from library cards
  document.addEventListener('loadLesson', e => {
    stopPlay();
    loadLesson(e.detail.idx);
    startPlay();
  });
}

if (document.readyState === 'loading'){
  document.addEventListener('DOMContentLoaded', init);
} else {
  init();
}

// ===========================================================================
// Beat Builder — step sequencer grid UI
// ===========================================================================
import { State, saveExtraLessons } from './state.js';
import { LANES, LANE_LABEL, LANE_COLORS, lessonFromPatterns } from './lessons.js';
import { exportMidiFile } from './midi-file.js';
import { checkAchievements } from './achievements.js';

// GM note numbers per lane: crash=49, hihat=42, snare=38, kick=36, tom=45, ride=51
const LANE_STEP_COLORS = [
  '#ff2a7a',   // crash — sticker-pink
  '#5cf07d',   // hihat — led-green
  '#dde2ea',   // snare
  '#ff3a5a',   // kick — led-red
  '#ff8a1e',   // tom — led-amber
  '#10c4d6',   // ride — sticker-cyan
];

let grid = null; // 6 x N boolean grid, indexed grid[lane][step]

function getSteps(){
  return State.builderSteps || 16;
}

function initGrid(steps){
  grid = LANES.map(() => new Array(steps).fill(false));
  State.builderPattern = grid;
}

export function initBuilder(){
  const steps = getSteps();
  initGrid(steps);
  renderBuilderGrid();
  wireBuilderControls();
}

function renderBuilderGrid(){
  const container = document.getElementById('builderGrid');
  if (!container) return;
  container.innerHTML = '';
  const steps = getSteps();

  // Set grid columns for step buttons area
  container.style.gridTemplateColumns = '1fr';

  LANES.forEach((lane, laneIdx) => {
    const row = document.createElement('div');
    row.className = 'builder-row';

    const label = document.createElement('div');
    label.className = 'builder-lane-label';
    label.style.color = LANE_STEP_COLORS[laneIdx];
    label.textContent = LANE_LABEL[laneIdx];
    row.appendChild(label);

    const stepsContainer = document.createElement('div');
    stepsContainer.className = 'builder-steps';
    stepsContainer.style.gridTemplateColumns = `repeat(${steps}, 1fr)`;

    for (let s = 0; s < steps; s++){
      const btn = document.createElement('button');
      btn.className = 'step-btn' + (s % 4 === 0 && s > 0 ? ' beat-marker' : '');
      btn.dataset.lane = laneIdx;
      btn.dataset.step = s;

      const color = LANE_STEP_COLORS[laneIdx];
      btn.style.setProperty('--step-color', color);

      if (grid && grid[laneIdx] && grid[laneIdx][s]){
        btn.classList.add('on');
        btn.style.background = hexToRgbaBackground(color);
      }

      btn.addEventListener('click', () => {
        grid[laneIdx][s] = !grid[laneIdx][s];
        btn.classList.toggle('on', grid[laneIdx][s]);
        if (grid[laneIdx][s]){
          btn.style.background = hexToRgbaBackground(color);
        } else {
          btn.style.background = '';
        }
        State.builderPattern = grid;
      });

      stepsContainer.appendChild(btn);
    }

    row.appendChild(stepsContainer);
    container.appendChild(row);
  });
}

function hexToRgbaBackground(color){
  // Convert CSS color to a dim background for "on" state
  // For var() references we just return a generic glow
  if (color.startsWith('#')){
    const r = parseInt(color.slice(1,3), 16);
    const g = parseInt(color.slice(3,5), 16);
    const b = parseInt(color.slice(5,7), 16);
    return `linear-gradient(180deg, rgba(${r},${g},${b},0.35) 0%, rgba(${r},${g},${b},0.18) 100%)`;
  }
  return 'linear-gradient(180deg, rgba(255,138,30,0.3) 0%, rgba(255,58,90,0.15) 100%)';
}

function wireBuilderControls(){
  // Step count selector
  document.querySelectorAll('.step-sel-btn').forEach(btn => {
    btn.addEventListener('click', () => {
      document.querySelectorAll('.step-sel-btn').forEach(b => b.classList.remove('active'));
      btn.classList.add('active');
      State.builderSteps = parseInt(btn.dataset.steps, 10);
      initGrid(State.builderSteps);
      renderBuilderGrid();
    });
  });

  // BPM sync between builder and player
  const builderBpm = document.getElementById('builderBpm');
  if (builderBpm){
    builderBpm.addEventListener('input', e => {
      const v = Math.max(40, Math.min(200, +e.target.value || 80));
      State.bpm = v;
      State.halfBeatMs = 60000 / v / 2;
      const playerBpm = document.getElementById('bpmInput');
      if (playerBpm) playerBpm.value = v;
    });
  }

  // Save MIDI
  const btnSave = document.getElementById('btnSaveMidi');
  if (btnSave){
    btnSave.addEventListener('click', () => {
      const steps = getSteps();
      const bpm = parseInt(document.getElementById('builderBpm')?.value, 10) || 80;
      const buf = exportMidiFile(grid, steps, bpm);
      const blob = new Blob([buf], { type: 'audio/midi' });
      const url = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = 'sp808-pattern.mid';
      a.click();
      URL.revokeObjectURL(url);
    });
  }

  // Load into Player
  const btnLoad = document.getElementById('btnLoadIntoPlayer');
  if (btnLoad){
    btnLoad.addEventListener('click', () => {
      const lesson = getBuilderLesson();
      if (!lesson) return;
      const existingIdx = State.extraLessons.findIndex(l => l._builderLesson);
      if (existingIdx >= 0){
        State.extraLessons[existingIdx] = lesson;
      } else {
        State.extraLessons.push(lesson);
      }
      saveExtraLessons();
      const hasCoach = !!document.getElementById('builderCoachNote')?.value.trim();
      checkAchievements({ onCreator: true, onCoach: hasCoach });
      const lessonIdx = existingIdx >= 0 ? existingIdx : State.extraLessons.length - 1;
      document.dispatchEvent(new CustomEvent('loadLesson', {
        detail: { idx: lessonIdx }
      }));
      // Switch to play tab
      document.querySelectorAll('.tab').forEach(t => t.classList.toggle('active', t.dataset.tab === 'play'));
      document.querySelectorAll('.panel').forEach(p => p.classList.toggle('active', p.id === 'panel-play'));
    });
  }

  // Clear pattern
  const btnClear = document.getElementById('btnClearPattern');
  if (btnClear){
    btnClear.addEventListener('click', () => {
      const steps = getSteps();
      initGrid(steps);
      renderBuilderGrid();
    });
  }
}

export function getBuilderPattern(){
  if (!grid) return [];
  return LANES.map((lane, i) => ({
    lane,
    pattern: grid[i],
  })).filter(p => p.pattern.some(Boolean));
}

function getBuilderLesson(){
  const steps = getSteps();
  const bpm = parseInt(document.getElementById('builderBpm')?.value, 10) || 80;
  const patterns = getBuilderPattern();
  if (patterns.length === 0){
    alert('Pattern is empty — add some steps first!');
    return null;
  }
  // Convert boolean[] to pattern string
  const strPatterns = patterns.map(p => ({
    lane: p.lane,
    pattern: p.pattern.map(on => on ? 'x' : '.').join(''),
  }));
  const coachNote = document.getElementById('builderCoachNote')?.value.trim() || '';
  const lesson = lessonFromPatterns('Builder Pattern', bpm, coachNote || 'Custom beat builder pattern.', strPatterns, 1);
  lesson._builderLesson = true;
  return lesson;
}

export function loadBuilderPattern(lesson){
  if (!lesson || !lesson.patterns) return;
  const steps = getSteps();
  initGrid(steps);
  lesson.patterns.forEach(p => {
    const laneIdx = LANES.indexOf(p.lane);
    if (laneIdx < 0) return;
    const arr = p.pattern.replace(/\s+/g,'').split('');
    arr.forEach((c, i) => {
      if (i < steps && grid[laneIdx]) grid[laneIdx][i] = (c === 'x' || c === 'X');
    });
  });
  State.builderPattern = grid;
  renderBuilderGrid();
  const ta = document.getElementById('builderCoachNote');
  if (ta && lesson.tip && lesson.tip !== 'Custom beat builder pattern.') ta.value = lesson.tip;
}

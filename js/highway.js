// ===========================================================================
// Note highway — animation loop, hit detection, pad handling
// ===========================================================================
import { State } from './state.js';
import { drumSound, clickSound } from './audio.js';
import { resetStats } from './scoring.js';
import { LANE_LABEL } from './lessons.js';

export const HIT_WINDOW = 60;
let lastMetronomeBeat = -1;
let judgeTO = null;

function setText(id, v){ const e = document.getElementById(id); if (e) e.textContent = v; }

export function highwayH(){
  const hw = document.getElementById('highway');
  return hw ? hw.clientHeight : 320;
}

export function hitY(){
  const hw = document.getElementById('highway');
  if (!hw) return 260;
  const hl = hw.querySelector('.hit-line');
  if (hl){
    const hr = hl.getBoundingClientRect();
    const wr = hw.getBoundingClientRect();
    return (hr.top - wr.top) + hr.height / 2;
  }
  return highwayH() - 56;
}

export function clearHighway(){
  const hw = document.getElementById('highway');
  if (!hw) return;
  State.noteEls.forEach(e => { if (e && e.parentNode) e.parentNode.removeChild(e); });
  State.noteEls = [];
  State.noteStates = [];
}

export function buildNotes(){
  const hw = document.getElementById('highway');
  if (!hw) return;
  State.noteEls = State.notes.map(n => {
    const el = document.createElement('div');
    el.className = 'note lane-' + n.lane;
    el.textContent = LANE_LABEL[n.lane];
    const laneW = 100 / 6;
    el.style.left = (n.lane * laneW + 1) + '%';
    el.style.width = (laneW - 2) + '%';
    el.style.top = '-40px';
    hw.appendChild(el);
    return el;
  });
  State.noteStates = State.notes.map(() => ({ hit: false, missed: false, y: -40 }));
}

export function buildStreak(){
  const bar = document.getElementById('streakBar');
  if (!bar) return;
  if (bar.children.length !== State.STREAK_MAX){
    bar.innerHTML = '';
    for (let i = 0; i < State.STREAK_MAX; i++){
      const d = document.createElement('div');
      d.className = 'sdot';
      bar.appendChild(d);
    }
  }
}

export function renderStreak(){
  const bar = document.getElementById('streakBar');
  if (!bar) return;
  [...bar.children].forEach((d, i) => {
    d.classList.toggle('lit', i < State.streak);
  });
}

export function showJudge(text, kind){
  const j = document.getElementById('judge');
  if (!j) return;
  j.textContent = text;
  j.dataset.kind = kind;
  j.style.opacity = '1';
  if (judgeTO) clearTimeout(judgeTO);
  judgeTO = setTimeout(() => { j.style.opacity = '0'; }, 500);
}

export function updateProgress(){
  const done = State.hits + State.misses;
  const total = State.notes.length;
  const pct = total > 0 ? Math.min(100, Math.round(done / total * 100)) : 0;
  const f = document.getElementById('progFill');
  if (f) f.style.width = pct + '%';
  setText('progLbl', done + ' / ' + total);
}

function pulseMetronome(){
  const el = document.getElementById('metToggle');
  if (!el) return;
  el.classList.add('pulse');
  setTimeout(() => el.classList.remove('pulse'), 100);
}

export function animate(ts){
  if (!State.startTime) State.startTime = ts;
  const elapsed = ts - State.startTime;
  const HY = hitY();
  const travelTime = 1800;
  let allDone = true;

  // metronome
  if (State.metronome){
    const totalQuarterMs = State.halfBeatMs * 2;
    const currentBeat = Math.floor(elapsed / totalQuarterMs);
    if (currentBeat !== lastMetronomeBeat){
      lastMetronomeBeat = currentBeat;
      clickSound(currentBeat % 4 === 0);
      pulseMetronome();
    }
  }

  State.notes.forEach((n, i) => {
    const st = State.noteStates[i];
    if (st.hit || st.missed) return;
    allDone = false;
    const noteTime = n.beat * State.halfBeatMs;
    const progress = (elapsed - (noteTime - travelTime)) / travelTime;
    const y = progress * (HY + 40) - 40;
    State.noteEls[i].style.top = Math.round(y) + 'px';
    st.y = y;

    if (y > HY + HIT_WINDOW + 8){
      st.missed = true;
      State.noteEls[i].classList.add('missed');
      State.misses++;
      State.combo = 0;
      State.streak = 0;
      renderStreak();
      setText('comboVal', '0x');
      showJudge('miss', 'miss');
      updateProgress();
    }
  });

  updateProgress();

  if (allDone && State.notes.length > 0 &&
      elapsed > (State.notes[State.notes.length - 1]?.beat || 0) * State.halfBeatMs + 1500){
    finishLesson();
    return;
  }

  State.animFrameId = requestAnimationFrame(animate);
}

export function finishLesson(){
  const total = State.notes.length;
  const acc = total > 0 ? State.hits / total : 0;
  const stars = acc >= 0.95 ? 3 : acc >= 0.8 ? 2 : acc >= 0.5 ? 1 : 0;
  const key = String(State.currentLesson);
  const prev = State.scores[key] || { high: 0, stars: 0, plays: 0 };
  State.scores[key] = {
    high: Math.max(prev.high, State.score),
    stars: Math.max(prev.stars, stars),
    plays: (prev.plays || 0) + 1,
    lastAcc: Math.round(acc * 100),
    when: Date.now()
  };
  localStorage.setItem('drum.scores', JSON.stringify(State.scores));

  if (State.loop){
    setTimeout(() => { if (State.playing) restartFromTop(); }, 800);
  } else {
    stopPlay();
    showJudge('done!', 'done');
  }

  // Refresh library to update score display
  import('./library.js').then(m => m.refreshLibrary());
}

export function restartFromTop(){
  State.startTime = null;
  lastMetronomeBeat = -1;
  clearHighway();
  buildNotes();
  State.combo = 0;
  State.streak = 0;
  setText('comboVal', '0x');
  renderStreak();
  State.hits = 0;
  State.misses = 0;
  setText('progLbl', '0 / ' + State.notes.length);
  const f = document.getElementById('progFill');
  if (f) f.style.width = '0%';
}

export function hitPad(lane){
  drumSound(lane);
  const pad = document.querySelector('[data-lane="' + lane + '"]');
  if (pad){ pad.classList.add('hit'); setTimeout(() => pad.classList.remove('hit'), 120); }
  if (!State.playing) return;

  const HY = hitY();
  for (let i = 0; i < State.notes.length; i++){
    const st = State.noteStates[i];
    if (st.hit || st.missed) continue;
    if (State.notes[i].lane !== lane) continue;
    const dy = Math.abs(st.y - HY);
    if (dy < HIT_WINDOW){
      st.hit = true;
      State.noteEls[i].classList.add('hit');
      State.hits++;
      State.combo++;
      State.maxCombo = Math.max(State.maxCombo, State.combo);
      State.streak = Math.min(State.streak + 1, State.STREAK_MAX);
      renderStreak();
      const pts = dy < 20 ? 300 : dy < 40 ? 200 : 100;
      State.score += pts * Math.max(1, Math.floor(State.combo / 4));
      setText('scoreVal', State.score.toLocaleString());
      setText('comboVal', State.combo + 'x');
      const total = State.hits + State.misses;
      const acc = Math.round(State.hits / total * 100);
      setText('accVal', acc + '%');
      const lbl = pts === 300 ? 'perfect!' : pts === 200 ? 'great!' : 'good';
      showJudge(lbl, pts === 300 ? 'perfect' : pts === 200 ? 'great' : 'good');
      updateProgress();
      return;
    }
  }
}

export function startPlay(){
  import('./audio.js').then(m => m.getAC()); // unlock audio
  State.playing = true;
  State.startTime = null;
  lastMetronomeBeat = -1;
  clearHighway();
  buildNotes();
  resetStats();
  setText('playLbl', 'Pause');
  document.getElementById('btnPlay')?.classList.add('playing');
  State.animFrameId = requestAnimationFrame(animate);
}

export function stopPlay(){
  State.playing = false;
  if (State.animFrameId){
    cancelAnimationFrame(State.animFrameId);
    State.animFrameId = null;
  }
  setText('playLbl', 'Play');
  document.getElementById('btnPlay')?.classList.remove('playing');
}

export function togglePlay(){
  State.playing ? stopPlay() : startPlay();
}

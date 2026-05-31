// ===========================================================================
// Note highway — animation loop, hit detection, pad handling
// ===========================================================================
import { State } from './state.js';
import { drumSound, clickSound } from './audio.js';
import { resetStats } from './scoring.js';
import { LANE_LABEL } from './lessons.js';
import { checkAchievements } from './achievements.js';

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
  State.shadowNoteEls.forEach(e => { if (e && e.parentNode) e.parentNode.removeChild(e); });
  State.noteEls = [];
  State.shadowNoteEls = [];
  State.noteStates = [];
}

function makeNoteEl(hw, n, shadow){
  const el = document.createElement('div');
  el.className = 'note lane-' + n.lane + (shadow ? ' shadow' : '');
  el.textContent = LANE_LABEL[n.lane];
  const laneW = 100 / 6;
  el.style.left = (n.lane * laneW + 1) + '%';
  el.style.width = (laneW - 2) + '%';
  el.style.top = '-40px';
  if (shadow) el.style.display = 'none';
  hw.appendChild(el);
  return el;
}

export function buildNotes(){
  const hw = document.getElementById('highway');
  if (!hw) return;
  State.noteEls       = State.notes.map(n => makeNoteEl(hw, n, false));
  State.shadowNoteEls = State.notes.map(n => makeNoteEl(hw, n, true));
  State.noteStates    = State.notes.map(() => ({ hit: false, missed: false, y: -40 }));
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
  const elapsed     = ts - State.startTime;
  const quarterMs   = State.halfBeatMs * 2;
  const countInMs   = State.countInBeats * State.halfBeatMs;
  const grooveMs    = State.loopLengthBeats * State.halfBeatMs;
  const travelTime  = 1800;

  // ── Metronome — continuous through count-in and groove ───────────────────
  if (State.metronome){
    const beat = Math.floor(elapsed / quarterMs);
    if (beat !== lastMetronomeBeat){
      lastMetronomeBeat = beat;
      clickSound(beat % 4 === 0);
      pulseMetronome();
    }
  }

  // ── grooveElapsed: time since groove started (negative during count-in) ──
  const grooveElapsed = elapsed - countInMs;

  // ── Count-in display ─────────────────────────────────────────────────────
  const j = document.getElementById('judge');
  if (grooveElapsed < 0 && State.loopIteration === 0){
    const countBeat = Math.floor(elapsed / quarterMs) + 1;
    if (j){ j.textContent = String(countBeat); j.dataset.kind = 'countin'; j.style.opacity = '1'; }
  } else if (j && j.dataset.kind === 'countin'){
    j.style.opacity = '0';
  }

  // ── Loop rollover ─────────────────────────────────────────────────────────
  if (State.loop && grooveElapsed >= 0){
    const pass = Math.floor(grooveElapsed / grooveMs);
    if (pass > State.loopIteration){
      State.loopIteration = pass;
      _savePassScore();
      State.hits = 0;
      State.misses = 0;
      State.ghostHits = 0;
      // Clear state flags; positions are re-derived from grooveElapsed naturally
      State.noteStates.forEach(st => { st.hit = false; st.missed = false; });
      State.noteEls.forEach(el => { el.classList.remove('hit','missed'); el.style.opacity = ''; });
    }
  }

  // ── Note positioning ──────────────────────────────────────────────────────
  // Each note is positioned using grooveElapsed directly (no modulo).
  // The primary element tracks the CURRENT pass; the shadow element tracks
  // the NEXT pass so it pre-appears from the top before the loop wraps.
  // This creates a seamless reel: the shadow slides in from the top while
  // the primary slides off the bottom, and they swap roles at the boundary.

  const HY = hitY();
  let allDone = true;

  State.notes.forEach((n, i) => {
    const st         = State.noteStates[i];
    const noteTime   = n.beat * State.halfBeatMs;

    // ── Primary: current pass ─────────────────────────────────────────────
    const tAbs    = noteTime + State.loopIteration * grooveMs;
    const prog    = (grooveElapsed - (tAbs - travelTime)) / travelTime;
    const y       = prog * (HY + 40) - 40;

    if (!st.hit && !st.missed){
      allDone = false;
      State.noteEls[i].style.top = Math.round(y) + 'px';
      st.y = y;

      if (grooveElapsed >= 0 && y > HY + HIT_WINDOW + 8){
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
    }

    // ── Shadow: next pass pre-appearing from top ──────────────────────────
    if (State.loop){
      const shadowEl   = State.shadowNoteEls[i];
      const tAbsNext   = noteTime + (State.loopIteration + 1) * grooveMs;
      const progNext   = (grooveElapsed - (tAbsNext - travelTime)) / travelTime;
      const yNext      = progNext * (HY + 40) - 40;
      if (shadowEl){
        if (yNext >= -42 && yNext <= HY + HIT_WINDOW + 10){
          shadowEl.style.top     = Math.round(yNext) + 'px';
          shadowEl.style.display = '';
        } else {
          shadowEl.style.display = 'none';
        }
      }
    }
  });

  updateProgress();

  // ── Non-loop end ─────────────────────────────────────────────────────────
  if (!State.loop && allDone && State.notes.length > 0 &&
      grooveElapsed > (State.notes[State.notes.length-1]?.beat || 0) * State.halfBeatMs + 1500){
    finishLesson();
    return;
  }

  State.animFrameId = requestAnimationFrame(animate);
}

// Save high score / stars for the pass that just ended (called on each loop rollover)
function _savePassScore(){
  // Accuracy denominator includes ghost hits so spam lowers the score (issue #68).
  const total = State.hits + State.misses + State.ghostHits;
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
  checkAchievements({ onPass: true });
  import('./library.js').then(m => m.refreshLibrary());
}

// Called only in non-loop mode when groove finishes
export function finishLesson(){
  _savePassScore();
  stopPlay();
  showJudge('done!', 'done');
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
      const total = State.hits + State.misses + State.ghostHits;
      const acc = Math.round(State.hits / total * 100);
      setText('accVal', acc + '%');
      const lbl = pts === 300 ? 'perfect!' : pts === 200 ? 'great!' : 'good';
      showJudge(lbl, pts === 300 ? 'perfect' : pts === 200 ? 'great' : 'good');
      updateProgress();
      checkAchievements({ onHit: true });
      return;
    }
  }
  // No in-window note found on this lane — ghost hit (anti-spam, issue #68).
  // Count in the accuracy denominator so spamming lowers accuracy.
  State.ghostHits++;
  State.combo = 0;
  setText('comboVal', '0x');
}

export function startPlay(){
  import('./audio.js').then(m => m.getAC()); // unlock audio
  State.playing = true;
  State.startTime = null;
  State.loopIteration = 0;
  lastMetronomeBeat = -1;
  clearHighway();
  buildNotes();
  resetStats();
  setText('playLbl', 'Pause');
  const btnPlay = document.getElementById('btnPlay');
  if (btnPlay){
    btnPlay.classList.add('playing');
    const icon = btnPlay.querySelector('i');
    if (icon) icon.className = 'ti ti-player-pause';
  }
  State.animFrameId = requestAnimationFrame(animate);
}

export function stopPlay(){
  State.playing = false;
  if (State.animFrameId){
    cancelAnimationFrame(State.animFrameId);
    State.animFrameId = null;
  }
  setText('playLbl', 'Play');
  const btnPlay = document.getElementById('btnPlay');
  if (btnPlay){
    btnPlay.classList.remove('playing');
    const icon = btnPlay.querySelector('i');
    if (icon) icon.className = 'ti ti-player-play';
  }
}

export function togglePlay(){
  State.playing ? stopPlay() : startPlay();
}

// ===========================================================================
// Library + Progress tab rendering
// ===========================================================================
import { State, saveExtraLessons } from './state.js';
import { LESSONS, LESSON_META, LANES, LANE_LABEL, lessonFromMidiEvents } from './lessons.js';
import { parseMidiFile, midiNoteToLane } from './midi-file.js';
import { stopPlay, startPlay } from './highway.js';
import { ACHIEVEMENTS, TIER_NAMES, TIER_COLORS, isUnlocked, getHighestTier, getStreak, getPlayDays } from './achievements.js';

function switchTab(name){
  document.querySelectorAll('.tab').forEach(t => t.classList.toggle('active', t.dataset.tab === name));
  document.querySelectorAll('.panel').forEach(p => p.classList.toggle('active', p.id === 'panel-' + name));
  if (name === 'library') refreshLibrary();
  if (name === 'progress') refreshProgress();
}

function allLessons(){
  return [...LESSONS, ...State.extraLessons];
}

function allMeta(){
  return [
    ...LESSON_META,
    ...State.extraLessons.map(() => ({ difficulty: 'MIDI', genre: 'Custom' })),
  ];
}

export function miniNotation(L){
  return L.patterns.slice(0, 2).map(p => {
    const lbl = LANE_LABEL[LANES.indexOf(p.lane)];
    const pattern = p.pattern.replace(/\s+/g, '');
    return `<div><span style="color:#999">${lbl}:</span> ${pattern}</div>`;
  }).join('');
}

export function highlightLibrary(){
  document.querySelectorAll('.lesson-card').forEach(c => {
    c.classList.toggle('playing', +c.dataset.idx === State.currentLesson);
  });
}

export function refreshLibrary(){
  const grid = document.getElementById('libGrid');
  if (!grid) return;
  grid.innerHTML = '';
  const lessons = allLessons();
  const meta = allMeta();
  const subText = document.getElementById('libSubText');
  if (subText){
    subText.innerHTML = `${lessons.length} patches · tap to load<br>build new grooves in the Build tab`;
  }

  if (lessons.length === 0){
    grid.innerHTML = `<div style="grid-column:span 3;font-family:'Major Mono Display',monospace;font-size:12px;color:var(--text-dim);padding:24px 0;letter-spacing:.1em">no patches loaded — use the Build tab to create one</div>`;
    return;
  }

  lessons.forEach((L, i) => {
    const m = meta[i] || { difficulty: 'Custom', genre: 'MIDI' };
    const s = State.scores[String(i)] || null;
    const num = String(i + 1).padStart(2, '0');
    const stars = s ? s.stars : 0;
    const card = document.createElement('div');
    card.className = 'lesson-card' + (i === State.currentLesson ? ' playing' : '');
    card.dataset.idx = i;
    // Tier pips (only for prebuilt lessons)
    let tierPips = '';
    if (i < LESSONS.length){
      const highestTier = getHighestTier(i);
      tierPips = '<div class="tier-pips">' +
        TIER_NAMES.map((name, t) =>
          `<span class="tier-pip${t <= highestTier ? ' lit' : ''}" style="${t <= highestTier ? `--tc:${TIER_COLORS[t]}` : ''}" title="${name}"></span>`
        ).join('') +
        '</div>';
    }
    card.innerHTML = `
      <div class="num">${num}</div>
      <div class="stamp ${s ? 'done' : ''}">${s ? 'Played' : 'New'}</div>
      <h2>${L.name}</h2>
      <div class="meta"><span>${m.difficulty}</span><span>·</span><span>${m.genre}</span><span>·</span><span><b>${L.bpm}</b> BPM</span></div>
      <div class="mini-notation">${miniNotation(L)}</div>
      <div class="score-row">
        <div class="stars">${'★'.repeat(stars)}<span class="off">${'★'.repeat(3 - stars)}</span></div>
        <div>${s ? 'High: ' + s.high.toLocaleString() : '—'}</div>
      </div>
      ${tierPips}
    `;
    card.addEventListener('click', () => {
      switchTab('play');
      stopPlay();
      loadLesson(i);
      startPlay();
    });
    grid.appendChild(card);
  });
  highlightLibrary();
}

function loadLesson(idx){
  // Lazy import to avoid circular — main.js owns loadLesson
  // We dispatch a custom event instead
  document.dispatchEvent(new CustomEvent('loadLesson', { detail: { idx } }));
}

export function relTime(t){
  if (!t) return '—';
  const diff = (Date.now() - t) / 1000;
  if (diff < 60) return 'just now';
  if (diff < 3600) return Math.round(diff / 60) + 'm ago';
  if (diff < 86400) return Math.round(diff / 3600) + 'h ago';
  return Math.round(diff / 86400) + 'd ago';
}

export function refreshProgress(){
  const lessons = allLessons();

  // ── Calendar (real play days) ─────────────────────────────────────────────
  const cal = document.getElementById('calGrid');
  if (cal){
    cal.innerHTML = '';
    const playDays = getPlayDays();
    for (let i = 13; i >= 0; i--){
      const d = new Date();
      d.setDate(d.getDate() - i);
      const key = d.toISOString().slice(0, 10);
      const played = playDays.has(key);
      const cell = document.createElement('div');
      cell.className = 'cal-cell ' + (played ? 'l3' : '');
      cell.title = key;
      cal.appendChild(cell);
    }
  }

  // ── Aggregate stats ───────────────────────────────────────────────────────
  const scoreEntries = Object.values(State.scores);
  const totalNotes   = scoreEntries.reduce((a, s) => a + (s.plays || 0) * 50, 0);
  const bestScore    = scoreEntries.reduce((a, s) => Math.max(a, s.high || 0), 0);
  const topAcc       = scoreEntries.reduce((a, s) => Math.max(a, s.lastAcc || 0), 0);
  const playsCount   = scoreEntries.reduce((a, s) => a + (s.plays || 0), 0);

  const streak = getStreak();

  const setText = (id, v) => { const e = document.getElementById(id); if (e) e.textContent = v; };
  const psStreakEl = document.getElementById('psStreak');
  if (psStreakEl) psStreakEl.innerHTML = `${streak}<span class="accent">d</span>`;
  setText('psDelta', streak > 0 ? `${streak} day${streak !== 1 ? 's' : ''} and counting!` : 'keep playing!');
  setText('psNotes',  totalNotes.toLocaleString());
  setText('psWeekDelta', playsCount > 0 ? `${playsCount} session${playsCount !== 1 ? 's' : ''} total` : 'start playing!');
  setText('psCombo',  bestScore.toLocaleString());
  setText('psAcc',    topAcc ? topAcc + '%' : '—');
  setText('psTime',   playsCount);

  // ── Achievement grid ──────────────────────────────────────────────────────
  const grid = document.getElementById('achievementGrid');
  if (grid){
    grid.innerHTML = '';
    let earnedCount = 0;
    ACHIEVEMENTS.forEach(ach => {
      const unlocked = isUnlocked(ach.id);
      if (unlocked) earnedCount++;
      const tile = document.createElement('div');
      tile.className = 'ach-tile' + (unlocked ? ' earned' : ' locked');
      tile.innerHTML =
        `<div class="ach-ico">${unlocked ? ach.icon : '?'}</div>` +
        `<div class="ach-nm">${ach.name}</div>` +
        `<div class="ach-desc">${unlocked ? ach.desc : '???'}</div>`;
      grid.appendChild(tile);
    });
    setText('badgeCount', `${earnedCount} of ${ACHIEVEMENTS.length} earned`);
  }

  // ── Recent sessions ───────────────────────────────────────────────────────
  const r = document.getElementById('recentList');
  if (r){
    r.innerHTML = '';
    const recent = Object.entries(State.scores)
      .map(([k, v]) => ({ idx: +k, ...v }))
      .sort((a, b) => (b.when || 0) - (a.when || 0))
      .slice(0, 5);
    if (recent.length === 0){
      r.innerHTML = '<div style="font-family:\'Major Mono Display\',monospace;font-size:11px;color:var(--text-dim);padding:8px">no sessions yet — press play!</div>';
      return;
    }
    recent.forEach(x => {
      const lesson = lessons[x.idx];
      if (!lesson) return;
      const div = document.createElement('div');
      div.className = 'recent';
      div.innerHTML = `<div class="rdate">${relTime(x.when)}</div><div class="rname">${lesson.name}</div><div class="rscore">${x.high.toLocaleString()} · ${x.lastAcc || '-'}%</div>`;
      r.appendChild(div);
    });
  }
}

export function initLibraryMidiLoad(){
  const btn = document.getElementById('btnLoadMidi');
  const fileInput = document.getElementById('midiFileInput');
  if (!btn || !fileInput) return;

  btn.addEventListener('click', () => fileInput.click());

  fileInput.addEventListener('change', async (e) => {
    const file = e.target.files[0];
    if (!file) return;
    try {
      const buf = await file.arrayBuffer();
      const { ppq, events } = parseMidiFile(buf);
      const mappedEvents = events.map(ev => ({
        tick: ev.tick,
        lane: midiNoteToLane(ev.midiNote),
        velocity: ev.velocity,
      })).filter(ev => ev.lane !== undefined);

      const name = file.name.replace(/\.midi?$/i, '');
      const lesson = lessonFromMidiEvents(name, mappedEvents, ppq);
      State.extraLessons.push(lesson);
      saveExtraLessons();
      refreshLibrary();
      alert(`Loaded: "${name}" — ${mappedEvents.length} events`);
    } catch (err) {
      alert('Failed to parse MIDI file: ' + err.message);
    }
    fileInput.value = '';
  });
}

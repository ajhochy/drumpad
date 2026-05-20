// ===========================================================================
// Library + Progress tab rendering
// ===========================================================================
import { State } from './state.js';
import { LESSONS, LESSON_META, LANES, LANE_LABEL, lessonFromMidiEvents } from './lessons.js';
import { parseMidiFile, midiNoteToLane } from './midi-file.js';
import { stopPlay, startPlay } from './highway.js';

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
    subText.innerHTML = `${lessons.length} patches · sorted by difficulty<br>tap to load · firmware locked at v2.6`;
  }

  lessons.forEach((L, i) => {
    const m = meta[i] || { difficulty: 'Custom', genre: 'MIDI' };
    const s = State.scores[String(i)] || null;
    const num = String(i + 1).padStart(2, '0');
    const stars = s ? s.stars : 0;
    const card = document.createElement('div');
    card.className = 'lesson-card' + (i === State.currentLesson ? ' playing' : '');
    card.dataset.idx = i;
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

  // calendar
  const cal = document.getElementById('calGrid');
  if (cal){
    cal.innerHTML = '';
    const seed = Object.keys(State.scores).length || 3;
    for (let i = 0; i < 14; i++){
      const d = document.createElement('div');
      const v = ((i * 7 + seed * 3) % 11);
      const lvl = v > 8 ? 'l4' : v > 6 ? 'l3' : v > 3 ? 'l2' : v > 1 ? 'l1' : '';
      d.className = 'cal-cell ' + lvl;
      cal.appendChild(d);
    }
  }

  // aggregate stats
  const scoreEntries = Object.values(State.scores);
  const totalHits = scoreEntries.reduce((a, s) => a + (s.plays || 0) * 10, 0);
  const bestCombo = scoreEntries.reduce((a, s) => Math.max(a, s.high || 0), 0);
  const topAcc = scoreEntries.reduce((a, s) => Math.max(a, s.lastAcc || 0), 0);
  const playsCount = scoreEntries.reduce((a, s) => a + (s.plays || 0), 0);

  const psNotes = document.getElementById('psNotes');
  if (psNotes) psNotes.textContent = totalHits.toLocaleString();
  const psCombo = document.getElementById('psCombo');
  if (psCombo) psCombo.textContent = bestCombo.toLocaleString();
  const psAcc = document.getElementById('psAcc');
  if (psAcc) psAcc.textContent = topAcc ? topAcc + '%' : '—';
  const psTime = document.getElementById('psTime');
  if (psTime) psTime.textContent = playsCount;

  // badges
  const allPlayed = Object.keys(State.scores).length >= lessons.length;
  const hasRock = State.scores['0'] != null;
  const hasFirst = Object.keys(State.scores).length > 0;
  const has100Combo = scoreEntries.some(s => s.high >= 5000);
  const has99Acc = scoreEntries.some(s => (s.lastAcc || 0) >= 99);

  function setBadge(id, earned){
    const el = document.getElementById(id);
    if (!el) return;
    if (earned){
      el.classList.add('earned');
      el.classList.remove('locked');
    } else {
      el.classList.remove('earned');
      el.classList.add('locked');
    }
  }
  setBadge('badge-rock', hasRock);
  setBadge('badge-combo', has100Combo);
  setBadge('badge-first', hasFirst);
  setBadge('badge-sharp', has99Acc);
  setBadge('badge-grad', allPlayed);

  const earned = [hasRock, has100Combo, hasFirst, false, has99Acc, allPlayed].filter(Boolean).length;
  const bc = document.getElementById('badgeCount');
  if (bc) bc.textContent = `${earned} of 6 earned`;

  // recent list
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
      const ago = relTime(x.when);
      div.innerHTML = `<div class="rdate">${ago}</div><div class="rname">${lesson.name}</div><div class="rscore">${x.high.toLocaleString()} · ${x.lastAcc || '-'}%</div>`;
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
      refreshLibrary();
      alert(`Loaded: "${name}" — ${mappedEvents.length} events`);
    } catch (err) {
      alert('Failed to parse MIDI file: ' + err.message);
    }
    fileInput.value = '';
  });
}

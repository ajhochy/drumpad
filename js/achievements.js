// ===========================================================================
// Achievement system — definitions, persistence, checks, toasts
// ===========================================================================
import { State } from './state.js';
import { LESSONS } from './lessons.js';
import { rollDrumrot, showDrumrotReveal } from './drumrots.js';

export const ACHIEVEMENTS = [
  // Performance
  { id: 'first_hit',     name: 'First Hit',       desc: 'Hit your first note',                 icon: '★', cat: 'performance' },
  { id: 'combo_50',      name: 'On a Roll',        desc: '50× combo unbroken',                 icon: '⚡', cat: 'performance' },
  { id: 'combo_100',     name: '100× Combo',       desc: '100× combo unbroken',                icon: '⚡', cat: 'performance' },
  { id: 'combo_200',     name: 'Unstoppable',      desc: '200× combo unbroken',                icon: '☄',  cat: 'performance' },
  { id: 'sharpshooter',  name: 'Sharpshooter',     desc: '90%+ accuracy 3 passes in a row',    icon: '⊕', cat: 'performance' },
  { id: 'perfect_pass',  name: 'Flawless',         desc: '100% accuracy on a full pass',       icon: '✦', cat: 'performance' },
  // Consistency
  { id: 'first_pass',    name: 'First Patch',      desc: 'Complete your first lesson',         icon: '●', cat: 'consistency' },
  { id: 'groove_master', name: 'Groove Master',    desc: '3 stars on any groove',              icon: '★', cat: 'consistency' },
  { id: 'all_grooves',   name: 'Full Set',         desc: 'Play every prebuilt lesson',         icon: '▣', cat: 'consistency' },
  { id: 'graduate',      name: 'Graduate',         desc: '3 stars on all prebuilt grooves',    icon: '♛', cat: 'consistency' },
  { id: 'streak_3',      name: '3 Day Streak',     desc: 'Practice 3 days in a row',           icon: '◆', cat: 'consistency' },
  { id: 'streak_7',      name: '7 Day Streak',     desc: 'Practice 7 days in a row',           icon: '◆', cat: 'consistency' },
  // Tempo
  { id: 'tempo_climber', name: 'Tempo Climber',    desc: 'Reach Grooving tier on 3 grooves',   icon: '↑', cat: 'tempo' },
  { id: 'full_throttle', name: 'Full Throttle',    desc: 'Reach Killing It tier on 5 grooves', icon: '⚑', cat: 'tempo' },
  { id: 'speed_demon',   name: 'Speed Demon',      desc: 'Play any groove at 160+ BPM (80%+)', icon: '▶', cat: 'tempo' },
  { id: 'slow_burn',     name: 'Slow Burn',        desc: 'Play any groove at ≤60 BPM (80%+)',  icon: '◐', cat: 'tempo' },
  // Builder
  { id: 'creator',       name: 'Creator',          desc: 'Build your first groove pattern',    icon: '✎', cat: 'builder' },
  { id: 'coach',         name: 'Coach',            desc: 'Attach a coach note to a pattern',   icon: '✍', cat: 'builder' },
];

export const TIER_NAMES  = ['Steady', 'Grooving', 'Locked', 'Killing It'];
export const TIER_COLORS = ['#5cf07d', '#ff8a1e', '#ff3a5a', '#ff2a7a'];

// ── Persistence helpers ───────────────────────────────────────────────────────
function loadUnlocked(){ return new Set(JSON.parse(localStorage.getItem('drum.achievements') || '[]')); }
function saveUnlocked(s){ localStorage.setItem('drum.achievements', JSON.stringify([...s])); }

function loadTiers(){ return JSON.parse(localStorage.getItem('drum.tiers') || '{}'); }
function saveTiers(t){ localStorage.setItem('drum.tiers', JSON.stringify(t)); }

function loadPlayDays(){ return new Set(JSON.parse(localStorage.getItem('drum.playDays') || '[]')); }
function savePlayDays(s){ localStorage.setItem('drum.playDays', JSON.stringify([...s])); }

function todayKey(){ return new Date().toISOString().slice(0, 10); }

export function isUnlocked(id){ return loadUnlocked().has(id); }

export function getHighestTier(lessonIdx){
  const t = loadTiers()[String(lessonIdx)];
  return t !== undefined ? t : -1;
}

export function getStreak(){
  const days = loadPlayDays();
  let streak = 0;
  const d = new Date();
  for (let i = 0; i < 365; i++){
    if (!days.has(d.toISOString().slice(0, 10))) break;
    streak++;
    d.setDate(d.getDate() - 1);
  }
  return streak;
}

export function getPlayDays(){ return loadPlayDays(); }

// ── Toast ─────────────────────────────────────────────────────────────────────
let _toastQueue = [];
let _toastBusy  = false;

function drainToastQueue(){
  if (_toastBusy || _toastQueue.length === 0) return;
  _toastBusy = true;
  const ach = _toastQueue.shift();

  let toast = document.getElementById('achievementToast');
  if (!toast){
    toast = document.createElement('div');
    toast.id = 'achievementToast';
    document.body.appendChild(toast);
  }
  toast.innerHTML =
    `<div class="toast-icon">${ach.icon}</div>` +
    `<div class="toast-body"><div class="toast-name">${ach.name}</div><div class="toast-desc">${ach.desc}</div></div>`;
  toast.classList.add('show');

  setTimeout(() => {
    toast.classList.remove('show');
    setTimeout(() => { _toastBusy = false; drainToastQueue(); }, 500);
  }, 3000);
}

function queueToast(ach){
  _toastQueue.push(ach);
  drainToastQueue();
}

// ── Tier calculation ──────────────────────────────────────────────────────────
function tierForPass(acc, bpm, lessonBpm){
  if (acc >= 90 && bpm >= lessonBpm + 60) return 3; // Killing It
  if (acc >= 80 && bpm >= lessonBpm + 40) return 2; // Locked
  if (acc >= 80 && bpm >= lessonBpm + 20) return 1; // Grooving
  if (acc >= 80 && bpm >= lessonBpm - 10) return 0; // Steady
  return -1;
}

// ── Main check — call after relevant actions ──────────────────────────────────
export function checkAchievements({ onHit = false, onPass = false, onCreator = false, onCoach = false } = {}){
  const unlocked = loadUnlocked();
  const tiers    = loadTiers();
  const earned   = [];

  function earn(id){
    if (!unlocked.has(id)){
      unlocked.add(id);
      const ach = ACHIEVEMENTS.find(a => a.id === id);
      if (ach) earned.push(ach);
    }
  }

  // ── Hit-time checks ───────────────────────────────────────────────────────
  if (onHit){
    if (State.hits >= 1)   earn('first_hit');
    if (State.combo >= 50)  earn('combo_50');
    if (State.combo >= 100) earn('combo_100');
    if (State.combo >= 200) earn('combo_200');
  }

  // ── Pass-complete checks ──────────────────────────────────────────────────
  if (onPass){
    const playDays = loadPlayDays();
    playDays.add(todayKey());
    savePlayDays(playDays);

    earn('first_pass');

    const total   = State.notes.length;
    const passAcc = total > 0 ? Math.round(State.hits / total * 100) : 0;

    if (passAcc === 100) earn('perfect_pass');

    if (passAcc >= 90){
      State.consecutiveAccuratePasses = (State.consecutiveAccuratePasses || 0) + 1;
    } else {
      State.consecutiveAccuratePasses = 0;
    }
    if (State.consecutiveAccuratePasses >= 3) earn('sharpshooter');

    const stars = passAcc >= 95 ? 3 : passAcc >= 80 ? 2 : passAcc >= 50 ? 1 : 0;
    if (stars === 3) earn('groove_master');

    // All prebuilt grooves played
    const prebuiltKeys = LESSONS.map((_, i) => String(i));
    if (prebuiltKeys.length > 0 && prebuiltKeys.every(k => State.scores[k])){
      earn('all_grooves');
    }
    // Graduate: all prebuilt grooves with 3 stars
    if (prebuiltKeys.length > 0 && prebuiltKeys.every(k => (State.scores[k]?.stars || 0) >= 3)){
      earn('graduate');
    }

    // Day streak
    const streak = getStreak();
    if (streak >= 3) earn('streak_3');
    if (streak >= 7) earn('streak_7');

    // BPM extremes
    if (passAcc >= 80 && State.bpm >= 160) earn('speed_demon');
    if (passAcc >= 80 && State.bpm <= 60)  earn('slow_burn');

    // Tempo tiers — only for prebuilt lessons
    const lessonIdx = State.currentLesson;
    if (lessonIdx < LESSONS.length){
      const lessonBpm = LESSONS[lessonIdx].bpm;
      const tier = tierForPass(passAcc, State.bpm, lessonBpm);
      if (tier >= 0){
        const key  = String(lessonIdx);
        const prev = tiers[key] !== undefined ? tiers[key] : -1;
        if (tier > prev) tiers[key] = tier;
      }
    }
    saveTiers(tiers);

    const groovingCount = Object.values(tiers).filter(t => t >= 1).length;
    const killingCount  = Object.values(tiers).filter(t => t >= 3).length;
    if (groovingCount >= 3) earn('tempo_climber');
    if (killingCount  >= 5) earn('full_throttle');
  }

  // ── Builder checks ────────────────────────────────────────────────────────
  if (onCreator) earn('creator');
  if (onCoach)   earn('coach');

  saveUnlocked(unlocked);
  earned.forEach((ach, i) => {
    queueToast(ach);
    // Roll a drumrot for this achievement — staggered after the toast sequence
    const delay = i * 4500 + 3200;
    setTimeout(() => {
      const { drumrot, tierKey } = rollDrumrot(ach.id);
      showDrumrotReveal(drumrot, tierKey, ach.name);
    }, delay);
  });
  return earned;
}

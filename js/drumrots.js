// ===========================================================================
// Drumrot Collection — characters, drop rolls, card renderer, collection tab
// ===========================================================================

// ── Tier config ───────────────────────────────────────────────────────────────
export const TIER_CONFIG = {
  common:      { name: 'Common',      color: '#9aa5b4', idx: 0 },
  rare:        { name: 'Rare',        color: '#3b82f6', idx: 1 },
  epic:        { name: 'Epic',        color: '#a855f7', idx: 2 },
  legendary:   { name: 'Legendary',   color: '#f59e0b', idx: 3 },
  mythic:      { name: 'Mythic',      color: '#ec4899', idx: 4 },
  drumrot_god: { name: 'Drumrot God', color: '#ff3a5a', idx: 5 },
  og:          { name: 'OG',          color: '#ffffff', idx: 6 },
};

export const TIERS_ORDER = ['common','rare','epic','legendary','mythic','drumrot_god','og'];

// ── Achievement → difficulty ──────────────────────────────────────────────────
const ACHIEVEMENT_DIFFICULTY = {
  first_hit:     'easy',
  first_pass:    'easy',
  creator:       'easy',
  combo_50:      'medium',
  groove_master: 'medium',
  streak_3:      'medium',
  slow_burn:     'medium',
  speed_demon:   'medium',
  coach:         'medium',
  combo_100:     'hard',
  sharpshooter:  'hard',
  all_grooves:   'hard',
  tempo_climber: 'hard',
  streak_7:      'hard',
  combo_200:     'elite',
  perfect_pass:  'elite',
  graduate:      'elite',
  full_throttle: 'elite',
};

// Weights per difficulty: [Common, Rare, Epic, Legendary, Mythic, DrumrotGod, OG]
// OG column stays 0 here — OG is handled by the separate 5% flat bonus
const TIER_WEIGHTS = {
  easy:   [55, 35,  8,  2,  0,  0, 0],
  medium: [20, 40, 25, 10,  4,  1, 0],
  hard:   [ 5, 15, 35, 30, 12,  3, 0],
  elite:  [ 0,  5, 20, 35, 25, 15, 0],
};

const OG_CHANCE = 0.05; // 5% flat upgrade to OG on any achievement

// ── Drumrot roster ────────────────────────────────────────────────────────────
export const DRUMROTS = [
  // COMMON ── ── ── ── ── ── ── ── ── ── ── ── ──
  {
    id: 'tung_tung_tamburino', tier: 'common', num: '001', art: '🥢🥢🥢',
    name: 'Tung Tung Tung Tung Tung Tamburino',
    sub: 'common · percussion being',
    flavor: 'The first drumrot ever summoned. Hits things. Does not stop. Has never stopped.',
    bpm: 60, groove: 2, power: 1,
  },
  {
    id: 'drumbeano_crocodilio', tier: 'common', num: '002', art: '🐊🫘',
    name: 'Drumbeano Crocodilio',
    sub: 'common · rimshot lizard',
    flavor: 'Emerged from a broken drum machine in Naples. Speaks only in rimshots.',
    bpm: 70, groove: 3, power: 2,
  },
  {
    id: 'kickarino_pinguino', tier: 'common', num: '003', art: '🐧🦵',
    name: 'Kickarino Pinguino',
    sub: 'common · kick enthusiast',
    flavor: 'Tiny penguin with enormous kick drum energy. Slides on every beat.',
    bpm: 75, groove: 3, power: 2,
  },
  {
    id: 'snappini_gattonini', tier: 'common', num: '004', art: '🐱💥',
    name: 'Snappini Gattonini',
    sub: 'common · domestic snapper',
    flavor: 'Domestic cat who discovered snare drums at age three. Never recovered.',
    bpm: 80, groove: 4, power: 3,
  },
  // RARE ── ── ── ── ── ── ── ── ── ── ── ── ──
  {
    id: 'bassolo_gorillini', tier: 'rare', num: '005', art: '🦍🎸',
    name: 'Bassolo Gorillini',
    sub: 'rare · low frequency primate',
    flavor: 'Plays bass with one finger. That is enough.',
    bpm: 85, groove: 5, power: 5,
  },
  {
    id: 'rimshottino_elefantino', tier: 'rare', num: '006', art: '🐘💥',
    name: 'Rimshottino Elefantino',
    sub: 'rare · precision mammal',
    flavor: 'Never misses a rimshot. This has been verified across four continents.',
    bpm: 88, groove: 6, power: 5,
  },
  {
    id: 'brrr_brrr_batteria', tier: 'rare', num: '007', art: '🐧❄️',
    name: 'Brrr Brrr Batteria',
    sub: 'rare · cold percussionist',
    flavor: 'Cold-blooded percussionist. Cannot explain the sound it makes. Neither can anyone else.',
    bpm: 92, groove: 6, power: 6,
  },
  {
    id: 'hihatini_serpentino', tier: 'rare', num: '008', art: '🐍🎩',
    name: 'Hihatini Serpentino',
    sub: 'rare · time-keeping serpent',
    flavor: 'Coils around the hi-hat stand. Keeps perfect time. Highly unnerving.',
    bpm: 95, groove: 7, power: 6,
  },
  // EPIC ── ── ── ── ── ── ── ── ── ── ── ── ──
  {
    id: 'bombardino_crashcino', tier: 'epic', num: '009', art: '🐊💥',
    name: 'Bombardino Crashcino',
    sub: 'epic · half croc half cymbal',
    flavor: 'Half crocodile, half crash cymbal. One hundred percent chaos.',
    bpm: 100, groove: 8, power: 9,
  },
  {
    id: 'cappuccino_tamburino', tier: 'epic', num: '010', art: '☕🥁',
    name: 'Cappuccino Tamburino',
    sub: 'epic · caffeinated drummer',
    flavor: 'Drinks espresso before every performance. Also during. Also after.',
    bpm: 102, groove: 9, power: 8,
  },
  {
    id: 'velociraptorino_rullante', tier: 'epic', num: '011', art: '🦖🥁',
    name: 'Velociraptorino Rullante',
    sub: 'epic · prehistoric roll master',
    flavor: 'Plays a drum roll faster than you can see. Also faster than you can hear.',
    bpm: 110, groove: 9, power: 10,
  },
  {
    id: 'quattro_quattro_pesci', tier: 'epic', num: '012', art: '🐟🎼',
    name: 'Quattro Quattro Pesciolino',
    sub: 'epic · time signature fish',
    flavor: 'Lives exactly in 4/4 time. Placed in 7/8, it simply ceases to exist.',
    bpm: 108, groove: 10, power: 9,
  },
  {
    id: 'brrr_paradiddlini', tier: 'epic', num: '013', art: '🐧🥢',
    name: 'Brrr Brrr Paradiddlini',
    sub: 'epic · rudiment penguin',
    flavor: 'Distant cousin of Brrr Brrr Batteria. Knows all 40 rudiments by memory.',
    bpm: 115, groove: 10, power: 10,
  },
  // LEGENDARY ── ── ── ── ── ── ── ── ── ── ── ── ──
  {
    id: 'trippelini_boomolini', tier: 'legendary', num: '014', art: '💣🎵',
    name: 'Trippelini Boomolini',
    sub: 'legendary · triplet deity',
    flavor: 'Thinks in triplets. Lives in triplets. Will die in triplets.',
    bpm: 120, groove: 13, power: 14,
  },
  {
    id: 'snarlarello_magnifico', tier: 'legendary', num: '015', art: '🦁🥢',
    name: 'Snarlarello Magnifico',
    sub: 'legendary · lion of the snare',
    flavor: 'The crack of its snare was heard from three villages away. Still echoing.',
    bpm: 125, groove: 14, power: 15,
  },
  {
    id: 'griddarello_metronomo', tier: 'legendary', num: '016', art: '⏱️😤',
    name: 'Griddarello del Metronomo',
    sub: 'legendary · fused with time',
    flavor: 'Born fused to a metronome. Cannot be rushed. Cannot be slowed. Cannot be stopped.',
    bpm: 130, groove: 15, power: 14,
  },
  {
    id: 'poliritmico_coccodrillo', tier: 'legendary', num: '017', art: '🐊🌀',
    name: 'Poliritmico Coccodrillo',
    sub: 'legendary · crocodile of 5 vs 3',
    flavor: 'Plays 5 against 3 while sleeping. This is disturbing. Also impressive.',
    bpm: 135, groove: 15, power: 16,
  },
  // MYTHIC ── ── ── ── ── ── ── ── ── ── ── ── ──
  {
    id: 'lirili_beatlarila', tier: 'mythic', num: '018', art: '🐘🌊',
    name: 'Lirili Beatlarila',
    sub: 'mythic · ancient rhythm spirit',
    flavor: 'Descended from ancient rhythm spirits. The groove precedes the beat.',
    bpm: 140, groove: 18, power: 20,
  },
  {
    id: 'frigo_bassolo_camelini', tier: 'mythic', num: '019', art: '🐪❄️',
    name: 'Frigo Bassolo Camelini',
    sub: 'mythic · camel of the low end',
    flavor: 'Stores the low end in its humps. Releases it only on beat one. Only.',
    bpm: 145, groove: 20, power: 21,
  },
  {
    id: 'sincopato_del_vento', tier: 'mythic', num: '020', art: '🌪️🎸',
    name: 'Sincopato del Vento',
    sub: 'mythic · child of the offbeat',
    flavor: 'Born between the beats. Lives in the spaces nobody else can hear.',
    bpm: 148, groove: 22, power: 22,
  },
  {
    id: 'maestro_falsetto_drumini', tier: 'mythic', num: '021', art: '🎩🥢',
    name: 'Il Maestro Falsetto Drumini',
    sub: 'mythic · conductor of chaos',
    flavor: 'Conducts full orchestras using only drumsticks. Orchestras fear him deeply.',
    bpm: 150, groove: 23, power: 24,
  },
  // DRUMROT GOD ── ── ── ── ── ── ── ── ── ── ── ── ──
  {
    id: 'tamburino_cosmico', tier: 'drumrot_god', num: '022', art: '🌌🥁',
    name: 'Il Tamburino Cosmico',
    sub: 'drumrot god · cosmic drummer',
    flavor: 'The universe beats at his tempo. Not the other way around.',
    bpm: 160, groove: 28, power: 30,
  },
  {
    id: 'bombardino_quattro_tempi', tier: 'drumrot_god', num: '023', art: '💣🎼',
    name: 'Bombardino Quattro Tempi',
    sub: 'drumrot god · master of all time',
    flavor: 'Once played a perfect 4/4 groove. Time itself stopped. It has not fully resumed.',
    bpm: 170, groove: 30, power: 35,
  },
  // OG ── ── ── ── ── ── ── ── ── ── ── ── ──
  {
    id: 'grande_maestro_drumbeano', tier: 'og', num: '024', art: '🌌👑🥁',
    name: 'Il Grande Maestro Drumbeano',
    sub: 'OG · the original',
    flavor: 'The original drumrot. All others are echoes of him. Nobody has heard the full performance.',
    bpm: 999, groove: 99, power: 99,
  },
  {
    id: 'doppio_paradiddle_supremo', tier: 'og', num: '025', art: '✨🥢🥢✨',
    name: 'Doppio Paradiddle Supremo',
    sub: 'OG · the unknowable',
    flavor: 'Has never played a wrong note. Has never played the same note twice. Unknowable.',
    bpm: 999, groove: 99, power: 99,
  },
];

// ── Drop roll ─────────────────────────────────────────────────────────────────
export function rollDrumrot(achievementId){
  const difficulty = ACHIEVEMENT_DIFFICULTY[achievementId] || 'easy';

  // 5% flat chance: straight to OG regardless of difficulty
  let tierKey;
  if (Math.random() < OG_CHANCE){
    tierKey = 'og';
  } else {
    const weights = TIER_WEIGHTS[difficulty];
    const roll = Math.random() * 100;
    let cum = 0;
    let tierIdx = 0;
    for (let i = 0; i < weights.length; i++){
      cum += weights[i];
      if (roll < cum){ tierIdx = i; break; }
    }
    tierKey = TIERS_ORDER[tierIdx];
  }

  // Pick random drumrot with that tier assignment
  const pool = DRUMROTS.filter(d => d.tier === tierKey);
  const source = pool.length > 0 ? pool : DRUMROTS;
  const drumrot = source[Math.floor(Math.random() * source.length)];
  return { drumrot, tierKey };
}

// ── Collection persistence ────────────────────────────────────────────────────
export function loadCollection(){
  return JSON.parse(localStorage.getItem('drum.collection') || '{}');
  // { drumrotId: tierIdx (0-6) }
}

function saveCollection(col){
  localStorage.setItem('drum.collection', JSON.stringify(col));
}

// Returns true if this is new or an upgrade
export function addToCollection(drumrotId, tierKey){
  const col = loadCollection();
  const newIdx = TIER_CONFIG[tierKey]?.idx ?? 0;
  const curIdx = col[drumrotId] ?? -1;
  if (newIdx > curIdx){
    col[drumrotId] = newIdx;
    saveCollection(col);
    return true;
  }
  return false;
}

// ── Card renderer ─────────────────────────────────────────────────────────────
export function renderDrumrotCard(drumrot, tierKey, locked = false){
  if (locked){
    return `
      <div class="drumrot-card tier-locked">
        <div class="dc-tier-banner">???</div>
        <div class="dc-portrait"><div class="dc-art">?</div></div>
        <div class="dc-nameplate">
          <div class="dc-name">???</div>
          <div class="dc-subtitle">unknown drumrot</div>
        </div>
        <div class="dc-flavor">Not yet collected.</div>
        <div class="dc-stats">
          <div class="dc-stat"><span class="dc-stat-lbl">BPM</span><span class="dc-stat-val">—</span></div>
          <div class="dc-stat"><span class="dc-stat-lbl">GRV</span><span class="dc-stat-val">—</span></div>
          <div class="dc-stat"><span class="dc-stat-lbl">PWR</span><span class="dc-stat-val">—</span></div>
        </div>
        <div class="dc-footer">
          <span class="dc-num">${drumrot.num}</span>
          <span class="dc-brand">SP-808 KILLA</span>
        </div>
      </div>`;
  }

  const tier = TIER_CONFIG[tierKey] || TIER_CONFIG.common;
  const isOG = tierKey === 'og';
  const bpmDisplay = drumrot.bpm >= 999 ? '∞' : drumrot.bpm;

  return `
    <div class="drumrot-card tier-${tierKey}">
      <div class="dc-tier-banner" style="color:${tier.color}">${tier.name.toUpperCase()}</div>
      <div class="dc-portrait">
        <div class="dc-art">${drumrot.art}</div>
        ${isOG ? '<div class="dc-og-shimmer"></div>' : ''}
      </div>
      <div class="dc-nameplate">
        <div class="dc-name">${drumrot.name}</div>
        <div class="dc-subtitle">${drumrot.sub}</div>
      </div>
      <div class="dc-flavor">"${drumrot.flavor}"</div>
      <div class="dc-stats">
        <div class="dc-stat"><span class="dc-stat-lbl">BPM</span><span class="dc-stat-val">${bpmDisplay}</span></div>
        <div class="dc-stat"><span class="dc-stat-lbl">GRV</span><span class="dc-stat-val">${drumrot.groove}</span></div>
        <div class="dc-stat"><span class="dc-stat-lbl">PWR</span><span class="dc-stat-val">${drumrot.power}</span></div>
      </div>
      <div class="dc-footer">
        <span class="dc-num">${drumrot.num}</span>
        <span class="dc-brand">SP-808 KILLA</span>
      </div>
    </div>`;
}

// ── Reveal overlay ────────────────────────────────────────────────────────────
let _revealQueue = [];
let _revealBusy  = false;

function drainRevealQueue(){
  if (_revealBusy || _revealQueue.length === 0) return;
  _revealBusy = true;
  const { drumrot, tierKey, fromAchievement } = _revealQueue.shift();

  const overlay = document.getElementById('drumrotReveal');
  if (!overlay){ _revealBusy = false; return; }

  const isOG = tierKey === 'og';
  const isNew = addToCollection(drumrot.id, tierKey);

  document.getElementById('drAchName').textContent = fromAchievement;
  document.getElementById('drCard').innerHTML = renderDrumrotCard(drumrot, tierKey, false);

  // Show new/upgrade badge
  const badge = document.getElementById('drNewBadge');
  if (badge) badge.textContent = isNew ? (isOG ? '⭐ FIRST OG!' : '✦ NEW!') : '↑ UPGRADED TIER';

  overlay.className = 'dr-active' + (isOG ? ' dr-og' : '');

  function dismiss(){
    overlay.className = 'dr-hiding';
    setTimeout(() => {
      overlay.className = '';
      _revealBusy = false;
      // Refresh Drops tab if open
      const dropsPanel = document.getElementById('panel-drops');
      if (dropsPanel?.classList.contains('active')) initDropsTab();
      drainRevealQueue();
    }, 400);
    overlay.removeEventListener('click', dismiss);
  }

  overlay.addEventListener('click', dismiss);
  setTimeout(dismiss, isOG ? 9000 : 6000);
}

export function showDrumrotReveal(drumrot, tierKey, fromAchievement){
  _revealQueue.push({ drumrot, tierKey, fromAchievement });
  drainRevealQueue();
}

// ── Drops tab renderer ────────────────────────────────────────────────────────
export function initDropsTab(){
  const grid = document.getElementById('dropsGrid');
  if (!grid) return;

  const col = loadCollection();
  const collected = Object.keys(col).length;

  const countEl = document.getElementById('dropsCount');
  if (countEl) countEl.textContent = `${collected} / ${DRUMROTS.length} collected`;

  grid.innerHTML = '';
  DRUMROTS.forEach(drumrot => {
    const tierIdx = col[drumrot.id];
    const hasIt   = tierIdx !== undefined;
    const tierKey = hasIt ? TIERS_ORDER[tierIdx] : null;

    const wrap = document.createElement('div');
    wrap.className = 'drops-card-wrap';
    wrap.innerHTML = renderDrumrotCard(drumrot, tierKey || drumrot.tier, !hasIt);
    grid.appendChild(wrap);
  });
}

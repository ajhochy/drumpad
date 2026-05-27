// ===========================================================================
// Drumrot Collection — characters, drop rolls, card renderer, collection tab
// ===========================================================================

// ── Tier config ───────────────────────────────────────────────────────────────
export const TIER_CONFIG = {
  common:    { name: 'Common',      label: 'COMMON',        color: '#9aa5b4', idx: 0 },
  rare:      { name: 'Rare',        label: 'RARE',          color: '#3b82f6', idx: 1 },
  epic:      { name: 'Epic',        label: 'EPIC',          color: '#a855f7', idx: 2 },
  legendary: { name: 'Legendary',   label: 'LEGENDARY',     color: '#f59e0b', idx: 3 },
  mythic:    { name: 'Mythic',      label: 'MYTHIC',        color: '#ec4899', idx: 4 },
  god:       { name: 'Drumrot God', label: 'DRUMROT GOD',   color: '#ff3a5a', idx: 5 },
  og:        { name: 'OG',          label: 'OG · PRISMATIC', color: '#ffffff', idx: 6 },
};

export const TIERS_ORDER = ['common','rare','epic','legendary','mythic','god','og'];

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

// Weights per difficulty: [Common, Rare, Epic, Legendary, Mythic, God, OG]
// OG column stays 0 here — OG is handled by the separate 5% flat bonus
const TIER_WEIGHTS = {
  easy:   [55, 35,  8,  2,  0,  0, 0],
  medium: [20, 40, 25, 10,  4,  1, 0],
  hard:   [ 5, 15, 35, 30, 12,  3, 0],
  elite:  [ 0,  5, 20, 35, 25, 15, 0],
};

const OG_CHANCE = 0.05; // 5% flat upgrade to OG on any achievement

// ── Drumrot roster ────────────────────────────────────────────────────────────
// Stats are stored as numbers. The render layer maps 99 → '∞' (bpm/groove on OG)
// or 'MAX' (power on og/god). See renderDrumrotCard for the display rules.
export const DRUMROTS = [
  // COMMON ── ── ── ── ── ── ── ── ── ── ── ── ──
  {
    id: 'tung_tung_tamburino', tier: 'common', num: '001', emoji: '🥢🥢🥢',
    name: 'Tung Tung Tung Tung Tung Tamburino',
    sub: 'common · timekeeping fool',
    flavor: 'Shows up at every soundcheck holding three sticks. Has been counting the band in since 1974. Will not stop.',
    bpm: 88, groove: 24, power: 19,
    parody: 'Tung Tung Tung Sahur',
    parodyImg: 'brainrots/Miscellaneous/Tung_Tung_Tung_Sahur.png',
    drumrotImg: 'art/drumrots/tung_tung_tamburino.webp',
  },
  {
    id: 'drumbeano_crocodilio', tier: 'common', num: '002', emoji: '🐊🫘',
    name: 'Drumbeano Crocodilio',
    sub: 'common · rimshot lizard',
    flavor: 'Emerged from a broken drum machine in Naples. Speaks only in rimshots. The faceplate is still warm.',
    bpm: 92, groove: 34, power: 21,
    parody: 'Bombardiro Crocodilo',
    parodyImg: 'brainrots/Mythic/Bombardiro_Crocodilo.png',
    drumrotImg: 'art/drumrots/drumbeano_crocodilio.webp',
  },
  {
    id: 'kickarino_pinguino', tier: 'common', num: '003', emoji: '🐧🦵',
    name: 'Kickarino Pinguino',
    sub: 'common · sub-zero kicker',
    flavor: 'Was a goalkeeper in a former life. Now plays kick drum exclusively with the left foot. Slides between fills.',
    bpm: 84, groove: 28, power: 30,
    parody: 'Penguino Cocosino',
    parodyImg: 'brainrots/Epic/Penguino_Cocosino.png',
    drumrotImg: 'art/drumrots/kickarino_pinguino.webp',
  },
  {
    id: 'snappini_gattonini', tier: 'common', num: '004', emoji: '🐱🥁',
    name: 'Snappini Gattonini',
    sub: 'common · snare nuisance',
    flavor: 'Knocks the snare off the rack twice per session. Calls it the swing. Refuses to acknowledge the click.',
    bpm: 96, groove: 38, power: 22,
    parody: 'Gattatino Nyanino',
    parodyImg: 'brainrots/Brainrot_God/Gattatino_Nyanino.png',
    drumrotImg: 'art/drumrots/snappini_gattonini.webp',
  },
  // RARE ── ── ── ── ── ── ── ── ── ── ── ── ──
  {
    id: 'bassolo_gorillini', tier: 'rare', num: '005', emoji: '🦍🎸',
    name: 'Bassolo Gorillini',
    sub: 'rare · low-end primate',
    flavor: 'Plays bass through a guitar amp on purpose. Believes the low end is a personal favor he is doing for you.',
    bpm: 102, groove: 48, power: 52,
    parody: 'Gorillo Subwoofero',
    parodyImg: 'brainrots/Mythic/Gorillo_Subwoofero.png',
    drumrotImg: 'art/drumrots/bassolo_gorillini.webp',
  },
  {
    id: 'rimshottino_elefantino', tier: 'rare', num: '006', emoji: '🐘💥',
    name: 'Rimshottino Elefantino',
    sub: 'rare · single-shot heavyweight',
    flavor: 'One rimshot every eight bars, perfectly placed. Then naps. Then another. The naps are part of the part.',
    bpm: 108, groove: 55, power: 44,
    parody: 'Cocofanto Elefanto',
    parodyImg: 'brainrots/Brainrot_God/Cocofanto_Elefanto.png',
    drumrotImg: 'art/drumrots/rimshottino_elefantino.webp',
  },
  {
    id: 'brrr_brrr_batteria', tier: 'rare', num: '007', emoji: '🐧❄️',
    name: 'Brrr Brrr Batteria',
    sub: 'rare · vibrating biped',
    flavor: 'Vibrates instead of breathing. The cymbals shiver when nobody is touching them. Nobody asks about it.',
    bpm: 112, groove: 52, power: 38,
    parody: 'Brr Brr Patapim',
    parodyImg: 'brainrots/Epic/Brr_Brr_Patapim.png',
    drumrotImg: 'art/drumrots/brrr_brrr_batteria.webp',
  },
  {
    id: 'hihatini_serpentino', tier: 'rare', num: '008', emoji: '🐍🎩',
    name: 'Hihatini Serpentino',
    sub: 'rare · top-hatted hisser',
    flavor: 'Hi-hats so tight they hiss back. Wears a very small top hat at all times. Demands you tip it.',
    bpm: 114, groove: 60, power: 41,
    parody: 'Brri Brri Bicus Dicus Bombicus',
    parodyImg: 'brainrots/Epic/Brri_Brri_Bicus_Dicus_Bombicus.png',
    drumrotImg: 'art/drumrots/hihatini_serpentino.webp',
  },
  // EPIC ── ── ── ── ── ── ── ── ── ── ── ── ──
  {
    id: 'bombardino_crashcino', tier: 'epic', num: '009', emoji: '🐊🔔',
    name: 'Bombardino Crashcino',
    sub: 'epic · cymbal vandal',
    flavor: 'Hits the crash like it owes him money. The cymbal owes him money. Nobody will say from where.',
    bpm: 122, groove: 68, power: 66,
    parody: 'Bombombini Gusini',
    parodyImg: 'brainrots/Mythic/Bombombini_Gusini.png',
    drumrotImg: 'art/drumrots/bombardino_crashcino.webp',
  },
  {
    id: 'cappuccino_tamburino', tier: 'epic', num: '010', emoji: '☕🥁',
    name: 'Cappuccino Tamburino',
    sub: 'epic · 6/8 barista',
    flavor: 'Plays in 6/8 because the foam needs it. Tastes faintly of paradiddles. Refuses to perform before 11am.',
    bpm: 118, groove: 72, power: 58,
    parody: 'Cappuccino Assassino',
    parodyImg: 'brainrots/Epic/Cappuccino_Assassino.png',
    drumrotImg: 'art/drumrots/cappuccino_tamburino.webp',
  },
  {
    id: 'velociraptorino_rullante', tier: 'epic', num: '011', emoji: '🦖🥁',
    name: 'Velociraptorino Rullante',
    sub: 'epic · cretaceous rolls',
    flavor: 'Drum rolls extinct in 65 million years. Plays them anyway, every gig. Three-fingered grip on a hot rod.',
    bpm: 126, groove: 65, power: 70,
    parody: 'Tractoro Dinosauro',
    parodyImg: 'brainrots/Brainrot_God/Tractoro_Dinosauro.png',
    drumrotImg: 'art/drumrots/velociraptorino_rullante.webp',
  },
  {
    id: 'quattro_quattro_pesci', tier: 'epic', num: '012', emoji: '🐟🎼',
    name: 'Quattro Quattro Pesciolino',
    sub: 'epic · strict-time pisces',
    flavor: 'Strict 4/4 only. Swims sideways through the click. Has gills. Will not be drawn into any odd meter.',
    bpm: 120, groove: 74, power: 61,
    parody: 'Tootini Shrimpini',
    parodyImg: 'brainrots/Brainrot_God/Tootini_Shrimpini.png',
    drumrotImg: 'art/drumrots/quattro_quattro_pesci.webp',
  },
  {
    id: 'brrr_paradiddlini', tier: 'epic', num: '013', emoji: '🐧🥢',
    name: 'Brrr Brrr Paradiddlini',
    sub: 'epic · rudiment penguin',
    flavor: 'Distant cousin of Brrr Brrr Batteria. Knows all 40 rudiments by memory. Quizzes new drummers, fairly, at the door.',
    bpm: 124, groove: 76, power: 62,
    parody: 'Salamino Penguino',
    parodyImg: 'brainrots/Epic/Salamino_Penguino.png',
    drumrotImg: 'art/drumrots/brrr_paradiddlini.webp',
  },
  // LEGENDARY ── ── ── ── ── ── ── ── ── ── ── ── ──
  {
    id: 'trippelini_boomolini', tier: 'legendary', num: '014', emoji: '💣🎵',
    name: 'Trippelini Boomolini',
    sub: 'legendary · triplet artillery',
    flavor: 'Triplet feel so deep it bends the click track. Detonates twice a measure. Cleanup happens off-mic.',
    bpm: 138, groove: 82, power: 79,
    parody: 'Trippi Troppi',
    parodyImg: 'brainrots/Rare/Trippi_Troppi.png',
    drumrotImg: 'art/drumrots/trippelini_boomolini.webp',
  },
  {
    id: 'snarlarello_magnifico', tier: 'legendary', num: '015', emoji: '🦁🥢',
    name: 'Snarlarello Magnifico',
    sub: 'legendary · maned showman',
    flavor: 'Mane shakes the rack toms loose. Has fronted four cover bands and one small cult. Still in the cult.',
    bpm: 142, groove: 79, power: 85,
    parody: 'Lionel Cactuseli',
    parodyImg: 'brainrots/Legendary/Lionel_Cactuseli.png',
    drumrotImg: 'art/drumrots/snarlarello_magnifico.webp',
  },
  {
    id: 'griddarello_metronomo', tier: 'legendary', num: '016', emoji: '⏱️😱',
    name: 'Griddarello del Metronomo',
    sub: 'legendary · haunted timekeeper',
    flavor: 'Has never been off the grid. Not once. Not for a millisecond. Looks haunted because it never sleeps.',
    bpm: 130, groove: 89, power: 72,
    parody: 'Tictac Sahur',
    parodyImg: 'brainrots/Secret/Tictac_Sahur.png',
    drumrotImg: 'art/drumrots/griddarello_metronomo.webp',
  },
  {
    id: 'poliritmico_coccodrillo', tier: 'legendary', num: '017', emoji: '🐊🌀',
    name: 'Poliritmico Coccodrillo',
    sub: 'legendary · cross-rhythm reptile',
    flavor: 'Plays five over four in his head, seven over eleven with his tail. Audience claps in eights. He forgives.',
    bpm: 144, groove: 86, power: 81,
    parody: 'Glorbo Fruttodrillo',
    parodyImg: 'brainrots/Legendary/Glorbo_Fruttodrillo.png',
    drumrotImg: 'art/drumrots/poliritmico_coccodrillo.webp',
  },
  // MYTHIC ── ── ── ── ── ── ── ── ── ── ── ── ──
  {
    id: 'lirili_beatlarila', tier: 'mythic', num: '018', emoji: '🐘🌊',
    name: 'Lirili Beatlarila',
    sub: 'mythic · tidal pachyderm',
    flavor: 'Trunk doubles as a kick pedal. Step pattern sounds like an ocean. Has cried during a fill. Twice.',
    bpm: 152, groove: 93, power: 89,
    parody: 'Lirili Larila',
    parodyImg: 'brainrots/Common/Liril_Laril_.png',
    drumrotImg: 'art/drumrots/lirili_beatlarila.webp',
  },
  {
    id: 'frigo_bassolo_camelini', tier: 'mythic', num: '019', emoji: '🐪❄️',
    name: 'Frigo Bassolo Camelini',
    sub: 'mythic · cold-storage camel',
    flavor: 'Stores the sub-bass in two humps. Walks the desert in 32-bar phrases. Refuses to play above 60Hz.',
    bpm: 156, groove: 91, power: 94,
    parody: 'Frigo Camelo',
    parodyImg: 'brainrots/Mythic/Frigo_Camelo.png',
    drumrotImg: 'art/drumrots/frigo_bassolo_camelini.webp',
  },
  {
    id: 'sincopato_del_vento', tier: 'mythic', num: '020', emoji: '🌪️🎸',
    name: 'Sincopato del Vento',
    sub: 'mythic · off-beat tempest',
    flavor: 'Made entirely of off-beats and dust. Cannot land on the downbeat. Refuses to even attempt the downbeat.',
    bpm: 164, groove: 96, power: 86,
    parody: 'Ventoliero Pavonero',
    parodyImg: 'brainrots/Secret/Ventoliero_Pavonero.png',
    drumrotImg: 'art/drumrots/sincopato_del_vento.webp',
  },
  {
    id: 'maestro_falsetto_drumini', tier: 'mythic', num: '021', emoji: '🎩🥢',
    name: 'Il Maestro Falsetto Drumini',
    sub: 'mythic · conductor of chaos',
    flavor: 'Conducts full orchestras using only drumsticks. The strings section weeps. The brass section nods. Both are correct.',
    bpm: 150, groove: 95, power: 90,
    parody: 'Cavallo Virtuoso',
    parodyImg: 'brainrots/Mythic/Cavallo_Virtuoso.png',
    drumrotImg: 'art/drumrots/maestro_falsetto_drumini.webp',
  },
  // DRUMROT GOD ── ── ── ── ── ── ── ── ── ── ── ── ──
  {
    id: 'tamburino_cosmico', tier: 'god', num: '022', emoji: '🌌🥁',
    name: 'Il Tamburino Cosmico',
    sub: 'drumrot god · galactic drummer',
    flavor: 'Beats the universe. The universe beats back. It is a draw every measure. The reverb tail never ends.',
    bpm: 174, groove: 98, power: 99,
    parody: 'Astrolero Cervalero',
    parodyImg: 'brainrots/Brainrot_God/Astrolero_Cervalero.png',
    drumrotImg: 'art/drumrots/tamburino_cosmico.webp',
  },
  {
    id: 'bombardino_quattro_tempi', tier: 'god', num: '023', emoji: '💣🎼',
    name: 'Bombardino Quattro Tempi',
    sub: 'drumrot god · four-limb prophet',
    flavor: 'Four time signatures at once. Each limb a different planet. Each planet thinks it is the downbeat.',
    bpm: 182, groove: 99, power: 97,
    parody: 'Bombardini Tortinii',
    parodyImg: 'brainrots/Brainrot_God/Bombardini_Tortinii.png',
    drumrotImg: 'art/drumrots/bombardino_quattro_tempi.webp',
  },
  // OG ── ── ── ── ── ── ── ── ── ── ── ── ──
  {
    id: 'grande_maestro_drumbeano', tier: 'og', num: '024', emoji: '🌌👑🥁',
    name: 'Il Grande Maestro Drumbeano',
    sub: 'og · day one · pack zero',
    flavor: 'The original. Pulled from pack zero. Conducts dreams. Cannot be unboxed twice. Bows are unnecessary.',
    bpm: 99, groove: 99, power: 99,
    parody: 'Tralalero Tralala',
    parodyImg: 'brainrots/Brainrot_God/Tralalero_Tralala.png',
    drumrotImg: 'art/drumrots/grande_maestro_drumbeano.webp',
  },
  {
    id: 'doppio_paradiddle_supremo', tier: 'og', num: '025', emoji: '✨🥢🥢✨',
    name: 'Doppio Paradiddle Supremo',
    sub: 'og · stereo paradiddle · holo',
    flavor: 'Both hands. All sixteen subdivisions. Simultaneously. In stereo. The sticks have never touched the rim.',
    bpm: 99, groove: 99, power: 99,
    parody: 'La Grande Combinasion',
    parodyImg: 'brainrots/Secret/La_Grande_Combinasion.png',
    drumrotImg: 'art/drumrots/doppio_paradiddle_supremo.webp',
  },
  {
    id: 'snareless_horseman', tier: 'og', num: '026', emoji: '🎃🐴🥁',
    name: 'Snareless Horseman',
    sub: 'og · the headless beat',
    flavor: 'Rides through the night carrying his own snare drum where his head should be. The groove is eternal.',
    bpm: 99, groove: 99, power: 99,
    parody: 'Headless Horseman',
    parodyImg: 'brainrots/OG/Headless_Horseman.png',
    drumrotImg: 'art/drumrots/snareless_horseman.webp',
  },
  {
    id: 'jam_pork', tier: 'og', num: '027', emoji: '🐷🎷',
    name: 'Jam Pork',
    sub: 'og · original session pig',
    flavor: 'Hosts the longest-running jam session in the multiverse. Has not stopped since 1998. The flannel never comes off.',
    bpm: 99, groove: 99, power: 99,
    parody: 'John Pork',
    parodyImg: 'brainrots/OG/John_Pork.png',
    drumrotImg: 'art/drumrots/jam_pork.webp',
  },
  {
    id: 'meowltronome', tier: 'og', num: '028', emoji: '🐱⏱️',
    name: 'Meowltronome',
    sub: 'og · feline of perfect time',
    flavor: 'Half cat, half metronome. Each blink is exactly one beat at 120 BPM. Has never blinked twice in a row.',
    bpm: 99, groove: 99, power: 99,
    parody: 'Meowl',
    parodyImg: 'brainrots/OG/Meowl.png',
    drumrotImg: 'art/drumrots/meowltronome.webp',
  },
  {
    id: 'trono_tomtomlet', tier: 'og', num: '029', emoji: '👑🥁',
    name: 'Trono Tomtomlet',
    sub: 'og · porcelain tom god',
    flavor: 'A tom drum cast from cathedral porcelain. Booms like a bell. Cannot be played indoors twice in one century.',
    bpm: 99, groove: 99, power: 99,
    drumrotImg: 'art/drumrots/trono_tomtomlet.webp',
  },
  {
    id: 'spyder_sousaphant', tier: 'og', num: '030', emoji: '🕷️🐘🎺',
    name: 'Spyder Sousaphant',
    sub: 'og · eight-armed brass deity',
    flavor: 'Eight arms, one sousaphone, one trunk. Plays every brass part of every marching band simultaneously.',
    bpm: 99, groove: 99, power: 99,
    parody: 'Spyder Elephant',
    parodyImg: 'brainrots/OG/Spyder_Elephant.png',
    drumrotImg: 'art/drumrots/spyder_sousaphant.webp',
  },
  {
    id: 'strawbeatry_elefantino', tier: 'og', num: '031', emoji: '🍓🐘🥢',
    name: 'Strawbeatry Elefantino',
    sub: 'og · the sweet downbeat',
    flavor: 'Crushes strawberries into the downbeat. The juice is the groove. The seeds are the syncopation.',
    bpm: 99, groove: 99, power: 99,
    parody: 'Strawberry Elephant',
    parodyImg: 'brainrots/OG/Strawberry_Elephant.png',
    drumrotImg: 'art/drumrots/strawbeatry_elefantino.webp',
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

// ── Card renderer (v0.3 chrome) ───────────────────────────────────────────────
const _segmenter = (typeof Intl !== 'undefined' && Intl.Segmenter)
  ? new Intl.Segmenter('en', { granularity: 'grapheme' })
  : null;

function splitEmojis(str){
  if (!str) return [];
  if (_segmenter) return [..._segmenter.segment(str)].map(s => s.segment);
  return Array.from(str);
}

function escapeHtml(str){
  return String(str ?? '').replace(/[&<>"']/g, c => ({
    '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;',
  }[c]));
}

function creatureHtml(emoji){
  const parts = splitEmojis(emoji);
  const n = Math.min(parts.length, 4);
  if (n === 0) return '';
  return `<div class="creature" data-n="${n}" aria-hidden="true">` +
    parts.slice(0, 4).map((g, i) => `<span class="e e${i+1}">${g}</span>`).join('') +
    `</div>`;
}

function portraitHtml(entry){
  // Always emit the emoji creature behind the image. If drumrotImg exists, the
  // image (z-index 2) covers it; if the image fails or is skipped by the
  // browser, the creature stays visible — no silently-blank portraits.
  const creature = creatureHtml(entry?.emoji || '');
  if (entry?.drumrotImg){
    const alt = escapeHtml(entry.name || '');
    return `
      ${creature}
      <img class="portrait-img" src="${entry.drumrotImg}" alt="${alt}" decoding="async" onerror="this.style.display='none'">
      <span class="photo-vignette"></span>
      <span class="photo-tint"></span>`;
  }
  return creature;
}

function statDisplay(entry, tierKey, key){
  const v = entry?.[key];
  if (v == null) return '—';
  if (tierKey === 'og'){
    if (key === 'power') return 'MAX';
    return '∞'; // bpm + groove
  }
  if (key === 'power' && v >= 99) return 'MAX';
  return v;
}

function numberDisplay(entry, tierKey){
  const num = entry?.num ?? '???';
  return tierKey === 'og' ? `#${num}/OG` : `#${num}`;
}

export function renderDrumrotCard(drumrot, tierKey, locked = false){
  if (locked){
    const num = escapeHtml(drumrot?.num ?? '???');
    return `
      <div class="cell">
        <article class="drumrot-card tier-${escapeHtml(tierKey || 'common')} tier-locked" aria-label="locked drumrot">
          <span class="screw tl"></span>
          <span class="screw tr"></span>
          <span class="screw bl"></span>
          <span class="screw br"></span>
          <div class="card-inner">
            <div class="tier-banner">
              <span class="label">★ ???</span>
              <span class="num">#???</span>
            </div>
            <div class="portrait">
              <div class="grid"></div>
              <div class="glow"></div>
              <div class="scan"></div>
              <span class="corner tl"></span>
              <span class="corner tr"></span>
              <span class="corner bl"></span>
              <span class="corner br"></span>
            </div>
            <div class="name-plate">
              <div class="name">???</div>
              <div class="sub"><span class="tier-name">???</span> · unknown</div>
            </div>
            <div class="flavor">Not yet collected.</div>
            <div class="stats">
              <div class="stat"><span class="k">bpm</span><span class="v">—</span></div>
              <div class="stat"><span class="k">grv</span><span class="v">—</span></div>
              <div class="stat"><span class="k">pwr</span><span class="v">—</span></div>
            </div>
            <div class="footer">
              <span class="num">#${num}</span>
              <span class="shine"></span>
              <span class="logo"><span class="mark"></span>drumrot</span>
            </div>
          </div>
        </article>
      </div>`;
  }

  const safeTier = (tierKey && TIER_CONFIG[tierKey]) ? tierKey : 'common';
  const tier = TIER_CONFIG[safeTier];
  const label = escapeHtml(tier.label);
  const num = escapeHtml(numberDisplay(drumrot, safeTier));
  const name = escapeHtml(drumrot?.name ?? '');
  const subFull = drumrot?.sub ?? '';
  const subParts = subFull.split(' · ');
  const tierLabel = escapeHtml(subParts[0] || '');
  const tierRest = escapeHtml(subParts.slice(1).join(' · '));
  const flavor = escapeHtml(drumrot?.flavor ?? '');
  const stampDigits = (drumrot?.num || '').replace(/[^0-9]/g, '').padStart(2,'0').slice(-2);

  return `
    <div class="cell">
      <article class="drumrot-card tier-${safeTier}" aria-label="${name}">
        <span class="screw tl"></span>
        <span class="screw tr"></span>
        <span class="screw bl"></span>
        <span class="screw br"></span>
        <div class="card-inner">
          <div class="tier-banner">
            <span class="label">★ ${label}</span>
            <span class="num">${num}</span>
          </div>
          <div class="portrait">
            <div class="grid"></div>
            <div class="glow"></div>
            <div class="scan"></div>
            ${portraitHtml(drumrot)}
            <span class="corner tl"></span>
            <span class="corner tr"></span>
            <span class="corner bl"></span>
            <span class="corner br"></span>
            <span class="stamp">FRG · ${stampDigits}</span>
          </div>
          <div class="name-plate">
            <div class="name">${name}</div>
            <div class="sub"><span class="tier-name">${tierLabel}</span>${tierRest ? ' · ' + tierRest : ''}</div>
          </div>
          <div class="flavor">${flavor}</div>
          <div class="stats">
            <div class="stat"><span class="k">bpm</span><span class="v">${statDisplay(drumrot, safeTier, 'bpm')}</span></div>
            <div class="stat"><span class="k">grv</span><span class="v">${statDisplay(drumrot, safeTier, 'groove')}</span></div>
            <div class="stat"><span class="k">pwr</span><span class="v">${statDisplay(drumrot, safeTier, 'power')}</span></div>
          </div>
          <div class="footer">
            <span class="num">${num}</span>
            <span class="shine"></span>
            <span class="logo"><span class="mark"></span>drumrot</span>
          </div>
        </div>
      </article>
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
  const drCard = document.getElementById('drCard');
  drCard.innerHTML = renderDrumrotCard(drumrot, tierKey, false);
  // Hook the entry animation on the inner card element.
  const cardEl = drCard.querySelector('.drumrot-card');
  if (cardEl){
    cardEl.classList.add('revealing');
    cardEl.addEventListener('animationend', () => cardEl.classList.remove('revealing'), { once: true });
  }

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

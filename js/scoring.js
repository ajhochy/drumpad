// ===========================================================================
// Scoring — score, combo, streak, accuracy
// ===========================================================================
import { State } from './state.js';

function setText(id, v){ const e = document.getElementById(id); if (e) e.textContent = v; }
function setStyle(id, k, v){ const e = document.getElementById(id); if (e) e.style[k] = v; }

export function resetStats(){
  State.score = 0;
  State.combo = 0;
  State.maxCombo = 0;
  State.hits = 0;
  State.misses = 0;
  State.ghostHits = 0;
  State.streak = 0;
  setText('scoreVal', '0');
  setText('comboVal', '0x');
  setText('accVal', '—');
  setStyle('accVal', 'color', '');
  const pf = document.getElementById('progFill');
  if (pf) pf.style.width = '0%';
  setText('progLbl', '0 / ' + State.notes.length);
}

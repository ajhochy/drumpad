// ===========================================================================
// Web Audio API — drum sounds + metronome click
// ===========================================================================

let AC = null;

export function getAC(){
  if (!AC) AC = new (window.AudioContext || window.webkitAudioContext)();
  return AC;
}

export function clickSound(accent = false){
  const ac = getAC();
  const o = ac.createOscillator();
  const g = ac.createGain();
  o.type = 'square';
  o.frequency.value = accent ? 1800 : 1100;
  g.gain.setValueAtTime(0, ac.currentTime);
  g.gain.linearRampToValueAtTime(accent ? 0.18 : 0.10, ac.currentTime + 0.002);
  g.gain.exponentialRampToValueAtTime(0.0001, ac.currentTime + 0.05);
  o.connect(g).connect(ac.destination);
  o.start(); o.stop(ac.currentTime + 0.06);
}

export function drumSound(lane){
  const ac = getAC();
  const t = ac.currentTime;
  if (lane === 3){ // kick
    const o = ac.createOscillator(), g = ac.createGain();
    o.frequency.setValueAtTime(120, t);
    o.frequency.exponentialRampToValueAtTime(40, t + 0.08);
    g.gain.setValueAtTime(0.45, t);
    g.gain.exponentialRampToValueAtTime(0.001, t + 0.18);
    o.connect(g).connect(ac.destination);
    o.start(t); o.stop(t + 0.2);
  } else if (lane === 2 || lane === 4){ // snare or tom
    const n = ac.createBufferSource();
    const buf = ac.createBuffer(1, ac.sampleRate * 0.18, ac.sampleRate);
    const d = buf.getChannelData(0);
    for (let i = 0; i < d.length; i++) d[i] = (Math.random() * 2 - 1) * Math.pow(1 - i / d.length, 2);
    n.buffer = buf;
    const flt = ac.createBiquadFilter();
    flt.type = lane === 2 ? 'highpass' : 'bandpass';
    flt.frequency.value = lane === 2 ? 1500 : 350;
    const g = ac.createGain();
    g.gain.setValueAtTime(0.35, t);
    g.gain.exponentialRampToValueAtTime(0.001, t + 0.16);
    n.connect(flt).connect(g).connect(ac.destination);
    n.start(t); n.stop(t + 0.18);
  } else { // cymbals: crash (0), hihat (1), ride (5)
    const n = ac.createBufferSource();
    const dur = lane === 0 ? 0.6 : (lane === 5 ? 0.35 : 0.08);
    const buf = ac.createBuffer(1, ac.sampleRate * dur, ac.sampleRate);
    const d = buf.getChannelData(0);
    for (let i = 0; i < d.length; i++) d[i] = (Math.random() * 2 - 1);
    n.buffer = buf;
    const flt = ac.createBiquadFilter();
    flt.type = 'highpass';
    flt.frequency.value = lane === 1 ? 7000 : 4000;
    const g = ac.createGain();
    g.gain.setValueAtTime(0.20, t);
    g.gain.exponentialRampToValueAtTime(0.001, t + dur);
    n.connect(flt).connect(g).connect(ac.destination);
    n.start(t); n.stop(t + dur);
  }
}

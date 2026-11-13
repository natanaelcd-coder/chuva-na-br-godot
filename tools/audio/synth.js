// In-page synthesizer for tools/audio/build_music.js. Grown from the web version's radio (web/chuva-na-br.html:
// tone, hit, melody, schedule) into a small band: plucked strings (Karplus-Strong), accordion, flute, electric
// piano, organ, synths and a Brazilian percussion kit. Everything is seeded, so the same track renders the same.
// window.renderTrack(def) -> {b64, rms, peak, secs}: mono 16-bit PCM at def.sr.
(() => {
const mtof = m => 440 * Math.pow(2, (m - 69) / 12);
function rngOf(seed) {   // mulberry32
  let a = seed >>> 0;
  return () => { a = (a + 0x6D2B79F5) >>> 0; let t = a; t = Math.imul(t ^ t >>> 15, t | 1); t ^= t + Math.imul(t ^ t >>> 7, t | 61); return ((t ^ t >>> 14) >>> 0) / 4294967296; };
}
function hashStr(s) { let h = 2166136261; for (const c of s) { h ^= c.charCodeAt(0); h = Math.imul(h, 16777619); } return h >>> 0; }

const Q = { M: [0, 4, 7], m: [0, 3, 7], '7': [0, 4, 7, 10], M7: [0, 4, 7, 11], m7: [0, 3, 7, 10], '6': [0, 4, 7, 9], m6: [0, 3, 7, 9],
  '9': [0, 4, 7, 10, 14], M9: [0, 4, 7, 11, 14], m9: [0, 3, 7, 10, 14], '69': [0, 4, 7, 9, 14], dim: [0, 3, 6, 9], sus: [0, 5, 7], m7b5: [0, 3, 6, 10] };
const PC = { C: 0, 'C#': 1, Db: 1, D: 2, 'D#': 3, Eb: 3, E: 4, F: 5, 'F#': 6, Gb: 6, G: 7, 'G#': 8, Ab: 8, A: 9, 'A#': 10, Bb: 10, B: 11 };
function chordOf(sym) {   // "Am7", "F#", "Bb7/F" (bass after the slash)
  const [main, slash] = sym.split('/');
  const m = main.match(/^([A-G][#b]?)(.*)$/);
  const pc = PC[m[1]], q = Q[m[2] || 'M'];
  if (!q) throw new Error('chord quality ' + sym);
  return { pc, q, bass: slash ? PC[slash] : pc, sym };
}
const above = (pc, lo) => { let m = lo; while (((m % 12) + 12) % 12 !== pc) m++; return m; };
function voice(ch, lo, hi) {   // close voicing from lo, folded under hi
  const b = above(ch.pc, lo);
  return ch.q.map(i => { let n = b + i; while (n > hi) n -= 12; return n; }).sort((a, b) => a - b);
}

window.renderTrack = async function (def) {
  const SR = def.sr;
  const rng = rngOf(hashStr(def.id + '|' + (def.seed || 0)));
  const r = () => rng(), pick = a => a[Math.floor(r() * a.length)], chance = p => r() < p;
  const beats = def.beats || 4, sub = def.sub || 4, SPB = beats * sub;   // steps per bar
  const stepDur = 60 / def.bpm / sub, barDur = stepDur * SPB;
  const plan = def.plan || null;
  // song form: intro, then phrases (A A B A ...) until the target length
  const phraseBars = def.phrase || 8, introBars = def.intro == null ? 4 : def.intro;
  let form = def.form || 'AABA';
  const target = def.secs || 78;
  let sections = [{ s: 'intro', bars: introBars }];
  let total = introBars, fi = 0;
  if (plan) { sections = plan.map(([s, bars]) => ({ s, bars })); total = sections.reduce((a, x) => a + x.bars, 0); }
  else while (total * barDur < target - phraseBars * barDur / 2) { const s = form[fi++ % form.length]; sections.push({ s, bars: phraseBars }); total += phraseBars; }
  const len = total * barDur, tail = def.tail || 3.0;
  const ctx = new OfflineAudioContext(1, Math.ceil((len + tail) * SR), SR);

  // ---- mix bus: highpass, lowpass, gentle compressor; echo and a small room as sends
  const bus = ctx.createGain(); bus.gain.value = 1;
  const hp = ctx.createBiquadFilter(); hp.type = 'highpass'; hp.frequency.value = def.hp || 90;
  const lp = ctx.createBiquadFilter(); lp.type = 'lowpass'; lp.frequency.value = def.lp || 5200;
  const comp = ctx.createDynamicsCompressor(); comp.threshold.value = -20; comp.ratio.value = 3; comp.attack.value = 0.01; comp.release.value = 0.2;
  bus.connect(hp); hp.connect(lp); lp.connect(comp); comp.connect(ctx.destination);
  const dly = ctx.createDelay(2); dly.delayTime.value = def.echo || stepDur * 3;
  const fb = ctx.createGain(); fb.gain.value = def.echoFb || 0.3;
  const dlp = ctx.createBiquadFilter(); dlp.type = 'lowpass'; dlp.frequency.value = 2400;
  dly.connect(dlp); dlp.connect(fb); fb.connect(dly); dlp.connect(bus);
  const rev = ctx.createConvolver();
  { const n = Math.floor(SR * (def.room || 1.4)), ir = ctx.createBuffer(1, n, SR), d = ir.getChannelData(0), rr = rngOf(7);
    for (let i = 0; i < n; i++) d[i] = (rr() * 2 - 1) * Math.pow(1 - i / n, 3); rev.buffer = ir; }
  const revG = ctx.createGain(); revG.gain.value = def.roomMix || 0.25; rev.connect(revG); revG.connect(bus);
  const noise = ctx.createBuffer(1, SR * 2, SR); { const d = noise.getChannelData(0), rr = rngOf(11); for (let i = 0; i < d.length; i++) d[i] = rr() * 2 - 1; }

  function out(node, o) {   // node -> bus, plus echo / room sends
    node.connect(o.dest || bus);
    if (o.echo) { const s = ctx.createGain(); s.gain.value = o.echo; node.connect(s); s.connect(dly); }
    if (o.rev) { const s = ctx.createGain(); s.gain.value = o.rev; node.connect(s); s.connect(rev); }
  }
  // one note: oscillators (with harmonics / detune), filter, envelope, vibrato, tremolo
  function tone(f, t, dur, vol, o = {}) {
    if (t < 0) return;
    const g = ctx.createGain(), att = o.att || 0.006, rel = o.rel || 0.08, end = t + dur + rel * 3 + 0.05;
    const parts = o.harm || [[1, 1]];
    const sum = ctx.createGain(); sum.gain.value = 1;
    let lfo = null;
    if (o.vib) { lfo = ctx.createOscillator(); lfo.frequency.value = o.vib[0]; const lg = ctx.createGain(); lg.gain.setValueAtTime(0, t);
      lg.gain.linearRampToValueAtTime(f * (Math.pow(2, o.vib[1] / 1200) - 1), t + (o.vib[2] || 0.25)); lfo.connect(lg); lfo._g = lg; lfo.start(t); lfo.stop(end); }
    for (const [mul, hv] of parts) {
      const dets = o.det ? [-o.det, o.det] : [0];
      for (const dc of dets) {
        const os = ctx.createOscillator(); os.type = o.type || 'sine'; os.frequency.setValueAtTime(f * mul, t); os.detune.value = dc;
        if (o.slide) os.frequency.exponentialRampToValueAtTime(o.slide * mul, t + (o.slideT || dur));
        if (lfo) { const k = ctx.createGain(); k.gain.value = mul; lfo._g.connect(k); k.connect(os.frequency); }
        const hg = ctx.createGain(); hg.gain.value = hv / dets.length; os.connect(hg); hg.connect(sum); os.start(t); os.stop(end);
      }
    }
    let node = sum;
    if (o.lp) { const fl = ctx.createBiquadFilter(); fl.type = 'lowpass'; fl.Q.value = o.lpq || 0.7; fl.frequency.setValueAtTime(o.lp, t);
      if (o.lpTo) fl.frequency.exponentialRampToValueAtTime(o.lpTo, t + (o.lpT || dur)); node.connect(fl); node = fl; }
    if (o.hp) { const fl = ctx.createBiquadFilter(); fl.type = 'highpass'; fl.frequency.value = o.hp; node.connect(fl); node = fl; }
    if (o.trem) { const tg = ctx.createGain(); tg.gain.value = 1 - o.trem[1]; const tl = ctx.createOscillator(); tl.frequency.value = o.trem[0];
      const tlg = ctx.createGain(); tlg.gain.value = o.trem[1]; tl.connect(tlg); tlg.connect(tg.gain); tl.start(t); tl.stop(end); node.connect(tg); node = tg; }
    node.connect(g);
    g.gain.setValueAtTime(0.0001, t);
    g.gain.linearRampToValueAtTime(vol, t + att);
    if (o.sus != null) {   // sustained: settle to sus, release after dur
      g.gain.setTargetAtTime(vol * o.sus, t + att, (o.dec || 0.2) / 3);
      g.gain.setTargetAtTime(0.0001, t + Math.max(dur, att), rel / 3);
    } else g.gain.exponentialRampToValueAtTime(0.0001, t + Math.max(dur, att + 0.01));   // percussive
    out(g, o);
  }
  // filtered noise burst
  function hit(t, dur, vol, o = {}) {
    if (t < 0) return;
    const s = ctx.createBufferSource(); s.buffer = noise; const g = ctx.createGain(); let node = s;
    for (const [type, fq, q] of o.f || [['highpass', 3000, 0.7]]) { const fl = ctx.createBiquadFilter(); fl.type = type; fl.frequency.value = fq; fl.Q.value = q || 0.7; node.connect(fl); node = fl; }
    g.gain.setValueAtTime(0.0001, t); g.gain.linearRampToValueAtTime(vol, t + (o.att || 0.002)); g.gain.exponentialRampToValueAtTime(0.0001, t + dur);
    node.connect(g); out(g, o); s.start(t, r() * 1.5); s.stop(t + dur + 0.05);
  }
  // plucked string (Karplus-Strong), tuned exactly with playbackRate; cached per period
  const ks = new Map();
  function ksBuf(N, bright, decay, variant) {
    const key = N + '|' + bright + '|' + decay + '|' + variant;
    if (ks.has(key)) return ks.get(key);
    const n = Math.ceil(SR * 2.2), b = ctx.createBuffer(1, n, SR), d = b.getChannelData(0), rr = rngOf(N * 977 + variant * 31 + Math.round(bright * 1000));
    let p = 0, mean = 0;
    for (let i = 0; i < N; i++) { p += bright * ((rr() * 2 - 1) - p); d[i] = p; mean += p; }
    mean /= N; let pk = 0; for (let i = 0; i < N; i++) { d[i] -= mean; pk = Math.max(pk, Math.abs(d[i])); }
    for (let i = 0; i < N; i++) d[i] /= pk || 1;
    for (let i = N; i < n; i++) d[i] = decay * 0.5 * (d[i - N] + d[Math.max(0, i - N - 1)]);
    ks.set(key, b); return b;
  }
  function pluck(m, t, vol, o = {}) {
    if (t < 0) return;
    const f = mtof(m), N = Math.max(2, Math.floor(SR / f - 0.5)), f0 = SR / (N + 0.5);
    const s = ctx.createBufferSource(); s.buffer = ksBuf(N, o.bright || 0.5, o.decay || 0.996, Math.floor(r() * 2)); s.playbackRate.value = f / f0;
    const g = ctx.createGain(); g.gain.setValueAtTime(vol, t);
    const dur = o.dur || 1.6; g.gain.setTargetAtTime(0.0001, t + dur, (o.rel || 0.05) / 3);
    let node = s; if (o.lp) { const fl = ctx.createBiquadFilter(); fl.type = 'lowpass'; fl.frequency.value = o.lp; s.connect(fl); node = fl; }
    node.connect(g); out(g, o); s.start(t); s.stop(t + dur + (o.rel || 0.05) * 3 + 0.05);
    if (o.oct) pluck(m + 12, t + 0.004, vol * o.oct, Object.assign({}, o, { oct: 0 }));   // paired strings (viola caipira)
  }
  function strum(notes, t, vol, o = {}) {   // down (default) or up
    const ns = o.up ? notes.slice().reverse() : notes, gap = o.gap || 0.012;
    ns.forEach((m, i) => pluck(m, t + i * gap, vol * (o.up ? 0.85 : 1), o));
  }

  // ---- instruments
  const LEADS = {
    flute: (f, t, d, v) => { tone(f, t, d, v, { type: 'sine', harm: [[1, 1], [2, 0.12], [3, 0.05]], att: 0.05, sus: 0.8, rel: 0.12, vib: [5.2, 14, 0.3], echo: 0.3, rev: 0.4 });
      hit(t, Math.min(d, 0.25), v * 0.05, { f: [['bandpass', f * 2, 1.5]] }); },
    sanfona: (f, t, d, v) => tone(f, t, d, v, { type: 'sawtooth', det: 9, harm: [[1, 1], [2, 0.3]], lp: 2000, att: 0.03, sus: 0.85, rel: 0.08, trem: [5.5, 0.12], rev: 0.25 }),
    epiano: (f, t, d, v) => tone(f, t, d + 0.4, v, { type: 'sine', harm: [[1, 1], [2, 0.18], [4, 0.04]], att: 0.004, echo: 0.2, rev: 0.3 }),
    vibra: (f, t, d, v) => tone(f, t, d + 0.8, v, { type: 'sine', harm: [[1, 1], [4, 0.1]], att: 0.003, trem: [6, 0.3], echo: 0.25, rev: 0.4 }),
    melodica: (f, t, d, v) => tone(f, t, d, v, { type: 'square', det: 6, lp: 2400, att: 0.03, sus: 0.8, rel: 0.06, vib: [5, 8, 0.4], echo: 0.25 }),
    teclado: (f, t, d, v) => tone(f, t, d, v, { type: 'square', lp: 1800, att: 0.01, sus: 0.7, rel: 0.15, vib: [6, 22, 0.15], echo: 0.4, rev: 0.3 }),
    saw: (f, t, d, v) => tone(f, t, d, v, { type: 'sawtooth', det: 7, lp: 2600, att: 0.02, sus: 0.7, rel: 0.2, vib: [5, 12, 0.3], echo: 0.45, rev: 0.4 }),
    sax: (f, t, d, v) => tone(f, t, d, v, { type: 'sawtooth', lp: 900, lpTo: 2200, lpT: 0.12, lpq: 2, att: 0.05, sus: 0.75, rel: 0.12, vib: [5, 18, 0.35], echo: 0.25, rev: 0.45 }),
    clarinete: (f, t, d, v) => tone(f, t, d, v, { type: 'square', harm: [[1, 1], [3, 0.2]], lp: 1600, att: 0.04, sus: 0.8, rel: 0.1, vib: [5, 10, 0.4], rev: 0.35 }),
    pip: (f, t, d, v) => tone(f, t, d, v, { type: 'sine', att: 0.003, sus: 1, rel: 0.01 }),
    clack: (f, t, d, v) => { hit(t, 0.035, v, { f: [['bandpass', f, 1.5]] }); tone(f / 8, t, 0.06, v * 0.6, { type: 'triangle' }); },
    viola: (f, t, d, v) => pluck(Math.round(69 + 12 * Math.log2(f / 440)), t, v * 2.2, { bright: 0.7, decay: 0.997, dur: d + 0.3, oct: 0.4, echo: 0.15, rev: 0.25 }),
  };
  function lead(name, m, t, d, v) { LEADS[name](mtof(m), t, d, v); }
  const kit = {
    kick: (t, v = 1) => tone(110, t, 0.18, 0.5 * v, { slide: 42, slideT: 0.16 }),
    snare: (t, v = 1) => { hit(t, 0.16, 0.14 * v, { f: [['highpass', 1800]], rev: 0.3 }); tone(190, t, 0.07, 0.12 * v, { type: 'triangle' }); },
    brush: (t, v = 1) => hit(t, 0.22, 0.05 * v, { f: [['bandpass', 4500, 0.6]], att: 0.03 }),
    rim: (t, v = 1) => { tone(1700, t, 0.03, 0.08 * v, { type: 'triangle' }); hit(t, 0.02, 0.05 * v, { f: [['bandpass', 3000, 2]] }); },
    hat: (t, v = 1, open = false) => hit(t, open ? 0.18 : 0.04, 0.05 * v, { f: [['highpass', 7000]] }),
    shaker: (t, v = 1) => hit(t, 0.07, 0.04 * v, { f: [['bandpass', 6000, 1.2]], att: 0.015 }),
    surdo: (t, v = 1) => tone(78, t, 0.55, 0.42 * v, { slide: 56, slideT: 0.4, rev: 0.15 }),
    tamborim: (t, v = 1) => { tone(880, t, 0.05, 0.07 * v, { type: 'triangle' }); hit(t, 0.03, 0.04 * v, { f: [['highpass', 3500]] }); },
    pandeiro: (t, v = 1) => hit(t, 0.06, 0.04 * v, { f: [['bandpass', 7500, 1]] }),
    agogo: (t, hi, v = 1) => tone(hi ? 1040 : 760, t, 0.14, 0.05 * v, { type: 'triangle', harm: [[1, 1], [2.7, 0.3]], echo: 0.1 }),
    bongo: (t, hi, v = 1) => tone(hi ? 420 : 300, t, 0.14, 0.14 * v, { slide: hi ? 360 : 250, slideT: 0.1, rev: 0.2 }),
    clave: (t, v = 1) => tone(2500, t, 0.05, 0.06 * v, { type: 'sine', rev: 0.2 }),
    triangulo: (t, open, v = 1) => tone(4200, t, open ? 0.35 : 0.06, 0.025 * v, { type: 'sine', harm: [[1, 1], [2.4, 0.5], [3.6, 0.3]], rev: 0.2 }),
    zabumba: (t, v = 1) => tone(90, t, 0.25, 0.4 * v, { slide: 60, slideT: 0.2 }),
  };

  // ---- harmony
  const progA = def.prog.map(chordOf), progB = (def.progB || def.prog).map(chordOf);
  const bpc = def.barsPerChord || 1;
  const chordAt = (sec, bi) => { const p = sec === 'B' ? progB : progA; return p[Math.floor(bi / bpc) % p.length]; };
  const scale = def.scale;   // pitch classes for the melody
  const lo = def.leadLo || 67, hi = def.leadHi || 84;
  const pool = []; for (let m = lo; m <= hi; m++) if (scale.includes(((m % 12) + 12) % 12)) pool.push(m);

  // ---- melody: a motif per section (rhythm + contour), repeated over the chords with a cadence at the end of the phrase
  function makeMotif(bars, dens) {
    const steps = bars * SPB, notes = [];
    for (let s = 0; s < steps; s++) {
      const strong = s % sub === 0, beat1 = s % SPB === 0;
      const p = beat1 ? 0.85 : strong ? 0.55 * dens + 0.2 : 0.3 * dens;
      if (chance(p) && s < steps - 1) notes.push({ s });
    }
    if (!notes.length || notes[0].s > sub) notes.unshift({ s: 0 });
    for (let i = 0; i < notes.length; i++) { const nx = i + 1 < notes.length ? notes[i + 1].s : steps; notes[i].len = Math.max(1, nx - notes[i].s); }
    let d = 0; for (const n of notes) { d += pick([-2, -1, -1, 0, 1, 1, 2, chance(0.15) ? pick([-4, 3, 4]) : 1]); d = Math.max(-5, Math.min(6, d)); n.d = d; }
    if (chance(0.5)) notes[notes.length - 1].rest = true;   // breathe at the end
    return notes;
  }
  const motifs = {}, phraseMotifBars = Math.max(1, Math.round(phraseBars / 4));
  const center = pool.indexOf(pool.reduce((a, m) => Math.abs(m - (lo + hi) / 2) < Math.abs(a - (lo + hi) / 2) ? m : a, pool[0]));
  function snapChord(m, ch) {   // nearest chord tone
    let best = m, bd = 99;
    for (let k = -4; k <= 4; k++) { const c = m + k; if (ch.q.some(i => ((c - ch.pc - i) % 12 + 12) % 12 === 0) && Math.abs(k) < bd) { bd = Math.abs(k); best = c; } }
    return best;
  }
  function melodyBar(sec, phraseBar, bi, t0, vol) {
    if (!motifs[sec]) motifs[sec] = { m: makeMotif(phraseMotifBars, def.dens || 0.5), shift: sec === 'B' ? 2 : 0 };
    const mo = motifs[sec], rep = Math.floor(phraseBar / phraseMotifBars), inBar = phraseBar % phraseMotifBars;
    const last = phraseBar >= phraseBars - phraseMotifBars, ch = chordAt(sec, bi);
    const varShift = [0, 1, 0, -1][rep % 4] + mo.shift;
    for (const n of mo.m) {
      if (Math.floor(n.s / SPB) !== inBar || n.rest) continue;
      const s = n.s % SPB;
      let idx = Math.max(0, Math.min(pool.length - 1, center + n.d + varShift)), m = pool[idx];
      if (s % sub === 0) m = snapChord(m, ch);
      let len = n.len;
      if (last && n === mo.m.filter(x => !x.rest).slice(-1)[0]) { m = snapChord(m, { pc: ch.pc, q: [0] }); len = Math.max(len, sub * 2); }   // cadence: land on the root
      lead(sec === 'B' && def.leadB ? def.leadB : def.lead, m, t0 + s * stepDur + swing(s), len * stepDur * 0.95, vol);
    }
  }
  const swing = s => (def.swing && s % 2 === 1) ? def.swing * stepDur : 0;
  const bass = (m, t, d, v, o = {}) => def.bassPluck
    ? pluck(m, t, v * 2.6, { bright: 0.35, decay: 0.995, dur: d, lp: 900 })
    : tone(mtof(m), t, d, v, Object.assign({ type: def.bassWave || 'triangle', lp: 700, att: 0.01, sus: 0.6, rel: 0.08 }, o));
  const bassNote = (ch, k = 0) => above(k ? (ch.pc + k) % 12 : ch.bass, def.bassLo || 36);
  const padNotes = ch => voice(ch, def.padLo || 55, def.padHi || 72);

  // ---- accompaniment, one bar at a time, per style
  const S = (t0, s) => t0 + s * stepDur + swing(s);
  const STY = {
    toada(t0, ch, sec, bi, full) {   // 6/8, viola caipira arpeggios with paired strings, sanfona chords in B
      const v = padNotes(ch), arp = [v[0], v[2] || v[1], v[1] + 12, v[2] || v[1], v[1], v[0] + 12];
      for (let s = 0; s < SPB; s++) pluck(arp[s % arp.length], S(t0, s), s % 3 === 0 ? 0.22 : 0.15, { bright: 0.75, decay: 0.997, dur: stepDur * 4, oct: 0.45, rev: 0.25 });
      bass(bassNote(ch), S(t0, 0), stepDur * 2.5, 0.22); bass(bassNote(ch, 7), S(t0, 3), stepDur * 2.5, 0.16);
      if (full) for (let s = 0; s < SPB; s++) kit.shaker(S(t0, s), s % 3 === 0 ? 1 : 0.5);
      if (sec === 'B') v.forEach(m => tone(mtof(m), S(t0, 0), barDur * 0.95, 0.025, { type: 'sawtooth', det: 9, lp: 1500, att: 0.15, sus: 0.9, rel: 0.2, trem: [5.5, 0.15] }));
    },
    valsa(t0, ch, sec, bi, full) {   // 3/4: bass on one, violão on two and three
      const v = padNotes(ch);
      bass(bi % 2 ? bassNote(ch, 7) : bassNote(ch), S(t0, 0), stepDur * 3, 0.24);
      strum(v, S(t0, 2), 0.13, { bright: 0.45, decay: 0.994, dur: stepDur * 1.6, rel: 0.06 });
      strum(v, S(t0, 4), 0.11, { bright: 0.45, decay: 0.994, dur: stepDur * 1.6, rel: 0.06, up: true });
      if (full) { kit.brush(S(t0, 2), 0.7); kit.brush(S(t0, 4), 0.7); }
      if (sec === 'B') kit.triangulo(S(t0, 0), true, 0.8);
    },
    balada(t0, ch, sec, bi, full) {   // slow 4/4: electric piano, picked arpeggio, brushes
      const v = padNotes(ch);
      v.forEach(m => tone(mtof(m), S(t0, 0), barDur * 0.9, 0.035, { type: 'sine', harm: [[1, 1], [2, 0.2]], att: 0.005, rev: 0.35 }));
      const arp = [v[0], v[1], v[2] || v[1], v[1] + 12, v[2] || v[0], v[1]];
      for (let s = 0; s < SPB; s++) if (sec !== 'intro' || s % 2 === 0) pluck(arp[s % arp.length] + 12, S(t0, s), 0.09, { bright: 0.55, decay: 0.996, dur: stepDur * 3, rev: 0.3 });
      bass(bassNote(ch), S(t0, 0), stepDur * 3.5, 0.24); bass(bassNote(ch, 7), S(t0, 4), stepDur * 3.5, 0.18);
      if (full) { kit.kick(S(t0, 0), 0.6); kit.kick(S(t0, 5), 0.35); kit.brush(S(t0, 2)); kit.brush(S(t0, 6)); kit.rim(S(t0, 6), 0.5); }
    },
    samba(t0, ch, sec, bi, full) {   // 2/4 in 16ths: surdo, tamborim teleco-teco, pandeiro, cavaquinho chops
      const v = padNotes(ch), two = bi % 2;
      if (full) {
        kit.surdo(S(t0, 0), 0.35); kit.surdo(S(t0, 4), 1);
        for (let s = 0; s < SPB; s++) kit.pandeiro(S(t0, s), s % 4 === 3 ? 1.2 : s % 2 ? 0.6 : 0.9);
        const tam = two ? [0, 2, 5, 7] : [1, 3, 6];   // teleco-teco over two bars
        tam.forEach(s => kit.tamborim(S(t0, s)));
      }
      const cav = two ? [0, 3, 6] : [1, 3, 4, 6];
      cav.forEach(s => strum(v.map(m => m + 12), S(t0, s), 0.09, { bright: 0.8, decay: 0.99, dur: stepDur * 1.2, rel: 0.03, gap: 0.006, up: s % 2 === 1 }));
      bass(two ? bassNote(ch, 7) : bassNote(ch), S(t0, 0), stepDur * 1.8, 0.24); bass(bassNote(ch), S(t0, 4), stepDur * 1.5, 0.2);
      if (two) bass(bassNote(ch, 10), S(t0, 7), stepDur, 0.14);
    },
    bossa(t0, ch, sec, bi, full) {   // 4/4 in eighths: nylon guitar thumb and fingers, rim clave, brushes
      const v = padNotes(ch), two = bi % 2;
      bass(bassNote(ch), S(t0, 0), stepDur * 2.6, 0.22); bass(bassNote(ch, 7), S(t0, 3), stepDur * 1.2, 0.17); bass(bassNote(ch, 7), S(t0, 4), stepDur * 2.6, 0.17); bass(bassNote(ch), S(t0, 7), stepDur, 0.14);
      const comp = two ? [0, 2, 5] : [1, 3, 6];
      comp.forEach(s => strum(v.slice(1).concat([v[0] + 12]), S(t0, s), 0.075, { bright: 0.35, decay: 0.995, dur: stepDur * 1.5, rel: 0.08, gap: 0.008 }));
      if (full) { (two ? [0, 3, 6] : [2, 5]).forEach(s => kit.rim(S(t0, s), 0.8)); for (let s = 0; s < SPB; s++) kit.shaker(S(t0, s), s % 2 ? 0.5 : 0.8); }
      if (sec === 'B') v.forEach(m => tone(mtof(m), S(t0, 0), barDur, 0.02, { type: 'sine', harm: [[1, 1], [2, 0.3]], att: 0.3, sus: 0.9, rel: 0.4, rev: 0.4 }));
    },
    ijexa(t0, ch, sec, bi, full) {   // laid-back 4/4: offbeat skank, agogô, syncopated bass, kick on three
      const v = padNotes(ch);
      [4, 12].forEach(s => strum(v.map(m => m + 12), S(t0, s), 0.09, { bright: 0.6, decay: 0.99, dur: stepDur * 1.4, rel: 0.03, gap: 0.005 }));
      [0, 3, 6, 10, 11].forEach((s, i) => bass(i === 2 ? bassNote(ch, 7) : bassNote(ch) + (i === 4 ? 12 : 0), S(t0, s), stepDur * (i === 0 ? 2.5 : 1.6), 0.22));
      if (full) {
        [0, 3, 6, 8, 10, 12, 14].forEach((s, i) => kit.agogo(S(t0, s), i % 3 !== 1, 0.8));
        kit.kick(S(t0, 8), 0.8); kit.rim(S(t0, 8), 0.7);
        for (let s = 2; s < SPB; s += 4) kit.hat(S(t0, s), 0.7);
        [0, 6, 12].forEach(s => kit.bongo(S(t0, s + 1), s === 6, 0.5));
      }
    },
    bolero(t0, ch, sec, bi, full) {   // 4/4 in 16ths: bongos, maracas, organ, requinto in B
      const v = padNotes(ch);
      v.forEach(m => tone(mtof(m), S(t0, 0), barDur * 0.98, 0.028, { type: 'sine', harm: [[1, 1], [2, 0.5], [3, 0.3], [4, 0.15]], att: 0.08, sus: 0.9, rel: 0.2, trem: [6, 0.1], rev: 0.3 }));
      bass(bassNote(ch), S(t0, 0), stepDur * 5, 0.24); bass(bassNote(ch, 7), S(t0, 6), stepDur * 1.6, 0.16); bass(bassNote(ch, 7), S(t0, 8), stepDur * 5, 0.2);
      if (full) {
        [[0, false], [4, true], [6, true], [8, false], [12, true], [14, true]].forEach(([s, h]) => kit.bongo(S(t0, s), h, 0.8));
        for (let s = 0; s < SPB; s += 2) kit.shaker(S(t0, s), s % 4 ? 0.6 : 1);
        kit.clave(S(t0, 0)); kit.clave(S(t0, 6)); kit.clave(S(t0, 12));
      }
      if (sec === 'B') for (let s = 0; s < SPB; s++) pluck(v[[0, 1, 2, 1][s % 4] % v.length] + 12, S(t0, s), 0.07, { bright: 0.6, decay: 0.995, dur: stepDur * 2, rev: 0.3 });
    },
    synth(t0, ch, sec, bi, full) {   // night drive: arpeggiator, pulsing bass, gated pad
      const v = padNotes(ch), ar = [v[0], v[1], v[2] || v[1], v[1] + 12, v[0] + 12, v[2] || v[1], v[1], v[0] + 12];
      for (let s = 0; s < SPB; s++) tone(mtof(ar[s % ar.length] + 12), S(t0, s), stepDur * 0.9, 0.035, { type: 'sawtooth', lp: 1400 + 600 * Math.sin(bi * 0.7 + s * 0.2), att: 0.003, echo: 0.3 });
      for (let s = 0; s < SPB; s += 2) bass(bassNote(ch) + (s % 4 === 2 ? 12 : 0), S(t0, s), stepDur * 1.6, 0.16, { type: 'square', lp: 500 });
      if (sec !== 'intro') v.forEach(m => tone(mtof(m), S(t0, 0), barDur, 0.022, { type: 'sawtooth', det: 12, lp: 1200, att: 0.4, sus: 0.9, rel: 0.5, rev: 0.4 }));
      if (full) { kit.kick(S(t0, 0)); kit.kick(S(t0, 8)); kit.snare(S(t0, 4)); kit.snare(S(t0, 12)); [2, 6, 10, 14].forEach(s => kit.hat(S(t0, s))); }
    },
    romantico(t0, ch, sec, bi, full) {   // 12/8: piano triplets, soft kit, the AM ballad
      const v = padNotes(ch), ar = [v[0], v[1], v[2] || v[1]];
      for (let s = 0; s < SPB; s++) tone(mtof(ar[s % 3] + (s % 6 >= 3 ? 12 : 0)), S(t0, s), stepDur * 2.5, 0.05, { type: 'sine', harm: [[1, 1], [2, 0.25], [3, 0.06]], att: 0.004, rev: 0.35 });
      bass(bassNote(ch), S(t0, 0), stepDur * 5.5, 0.24); bass(bassNote(ch, 7), S(t0, 6), stepDur * 5.5, 0.18);
      if (full) { kit.kick(S(t0, 0), 0.7); kit.kick(S(t0, 6), 0.5); kit.snare(S(t0, 3), 0.6); kit.snare(S(t0, 9), 0.6); for (let s = 0; s < SPB; s += 3) kit.hat(S(t0, s), 0.5); }
    },
    none() {},
    xote(t0, ch, sec, bi, full) {   // forró-ish 2/4: zabumba, triangle, sanfona chords on the offbeat
      const v = padNotes(ch);
      if (full) { kit.zabumba(S(t0, 0)); kit.zabumba(S(t0, 3), 0.6); kit.zabumba(S(t0, 4), 0.8); for (let s = 0; s < SPB; s++) kit.triangulo(S(t0, s), s % 2 === 1, s % 4 === 2 ? 1 : 0.6); }
      [2, 6].forEach(s => v.forEach(m => tone(mtof(m), S(t0, s), stepDur * 1.6, 0.035, { type: 'sawtooth', det: 9, lp: 1700, att: 0.02, sus: 0.8, rel: 0.05 })));
      bass(bassNote(ch), S(t0, 0), stepDur * 2.5, 0.24); bass(bassNote(ch, 7), S(t0, 4), stepDur * 2.5, 0.2);
    },
  };

  // ---- the song
  let t = 0, bi = 0;
  for (const sec of sections) {
    for (let b = 0; b < sec.bars; b++, bi++) {
      const ch = chordAt(sec.s, b), full = !(sec.s === 'intro' && b < (def.introQuiet == null ? 2 : def.introQuiet));
      STY[def.style](t, ch, sec.s, b, full);
      if (sec.s !== 'intro' && def.lead && !def.noLead) melodyBar(sec.s, b % phraseBars, b, t, (def.leadVol || 0.09) * (sec.s === 'B' ? 1.05 : 1));
      t += barDur;
    }
  }
  // jingles and beds can add a few notes of their own on top (def.extra: [[lead, midi, step, steps, vol], ...])
  for (const [name, m, s, n, v] of def.extra || []) lead(name, m, s * stepDur, n * stepDur, v);

  const buf = await ctx.startRendering();
  const d = buf.getChannelData(0), n = Math.round(len * SR), outp = new Float32Array(def.oneShot ? d.length : n);
  if (def.oneShot) outp.set(d);
  else { outp.set(d.subarray(0, n)); for (let i = n; i < d.length; i++) outp[i - n] += d[i]; }   // wrap the tail: seamless loop
  // loudness: RMS to target, peaks softened with tanh
  let ss = 0; for (const x of outp) ss += x * x; const rms0 = Math.sqrt(ss / outp.length);
  const gain = Math.pow(10, (def.rmsDb || -30) / 20) / (rms0 || 1);
  let pk = 0, ss2 = 0; const ceil = 0.5;
  for (let i = 0; i < outp.length; i++) { let x = outp[i] * gain; x = ceil * Math.tanh(x / ceil); outp[i] = x; pk = Math.max(pk, Math.abs(x)); ss2 += x * x; }
  if (def.oneShot) { const f = Math.min(outp.length, Math.round(SR * 0.05)); for (let i = 0; i < f; i++) outp[outp.length - 1 - i] *= i / f; }
  const i16 = new Int16Array(outp.length); for (let i = 0; i < outp.length; i++) i16[i] = Math.max(-32767, Math.min(32767, Math.round(outp[i] * 32767)));
  const u8 = new Uint8Array(i16.buffer); let bin = ''; for (let i = 0; i < u8.length; i += 0x8000) bin += String.fromCharCode.apply(null, u8.subarray(i, i + 0x8000));
  return { b64: btoa(bin), rms: 20 * Math.log10(Math.sqrt(ss2 / outp.length)), peak: 20 * Math.log10(pk), secs: outp.length / SR, bars: total };
};
})();

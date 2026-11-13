// What tools/audio/build_music.js renders: three new songs per station, the station jingles ("plim"), the
// talk beds the announcer speaks over, the time signal and the tape deck's click. Names shown in the game
// live in scripts/features/radio.gd (TRACKS); keep the file names in step.
// Fields: style (see STY in synth.js), bpm, beats per bar, sub (steps per beat), prog / progB (chords per bar or
// per barsPerChord bars), scale (melody pitch classes), lead / leadB (LEADS in synth.js), secs (target length).
const PC = { C: 0, 'C#': 1, Db: 1, D: 2, Eb: 3, E: 4, F: 5, 'F#': 6, G: 7, Ab: 8, A: 9, Bb: 10, B: 11 };
const sc = (key, iv) => iv.map(i => (PC[key] + i) % 12);
const PENTA = [0, 2, 4, 7, 9], MAJOR = [0, 2, 4, 5, 7, 9, 11], MINOR = [0, 2, 3, 5, 7, 8, 10], HARM = [0, 2, 3, 5, 7, 8, 11], MPENTA = [0, 3, 5, 7, 10];

module.exports = [
  // ---- SERRA FM 98,7: interior, viola, sanfona and waltz
  { id: 'radio_serra_1', style: 'valsa', bpm: 138, beats: 3, sub: 2, scale: sc('G', MAJOR), lead: 'flute', leadB: 'sanfona', dens: 0.45,
    prog: ['G', 'D7', 'G', 'C', 'G', 'Em', 'A7', 'D7'], progB: ['C', 'G', 'Am', 'D7', 'B7', 'Em', 'A7', 'D7'], secs: 80 },
  { id: 'radio_serra_2', style: 'toada', bpm: 62, beats: 2, sub: 3, scale: sc('D', PENTA), lead: 'sanfona', leadB: 'viola', dens: 0.5, leadLo: 64, leadHi: 81,
    prog: ['D', 'D', 'A7', 'D', 'G', 'D', 'A7', 'D'], progB: ['G', 'A', 'D', 'Bm', 'G', 'A7', 'D', 'D'], secs: 80, room: 1.8 },
  { id: 'radio_serra_3', style: 'balada', bpm: 72, beats: 4, sub: 2, scale: sc('F', PENTA), lead: 'epiano', leadB: 'clarinete', dens: 0.4, swing: 0.15,
    prog: ['FM7', 'Am7', 'BbM7', 'C9'], progB: ['Dm7', 'Am7', 'BbM7', 'C'], secs: 78 },
  // ---- LITORAL FM 102,3: samba, bossa, ijexá
  { id: 'radio_litoral_1', style: 'samba', bpm: 102, beats: 2, sub: 4, barsPerChord: 2, scale: sc('C', MAJOR), lead: 'flute', leadB: 'clarinete', dens: 0.65,
    prog: ['C', 'A7', 'Dm7', 'G7'], progB: ['F', 'Fm6', 'C', 'G7'], secs: 78, phrase: 8, intro: 4 },
  { id: 'radio_litoral_2', style: 'bossa', bpm: 128, beats: 4, sub: 2, scale: sc('D', MAJOR), lead: 'vibra', leadB: 'flute', dens: 0.45, leadLo: 66, leadHi: 83,
    prog: ['DM7', 'Em7', 'A7', 'DM7', 'Bm7', 'E9', 'Em7', 'A7'], progB: ['GM7', 'Gm6', 'F#m7', 'B7', 'Em7', 'A7', 'DM7', 'DM7'], secs: 82, room: 1.6 },
  { id: 'radio_litoral_3', style: 'ijexa', bpm: 86, beats: 4, sub: 4, scale: sc('A', PENTA), lead: 'melodica', dens: 0.4,
    prog: ['A', 'F#m', 'D', 'E'], progB: ['D', 'E', 'C#m', 'F#m'], secs: 78 },
  // ---- NOITE AM 1040: bolero, synth for the night shift, the AM ballad
  { id: 'radio_noite_1', style: 'bolero', bpm: 78, beats: 4, sub: 4, scale: sc('A', HARM), lead: 'teclado', dens: 0.4, intro: 2, form: 'AAB',
    prog: ['Am', 'Dm', 'E7', 'Am'], progB: ['Dm', 'G7', 'C', 'E7'], secs: 80, lp: 3600 },
  { id: 'radio_noite_2', style: 'synth', bpm: 108, beats: 4, sub: 4, scale: sc('E', MPENTA), lead: 'saw', dens: 0.35, intro: 4,
    prog: ['Em', 'C', 'G', 'D'], progB: ['Am', 'C', 'Em', 'B7'], secs: 80, lp: 3800, echo: 60 / 108 * 0.75, echoFb: 0.4 },
  { id: 'radio_noite_3', style: 'romantico', bpm: 58, beats: 4, sub: 3, scale: sc('C', MAJOR), lead: 'sax', dens: 0.3, intro: 1, phrase: 4, form: 'AABA',
    prog: ['C', 'Am', 'F', 'G7'], progB: ['Em', 'Am', 'Dm7', 'G7'], secs: 78, lp: 3400, room: 2.0 },

  // ---- jingles: a few notes over silence (step = 1/16 at 120 bpm)
  { id: 'vinheta_serra', style: 'none', bpm: 120, beats: 4, sub: 4, prog: ['G'], scale: [], plan: [['intro', 1]], oneShot: true, tail: 1.6, rmsDb: -27,
    extra: [['viola', 67, 0, 3, 0.1], ['viola', 71, 1, 3, 0.1], ['viola', 74, 2, 3, 0.1], ['flute', 79, 3, 5, 0.12], ['flute', 83, 6, 6, 0.1]] },
  { id: 'vinheta_litoral', style: 'none', bpm: 120, beats: 4, sub: 4, prog: ['C'], scale: [], plan: [['intro', 1]], oneShot: true, tail: 1.6, rmsDb: -27,
    extra: [['vibra', 72, 0, 2, 0.1], ['vibra', 76, 1, 2, 0.1], ['vibra', 79, 2, 2, 0.1], ['vibra', 84, 3, 6, 0.12], ['vibra', 76, 3, 6, 0.06], ['vibra', 79, 3, 6, 0.06]] },
  { id: 'vinheta_noite', style: 'none', bpm: 120, beats: 4, sub: 4, prog: ['Am'], scale: [], plan: [['intro', 1]], oneShot: true, tail: 2.2, rmsDb: -27, echoFb: 0.45,
    extra: [['saw', 57, 0, 8, 0.06], ['saw', 60, 0, 8, 0.06], ['saw', 64, 0, 8, 0.06], ['teclado', 69, 2, 3, 0.1], ['teclado', 76, 5, 8, 0.1]] },
  { id: 'hora_certa', style: 'none', bpm: 60, beats: 4, sub: 4, prog: ['C'], scale: [], plan: [['intro', 1]], oneShot: true, tail: 0.3, rmsDb: -28, roomMix: 0.05,
    extra: [['pip', 83, 0, 0.4, 0.1], ['pip', 83, 4, 0.4, 0.1], ['pip', 83, 8, 0.4, 0.1], ['pip', 95, 12, 2.4, 0.1]] },
  { id: 'k7_clique', style: 'none', bpm: 120, beats: 4, sub: 4, prog: ['C'], scale: [], plan: [['intro', 1]], oneShot: true, tail: 0.2, rmsDb: -26, roomMix: 0.02,
    extra: [['clack', 84, 0, 1, 0.5], ['clack', 70, 1.6, 1, 0.4]] },

  // ---- talk beds: soft loops the announcer talks over (no drums, no tune)
  { id: 'fundo_serra', style: 'balada', bpm: 72, beats: 4, sub: 2, prog: ['G', 'Em7', 'C', 'D'], scale: [], plan: [['intro', 4]], introQuiet: 99, noLead: true, rmsDb: -33 },
  { id: 'fundo_litoral', style: 'bossa', bpm: 120, beats: 4, sub: 2, prog: ['CM7', 'Am7', 'Dm7', 'G7'], scale: [], plan: [['intro', 4]], introQuiet: 99, noLead: true, rmsDb: -33 },
  { id: 'fundo_noite', style: 'synth', bpm: 96, beats: 4, sub: 4, prog: ['Am', 'F', 'C', 'G'], scale: [], plan: [['intro', 4]], introQuiet: 99, noLead: true, rmsDb: -34, lp: 3000 },
];

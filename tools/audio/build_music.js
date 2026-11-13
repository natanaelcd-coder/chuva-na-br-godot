// Renders the radio audio in assets/audio from tools/audio/tracks.js with the Web Audio API (OfflineAudioContext)
// in headless Chromium (tools/audio/synth.js), then encodes Ogg Vorbis with ffmpeg (libvorbis). Seeded: the same
// definitions give the same music.
// Usage: node tools/audio/build_music.js [id ...]   (no ids: everything; needs Playwright with Chromium and ffmpeg)
const { chromium } = require('playwright');
const fs = require('fs'), path = require('path'), os = require('os'), { execFileSync } = require('child_process');
const root = path.resolve(__dirname, '../..');
const SR = 32000;
const tracks = require('./tracks.js');
const only = process.argv.slice(2);

function wav(pcm) {   // mono 16-bit
  const h = Buffer.alloc(44);
  h.write('RIFF', 0); h.writeUInt32LE(36 + pcm.length, 4); h.write('WAVE', 8); h.write('fmt ', 12);
  h.writeUInt32LE(16, 16); h.writeUInt16LE(1, 20); h.writeUInt16LE(1, 22); h.writeUInt32LE(SR, 24); h.writeUInt32LE(SR * 2, 28);
  h.writeUInt16LE(2, 32); h.writeUInt16LE(16, 34); h.write('data', 36); h.writeUInt32LE(pcm.length, 40);
  return Buffer.concat([h, pcm]);
}

(async () => {
  const b = await chromium.launch(); const p = await b.newPage();
  p.on('pageerror', e => console.log('page error:', e.message));
  p.on('console', m => console.log('page:', m.text()));
  await p.setContent('<!doctype html><html><head><meta charset="utf-8"></head><body></body></html>');
  await p.addScriptTag({ content: fs.readFileSync(path.join(__dirname, 'synth.js'), 'utf8') });
  const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'radio-'));
  for (const def of tracks) {
    if (only.length && !only.includes(def.id)) continue;
    const res = await p.evaluate(d => window.renderTrack(d), Object.assign({ sr: SR }, def));
    const w = path.join(tmp, def.id + '.wav'), o = path.join(root, 'assets/audio', def.id + '.ogg');
    fs.writeFileSync(w, wav(Buffer.from(res.b64, 'base64')));
    execFileSync('ffmpeg', ['-y', '-loglevel', 'error', '-i', w, '-c:a', 'libvorbis', '-q:a', '2', '-ar', String(SR), '-ac', '1', '-map_metadata', '-1', o]);
    fs.unlinkSync(w);
    console.log(`${def.id}: ${res.secs.toFixed(1)} s, ${res.bars} bars, rms ${res.rms.toFixed(1)} dB, peak ${res.peak.toFixed(1)} dB`);
  }
  fs.rmSync(tmp, { recursive: true, force: true });
  await b.close();
})();

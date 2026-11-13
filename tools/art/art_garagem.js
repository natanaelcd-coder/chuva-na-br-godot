// Garagem (idea 18): paint jobs for the three player cars, the matching painted cabins, and rear-window stickers.
// The rear views are the art.js / web drawings with the colours as parameters; the cabins are the original cockpit
// canvases with the body paint swapped pixel by pixel (blends at the edges follow, so nothing old shows at the seams).
// Names, km to unlock and the order live in scripts/features/garagem.gd; the ids here must match it.
(() => {
const H_ = window.__H, { R, poly, circ, rr, mk, text, ctext, tw } = H_;
const ART = window.ART, OUT = {};
const rgb = h => [1, 3, 5].map(i => parseInt(h.slice(i, i + 2), 16));
const css = a => '#' + a.map(v => Math.max(0, Math.min(255, Math.round(v))).toString(16).padStart(2, '0')).join('');
const mix = (h, k, t) => { const a = rgb(h), b = rgb(k); return css(a.map((v, i) => v + (b[i] - v) * t)); };
// a body colour and its ramp: highlight, soft light, shade, deep shade (a touch of blue in the shadows, like the originals)
const ramp = body => ({ body, hi: mix(body, '#ffffff', .45), mid: mix(body, '#ffffff', .24), shade: mix(mix(body, '#000000', .27), '#1a2440', .1),
  deep: mix(mix(body, '#000000', .44), '#1a2440', .12), deeper: mix(mix(body, '#000000', .6), '#1a2440', .14) });

// swap colours `from` -> `to` inside region [x0, y0, x1, y1] (logical units); a pixel that is a blend of a swapped colour and
// another swapped or `keep` colour (anti-aliased edges) becomes the same blend of the new colours
function repaint(src, from, to, keep, region) {
  const o = document.createElement('canvas'); o.width = src.width; o.height = src.height;
  const c = o.getContext('2d'); c.drawImage(src, 0, 0);
  const d = c.getImageData(0, 0, o.width, o.height), a = d.data;
  const S = from.map(rgb), D = to.map(rgb), K = keep.map(rgb), pairs = [];
  S.forEach((s, i) => { S.forEach((t, j) => { if (j > i) pairs.push([s, t, D[i], D[j]]); }); K.forEach(k => pairs.push([s, k, D[i], k])); });
  const [x0, y0, x1, y1] = (region || [0, 0, o.width / 2, o.height / 2]).map(v => Math.round(v * 2));
  const eq = (p, q) => p[0] === q[0] && p[1] === q[1] && p[2] === q[2];
  for (let y = y0; y < y1; y++) for (let x = x0; x < x1; x++) {
    const n = (y * o.width + x) * 4; if (a[n + 3] === 0) continue;
    const p = [a[n], a[n + 1], a[n + 2]];
    let out = null;
    const i = S.findIndex(s => eq(s, p));
    if (i >= 0) out = D[i];
    else if (!K.some(k => eq(k, p))) {
      let best = 2.5 + (255 - a[n + 3]) / 12;
      for (const [s, t, ds, dt] of pairs) {
        const v = [t[0] - s[0], t[1] - s[1], t[2] - s[2]], L = v[0] * v[0] + v[1] * v[1] + v[2] * v[2];
        const u = ((p[0] - s[0]) * v[0] + (p[1] - s[1]) * v[1] + (p[2] - s[2]) * v[2]) / L;
        if (u < 0 || u > 1) continue;
        const e = Math.hypot(p[0] - s[0] - v[0] * u, p[1] - s[1] - v[1] * u, p[2] - s[2] - v[2] * u);
        if (e < best) { best = e; out = ds.map((w, k) => w + (dt[k] - w) * u); }
      }
    }
    if (out) { a[n] = out[0]; a[n + 1] = out[1]; a[n + 2] = out[2]; }
  }
  c.putImageData(d, 0, 0);
  return o;
}
const DARKS = ['#0a0a0f', '#05070c', '#16202b', '#121a33', '#2a2c33', '#16233f', '#0c2a1c'];   // gauge faces too

/* ================= BESOURO 1973 ================= */
const BESOURO = { limao: '#9cc23a', bege: '#d6bf90', calcinha: '#93c3e3', laranja: '#d9762c', branco: '#e4e2d8' };
const besouroBack = p => mk(64, 46, c => {   // the web version's myBody, colours as parameters
  c.fillStyle = p.body; c.beginPath(); c.moveTo(13, 25); c.quadraticCurveTo(13.5, 3, 32, 3); c.quadraticCurveTo(50.5, 3, 51, 25); c.closePath(); c.fill();
  c.strokeStyle = p.hi; c.lineWidth = .5; c.beginPath(); c.moveTo(16.5, 14); c.quadraticCurveTo(19, 4.5, 32, 4); c.stroke();
  rr(c, '#0a0a0f', 19.5, 7.5, 25, 11.5, 4.5); rr(c, '#16233f', 20.5, 8.5, 23, 9.5, 3.5);
  circ(c, '#05070c', 26, 14.5, 3); R(c, '#05070c', 22.5, 16.5, 7, 1.5); R(c, '#05070c', 31.75, 8.5, .5, 3.5); R(c, '#c22630', 30.5, 12, 1.5, 1.5); R(c, '#c22630', 32.5, 13, 1.5, 1.5);
  R(c, '#3d5f94', 22, 9.5, 7, .5); R(c, '#3d5f94', 23, 10.5, 3, .5);
  rr(c, p.body, 4, 20, 56, 18, 7); circ(c, p.body, 9.5, 28, 7.5); circ(c, p.body, 54.5, 28, 7.5);
  c.strokeStyle = p.mid; c.lineWidth = .5; c.beginPath(); c.arc(9.5, 28, 7, Math.PI * 1.05, Math.PI * 1.6); c.stroke(); c.beginPath(); c.arc(54.5, 28, 7, Math.PI * 1.4, Math.PI * 1.95); c.stroke();
  rr(c, p.shade, 5, 33, 54, 6, 3); R(c, p.mid, 14, 20.5, 36, .5);
  c.strokeStyle = p.shade; c.lineWidth = .5; c.beginPath(); c.roundRect(19.5, 21.5, 25, 13, 3); c.stroke();
  for (let y = 23; y < 28; y += 1.5) { R(c, p.deep, 24, y, 6.5, .5); R(c, p.deep, 33.5, y, 6.5, .5); }
  [9.5, 54.5].forEach(x => { circ(c, '#a8acb5', x, 27.5, 3.5); circ(c, '#c22630', x, 27.5, 3); circ(c, '#f0484a', x, 27, 1.8); R(c, '#ff9a8a', x - 1, 26, 1, .5); });
  R(c, '#a8acb5', 21.5, 28.5, 21, 6); R(c, '#e6e8ee', 22, 29, 20, 5); text(c, 'CWB-73', 23.5, 29.75, '#16202b');
  rr(c, '#a8acb5', 2.5, 37, 59, 3, 1.5); R(c, '#e6e8ee', 5, 37.5, 54, .5); R(c, '#777b86', 5, 39, 54, .5); rr(c, '#a8acb5', 17, 34, 2, 5, 1); rr(c, '#a8acb5', 45, 34, 2, 5, 1);
  R(c, '#4a4d57', 13, 40, 2.5, 2); R(c, '#4a4d57', 48.5, 40, 2.5, 2);
});
// the Besouro cabin lives inside the web page's closure: rebuild it from the page's own source, between its two markers
// (markers are split so that this file's own text never matches them)
const M0 = 'const WIN' + ' = [', M1 = '/* ---------- cockpit' + ' (moving parts)';
const page = [...document.scripts].map(s => s.textContent).find(t => t.includes(M0) && t.includes(M1)) || '';
const cockSrc = page ? page.slice(page.indexOf(M0), page.indexOf(M1)) : '';
const cock = cockSrc ? new Function(...Object.keys(H_), cockSrc + '\nreturn cock;')(...Object.values(H_)) : null;
for (const [id, body] of Object.entries(BESOURO)) {
  const p = ramp(body);
  OUT['gar_player_besouro_' + id] = besouroBack(p);
  // the whole cabin is painted metal in the body colour: frame, roof edge, doors, dash
  if (cock)
    OUT['gar_cockpit_besouro_' + id] = repaint(cock, ['#5682a0', '#3f5d75', '#30465a', '#7aa7c2', '#22303f'],
      [p.body, p.shade, p.deep, p.mid, p.deeper], DARKS.concat(['#a8acb5', '#4a2d1c', '#6e4526']));
}

/* ================= PICAPE RURAL 1979 ================= */
// one colour, a colour with a white stripe, or "saia e blusa": cab and roof in one colour, bed and tailgate in another
const PICAPE = {
  vermelha: { body: '#b8282e', stripe: '#e6e8ee', stripe2: true },
  saia: { body: '#7a4a24', top: '#e8dcbc', stripe: '#e8dcbc' },
  azul: { body: '#3d6f9e', stripe: '#e3ab7c' },
  saia_azul: { body: '#2f5f8f', top: '#e6e8ee', stripe: '#e6e8ee' },
  amarela: { body: '#d9a524', stripe: '#2b1a12' },
};
const picapeBack = p => mk(64, 46, c => {   // art.js player_picape, colours as parameters
  rr(c, p.cab, 12, 2, 40, 16, 3); R(c, p.roof, 12, 2, 40, 2);
  rr(c, '#0a0a0f', 16, 5, 32, 10, 2); rr(c, '#16233f', 17, 6, 30, 8, 2);
  circ(c, '#05070c', 26, 11, 2.5); R(c, '#05070c', 23, 13, 6, 2); R(c, '#3d5f94', 19, 7, 7, .5);
  rr(c, '#a8acb5', 18, 13, 6, 8, 1); R(c, '#e6e8ee', 19, 13, 1, 8); rr(c, '#a8acb5', 26, 14, 6, 7, 1); R(c, '#e6e8ee', 27, 14, 1, 7);
  rr(c, '#c68a5a', 36, 14, 10, 7, 2); R(c, '#96643a', 37, 17, 8, .5);
  R(c, p.shade, 2, 18, 60, 4); R(c, p.body, 2, 18, 60, 1);
  R(c, p.body, 3, 22, 58, 14); R(c, p.shade, 3, 33, 58, 3);
  for (let x = 8; x < 58; x += 5) R(c, p.shade, x, 23, .5, 9);
  R(c, p.stripe, 3, 26, 58, 2); if (p.stripe2) R(c, p.stripe, 3, 29, 58, .5);
  rr(c, '#e6e8ee', 19, 28, 26, 6, 1); ctext(c, 'SIT-0790', 32, 29.5, '#16202b');
  [3, 56].forEach(x => { rr(c, '#7a1620', x, 22, 5, 11, 1); R(c, '#c22630', x + 1, 23, 3, 9); R(c, '#f0484a', x + 1, 23.5, 1, 3); });
  rr(c, '#a8acb5', 1, 36, 62, 4, 1); R(c, '#e6e8ee', 3, 36.5, 58, .5); R(c, '#777b86', 3, 39, 58, .5); R(c, '#4a4d57', 28, 37, 8, 2);
  R(c, '#2a2c33', 10, 40, 3, 3); R(c, '#2a2c33', 51, 40, 3, 3);
});
for (const [id, q] of Object.entries(PICAPE)) {
  const p = ramp(q.body), t = q.top ? ramp(q.top) : null;
  OUT['gar_player_picape_' + id] = picapeBack({ ...p, cab: t ? t.shade : p.shade, roof: t ? t.hi : '#e3ab7c', stripe: q.stripe, stripe2: q.stripe2 });
  const dash = t || p;   // two-tone trucks: the dash takes the light colour
  if (ART.cockpit_picape)
    OUT['gar_cockpit_picape_' + id] = repaint(ART.cockpit_picape, ['#23743f', '#3fae5a', '#16482c'], [dash.body, dash.mid, dash.shade],
      DARKS.concat(['#a8acb5', '#ffd65a', '#e6e8ee', '#c22630']), [18, 124, 366, 180]);
}

/* ================= SEDÃ GT 1989 ================= */
const GT = { prata: { body: '#a8acb5', pin: '#c22630' }, preto: { body: '#24262e', pin: '#ffd65a' },
  branco: { body: '#dfe2e8', pin: '#c22630' }, azul: { body: '#24406e', pin: '#e6e8ee' } };
const gtBack = p => mk(64, 46, c => {   // art.js player_gt, colours as parameters
  poly(c, p.body, [[17, 10], [47, 10], [54, 22], [10, 22]]); R(c, p.hi, 18, 10, 28, 1);
  poly(c, '#0a0a0f', [[19, 12], [45, 12], [50, 21], [14, 21]]); poly(c, '#16233f', [[20, 13], [44, 13], [48, 20], [16, 20]]);
  circ(c, '#05070c', 26, 17.5, 2.3); R(c, '#05070c', 23.5, 19, 5, 1.5); R(c, '#3d5f94', 21, 14, 7, .5);
  rr(c, p.body, 3, 22, 58, 16, 2); R(c, p.hi, 4, 22, 56, 1);
  rr(c, p.dark, 6, 20.5, 52, 2.5, 1);
  R(c, '#05070c', 4, 26, 56, 6); for (let x = 6; x < 58; x += 3) R(c, '#7a1620', x, 27, 2.2, 4);
  [5, 50].forEach(x => { R(c, '#f0484a', x, 27, 9, 4); R(c, '#ff9a8a', x + 1, 27.5, 3, .5); });
  rr(c, '#e6e8ee', 19, 32.5, 26, 5, 1); ctext(c, 'RAP-1989', 32, 33.5, '#16202b');
  R(c, p.pin, 4, 33, 14, .5); R(c, p.pin, 46, 33, 14, .5);
  rr(c, '#2a2c33', 2, 38, 60, 3, 1); R(c, '#4a4d57', 4, 38, 56, .5);
  circ(c, '#4a4d57', 46, 42, 1.6); circ(c, '#4a4d57', 51, 42, 1.6); circ(c, '#05070c', 46, 42, .8); circ(c, '#05070c', 51, 42, .8);
});
for (const [id, q] of Object.entries(GT)) {
  const p = ramp(q.body), hi = mix(q.body, '#ffffff', .3), dark = p.deep;
  OUT['gar_player_gt_' + id] = gtBack({ body: q.body, hi, dark, pin: q.pin });
  // only the hood shows from inside: the cabin is black and red whatever the paint
  if (ART.cockpit_gt)
    OUT['gar_cockpit_gt_' + id] = repaint(ART.cockpit_gt, ['#3a0d12', '#7a1620', '#c22630'], [dark, q.body, hi], DARKS, [26, 96, 358, 107]);
}

/* ================= rear-window stickers ================= */
// bg null: cut vinyl letters straight on the glass; otherwise a printed sticker
const STICKERS = {
  pago: ['TÁ PAGO', null, '#e6e8ee'], chuva: ['XÔ CHUVA', null, '#ffd65a'], br: ['PÉ NA BR', null, '#8fe07a'],
  deus: ['SÓ DEUS', '#e6e8ee', '#c22630'], volto: ['VOLTO JÁ', null, '#ff9a8a'], devagar: ['DEVAGAR', '#ffd65a', '#2b1a12'],
  indo: ['TÔ INDO', '#c22630', '#e6e8ee'],
};
for (const [id, [s, bg, fg]] of Object.entries(STICKERS)) {
  const m = bg ? 1 : .5, w = tw(s) + m * 2;
  OUT['gar_adesivo_' + id] = mk(w, 6, c => {   // accents sit above the capitals, so the letters start 2 units down
    if (bg) { R(c, bg, 0, 0, w, 6); R(c, mix(bg, '#000000', .25), 0, 5.5, w, .5); }
    text(c, s, m, 2, fg);
  });
}

Object.assign(window.ART, OUT);
})();

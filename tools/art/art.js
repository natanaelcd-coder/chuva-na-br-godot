// New art for Chuva na BR: two cockpits, two player cars, traffic and roadside sets for the dirt road
// and the expressway. Runs inside the web version's page (tools/art/build_art.js) and uses its pixel
// helpers through window.__H. Every function draws in logical units; mk() doubles them to file pixels.
(() => {
const { GL, ACC, R, poly, circ, rr, mk, text, ctext, tw, lighten, leaves, sign, billboard, W, H } = window.__H;
const OUT = {};
// glyphs the web font lacks
ACC['Ô'] = 'Oc';
GL['%'] = [25, 26, 2, 4, 8, 11, 19];
const line = (c, col, w, pts) => { c.strokeStyle = col; c.lineWidth = w; c.beginPath(); pts.forEach((p, i) => i ? c.lineTo(p[0], p[1]) : c.moveTo(p[0], p[1])); c.stroke(); };
const ring = (c, col, x, y, r, w) => { c.strokeStyle = col; c.lineWidth = w; c.beginPath(); c.arc(x, y, r, 0, 7); c.stroke(); };
const shadow = (c, cx, cy, rx, ry) => { c.fillStyle = 'rgba(0,0,0,.5)'; c.beginPath(); c.ellipse(cx, cy, rx, ry, 0, 0, 7); c.fill(); };
// a window-cut cabin: fill everything, outline the windows, punch them out
function cabin(c, base, frame, rim, wins) {
  R(c, base, 0, 0, W, H);
  wins.forEach(w => { c.strokeStyle = frame; c.lineWidth = 6; c.beginPath(); w(c); c.stroke(); c.strokeStyle = rim; c.lineWidth = 3; c.beginPath(); w(c); c.stroke(); });
  c.globalCompositeOperation = 'destination-out'; wins.forEach(w => { c.beginPath(); w(c); c.fill(); }); c.globalCompositeOperation = 'source-over';
}
function gauge(c, cx, cy, r, face, ticks, red) {
  circ(c, '#16202b', cx, cy, r + 3); circ(c, '#a8acb5', cx, cy, r + 1.5); circ(c, face, cx, cy, r);
  for (let i = 0; i <= ticks; i++) { const a = Math.PI * .8 + i * Math.PI * 1.4 / ticks; R(c, i > ticks - red ? '#f0484a' : '#e6e8ee', Math.round(cx + Math.cos(a) * (r - 2)), Math.round(cy + Math.sin(a) * (r - 2)), 1, 1); }
}

/* ================= PICAPE RURAL 1979: tall cabin, flat glass, painted metal dash ================= */
const WIN_P = [
  c => { c.moveTo(34, 9); c.lineTo(350, 9); c.lineTo(352, 120); c.lineTo(32, 120); c.closePath(); },
  c => { c.moveTo(-2, 12); c.lineTo(24, 10); c.lineTo(22, 116); c.lineTo(-2, 124); c.closePath(); },
  c => { c.moveTo(386, 12); c.lineTo(360, 10); c.lineTo(362, 116); c.lineTo(386, 124); c.closePath(); }];
OUT.cockpit_picape = mk(W, H, c => {
  cabin(c, '#96643a', '#c68a5a', '#0a0a0f', WIN_P);
  R(c, '#e3ab7c', 0, 0, W, 6); R(c, '#c68a5a', 0, 6, W, 2);                       // headliner
  // doors: tan vinyl with chrome crank handle
  R(c, '#6e4526', 0, 126, 28, 90); R(c, '#4a2d1c', 0, 150, 24, 34); circ(c, '#a8acb5', 12, 140, 3); R(c, '#a8acb5', 12, 139, 9, 2);
  R(c, '#6e4526', 356, 126, 28, 90); R(c, '#4a2d1c', 360, 150, 24, 34); circ(c, '#a8acb5', 372, 140, 3); R(c, '#a8acb5', 363, 139, 9, 2);
  // painted metal dash in body green, black crash pad on top
  R(c, '#16202b', 18, 120, 348, 7); R(c, '#2a2c33', 18, 120, 348, 1);
  R(c, '#23743f', 22, 127, 340, 52); R(c, '#3fae5a', 22, 127, 340, 1); R(c, '#16482c', 22, 175, 340, 4);
  for (let x = 30; x < 356; x += 4) R(c, '#16482c', x, 131, 2, .5);
  for (let x = 150; x < 236; x += 5) R(c, '#05070c', x, 122, 3, 2);              // defroster slots
  // rectangular chrome cluster: speedometer + fuel/temperature
  rr(c, '#a8acb5', 84, 128, 72, 28, 4); rr(c, '#0a0a0f', 86, 130, 68, 24, 3);
  gauge(c, 106, 142, 9, '#0c2a1c', 10, 2); ctext(c, 'KM/H', 106, 146, '#777b86');
  circ(c, '#0c2a1c', 136, 142, 7); R(c, '#f0484a', 131, 145, 1, 2); R(c, '#8fe07a', 140, 145, 1, 2); ctext(c, 'C', 136, 137.5, '#777b86');
  // AM radio with push buttons
  rr(c, '#a8acb5', 182, 136, 64, 26, 2); R(c, '#0a0a0f', 184, 138, 60, 22); R(c, '#2b1a12', 196, 141, 40, 8);
  for (let i = 0; i < 5; i++) { R(c, '#e6e8ee', 190 + i * 10, 152, 6, 5); R(c, '#777b86', 190 + i * 10, 156, 6, 1); }
  circ(c, '#a8acb5', 189, 145, 3); circ(c, '#a8acb5', 241, 145, 3);
  // glovebox with stickers
  c.strokeStyle = '#16482c'; c.lineWidth = .5; c.strokeRect(258.25, 133.25, 96.5, 38.5); R(c, '#a8acb5', 300, 166, 10, 2);
  R(c, '#ffd65a', 262, 137, 54, 18); ctext(c, 'DEVAGAR SE', 289, 140, '#2b1a12'); ctext(c, 'VAI AO LONGE', 289, 147, '#2b1a12');
  R(c, '#e6e8ee', 320, 137, 30, 18); ctext(c, 'SÓ', 335, 140, '#c22630'); ctext(c, 'DEUS', 335, 147, '#c22630');
  R(c, '#c22630', 266, 158, 52, 9); ctext(c, '100% SÍTIO', 292, 160.5, '#e6e8ee');
  // dash top: straw hat and a small saint
  poly(c, '#c47a1c', [[262, 120], [270, 112], [300, 112], [310, 120]]); rr(c, '#f2a62a', 272, 103, 28, 11, 5); R(c, '#c22630', 272, 110, 28, 2); R(c, '#ffd65a', 276, 104, 18, .5);
  for (let x = 266; x < 306; x += 3) R(c, '#7a4a10', x, 116, 1, .5);
  R(c, '#c47a1c', 330, 102, 12, 18); R(c, '#cfe0f2', 332, 104, 8, 14); R(c, '#3d5f94', 333, 110, 6, 8); circ(c, '#e3ab7c', 336, 108, 1.6);
  // steering column with three-on-the-tree shifter
  R(c, '#16202b', 104, 170, 10, 20); line(c, '#a8acb5', 1.5, [[112, 176], [148, 168]]); circ(c, '#e6e8ee', 149, 167.5, 2.5);
  // floor, bench seat in plaid
  R(c, '#0a0a0f', 22, 179, 340, 37); R(c, '#2a2c33', 22, 179, 340, 1);
  poly(c, '#7a4a10', [[250, 216], [262, 196], [384, 194], [384, 216]]);
  for (let y = 198; y < 216; y += 4) R(c, '#c47a1c', 256 + (216 - y) * .6, y, 140, 1);
  for (let x = 266; x < 384; x += 8) R(c, '#c22630', x, 196, 1.5, 20);
  // mirrors
  R(c, '#0a0a0f', 190, 0, 4, 12); rr(c, '#0a0a0f', 164, 10, 56, 16, 3); R(c, '#121a33', 167, 13, 50, 10);
  rr(c, '#a8acb5', 0, 74, 22, 22, 2); R(c, '#121a33', 2, 77, 18, 16);
});
OUT.player_picape = mk(64, 46, c => {
  // cab behind, bed in front of it, tailgate facing us
  rr(c, '#16482c', 12, 2, 40, 16, 3); R(c, '#e3ab7c', 12, 2, 40, 2);
  rr(c, '#0a0a0f', 16, 5, 32, 10, 2); rr(c, '#16233f', 17, 6, 30, 8, 2);
  circ(c, '#05070c', 26, 11, 2.5); R(c, '#05070c', 23, 13, 6, 2); R(c, '#3d5f94', 19, 7, 7, .5);
  // milk cans and a sack in the bed
  rr(c, '#a8acb5', 18, 13, 6, 8, 1); R(c, '#e6e8ee', 19, 13, 1, 8); rr(c, '#a8acb5', 26, 14, 6, 7, 1); R(c, '#e6e8ee', 27, 14, 1, 7);
  rr(c, '#c68a5a', 36, 14, 10, 7, 2); R(c, '#96643a', 37, 17, 8, .5);
  // bed sides and tailgate
  R(c, '#16482c', 2, 18, 60, 4); R(c, '#23743f', 2, 18, 60, 1);
  R(c, '#23743f', 3, 22, 58, 14); R(c, '#16482c', 3, 33, 58, 3);
  for (let x = 8; x < 58; x += 5) R(c, '#16482c', x, 23, .5, 9);
  R(c, '#e3ab7c', 3, 26, 58, 2);
  rr(c, '#e6e8ee', 19, 28, 26, 6, 1); ctext(c, 'SIT-0790', 32, 29.5, '#16202b');
  // vertical tail lights at the corners
  [3, 56].forEach(x => { rr(c, '#7a1620', x, 22, 5, 11, 1); R(c, '#c22630', x + 1, 23, 3, 9); R(c, '#f0484a', x + 1, 23.5, 1, 3); });
  // chrome step bumper
  rr(c, '#a8acb5', 1, 36, 62, 4, 1); R(c, '#e6e8ee', 3, 36.5, 58, .5); R(c, '#777b86', 3, 39, 58, .5); R(c, '#4a4d57', 28, 37, 8, 2);
  R(c, '#2a2c33', 10, 40, 3, 3); R(c, '#2a2c33', 51, 40, 3, 3);
});

/* ================= SEDÃ GT 1989: low seat, sloped glass, black and red interior ================= */
const WIN_G = [
  c => { c.moveTo(60, 24); c.lineTo(324, 24); c.quadraticCurveTo(340, 24, 344, 34); c.lineTo(356, 106); c.lineTo(28, 106); c.lineTo(40, 34); c.quadraticCurveTo(44, 24, 60, 24); },
  c => { c.moveTo(-2, 30); c.lineTo(26, 28); c.lineTo(16, 104); c.lineTo(-2, 112); c.closePath(); },
  c => { c.moveTo(386, 30); c.lineTo(358, 28); c.lineTo(368, 104); c.lineTo(386, 112); c.closePath(); }];
OUT.cockpit_gt = mk(W, H, c => {
  cabin(c, '#16202b', '#2a2c33', '#05070c', WIN_G);
  R(c, '#0a0a0f', 0, 0, W, 18); R(c, '#2a2c33', 0, 18, W, 1);                     // dark headliner, low roof
  // dark red hood seen over the dash, with a power bulge
  poly(c, '#3a0d12', [[40, 98], [344, 98], [356, 106], [28, 106]]); poly(c, '#7a1620', [[150, 98], [234, 98], [240, 106], [144, 106]]); R(c, '#c22630', 150, 98, 84, .5);
  // doors with red stripe
  R(c, '#0a0a0f', 0, 114, 26, 102); R(c, '#c22630', 0, 140, 26, 2); R(c, '#2a2c33', 4, 150, 18, 30);
  R(c, '#0a0a0f', 358, 114, 26, 102); R(c, '#c22630', 358, 140, 26, 2); R(c, '#2a2c33', 362, 150, 18, 30);
  // dash: wide padded black, long binnacle over the gauges
  R(c, '#0a0a0f', 18, 112, 348, 8); R(c, '#2a2c33', 18, 112, 348, 1);
  R(c, '#16202b', 22, 120, 340, 58); R(c, '#2a2c33', 22, 120, 340, 1); R(c, '#0a0a0f', 22, 174, 340, 4);
  for (let y = 124; y < 172; y += 3) R(c, '#121a33', 22, y, 340, .5);
  rr(c, '#0a0a0f', 64, 118, 128, 42, 6); rr(c, '#05070c', 68, 124, 120, 34, 4);
  gauge(c, 96, 142, 13, '#0a0a0f', 10, 0); ctext(c, 'KM/H', 96, 148, '#777b86');
  gauge(c, 152, 142, 13, '#0a0a0f', 7, 2); ctext(c, 'RPM', 152, 148, '#777b86');
  rr(c, '#05070c', 116, 126, 16, 8, 1);                                              // digital clock window
  R(c, '#c22630', 64, 160, 128, 1);
  // centre console: auto-reverse tape deck with equalizer
  rr(c, '#2a2c33', 196, 128, 76, 44, 3); R(c, '#05070c', 199, 131, 70, 14); R(c, '#05070c', 199, 148, 70, 12);
  R(c, '#2b1a12', 203, 133, 44, 8); for (let i = 0; i < 4; i++) R(c, '#777b86', 252 + i * 4, 134, 2, 6);
  R(c, '#4a4d57', 199, 162, 70, 7); R(c, '#05070c', 204, 164, 30, 2); ctext(c, 'AUTO REVERSE', 234, 163, '#a8acb5');
  // glovebox: one sticker, sport style
  c.strokeStyle = '#2a2c33'; c.lineWidth = .5; c.strokeRect(282.25, 128.25, 76.5, 40.5);
  R(c, '#c22630', 290, 134, 60, 14); ctext(c, 'NO EMBALO', 320, 136, '#e6e8ee'); ctext(c, 'DOS ANOS 80', 320, 142.5, '#e6e8ee');
  // five-speed lever with leather boot, bucket seat with stripes
  R(c, '#0a0a0f', 22, 178, 340, 38); poly(c, '#2a2c33', [[222, 216], [226, 196], [242, 196], [246, 216]]); R(c, '#4a4d57', 233, 186, 2, 12); circ(c, '#0a0a0f', 234, 185, 5); circ(c, '#2a2c33', 233, 184, 2);
  poly(c, '#16202b', [[280, 216], [290, 194], [384, 192], [384, 216]]); for (let x = 300; x < 384; x += 14) R(c, '#c22630', x, 194, 3, 22);
  // mirrors
  R(c, '#05070c', 190, 10, 4, 14); rr(c, '#05070c', 166, 22, 52, 14, 4); R(c, '#121a33', 169, 25, 46, 8);
  rr(c, '#7a1620', 0, 72, 20, 16, 3); R(c, '#121a33', 2, 75, 16, 10);
});
OUT.player_gt = mk(64, 46, c => {
  // low sloped roof, long trunk with a lip spoiler, full-width red light bar
  poly(c, '#7a1620', [[17, 10], [47, 10], [54, 22], [10, 22]]); R(c, '#c22630', 18, 10, 28, 1);
  poly(c, '#0a0a0f', [[19, 12], [45, 12], [50, 21], [14, 21]]); poly(c, '#16233f', [[20, 13], [44, 13], [48, 20], [16, 20]]);
  circ(c, '#05070c', 26, 17.5, 2.3); R(c, '#05070c', 23.5, 19, 5, 1.5); R(c, '#3d5f94', 21, 14, 7, .5);
  rr(c, '#7a1620', 3, 22, 58, 16, 2); R(c, '#c22630', 4, 22, 56, 1);
  rr(c, '#3a0d12', 6, 20.5, 52, 2.5, 1);                                              // spoiler
  R(c, '#05070c', 4, 26, 56, 6); for (let x = 6; x < 58; x += 3) R(c, '#7a1620', x, 27, 2.2, 4);
  [5, 50].forEach(x => { R(c, '#f0484a', x, 27, 9, 4); R(c, '#ff9a8a', x + 1, 27.5, 3, .5); });
  rr(c, '#e6e8ee', 19, 32.5, 26, 5, 1); ctext(c, 'RAP-1989', 32, 33.5, '#16202b');
  R(c, '#e6e8ee', 4, 33, 14, .5); R(c, '#e6e8ee', 46, 33, 14, .5);                      // silver pinstripe
  rr(c, '#2a2c33', 2, 38, 60, 3, 1); R(c, '#4a4d57', 4, 38, 56, .5);
  circ(c, '#4a4d57', 46, 42, 1.6); circ(c, '#4a4d57', 51, 42, 1.6); circ(c, '#05070c', 46, 42, .8); circ(c, '#05070c', 51, 42, .8);
});

/* ================= traffic ================= */
OUT.trator = mk(48, 44, c => {
  shadow(c, 24, 41.5, 22, 2.5);
  [[1, 16, 12, 26], [35, 16, 12, 26]].forEach(([x, y, w, h]) => { rr(c, '#0a0a0f', x, y, w, h, 3); for (let yy = y + 2; yy < y + h - 2; yy += 3) R(c, '#2a2c33', x + 1, yy, w - 2, 1); });
  R(c, '#c22630', 12, 18, 24, 18); R(c, '#f0484a', 12, 18, 24, 1); R(c, '#7a1620', 12, 32, 24, 4);
  R(c, '#4a4d57', 14, 36, 20, 4); R(c, '#2a2c33', 21, 38, 6, 3);                      // hitch
  R(c, '#2a2c33', 30, 2, 2, 16); R(c, '#4a4d57', 29, 1, 4, 2);                          // exhaust
  rr(c, '#2a2c33', 17, 10, 14, 9, 2);                                                   // seat back
  circ(c, '#e3ab7c', 24, 7, 3); poly(c, '#f2a62a', [[17, 6], [31, 6], [28, 3], [20, 3]]); R(c, '#c47a1c', 16, 6, 16, 1.2);   // driver with straw hat
  R(c, '#3d5f94', 19, 10, 10, 9);
  R(c, '#f2a62a', 14, 26, 3, 3); R(c, '#f2a62a', 31, 26, 3, 3); R(c, '#e6e8ee', 15, 22, 18, 6); ctext(c, 'LENTO', 24, 23.5, '#c22630');
});
OUT.onibus = mk(52, 62, c => {
  shadow(c, 26, 58.5, 24, 3); rr(c, '#0a0a0f', 5, 50, 10, 11, 2); rr(c, '#0a0a0f', 37, 50, 10, 11, 2);
  rr(c, '#e6e8ee', 2, 2, 48, 48, 3); R(c, '#cfe0f2', 2, 2, 48, 1);
  rr(c, '#121a33', 6, 6, 40, 16, 2); R(c, '#24345f', 8, 8, 14, 1);
  R(c, '#3d5f94', 2, 24, 48, 6); R(c, '#ffd65a', 2, 30, 48, 2);
  ctext(c, 'VIAÇÃO', 26, 25, '#e6e8ee'); ctext(c, 'SERRANA', 26, 34.5, '#3d5f94');
  for (let x = 12; x < 40; x += 3) R(c, '#a8acb5', x, 40, 2, 6);
  [3, 43].forEach(x => { rr(c, '#7a1620', x, 41, 6, 6, 1); R(c, '#f0484a', x + 1, 42, 4, 2); });
  R(c, '#2a2c33', 2, 47, 48, 4); R(c, '#e6e8ee', 19, 47.5, 14, 3);
});
function modernBack(body, shade, tall) {
  const o = tall ? 6 : 0, hi = lighten(body, .35);
  return mk(48, 36 + o, c => {
    shadow(c, 24, 32.5 + o, 22, 3); rr(c, '#0a0a0f', 5, 27 + o, 8, 8, 2); rr(c, '#0a0a0f', 35, 27 + o, 8, 8, 2);
    c.fillStyle = body; c.beginPath(); c.moveTo(9, 15 + o); c.quadraticCurveTo(12, 2, 24, 2); c.quadraticCurveTo(36, 2, 39, 15 + o); c.closePath(); c.fill();
    c.fillStyle = '#121a33'; c.beginPath(); c.moveTo(12, 14 + o); c.quadraticCurveTo(14, 5, 24, 5); c.quadraticCurveTo(34, 5, 36, 14 + o); c.closePath(); c.fill();
    R(c, '#24345f', 16, 6, 7, .5);
    rr(c, body, 2, 14 + o, 44, 15, 5); R(c, hi, 6, 14.5 + o, 36, .5); R(c, shade, 3, 24 + o, 42, 4);
    R(c, '#7a1620', 3, 17 + o, 42, 2.5); R(c, '#f0484a', 3, 17 + o, 9, 1.5); R(c, '#f0484a', 36, 17 + o, 9, 1.5); R(c, '#ff9a8a', 4, 17.5 + o, 6, .5); R(c, '#ff9a8a', 38, 17.5 + o, 6, .5);
    rr(c, '#e6e8ee', 18, 21 + o, 12, 4, .5); R(c, '#4a4d57', 19.5, 22.5 + o, 9, .5);
    rr(c, shade, 2, 27 + o, 44, 3, 1.5); R(c, '#2a2c33', 8, 29 + o, 32, 1);
  });
}
OUT.mod0 = modernBack('#e6e8ee', '#a8acb5');
OUT.mod1 = modernBack('#777b86', '#4a4d57');
OUT.mod2 = modernBack('#0a0a0f', '#2a2c33');
OUT.mod3 = modernBack('#3d5f94', '#24345f', true);
function modernFront(body, shade) {
  return mk(48, 36, c => {
    shadow(c, 24, 32.5, 22, 3); rr(c, '#0a0a0f', 5, 27, 8, 8, 2); rr(c, '#0a0a0f', 35, 27, 8, 8, 2);
    c.fillStyle = body; c.beginPath(); c.moveTo(9, 15); c.quadraticCurveTo(12, 2, 24, 2); c.quadraticCurveTo(36, 2, 39, 15); c.closePath(); c.fill();
    c.fillStyle = '#121a33'; c.beginPath(); c.moveTo(11, 14); c.quadraticCurveTo(13, 4, 24, 4); c.quadraticCurveTo(35, 4, 37, 14); c.closePath(); c.fill();
    rr(c, body, 2, 14, 44, 15, 5); R(c, shade, 3, 24, 42, 4);
    poly(c, '#fff3b0', [[3, 17], [13, 18], [13, 21], [4, 20]]); poly(c, '#fff3b0', [[45, 17], [35, 18], [35, 21], [44, 20]]);
    R(c, '#ffffff', 5, 18.5, 6, 1); R(c, '#ffffff', 37, 18.5, 6, 1);
    rr(c, '#0a0a0f', 15, 19, 18, 5, 1.5); for (let x = 17; x < 32; x += 2) R(c, '#2a2c33', x, 20, 1, 3);
    rr(c, shade, 2, 27, 44, 3, 1.5);
  });
}
OUT.front_mod0 = modernFront('#e6e8ee', '#a8acb5');
OUT.front_mod1 = modernFront('#30465a', '#16202b');

/* ================= the dirt road: Estrada do Sítio ================= */
OUT.cerca = mk(40, 14, c => {
  [2, 20, 38].forEach(x => { R(c, '#4a2d1c', x - 1, 2, 2, 12); R(c, '#6e4526', x - 1, 2, .5, 12); });
  [4, 7.5, 11].forEach(y => line(c, '#777b86', .5, [[0, y], [40, y + .3]]));
  for (let x = 4; x < 40; x += 6) { R(c, '#a8acb5', x, 3.6, .5, .8); R(c, '#a8acb5', x + 3, 7.2, .5, .8); }
});
OUT.eucalipto = mk(32, 96, c => {
  R(c, '#c8b8a0', 15, 22, 3, 74); R(c, '#e6e8ee', 15, 22, 1, 74); for (let y = 30; y < 94; y += 7) R(c, '#96643a', 16, y, 2, 2);
  line(c, '#c8b8a0', 1, [[16, 40], [8, 30]]); line(c, '#c8b8a0', 1, [[17, 34], [25, 24]]);
  const bl = [[16, 14, 10], [8, 26, 6], [25, 22, 6], [16, 4, 5]]; bl.forEach(b => circ(c, '#16482c', b[0], b[1], b[2] * .8)); leaves(c, bl, 90);
});
OUT.cafe = mk(48, 18, c => {
  [[8, 10, 8], [24, 9, 9], [40, 10, 8]].forEach(b => { circ(c, '#0c2a1c', b[0], b[1], b[2]); circ(c, '#16482c', b[0] - 2, b[1] - 3, b[2] * .5); });
  for (let i = 0; i < 26; i++) { const x = 3 + Math.random() * 42, y = 6 + Math.random() * 9; R(c, Math.random() < .6 ? '#c22630' : '#8fe07a', x, y, .7, .7); }
  R(c, '#4a2d1c', 0, 16, 48, 2);
});
OUT.casa_sitio = mk(96, 64, c => {
  shadow(c, 48, 62, 46, 2);
  poly(c, '#96643a', [[4, 26], [48, 6], [92, 26]]); for (let y = 10; y < 26; y += 3) R(c, '#7a4a10', 48 - (y - 6) * 2.2, y, (y - 6) * 4.4, .7);   // clay tile roof
  R(c, '#c47a1c', 4, 25, 88, 2);
  R(c, '#e6e8ee', 8, 27, 80, 33); R(c, '#cfe0f2', 8, 27, 80, 1); R(c, '#a8acb5', 8, 55, 80, 5);
  [[14, 33], [64, 33]].forEach(([x, y]) => { R(c, '#3d5f94', x, y, 16, 14); R(c, '#ffd65a', x + 2, y + 2, 12, 10); R(c, '#3d5f94', x + 7.5, y + 2, 1, 10); R(c, '#3d5f94', x + 2, y + 6.5, 12, 1); });
  R(c, '#3d5f94', 40, 34, 14, 24); R(c, '#5279ad', 42, 36, 4, 20); R(c, '#5279ad', 48, 36, 4, 20); circ(c, '#ffd65a', 51, 46, .8);
  R(c, '#6e4526', 2, 58, 92, 3); for (let x = 4; x < 92; x += 10) R(c, '#4a2d1c', x, 46, 1.5, 12);   // porch rail
  R(c, '#a8acb5', 70, 0, 6, 10); c.fillStyle = 'rgba(207,224,242,.5)'; [[73, -1, 3], [76, -5, 4], [80, -10, 5]].forEach(([x, y, r]) => { c.beginPath(); c.arc(x, y + 10, r, 0, 7); c.fill(); });
});
OUT.capela = mk(56, 72, c => {
  shadow(c, 28, 70, 26, 2);
  R(c, '#e6e8ee', 18, 6, 20, 26); poly(c, '#c47a1c', [[16, 8], [28, 0], [40, 8]]); R(c, '#2b1a12', 25, 12, 6, 8); circ(c, '#ffd65a', 28, 16, 2);   // bell tower
  R(c, '#ffd65a', 27, -1, 2, 7); R(c, '#ffd65a', 25, 1, 6, 1.5);
  R(c, '#e6e8ee', 6, 30, 44, 40); poly(c, '#96643a', [[2, 32], [28, 20], [54, 32]]); R(c, '#cfe0f2', 6, 30, 44, 1);
  rr(c, '#3d5f94', 21, 46, 14, 24, 7); R(c, '#5279ad', 27.5, 48, 1, 22);
  circ(c, '#3d5f94', 28, 38, 4); circ(c, '#ffd65a', 28, 38, 2.5); R(c, '#3d5f94', 27.5, 35, 1, 6); R(c, '#3d5f94', 25, 37.5, 6, 1);
  R(c, '#a8acb5', 4, 68, 48, 4);
});
function vaca(body, spots) {
  return mk(40, 28, c => {
    shadow(c, 20, 26.5, 17, 1.5);
    [8, 13, 27, 32].forEach(x => { R(c, body, x, 18, 3, 8); R(c, '#2a2c33', x, 25, 3, 1.5); });
    rr(c, body, 6, 8, 28, 12, 5);
    if (spots) [[10, 10, 6, 5], [22, 12, 7, 6], [28, 9, 4, 4]].forEach(([x, y, w, h]) => rr(c, spots, x, y, w, h, 2));
    else rr(c, lighten(body, .2), 22, 4, 8, 8, 4);                                      // the hump of a nelore
    rr(c, body, 30, 12, 8, 12, 3); R(c, '#2a2c33', 34, 22, 4, 2); R(c, '#2a2c33', 32, 15, 1, 1);   // head down, grazing
    R(c, '#e6e8ee', 31, 11, 1.5, 3); R(c, '#e6e8ee', 36, 11, 1.5, 3);
    line(c, body, 1, [[6, 10], [3, 18]]); R(c, '#2a2c33', 2, 18, 2, 2);
  });
}
OUT.vaca0 = vaca('#e6e8ee', null);
OUT.vaca1 = vaca('#e6e8ee', '#16202b');
OUT.porteira = mk(48, 24, c => {
  [3, 45].forEach(x => { R(c, '#4a2d1c', x - 2, 0, 4, 24); R(c, '#6e4526', x - 2, 0, 1, 24); });
  [4, 10, 16].forEach(y => R(c, '#c68a5a', 5, y, 38, 2.5));
  line(c, '#c68a5a', 2.5, [[6, 20], [42, 5]]); [4, 10, 16].forEach(y => R(c, '#96643a', 5, y + 2, 38, .5));
});
function placaMadeira(l1, l2, col) {
  return mk(48, 40, c => {
    R(c, '#4a2d1c', 22, 18, 4, 22); R(c, '#6e4526', 22, 18, 1, 22);
    rr(c, '#e3ab7c', 2, 2, 44, 20, 1); for (let y = 6; y < 22; y += 5) R(c, '#c68a5a', 3, y, 42, .5);
    ctext(c, l1, 24, 4.5, col, 1); ctext(c, l2, 24, 13, col, .8);
  });
}
OUT.placa_queijo = placaMadeira('QUEIJO', 'CASEIRO', '#c22630');
OUT.placa_ovos = placaMadeira('OVOS', 'CAIPIRA', '#16482c');
OUT.placa_gado = mk(36, 48, c => {
  R(c, '#4a4d57', 16.5, 22, 3, 26);
  poly(c, '#2a2c33', [[18, 0], [36, 18], [18, 36], [0, 18]]); poly(c, '#ffd65a', [[18, 2], [34, 18], [18, 34], [2, 18]]);
  rr(c, '#2a2c33', 9, 15, 15, 7, 3); R(c, '#2a2c33', 22, 13, 5, 5); [11, 14, 19, 22].forEach(x => R(c, '#2a2c33', x, 21, 1.5, 5));
});
OUT.venda = mk(128, 64, c => {
  shadow(c, 64, 62, 62, 2);
  poly(c, '#7a4a10', [[0, 18], [8, 8], [120, 8], [128, 18]]); R(c, '#4a2d1c', 0, 18, 128, 2);
  R(c, '#c68a5a', 6, 20, 116, 40); for (let x = 6; x < 122; x += 4) R(c, '#96643a', x, 20, .7, 40);
  R(c, '#e6e8ee', 26, 10, 76, 9); ctext(c, 'VENDA DO ZÉ', 64, 11.5, '#c22630', 1);
  R(c, '#2b1a12', 14, 32, 24, 28); R(c, '#ffd65a', 16, 34, 20, 12); R(c, '#2b1a12', 25.5, 34, 1, 12);   // open door, lit inside
  R(c, '#3d5f94', 50, 30, 26, 16); R(c, '#ffd65a', 52, 32, 22, 12);
  ctext(c, 'PINGA', 63, 34, '#c22630'); ctext(c, 'FUMO', 63, 40, '#c22630');
  R(c, '#6e4526', 84, 50, 30, 3); R(c, '#4a2d1c', 86, 53, 2, 7); R(c, '#4a2d1c', 110, 53, 2, 7);   // bench
  rr(c, '#c22630', 116, 30, 10, 30, 2); R(c, '#e6e8ee', 118, 33, 6, 6); R(c, '#16202b', 119, 34, 4, 1); line(c, '#0a0a0f', 1, [[125, 40], [128, 52]]);   // old pump
  R(c, '#2a2c33', 0, 60, 128, 4);
});
OUT.ipe = mk(48, 64, c => {
  R(c, '#4a2d1c', 22, 32, 4, 32); line(c, '#4a2d1c', 2, [[24, 38], [14, 26]]); line(c, '#4a2d1c', 2, [[24, 36], [34, 24]]);
  const bl = [[24, 20, 13], [12, 24, 8], [36, 24, 8], [24, 9, 8]];
  bl.forEach(b => circ(c, '#c47a1c', b[0], b[1], b[2]));
  for (let i = 0; i < 170; i++) { const b = bl[i % 4], a = Math.random() * 6.28, d = Math.sqrt(Math.random()) * b[2], up = Math.sin(a) < 0; circ(c, up ? (Math.random() < .5 ? '#ffd65a' : '#fff3b0') : '#f2a62a', b[0] + Math.cos(a) * d, b[1] + Math.sin(a) * d, .5 + Math.random() * .9); }
});
OUT.bambu = mk(40, 64, c => {
  for (let i = 0; i < 9; i++) { const x = 8 + i * 3, lean = (i - 4) * 1.6; line(c, i % 2 ? '#3fae5a' : '#23743f', 1.5, [[x, 64], [x + lean * 3, 6 + (i % 3) * 4]]); for (let y = 54; y > 12; y -= 9) R(c, '#16482c', x + lean * 3 * (64 - y) / 58 - .5, y, 2, .5); }
  for (let i = 0; i < 60; i++) { const x = Math.random() * 40, y = 4 + Math.random() * 36; poly(c, Math.random() < .5 ? '#23743f' : '#8fe07a', [[x, y], [x + 4, y + 1], [x, y + 1.2]]); }
});
function placaMarrom(lines) {   // brown tourist sign, the Brazilian kind for farms, chapels and waterfalls
  return mk(72, 64, c => {
    R(c, '#4a4d57', 10, 30, 3, 34); R(c, '#4a4d57', 59, 30, 3, 34);
    const h = lines.length * 10 + 6; rr(c, '#e6e8ee', 0, 0, 72, h, 2); rr(c, '#6e4526', 1, 1, 70, h - 2, 1.5);
    lines.forEach((l, i) => ctext(c, l, 36, 5 + i * 10, '#e6e8ee', 1));
  });
}
OUT.placa_sitio0 = placaMarrom(['SÍTIO', 'SÃO JOSÉ', '2 KM']);
OUT.placa_sitio1 = placaMarrom(['CAPELA DE', 'SANTA LUZIA']);
OUT.placa_sitio2 = placaMarrom(['CACHOEIRA', 'DO ROSA', '5 KM']);
OUT.placa_venda = placaMarrom(['VENDA', 'A 1 KM']);

/* ================= the expressway: Rodovia Expressa ================= */
OUT.luminaria = mk(80, 110, c => {   // double-arm lamp standing on the median barrier
  R(c, '#777b86', 38.5, 10, 3, 100); R(c, '#a8acb5', 38.5, 10, 1, 100);
  line(c, '#777b86', 2, [[40, 12], [30, 6], [8, 5]]); line(c, '#777b86', 2, [[40, 12], [50, 6], [72, 5]]);
  rr(c, '#4a4d57', 2, 3, 14, 4, 1.5); R(c, '#fff3b0', 4, 6, 10, 1.5); rr(c, '#4a4d57', 64, 3, 14, 4, 1.5); R(c, '#fff3b0', 66, 6, 10, 1.5);
});
OUT.muro = mk(96, 40, c => {   // sound barrier panel
  R(c, '#777b86', 0, 6, 96, 34); R(c, '#a8acb5', 0, 6, 96, 1.5);
  for (let x = 0; x < 96; x += 6) { R(c, '#4a4d57', x, 8, .7, 32); R(c, '#9a9ea8', x + 3, 8, .5, 32); }
  for (let x = 0; x < 96; x += 24) R(c, '#2a2c33', x, 0, 3, 40);
  const bl = [[12, 6, 6], [40, 5, 7], [70, 6, 6], [90, 6, 5]]; bl.forEach(b => circ(c, '#16482c', b[0], b[1], b[2] * .7)); leaves(c, bl, 50);
});
OUT.portico = mk(240, 90, c => {   // overhead gantry with two direction panels
  [6, 228].forEach(x => { R(c, '#777b86', x, 18, 6, 72); R(c, '#a8acb5', x, 18, 1.5, 72); R(c, '#4a4d57', x - 2, 86, 10, 4); });
  R(c, '#777b86', 6, 14, 228, 4); R(c, '#777b86', 6, 30, 228, 2);
  for (let x = 10; x < 230; x += 8) line(c, '#4a4d57', .7, [[x, 18], [x + 8, 30]]);
  const panel = (x, w, l1, l2, arrow) => {
    rr(c, '#e6e8ee', x, 0, w, 30, 2); rr(c, '#16482c', x + 1, 1, w - 2, 28, 1.5);
    ctext(c, l1, x + w / 2 - (arrow ? 6 : 0), 5, '#e6e8ee', 1); ctext(c, l2, x + w / 2 - (arrow ? 6 : 0), 16, '#e6e8ee', 1);
    if (arrow) { const ax = x + w - 14; line(c, '#e6e8ee', 2, [[ax, 22], [ax + 8, 10]]); poly(c, '#e6e8ee', [[ax + 10, 7], [ax + 9, 14], [ax + 4, 10]]); }
  };
  panel(24, 104, 'SÃO PAULO', '85 KM', false);
  panel(136, 92, 'SAÍDA 32', 'JUNDIAÍ', true);
});
function ledBoard(bg, fg, l1, l2) {
  return mk(80, 58, c => {
    R(c, '#4a4d57', 37, 36, 6, 22); R(c, '#777b86', 37, 36, 1.5, 22);
    R(c, '#0a0a0f', 0, 0, 80, 38); R(c, bg, 3, 3, 74, 32);
    for (let y = 3; y < 35; y += 1.5) R(c, 'rgba(0,0,0,.25)', 3, y, 74, .5);
    ctext(c, l1, 40, 8, fg, 1); ctext(c, l2, 40, 20, fg, 1);
  });
}
OUT.led0 = ledBoard('#24345f', '#3fe0e8', 'REDUZA', 'NA CHUVA');
OUT.led1 = ledBoard('#3a0d12', '#ffd65a', 'CAFÉ 24H', 'KM 112');
OUT.sos = mk(16, 30, c => { R(c, '#4a4d57', 7, 14, 2, 16); rr(c, '#f2a62a', 1, 0, 14, 16, 1.5); R(c, '#c47a1c', 1, 12, 14, 4); ctext(c, 'SOS', 8, 3, '#0a0a0f', .9); R(c, '#2a2c33', 4, 10, 8, 3); });
OUT.placa_radar = mk(56, 64, c => {
  R(c, '#4a4d57', 26.5, 34, 3, 30);
  rr(c, '#e6e8ee', 0, 0, 56, 36, 2); rr(c, '#2a2c33', 1, 1, 54, 34, 1.5); rr(c, '#e6e8ee', 2, 2, 52, 32, 1);
  circ(c, '#c22630', 13, 18, 10); circ(c, '#e6e8ee', 13, 18, 7.5); ctext(c, '110', 13, 15, '#0a0a0f', .9);
  ctext(c, 'RADAR', 40, 10, '#0a0a0f', .8); ctext(c, 'KM/H', 40, 20, '#0a0a0f', .8);
});
OUT.placa_saida = sign(['SAÍDA 45', 'RIO CLARO']);
OUT.placa_pedagio = sign(['PEDÁGIO', 'ELETRÔNICO', 'A 3 KM']);
OUT.placa_parada = sign(['PARADA', 'EXPRESSA', 'A 1 KM']);
OUT.parada = mk(176, 72, c => {   // service area: canopy with LED edge, pumps and a convenience store
  shadow(c, 88, 70, 86, 2);
  R(c, '#e6e8ee', 0, 30, 54, 36); R(c, '#3fe0e8', 6, 38, 42, 16); R(c, '#24345f', 0, 26, 54, 4); ctext(c, 'LOJA', 27, 27, '#e6e8ee');
  R(c, '#a8acb5', 66, 22, 3, 44); R(c, '#a8acb5', 160, 22, 3, 44);
  R(c, '#e6e8ee', 56, 8, 116, 14); R(c, '#3d5f94', 56, 18, 116, 4); R(c, '#3fe0e8', 56, 22, 116, 1.5);
  ctext(c, 'PARADA EXPRESSA', 114, 11, '#24345f', 1);
  [86, 116, 146].forEach(x => { rr(c, '#e6e8ee', x, 46, 10, 20, 1); R(c, '#3d5f94', x, 46, 10, 3); R(c, '#0a0a0f', x + 2, 51, 6, 4); R(c, '#3fe0e8', x + 2.5, 52, 5, 2); });
  R(c, '#2a2c33', 0, 66, 176, 6); R(c, '#e6e8ee', 0, 66, 176, .5);
});

window.ART = OUT;
})();

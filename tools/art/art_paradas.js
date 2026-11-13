// Art for "paradas e memórias": the three stop scenes (venda, posto, loja da parada), the snacks on the
// menu board, the passengers (a vó and a caramelo dog) and the three postcards. Same helpers as art.js.
// The scenes leave the view outside transparent: the game paints the sky, the road, the parked car and the rain.
(() => {
const { R, poly, circ, rr, mk, text, ctext, W, H } = window.__H;
const OUT = {};
const line = (c, col, w, pts) => { c.strokeStyle = col; c.lineWidth = w; c.beginPath(); pts.forEach((p, i) => i ? c.lineTo(p[0], p[1]) : c.moveTo(p[0], p[1])); c.stroke(); };
const ell = (c, col, x, y, rx, ry, rot = 0) => { c.fillStyle = col; c.beginPath(); c.ellipse(x, y, rx, ry, rot, 0, 7); c.fill(); };
const arc = (c, col, w, x, y, r, a0, a1) => { c.strokeStyle = col; c.lineWidth = w; c.beginPath(); c.arc(x, y, r, a0, a1); c.stroke(); };
const shadow = (c, cx, cy, rx, ry) => ell(c, 'rgba(0,0,0,.45)', cx, cy, rx, ry);

/* ================= shared pieces of a stop ================= */
// the outside opening is x 12..264, y 22..146; the menu board hangs at 270..366 x 30..124 (parada.gd reads these)
function board(c, frame, face, inner) {
  R(c, '#0a0a0f', 271, 31, 96, 94);                       // shadow on the wall
  rr(c, frame, 268, 28, 100, 98, 2); R(c, inner, 271, 31, 94, 92); R(c, face, 272, 32, 92, 90);
  R(c, lighten2(frame), 268, 28, 100, 1);
}
const lighten2 = h => h === '#6e4526' ? '#96643a' : h === '#2a2c33' ? '#4a4d57' : '#a8acb5';
function chalkSmudge(c) {   // old chalk ghosts on the board
  c.fillStyle = 'rgba(230,232,238,.07)';
  for (let i = 0; i < 9; i++) c.fillRect(276 + (i * 37) % 80, 40 + (i * 23) % 76, 10 + (i * 7) % 14, 1.5);
}
function counter(c, top, topHi, front, frontLine, kick) {
  R(c, '#0a0a0f', 0, 144, W, 3);
  R(c, top, 0, 146, W, 9); R(c, topHi, 0, 146, W, 1); R(c, 'rgba(0,0,0,.35)', 0, 154, W, 1.5);
  R(c, front, 0, 156, W, 60); R(c, kick, 0, 208, W, 8);
  for (let x = 0; x < W; x += 24) R(c, frontLine, x, 156, 1, 52);
}
function post(c, x, col, hi, sh) { R(c, col, x, 0, 12, 146); R(c, hi, x, 0, 1.5, 146); R(c, sh, x + 10, 0, 2, 146); }
function signBand(c, bg, rim, x0 = 60, x1 = 324) { R(c, '#0a0a0f', x0 - 1, 2, x1 - x0 + 2, 17); R(c, rim, x0, 3, x1 - x0, 15); R(c, bg, x0 + 1.5, 4.5, x1 - x0 - 3, 12); }
function copo(c, x, y, fill, foam) {     // copo americano: faceted glass, 7 x 10
  R(c, 'rgba(207,224,242,.55)', x, y, 7, 10); R(c, fill, x + .5, y + 2.5, 6, 7); R(c, foam, x + .5, y + 2, 6, 1);
  R(c, '#e6e8ee', x, y, 7, .5); R(c, 'rgba(230,232,238,.7)', x + .5, y + 3, .5, 6);
  for (let i = 1; i < 6; i++) R(c, 'rgba(10,10,15,.25)', x + i * 1.15, y + 3, .5, 6.5);
  R(c, 'rgba(230,232,238,.6)', x, y + 9.5, 7, .5);
}
function steamless() {}
// someone behind the counter, from the waist up: x is the centre, y the top of the head
function person(c, x, y, o) {
  const skin = o.skin || '#c68a5a', sk2 = o.sk2 || '#96643a';
  // body
  rr(c, o.shirt, x - 13, y + 20, 26, 40, 5); R(c, o.shirt2, x - 13, y + 52, 26, 8);
  if (o.apron) { R(c, o.apron, x - 8, y + 30, 16, 30); R(c, o.apron, x - 6, y + 24, 12, 6); line(c, o.apron, .7, [[x - 6, y + 24], [x - 3, y + 19]]); line(c, o.apron, .7, [[x + 6, y + 24], [x + 3, y + 19]]); }
  if (o.plaid) for (let i = 0; i < 26; i += 4) { R(c, o.plaid, x - 13 + i, y + 20, 1, 40); R(c, o.plaid, x - 13, y + 22 + i * 1.4, 26, .7); }
  if (o.stripe) R(c, o.stripe, x - 13, y + 34, 26, 2);
  R(c, sk2, x - 3, y + 15, 6, 6);                                         // neck
  // arms resting on the counter
  rr(c, o.shirt, x - 19, y + 24, 8, 26, 3); rr(c, o.shirt, x + 11, y + 24, 8, 26, 3);
  ell(c, skin, x - 15, y + 52, 4, 3); ell(c, skin, x + 15, y + 52, 4, 3);
  // head
  ell(c, skin, x, y + 9, 8, 9.5); ell(c, sk2, x + 5, y + 11, 3, 6);
  R(c, skin, x - 9, y + 8, 2, 4); R(c, skin, x + 7, y + 8, 2, 4);             // ears
  R(c, '#0a0a0f', x - 4, y + 8, 1.5, 1.5); R(c, '#0a0a0f', x + 2.5, y + 8, 1.5, 1.5);
  if (o.mustache) R(c, o.hair, x - 4, y + 13, 8, 1.5);
  R(c, '#7a1620', x - 2, y + 15, 4, .7);
  if (o.hat === 'palha') {
    ell(c, '#c47a1c', x, y + 2, 15, 3); ell(c, '#f2a62a', x, y - 1, 9, 5); R(c, '#7a1620', x - 9, y + 1, 18, 1.5); ell(c, '#ffd65a', x - 3, y - 3, 4, 1.5);
  } else if (o.hat === 'bone') {
    ell(c, o.cap, x, y + 1, 8.5, 5); R(c, o.cap, x - 9, y + 1, 18, 3); R(c, o.capBrim, x - 13, y + 3, 10, 2); R(c, o.capLogo, x - 2, y - 1, 4, 2);
  } else {
    ell(c, o.hair, x, y + 2, 8.5, 5); R(c, o.hair, x - 8.5, y + 2, 2, 7); R(c, o.hair, x + 6.5, y + 2, 2, 7);
  }
}

/* ================= VENDA (Estrada do Sítio): wood, clay tiles, cheese and doce de leite ================= */
OUT.parada_venda = mk(W, H, c => {
  // roof: rafters and the clay-tile edge
  R(c, '#2b1a12', 0, 0, W, 16);
  for (let x = 4; x < W; x += 22) { R(c, '#4a2d1c', x, 0, 6, 16); R(c, '#6e4526', x, 0, 1, 16); }
  for (let x = -6; x < W; x += 12) { ell(c, '#7a4a10', x + 6, 18, 6.5, 4); ell(c, '#c47a1c', x + 6, 17, 5.5, 3); R(c, '#e3ab7c', x + 3, 15.5, 5, .7); }
  signBand(c, '#e6e8ee', '#96643a');
  R(c, '#c22630', 64, 15, 256, .7);
  // whitewashed wall on the right, blue barra at the bottom
  R(c, '#cfe0f2', 264, 20, 120, 126); R(c, '#a9c0d8', 264, 20, 2, 126);
  R(c, '#3d5f94', 264, 128, 120, 18); R(c, '#5279ad', 264, 128, 120, 1);
  for (let i = 0; i < 14; i++) R(c, 'rgba(111,151,196,.35)', 270 + (i * 53) % 108, 24 + (i * 31) % 100, 4 + i % 3, 1);   // worn lime
  board(c, '#6e4526', '#16202b', '#2b1a12'); chalkSmudge(c);
  // a string of little cheeses hanging by the door frame
  line(c, '#e3ab7c', .5, [[374, 20], [374, 96]]);
  for (let k = 0; k < 4; k++) { ell(c, '#ffd65a', 375, 34 + k * 17, 5, 6); ell(c, '#f2a62a', 377, 36 + k * 17, 2.5, 4); line(c, '#c47a1c', .5, [[371, 31 + k * 17], [379, 31 + k * 17]]); }
  // shelf with doce de leite jars and pinga bottles, under the board
  R(c, '#4a2d1c', 266, 126, 0, 0);
  // left post: a round wooden pole
  post(c, 0, '#6e4526', '#96643a', '#4a2d1c');
  // the porch rail outside, a bench and a sleeping dog (seen through the opening)
  R(c, '#4a2d1c', 12, 118, 252, 3); R(c, '#6e4526', 12, 118, 252, 1);
  for (let x = 20; x < 262; x += 18) R(c, '#4a2d1c', x, 121, 2, 25);
  // Seu Zé behind the counter, by the wall
  person(c, 238, 78, { shirt: '#c22630', shirt2: '#7a1620', plaid: '#7a1620', hair: '#4a4d57', hat: 'palha', mustache: true, skin: '#c68a5a', sk2: '#96643a' });
  // counter: old peroba wood
  counter(c, '#96643a', '#c68a5a', '#4a2d1c', '#2b1a12', '#2b1a12');
  for (let x = 6; x < W; x += 24) { R(c, '#6e4526', x, 160, 14, .7); R(c, '#6e4526', x + 4, 186, 10, .7); }
  // on the counter: cheese on a board, a glass baleiro, the thermos and a copo americano
  rr(c, '#6e4526', 18, 140, 44, 6, 1); ell(c, '#f2a62a', 38, 137, 16, 6); ell(c, '#ffd65a', 38, 135, 16, 5.5); R(c, '#e6e8ee', 26, 134, 10, .7);
  poly(c, '#f3cfa6', [[44, 136], [56, 133], [56, 140], [44, 141]]);
  rr(c, 'rgba(207,224,242,.45)', 70, 118, 20, 28, 3); R(c, '#a8acb5', 72, 116, 16, 3);
  for (let i = 0; i < 10; i++) circ(c, ['#c22630', '#ffd65a', '#3fae5a', '#e6e8ee', '#f2a62a'][i % 5], 74 + (i * 7) % 13, 128 + (i * 5) % 15, 1.6);
  R(c, '#e6e8ee', 72, 120, 1, 20);
  // thermos (garrafa térmica) and the cup
  rr(c, '#c22630', 206, 118, 14, 28, 2); R(c, '#e6e8ee', 206, 118, 14, 5); R(c, '#7a1620', 218, 122, 2, 24); R(c, '#e6e8ee', 209, 130, 8, 2);
  R(c, '#0a0a0f', 210, 115, 6, 3); rr(c, '#e6e8ee', 219, 124, 4, 9, 1.5);
  copo(c, 194, 136, '#2b1a12', '#6e4526');
});

/* ================= POSTO (BR-116): tiles, the glass warmer and the cane press ================= */
OUT.parada_posto = mk(W, H, c => {
  // concrete canopy with the red band of POSTO ESTRELA
  R(c, '#e6e8ee', 0, 0, W, 21); R(c, '#c22630', 0, 17, W, 4); R(c, '#ffd65a', 0, 17, W, 1); R(c, '#a8acb5', 0, 0, W, 1);
  for (let x = 8; x < W; x += 40) { R(c, '#fff3b0', x, 21, 20, 1.5); R(c, 'rgba(255,243,176,.35)', x - 4, 22.5, 28, 1); }   // tube lights
  signBand(c, '#fff3b0', '#c22630');
  for (let k = 0; k < 2; k++) { const sx = k ? 316 : 68; circ(c, '#c22630', sx, 10.5, 5); poly(c, '#ffd65a', [[sx, 6.5], [sx + 1.2, 9.6], [sx + 4, 9.8], [sx + 1.8, 11.6], [sx + 2.6, 14.5], [sx, 12.8], [sx - 2.6, 14.5], [sx - 1.8, 11.6], [sx - 4, 9.8], [sx - 1.2, 9.6]]); }
  // white tile wall with the board
  R(c, '#e6e8ee', 264, 21, 120, 125);
  for (let y = 21; y < 146; y += 8) R(c, '#a8acb5', 264, y, 120, .5);
  for (let x = 264; x < W; x += 8) R(c, '#a8acb5', x, 21, .5, 125);
  R(c, '#23743f', 264, 132, 120, 14); R(c, '#3fae5a', 264, 132, 120, 1);
  board(c, '#2a2c33', '#16202b', '#0a0a0f'); chalkSmudge(c);
  R(c, '#c22630', 268, 28, 100, 3); ctext(c, 'LANCHONETE', 318, 28.5, '#fff3b0', .5);
  // steel column
  post(c, 0, '#a8acb5', '#e6e8ee', '#777b86');
  // outside: two pumps and the frentista waiting by the car
  for (const x of [34, 222]) {
    R(c, '#4a4d57', x - 2, 140, 26, 6);
    rr(c, '#c22630', x, 88, 22, 52, 2); R(c, '#f0484a', x, 88, 22, 1); R(c, '#e6e8ee', x + 3, 93, 16, 12); R(c, '#16202b', x + 4, 95, 14, 3);
    R(c, '#3fe0e8', x + 5, 96, 6, 1); R(c, '#16202b', x + 4, 100, 10, 2); R(c, '#ffd65a', x + 3, 110, 16, 4); ctext(c, 'ESTRELA', x + 11, 110.5, '#c22630', .5);
    R(c, '#0a0a0f', x + 20, 116, 3, 2); line(c, '#0a0a0f', 1, [[x + 22, 117], [x + 26, 124], [x + 24, 138]]);
  }
  // frentista: orange overalls and a cap
  const fx = 104, fy = 92;
  R(c, '#0a0a0f', fx - 4, fy + 44, 3, 6); R(c, '#0a0a0f', fx + 1, fy + 44, 3, 6);
  rr(c, '#f2a62a', fx - 6, fy + 12, 12, 34, 2); R(c, '#c47a1c', fx - 6, fy + 28, 12, 1.5); R(c, '#3d5f94', fx - 4, fy + 14, 8, 8); R(c, '#e6e8ee', fx - 3, fy + 16, 3, 1);
  rr(c, '#f2a62a', fx - 9, fy + 13, 4, 18, 2); rr(c, '#f2a62a', fx + 5, fy + 13, 4, 14, 2); ell(c, '#96643a', fx + 7, fy + 28, 2, 2);
  ell(c, '#96643a', fx, fy + 6, 4.5, 5.5); R(c, '#0a0a0f', fx - 2, fy + 5, 1, 1); R(c, '#0a0a0f', fx + 1.5, fy + 5, 1, 1);
  ell(c, '#c22630', fx, fy + 1.5, 5, 3); R(c, '#c22630', fx - 9, fy + 2, 8, 1.5);
  // the counter: granite top over green tiles
  counter(c, '#4a4d57', '#777b86', '#16482c', '#0c2a1c', '#0a1614');
  for (let x = 0; x < W; x += 12) R(c, '#0c2a1c', x, 182, 12, .5);
  for (let i = 0; i < 60; i++) R(c, i % 2 ? '#2a2c33' : '#a8acb5', (i * 67) % W, 147.5 + (i * 13) % 6, .5, .5);
  // the glass warmer: coxinhas, pastéis and pão de queijo under a warm lamp
  rr(c, '#a8acb5', 14, 104, 86, 42, 2); R(c, '#777b86', 14, 142, 86, 4);
  R(c, '#7a4a10', 17, 107, 80, 34); R(c, 'rgba(255,214,90,.35)', 17, 107, 80, 34); R(c, '#fff3b0', 17, 107, 80, 2);
  R(c, '#a8acb5', 17, 123, 80, 1.5);
  for (let i = 0; i < 6; i++) { poly(c, '#c47a1c', [[22 + i * 12, 121], [26 + i * 12, 112], [30 + i * 12, 121]]); ell(c, '#c47a1c', 26 + i * 12, 119, 4, 3); R(c, '#f2a62a', 24 + i * 12, 116, 1, 2); }
  for (let i = 0; i < 4; i++) { ell(c, '#f2a62a', 28 + i * 19, 136, 8, 4); R(c, '#c47a1c', 21 + i * 19, 136, 14, 1); R(c, '#ffd65a', 24 + i * 19, 133.5, 3, .7); }
  for (let i = 0; i < 5; i++) circ(c, '#ffd65a', 24 + i * 4, 129, 1.8);
  R(c, 'rgba(230,232,238,.5)', 19, 108, 1, 32); R(c, 'rgba(230,232,238,.5)', 54, 108, 1, 14);
  // napkins, ketchup and mustard
  rr(c, '#a8acb5', 110, 132, 12, 14, 1); R(c, '#e6e8ee', 112, 128, 8, 5); R(c, '#777b86', 110, 140, 12, 1);
  rr(c, '#c22630', 125, 130, 5, 16, 1.5); R(c, '#ffd65a', 126.5, 127, 2, 3); rr(c, '#ffd65a', 131, 130, 5, 16, 1.5); R(c, '#c22630', 132.5, 127, 2, 3);
  // cane press (moenda) with stalks behind, on the right of the counter
  for (let i = 0; i < 6; i++) { R(c, i % 2 ? '#3fae5a' : '#8fe07a', 236 + i * 3, 86, 2, 60); for (let y = 92; y < 146; y += 9) R(c, '#16482c', 236 + i * 3, y, 2, .7); }
  rr(c, '#23743f', 212, 118, 40, 28, 2); R(c, '#3fae5a', 212, 118, 40, 1.5); circ(c, '#a8acb5', 222, 128, 7); circ(c, '#4a4d57', 222, 128, 2);
  for (let a = 0; a < 6; a++) line(c, '#4a4d57', 1, [[222, 128], [222 + Math.cos(a) * 7, 128 + Math.sin(a) * 7]]);
  R(c, '#e6e8ee', 238, 128, 10, 3); ctext(c, 'CALDO', 243, 128.5, '#16482c', .4);
  R(c, '#777b86', 244, 138, 6, 8);
  // balconista with a white cap and apron
  person(c, 172, 84, { shirt: '#e6e8ee', shirt2: '#a8acb5', apron: '#c22630', hair: '#2b1a12', hat: 'bone', cap: '#e6e8ee', capBrim: '#a8acb5', capLogo: '#c22630', skin: '#e3ab7c', sk2: '#c68a5a' });
});

/* ================= LOJA DA PARADA (Rodovia Expressa): clean, cold light, an espresso machine ================= */
OUT.parada_loja = mk(W, H, c => {
  R(c, '#e6e8ee', 0, 0, W, 20); R(c, '#3d5f94', 0, 15, W, 5); R(c, '#3fe0e8', 0, 20, W, 1.5);
  signBand(c, '#24345f', '#e6e8ee');
  for (let x = 4; x < W; x += 30) R(c, '#cfe0f2', x, 21.5, 16, 1);
  // wall: grey panels, digital menu board, a fridge of drinks at the edge
  R(c, '#777b86', 264, 21, 120, 125); for (let x = 264; x < W; x += 30) R(c, '#4a4d57', x, 21, 1, 125);
  board(c, '#2a2c33', '#0b1020', '#05070c'); R(c, '#3fe0e8', 272, 32, 92, .7); R(c, '#3fe0e8', 272, 121.3, 92, .7);
  rr(c, '#a8acb5', 368, 24, 18, 122, 1); R(c, '#cfe0f2', 370, 26, 14, 118);
  for (let y = 30; y < 140; y += 14) { R(c, '#777b86', 370, y + 11, 14, 1); for (let x = 371; x < 384; x += 3.5) R(c, ['#c22630', '#3fae5a', '#ffd65a', '#3d5f94', '#f2a62a'][((x + y) | 0) % 5], x, y + 3, 2.5, 8); }
  post(c, 0, '#4a4d57', '#777b86', '#2a2c33');
  // outside: lit canopy columns and a bin; the rest is the forecourt
  R(c, '#a8acb5', 52, 22, 5, 124); R(c, '#e6e8ee', 52, 22, 1, 124);
  rr(c, '#3d5f94', 30, 124, 12, 22, 1); R(c, '#24345f', 30, 124, 12, 3);
  // counter: white top, navy front
  counter(c, '#e6e8ee', '#ffffff', '#24345f', '#1a2547', '#121a33');
  R(c, '#3fe0e8', 0, 156, W, .7);
  // display case with misto, pão de queijo and coxinha
  rr(c, '#a8acb5', 14, 108, 82, 38, 3); R(c, '#cfe0f2', 17, 111, 76, 31); R(c, 'rgba(255,243,176,.4)', 17, 111, 76, 31); R(c, '#a8acb5', 17, 126, 76, 1.5);
  for (let i = 0; i < 5; i++) { R(c, '#c47a1c', 21 + i * 14, 118, 11, 6); R(c, '#ffd65a', 21 + i * 14, 120, 11, 1.5); }
  for (let i = 0; i < 7; i++) circ(c, '#ffd65a', 23 + i * 10, 135, 2.2);
  R(c, 'rgba(255,255,255,.6)', 19, 112, 1, 28);
  // espresso machine and paper cups
  rr(c, '#2a2c33', 196, 104, 36, 42, 2); R(c, '#a8acb5', 196, 104, 36, 4); R(c, '#0a0a0f', 202, 116, 24, 16); R(c, '#3fe0e8', 204, 109, 8, 2);
  R(c, '#777b86', 210, 116, 8, 4); R(c, '#e6e8ee', 211, 126, 6, 6); R(c, '#7a4a10', 211.5, 127, 5, 2);
  for (let i = 0; i < 4; i++) R(c, '#e6e8ee', 236, 132 - i * 3.5, 7, 3.5); R(c, '#c47a1c', 236, 136, 7, 10);
  // atendente: blue polo and cap
  person(c, 160, 84, { shirt: '#3d5f94', shirt2: '#24345f', stripe: '#3fe0e8', hair: '#2b1a12', hat: 'bone', cap: '#24345f', capBrim: '#1a2547', capLogo: '#3fe0e8', skin: '#96643a', sk2: '#6e4526' });
});

/* ================= snacks (32 x 24 each) ================= */
const snack = fn => mk(32, 24, c => { shadow(c, 16, 22, 13, 1.6); fn(c); });
const plate = c => { ell(c, '#a8acb5', 16, 20.5, 14, 3); ell(c, '#e6e8ee', 16, 19.5, 13, 2.6); };
const napkin = c => poly(c, '#e6e8ee', [[3, 21], [9, 15], [29, 15], [23, 21]]);
function bigCopo(c, fill, foam) {
  poly(c, 'rgba(207,224,242,.5)', [[10, 3], [22, 3], [21, 22], [11, 22]]);
  poly(c, fill, [[10.6, 7], [21.4, 7], [20.6, 21.5], [11.4, 21.5]]); R(c, foam, 10.6, 6.5, 10.8, 1.5);
  for (let i = 0; i < 6; i++) R(c, 'rgba(10,10,15,.3)', 11.6 + i * 1.6, 8.5, .6, 12.5);
  R(c, 'rgba(230,232,238,.9)', 11.6, 8.5, .6, 12.5); R(c, '#e6e8ee', 10, 3, 12, .6); R(c, '#e6e8ee', 11, 21.4, 10, .6);
  R(c, 'rgba(230,232,238,.6)', 10.5, 5, 11, .5);
}
OUT.lanche_cafe = snack(c => bigCopo(c, '#2b1a12', '#7a4a10'));
OUT.lanche_pingado = snack(c => bigCopo(c, '#c68a5a', '#f3cfa6'));
OUT.lanche_pao_queijo = snack(c => {
  napkin(c);
  [[10, 15], [16, 14], [22, 15], [13, 10], [19, 10]].forEach(([x, y]) => { circ(c, '#c47a1c', x, y, 4); circ(c, '#ffd65a', x - .5, y - .5, 3.4); R(c, '#fff3b0', x - 2, y - 2.5, 1.5, 1); R(c, '#f2a62a', x + 1, y + 1, 1, 1); });
});
OUT.lanche_pastel = snack(c => {
  napkin(c);
  rr(c, '#c47a1c', 3, 8, 26, 11, 3); rr(c, '#f2a62a', 4, 8, 24, 9, 3);
  for (let x = 5; x < 28; x += 2) R(c, '#c47a1c', x, 17, 1, 1.5);
  for (let i = 0; i < 9; i++) circ(c, '#ffd65a', 6 + (i * 7) % 20, 10 + (i * 3) % 5, .8);
});
OUT.lanche_caldo_cana = snack(c => {
  poly(c, 'rgba(207,224,242,.55)', [[8, 2], [24, 2], [22, 22], [10, 22]]);
  poly(c, '#8fe07a', [[8.7, 6], [23.3, 6], [21.6, 21.5], [10.4, 21.5]]); R(c, '#ffd65a', 9, 6, 14, 2.5); R(c, '#fff3b0', 9, 5.5, 14, 1);
  R(c, 'rgba(255,214,90,.6)', 11, 9, 2, 12); line(c, '#c22630', 1, [[18, 0], [16, 12]]);
  ell(c, '#3fae5a', 23, 4, 4, 3); ell(c, '#8fe07a', 23, 4, 3, 2); R(c, '#e6e8ee', 22, 3.5, 2, .7);
});
OUT.lanche_coxinha = snack(c => {
  napkin(c);
  poly(c, '#c47a1c', [[16, 2], [24, 16], [8, 16]]); ell(c, '#c47a1c', 16, 15, 8.5, 5.5);
  poly(c, '#f2a62a', [[16, 3], [22.5, 15], [9.5, 15]]); ell(c, '#f2a62a', 16, 14.5, 7, 4.5);
  for (let i = 0; i < 14; i++) R(c, i % 2 ? '#c47a1c' : '#ffd65a', 10 + (i * 5) % 12, 7 + (i * 3) % 10, .7, .7);
  R(c, '#fff3b0', 13, 8, 1, 3);
});
OUT.lanche_queijo_doce = snack(c => {
  rr(c, '#6e4526', 1, 16, 30, 5, 1); R(c, '#96643a', 1, 16, 30, 1);
  poly(c, '#f3cfa6', [[3, 16], [6, 7], [15, 7], [14, 16]]); poly(c, '#fff3b0', [[6, 7], [15, 7], [14, 9], [5.5, 9]]);
  R(c, '#e3ab7c', 7, 11, 1.5, 1); R(c, '#e3ab7c', 10, 13, 1, 1);
  ell(c, '#e6e8ee', 23, 13, 7, 4); ell(c, '#96643a', 23, 12, 6, 2.6); ell(c, '#c68a5a', 22, 11.5, 3, 1);
  line(c, '#a8acb5', 1, [[24, 12], [30, 4]]);
});
OUT.lanche_pamonha = snack(c => {
  ell(c, '#8fe07a', 16, 14, 13, 6); ell(c, '#3fae5a', 16, 15, 13, 5); ell(c, '#fff3b0', 16, 12.5, 9, 3.5);
  ell(c, '#ffd65a', 16, 12, 7, 2.5);
  line(c, '#e3ab7c', 1, [[10, 8], [10, 20]]); line(c, '#e3ab7c', 1, [[22, 8], [22, 20]]);
  poly(c, '#8fe07a', [[3, 14], [0, 10], [5, 12]]); poly(c, '#8fe07a', [[29, 14], [32, 10], [27, 12]]);
});
OUT.lanche_bolo_fuba = snack(c => {
  plate(c);
  poly(c, '#c47a1c', [[5, 18], [11, 6], [27, 10], [27, 18]]); poly(c, '#ffd65a', [[6.5, 17], [11.5, 8], [25.5, 11.5], [25.5, 17]]);
  poly(c, '#c47a1c', [[11, 6], [27, 10], [26, 11.5], [11.5, 8]]);
  for (let i = 0; i < 9; i++) R(c, '#16482c', 10 + (i * 7) % 14, 11 + (i * 3) % 5, .6, .6);
});
OUT.lanche_pao_chapa = snack(c => {
  plate(c);
  ell(c, '#c47a1c', 16, 14, 13, 5); ell(c, '#f2a62a', 16, 13, 12, 4); ell(c, '#fff3b0', 16, 12.5, 9, 2.6);
  for (let x = 8; x < 25; x += 4) R(c, '#7a4a10', x, 11, 1, 3.5);
  R(c, '#ffd65a', 14, 11.5, 5, 1.5);
});
OUT.lanche_caldinho = snack(c => {
  poly(c, '#e6e8ee', [[7, 7], [25, 7], [23, 21], [9, 21]]); R(c, '#a8acb5', 23, 7, 2, 14);
  ell(c, '#4a2d1c', 16, 8, 9, 2.5); ell(c, '#6e4526', 16, 7.6, 8, 1.8);
  for (let i = 0; i < 6; i++) R(c, i % 2 ? '#3fae5a' : '#f2a62a', 11 + i * 2, 7 + (i % 3) * .6, 1, .8);
  line(c, '#a8acb5', 1, [[20, 7], [27, 0]]);
});
OUT.lanche_misto = snack(c => {
  plate(c);
  poly(c, '#c47a1c', [[4, 16], [16, 6], [28, 16]]); poly(c, '#f2a62a', [[6, 15], [16, 7.5], [26, 15]]);
  R(c, '#ffd65a', 5, 15, 22, 2); R(c, '#f3cfa6', 6, 17, 20, 1.5); poly(c, '#ffd65a', [[12, 17], [14, 20], [16, 17]]);
  for (let i = 0; i < 3; i++) R(c, '#7a4a10', 10 + i * 4, 10 + i, 6, .7);
});
OUT.lanche_agua_coco = snack(c => {
  ell(c, '#23743f', 16, 14, 11, 9); ell(c, '#3fae5a', 15, 13, 9.5, 7.5); ell(c, '#8fe07a', 12, 10, 3, 2);
  ell(c, '#e6e8ee', 18, 6.5, 4, 1.5); line(c, '#f0484a', 1.2, [[18, 6], [23, 0]]);
});
OUT.lanche_milho = snack(c => {
  napkin(c);
  ell(c, '#c47a1c', 16, 13, 12, 4.5); ell(c, '#ffd65a', 16, 12.5, 11, 4);
  for (let x = 7; x < 26; x += 2.2) for (let y = 10; y < 16; y += 2) R(c, '#f2a62a', x, y, .7, .7);
  R(c, '#fff3b0', 12, 10, 6, 1.2);
  poly(c, '#8fe07a', [[3, 13], [0, 8], [7, 12]]); poly(c, '#3fae5a', [[3, 14], [0, 18], [7, 15]]);
});

/* ================= passengers ================= */
// the vó: body (cardigan, blouse, crochet bag on her lap) and four heads: awake, drowsy, asleep, startled
OUT.vo_corpo = mk(80, 128, c => {
  rr(c, '#3a2a55', 4, 14, 76, 120, 18);                                  // cardigan
  rr(c, '#6a4a7a', 8, 16, 66, 116, 16);
  R(c, '#3a2a55', 8, 40, 66, 1); for (let y = 24; y < 128; y += 6) R(c, '#3a2a55', 10, y, 60, .5);   // knit rows
  poly(c, '#e6e8ee', [[22, 10], [40, 22], [58, 10], [52, 30], [40, 26], [28, 30]]);   // blouse collar
  poly(c, '#cfe0f2', [[30, 18], [40, 26], [50, 18], [48, 46], [32, 46]]);
  for (let y = 30; y < 46; y += 5) circ(c, '#a8acb5', 40, y, .8);
  circ(c, '#ffd65a', 26, 38, 2); circ(c, '#c22630', 26, 38, 1);            // brooch
  rr(c, '#3a2a55', 0, 46, 22, 60, 8); rr(c, '#6a4a7a', 2, 48, 18, 54, 7);    // her arm toward us
  ell(c, '#c68a5a', 18, 104, 7, 5);
  rr(c, '#c47a1c', 14, 96, 50, 30, 6); R(c, '#7a4a10', 14, 104, 50, 1);     // crochet bag
  for (let x = 18; x < 62; x += 4) for (let y = 100; y < 124; y += 4) circ(c, '#f2a62a', x, y, 1);
  line(c, '#7a4a10', 1.5, [[26, 96], [38, 84], [50, 96]]);
  ell(c, '#e3ab7c', 52, 102, 6, 4.5);
});
function voHead(c, ox, mood) {
  const x = ox + 20, y = 22;
  ell(c, '#a8acb5', x + 4, y - 9, 14, 13);                                 // hair
  circ(c, '#a8acb5', x + 14, y - 18, 6); circ(c, '#cfe0f2', x + 13, y - 20, 2.5);   // bun
  ell(c, '#e3ab7c', x, y, 12, 13.5); ell(c, '#c68a5a', x + 8, y + 2, 4, 9);   // face, shade on the far side
  ell(c, '#a8acb5', x + 2, y - 10, 13, 5); R(c, '#e6e8ee', x - 6, y - 13, 9, 1); R(c, '#cfe0f2', x - 9, y - 9, 6, 1);
  ell(c, '#c68a5a', x + 11, y + 1, 3, 4.5); circ(c, '#e6e8ee', x + 11, y + 6, 1.3);   // ear and pearl
  ell(c, '#ff9a8a', x - 6, y + 5, 3, 1.8); ell(c, '#ff9a8a', x + 6, y + 5, 2.5, 1.6);
  R(c, '#c68a5a', x - 1, y + 1, 2, 4);                                       // nose
  // eyes behind the glasses
  const ey = y - 1;
  if (mood === 0) { R(c, '#2b1a12', x - 6, ey, 2, 2); R(c, '#2b1a12', x + 4, ey, 2, 2); R(c, '#e6e8ee', x - 6, ey, .7, .7); R(c, '#e6e8ee', x + 4, ey, .7, .7); }
  else if (mood === 1) { R(c, '#c68a5a', x - 7, ey - 1, 4, 1.5); R(c, '#c68a5a', x + 3, ey - 1, 4, 1.5); R(c, '#2b1a12', x - 6, ey + .5, 2, 1); R(c, '#2b1a12', x + 4, ey + .5, 2, 1); }
  else if (mood === 2) { line(c, '#2b1a12', .8, [[x - 7, ey + .5], [x - 5, ey + 1.5], [x - 3, ey + .5]]); line(c, '#2b1a12', .8, [[x + 3, ey + .5], [x + 5, ey + 1.5], [x + 7, ey + .5]]); }
  else { circ(c, '#e6e8ee', x - 5, ey + .5, 2.2); circ(c, '#e6e8ee', x + 5, ey + .5, 2.2); R(c, '#2b1a12', x - 5.5, ey, 1.2, 1.2); R(c, '#2b1a12', x + 4.5, ey, 1.2, 1.2); }
  // glasses
  c.strokeStyle = '#4a2d1c'; c.lineWidth = .8;
  c.beginPath(); c.ellipse(x - 5, ey + .5, 4, 3.2, 0, 0, 7); c.stroke(); c.beginPath(); c.ellipse(x + 5, ey + .5, 4, 3.2, 0, 0, 7); c.stroke();
  line(c, '#4a2d1c', .8, [[x - 1, ey], [x + 1, ey]]); line(c, '#4a2d1c', .8, [[x + 9, ey], [x + 11, ey - 1]]);
  R(c, 'rgba(230,232,238,.5)', x - 7, ey - 1.5, 1.5, .7); R(c, 'rgba(230,232,238,.5)', x + 3, ey - 1.5, 1.5, .7);
  // mouth
  if (mood === 0) line(c, '#7a1620', .8, [[x - 3, y + 7], [x, y + 8.5], [x + 3, y + 7]]);
  else if (mood === 1) R(c, '#7a1620', x - 2, y + 7.5, 4, .8);
  else if (mood === 2) ell(c, '#7a1620', x, y + 8, 1.5, 1.2);
  else ell(c, '#7a1620', x, y + 8, 2, 2.4);
  R(c, '#c68a5a', x - 9, y + 9, 2, .6); R(c, '#c68a5a', x + 7, y + 9, 2, .6);  // smile lines
}
OUT.vo_cabeca = mk(160, 44, c => { for (let i = 0; i < 4; i++) voHead(c, i * 40, i); });

// the caramelo: a vira-lata sitting on the seat, and four heads
OUT.caramelo_corpo = mk(72, 96, c => {
  ell(c, '#7a4a10', 40, 70, 30, 26);                                         // haunch
  ell(c, '#c47a1c', 38, 66, 28, 25);
  rr(c, '#c47a1c', 14, 16, 40, 66, 18);                                       // chest
  ell(c, '#f3cfa6', 32, 50, 12, 22); ell(c, '#e3ab7c', 34, 58, 8, 14);
  rr(c, '#c47a1c', 14, 60, 10, 34, 4); rr(c, '#c47a1c', 40, 60, 10, 34, 4);     // front legs
  R(c, '#f3cfa6', 14, 88, 10, 6); R(c, '#f3cfa6', 40, 88, 10, 6);
  R(c, '#7a4a10', 18, 90, .7, 4); R(c, '#7a4a10', 44, 90, .7, 4);
  rr(c, '#c22630', 18, 14, 34, 6, 2); circ(c, '#ffd65a', 35, 22, 2.5);         // collar and tag
  for (let i = 0; i < 6; i++) R(c, '#f2a62a', 20 + i * 5, 30 + (i % 2) * 4, 3, .7);
});
function dogHead(c, ox, mood) {
  const x = ox + 22, y = 20;
  // ears: up and flying when awake, down when sleepy
  if (mood === 0 || mood === 3) { poly(c, '#7a4a10', [[x - 12, y - 6], [x - 18, y - 16 - (mood === 3 ? 4 : 0)], [x - 5, y - 11]]); poly(c, '#7a4a10', [[x + 9, y - 9], [x + 17, y - 18 - (mood === 3 ? 4 : 0)], [x + 14, y - 3]]); }
  else { poly(c, '#7a4a10', [[x - 11, y - 8], [x - 16, y + 6], [x - 8, y + 2]]); poly(c, '#7a4a10', [[x + 10, y - 8], [x + 16, y + 6], [x + 8, y + 2]]); }
  ell(c, '#c47a1c', x, y - 2, 12, 11);
  ell(c, '#f2a62a', x - 3, y - 6, 6, 3);
  ell(c, '#f3cfa6', x, y + 6, 8, 6); R(c, '#f3cfa6', x - 1, y - 8, 2, 8);    // muzzle and blaze
  ell(c, '#0a0a0f', x, y + 2.5, 3, 2); R(c, '#4a4d57', x - 1, y + 1.5, 1, .7);
  const ey = y - 3;
  if (mood === 0) { circ(c, '#0a0a0f', x - 6, ey, 1.6); circ(c, '#0a0a0f', x + 6, ey, 1.6); R(c, '#e6e8ee', x - 6.5, ey - 1, .7, .7); R(c, '#e6e8ee', x + 5.5, ey - 1, .7, .7); }
  else if (mood === 1) { R(c, '#7a4a10', x - 8, ey - 1, 4, 1.5); R(c, '#7a4a10', x + 4, ey - 1, 4, 1.5); R(c, '#0a0a0f', x - 7, ey + .5, 2, 1); R(c, '#0a0a0f', x + 5, ey + .5, 2, 1); }
  else if (mood === 2) { line(c, '#4a2d1c', .8, [[x - 8, ey], [x - 6, ey + 1.2], [x - 4, ey]]); line(c, '#4a2d1c', .8, [[x + 4, ey], [x + 6, ey + 1.2], [x + 8, ey]]); }
  else { circ(c, '#e6e8ee', x - 6, ey, 2.4); circ(c, '#e6e8ee', x + 6, ey, 2.4); circ(c, '#0a0a0f', x - 6, ey, 1.2); circ(c, '#0a0a0f', x + 6, ey, 1.2); }
  if (mood === 0) { rr(c, '#ff9a8a', x - 1, y + 9, 4, 7, 2); R(c, '#f0484a', x + .5, y + 10, 1, 4); }      // tongue out
  else if (mood === 3) ell(c, '#7a1620', x, y + 10, 2.5, 2);
  else R(c, '#7a4a10', x - 3, y + 10, 6, .7);
}
OUT.caramelo_cabeca = mk(176, 40, c => { for (let i = 0; i < 4; i++) dogHead(c, i * 44, i); });

/* ================= postcards (192 x 108, sky left clear for the game to paint) ================= */
function hills(c, col, base, amp, seed) {
  c.fillStyle = col; c.beginPath(); c.moveTo(0, 108);
  for (let x = 0; x <= 192; x += 2) c.lineTo(x, base - amp * (Math.sin(x * .045 + seed) * .6 + Math.sin(x * .11 + seed * 2) * .4));
  c.lineTo(192, 108); c.closePath(); c.fill();
}
OUT.postal_terra = mk(192, 108, c => {
  hills(c, '#3f5d75', 52, 8, 1); hills(c, '#1d4030', 60, 6, 3);
  R(c, '#23743f', 0, 64, 192, 44);
  for (let y = 66; y < 108; y += 4) for (let x = (y % 8) ? 0 : 3; x < 192; x += 7) { const k = (y - 64) / 44; ell(c, '#16482c', x, y, 2 + k * 2, 1 + k); ell(c, '#3fae5a', x - .5, y - .5, 1.4 + k, .7 + k * .6); }
  poly(c, '#96643a', [[92, 62], [100, 62], [150, 108], [40, 108]]); poly(c, '#c68a5a', [[94, 62], [98, 62], [124, 108], [70, 108]]);
  line(c, '#6e4526', 1, [[95, 64], [84, 108]]); line(c, '#6e4526', 1, [[97, 64], [110, 108]]);
  // chapel on the hill
  R(c, '#e6e8ee', 140, 46, 18, 16); poly(c, '#c22630', [[138, 47], [149, 39], [160, 47]]); R(c, '#e6e8ee', 146, 32, 6, 10); poly(c, '#c22630', [[145, 33], [149, 28], [153, 33]]);
  R(c, '#3d5f94', 147, 54, 4, 8); R(c, '#4a2d1c', 148.5, 25, 1, 4); R(c, '#4a2d1c', 147.5, 26, 3, 1);
  // ipê in bloom and a fence
  R(c, '#4a2d1c', 30, 52, 3, 20); ell(c, '#ffd65a', 31, 46, 14, 9); ell(c, '#f2a62a', 34, 48, 8, 5); ell(c, '#fff3b0', 27, 43, 5, 3);
  for (let x = 0; x < 80; x += 10) { R(c, '#4a2d1c', x, 72 + x * .1, 1.5, 9); }
  line(c, '#6e4526', .8, [[0, 74], [80, 81]]); line(c, '#6e4526', .8, [[0, 78], [80, 85]]);
  ell(c, '#e6e8ee', 168, 74, 6, 3); ell(c, '#16202b', 166, 73, 2, 1.5); R(c, '#e6e8ee', 162, 75, 2, 3); R(c, '#e6e8ee', 172, 75, 2, 3);   // a cow
});
OUT.postal_br = mk(192, 108, c => {
  hills(c, '#30465a', 48, 14, 2); hills(c, '#1d4030', 60, 8, 5);
  R(c, '#10261f', 0, 62, 192, 46);
  for (let i = 0; i < 26; i++) { const x = (i * 37) % 192, y = 64 + (i * 13) % 40; poly(c, '#16482c', [[x, y - 6 - y * .05], [x + 3 + y * .03, y], [x - 3 - y * .03, y]]); }
  poly(c, '#2a2c33', [[90, 60], [102, 60], [176, 108], [16, 108]]);
  for (let k = 0; k < 6; k++) { const t0 = k / 6, t1 = t0 + .07; R(c, '#e6e8ee', 96 - .2 + (t0 * t0) * 0, 61 + t0 * t0 * 47, .6 + t0 * 1.6, (t1 * t1 - t0 * t0) * 47); }
  line(c, '#a8acb5', 1, [[103, 60], [178, 106]]); line(c, '#777b86', .6, [[103, 62], [178, 108]]);
  for (let k = 0; k < 8; k++) R(c, '#4a4d57', 110 + k * 9, 66 + k * 5.4, 1, 3 + k * .5);
  // the truck going away
  R(c, '#16202b', 106, 74, 14, 2); rr(c, '#e6e8ee', 105, 62, 16, 13, 1); R(c, '#c22630', 105, 72, 16, 1.5); R(c, '#f0484a', 106, 74, 2, 1); R(c, '#f0484a', 118, 74, 2, 1);
  // posto sign on a pole
  R(c, '#4a4d57', 40, 34, 2, 30); R(c, '#ffd65a', 32, 26, 18, 12); circ(c, '#c22630', 41, 32, 4); circ(c, '#ffd65a', 41, 32, 1.6);
  for (let i = 0; i < 5; i++) { R(c, '#4a4d57', 60 + i * 6, 56 - i * 3, 1, 8 + i); }
});
OUT.postal_expressa = mk(192, 108, c => {
  // city skyline far away
  for (let i = 0; i < 18; i++) { const x = i * 11 + (i % 3) * 2, h = 8 + (i * 7) % 18; R(c, '#24345f', x, 58 - h, 9, h); for (let w = 0; w < 4; w++) R(c, '#ffd65a', x + 2 + (w % 2) * 4, 60 - h + 2 + (w >> 1) * 4, 1, 1); }
  hills(c, '#1a2547', 60, 3, 4);
  R(c, '#22303f', 0, 60, 192, 48);
  poly(c, '#777b86', [[84, 60], [108, 60], [192, 102], [192, 108], [0, 108], [0, 102]]);
  poly(c, '#4a4d57', [[94, 60], [98, 60], [80, 108], [68, 108]]);
  for (let k = 0; k < 7; k++) { const t = k / 7; R(c, '#e6e8ee', 101 + t * t * 40, 61 + t * t * 47, .5 + t, 1 + t * 3); R(c, '#e6e8ee', 106 + t * t * 80, 61 + t * t * 47, .5 + t, 1 + t * 3); }
  // gantry
  R(c, '#a8acb5', 62, 32, 2, 34); R(c, '#a8acb5', 150, 32, 2, 34); R(c, '#777b86', 62, 32, 90, 2);
  R(c, '#23743f', 70, 34, 34, 13); R(c, '#e6e8ee', 70, 34, 34, .6); text(c, 'CENTRO', 77, 36, '#e6e8ee', .5); text(c, 'SAÍDA 12', 75, 41, '#e6e8ee', .5);
  R(c, '#23743f', 108, 34, 36, 13); R(c, '#e6e8ee', 108, 34, 36, .6); text(c, 'LITORAL', 114, 36, '#e6e8ee', .5); text(c, '84 KM', 119, 41, '#e6e8ee', .5);
  for (let k = 0; k < 5; k++) { const x = 20 + k * 40; R(c, '#a8acb5', x, 40 - k * 2, 1, 24 + k * 3); R(c, '#fff3b0', x - 3, 40 - k * 2, 5, 1.5); }
});

Object.assign(window.ART, OUT);
})();

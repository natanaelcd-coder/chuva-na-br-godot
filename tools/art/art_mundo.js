// "Mundo vivo": roadside events (boiada, carroça, romeiros, pamonha, quermesse...), sky visitors and seasonal
// decorations (ipês, festa junina, Natal). Same pixel helpers as art.js; every function draws in logical units.
(() => {
const { GL, ACC, R, poly, circ, rr, mk, ctext, lighten } = window.__H;
GL['?'] = [14, 17, 1, 2, 4, 0, 4];
GL['+'] = [0, 4, 4, 31, 4, 4, 0];
const OUT = {};
const line = (c, col, w, pts) => { c.strokeStyle = col; c.lineWidth = w; c.beginPath(); pts.forEach((p, i) => i ? c.lineTo(p[0], p[1]) : c.moveTo(p[0], p[1])); c.stroke(); };
const shadow = (c, cx, cy, rx, ry) => { c.fillStyle = 'rgba(0,0,0,.45)'; c.beginPath(); c.ellipse(cx, cy, rx, ry, 0, 0, 7); c.fill(); };
const ell = (c, col, x, y, rx, ry) => { c.fillStyle = col; c.beginPath(); c.ellipse(x, y, rx, ry, 0, 0, 7); c.fill(); };
let seed = 7; const rnd = () => (seed = (seed * 16807) % 2147483647) / 2147483647;   // same art on every build
const FLAGS = ['#e8434a', '#ffd65a', '#3fae5a', '#4aa8e8', '#f2a62a', '#e6e8ee', '#c45ad6'];

/* ---------------- boiada: nelore cattle seen from behind, and the peão on his horse ---------------- */
function cowBack(c, x, y, s, body, shade) {
  R(c, '#2a2c33', x - 4 * s, y + 6 * s, 2 * s, 5 * s); R(c, '#2a2c33', x + 2 * s, y + 6 * s, 2 * s, 5 * s);   // hind legs
  ell(c, body, x, y, 6.5 * s, 6 * s);                                              // rump
  ell(c, lighten(body, .25), x - 1.5 * s, y - 3 * s, 3 * s, 2 * s);
  ell(c, body, x + 1 * s, y - 6.5 * s, 3.2 * s, 2.6 * s);                          // the hump
  R(c, shade, x - .4 * s, y - 4 * s, .8 * s, 9 * s);                              // spine and tail
  R(c, '#2a2c33', x - .6 * s, y + 4.5 * s, 1.2 * s, 2 * s);
  R(c, shade, x - 6 * s, y + 1 * s, 1 * s, 3 * s); R(c, shade, x + 5 * s, y + 1 * s, 1 * s, 3 * s);
  R(c, '#e6e8ee', x - 7.5 * s, y - 7 * s, 1.5 * s, 2 * s); R(c, '#e6e8ee', x + 6 * s, y - 7 * s, 1.5 * s, 2 * s);   // horn tips over the back
}
function herd(cols, seedv) {
  return mk(48, 30, c => {
    seed = seedv;
    shadow(c, 24, 28.5, 23, 1.5);
    const spots = [[10, 12, .85], [24, 10, .8], [38, 12, .85], [17, 19, 1], [32, 19, 1]];
    spots.forEach((p, i) => { const col = cols[i % cols.length]; cowBack(c, p[0] + (rnd() - .5) * 2, p[1], p[2], col, '#a8acb5'); });
    // dust kicked up by the hooves
    c.fillStyle = 'rgba(200,170,130,.35)'; for (let i = 0; i < 8; i++) { c.beginPath(); c.arc(4 + rnd() * 40, 27 + rnd() * 2, 1.5 + rnd() * 2, 0, 7); c.fill(); }
  });
}
OUT.boiada0 = herd(['#e6e8ee', '#cfd2d8', '#e6e8ee', '#d8d4cc', '#e6e8ee'], 11);
OUT.boiada1 = herd(['#cfd2d8', '#96643a', '#e6e8ee', '#e6e8ee', '#6e4526'], 23);
function horseBack(c, x, y, coat) {
  R(c, '#2b1a12', x - 4, y + 6, 2, 11); R(c, '#2b1a12', x + 2, y + 6, 2, 11);
  ell(c, coat, x, y + 2, 6, 7); ell(c, lighten(coat, .2), x - 2, y - 1, 2.5, 3);
  R(c, '#16202b', x - .7, y, 1.4, 12);                                                // tail
  rr(c, coat, x - 2, y - 14, 4, 9, 2); R(c, '#16202b', x - 1.5, y - 15, 1, 6); R(c, coat, x - 2.5, y - 16, 1.5, 2.5); R(c, coat, x + 1, y - 16, 1.5, 2.5);   // neck and ears ahead
}
OUT.peao = mk(48, 48, c => {
  shadow(c, 24, 46.5, 10, 1.5);
  horseBack(c, 24, 28, '#7a4a10');
  R(c, '#4a2d1c', 17, 25, 14, 3);                                                     // saddle blanket
  rr(c, '#3d5f94', 20, 13, 8, 12, 2); R(c, '#24345f', 20, 22, 8, 3);                 // rider, blue shirt
  R(c, '#3d5f94', 18, 15, 2, 7); R(c, '#3d5f94', 28, 15, 2, 7); circ(c, '#e3ab7c', 18.5, 22, 1); circ(c, '#e3ab7c', 29.5, 22, 1);
  R(c, '#2a2c33', 18, 25, 3, 6); R(c, '#2a2c33', 27, 25, 3, 6);                      // boots in the stirrups
  circ(c, '#c68a5a', 24, 10, 2.6);
  ell(c, '#c47a1c', 24, 8.5, 7, 1.6); rr(c, '#f2a62a', 21, 4.5, 6, 4.5, 1.5); R(c, '#7a1620', 21, 7.5, 6, .8);   // straw hat
  line(c, '#e3ab7c', .6, [[30, 20], [36, 12], [40, 14]]);                             // the lasso arm
  c.strokeStyle = '#c68a5a'; c.lineWidth = .6; c.beginPath(); c.ellipse(41, 11, 4, 2.5, .3, 0, 7); c.stroke();
});

/* ---------------- carroça, ciclista, romeiros ---------------- */
OUT.carroca = mk(48, 44, c => {
  shadow(c, 24, 42.5, 20, 1.5);
  rr(c, '#e6e8ee', 18, 2, 12, 10, 2); circ(c, '#7a4a10', 24, 4, 2.5); R(c, '#16202b', 23.5, 1, 1, 4);   // the horse's head ahead, over the load
  [6, 42].forEach(x => { circ(c, '#2b1a12', x, 32, 9); circ(c, '#96643a', x, 32, 7.5); circ(c, '#2b1a12', x, 32, 1.5);
    for (let a = 0; a < 6; a++) line(c, '#2b1a12', .8, [[x, 32], [x + Math.cos(a) * 7.5, 32 + Math.sin(a) * 7.5]]); });
  R(c, '#96643a', 8, 14, 32, 18); R(c, '#c68a5a', 8, 14, 32, 1.5); for (let x = 10; x < 40; x += 5) R(c, '#6e4526', x, 15.5, .7, 16);
  R(c, '#6e4526', 8, 30, 32, 2);
  rr(c, '#8fe07a', 11, 8, 10, 7, 2); rr(c, '#ffd65a', 21, 9, 8, 6, 2); rr(c, '#3fae5a', 28, 8, 9, 7, 2);   // load of greens and corn
  rr(c, '#c22630', 30, 4, 6, 7, 1.5); circ(c, '#c68a5a', 33, 2.5, 2); ell(c, '#f2a62a', 33, 1.5, 4, 1); // the carter, sitting high
  R(c, '#f2a62a', 9, 26, 3, 3); R(c, '#f2a62a', 36, 26, 3, 3);                       // reflectors
  ctext(c, 'DEVAGAR', 24, 20, '#e6e8ee', .5);
});
OUT.ciclista = mk(48, 40, c => {
  shadow(c, 24, 38.5, 6, 1);
  R(c, '#0a0a0f', 23, 24, 2, 14); R(c, '#2a2c33', 23.5, 25, 1, 12);                  // rear wheel edge-on
  R(c, '#a8acb5', 21, 21, 6, 1.5); R(c, '#c22630', 22.5, 26, 3, 2); R(c, '#ff9a8a', 23, 26.5, 2, .8);   // rack and red reflector
  R(c, '#24345f', 20, 18, 3, 9); R(c, '#24345f', 25, 16, 3, 8); R(c, '#16202b', 20, 26, 3, 2); R(c, '#16202b', 25, 23, 3, 2);   // legs pedalling
  rr(c, '#ffd65a', 19, 7, 10, 11, 2); R(c, '#f2a62a', 19, 15, 10, 2);              // yellow jersey
  R(c, '#ffd65a', 17, 9, 2, 6); R(c, '#ffd65a', 29, 9, 2, 6); R(c, '#a8acb5', 15, 14, 18, 1);   // arms to the bars
  circ(c, '#c68a5a', 24, 5, 2.6); rr(c, '#e6e8ee', 21, 1, 6, 3.5, 1.5); R(c, '#c22630', 21, 3, 6, .8);   // helmet
});
OUT.romeiros = mk(48, 36, c => {
  shadow(c, 24, 34.5, 22, 1.5);
  const walker = (x, y, shirt, hat, staff) => {
    R(c, '#2a2c33', x - 2, y + 9, 1.6, 8); R(c, '#2a2c33', x + .5, y + 9, 1.6, 8);
    rr(c, shirt, x - 3.5, y, 7, 10, 1.5); R(c, '#96643a', x - 3, y + 1, 6, 6);   // backpack
    circ(c, '#c68a5a', x, y - 2, 2.2); ell(c, hat, x, y - 3, 4, 1); rr(c, hat, x - 2, y - 6, 4, 3, 1);
    if (staff) line(c, '#6e4526', .8, [[x + 4, y + 17], [x + 5, y - 4]]);
  };
  walker(8, 15, '#e6e8ee', '#f2a62a', true); walker(22, 13, '#4aa8e8', '#e6e8ee', false); walker(37, 15, '#c22630', '#f2a62a', true);
  rr(c, '#e6e8ee', 26, 2, 12, 7, 1); ctext(c, 'FÉ', 32, 3, '#c22630', .5);      // a little banner of the saint
  line(c, '#6e4526', .8, [[26, 2], [25, 22]]);
});

/* ---------------- the old van with loudspeakers: pamonha and quermesse ---------------- */
function kombi(top, bottom, l1, l2, ink) {
  return mk(48, 46, c => {
    shadow(c, 24, 43, 22, 2.5);
    rr(c, '#0a0a0f', 5, 36, 8, 8, 1.5); rr(c, '#0a0a0f', 35, 36, 8, 8, 1.5);
    [[10, 2], [32, 2]].forEach(([x, y]) => { poly(c, '#a8acb5', [[x, y + 6], [x + 6, y + 6], [x + 8, y], [x - 2, y]]); R(c, '#4a4d57', x, y + 6, 6, 1); });   // horn loudspeakers
    R(c, '#4a4d57', 6, 8, 36, 1.5);                                                    // roof rack
    rr(c, top, 3, 9, 42, 16, 6); rr(c, bottom, 3, 21, 42, 16, 3); R(c, top, 3, 21, 42, 2);
    rr(c, '#121a33', 8, 12, 32, 8, 2); R(c, '#24345f', 10, 13, 10, .7); R(c, '#05070c', 23.5, 12, 1, 8);
    for (let x = 14; x < 34; x += 2) R(c, '#2a2c33', x, 32.5, 1, 2.5);   // engine grille
    rr(c, '#c22630', 5, 27, 4, 5, 1); rr(c, '#c22630', 39, 27, 4, 5, 1); R(c, '#f0484a', 5.5, 27.5, 3, 2); R(c, '#f0484a', 39.5, 27.5, 3, 2);
    ctext(c, l1, 24, 22.5, ink, .7); if (l2) ctext(c, l2, 24, 28, ink, .45);
    rr(c, '#777b86', 2, 36, 44, 2.5, 1); R(c, '#e6e8ee', 19, 32.5, 10, 3); R(c, '#4a4d57', 20, 33.5, 8, .5);
  });
}
OUT.kombi_pamonha = kombi('#e6e8ee', '#3fae5a', 'PAMONHA', 'CURAU MILHO', '#ffd65a');
OUT.kombi_som = kombi('#e6e8ee', '#3d5f94', 'QUERMESSE', 'HOJE NA MATRIZ', '#e6e8ee');

/* ---------------- roadside, standing still ---------------- */
OUT.barraca_pamonha = mk(80, 48, c => {
  shadow(c, 40, 46.5, 38, 1.5);
  [6, 72].forEach(x => R(c, '#6e4526', x, 12, 2, 34));
  poly(c, '#c47a1c', [[0, 14], [8, 4], [72, 4], [80, 14]]); for (let x = 2; x < 80; x += 3) R(c, '#7a4a10', x, 6 + Math.abs(40 - x) * .05, .7, 8);   // straw roof
  R(c, '#96643a', 4, 30, 72, 4); R(c, '#6e4526', 6, 34, 2, 12); R(c, '#6e4526', 72, 34, 2, 12);   // table
  for (let i = 0; i < 9; i++) { rr(c, '#8fe07a', 10 + i * 4.5, 24 + (i % 2), 4, 7, 1.5); R(c, '#3fae5a', 11 + i * 4.5, 25 + (i % 2), 1, 5); }   // pamonhas in husk
  for (let i = 0; i < 6; i++) { rr(c, '#ffd65a', 52 + i * 3.5, 22 + (i % 2) * 2, 3, 8, 1.5); R(c, '#3fae5a', 52 + i * 3.5, 28 + (i % 2) * 2, 3, 2); }   // corn cobs
  rr(c, '#c22630', 34, 13, 8, 10, 2); circ(c, '#c68a5a', 38, 11, 2.4); ell(c, '#f2a62a', 38, 9.5, 4, 1);   // the vendor
  rr(c, '#e6e8ee', 22, 36, 36, 10, 1); ctext(c, 'PAMONHA', 40, 37, '#16482c', .6); ctext(c, 'MILHO VERDE', 40, 41.5, '#c22630', .5);
});
function flagString(c, x0, y0, x1, y1, sag, n, sz) {
  for (let i = 0; i <= n; i++) {
    const u = i / n, x = x0 + (x1 - x0) * u, y = y0 + (y1 - y0) * u + Math.sin(u * Math.PI) * sag;
    if (i < n) poly(c, FLAGS[(i + Math.round(x0)) % FLAGS.length], [[x - sz * .5, y], [x + sz * .5, y], [x, y + sz * 1.2]]);
  }
  line(c, '#2a2c33', .4, Array.from({ length: 9 }, (_, i) => { const u = i / 8; return [x0 + (x1 - x0) * u, y0 + (y1 - y0) * u + Math.sin(u * Math.PI) * sag]; }));
}
OUT.quermesse = mk(128, 64, c => {
  shadow(c, 64, 62.5, 62, 1.5);
  R(c, '#6e4526', 4, 6, 2, 56); R(c, '#6e4526', 122, 6, 2, 56); R(c, '#6e4526', 63, 2, 2, 20);
  flagString(c, 5, 7, 64, 3, 7, 12, 3); flagString(c, 64, 3, 123, 7, 7, 12, 3); flagString(c, 5, 14, 123, 14, 10, 24, 3);
  const stall = (x, roof, l) => {
    poly(c, roof, [[x - 2, 34], [x + 4, 28], [x + 30, 28], [x + 36, 34]]); for (let i = 0; i < 6; i++) R(c, i % 2 ? '#e6e8ee' : roof, x - 2 + i * 6.4, 34, 6.4, 2);
    R(c, '#96643a', x, 36, 34, 24); R(c, '#c68a5a', x, 36, 34, 1); R(c, '#e6e8ee', x + 3, 40, 28, 7); ctext(c, l, x + 17, 41.5, '#c22630', .6);
    R(c, '#2b1a12', x + 2, 49, 30, 10); R(c, '#ffd65a', x + 4, 50, 26, 6);
  };
  stall(10, '#c22630', 'QUENTÃO'); stall(47, '#3d5f94', 'PASTEL'); stall(84, '#16482c', 'PESCARIA');
  rr(c, '#ffd65a', 40, 18, 48, 9, 1); ctext(c, 'QUERMESSE', 64, 19.5, '#7a1620', .9);
  R(c, '#2a2c33', 0, 60, 128, 4);
});
OUT.caramelo = mk(24, 22, c => {   // sitting by the road, watching it go by
  shadow(c, 12, 21, 9, 1);
  ell(c, '#c47a1c', 12, 15, 6, 5.5); ell(c, '#f2a62a', 11, 14, 4, 4); R(c, '#f2a62a', 7, 15, 2, 6); R(c, '#f2a62a', 13, 15, 2, 6);
  R(c, '#fff3b0', 10, 12, 3, 5);                                                      // pale chest
  rr(c, '#f2a62a', 8, 3, 9, 8, 3); R(c, '#c47a1c', 7, 2, 3, 5); R(c, '#c47a1c', 15, 2, 3, 5);   // head and ears
  R(c, '#0a0a0f', 10, 6, 1, 1); R(c, '#0a0a0f', 14, 6, 1, 1); rr(c, '#fff3b0', 11, 7.5, 3, 2.5, 1); R(c, '#0a0a0f', 12, 8, 1.2, .8);
  line(c, '#c47a1c', 1.5, [[18, 19], [21, 17], [22, 13]]);                              // tail
  R(c, '#c22630', 9, 10.5, 7, 1);                                                     // collar
});
OUT.cavalo = mk(56, 40, c => {   // loose horse grazing on the verge, side view
  shadow(c, 28, 38.5, 22, 1.5);
  [12, 17, 36, 41].forEach(x => { R(c, '#4a2d1c', x, 24, 3, 13); R(c, '#16202b', x, 36, 3, 1.5); });
  ell(c, '#7a4a10', 27, 20, 16, 7); ell(c, '#96643a', 25, 17, 11, 3);
  poly(c, '#7a4a10', [[40, 16], [46, 16], [54, 31], [50, 33]]); rr(c, '#7a4a10', 47, 29, 8, 5, 2);   // neck down to the grass
  line(c, '#16202b', 2, [[42, 14], [50, 26]]);                                       // mane
  line(c, '#16202b', 2, [[11, 17], [7, 24], [8, 31]]);                                // tail
  R(c, '#e6e8ee', 52, 30, 1.5, 1.5);
  for (let i = 0; i < 6; i++) R(c, '#3fae5a', 46 + i * 1.6, 34 + (i % 2), .7, 3);
});
OUT.borracharia = mk(96, 56, c => {
  shadow(c, 48, 54.5, 46, 1.5);
  poly(c, '#777b86', [[0, 18], [96, 12], [96, 16], [0, 22]]);                         // tin roof
  R(c, '#e3ab7c', 4, 20, 88, 34); R(c, '#c68a5a', 4, 20, 88, 1);
  R(c, '#2b1a12', 50, 30, 30, 24); R(c, '#ffd65a', 52, 32, 26, 6);
  rr(c, '#e6e8ee', 6, 24, 42, 22, 1);                                                // hand-painted sign
  ctext(c, 'BORRA-', 27, 25.5, '#c22630', .8); ctext(c, 'CHARIA', 27, 32, '#c22630', .8); ctext(c, '24 H', 27, 39, '#16202b', .8);
  const tyre = (x, y) => { ell(c, '#0a0a0f', x, y, 7, 3); ell(c, '#2a2c33', x, y - .5, 4, 1.5); };
  for (let i = 0; i < 4; i++) tyre(88, 52 - i * 4);
  for (let i = 0; i < 3; i++) tyre(42 + i * 2, 52 - i * 4);
  circ(c, '#0a0a0f', 14, 49, 5); circ(c, '#2a2c33', 14, 49, 2.5);                    // a tyre leaning on the wall
  R(c, '#c22630', 82, 0, 2, 14); rr(c, '#ffd65a', 74, 0, 18, 6, 1); ctext(c, 'ABERTO', 83, 1.2, '#16202b', .45);
});
function ledFun(bg, fg, l1, l2) {
  return mk(80, 58, c => {
    R(c, '#4a4d57', 37, 36, 6, 22); R(c, '#777b86', 37, 36, 1.5, 22);
    R(c, '#0a0a0f', 0, 0, 80, 38); R(c, bg, 3, 3, 74, 32);
    for (let y = 3; y < 35; y += 1.5) R(c, 'rgba(0,0,0,.25)', 3, y, 74, .5);
    ctext(c, l1, 40, 8, fg, .8); ctext(c, l2, 40, 21, fg, .8);
  });
}
[['BEBEU?', 'CHAME UM AMIGO'], ['SEM PRESSA', 'A VIDA AGRADECE'], ['CHUVA?', 'FAROL BAIXO'],
 ['MANDE UM', 'OI PRA MÃE'], ['CAFÉ', 'NA PRÓXIMA'], ['SORRIA', 'VOCÊ ESTÁ NA BR']].forEach((m, i) =>
  OUT['led_fun' + i] = ledFun(['#24345f', '#3a0d12', '#0c2a1c'][i % 3], ['#3fe0e8', '#ffd65a', '#8fe07a'][i % 3], m[0], m[1]));

/* ---------------- in the sky ---------------- */
OUT.balao = mk(24, 34, c => {   // a festive hot-air balloon, far away
  const cols = ['#e8434a', '#ffd65a', '#4aa8e8', '#3fae5a', '#f2a62a'];
  c.save(); c.beginPath(); c.ellipse(12, 12, 11, 12, 0, 0, 7); c.clip();
  for (let i = 0; i < 6; i++) R(c, cols[i % cols.length], i * 4, 0, 4, 26);
  R(c, 'rgba(255,255,255,.25)', 0, 0, 24, 6); c.restore();
  poly(c, '#e8434a', [[4, 19], [20, 19], [15, 25], [9, 25]]);
  line(c, '#4a2d1c', .5, [[9, 25], [10, 29]]); line(c, '#4a2d1c', .5, [[15, 25], [14, 29]]);
  R(c, '#96643a', 9, 29, 6, 4); R(c, '#6e4526', 9, 29, 6, 1);
});
OUT.helicoptero = mk(40, 18, c => {
  R(c, '#2a2c33', 2, 1, 36, 1);                                                      // rotor blur
  R(c, '#4a4d57', 19, 2, 2, 3);
  rr(c, '#e6e8ee', 10, 4, 18, 9, 4); rr(c, '#4aa8e8', 21, 5, 6, 5, 2); R(c, '#c22630', 10, 9, 18, 1.5);
  R(c, '#e6e8ee', 0, 6, 12, 2); R(c, '#c22630', 0, 3, 2, 5);                          // tail boom
  R(c, '#4a4d57', 12, 15, 16, 1); R(c, '#4a4d57', 14, 13, 1, 2); R(c, '#4a4d57', 24, 13, 1, 2);   // skids
  ctext(c, 'TV', 15, 5.5, '#c22630', .45);
});

/* ---------------- seasons ---------------- */
function ipe(light, mid, dark, seedv) {
  return mk(48, 64, c => {
    seed = seedv;
    R(c, '#4a2d1c', 22, 32, 4, 32); line(c, '#4a2d1c', 2, [[24, 38], [14, 26]]); line(c, '#4a2d1c', 2, [[24, 36], [34, 24]]);
    const bl = [[24, 20, 13], [12, 24, 8], [36, 24, 8], [24, 9, 8]];
    bl.forEach(b => circ(c, dark, b[0], b[1], b[2]));
    for (let i = 0; i < 190; i++) { const b = bl[i % 4], a = rnd() * 6.28, d = Math.sqrt(rnd()) * b[2], up = Math.sin(a) < 0; circ(c, up ? (rnd() < .5 ? mid : light) : dark, b[0] + Math.cos(a) * d, b[1] + Math.sin(a) * d, .5 + rnd() * .9); }
    for (let i = 0; i < 14; i++) circ(c, rnd() < .5 ? mid : light, 6 + rnd() * 36, 60 + rnd() * 3, .6);   // fallen flowers on the ground
  });
}
OUT.ipe_amarelo = ipe('#fff3b0', '#ffd65a', '#d89a1c', 3);
OUT.ipe_roxo = ipe('#f0b8f0', '#d070c8', '#8a3a8a', 5);
OUT.ipe_branco = ipe('#ffffff', '#f2eef2', '#c8bccc', 9);
OUT.ipe_rosa = ipe('#ffd0e0', '#f08cb0', '#b84a7a', 13);
OUT.bandeirinhas = mk(240, 60, c => {   // strung across the road between two bamboo poles
  [14, 224].forEach(x => { R(c, '#c68a5a', x, 0, 3, 60); R(c, '#96643a', x + 2, 0, 1, 60); for (let y = 6; y < 60; y += 9) R(c, '#96643a', x, y, 3, .7); });
  flagString(c, 15, 4, 226, 4, 12, 36, 4.5);
  flagString(c, 15, 12, 226, 12, 16, 40, 4);
  flagString(c, 15, 4, 120, 22, 4, 18, 3.5); flagString(c, 120, 22, 226, 4, 4, 18, 3.5);
});
OUT.fogueira = mk(32, 32, c => {
  shadow(c, 16, 30.5, 14, 1.5);
  line(c, '#4a2d1c', 3, [[4, 30], [24, 14]]); line(c, '#6e4526', 3, [[28, 30], [8, 14]]); line(c, '#4a2d1c', 3, [[16, 31], [16, 12]]);
  poly(c, '#c22630', [[6, 29], [10, 14], [13, 20], [16, 4], [19, 18], [22, 12], [26, 29]]);
  poly(c, '#f2a62a', [[9, 29], [12, 18], [14, 22], [16, 10], [18, 22], [21, 17], [23, 29]]);
  poly(c, '#ffd65a', [[12, 29], [14, 22], [16, 16], [18, 23], [20, 29]]);
  for (let i = 0; i < 6; i++) R(c, '#ffd65a', 6 + i * 4, 4 + (i * 7) % 9, .7, .7);   // sparks
  for (let i = 0; i < 5; i++) ell(c, '#2a2c33', 5 + i * 5.5, 30.5, 2.5, 1.2);          // stones around it
});
OUT.arvore_natal = mk(32, 48, c => {
  shadow(c, 16, 46.5, 12, 1.5);
  R(c, '#6e4526', 14, 38, 4, 8); R(c, '#c22630', 10, 42, 12, 5);
  [[16, 6, 6, 14], [16, 14, 9, 24], [16, 24, 13, 38]].forEach(([x, y0, hw, y1]) => poly(c, '#16482c', [[x, y0], [x + hw, y1], [x - hw, y1]]));
  [[16, 10, 3, 14], [16, 18, 6, 24], [16, 28, 9, 38]].forEach(([x, y0, hw, y1]) => poly(c, '#23743f', [[x, y0], [x + hw * .6, y1 - 2], [x - hw, y1]]));
  for (let i = 0; i < 16; i++) circ(c, FLAGS[i % FLAGS.length], 6 + (i * 37 % 20), 14 + (i * 53 % 23), .9);
  poly(c, '#ffd65a', [[16, 0], [17.5, 4], [21, 4], [18, 6.5], [19, 10], [16, 8], [13, 10], [14, 6.5], [11, 4], [14.5, 4]]);
});

Object.assign(window.ART, OUT);
})();

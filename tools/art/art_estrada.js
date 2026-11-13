// Art for the "Estrada" features: blank distance signs (the game writes city names and km on them),
// a small town the road runs through (houses, church, bar, bus stop, phone, people, bunting), and the
// speed-bump signs. Runs after art.js inside tools/art/build_art.js; logical units, mk() doubles them.
(() => {
const { R, poly, circ, rr, mk, ctext, text, lighten } = window.__H;
const OUT = {};
const line = (c, col, w, pts) => { c.strokeStyle = col; c.lineWidth = w; c.beginPath(); pts.forEach((p, i) => i ? c.lineTo(p[0], p[1]) : c.moveTo(p[0], p[1])); c.stroke(); };
const shadow = (c, cx, cy, rx, ry) => { c.fillStyle = 'rgba(0,0,0,.5)'; c.beginPath(); c.ellipse(cx, cy, rx, ry, 0, 0, 7); c.fill(); };

/* ---------- blank signs: panel on top (2 or 3 text rows of 10 units), two posts at 14% and 82% ---------- */
// The game writes on them with the same 5x7 font at 1 unit per dot, rows starting at y = 5 + 10 * row.
function blankSign(w, rows, bg, rim, hi) {
  return mk(w, 64, c => {
    const h = rows * 10 + 6, p1 = Math.round(w * .14), p2 = Math.round(w * .82);
    [p1, p2].forEach(x => { R(c, '#4a4d57', x, h - 2, 3, 66 - h); R(c, '#777b86', x, h - 2, .5, 66 - h); });
    rr(c, '#e6e8ee', 0, 0, w, h, 2); rr(c, bg, 1, 1, w - 2, h - 2, 1.5);
    if (hi) R(c, hi, 2, 1.5, w - 4, .5);
    if (rim) { R(c, rim, 2, h - 2.5, w - 4, .5); }
  });
}
OUT.placa_km_verde = blankSign(128, 2, '#16482c', '#0c2a1c', '#23743f');
OUT.placa_km_marrom = blankSign(128, 2, '#6e4526', '#4a2d1c', '#96643a');
// "welcome" sign at the edge of town: blue municipal panel, the town's name goes on the second row
OUT.placa_cidade = mk(128, 64, c => {
  const h = 36, p1 = 18, p2 = 105;
  [p1, p2].forEach(x => { R(c, '#4a4d57', x, h - 2, 3, 66 - h); R(c, '#777b86', x, h - 2, .5, 66 - h); });
  rr(c, '#e6e8ee', 0, 0, 128, h, 2); rr(c, '#24345f', 1, 1, 126, h - 2, 1.5); R(c, '#3d5f94', 2, 1.5, 124, .5);
  ctext(c, 'BEM-VINDOS A', 64, 4, '#ffd65a', .5);
  R(c, '#ffd65a', 30, 29, 68, .5);
  ctext(c, 'DIRIJA COM CUIDADO', 64, 30.5, '#cfe0f2', .5);
});
OUT.placa_volte = mk(72, 64, c => {
  R(c, '#4a4d57', 10, 22, 3, 42); R(c, '#4a4d57', 59, 22, 3, 42);
  rr(c, '#e6e8ee', 0, 0, 72, 26, 2); rr(c, '#24345f', 1, 1, 70, 24, 1.5);
  ctext(c, 'VOLTE', 36, 5, '#e6e8ee', 1); ctext(c, 'SEMPRE', 36, 15, '#e6e8ee', 1);
});
// overhead gantry with blank panels (expressway): the game writes the next town and its exit
OUT.portico_branco = mk(240, 90, c => {
  [6, 228].forEach(x => { R(c, '#777b86', x, 18, 6, 72); R(c, '#a8acb5', x, 18, 1.5, 72); R(c, '#4a4d57', x - 2, 86, 10, 4); });
  R(c, '#777b86', 6, 14, 228, 4); R(c, '#777b86', 6, 30, 228, 2);
  for (let x = 10; x < 230; x += 8) line(c, '#4a4d57', .7, [[x, 18], [x + 8, 30]]);
  rr(c, '#e6e8ee', 16, 0, 112, 30, 2); rr(c, '#16482c', 17, 1, 110, 28, 1.5);
  rr(c, '#e6e8ee', 134, 0, 100, 30, 2); rr(c, '#16482c', 135, 1, 98, 28, 1.5);
  const ax = 220; line(c, '#e6e8ee', 2, [[ax, 22], [ax + 8, 10]]); poly(c, '#e6e8ee', [[ax + 10, 7], [ax + 9, 14], [ax + 4, 10]]);
});

/* ---------- speed bump signs ---------- */
OUT.placa_lombada = mk(36, 48, c => {   // yellow diamond: a hump on the road
  R(c, '#4a4d57', 16.5, 22, 3, 26);
  poly(c, '#2a2c33', [[18, 0], [36, 18], [18, 36], [0, 18]]); poly(c, '#ffd65a', [[18, 2], [34, 18], [18, 34], [2, 18]]);
  R(c, '#2a2c33', 7, 22, 22, 2); c.fillStyle = '#2a2c33'; c.beginPath(); c.ellipse(18, 22, 7, 5, 0, Math.PI, 0); c.fill();
});
OUT.placa_reduza = mk(56, 72, c => {   // REDUZA 40, LOMBADA: white plate with the red ring
  R(c, '#4a4d57', 26.5, 40, 3, 32);
  rr(c, '#e6e8ee', 0, 0, 56, 42, 2); rr(c, '#2a2c33', 1, 1, 54, 40, 1.5); rr(c, '#e6e8ee', 2, 2, 52, 38, 1);
  ctext(c, 'REDUZA', 28, 4, '#0a0a0f', .8);
  circ(c, '#c22630', 28, 21, 9); circ(c, '#e6e8ee', 28, 21, 6.5); ctext(c, '40', 28, 18, '#0a0a0f', .9);
  ctext(c, 'LOMBADA', 28, 33, '#0a0a0f', .8);
});

/* ---------- the little town ---------- */
// row houses with a parapet front, the small-town kind: one colour each, door, window, maybe a shop name
function casa(wall, trim, door, shop, shopCol) {
  return mk(64, 48, c => {
    shadow(c, 32, 46.5, 31, 1.5);
    R(c, wall, 2, 8, 60, 38); R(c, lighten(wall, .25), 2, 8, 60, 1); R(c, trim, 2, 4, 60, 4); R(c, lighten(trim, .3), 2, 4, 60, .5);
    R(c, trim, 2, 42, 60, 4);                                                          // skirting
    if (shop) {
      R(c, '#e6e8ee', 6, 11, 52, 9); ctext(c, shop, 32, 12, shopCol, 1);
      R(c, '#2b1a12', 8, 23, 22, 19); R(c, '#ffd65a', 9.5, 24.5, 19, 17); R(c, '#2b1a12', 18.75, 24.5, .5, 17);   // open shop door, lit inside
      R(c, '#3d5f94', 36, 24, 20, 12); R(c, '#cfe0f2', 37, 25, 18, 10); R(c, '#3d5f94', 45.75, 25, .5, 10);
      R(c, '#c22630', 34, 21, 24, 2); for (let x = 34; x < 58; x += 4) R(c, '#e6e8ee', x, 21, 2, 2);   // awning
    } else {
      R(c, door, 10, 22, 12, 20); R(c, lighten(door, .2), 11, 23, 4, 18); circ(c, '#ffd65a', 20, 32, .7);
      [[30, 18], [46, 18]].forEach(([x, y]) => { R(c, trim, x - 1, y - 1, 14, 14); R(c, '#3d5f94', x, y, 12, 12); R(c, '#ffd65a', x + 1, y + 1, 10, 10); R(c, door, x + 5.75, y + 1, .5, 10); R(c, door, x, y + 6, 12, 1.5); });
      R(c, trim, 28, 31, 32, 1);
    }
  });
}
OUT.casa_vila0 = casa('#e3ab7c', '#c47a1c', '#3d5f94', 'PADARIA', '#c22630');
OUT.casa_vila1 = casa('#8fb8d8', '#3d5f94', '#7a1620', null);
OUT.casa_vila2 = casa('#f2d08a', '#c22630', '#16482c', 'FARMÁCIA', '#16482c');
OUT.casa_vila3 = casa('#b8d8a8', '#23743f', '#96643a', null);
OUT.casa_vila4 = casa('#e8b8c8', '#a84a6a', '#3d5f94', 'ARMARINHO', '#3d5f94');
OUT.igreja = mk(80, 100, c => {   // the town church: white front, two blue towers with bells
  shadow(c, 40, 98, 38, 2);
  [[10, 26], [56, 26]].forEach(([x, y]) => {
    R(c, '#e6e8ee', x, y, 14, 72); R(c, '#cfe0f2', x, y, 14, 1); poly(c, '#3d5f94', [[x - 1, y + 1], [x + 7, y - 14], [x + 15, y + 1]]);
    R(c, '#ffd65a', x + 6.5, y - 20, 1, 7); R(c, '#ffd65a', x + 4.5, y - 18, 5, 1);
    rr(c, '#2b1a12', x + 4, y + 8, 6, 9, 3); circ(c, '#ffd65a', x + 7, y + 14, 1.8);
  });
  R(c, '#e6e8ee', 24, 40, 32, 58); poly(c, '#e6e8ee', [[22, 42], [40, 24], [58, 42]]); R(c, '#cfe0f2', 24, 40, 32, 1);
  line(c, '#3d5f94', 1.5, [[22, 42], [40, 24], [58, 42]]);
  circ(c, '#3d5f94', 40, 36, 4); circ(c, '#ffd65a', 40, 36, 2.6); R(c, '#3d5f94', 39.5, 33, 1, 6); R(c, '#3d5f94', 37, 35.5, 6, 1);
  rr(c, '#7a4a10', 33, 70, 14, 28, 7); R(c, '#4a2d1c', 39.75, 72, .5, 26);
  [[28, 50], [46, 50]].forEach(([x, y]) => { rr(c, '#3d5f94', x, y, 6, 12, 3); R(c, '#8ec5ff', x + 1, y + 2, 4, 9); });
  R(c, '#a8acb5', 6, 94, 68, 4); R(c, '#777b86', 30, 96, 20, 2);                     // steps
});
OUT.bar = mk(80, 48, c => {   // corner bar: half door, crates, plastic table and chairs
  shadow(c, 40, 46.5, 39, 1.5);
  R(c, '#d8e8c8', 2, 8, 76, 38); R(c, '#23743f', 2, 4, 76, 4); R(c, '#23743f', 2, 38, 76, 8);
  R(c, '#ffd65a', 8, 9, 64, 9); ctext(c, 'BAR DO TIÃO', 40, 10, '#7a1620', 1);
  R(c, '#2b1a12', 8, 21, 30, 17); R(c, '#ffd65a', 9.5, 22.5, 27, 14); R(c, '#c47a1c', 9.5, 30, 27, 6.5);   // counter
  for (let x = 11; x < 36; x += 4) { R(c, '#7a4a10', x, 23, 2, 5); R(c, '#e6e8ee', x + .5, 23, 1, 1); }
  R(c, '#2b1a12', 44, 21, 26, 17); R(c, '#ffd65a', 45.5, 22.5, 23, 15);
  [[44, 40], [54, 40]].forEach(([x, y]) => { R(c, '#c22630', x, y, 8, 6); R(c, '#f0484a', x, y, 8, 1); });   // beer crates
  R(c, '#e6e8ee', 62, 36, 14, 2); R(c, '#cfe0f2', 68.5, 38, 1, 8); R(c, '#e6e8ee', 60, 40, 3, 6); R(c, '#e6e8ee', 75, 40, 3, 6);   // table, chairs
  R(c, '#ffd65a', 65, 33, 2, 3); R(c, '#e6e8ee', 65, 33, 2, .7);
});
OUT.ponto_onibus = mk(44, 40, c => {   // bus shelter with someone waiting
  shadow(c, 22, 38.5, 21, 1.5);
  R(c, '#777b86', 3, 8, 2, 30); R(c, '#777b86', 39, 8, 2, 30);
  poly(c, '#3d5f94', [[0, 10], [2, 4], [42, 4], [44, 10]]); R(c, '#24345f', 0, 10, 44, 1.5);
  R(c, 'rgba(207,224,242,.35)', 5, 12, 34, 18); R(c, '#cfe0f2', 5, 12, 34, .5);
  R(c, '#96643a', 8, 28, 28, 2); R(c, '#4a2d1c', 10, 30, 1.5, 8); R(c, '#4a2d1c', 33, 30, 1.5, 8);
  R(c, '#e6e8ee', 36, 0, 6, 6); R(c, '#3d5f94', 37, 1, 4, 4); R(c, '#e6e8ee', 38, 2, 2, 2);   // bus stop plate
  circ(c, '#7a4a10', 20, 17, 2.5); R(c, '#c22630', 17.5, 20, 5, 8); R(c, '#24345f', 18, 28, 4, 9);   // waiting
  R(c, '#2a2c33', 17.5, 36, 2, 2); R(c, '#2a2c33', 20.5, 36, 2, 2);
  R(c, '#2a2c33', 0, 38, 44, 2);
});
OUT.orelhao = mk(18, 36, c => {   // the orange phone hood
  R(c, '#4a4d57', 8, 16, 2, 20);
  c.fillStyle = '#f2a62a'; c.beginPath(); c.ellipse(9, 12, 9, 12, 0, Math.PI, 0); c.fill(); R(c, '#f2a62a', 0, 11, 18, 5);
  R(c, '#c47a1c', 0, 15, 18, 1.5); R(c, '#ffd65a', 3, 3, 4, 1);
  R(c, '#2a2c33', 6, 8, 6, 7); R(c, '#a8acb5', 7, 9, 4, 2);
});
function gente(shirt, pants, skin, hat) {
  return mk(12, 26, c => {
    shadow(c, 6, 25, 5, 1);
    circ(c, skin, 6, 4, 2.5); if (hat) { R(c, hat, 2.5, 1, 7, 1.5); R(c, hat, 4, -1, 4, 2.5); }
    R(c, shirt, 3, 7, 6, 9); R(c, shirt, 1.5, 8, 1.5, 6); R(c, shirt, 9, 8, 1.5, 6);
    R(c, pants, 3, 16, 2.5, 8); R(c, pants, 6.5, 16, 2.5, 8); R(c, '#2a2c33', 3, 23.5, 2.5, 1.5); R(c, '#2a2c33', 6.5, 23.5, 2.5, 1.5);
  });
}
OUT.gente0 = gente('#c22630', '#24345f', '#c68a5a', '#e3ab7c');
OUT.gente1 = gente('#ffd65a', '#4a4d57', '#7a4a10', null);
OUT.gente2 = gente('#3fae5a', '#2b1a12', '#e3ab7c', null);
// festa bunting strung across the street between two poles
OUT.bandeirinhas = mk(240, 44, c => {
  [2, 236].forEach(x => { R(c, '#4a2d1c', x, 0, 3, 44); R(c, '#6e4526', x, 0, .7, 44); });
  const cols = ['#c22630', '#ffd65a', '#3d5f94', '#3fae5a', '#f2a62a', '#e6e8ee'];
  for (let row = 0; row < 2; row++) {
    const y0 = 3 + row * 9, sag = 7;
    const yAt = x => y0 + sag * Math.sin(Math.PI * (x - 4) / 232);
    const pts = []; for (let x = 4; x <= 236; x += 4) pts.push([x, yAt(x)]); line(c, '#2a2c33', .5, pts);
    for (let x = 8 + row * 4, k = row; x < 232; x += 8, k++) { const y = yAt(x); poly(c, cols[k % cols.length], [[x - 3, y], [x + 3, y], [x, y + 5]]); }
  }
});

Object.assign(window.ART, OUT);
})();

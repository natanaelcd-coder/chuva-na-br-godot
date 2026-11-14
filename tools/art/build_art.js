// Builds the PNGs in assets/sprites from tools/art/art.js.
// Usage: node tools/art/build_art.js [sheet.png]   (needs Playwright with Chromium)
const { chromium } = require('playwright');
const fs = require('fs'), path = require('path');
const root = path.resolve(__dirname, '../..');
let html = fs.readFileSync(path.join(root, 'web/chuva-na-br.html'), 'utf8');
const hook = 'function start(d) {';
if (!html.includes(hook)) throw new Error('web/chuva-na-br.html changed: hook not found');
html = html.replace(hook, 'window.__H = { GL, ACC, ACM, R, poly, circ, rr, mk, text, ctext, tw, lighten, leaves, sign, billboard, W, H };\n' + hook);
(async () => {
  const b = await chromium.launch(); const p = await b.newPage();
  p.on('pageerror', e => console.log('page error:', e.message));
  await p.setContent('<!doctype html><html><head><meta charset="utf-8"></head><body>' + html + '</body></html>');
  await p.waitForTimeout(500);
  await p.addScriptTag({ content: fs.readFileSync(path.join(__dirname, 'art.js'), 'utf8') });
  // more art lives in tools/art/art_*.js; each one adds its canvases with Object.assign(window.ART, {...})
  for (const f of fs.readdirSync(__dirname).filter(f => /^art_.+\.js$/.test(f)).sort())
    await p.addScriptTag({ content: fs.readFileSync(path.join(__dirname, f), 'utf8') });
  const imgs = await p.evaluate(() => Object.fromEntries(Object.entries(window.ART).map(([k, c]) => [k, c.toDataURL('image/png')])));
  // sprites redrawn with AI (PixelLab) are listed one per line in tools/art/ia_*.txt and are never overwritten here
  const keep = new Set(fs.readdirSync(__dirname).filter(f => /^ia_.+\.txt$/.test(f))
    .flatMap(f => fs.readFileSync(path.join(__dirname, f), 'utf8').split('\n').map(l => l.trim()).filter(l => l && !l.startsWith('#'))));
  for (const [k, d] of Object.entries(imgs)) if (!keep.has(k)) fs.writeFileSync(path.join(root, 'assets/sprites', k + '.png'), Buffer.from(d.split(',')[1], 'base64'));
  console.log(Object.keys(imgs).length, 'sprites:', Object.keys(imgs).join(' '));
  if (process.argv[2]) {   // contact sheet on a mid-grey background for a quick look
    const sheet = await p.evaluate(names => {
      const imgs = names.map(n => window.ART[n]); const cols = 6, cw = 260, chh = 240;
      const big = imgs.filter(c => c.width > 500), small = imgs.filter(c => c.width <= 500);
      const rows = Math.ceil(small.length / cols); const o = document.createElement('canvas');
      o.width = cols * cw; o.height = rows * chh + big.length * 440; const g = o.getContext('2d'); g.imageSmoothingEnabled = false;
      g.fillStyle = '#5a6b5a'; g.fillRect(0, 0, o.width, o.height);
      small.forEach((c, i) => { const s = Math.min(1.5, (cw - 10) / c.width, (chh - 10) / c.height); g.drawImage(c, (i % cols) * cw + 5, Math.floor(i / cols) * chh + 5, c.width * s, c.height * s); });
      big.forEach((c, i) => g.drawImage(c, 0, rows * chh + i * 440, 768, 432));
      return o.toDataURL('image/png');
    }, Object.keys(imgs));
    fs.writeFileSync(process.argv[2], Buffer.from(sheet.split(',')[1], 'base64'));
  }
  await b.close();
})();

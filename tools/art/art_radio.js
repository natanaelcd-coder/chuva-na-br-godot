// Radio package: display labels for the Besouro's tape deck (label5 = side A, label6 = side B), drawn like the
// station names on the radio (label0..label4 come from the web version).
(() => {
const { mk, ctext } = window.__H;
Object.assign(window.ART, {
  label5: mk(40, 5, c => ctext(c, 'FITA A', 20, 0.75, '#f2a62a')),
  label6: mk(40, 5, c => ctext(c, 'FITA B', 20, 0.75, '#f2a62a')),
});
})();

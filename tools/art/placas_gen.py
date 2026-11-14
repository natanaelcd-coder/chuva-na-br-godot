#!/usr/bin/env python3
"""PixelLab: placas, pórticos, outdoors, barracas e ícones de lanche (sem letras: o texto é escrito por placas_build.py).
    python3 tools/art/placas_gen.py TAG [TAG...]   # gera 4 variações de cada em docs/ia/placas/TAG_i.png"""
import os, sys, tempfile
from PIL import Image
ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
sys.path.insert(0, os.path.join(ROOT, 'tools/ai'))
from pl import post, style, save, images_of   # noqa: E402
RAW = os.path.join(ROOT, 'docs/ia/placas')
os.makedirs(RAW, exist_ok=True)
TMP = tempfile.mkdtemp()
NOTXT = " Completely blank, no text, no letters, no numbers, no symbols on the face. "


def padded(path, size, name):
    im = Image.open(path).convert('RGBA')
    if im.width > size or im.height > size:
        k = size / max(im.width, im.height)
        im = im.resize((max(1, int(im.width * k)), max(1, int(im.height * k))), Image.NEAREST)
    sq = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    sq.alpha_composite(im, ((size - im.width) // 2, (size - im.height) // 2))
    p = os.path.join(TMP, name + '.png')
    sq.save(p)
    return p


def gen(tag, desc, refs, size):
    ps = []
    for i, r in enumerate(refs):
        src = r if os.path.exists(r) else os.path.join(ROOT, 'assets/sprites', r + '.png')
        ps.append(padded(src, size, f'{tag}_ref{i}'))
    r = post("/generate-with-style-v2", {"description": desc, "style_images": [style(p) for p in ps], "no_background": True})
    for i, im in enumerate(images_of(r)):
        save(im, os.path.join(RAW, f'{tag}_{i}.png'))
    print(tag, 'ok', len(images_of(r)), r.get('usage'))


JOBS = {
    "verde": ("Brazilian highway road sign seen from the front: a plain dark green rectangular board with a thin white border, mounted on two grey metal posts, slightly weathered." + NOTXT, ["placa_mel", "ponto_onibus"], 144),
    "marrom": ("Brazilian tourist road sign seen from the front: a plain brown rectangular board with a thin white border, mounted on two grey metal posts, slightly weathered." + NOTXT, ["placa_mel", "ponto_onibus"], 144),
    "gado": ("Yellow diamond-shaped warning road sign with black border, showing a black cow silhouette, on a grey metal post, slightly rusty.", ["placa_mel", "ponto_onibus"], 96),
    "lombada": ("Yellow diamond-shaped warning road sign with black border, showing a black speed bump hump symbol, on a grey metal post, slightly rusty.", ["placa_mel", "ponto_onibus"], 96),
    "radar": ("White rectangular Brazilian road sign with grey border and a red ring circle on the left, mounted on a single grey metal post. The ring and the rest of the face are empty." + NOTXT, ["placa_mel", "ponto_onibus"], 128),
    "madeira": ("Small rustic hand-made wooden farm sign on a single wooden post, a plain pale orange-brown plank board with darker plank lines, nailed on." + NOTXT, ["placa_mel"], 96),
    "sos": ("Small yellow roadside emergency call box on a thin grey post, orange-yellow box with a dark phone slot, no text, no letters.", ["placa_mel", "ponto_onibus"], 64),
    "portico": ("Overhead steel highway gantry frame seen from the front: two thick light-grey steel posts on concrete bases joined by a horizontal truss beam across the top, no signs hanging on it, empty.", ["ponto_onibus", "torre_celular"], 256),
    "board": ("Roadside billboard seen from the front: a flat blank plain white rectangular panel with a thin light frame, on two dark brown wooden posts with a crossbeam between them, small lamps on top." + NOTXT, ["placa_mel", "ponto_onibus"], 160),
    "led": ("Roadside electronic LED message board seen from the front: black plastic casing with a plain dark blank screen, on a single grey metal post." + NOTXT, ["placa_mel", "ponto_onibus"], 160),
    "quermesse": ("Brazilian festa junina fair: three small market stalls side by side with red, blue and green awnings and blank cream name boards, a string of colourful bunting flags above, wooden posts, dark ground strip." + NOTXT, ["banca_frutas", "caldo_cana"], 256),
    "pamonha": ("Rustic roadside pamonha stall: thatched straw roof on wooden posts, a wooden counter with green corn-husk pamonhas and yellow corn cobs, a vendor in red shirt and straw hat, a blank cream price board in front." + NOTXT, ["banca_frutas", "caldo_cana"], 160),
    "quermesse2": ("Brazilian festa junina fair seen from the front: three small market stalls side by side with red, blue and green awnings, each with a BIG wide blank cream name board across the top almost as wide as the stall, a big wide blank yellow banner board above the middle stall, strings of colourful bunting flags, wooden posts, dark ground strip." + NOTXT, ["banca_frutas", "caldo_cana"], 256),
    "pamonha2": ("Rustic roadside pamonha stall seen from the front: thatched straw roof on wooden posts, a wooden counter with green corn-husk pamonhas and yellow corn cobs, a vendor in red shirt and straw hat, and a wide blank cream signboard hanging across the whole front below the thatch." + NOTXT, ["banca_frutas", "caldo_cana"], 160),
    "bandeirinhas": ("Two garlands of colourful festa junina bunting flags hanging between two tall thin wooden poles, wide and low, nothing else.", ["banca_frutas", "porteira"], 256),
    "cafe": ("Row of three round dark green coffee plant bushes with red coffee cherries, on a low brown soil bed.", ["bush2", "banca_frutas"], 96),
}
FOODS = {
    "pastel": "a crispy golden fried Brazilian pastel, a half-moon fried pastry, on a small white paper plate",
    "coxinha": "a golden breaded Brazilian coxinha, a teardrop-shaped chicken croquette, on a small white paper napkin",
    "caldo_cana": "a tall glass of green sugarcane juice with a lime slice on the rim and a red straw",
    "cafe": "a small white ceramic cup of black Brazilian coffee on a saucer, a little steam",
    "pao_queijo": "a small pile of five golden Brazilian pao de queijo cheese bread balls on a small white plate",
    "bolo_fuba": "a slice of yellow Brazilian cornmeal cake (bolo de fuba) on a small white plate",
    "milho": "a cooked ear of corn on the cob with green husk leaves and golden kernels, on a stick",
    "queijo_doce": "a block of white Minas cheese beside a small white bowl of dark guava-paste (goiabada) with a spoon, on a small wooden board",
    "misto": "a grilled ham and cheese sandwich (misto quente) cut diagonally, on a small white plate",
    "pamonha": "a pamonha wrapped in a green corn husk, tied with string, on a small white plate",
    "pao_chapa": "a toasted buttered French bread roll (pao na chapa) on a small white paper plate",
    "agua_coco": "a green coconut with a red straw",
    "pingado": "a tall glass of cafe pingado, coffee with milk, brown and cream layers",
    "caldinho": "a small white cup of thick brown bean broth (caldinho de feijao) with a metal spoon",
}
for _k, _v in FOODS.items():
    JOBS["lanche_" + _k] = ("Small food icon, three-quarter top view: " + _v + ". Single item, no text, no letters.", ["caldo_cana", "banca_frutas"], 64)

if __name__ == "__main__":
    for t in sys.argv[1:]:
        gen(t, *JOBS[t])

#!/usr/bin/env python3
"""Recorta (caixa do alfa) e encaixa as gerações escolhidas em docs/ia/estrada/ nos sprites do jogo.
Com largura alvo (px) o recorte é reduzido por vizinho mais próximo; sem ela fica 1:1."""
import sys, re
from PIL import Image
SPEC = {  # sprite: (geração, largura alvo ou None, colunas cortadas à esquerda)
    "borracharia": ("borracharia_0", 192, 0), "igreja": ("igreja_0", 160, 0), "casa_sitio": ("casa_sitio_0", 192, 0),
    "capela": ("capela_0", 112, 0), "casa_vila0": ("casa_vila0_0", 128, 0), "casa_vila1": ("casa_vila1_0", 128, 0),
    "casa_vila2": ("casa_vila2_0", 128, 0), "casa_vila3": ("casa_vila3_0", 128, 0), "casa_vila4": ("casa_vila4_0", 128, 0),
    "ponto_onibus": ("ponto_onibus_0", 88, 0), "porteira": ("porteira_1", 96, 0), "bar": ("bar_0", 160, 18),
    "caldo_cana": ("caldo_cana_0", None, 0), "banca_frutas": ("banca_frutas_0", None, 0), "cruz_flores": ("cruz_flores_3", None, 0), "placa_mel": ("placa_mel_0", 96, 0),
    "posto": ("posto_c_0", None, 0), "venda": ("venda_a_0", None, 0),
    "moto0": ("moto_t_a_3", None, 0), "moto1": ("moto_t_a_1", None, 0), "front_moto0": ("moto_f_a_0", None, 0), "front_moto1": ("moto_f_a_1", None, 0),
    "van0": ("van_t_a_0", None, 0), "van1": ("van_t_a_2", None, 0), "front_van0": ("van_f_a_0", None, 0),
    "car7": ("car7b_1", None, 0), "mod2": ("mod2_0", None, 0), "caixa_dagua": ("caixa_dagua_b_1", None, 0), "torre_celular": ("torre_celular_b_0", None, 0),
}
# --- text the generator can't spell: written over the blank boards with the game's 5x7 pixel font
def _font():
    html = open("web/chuva-na-br.html", encoding="utf8").read()
    blk = html[html.index("const GL = {"):]
    blk = blk[:blk.index("};")]
    return {k: [int(v) for v in vs.split(",")] for k, vs in re.findall(r"'?([^'\s:,{\[\]]+)'?:\[([\d,]+)\]", blk)}
ACC = {"Á": "A/", "É": "E/", "Í": "I/", "Ó": "O/", "Ú": "U/", "Ã": "A~", "Õ": "O~", "Â": "A^", "Ê": "E^", "Ô": "O^", "Ç": "C,"}   # base letter + accent kind
def write(im, s, x, y, col, k=1):
    gl = _font()
    px = im.load()
    def dot(a, b):
        for i in range(k):
            for j in range(k):
                px[x0 + a * k + i, y + b * k + j] = col
    def mark(kind):   # accents sit above the cap line (or below, the cedilla), 2 rows tall at any scale so they fit under a roof edge
        t = 3 * k
        pts = {"/": ((3 * k, -3), (3 * k + 1, -3), (2 * k + 1, -1), (2 * k + 2, -1)) if k > 1 else ((3, -3), (2, -2)),
               "~": ((1 * k, -2), (2 * k, -3), (3 * k, -2), (4 * k, -3)) if k > 1 else ((1, -2), (2, -3), (3, -2)),
               "^": ((2 * k, -2), (2 * k + 1, -3), (3 * k, -3), (3 * k + 1, -2)) if k > 1 else ((1, -2), (2, -3), (3, -2)),
               ",": ((2 * k, 7 * k), (2 * k + 1, 7 * k + 1), (1 * k + 1, 7 * k + 2)) if k > 1 else ((2, 7), (1, 8))}[kind]
        for ax, ay in pts:
            px[x0 + ax, y + ay] = col
    x0 = x
    for ch in s:
        base, kind = (ACC[ch][0], ACC[ch][1]) if ch in ACC else (ch, None)
        g = gl.get(base)
        if g:
            for r in range(7):
                for b in range(5):
                    if g[r] >> (4 - b) & 1:
                        dot(b, r)
        if kind:
            mark(kind)
        x0 += 6 * k
def centered(im, s, cx, y, col, k=1):
    write(im, s, cx - (len(s) * 6 - 1) * k // 2, y, col, k)
LETTERS = {
    "posto": lambda im: centered(im, "POSTO ESTRELA", 162, 18, (194, 38, 48, 255), 2),
    "venda": lambda im: (centered(im, "VENDA DO ZÉ", 128, 11, (122, 52, 24, 255), 2),
                         centered(im, "PINGA", 126, 55, (40, 30, 60, 255)), centered(im, "FUMO", 126, 64, (40, 30, 60, 255))),
}

def fit(name, src, width, cut, out="assets/sprites"):
    im = Image.open(f"docs/ia/estrada/{src}.png").convert("RGBA")
    if cut:
        im = im.crop((cut, 0, im.width, im.height))
    a = im.getchannel("A").point(lambda v: 255 if v > 8 else 0)
    bb = a.getbbox()
    if src.startswith(("caixa_dagua_b", "torre_celular_b")):   # drop the flat grey ground slab the generator draws under them
        px = a.load()
        cut = bb[3]
        while cut > bb[1] and sum(1 for x in range(im.width) if px[x, cut - 1]) > 0.55 * (bb[2] - bb[0]):
            cut -= 1
        im = im.crop((0, 0, im.width, cut))
    im = im.crop(im.getchannel("A").point(lambda a: 255 if a > 8 else 0).getbbox())
    if width:
        im = im.resize((width, max(1, round(im.height * width / im.width))), Image.NEAREST)
    if name in LETTERS:
        LETTERS[name](im)
    im.save(f"{out}/{name}.png")
    print(name, im.size)
if __name__ == "__main__":
    for n in (sys.argv[1:] or SPEC):
        fit(n, *SPEC[n])

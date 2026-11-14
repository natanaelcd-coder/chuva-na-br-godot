#!/usr/bin/env python3
"""Recorta (caixa do alfa) e encaixa as gerações escolhidas em docs/ia/estrada/ nos sprites do jogo.
Com largura alvo (px) o recorte é reduzido por vizinho mais próximo; sem ela fica 1:1."""
import sys
from PIL import Image
SPEC = {  # sprite: (geração, largura alvo ou None, colunas cortadas à esquerda)
    "borracharia": ("borracharia_0", 192, 0), "igreja": ("igreja_0", 160, 0), "casa_sitio": ("casa_sitio_0", 192, 0),
    "capela": ("capela_0", 112, 0), "casa_vila0": ("casa_vila0_0", 128, 0), "casa_vila1": ("casa_vila1_0", 128, 0),
    "casa_vila2": ("casa_vila2_0", 128, 0), "casa_vila3": ("casa_vila3_0", 128, 0), "casa_vila4": ("casa_vila4_0", 128, 0),
    "ponto_onibus": ("ponto_onibus_0", 88, 0), "porteira": ("porteira_1", 96, 0), "bar": ("bar_0", 160, 18),
    "caldo_cana": ("caldo_cana_0", None, 0), "banca_frutas": ("banca_frutas_0", None, 0), "cruz_flores": ("cruz_flores_3", None, 0), "placa_mel": ("placa_mel_0", 96, 0),
    "car7": ("car7b_1", None, 0), "mod2": ("mod2_0", None, 0), "caixa_dagua": ("caixa_dagua_b_1", None, 0), "torre_celular": ("torre_celular_b_0", None, 0),
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
    im.save(f"{out}/{name}.png")
    print(name, im.size)
if __name__ == "__main__":
    for n in (sys.argv[1:] or SPEC):
        fit(n, *SPEC[n])

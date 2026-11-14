#!/usr/bin/env python3
"""Monta os sprites da segunda rodada de personagens/animais (PixelLab) a partir dos quadros escolhidos em
docs/ia/personagens/<nome>_a0..aN.png: tira os respingos soltos, recorta (quando preciso) pela caixa comum a todos os
quadros e escreve assets/sprites/<alvo>.png (quadro 0) e <alvo>_anim.png (tira lado a lado).
    python3 tools/ai/pers2_build.py"""
import os
from PIL import Image

SRC = "docs/ia/personagens"
OUT = "assets/sprites"
# alvo: (prefixo dos quadros, numero de quadros, recortar pela caixa comum, remover respingos <= N px, [largura final:
# centraliza o recorte; a largura do sprite no mundo e fixa, entao isso mantem a altura parecida com a do sprite antigo])
ITEMS = {
    "vaca0": ("vaca0", 8, False, 5),
    "vaca1": ("vaca1", 8, False, 5),
    "cavalo": ("cavalo", 9, False, 5),
    "caramelo": ("caramelo_borda", 8, False, 4),
    "galinhas": ("galinhas", 9, True, 4),
    "trator": ("trator", 8, True, 6, 80),
    "carroca": ("carroca", 9, True, 8, 80),
    "pessoa_vend": ("vend2", 9, False, 0),
    "pessoa_atend": ("atend2", 9, False, 0),
}

def despeckle(im, maxn, green=False):
    if maxn <= 0:
        return im
    if green:   # grass bits stuck to the cow's mouth
        q = im.load()
        for y in range(im.height):
            for x in range(im.width):
                r, g_, b, a = q[x, y]
                if a and g_ > r + 40 and g_ > b + 40:
                    q[x, y] = (0, 0, 0, 0)
    w, h = im.size
    px = im.load()
    seen = set()
    for y in range(h):
        for x in range(w):
            if px[x, y][3] == 0 or (x, y) in seen:
                continue
            comp, st = [], [(x, y)]
            seen.add((x, y))
            while st:
                cx, cy = st.pop()
                comp.append((cx, cy))
                for dx in (-1, 0, 1):
                    for dy in (-1, 0, 1):
                        nx, ny = cx + dx, cy + dy
                        if 0 <= nx < w and 0 <= ny < h and (nx, ny) not in seen and px[nx, ny][3] > 0:
                            seen.add((nx, ny))
                            st.append((nx, ny))
            if len(comp) <= maxn:
                for cx, cy in comp:
                    px[cx, cy] = (0, 0, 0, 0)
    return im

def main():
    for tgt, (pre, n, crop, spk, *pw) in ITEMS.items():
        fr = [despeckle(Image.open(f"{SRC}/{pre}_a{i}.png").convert("RGBA"), spk, tgt.startswith("vaca")) for i in range(n)]
        if crop:
            box = None
            for f in fr:
                b = f.getbbox()
                box = b if box is None else (min(box[0], b[0]), min(box[1], b[1]), max(box[2], b[2]), max(box[3], b[3]))
            fr = [f.crop(box) for f in fr]
            if pw and fr[0].width < pw[0]:
                pad = []
                for f in fr:
                    c = Image.new("RGBA", (pw[0], f.height), (0, 0, 0, 0))
                    c.paste(f, ((pw[0] - f.width) // 2, 0))
                    pad.append(c)
                fr = pad
        w, h = fr[0].size
        strip = Image.new("RGBA", (w * n, h), (0, 0, 0, 0))
        for i, f in enumerate(fr):
            strip.paste(f, (i * w, 0))
        fr[0].save(f"{OUT}/{tgt}.png")
        strip.save(f"{OUT}/{tgt}_anim.png")
        print(tgt, (w, h), n, "quadros")

if __name__ == "__main__":
    main()

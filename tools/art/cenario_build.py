#!/usr/bin/env python3
"""Scenery picks in docs/ia/cenario/*.png -> assets/sprites (sky, horizon, roadside pieces, stops).

    python3 tools/art/cenario_build.py          # everything
    python3 tools/art/cenario_build.py sky hz   # only some groups

sky:  sky_nuvem0..3 (cumulus), sky_chuva0..3 (rain banks), sky_sol, sky_lua: cropped to the alpha box.
hz:   hz_far_<road>, hz_near_<road>: horizon strips for scripts/world.gd. Each strip is mirrored (A + flip(A)) so the
      tile joins without a seam, and its top rows fade out where the generator clipped a ridge at the edge.
Sprites written here are listed in tools/art/ia_cenario.txt."""
import os, sys
from PIL import Image

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
RAW = os.path.join(ROOT, 'docs/ia/cenario')
OUT = os.path.join(ROOT, 'assets/sprites')


def load(n):
    return Image.open(os.path.join(RAW, n + '.png')).convert('RGBA')


def crop(im):
    return im.crop(im.getchannel('A').point(lambda a: 255 if a > 8 else 0).getbbox())


def save(im, name):
    im.save(os.path.join(OUT, name + '.png'))
    print(name, im.size)


def sky():
    for i in range(4):
        save(crop(load(f'nuvem_a_{i}')), f'sky_nuvem{i}')
    for i in range(4):
        save(crop(load(f'nuvem_chuva_{i}')), f'sky_chuva{i}')
    save(crop(load('sol_0')), 'sky_sol')
    save(crop(load('lua_0')), 'sky_lua')


def strip(im, fade):
    """mirror for a seamless tile; fade = rows at the top that dissolve (a ridge clipped by the generator's edge)"""
    px = im.load()
    for y in range(fade):
        k = (y + 1) / (fade + 1)
        for x in range(im.width):
            r, g, b, a = px[x, y]
            if a:
                # ordered dither so the fade stays pixel art
                if ((x * 7 + y * 13) % 8) / 8.0 >= k:
                    px[x, y] = (r, g, b, 0)
    t = Image.new('RGBA', (im.width * 2, im.height))
    t.paste(im, (0, 0))
    t.paste(im.transpose(Image.FLIP_LEFT_RIGHT), (im.width, 0))
    return t


HZ = {  # layer: (generation, fade rows)
    'hz_far_terra': ('far_terra_0', 12), 'hz_near_terra': ('morros_terra_0', 0),
    'hz_far_br': ('far_br_0', 12), 'hz_near_br': ('near_br_0', 2),
    'hz_far_expressa': ('far_expressa_0', 12), 'hz_near_expressa': ('near_expressa_0', 2),
}


def hz():
    for name, (src, fade) in HZ.items():
        save(strip(load(src), fade), name)


def _lettering():
    sys.path.insert(0, os.path.join(ROOT, 'tools/ai'))
    os.chdir(ROOT)   # fit_estrada reads the 5x7 font from web/chuva-na-br.html
    import fit_estrada
    return fit_estrada


def parada():
    """roadside stop of the expressa: convenience store + fuel canopy; the signs are blank in the generation and get our font"""
    fe = _lettering()
    im = crop(load('parada_a_0'))
    fe.centered(im, 'PARADA', 202, 5, (22, 84, 96, 255), 2)
    fe.centered(im, 'LOJA 24H', 88, 47, (255, 255, 255, 255), 1)
    save(im, 'parada')


def loja():
    """interior of the expressa's convenience store (no people: pessoa_atend is drawn over it): magenta glass keyed out, doubled"""
    im = load('loja_int_0')
    px = im.load()
    W, H = im.size
    clear = [[px[x, y][3] < 128 for x in range(W)] for y in range(H)]
    for y in range(H):
        for x in range(W):
            r, g, b, a = px[x, y]
            if a >= 128 and min(r, b) - g > 40 and abs(r - b) < 120:
                clear[y][x] = True
    out = Image.new('RGBA', (W, H))
    po = out.load()
    for y in range(H):
        for x in range(W):
            if not clear[y][x]:
                r, g, b, a = px[x, y]
                po[x, y] = (r, g, b, 255)
    save(out.resize((W * 2, H * 2), Image.NEAREST), 'parada_loja_sem')


def _cut_slab(im, rows=6):
    """drop the flat dark ground line some generations draw under a piece (a full-width run of dark pixels at the bottom)"""
    px = im.load()
    h = im.height
    while h > 4:
        n = sum(1 for x in range(im.width) if px[x, h - 1][3] > 8)
        dark = sum(1 for x in range(im.width) if px[x, h - 1][3] > 8 and max(px[x, h - 1][:3]) < 90)
        if n > 0.6 * im.width and dark > 0.8 * n and rows > 0:
            h -= 1
            rows -= 1
        else:
            break
    return im.crop((0, 0, im.width, h))


def props():
    """roadside pieces: cropped to the alpha box (1:1, sizes in the world come from the ww in game.gd / estrada.gd)"""
    for name, src in (('pole', 'pole_n_0'), ('lamp', 'lamp_n_0'), ('luminaria', 'luminaria_n_0')):
        save(crop(load(src)), name)
    save(_cut_slab(crop(load('muro_n_0'))), 'muro')
    a = crop(load('cerca_n_0'))   # one span between two posts: two spans, the right post of the first is the left post of the second
    px = a.load()
    cols = [x for x in range(a.width) if sum(1 for y in range(a.height) if px[x, y][3] > 8 and max(px[x, y][:3]) < 140) > a.height * 0.5]
    runs = []   # [start, end] of each post
    for x in cols:
        if runs and x == runs[-1][1] + 1:
            runs[-1][1] = x
        else:
            runs.append([x, x])
    (p1, e1), (p2, e2) = runs[0], runs[1]
    span = a.crop((p1, 0, p2, a.height))   # post + wire up to the next post
    t = Image.new('RGBA', (span.width * 2 + (e2 - p2 + 1), a.height))
    t.alpha_composite(span, (0, 0))
    t.alpha_composite(span, (span.width, 0))
    t.alpha_composite(a.crop((p2, 0, e2 + 1, a.height)), (span.width * 2, 0))
    save(t, 'cerca')


def eventos():
    """events and seasonal pieces: vans, rider, pilgrims, sky objects, tree, fire, payphone (text from the game's 5x7 font)"""
    fe = _lettering()
    k = crop(load('kombi_pamonha_n_0'))
    fe.centered(k, 'PAMONHA', 39, 46, (24, 112, 44, 255), 1)
    save(k, 'kombi_pamonha')
    k = crop(load('kombi_som_n_0'))
    fe.centered(k, 'FESTA', 41, 46, (36, 62, 108, 255), 1)
    save(k, 'kombi_som')
    for name, src in (('peao', 'peao_n_0'), ('romeiros', 'romeiros_n_0'), ('helicoptero', 'helicoptero_n_1'), ('balao', 'balao_n_0'),
                      ('arvore_natal', 'arvore_natal_n_1'), ('orelhao', 'orelhao_n_2'), ('fogueira', 'fogueira_n_0')):
        save(crop(load(src)), name)


def menu():
    """title-screen illustration under the translucent left panel of the main menu (scripts/menu.gd)"""
    save(load('menu_arte_0').convert('RGB'), 'menu_arte')


if __name__ == '__main__':
    todo = sys.argv[1:] or ['sky', 'hz']
    for t in todo:
        globals()[t]()

#!/usr/bin/env python3
"""Cabins redrawn with PixelLab (docs/ia/cabines/*.png, 384x216 with magenta glass) -> assets/sprites.

    python3 tools/art/cabines_ia.py            # cockpit*.png and every gar_cockpit_<car>_<paint>.png

Steps per car: key the magenta glass out (and clean its anti-aliased rim), paint over what the game draws itself
(gauge needles, clock digits, the radio's display, made-up sticker text), double to 768x432 with NEAREST and paint
gauge faces, displays and stickers at full resolution (stickers in the web version's 5x7 pixel font, read from
web/chuva-na-br.html, so the text is ours and not the AI's). The garage paints are the same art with the
car's main colour moved to another hue/lightness (only pixels of that colour family are touched).
The sprites written here are listed in tools/art/ia_cabines.txt so tools/art/build_art.js leaves them alone."""
import colorsys, math, os, re
from collections import deque
from PIL import Image, ImageDraw

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
RAW = os.path.join(ROOT, 'docs/ia/cabines')
OUT = os.path.join(ROOT, 'assets/sprites')
W, H = 384, 216


# ---------------------------------------------------------------- glass
def magenta(p):
    r, g, b = p[:3]
    return min(r, b) - g, abs(r - b)


def key(im):
    """magenta -> transparent, with the rim cleaned; returns RGBA 384x216"""
    im = im.convert('RGBA')
    px = im.load()
    clear = [[False] * W for _ in range(H)]
    for y in range(H):
        for x in range(W):
            p = px[x, y]
            m, d = magenta(p)
            if p[3] < 160 or (m > 110 and d < 100):
                clear[y][x] = True
    # rim: magenta-tinted pixels touching the glass go too; the faint ones take a neighbour's colour
    for _ in range(2):
        add = []
        for y in range(H):
            for x in range(W):
                if clear[y][x]:
                    continue
                if not any(0 <= x + dx < W and 0 <= y + dy < H and clear[y + dy][x + dx] for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))):
                    continue
                m, d = magenta(px[x, y])
                if m > 55 and d < 110:
                    add.append((x, y))
        for x, y in add:
            clear[y][x] = True
    # tiny opaque specks floating in the glass -> clear; tiny holes in the cabin -> filled
    _islands(clear, False, 30)
    _islands(clear, True, 8)
    out = Image.new('RGBA', (W, H))
    po = out.load()
    for y in range(H):
        for x in range(W):
            if clear[y][x]:
                po[x, y] = (0, 0, 0, 0)
            else:
                p = px[x, y]
                m, d = magenta(p)
                if m > 25 and d < 110:   # still a pinkish cast on the rim: take the darkest opaque neighbour
                    p = _neighbour(px, clear, x, y) or p
                po[x, y] = p[:3] + (255,)
    return out


def _islands(clear, val, maxn):
    """flip every component of pixels with clear == val smaller than maxn that does not touch the border
    (val=False: opaque specks in the glass; val=True: pin holes in the cabin)"""
    seen = [[False] * W for _ in range(H)]
    for y in range(H):
        for x in range(W):
            if seen[y][x] or clear[y][x] != val:
                continue
            comp, q, edge = [], deque([(x, y)]), False
            seen[y][x] = True
            while q:
                cx, cy = q.popleft()
                comp.append((cx, cy))
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    nx, ny = cx + dx, cy + dy
                    if not (0 <= nx < W and 0 <= ny < H):
                        edge = True
                        continue
                    if not seen[ny][nx] and clear[ny][nx] == clear[cy][cx]:
                        seen[ny][nx] = True
                        q.append((nx, ny))
            if len(comp) < maxn and not edge:
                for cx, cy in comp:
                    clear[cy][cx] = not clear[cy][cx]


def _neighbour(px, clear, x, y):
    best = None
    for dx in (-1, 0, 1):
        for dy in (-1, 0, 1):
            nx, ny = x + dx, y + dy
            if (dx or dy) and 0 <= nx < W and 0 <= ny < H and not clear[ny][nx]:
                p = px[nx, ny]
                m, d = magenta(p)
                if m <= 25 and (best is None or sum(p[:3]) < sum(best[:3])):
                    best = p
    return best


def fill_components(im, seeds, col):
    """the transparent component holding each seed becomes opaque `col` (mirror glass the AI also drew magenta)"""
    px = im.load()
    for sx, sy in seeds:
        if px[sx, sy][3]:
            continue
        q = deque([(sx, sy)])
        px[sx, sy] = col
        while q:
            x, y = q.popleft()
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = x + dx, y + dy
                if 0 <= nx < W and 0 <= ny < H and px[nx, ny][3] == 0:
                    px[nx, ny] = col
                    q.append((nx, ny))


# ---------------------------------------------------------------- pixel font (the web version's, 5x7, 6 px advance)
def _font():
    html = open(os.path.join(ROOT, 'web/chuva-na-br.html'), encoding='utf8').read()
    blk = html[html.index('const GL = {'):]
    blk = blk[:blk.index('};')]
    gl = {k: [int(v) for v in vs.split(',')] for k, vs in re.findall(r"'?([^'\s:,{\[\]]+)'?:\[([\d,]+)\]", blk)}
    gl['%'] = [25, 26, 2, 4, 8, 11, 19]   # (art.js adds it too)
    return gl


GL = _font()
ACC = {'Á': 'Aa', 'À': 'Ag', 'Ã': 'At', 'Â': 'Ac', 'É': 'Ea', 'Ê': 'Ec', 'Í': 'Ia', 'Ó': 'Oa', 'Õ': 'Ot', 'Ú': 'Ua', 'Ç': 'Cd', 'Ô': 'Oc'}
ACM = {'a': [(3, -3), (2, -2)], 'g': [(1, -3), (2, -2)], 'c': [(1, -2), (2, -3), (3, -2)], 't': [(1, -2), (2, -3), (3, -2), (4, -3)],
       'd': [(2, 7), (1, 8)]}


def text(d, s, x, y, col):
    col = _hex(col)
    for ch in s:
        ac = ACC.get(ch)
        gl = GL.get(ac[0] if ac else ch)
        if gl:
            for r in range(7):
                for b in range(5):
                    if gl[r] >> (4 - b) & 1:
                        d.point((x + b, y + r), fill=col)
        if ac:
            for mx, my in ACM[ac[1]]:
                d.point((x + mx, y + my), fill=col)
        x += 6


def tw(s):
    return len(s) * 6 - 1


def sticker(d, box, lines, bg, fg, edge=None):
    """box in logical units; text centred, 10 px per line (accents need the 3 rows above the capitals)"""
    x0, y0, x1, y1 = [int(v * 2) for v in box]
    d.rectangle((x0, y0, x1 - 1, y1 - 1), fill=_hex(edge) if edge else _dark(bg, 0.25))
    d.rectangle((x0 + 1, y0 + 1, x1 - 2, y1 - 3), fill=_hex(bg))
    d.line((x0 + 1, y0 + 1, x1 - 2, y0 + 1), fill=_light(bg, 0.35))
    th = len(lines) * 10 - 3
    ty = y0 + (y1 - y0 - th) // 2 + 1
    for i, l in enumerate(lines):
        text(d, l, x0 + (x1 - x0 - tw(l)) // 2, ty + i * 10, fg)


def _hex(c):
    return tuple(int(c[i:i + 2], 16) for i in (1, 3, 5)) if isinstance(c, str) else tuple(c[:3])


def _dark(c, k):
    return tuple(int(v * (1 - k)) for v in _hex(c))


def _light(c, k):
    return tuple(int(v + (255 - v) * k) for v in _hex(c))


# ---------------------------------------------------------------- gauge faces (code draws the needles: same sweep as cockpit.gd)
def gauge(d, cx, cy, r, face, tick, n=9, red=0):
    """dial face of radius r (logical) centred at (cx, cy), ticks from 0.8 pi to 2.2 pi like cockpit.gd's _needle"""
    X, Y, R_ = cx * 2, cy * 2, r * 2
    d.ellipse((X - R_, Y - R_, X + R_ - 1, Y + R_ - 1), fill=_hex(face))
    for i in range(n + 1):
        a = math.pi * 0.8 + i * math.pi * 1.4 / n
        col = _hex('#f0484a' if i > n - red else tick)
        r1 = R_ - (5.5 if i % 2 == 0 else 4.0)
        d.line((X - 0.5 + math.cos(a) * (R_ - 2.0), Y - 0.5 + math.sin(a) * (R_ - 2.0),
                X - 0.5 + math.cos(a) * r1, Y - 0.5 + math.sin(a) * r1), fill=col, width=1)


def fuel_face(d, px_, py_, r, face, tick, box=None):
    """fuel gauge: needle pivot (px_, py_) sweeping 1.2 pi .. 1.8 pi (cockpit.gd), E in red on the left"""
    if box:
        d.rectangle([int(v * 2) for v in box], fill=_hex(face))
    X, Y, R_ = px_ * 2, py_ * 2, r * 2
    for i in range(5):
        a = math.pi * 1.2 + i * math.pi * 0.6 / 4
        d.line((X - 0.5 + math.cos(a) * (R_ + 1.0), Y - 0.5 + math.sin(a) * (R_ + 1.0), X - 0.5 + math.cos(a) * (R_ - 1.0),
                Y - 0.5 + math.sin(a) * (R_ - 1.0)), fill=_hex('#f0484a' if i == 0 else tick), width=1)


def rect(d, box, col, edge=None):
    x0, y0, x1, y1 = [int(v * 2) for v in box]
    if edge:
        d.rectangle((x0 - 1, y0 - 1, x1, y1), fill=_hex(edge))
    d.rectangle((x0, y0, x1 - 1, y1 - 1), fill=_hex(col))


# ---------------------------------------------------------------- per car (positions in logical units; scripts/catalog.gd's layout matches)
def besouro(im):
    big = im.resize((W * 2, H * 2), Image.NEAREST)
    d = ImageDraw.Draw(big)
    gauge(d, 127.5, 139.0, 14.5, '#1b1d24', '#e6e8ee', n=12, red=2)     # speedometer (black face, like the real one)
    fuel_face(d, 156.5, 143.5, 4.5, '#1b1d24', '#e6e8ee', box=(151, 133, 162, 145))   # the little square box: fuel
    rect(d, (179, 133, 209, 139), '#1a120c', '#2a2c33')                # radio dial window (station name)
    rect(d, (188, 140.5, 208, 145.5), '#16202b', '#a8acb5')            # tape slot (reels: radio.gd)
    sticker(d, (226, 125, 262, 132), ['DEUS É FIEL'], '#e6e8ee', '#16202b')
    sticker(d, (229, 136, 265, 150), ['É VELHO', 'MAS TÁ PAGO'], '#e6e8ee', '#16202b')
    sticker(d, (273, 128, 304, 148), ['NÃO CORRA', 'NÃO MATE', 'NÃO MORRA'], '#ffd65a', '#16202b', edge='#c47a1c')
    return big


def picape(im):
    big = im.resize((W * 2, H * 2), Image.NEAREST)
    d = ImageDraw.Draw(big)
    gauge(d, 110.5, 143.5, 8, '#1e1c2a', '#d9dde0', n=8, red=1)
    d.ellipse((133 * 2, 138 * 2, 145 * 2 - 1, 150 * 2 - 1), fill=_hex('#1e1c2a'))
    fuel_face(d, 139.0, 147.0, 5.0, '#1e1c2a', '#d9dde0')
    rect(d, (197, 142.5, 233, 149), '#1a120c')                          # radio dial (no tuning needle: the code writes the station)
    sticker(d, (261, 139, 312, 156), ['DEVAGAR SE', 'VAI AO LONGE'], '#ffd65a', '#2b1a12', edge='#c47a1c')
    sticker(d, (318, 139, 345, 156), ['SÓ', 'DEUS'], '#e6e8ee', '#c22630')
    sticker(d, (265, 159.5, 315, 168), ['100% SÍTIO'], '#c22630', '#e6e8ee', edge='#7a1620')
    return big


GT_HOOD = ('#7a1620', '#c22630', '#3a0d12')   # body, highlight, shade: the paint seen through the glass


def hood(im, cols):
    """a strip of bonnet at the bottom of the windscreen, in the paint's colour"""
    px = im.load()
    body, hi, sh = [_hex(c) + (255,) for c in cols]
    for x in range(40, 346):
        top = 88.5 + 3.0 * ((x - 192) / 150.0) ** 2
        for y in range(int(top), 100):
            if px[x, y][3] == 0:
                px[x, y] = hi if y == int(top) else (sh if y >= 93 else body)


def gt_pre(im):
    fill_components(im, [(192, 28), (6, 92), (378, 92)], (26, 37, 71, 255))   # mirrors: the AI made their glass magenta too
    hood(im, GT_HOOD)


def gt(im):
    big = im.resize((W * 2, H * 2), Image.NEAREST)
    d = ImageDraw.Draw(big)
    gauge(d, 100.0, 114.5, 11, '#13141c', '#e6e8ee', n=10, red=0)      # speedometer
    gauge(d, 129.5, 114.5, 11, '#13141c', '#e6e8ee', n=10, red=3)      # tachometer
    d.ellipse((145 * 2, 116.5 * 2, 155 * 2 - 1, 126.5 * 2 - 1), fill=_hex('#13141c'))
    fuel_face(d, 150.0, 124.0, 4.0, '#13141c', '#e6e8ee')               # small bottom-right gauge: fuel
    rect(d, (191, 99.5, 234, 110.5), '#1f0910')                            # clock display (digits: cockpit.gd)
    rect(d, (170, 141, 198, 148), '#140c08', '#0a0a0f')                 # station display
    rect(d, (188, 164, 226, 175), '#0a0a0f')                            # equalizer window (bars: cockpit.gd)
    sticker(d, (295, 146, 335, 158), ['NO EMBALO', 'DOS ANOS 80'], '#c22630', '#e6e8ee', edge='#7a1620')
    return big


CARS = {'besouro': ('cockpit', None, besouro), 'picape': ('cockpit_picape', None, picape), 'gt': ('cockpit_gt', gt_pre, gt)}


# ---------------------------------------------------------------- garage paints
def recolor(im, base, target, hue_band, smin=0.15, lmin=0.2, sat=None, hshift=0.0):
    """move the colour family around `base` to `target`, keeping each pixel's light relative to base
    (hue_band is tested on the hue turned by hshift, so a band can straddle red)"""
    hb, lb, sb = colorsys.rgb_to_hls(*[v / 255 for v in _hex(base)])
    ht, lt, st = colorsys.rgb_to_hls(*[v / 255 for v in _hex(target)])
    if sat is not None:
        st = sat
    out = im.copy()
    px = out.load()
    h0, h1 = hue_band
    for y in range(out.size[1]):
        for x in range(out.size[0]):
            p = px[x, y]
            if p[3] == 0:
                continue
            h, l, s = colorsys.rgb_to_hls(p[0] / 255, p[1] / 255, p[2] / 255)
            h = (h + hshift) % 1.0
            w = _ramp(s, smin * 0.6, smin) * _ramp(l, lmin * 0.7, lmin) * _ramp(h, h0 - 0.03, h0) * (1 - _ramp(h, h1, h1 + 0.03))
            if w <= 0:
                continue
            nl = lt * l / lb if l <= lb else lt + (1 - lt) * (l - lb) / (1 - lb)
            ns = min(1.0, st * min(1.6, s / max(sb, 0.01)))
            rgb = colorsys.hls_to_rgb(ht, min(1.0, nl), ns)
            px[x, y] = tuple(int(round(p[i] + (rgb[i] * 255 - p[i]) * w)) for i in range(3)) + (p[3],)
    return out


def _ramp(v, a, b):
    return 0.0 if v <= a else (1.0 if v >= b else (v - a) / (b - a))


PAINTS = {   # same ids as scripts/features/garagem.gd; colours from tools/art/art_garagem.js
    'besouro': {'limao': '#9cc23a', 'bege': '#d6bf90', 'calcinha': '#93c3e3', 'laranja': '#d9762c', 'branco': '#e4e2d8'},
    'picape': {'vermelha': '#b8282e', 'saia': '#e8dcbc', 'azul': '#3d6f9e', 'saia_azul': '#e6e8ee', 'amarela': '#d9a524'},   # two-tone: the dash takes the light colour
    'gt': {'prata': '#a8acb5', 'preto': '#24262e', 'branco': '#dfe2e8', 'azul': '#24406e'},
}


def paint(car, im, pid, col):
    if car == 'besouro':   # the whole cabin is painted metal: frame, roof edge, doors, dash
        return besouro(recolor(im, '#84aed1', col, (0.52, 0.66)))
    if car == 'picape':    # the dash only (doors are leather, pillars trim)
        return picape(recolor(im, '#356645', col, (0.25, 0.47), smin=0.12, lmin=0.12))
    # GT: the bonnet takes the paint; silver and blue cars get matching trim (door cards, dash stripe, pillars),
    # black and white ones keep the red interior
    c = _hex(col)
    out = im.copy()
    px = out.load()
    old = [_hex(v) for v in GT_HOOD]
    new = [c, _light(c, 0.3), _dark(c, 0.45)]
    for y in range(85, 100):
        for x in range(40, 346):
            p = px[x, y][:3]
            if p in old:
                px[x, y] = new[old.index(p)] + (255,)
    trim = {'prata': ('#9a9ea8', 0.08), 'azul': ('#3560a8', None)}.get(pid)
    if trim:
        out = recolor(out, '#b01c24', trim[0], (0.05, 0.15), smin=0.35, lmin=0.12, sat=trim[1], hshift=0.1)
    return gt(out)


def main():
    names = []
    for car, (sprite, pre, post) in CARS.items():
        im = key(Image.open(os.path.join(RAW, car + '.png')))
        if pre:
            pre(im)
        post(im).save(os.path.join(OUT, sprite + '.png'))
        names.append(sprite)
        for pid, col in PAINTS[car].items():
            n = 'gar_cockpit_%s_%s' % (car, pid)
            paint(car, im, pid, col).save(os.path.join(OUT, n + '.png'))
            names.append(n)
    with open(os.path.join(os.path.dirname(__file__), 'ia_cabines.txt'), 'w') as f:
        f.write('# cabines refeitas com a PixelLab (tools/art/cabines_ia.py, brutos em docs/ia/cabines/)\n')
        f.write('\n'.join(names) + '\n')
    print(len(names), 'sprites')


if __name__ == '__main__':
    main()

#!/usr/bin/env python3
"""Monta os sprites de placas a partir das gerações escolhidas em docs/ia/placas/ (placas_gen.py).
A IA desenha só a placa em branco (moldura, postes, ferrugem); o texto e os símbolos (anéis do radar, setas) vêm do
sprite antigo, recortados pelo mapa de pixels que diferem da cor do fundo, e são colados na mesma posição.
    python3 tools/art/placas_build.py [nome ...]"""
import os, sys, colorsys
from PIL import Image
ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
SPR = os.path.join(ROOT, 'assets/sprites')
RAW = os.path.join(ROOT, 'docs/ia/placas')
OLD = os.path.join(ROOT, 'tools/art/placas_antigas')   # cópia dos sprites antigos (só leitura, ver old())


def gen(name):
    return Image.open(os.path.join(RAW, name + '.png')).convert('RGBA')


def old(name):
    p = os.path.join(OLD, name + '.png')
    if not os.path.exists(p):
        p = os.path.join(SPR, name + '.png')
    return Image.open(p).convert('RGBA')


def bbox(im):
    return im.getchannel('A').point(lambda a: 255 if a > 8 else 0).getbbox()


def stretch(src, size, mx, my):
    """9 fatias: bordas fixas (mx, my) e o miolo esticado (vizinho mais próximo)"""
    w, h = src.size
    tw, th = size
    out = Image.new('RGBA', size, (0, 0, 0, 0))
    xs = [(0, mx, 0, mx), (mx, w - mx, mx, tw - mx), (w - mx, w, tw - mx, tw)]
    ys = [(0, my, 0, my), (my, h - my, my, th - my), (h - my, h, th - my, th)]
    for sx0, sx1, dx0, dx1 in xs:
        for sy0, sy1, dy0, dy1 in ys:
            piece = src.crop((sx0, sy0, sx1, sy1)).resize((dx1 - dx0, dy1 - dy0), Image.NEAREST)
            out.paste(piece, (dx0, dy0))
    return out


def split_sign(im):
    """face (retângulo) e postes de uma geração de placa: devolve (face, [postes])"""
    bb = bbox(im)
    im = im.crop(bb)
    a = im.getchannel('A')
    W, H = im.size
    fy = 0
    for y in range(H):
        if sum(1 for x in range(W) if a.getpixel((x, y)) > 8) > 0.6 * W:
            fy = y
    face = im.crop((0, 0, W, fy + 1))
    posts = []
    x = 0
    while x < W:
        if a.getpixel((x, H - 1)) > 8:
            s = x
            while x < W and a.getpixel((x, H - 1)) > 8:
                x += 1
            posts.append(im.crop((s - 1, fy + 1, x + 1, H)))
        x += 1
    return face, posts


def stretch_post(p, h, top=4, bot=8):
    w, ph = p.size
    out = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    out.paste(p.crop((0, 0, w, top)), (0, 0))
    out.paste(p.crop((0, ph - bot, w, ph)), (0, h - bot))
    mid = p.crop((0, top, w, ph - bot))
    # miolo: repete a faixa central (os postes são lisos), para a ferrugem do pé não ser esticada
    y = top
    while y < h - bot:
        out.paste(mid.crop((0, 0, w, min(mid.height, h - bot - y))), (0, y))
        y += mid.height
    return out


def recolor(im, hue, sat=None, val=1.0, lo=0.25):
    """troca o matiz dos pixels bem saturados (a face verde vira azul); ferrugem/moldura ficam"""
    px = im.load()
    for y in range(im.height):
        for x in range(im.width):
            r, g, b, a = px[x, y]
            if a == 0:
                continue
            h, s, v = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
            if s > lo and 0.25 < h < 0.5:
                s2 = s if sat is None else min(1, s * sat)
                r2, g2, b2 = colorsys.hsv_to_rgb(hue, s2, min(1, v * val))
                px[x, y] = (int(r2 * 255), int(g2 * 255), int(b2 * 255), a)
    return im


def ink(oldim, base, rect, ignore=()):
    """pixels do sprite antigo dentro de rect cuja cor difere de base: o texto/símbolos"""
    x0, y0, x1, y1 = rect
    op = oldim.load()
    out = []
    for y in range(y0, y1):
        for x in range(x0, x1):
            c = op[x, y]
            if c[3] > 0 and c[:3] != base[:3] and c[:3] not in ignore:
                out.append((x, y, c))
    return out


def sign(name, src, face_h, base, wipe=False, hue=None, hue_sat=None, hue_val=1.0, ring=False, inset=5, post_h=None, keep_ring=False):
    o = old(name)
    W, H = o.size
    face_g, posts_g = split_sign(gen(src))
    if wipe:   # apaga o anel vermelho da geração: o anel e os números vêm do sprite antigo
        px = face_g.load()
        for y in range(face_g.height):
            for x in range(face_g.width):
                r, g, b, a = px[x, y]
                if a and r > 140 and g < 110 and b < 110:
                    px[x, y] = (236, 237, 241, 255)
    if hue is not None:
        face_g = recolor(face_g, hue, hue_sat, hue_val)
        posts_g = [p for p in posts_g]
    out = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    # postes nas mesmas posições do antigo
    oa = o.getchannel('A')
    runs, x = [], 0
    while x < W:
        if oa.getpixel((x, H - 1)) > 0:
            s = x
            while x < W and oa.getpixel((x, H - 1)) > 0:
                x += 1
            runs.append((s, x - 1))
        x += 1
    for i, (s, e) in enumerate(runs):
        pg = posts_g[min(i, len(posts_g) - 1)] if posts_g else None
        if pg is None:
            continue
        cx = (s + e + 1) // 2
        pst = stretch_post(pg, H - face_h + 6)
        out.alpha_composite(pst, (cx - pst.width // 2, face_h - 6))
    f = stretch(face_g, (W, face_h), min(7, face_g.width // 4), min(7, face_g.height // 4))
    out.alpha_composite(f, (0, 0))
    if wipe:   # miolo liso: sem o anel fantasma da geração
        for y in range(inset + 1, face_h - inset - 1):
            for x in range(inset + 1, W - inset - 1):
                out.putpixel((x, y), (236, 237, 241, 255))
    for x, y, c in ink(o, base, (inset, inset, W - inset, face_h - inset)):
        out.putpixel((x, y), c)
    return out


def save(im, name):
    im.save(os.path.join(SPR, name + '.png'))
    print(name, im.size)


def squeeze(im, h):
    """ajusta a altura apagando (ou repetindo) linhas do meio"""
    w, ph = im.size
    if ph == h:
        return im
    mid = ph // 2
    if h < ph:
        d = ph - h
        a, b = mid - d // 2, mid - d // 2 + d
        out = Image.new('RGBA', (w, h), (0, 0, 0, 0))
        out.paste(im.crop((0, 0, w, a)), (0, 0))
        out.paste(im.crop((0, b, w, ph)), (0, a))
        return out
    out = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    out.paste(im.crop((0, 0, w, mid)), (0, 0))
    out.paste(im.crop((0, mid, w, ph)), (0, h - (ph - mid)))
    for y in range(mid, h - (ph - mid)):
        out.paste(im.crop((0, mid, w, mid + 1)), (0, y))
    return out


def head_legs(im, light=False):
    """primeira faixa contígua de linhas largas (a placa/caixa) e o resto (pernas); light: só linhas claras (placa branca, sem a travessa)"""
    im = im.crop(bbox(im))
    a = im.getchannel('A')
    W, H = im.size
    wide = [sum(1 for x in range(W) if a.getpixel((x, y)) > 8 and (not light or sum(im.getpixel((x, y))[:3]) > 380)) > 0.5 * W for y in range(H)]
    y0 = wide.index(True)
    y1 = y0
    while y1 + 1 < H and wide[y1 + 1]:
        y1 += 1
    return im.crop((0, 0, W, y1 + 1)), im.crop((0, y1 + 1, W, H)), y0


def panel(name, src, face_h, inset, mx, legs_mx, interior=True, head_my_top=None, legs_center=False, light=False):
    """cabeça (placa/caixa) esticada em 9 fatias + pernas, e o interior do sprite antigo colado dentro da moldura"""
    o = old(name)
    W, H = o.size
    head, legs, y0 = head_legs(gen(src), light)
    out = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    lh = H - face_h
    if legs.height and lh > 0:
        if legs_center:
            lg = squeeze(legs, lh + 4)
            out.alpha_composite(lg, ((W - lg.width) // 2, face_h - 4))
        else:
            lg = squeeze(stretch(legs, (W, legs.height), legs_mx, 1), lh + 4)
            out.alpha_composite(lg, (0, face_h - 4))
    hd = stretch(head, (W, face_h), mx, min(head_my_top or 8, head.height // 3))
    out.alpha_composite(hd, (0, 0))
    if interior:
        op = o.load()
        for y in range(inset, face_h - inset):
            for x in range(inset, W - inset):
                if op[x, y][3] > 0:
                    out.putpixel((x, y), op[x, y])
    return out


GREEN, BROWN, BLUE = (22, 72, 44), (110, 69, 38), (36, 52, 95)
PICK = {"verde": "verde_1", "marrom": "marrom_1", "board": "board_1", "led": "led_2"}   # gerações escolhidas


def build_signs(only=None):
    S = {}
    for n, fh in [("placa_parada", 72), ("placa_pedagio", 72), ("placa_saida", 52), ("sign0", 72), ("sign1", 52), ("sign2", 72),
                  ("sign3", 52), ("sign4", 52), ("sign5", 32), ("sign_posto", 72)]:
        S[n] = lambda n=n, fh=fh: sign(n, PICK["verde"], fh, GREEN)
    for n, fh in [("placa_sitio0", 72), ("placa_sitio1", 52), ("placa_sitio2", 72), ("placa_venda", 52)]:
        S[n] = lambda n=n, fh=fh: sign(n, PICK["marrom"], fh, BROWN)
    S["placa_volte"] = lambda: sign("placa_volte", PICK["verde"], 52, BLUE, hue=0.625, hue_val=1.3)
    S["placa_cidade"] = lambda: sign("placa_cidade", PICK["verde"], 72, BLUE, hue=0.625, hue_val=1.3)
    S["placa_km_verde"] = lambda: sign("placa_km_verde", PICK["verde"], 52, GREEN)
    S["placa_km_marrom"] = lambda: sign("placa_km_marrom", PICK["marrom"], 52, BROWN)
    for n in ["board0", "board1", "board2", "board3"]:
        S[n] = lambda n=n: panel(n, PICK["board"], 72, 3, 9, 22, light=True)
    for n in ["led0", "led1"] + ["led_fun%d" % i for i in range(6)]:
        S[n] = lambda n=n: panel(n, PICK["led"], 76, 7, 8, 0, legs_center=True)
    for n, f in S.items():
        if not only or n in only:
            save(f(), n)


def fit_sprite(im, W, H):
    """recorta, leva à largura W (vizinho mais próximo) e acerta a altura H apagando/repetindo linhas do meio (o poste)"""
    im = im.crop(bbox(im))
    im = im.resize((W, max(1, round(im.height * W / im.width))), Image.NEAREST)
    out = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    im = squeeze(im, H) if im.height > H else im
    out.alpha_composite(im, (0, H - im.height))
    return out


def no_green(im):
    px = im.load()
    for y in range(im.height):
        for x in range(im.width):
            r, g, b, a = px[x, y]
            if a and g > r + 15 and g > b + 15:
                px[x, y] = (0, 0, 0, 0)
    return im


def build_extras(only=None):
    S = {
        "placa_gado": lambda: fit_sprite(gen("gado_0"), 72, 96),
        "placa_lombada": lambda: fit_sprite(gen("lombada_0"), 72, 96),
        "placa_radar": lambda: sign("placa_radar", "radar_0", 72, (230, 232, 238), wipe=True, inset=4),
        "placa_reduza": lambda: sign("placa_reduza", "radar_0", 84, (230, 232, 238), wipe=True, inset=4),
        "sos": lambda: fit_sprite(no_green(gen("sos_4")), 32, 60),
        "cafe": lambda: fit_sprite(gen("cafe_0"), 96, 36),
    }
    for n, f in S.items():
        if not only or n in only:
            save(f(), n)


def build_portico():
    """pórtico 480x180: estrutura gerada (postes e treliça, treliça repetida no meio) + duas placas verdes nas posições do antigo"""
    fr = gen("portico_0")
    fr = fr.crop(bbox(fr))
    w, h = fr.size
    mx = 40
    base = Image.new('RGBA', (480, 180), (0, 0, 0, 0))
    left, right = squeeze(fr.crop((0, 0, mx, h)), 180), squeeze(fr.crop((w - mx, 0, w, h)), 180)
    mid = fr.crop((mx, 0, w - mx, 36))   # só a treliça (sem a sombra do chão)
    base.alpha_composite(left, (4, 0))
    base.alpha_composite(right, (476 - mx, 0))
    x = 4 + mx
    while x < 476 - mx:
        base.alpha_composite(mid.crop((0, 0, min(mid.width, 476 - mx - x), 36)), (x, 0))
        x += mid.width
    face_g, _ = split_sign(gen(PICK["verde"]))
    for (x0, x1) in [(36, 251), (272, 463)]:
        base.alpha_composite(stretch(face_g, (x1 - x0 + 1, 62), 7, 7), (x0, 0))
    for name in ("portico_branco", "portico"):
        out, o = base.copy(), old(name)
        for (x0, x1) in [(36, 251), (272, 463)]:
            for xx, yy, c in ink(o, GREEN, (x0 + 13, 2, x1 - 11, 56)):
                out.putpixel((xx, yy), c)
        save(out, name)


def _garland_strip(g):
    """a guirlanda de baixo (lado esquerdo) da geração, 'desentortada' (cada coluna sobe até o cordão ficar reto) e cortada entre
    duas bandeirinhas: um pedaço que emenda a si mesmo"""
    a = g.load()
    W, H = g.size
    x0, x1 = 12, 136
    y = 56
    cols = []
    for x in range(x0, x1):
        best = None
        for yy in range(y - 1, y + 3):
            if a[x, yy][3] > 0:
                best = yy
                break
        if best is None:
            best = y
        y = best
        cols.append((x, y))
    FH = 28
    strip = Image.new('RGBA', (len(cols), FH), (0, 0, 0, 0))
    for i, (x, cy) in enumerate(cols):
        for j in range(FH):
            yy = cy - 1 + j
            if yy < H and not (j < 1 and a[x, yy][3] == 0):
                strip.putpixel((i, j), a[x, yy])
    # colunas "vazias" (só cordão): cortes possíveis
    gaps = [i for i in range(strip.width) if sum(1 for j in range(4, FH) if strip.getpixel((i, j))[3] > 0) == 0]
    return strip, gaps


def build_bandeirinhas():
    g = gen("bandeirinhas_0")
    g = g.crop(bbox(g))
    strip, gaps = _garland_strip(g)
    c0 = gaps[0] if gaps else 0
    c1 = gaps[-1] if gaps else strip.width
    piece = strip.crop((c0, 0, c1, strip.height))
    # postes da própria geração
    pw = 8
    pole_l = g.crop((0, 0, pw, g.height))
    pole_r = g.crop((g.width - pw, 0, g.width, g.height))
    def pole(src, h):
        return stretch_post(src, h, top=6, bot=10)
    def garland(L, y_end, sag, shift):
        out = Image.new('RGBA', (L, y_end + sag + 30), (0, 0, 0, 0))
        base = Image.new('RGBA', (L, strip.height), (0, 0, 0, 0))
        x = -(shift % piece.width)
        while x < L:
            base.alpha_composite(piece, (x, 0))
            x += piece.width
        for xx in range(L):
            t = (xx + 0.5) / L
            dy = int(round(sag * (1 - (2 * t - 1) ** 2)))
            col = base.crop((xx, 0, xx + 1, strip.height))
            out.alpha_composite(col, (xx, y_end + dy))
        return out
    def tone(im, sat, val):
        im = im.copy()
        px = im.load()
        for yy in range(im.height):
            for xx in range(im.width):
                r, gg, b, aa = px[xx, yy]
                if aa:
                    h, s_, v = colorsys.rgb_to_hsv(r / 255, gg / 255, b / 255)
                    r2, g2, b2 = colorsys.hsv_to_rgb(h, s_ * sat, min(1, v * val))
                    px[xx, yy] = (int(r2 * 255), int(g2 * 255), int(b2 * 255), aa)
        return im
    def compose(W, H, xl, xr, gar, sat, val):
        out = Image.new('RGBA', (W, H), (0, 0, 0, 0))
        L = xr - xl - pw
        for (ye, sag, sh) in gar:
            gl = garland(L, ye, sag, sh)
            out.alpha_composite(tone(gl, sat, val), (xl + pw, 0))
        out.alpha_composite(pole(pole_l, H), (xl, 0))
        out.alpha_composite(pole(pole_r, H), (xr, 0))
        return out
    save(compose(480, 88, 4, 468, [(4, 10, 0), (28, 12, 40)], 0.62, 0.92), "bandeirinhas")
    save(compose(480, 192, 26, 446, [(26, 12, 0), (52, 14, 61)], 1.0, 1.0), "bandeirinhas_junina")


LANCHES = {"pastel": 0, "coxinha": 0, "caldo_cana": 0, "cafe": 0, "pao_queijo": 0, "bolo_fuba": 0, "milho": 0, "queijo_doce": 0,
           "misto": 0, "pamonha": 0, "pao_chapa": 0, "agua_coco": 0, "pingado": 0, "caldinho": 1}   # geração escolhida de cada ícone


def build_lanches(only=None):
    """ícones 64x48 (o jogo os desenha em 32x24): a geração (64x64) recortada e centrada, sem esticar"""
    for k, i in LANCHES.items():
        if only and "lanche_" + k not in only:
            continue
        src = os.path.join(RAW, "lanche_%s_%d.png" % (k, i))
        if not os.path.exists(src):
            continue
        im = gen("lanche_%s_%d" % (k, i))
        im = im.crop(bbox(im))
        if im.width > 62 or im.height > 46:
            f = min(62 / im.width, 46 / im.height)
            im = im.resize((max(1, int(im.width * f)), max(1, int(im.height * f))), Image.NEAREST)
        out = Image.new('RGBA', (64, 48), (0, 0, 0, 0))
        out.alpha_composite(im, ((64 - im.width) // 2, 47 - im.height))
        save(out, "lanche_" + k)


def _font_tools():
    sys.path.insert(0, os.path.join(ROOT, 'tools/ai'))
    import fit_estrada
    return fit_estrada


def build_barracas():
    fe = _font_tools()
    # barraca de pamonha: a placa creme larga da geração leva o texto
    im = gen("pamonha2_2")
    im = im.crop(bbox(im))
    ox, oy = bbox(gen("pamonha2_2"))[:2]
    fe.centered(im, "PAMONHA", 45 - ox, 47 - oy, (122, 52, 24, 255))
    fe.centered(im, "QUENTINHA", 45 - ox, 56 - oy, (194, 38, 48, 255))
    save(im, "barraca_pamonha")
    # quermesse: três barracas com placas em branco e a faixa amarela
    im = gen("quermesse2_0")
    bb = bbox(im)
    im = im.crop(bb)
    red, dark = (160, 30, 40, 255), (122, 52, 24, 255)
    fe.centered(im, "QUERMESSE", 131, 13, dark)
    fe.centered(im, "QUENTÃO", 54, 47, red)
    fe.centered(im, "PASTEL", 131, 47, red)
    fe.centered(im, "PESCARIA", 207, 47, red)
    save(im, "quermesse")


if __name__ == "__main__":
    a = sys.argv[1:]
    if a == ["lanches"]:
        build_lanches()
    elif a == ["bandeirinhas"]:
        build_bandeirinhas()
    elif a == ["portico"]:
        build_portico()
    elif a and a[0] == "extras":
        build_extras(a[1:])
    elif a == ["barracas"]:
        build_barracas()
    else:
        build_signs(a)

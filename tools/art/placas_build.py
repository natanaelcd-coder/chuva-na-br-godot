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


def sign(name, src, face_h, base, hue=None, hue_sat=None, hue_val=1.0, ring=False, inset=5, post_h=None, keep_ring=False):
    o = old(name)
    W, H = o.size
    face_g, posts_g = split_sign(gen(src))
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
    elif a == ["barracas"]:
        build_barracas()
    else:
        build_signs(a)

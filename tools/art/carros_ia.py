#!/usr/bin/env python3
"""Carros do jogador vistos de fora (traseira), refeitos com a PixelLab (/generate-with-style-v2, referências = o trânsito novo).
Brutos escolhidos em docs/ia/carros/{besouro,picape,gt}_raw.png (128x128, fundo transparente, com rodas e sombra no chão).
Este script: corta a sombra e as rodas (o jogo desenha as rodas à parte, para elas ficarem no chão quando a carroceria
balança/pula), centra no eixo dos pneus, deixa folga embaixo para as rodas, e recolore a lataria para as cores da garagem.
Escreve assets/sprites/player*.png e gar_player_*.png e imprime as medidas para scripts/catalog.gd (wheel_x, brake_x/y...).
    python3 tools/art/carros_ia.py"""
import colorsys, os, sys
import numpy as np
from PIL import Image

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..")
RAW = os.path.join(ROOT, "docs", "ia", "carros")
OUT = os.path.join(ROOT, "assets", "sprites")

# cut = primeira linha (do bruto) já dentro dos pneus; tires = (x esquerdo do pneu, x direito do pneu) centros; bw = largura da carroceria em unidades do jogo
CARS = {
    "besouro": dict(raw="besouro_raw.png", out="player", cut=93, tires=(28.5, 97.0), bw=60.0, lamp_y=74.5),
    "picape":  dict(raw="picape_raw.png", out="player_picape", cut=95, tires=(30.0, 97.0), bw=64.0, lamp_y=74.0),
    "gt":      dict(raw="gt_raw.png", out="player_gt", cut=96, tires=(28.0, 99.0), bw=64.0, lamp_y=74.5),
}
GAP = 3.0   # unidades de folga embaixo (a carroceria repousa 6 acima do chão; as rodas têm 7 de altura)


def base(c):
    a = np.array(Image.open(os.path.join(RAW, c["raw"])).convert("RGBA"))
    a[c["cut"]:] = 0
    ys, xs = np.where(a[..., 3] > 0)
    cx = sum(c["tires"]) / 2.0
    half = int(max(cx - xs.min(), xs.max() - cx) + 1)
    x0 = int(round(cx)) - half; x1 = int(round(cx)) + half + 1
    y0 = ys.min()
    crop = a[y0:c["cut"], max(x0, 0):x1]
    if x0 < 0: crop = np.pad(crop, ((0, 0), (-x0, 0), (0, 0)))
    h0, w0 = crop.shape[:2]
    # a tela do jogo desenha o corpo num retângulo 64x46 unidades (também no diário, na parada e na garagem): a tela tem essa proporção
    pad = 4
    for _ in range(6):
        H = h0 + pad
        W = max(int(np.ceil(H * 64.0 / 46.0)), w0)
        s = 64.0 / W
        pad = int(round(GAP / s))
    H = h0 + pad
    W = max(int(np.ceil(H * 64.0 / 46.0)), w0)
    canvas = np.zeros((H, W, 4), np.uint8)
    ox = (W - w0) // 2
    canvas[:h0, ox:ox + w0] = crop
    crop = canvas
    w = W
    c["s"] = s; c["w"] = w; c["h"] = crop.shape[0]; c["pad"] = pad; c["y0"] = y0; c["x0"] = x0 - ox
    return crop


def metrics(name, c, arr):
    s = c["s"]; ccx = (c["w"]) / 2.0
    tl, tr = (c["tires"][0] - c["x0"]), (c["tires"][1] - c["x0"])
    half = (tr - tl) / 2.0 * s
    print(f"{name}: tex {c['w']}x{c['h']} px, {c['w']*s:.1f}x{c['h']*s:.2f} unidades; wheel_x=[{-half-4.5:.1f}, {half-4.5:.1f}]")
    lamp_dx = 0
    a = arr
    r, g, b = a[..., 0].astype(int), a[..., 1].astype(int), a[..., 2].astype(int)
    m = (a[..., 3] > 128) & (r > 150) & (g < 100) & (b < 100)
    yy, xx = np.where(m)
    if len(xx):
        sel = xx > ccx
        print(f"   lampadas: x=+-{(xx[sel].mean() - ccx)*s:.1f}")
    ly = (c["lamp_y"] - c["y0"])
    print(f"   brake_y = {2.0 - (c['h'] - ly) * s:.1f}  (altura da textura {c['h']*s:.1f}u, lampada a {ly*s:.1f}u do topo)")


def hsv_arr(a):
    rgb = a[..., :3].astype(np.float32) / 255.0
    mx = rgb.max(-1); mn = rgb.min(-1); d = mx - mn
    r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
    h = np.zeros_like(mx)
    m = d > 1e-6
    rc = m & (mx == r); gc = m & (mx == g) & ~rc; bc = m & ~rc & ~gc
    h[rc] = ((g - b)[rc] / d[rc]) % 6
    h[gc] = (b - r)[gc] / d[gc] + 2
    h[bc] = (r - g)[bc] / d[bc] + 4
    return h * 60.0, np.where(mx > 0, d / np.maximum(mx, 1e-6), 0), mx


def hex2hsv(hx):
    return colorsys.rgb_to_hsv(*[int(hx[i:i + 2], 16) / 255 for i in (1, 3, 5)])


def recolor(a, mask, target):
    """lataria (mask) -> cor `target`, mantendo as luzes e sombras do desenho: o V de cada pixel relativo ao V mediano da lataria"""
    h, s, v = hsv_arr(a)
    vref = np.median(v[mask]); sref = np.median(s[mask])
    th, ts, tv = hex2hsv(target)
    nv = np.clip(tv * (v / vref) ** 0.9, 0, 1)
    ns = np.clip(ts * (s / max(sref, 1e-3)) ** 0.7, 0, 1)
    ns = ns * np.where(nv > 0.85, 0.6, 1.0)   # brilho quase branco perde cor
    out = a.copy()
    sel = np.where(mask)
    for y, x in zip(*sel):
        r, g, b = colorsys.hsv_to_rgb(th, float(ns[y, x]), float(nv[y, x]))
        out[y, x, :3] = (round(r * 255), round(g * 255), round(b * 255))
    return out


def masks(name, a):
    h, s, v = hsv_arr(a)
    al = a[..., 3] > 0
    if name == "besouro":
        return al & (h > 185) & (h < 213) & (s > 0.12) & (v > 0.3)
    if name == "picape":
        return al & (h > 85) & (h < 175) & (s > 0.22)
    # gt: lataria vermelha escura; lanternas (vermelho vivo) e parachoque preto ficam
    m = al & ((h > 335) | (h < 15)) & (s > 0.45) & (v > 0.15)
    return m

PAINTS = {
    "besouro": {"limao": "#9cc23a", "bege": "#d6bf90", "calcinha": "#93c3e3", "laranja": "#d9762c", "branco": "#e4e2d8"},
    "picape": {"vermelha": "#b8282e", "saia": ("#7a4a24", "#e8dcbc"), "azul": "#3d6f9e", "saia_azul": ("#2f5f8f", "#e6e8ee"), "amarela": "#d9a524"},
    "gt": {"prata": "#a8acb5", "preto": "#2b2d36", "branco": "#dfe2e8", "azul": "#24406e"},
}
CAB_ROW = 31   # picape: acima disto é a cabine (teto e vidro de trás), abaixo a caçamba


def main():
    for name, c in CARS.items():
        arr = base(c)
        Image.fromarray(arr).save(os.path.join(OUT, c["out"] + ".png"))
        metrics(name, c, arr)
        m = masks(name, arr)
        if name == "gt":   # as lanternas continuam vermelhas: a faixa delas (pixels vivos) fica fora
            ly = int(c["lamp_y"] - c["y0"]); cxp = arr.shape[1] / 2.0
            xs = np.abs(np.arange(arr.shape[1]) - cxp + 0.5)
            box = np.zeros_like(m); box[ly - 4:ly + 4, :] = ((xs > 16.5) & (xs < 44))[None, :]
            m &= ~box
        for pid, col in PAINTS[name].items():
            if isinstance(col, tuple):
                top = np.zeros_like(m); top[:CAB_ROW] = True
                o = recolor(arr, m & ~top, col[0])
                o = recolor(o, m & top, col[1])
            else:
                o = recolor(arr, m, col)
            Image.fromarray(o).save(os.path.join(OUT, f"gar_player_{name}_{pid}.png"))


if __name__ == "__main__":
    main()

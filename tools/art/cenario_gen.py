#!/usr/bin/env python3
"""PixelLab helpers for the scenery pass (sky, horizon, roadside pieces, stops, title art).
Raw picks live in docs/ia/cenario/; tools/art/cenario_build.py turns them into assets/sprites.

    from cenario_gen import gen_style, gen_image
    gen_style("nuvem_a", "descrição", ["mangueira"], 128)   # /generate-with-style-v2: 4 variações, fundo transparente
    gen_image("serra_br", "descrição", 688, 384, refs=[...]) # /generate-image-v2
"""
import os, sys, tempfile
from PIL import Image
ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
sys.path.insert(0, os.path.join(ROOT, 'tools/ai'))
from pl import post, img, ref, style, save, images_of   # noqa: E402

RAW = os.path.join(ROOT, 'docs/ia/cenario')
TMP = tempfile.mkdtemp()
os.makedirs(RAW, exist_ok=True)


def padded(path, size, name):
    """style images fix the output size (largest side, square): paste the reference on a transparent square"""
    im = Image.open(path).convert('RGBA')
    if im.width > size or im.height > size:
        k = size / max(im.width, im.height)
        im = im.resize((max(1, int(im.width * k)), max(1, int(im.height * k))), Image.NEAREST)
    sq = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    sq.alpha_composite(im, ((size - im.width) // 2, (size - im.height) // 2))
    p = os.path.join(TMP, name + '.png')
    sq.save(p)
    return p


def gen_style(tag, desc, refs, size, extra=None):
    paths = []
    for i, r in enumerate(refs):
        src = r if os.path.exists(r) else os.path.join(ROOT, 'assets/sprites', r + '.png')
        paths.append(padded(src, size, f'{tag}_ref{i}'))
    body = {"description": desc, "style_images": [style(p) for p in paths], "no_background": True}
    body.update(extra or {})
    r = post("/generate-with-style-v2", body)
    out = []
    for i, im in enumerate(images_of(r)):
        p = os.path.join(RAW, f'{tag}_{i}.png')
        save(im, p)
        out.append(p)
    print(tag, 'ok', len(out), r.get('usage'))
    return out


def gen_image(tag, desc, w, h, refs=(), style_img=None, extra=None):
    body = {"description": desc, "image_size": {"width": w, "height": h}}
    if style_img:
        body["style_image"] = ref(style_img)
    if refs:
        body["reference_images"] = [ref(p, u) if isinstance(p, str) else ref(*p) for p, u in [(r, None) if isinstance(r, str) else r for r in refs]]
    body.update(extra or {})
    r = post("/generate-image-v2", body)
    out = []
    for i, im in enumerate(images_of(r)):
        p = os.path.join(RAW, f'{tag}_{i}.png')
        save(im, p)
        out.append(p)
    print(tag, 'ok', len(out), r.get('usage'))
    return out

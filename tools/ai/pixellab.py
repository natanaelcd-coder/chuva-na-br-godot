#!/usr/bin/env python3
"""PixelLab v2 pixflux: pixellab.py OUT.png W H "description" [--seed N] [--palette pal.png] [--bg]
The key comes from PIXELLAB_API_KEY or is injected by the session's network secrets."""
import base64, json, os, sys, urllib.request

def b64(path):
    return {"type": "base64", "base64": "data:image/png;base64," + base64.b64encode(open(path, "rb").read()).decode()}

a = sys.argv[1:]
out, w, h, desc = a[0], int(a[1]), int(a[2]), a[3]
body = {"description": desc, "image_size": {"width": w, "height": h}}
if "--seed" in a:
    body["seed"] = int(a[a.index("--seed") + 1])
if "--palette" in a:
    body["color_image"] = b64(a[a.index("--palette") + 1])
if "--bg" in a:
    body["no_background"] = True
hd = {"Content-Type": "application/json"}
if os.environ.get("PIXELLAB_API_KEY"):
    hd["Authorization"] = "Bearer " + os.environ["PIXELLAB_API_KEY"]
req = urllib.request.Request("https://api.pixellab.ai/v2/create-image-pixflux", data=json.dumps(body).encode(), headers=hd, method="POST")
try:
    r = json.load(urllib.request.urlopen(req, timeout=180))
except urllib.error.HTTPError as e:
    sys.exit(f"HTTP {e.code}: {e.read().decode()[:400]}")
open(out, "wb").write(base64.b64decode(r["image"]["base64"].split(",", 1)[-1]))
print("ok", out, "uso", r.get("usage"))

#!/usr/bin/env python3
"""PixelLab v2 generic client. Usage from Python:
    from pl import post, img, save
    r = post("/create-image-pixflux", {...})          # sync endpoints return the result
    r = post("/generate-with-style-v2", {...})        # async ones are polled until done
Images: img(path) builds the base64 object; save(obj, path) writes a returned image.
CLI: pl.py ENDPOINT body.json OUT_PREFIX"""
import base64, json, os, sys, time, urllib.request

API = "https://api.pixellab.ai/v2"

def _req(method, path, body=None):
    hd = {"Content-Type": "application/json"}
    if os.environ.get("PIXELLAB_API_KEY"):
        hd["Authorization"] = "Bearer " + os.environ["PIXELLAB_API_KEY"]
    rq = urllib.request.Request(API + path, method=method, headers=hd,
                                data=json.dumps(body).encode() if body is not None else None)
    try:
        return json.load(urllib.request.urlopen(rq, timeout=300))
    except urllib.error.HTTPError as e:
        raise SystemExit(f"HTTP {e.code} {path}: {e.read().decode()[:600]}")

def img(path):
    return {"type": "base64", "base64": "data:image/png;base64," + base64.b64encode(open(path, "rb").read()).decode()}

def _size(path):
    import struct
    with open(path, "rb") as f:
        f.read(16)
        return struct.unpack(">II", f.read(8))

def ref(path, usage=None):
    """reference/style image for /generate-image-v2"""
    w, h = _size(path)
    r = {"image": img(path), "size": {"width": w, "height": h}}
    if usage:
        r["usage_description"] = usage
    return r

def style(path):
    """style image for /generate-with-style-v2"""
    w, h = _size(path)
    return {"image": img(path), "width": w, "height": h}

def save(obj, path):
    b = obj["base64"] if isinstance(obj, dict) else obj
    open(path, "wb").write(base64.b64decode(b.split(",", 1)[-1]))

def post(path, body):
    r = _req("POST", path, body)
    jid = r.get("background_job_id") or r.get("job_id")
    if not jid or r.get("image") or r.get("images"):
        return r
    while True:
        time.sleep(3)
        j = _req("GET", f"/background-jobs/{jid}")
        st = j.get("status")
        if st in ("completed", "succeeded", "done"):
            return j.get("last_response") or j.get("result") or j
        if st in ("failed", "error", "cancelled"):
            raise SystemExit(f"job failed: {json.dumps(j)[:600]}")

def images_of(r):
    if r.get("image"):
        return [r["image"]]
    return r.get("images") or []

if __name__ == "__main__":
    ep, bodyf, out = sys.argv[1:4]
    r = post(ep, json.load(open(bodyf)))
    ims = images_of(r)
    for i, im in enumerate(ims):
        save(im, f"{out}_{i}.png")
    print("ok", len(ims), "imagens", r.get("usage"))

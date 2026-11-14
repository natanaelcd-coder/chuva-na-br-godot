#!/usr/bin/env python3
"""Retro Diffusion v2: rd.py OUT.png STYLE W H "prompt" [--ref ref.png] [--init img.png --strength 0.5] [--seed N] [--bg]
The key comes from RETRODIFFUSION_API_KEY or is injected by the session's network secrets."""
import base64, json, os, sys, time, uuid, urllib.request

API = "https://api.retrodiffusion.ai/v2"

def call(method, path, body=None):
    h = {"Content-Type": "application/json"}
    if os.environ.get("RETRODIFFUSION_API_KEY"):
        h["X-RD-Token"] = os.environ["RETRODIFFUSION_API_KEY"]
    if body is not None and not body.get("check_cost"):
        h["Idempotency-Key"] = str(uuid.uuid4())
    req = urllib.request.Request(API + path, method=method, headers=h,
                                 data=json.dumps(body).encode() if body is not None else None)
    try:
        return json.load(urllib.request.urlopen(req, timeout=60))
    except urllib.error.HTTPError as e:
        sys.exit(f"HTTP {e.code}: {e.read().decode()[:400]}")

def main():
    a = sys.argv[1:]
    out, style, w, hgt, prompt = a[0], a[1], int(a[2]), int(a[3]), a[4]
    body = {"prompt": prompt, "prompt_style": style, "width": w, "height": hgt, "num_images": 1}
    if "--ref" in a:
        body["reference_images"] = [base64.b64encode(open(a[a.index("--ref") + 1], "rb").read()).decode()]
    if "--seed" in a:
        body["seed"] = int(a[a.index("--seed") + 1])
    if "--init" in a:
        body["input_image"] = base64.b64encode(open(a[a.index("--init") + 1], "rb").read()).decode()
        body["strength"] = float(a[a.index("--strength") + 1]) if "--strength" in a else 0.5
    if "--bg" in a:
        body["remove_bg"] = True
    r = call("POST", "/inferences", body)
    tid = r["task_id"]
    while True:
        time.sleep(2)
        t = call("GET", f"/inferences/tasks/{tid}")
        if t["status"] == "succeeded":
            res = t["result"]
            if res.get("base64_images"):
                open(out, "wb").write(base64.b64decode(res["base64_images"][0]))
            else:
                urllib.request.urlretrieve(res["output_urls"][0], out)
            print(f"ok {out}  custo {res.get('balance_cost')}  saldo {res.get('remaining_balance')}")
            return
        if t["status"] == "failed":
            sys.exit(f"falhou: {t.get('error')}")

main()

#!/usr/bin/env python3
"""ElevenLabs:
  eleven.py tts OUT.mp3 VOICE_ID "texto"   [--model eleven_multilingual_v2]
  eleven.py sfx OUT.mp3 SECONDS "description" [--loop]
The key comes from ELEVENLABS_API_KEY or is injected by the session's network secrets."""
import json, os, sys, urllib.request

def post(path, body):
    hd = {"Content-Type": "application/json", "Accept": "audio/mpeg"}
    if os.environ.get("ELEVENLABS_API_KEY"):
        hd["xi-api-key"] = os.environ["ELEVENLABS_API_KEY"]
    req = urllib.request.Request("https://api.elevenlabs.io" + path, data=json.dumps(body).encode(), headers=hd, method="POST")
    try:
        return urllib.request.urlopen(req, timeout=180).read()
    except urllib.error.HTTPError as e:
        sys.exit(f"HTTP {e.code}: {e.read().decode()[:400]}")

a = sys.argv[1:]
kind, out = a[0], a[1]
if kind == "tts":
    model = a[a.index("--model") + 1] if "--model" in a else "eleven_multilingual_v2"
    data = post(f"/v1/text-to-speech/{a[2]}?output_format=mp3_44100_128",
                {"text": a[3], "model_id": model, "language_code": "pt",
                 "voice_settings": {"stability": 0.45, "similarity_boost": 0.8, "style": 0.35}})
else:
    data = post("/v1/sound-generation?output_format=mp3_44100_128",
                {"text": a[3], "duration_seconds": float(a[2]), "prompt_influence": 0.5, "loop": "--loop" in a})
open(out, "wb").write(data)
print("ok", out, len(data), "bytes")

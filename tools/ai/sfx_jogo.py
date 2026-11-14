#!/usr/bin/env python3
"""Efeitos sonoros do jogo pela ElevenLabs: gera (só o que falta) e trata para o Godot.

    BRUTO=/pasta/dos/mp3 python3 tools/ai/sfx_jogo.py

Os mp3 brutos ficam em BRUTO (fora do git). O tratamento corta o silêncio, recorta o trecho útil, ajusta o nível
para o mix do jogo (o volume de cada som em game.gd foi pensado para os sons antigos) e, nos loops, refaz a emenda
com um crossfade para não ter estalo nem "respiro" a cada volta.
"""
import os, subprocess, sys, wave
import numpy as np

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
AUD = os.path.join(ROOT, "assets/audio")
BRUTO = os.environ.get("BRUTO", os.path.join(ROOT, ".godot", "sfx_bruto"))
SR = 44100

# name: (seconds, prompt, loop, output, treatment)
SONS = {
    "engine": (4, "steady idle of an old air-cooled flat-four car engine heard from inside the cabin, constant rpm, continuous low "
                  "putt-putt rumble, no revving, no gear changes", True, "engine.wav", {"loop_from": 0.5, "xfade": 0.3, "rms": -30}),
    "rain": (10, "steady moderate rain falling on an asphalt road outdoors, continuous even rain ambience, no thunder, no wind gusts",
             True, "rain.ogg", {"loop_from": 0.3, "xfade": 0.5, "rms": -28}),
    "hole": (0.7, "car tire hitting a deep pothole, heavy metallic suspension clunk and thud, single impact", False, "hole.wav", {"peak": -7}),
    "bump": (0.8, "old car driving over a speed bump, soft rubbery suspension thump and body creak, single bump", False, "bump.wav", {"peak": -9}),
    "splash": (1, "car tire driving fast through a puddle, short water splash spray", False, "splash.wav", {"peak": -11}),
    "wiper": (1.2, "single windshield wiper stroke across wet glass, rubber blade swish with a soft squeak, from inside the car", False,
              "wiper.wav", {"cut": (0.08, 1.0), "peak": -20}),
    "horn": (0.6, "short beep of a small old 1960s car horn, single honk", False, "horn.wav", {"peak": -12}),
    "seta": (0.5, "single click of a car turn signal relay, one dry tick, close up", False, "seta.wav", {"cut": (0.06, 0.2), "peak": -4}),
    "land": (1, "car landing hard on the road after a small jump, suspension bottoming out, heavy thud with a short metallic rattle",
             False, "pouso.wav", {"peak": -5}),
    "trovao": (7, "soft distant rolling thunder far away during rain, low gentle rumble, no rain sound", False, "trovao.ogg",
               {"peak": -5, "fade_out": 1.2}),
}
# a chuva no teto do primeiro teste (docs/ia/teste1/chuva_teto.mp3, 10 s, já em loop): só tratada
EXTRA = {"chuva_teto": (os.path.join(ROOT, "docs/ia/teste1/chuva_teto.mp3"), "chuva_teto.ogg", {"loop_from": 0.0, "xfade": 0.0, "rms": -30})}


def load(f):
    raw = subprocess.check_output(["ffmpeg", "-v", "error", "-i", f, "-ac", "1", "-ar", str(SR), "-f", "s16le", "-"])
    return np.frombuffer(raw, np.int16).astype(np.float64) / 32768.0


def db(x):
    return 20 * np.log10(max(x, 1e-9))


def treat(x, t):
    if "cut" in t:
        a, b = t["cut"]
        x = x[int(a * SR):int(b * SR)].copy()
        f = int(0.004 * SR)
        x[:f] *= np.linspace(0, 1, f)
    if "loop_from" in t:   # loop: start past the fade-in, blend the end into what came just before the start
        a = int(t["loop_from"] * SR)
        L = int(t["xfade"] * SR)
        y = x[a:].copy()
        if L > 0 and a >= L:
            k = np.sqrt(np.linspace(0, 1, L))   # equal power
            y[-L:] = y[-L:] * k[::-1] + x[a - L:a] * k
        x = y
        g = t["rms"] - db(np.sqrt((x ** 2).mean()))
    else:
        g = t["peak"] - db(np.abs(x).max())
    x = x * 10 ** (g / 20)
    if "fade_out" in t:
        f = int(t["fade_out"] * SR)
        x[-f:] *= np.linspace(1, 0, f) ** 2
    if "loop_from" not in t:   # one-shots: no click at the end
        f = int(0.01 * SR)
        x[-f:] *= np.linspace(1, 0, f)
    return np.clip(x, -1, 1)


def save(x, out):
    path = os.path.join(AUD, out)
    pcm = (x * 32767).astype("<i2").tobytes()
    if out.endswith(".wav"):
        with wave.open(path, "wb") as w:
            w.setnchannels(1)
            w.setsampwidth(2)
            w.setframerate(SR)
            w.writeframes(pcm)
    else:
        subprocess.run(["ffmpeg", "-v", "error", "-y", "-f", "s16le", "-ar", str(SR), "-ac", "1", "-i", "-", "-c:a", "libvorbis", "-q:a", "5", path],
                       input=pcm, check=True)
    print("ok", out, f"{len(x) / SR:.2f} s")


def main():
    os.makedirs(BRUTO, exist_ok=True)
    for name, (sec, prompt, loop, out, t) in SONS.items():
        raw = os.path.join(BRUTO, name + ".mp3")
        if not os.path.exists(raw):
            subprocess.run([sys.executable, os.path.join(ROOT, "tools/ai/eleven.py"), "sfx", raw, str(sec), prompt] + (["--loop"] if loop else []), check=True)
        save(treat(load(raw), t), out)
    for name, (src, out, t) in EXTRA.items():
        save(treat(load(src), t), out)


if __name__ == "__main__":
    main()

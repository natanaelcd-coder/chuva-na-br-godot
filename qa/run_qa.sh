#!/usr/bin/env bash
# Runs the automated test drive. Metrics headless (fast), screenshots under a virtual display.
set -e
cd "$(dirname "$0")/.."
G=${GODOT:-/tmp/claude-0/-home-user/88bea8a4-b2fd-5024-b1fd-13bcbda578e9/scratchpad/godot/Godot_v4.5.1-stable_linux.x86_64}
timeout 300 "$G" --headless --path . --fixed-fps 60 --script res://tests/test_drive.gd > /dev/null 2> qa/metrics/stderr.txt || true
cp qa/metrics/latest.json qa/metrics/metrics.json
timeout 600 xvfb-run -a -s "-screen 0 1600x900x24" "$G" --path . --fixed-fps 60 --rendering-driver opengl3 --audio-driver Dummy \
  --script res://tests/test_drive.gd -- --shots-only > /dev/null 2>> qa/metrics/stderr.txt || true
mv qa/metrics/metrics.json qa/metrics/latest.json
python3 - <<'PY'
import json, os
m = json.load(open("qa/metrics/latest.json"))
if os.path.exists("qa/shots/visibility.json"):
    v = json.load(open("qa/shots/visibility.json"))
    lc = {x["speed_kmh"]: x["time_to_target_s"] for x in m.get("lane_change", [])}
    for c in v["cams"].values():
        c["margin_70kmh_s"] = round(c["lead_time_70kmh_s"] - lc.get(70.0, 0), 2)
        c["margin_95kmh_s"] = round(c["lead_time_95kmh_s"] - lc.get(95.0, 0), 2)
    m["visibility_rendered"] = v
json.dump(m, open("qa/metrics/latest.json", "w"), indent=2)
PY
grep -E "SCRIPT ERROR|Parse Error" qa/metrics/stderr.txt && exit 1
echo "metrics: qa/metrics/latest.json  shots: qa/shots/"

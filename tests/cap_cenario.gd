extends SceneTree
# Captures of the scenery (sky, horizon) for road/time/weather/camera combinations, and of the stops and title screen.
#   xvfb-run -a godot --path . --fixed-fps 60 --rendering-driver opengl3 --audio-driver Dummy --script res://tests/cap_cenario.gd -- <dir> [road:time:weather:cam[:stop] ...]
const MAIN := preload("res://main.tscn")
var out := "/tmp"

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() > 0:
		out = a[0]
	var combos: Array = []
	for i in range(1, a.size()):
		combos.append(a[i])
	if combos.is_empty():
		for r in ["terra", "br", "expressa"]:
			for t in ["dia", "entardecer", "noite"]:
				for w in ["sol", "chuva"]:
					combos.append("%s:%s:%s:1" % [r, t, w])
	Engine.set_meta("test_seed", 5)
	var g = MAIN.instantiate()
	root.add_child(g)
	await process_frame
	for cb in combos:
		var p: PackedStringArray = String(cb).split(":")
		g.cfg = {"car": "besouro", "road": p[0], "weather": p[2], "time": p[1]}
		g.setup()
		g.begin()
		g.set_cam(int(p[3]))
		g.set_auto(true)
		g.hud.toast_t = 0.0
		g.pos = 40.0 * g.SEG
		for f in 4:
			await process_frame
		if p.size() > 4:   # a fifth field: "stop" plants the stop building of the road a few segments ahead (the real ones come with the dressing)
			var k0 := int(g.pos / g.SEG) + 34
			g.segs[k0 % g.N].spr.append({"tex": g.tex[g.road.stop], "off": 2.75, "ww": g.ww_fit(g.road.stop, g.road.stop_ww), "kind": 3, "name": g.road.stop})
		for f in (12 if p.size() > 4 else 50):
			await process_frame
		root.get_texture().get_image().save_png("%s/%s_%s_%s_c%s%s.png" % [out, p[0], p[1], p[2], p[3], "_parada" if p.size() > 4 else ""])
	print("done ", combos.size())
	quit()

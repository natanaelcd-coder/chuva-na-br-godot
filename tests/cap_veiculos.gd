extends SceneTree
# Captures of the roadside stops (posto, venda) and of the motorbike and van in traffic.
#   xvfb-run -a godot --path . --fixed-fps 60 --rendering-driver opengl3 --audio-driver Dummy --script res://tests/cap_veiculos.gd -- <dir> [tempo] [clima]
const MAIN := preload("res://main.tscn")
var out := "/tmp"

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() > 0:
		out = a[0]
	var tm: String = a[1] if a.size() > 1 else "dia"
	var wx: String = a[2] if a.size() > 2 else "sol"
	Engine.set_meta("test_seed", 5)
	var g = MAIN.instantiate()
	root.add_child(g)
	await process_frame
	for road in ["terra", "br", "expressa"]:
		g.cfg = {"car": "besouro", "road": road, "weather": wx, "time": tm}
		g.setup()
		g.begin()
		g.set_cam(1)
		g.set_auto(true)
		g.hud.toast_t = 0.0
		await process_frame
		await process_frame
		# the stop, a few segments ahead
		if road != "expressa":
			var stop: String = g.road.stop
			var est = g.get_node("estrada")
			var sa: int = est.stops[0].a
			while est.cursor < sa + 5:   # drive on, a few hundred segments a frame, until the feature has dressed the stop
				g.pos = fmod(g.pos + 300.0 * g.SEG, g.TRACK)
				await process_frame
			g.pos = float(posmod(sa - 13, g.N)) * g.SEG
			var names := []
			for d in range(-3, 4):
				for q in g.segs[posmod(sa + d, g.N)].spr:
					names.append("%d:%s@%.2f" % [d, q.name, q.off])
			print(road, " stop at ", sa, " ", names)
			for f in 12:
				await process_frame
			root.get_texture().get_image().save_png("%s/%s_%s_%s_%s.png" % [out, road, tm, wx, stop])
		# each kind of motorbike or van: the player behind it (our side) or facing it (oncoming)
		var seen := {}
		for c in g.cars:
			var n := ""
			for k in g.tex.keys():
				if g.tex[k] == c.tex:
					n = k
			if not (n.contains("moto") or n.contains("van")) or seen.has(n):
				continue
			seen[n] = true
			g.pos = fposmod(c.z - (950.0 if c.dir > 0 else 2300.0), g.TRACK)
			g.px = c.x if c.dir > 0 else g.LANES[g.lane]
			g.v = 0.0
			for f in 6:
				await process_frame
			root.get_texture().get_image().save_png("%s/%s_%s_%s_%s.png" % [out, road, tm, wx, n])
		print(road, " ", seen.keys())
	quit()

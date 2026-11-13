extends SceneTree
# Drives every car on every road, in sun and in rain: 40 s on autopilot, then 30 s of a keyboard
# driver weaving between lanes. Reports bumps, potholes, time off the road and speed.
#   godot --headless --path . --fixed-fps 60 --script res://tests/combos.gd
const MAIN := preload("res://main.tscn")
const Cat = preload("res://scripts/catalog.gd")

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var rows := []
	for road in Cat.ROAD_IDS:
		for car in Cat.CAR_IDS:
			for wx in Cat.WEATHER_IDS:
				Engine.set_meta("test_seed", 11)
				var g = MAIN.instantiate()
				root.add_child(g)
				await process_frame
				g.cfg = {"car": car, "road": road, "weather": wx, "time": "dia"}
				g.setup()
				g.begin()
				g.set_auto(true)
				var vs := 0.0
				var n := 0
				for i in 2400:
					await process_frame
					vs += g.v
					n += 1
				var a_b: int = g.n_bumps
				var a_h: int = g.n_holes
				g.set_auto(false)
				g.target = minf(90.0, g.car.top)
				var off := 0.0
				var bad := false
				for i in 1800:   # weave: two seconds in one lane, two in the next
					var want: float = g.LANES[(i / 120) % g.LANES.size()]
					g.bot_steer = clampf((want - g.px) * 5.0 - g.vx * 1.5, -1.0, 1.0)
					g.bot_steer = 0.0 if absf(g.bot_steer) < 0.2 else signf(g.bot_steer)
					await process_frame
					if absf(g.px) > 1.02:
						off += 1.0 / 60.0
					if is_nan(g.px) or is_nan(g.zb) or is_nan(g.v):
						bad = true
				rows.append("%-9s %-8s %-6s | auto: bumps %d holes %d avg %3d km/h | weave: bumps %d holes %d offroad %.1fs v %3d %s" % [
					road, car, wx, a_b, a_h, int(vs / n), g.n_bumps - a_b, g.n_holes - a_h, off, int(g.v), "NaN!" if bad else ""])
				g.queue_free()
				await process_frame
	for r in rows:
		print(r)
	quit()

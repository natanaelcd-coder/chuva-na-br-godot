extends SceneTree
# Checks the "Estrada" feature (scripts/features/estrada.gd) on the three roads and takes screenshots.
#   checks:   godot --headless --path . --fixed-fps 60 --script res://tests/feat_estrada.gd
#   + images: xvfb-run godot --path . --fixed-fps 60 --script res://tests/feat_estrada.gd -- <out_dir>
# - the same test_seed gives the same road after several laps (determinism)
# - the road is dressed again behind the car: a stretch is different the next time around
# - fuel stops come by distance; the autopilot slows for the speed bumps and feels them
# - arriving at the destination
const MAIN := preload("res://main.tscn")
const Cat = preload("res://scripts/catalog.gd")
var out := ""
var g
var f
var fails := 0

func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() > 0:
		out = a[0]
	_run.call_deferred()

func step(n: int) -> void:
	for i in n:
		await process_frame

func check(ok: bool, what: String) -> void:
	print(("  ok   " if ok else "  FAIL ") + what)
	if not ok:
		fails += 1

func make(road: String, wx := "chuva", tm := "entardecer", car := "besouro") -> void:
	Engine.set_meta("test_seed", 5)
	g = MAIN.instantiate()
	root.add_child(g)
	await process_frame
	g.cfg = {"car": car, "road": road, "weather": wx, "time": tm}
	g.setup()
	f = g.get_node("estrada")

func drop() -> void:
	g.queue_free()
	await step(2)

# move the car forward n segments, a few hundred per frame, so the dressing keeps up out of sight
func ff(n: int) -> void:
	while n > 0:
		var k := mini(n, 300)
		g.pos = fmod(g.pos + k * g.SEG, g.TRACK)
		n -= k
		await process_frame

func to_abs(a: int) -> void:
	await ff(a - f.abs_c)

func digest() -> String:
	var parts: PackedStringArray = []
	for s in g.segs:
		for q in s.spr:
			parts.append("%s%.3f" % [q.name, q.off])
		for e in s.feat:
			parts.append("%d%.3f" % [e.t, e.x])
		parts.append("%.2f" % s.curve)
	return str(hash("".join(parts)))

func window_names(a: int, b: int) -> String:
	var parts: PackedStringArray = []
	for i in range(a, b):
		for q in g.segs[i % g.N].spr:
			parts.append(q.name)
	return ",".join(parts)

func shot(name: String) -> void:
	if out == "":
		return
	await step(2)
	root.get_texture().get_image().save_png("%s/%s.png" % [out, name])

func _run() -> void:
	for road in ([] if OS.get_cmdline_user_args().has("--shots-only") else Cat.ROAD_IDS):
		print(road)
		# determinism
		var ds: Array = []
		for k in 3:
			await make(road)
			g.set_process(false)   # only the teleports move the car: the same positions every run
			await ff(g.N * 3 + 500)
			ds.append(digest())
			await drop()
		check(ds[0] == ds[1] and ds[1] == ds[2], "same seed, same road after 3 laps %s" % str(ds))
		# the road does not repeat
		await make(road)
		var before := window_names(400, 700)
		await ff(g.N + 20)
		var cs: int = f.cursor
		check(cs >= g.N + 20 + g.N - 200 - 1, "dressing cursor follows the car (%d)" % cs)
		check(window_names(400, 700) != before, "a stretch looks different on the next lap")
		# stops by distance
		var st: Array = []
		var in_view := 0
		var listed := 0
		var plen := 0
		for k in 40:
			for s in f.stops:
				if s.a <= f.cursor and s.a > f.cursor - g.N:
					in_view += 1
					listed += 1 if g.postos.has(s.a % g.N) else 0
			plen += g.postos.size()
			for s in f.stops:
				var km := snappedf(s.a / f.SEGS_KM, 0.1)
				if not st.has(km):
					st.append(km)
			await ff(500)
		var gap_ok := st.size() >= 3
		for k in range(1, st.size()):
			gap_ok = gap_ok and st[k] - st[k - 1] >= 3.9
		check(gap_ok, "stops by distance, km %s" % str(st))
		check(in_view > 0 and listed == in_view and plen == in_view, "postos lists the stops on the dressed lap (%d/%d/%d)" % [listed, in_view, plen])
		var names := []
		for t in f.towns:
			names.append("%s@%.1f" % [t.name, t.a / f.SEGS_KM])
		print("  towns: ", names)
		await drop()
		# drive through the first town on autopilot: slows for the bumps and feels them
		await make(road)
		g.begin()
		g.set_auto(true)
		var t0: Dictionary = f.towns[0]
		await to_abs(t0.a - 330)
		await step(20)
		var b0: int = g.n_bumps
		g.bumped.connect(func(k): print("    bumped: ", k, " v ", int(g.v)))
		g.v = 70.0
		g.target = 70.0
		var vmin := 999.0
		var zmax := 0.0
		var bump_v: Array = []
		var prev_i: int = int(g.pos / g.SEG) % g.N
		var shot_done := false
		for i in 1500:
			await process_frame
			var ci: int = int(g.pos / g.SEG) % g.N
			if ci != prev_i:
				for e in g.segs[ci].feat:
					if e.t == 3:
						bump_v.append(int(g.v))
				prev_i = ci
			if f.abs_c > t0.a and f.abs_c < t0.a + t0.len:
				vmin = minf(vmin, g.v)
				zmax = maxf(zmax, absf(g.zb_v))
			if not shot_done and f.abs_c >= t0.a - 60:
				shot_done = true
				if road != "expressa":
					g.set_cam(1)
					await shot("town_%s_chase" % road)
					g.set_cam(0)
					await shot("town_%s_cockpit" % road)
			if out != "" and road != "expressa" and f.abs_c >= t0.a + 24 and f.abs_c < t0.a + 26:
				g.set_cam(1)
				await shot("bump_%s_chase" % road)
				g.set_cam(0)
			if f.abs_c > t0.a + t0.len + 40:
				break
		if road != "expressa":
			check(bump_v.size() == 2 and bump_v.max() <= 40, "autopilot over the bumps at %s km/h" % str(bump_v))
			check(zmax > 150.0, "the bump is felt in the suspension (zb_v %d)" % int(zmax))
		check(g.n_bumps == b0, "no bumps into traffic in town")
		await drop()
	await shots()
	print("FAILS: %d" % fails)
	quit(1 if fails > 0 else 0)

func shots() -> void:
	# a distance sign close up and far, on each road
	for road in Cat.ROAD_IDS:
		await make(road, "sol", "dia", "gt" if road == "expressa" else "besouro")
		g.begin()
		g.set_auto(true)
		g.hud.toast_t = 0.0
		await ff(g.N)   # the next sign planned ahead (dressed by the time we get there)
		var a := -1
		for tries in 12:
			for k in f.pending.keys():
				for q in f.pending[k]:
					if (q.name == "placa_km" or q.name == "portico") and (a < 0 or k < a) and k > f.abs_c + 300:
						a = k
			if a >= 0:
				break
			await ff(800)
		if a < 0:
			continue
		await to_abs(a - 120)
		g.set_cam(1)
		await shot("sign_%s_far" % road)
		await to_abs(a - 22)
		g.set_cam(0)
		await shot("sign_%s_near" % road)
		await drop()
	# the next town on the horizon at dusk, then arriving at the destination
	await make("br", "sol", "entardecer")
	f.dest_k = 1
	g.begin()
	g.set_auto(true)
	var t0: Dictionary = f.towns[0]
	await to_abs(t0.a - int(1.2 * f.SEGS_KM))
	g.set_cam(1)
	await step(30)
	await shot("skyline_br")
	await to_abs(t0.a - 30)
	await step(60)
	await shot("arrival_br")
	check(f.dest.is_empty() and f.fw_t > 0.0, "arrived: destination cleared, fireworks on")
	await drop()
	# the destination screen
	await make("terra", "sol", "dia")
	g.menu.show_main()
	f._open_dest()
	await step(5)
	await shot("menu_destino")
	f._dest_key(KEY_DOWN)
	f._dest_key(KEY_ENTER)
	await step(5)
	await shot("menu_main_destino")
	await drop()

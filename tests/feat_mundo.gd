extends SceneTree
# "Mundo vivo" (scripts/features/mundo_*.gd): bumper phrases, the tractor's blinker, roadside events,
# variable weather with rainbow and the seasons. Takes screenshots and prints a few checks.
#   xvfb-run -a -s "-screen 0 1600x900x24" godot --path . --fixed-fps 60 --rendering-driver opengl3 \
#       --audio-driver Dummy --script res://tests/feat_mundo.gd -- <out_dir> [filter]
const MAIN := preload("res://main.tscn")
var out := "/tmp"
var only := ""

func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() > 0:
		out = a[0]
	if a.size() > 1:
		only = a[1]
	_run.call_deferred()

func step(n: int) -> void:
	for i in n:
		await process_frame

func shot(name: String) -> void:
	root.get_texture().get_image().save_png("%s/%s.png" % [out, name])

func make(car: String, road: String, weather: String, time: String, cam: int, epoca := "nenhuma"):
	Engine.set_meta("test_seed", 7)
	Engine.set_meta("mundo_epoca", epoca)
	var g = MAIN.instantiate()
	root.add_child(g)
	await process_frame
	g.cfg = {"car": car, "road": road, "weather": weather, "time": time}
	g.setup()
	g.begin()
	g.set_cam(cam)
	g.set_auto(true)
	g.hud.toast_t = 0.0
	return g

func feat(g, n: String):
	return g.get_node(n)

func ahead(g, tex: String, d: float, x: float, v: float) -> Dictionary:
	var c := {"z": fposmod(g.pos + d, g.TRACK), "x": x, "v": v, "tex": g.tex[tex], "dir": 1}
	g.cars.append(c)
	return c

func clear_near(g, dist: float) -> void:   # keep the stretch ahead free of other traffic
	for c in g.cars.duplicate():
		var d: float = fposmod(c.z - g.pos, g.TRACK)
		if d < dist or d > g.TRACK - 4000.0:
			g.cars.erase(c)

func want(n: String) -> bool:
	return only == "" or n.begins_with(only)

func _run() -> void:
	if want("frases"):
		for cam in [0, 1]:
			for d in [5200.0, 2600.0, 1300.0]:
				var g = await make("besouro", "br", "chuva", "entardecer", cam)
				clear_near(g, 40000.0)
				g.px = g.LANES[1]
				g.lane = 1
				ahead(g, "car7", d, g.LANES[1], g.v)
				ahead(g, "onibus", d + 900.0, g.LANES[2], g.v)
				await step(3)
				for c in g.cars:
					if c.has("seta_d") == false and c.x == g.LANES[1]:
						c.z = fposmod(g.pos + d, g.TRACK)
				await step(2)
				shot("frases_cam%d_%d" % [cam, int(d)])
				g.queue_free()
				await step(2)
	if want("seta"):
		# 1) behind the tractor, a bit to the left so the chase view shows its blinker
		var g = await make("besouro", "terra", "sol", "dia", 1)
		clear_near(g, 60000.0)
		for c in g.cars:   # push oncoming traffic far away
			if c.dir < 0:
				c.z = fposmod(g.pos - 8000.0, g.TRACK)
		var tr := ahead(g, "trator", 2400.0, g.LANES[1], 20.0)
		g.set_auto(false)
		g.target = 40.0
		for i in 150:
			g.px = 0.22
			g.vx = 0.0
			await process_frame
		print("seta: blink_t %.1f" % tr.get("blink_t", 0.0))
		for i in 60:
			await process_frame
			if fmod(g.t, 0.8) < 0.3:
				break
		shot("seta_piscando")
		g.queue_free()
		await step(2)
		# 2) the autopilot comes up from far behind and overtakes while it blinks
		g = await make("besouro", "terra", "sol", "dia", 1)
		clear_near(g, 60000.0)
		for c in g.cars:
			if c.dir < 0:
				c.z = fposmod(g.pos - 8000.0, g.TRACK)
		tr = ahead(g, "trator", 9000.0, g.LANES[1], 20.0)
		var blinked := false
		for i in 1500:
			await process_frame
			blinked = blinked or tr.get("blink_t", 0.0) > 0.0
			if feat(g, "mundo_seta").thanks > 0:
				break
		print("seta: piscou %s, agradecimentos %d, batidas %d" % [blinked, feat(g, "mundo_seta").thanks, g.n_bumps])
		await step(20)
		shot("seta_agradeceu")
		g.queue_free()
		await step(2)
	if want("clima"):
		for ph in [["sol", "dia"], ["nublando", "dia"], ["pancada", "dia"], ["garoa", "dia"], ["arco", "dia"], ["arco", "entardecer"]]:
			var g = await make("picape", "terra", "variavel", ph[1], 0)
			var cl = feat(g, "mundo_clima")
			cl.force(ph[0])
			await step(600 if ph[0] == "nublando" else 240)
			print("clima %s: rain %.2f sky %.2f wet %.2f bow %.2f" % [ph[0], g.rain, g.sky_k, g.wet_k, cl.bow])
			shot("clima_%s_%s" % [ph[0], ph[1]])
			g.set_cam(1)
			await step(4)
			shot("clima_%s_%s_ext" % [ph[0], ph[1]])
			g.queue_free()
			await step(2)
		# a whole shower cycle, sped up: no NaN, rain comes and goes
		var g = await make("besouro", "br", "variavel", "dia", 0)
		var cl = feat(g, "mundo_clima")
		var mx := 0.0
		var seen := {}
		for i in 60 * 400:
			if i % 3 == 0:
				cl.phase_t -= 1.0
			await process_frame
			mx = maxf(mx, g.rain)
			seen[cl.phase] = true
		print("clima ciclo: max rain %.2f phases %s bumps %d nan %s" % [mx, seen.keys(), g.n_bumps, is_nan(g.px)])
		g.queue_free()
		await step(2)
	if want("eventos"):
		var list := [["boiada", "terra", "dia"], ["carroca", "terra", "entardecer"], ["cavalo", "terra", "dia"], ["romeiros", "terra", "dia"],
			["pamonha", "terra", "dia"], ["carro_som", "br", "entardecer"], ["quermesse", "terra", "noite"], ["ciclista", "br", "dia"],
			["caramelo", "br", "dia"], ["borracharia", "br", "noite"], ["led", "expressa", "dia"], ["helicoptero", "expressa", "dia"],
			["balao", "br", "dia"], ["periquitos", "terra", "dia"], ["vagalumes", "terra", "noite"]]
		for e in list:
			if only.begins_with("eventos_") and only != "eventos_" + e[0]:
				continue
			var g = await make("besouro", e[1], "sol", e[2], 0)
			clear_near(g, 30000.0)
			var ev = feat(g, "mundo_eventos")
			ev.start(e[0])
			var best := 1e9
			for i in 60 * 40:   # drive until it is close
				await process_frame
				var d: float = ev.distance()
				if d < 2600.0 or (d > 1e8 and i > 300):
					break
			shot("evento_%s" % e[0])
			g.set_cam(1)
			await step(3)
			shot("evento_%s_ext" % e[0])
			for i in 60 * 50:
				await process_frame
				if not ev.active():
					break
			print("evento %s: ainda ativo %s, batidas %d, carros %d" % [e[0], ev.active(), g.n_bumps, g.cars.size()])
			g.queue_free()
			await step(2)
	if want("epoca"):
		for e in [["ipes", "terra", "dia"], ["ipes", "br", "dia"], ["junina", "terra", "noite"], ["junina", "br", "entardecer"],
				["natal", "terra", "noite"], ["natal", "br", "noite"], ["natal", "expressa", "noite"], ["verao", "terra", "dia"]]:
			var g = await make("besouro", e[1], "sol", e[2], 0, e[0])
			await step(200)
			shot("epoca_%s_%s_%s" % [e[0], e[1], e[2]])
			g.set_cam(1)
			await step(4)
			shot("epoca_%s_%s_%s_ext" % [e[0], e[1], e[2]])
			g.queue_free()
			await step(2)
		var g = await make("besouro", "br", "chuva", "entardecer", 0)
		g.to_menu()
		g.menu.extra_sel = 0
		await step(2)
		var ep = feat(g, "mundo_epoca")
		ep.open()
		await step(3)
		shot("epoca_menu")
		g.queue_free()
		await step(2)
	quit()

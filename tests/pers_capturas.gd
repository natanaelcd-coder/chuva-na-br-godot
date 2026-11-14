extends SceneTree
# Captures of the PixelLab characters and animals: stops (venda/posto/loja), vó and caramelo in the three cabins,
# the bus stop and the people of the town, the herd; plus a frame strip that proves the animation.
#   xvfb-run godot --path . --fixed-fps 60 --rendering-driver opengl3 --audio-driver Dummy --script res://tests/pers_capturas.gd -- <dir> [only]
const MAIN := preload("res://main.tscn")
var out := "/tmp"
var only := ""
var g

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
	await step(2)
	root.get_texture().get_image().save_png("%s/%s.png" % [out, name])

func crop_shot(name: String, r: Rect2i, strip := 1) -> void:
	await step(2)
	root.get_texture().get_image().get_region(r).save_png("%s/%s.png" % [out, name])

func make(car: String, road: String, wx: String, tm: String, seed_ := 5) -> void:
	if g:
		g.queue_free()
		await step(2)
	Engine.set_meta("test_seed", seed_)
	g = MAIN.instantiate()
	root.add_child(g)
	await process_frame
	g.cfg = {"car": car, "road": road, "weather": wx, "time": tm}
	g.setup()

func want(n: String) -> bool:
	return only == "" or only == n

func _run() -> void:
	if want("parada"):
		for r in [["terra", "venda"], ["br", "posto"], ["expressa", "loja"]]:
			await make("besouro", r[0], "chuva", "entardecer")
			g.begin()
			var par = g.get_node("parada")
			par.enter(0)
			par.order(par.menu_ids[0])
			await step(50)
			await shot("parada_%s" % r[1])
			if r[1] == "posto":   # strip of the people over one animation loop
				var imgs: Array = []
				for k in 6:
					await step(14)
					imgs.append(root.get_texture().get_image().get_region(Rect2i(0, 150, 768, 200)))
				var s := Image.create(768, 200 * 3, false, Image.FORMAT_RGBA8)
				for k in 3:
					s.blit_rect(imgs[k * 2], Rect2i(0, 0, 768, 200), Vector2i(0, k * 200))
				s.save_png(out + "/tira_parada_posto.png")
	if want("cabine"):
		for car in ["besouro", "picape", "gt"]:
			for who in ["vo", "caramelo"]:
				await make(car, "br", "chuva", "entardecer")
				g.begin()
				g.set_cam(0)
				var p = g.get_node("passageiro")
				while p.who != who:
					p._cycle()
				p.set_process(false)
				var imgs: Array = []
				for st in [[0.0, 0.0], [0.45, 0.0], [1.0, 0.0], [0.0, 0.9]]:
					p.sleep = st[0]
					p.startle = st[1]
					p.blink_t = 2.0
					await step(6)
					root.get_texture().get_image().save_png("%s/cab_%s_%s_%d.png" % [out, who, car, int(st[0] * 10 + st[1] * 10)])
					imgs.append(root.get_texture().get_image().get_region(Rect2i(560, 150, 208, 190)))
				if car == "besouro":
					var s := Image.create(208 * 4, 190, false, Image.FORMAT_RGBA8)
					for k in 4:
						s.blit_rect(imgs[k], Rect2i(0, 0, 208, 190), Vector2i(k * 208, 0))
					s.save_png("%s/tira_%s.png" % [out, who])
	if want("cidade"):
		await make("besouro", "br", "sol", "dia")
		var f = g.get_node("estrada")
		g.begin()
		g.set_auto(true)
		var t0: Dictionary = f.towns[0]
		var n: int = t0.a + 10 - f.abs_c
		while n > 0:
			var k := mini(n, 300)
			g.pos = fmod(g.pos + k * g.SEG, g.TRACK)
			n -= k
			await process_frame
		var gi := -1   # the nearest ahead of the town's people / bus stop on the dressed lap
		for d in range(5, 300):
			for q in g.segs[(int(g.pos / g.SEG) + d) % g.N].spr:
				if q.name.begins_with("gente") or q.name == "ponto_onibus":
					gi = d
					break
			if gi >= 0:
				break
		print("cidade: pessoa/ponto a ", gi, " segmentos")
		if gi > 14:
			g.pos = fmod(g.pos + (gi - 14) * g.SEG, g.TRACK)
		g.v = 8.0
		g.target = 8.0
		g.set_cam(1)
		await step(30)
		await shot("cidade_ponto")
		await step(25)
		await shot("cidade_ponto_b")
		g.set_cam(0)
		await step(10)
		await shot("cidade_ponto_cab")
	if want("boiada"):
		await make("besouro", "terra", "sol", "dia", 7)
		g.begin()
		g.set_auto(true)
		for c in g.cars.duplicate():
			var d: float = fposmod(c.z - g.pos, g.TRACK)
			if d < 30000.0 or d > g.TRACK - 4000.0:
				g.cars.erase(c)
		var ev = g.get_node("mundo_eventos")
		ev.start("boiada")
		for i in 60 * 40:
			await process_frame
			if ev.distance() < 900.0:
				break
		g.set_cam(1)
		await step(5)
		await shot("boiada_a")
		await step(40)
		await shot("boiada_b")
	quit()

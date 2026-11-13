extends SceneTree
# Coleção (ideias 1, 5 e 7): hodômetro, caderneta de figurinhas e penduricalhos da cabine.
# Drives a while on each road to see stickers being collected, then takes screenshots of the HUD, the cabin prizes
# in every car, the CADERNETA and CABINE screens, the menu line and the pause list.
#   godot --headless --path . --fixed-fps 60 --script res://tests/feat_colecao.gd -- collect   (drives and prints)
#   xvfb-run godot --path . --fixed-fps 60 --rendering-driver opengl3 --script res://tests/feat_colecao.gd -- <out_dir>
const MAIN := preload("res://main.tscn")
var out := "/tmp"
var collect := false

func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() > 0:
		out = a[0]
		collect = a[0] == "collect"
	_run.call_deferred()

func step(n: int) -> void:
	for i in n:
		await process_frame

func shot(name: String) -> void:
	await step(2)
	root.get_texture().get_image().save_png("%s/%s.png" % [out, name])

func _game(cfg: Dictionary):
	Engine.set_meta("test_seed", 7)
	var g = MAIN.instantiate()
	root.add_child(g)
	await process_frame
	g.cfg = cfg
	g.setup()
	g.menu.show_main()
	return g

func _run() -> void:
	if not collect:
		_shots()
		return
	# 1) collecting while driving on autopilot, every road
	for road in ["terra", "br", "expressa"]:
		var g = await _game({"car": "besouro", "road": road, "weather": "chuva" if road != "expressa" else "sol", "time": "ciclo"})
		g.begin()
		g.set_auto(true)
		await step(60 * 120)
		var cad = g.get_node("caderneta")
		print("%s: %.1f km, odometer %.2f, stickers %s, page %s" % [road, g.km_trip, g.get_node("hodometro").car_km(), cad.count(), cad.count(road)])
		var missing: Array = []
		for s in cad.STICKERS:
			if (s.page == road or s.page == "ceu") and not cad.has(s.id):
				missing.append(s.id)
		print("  missing: ", missing)
		g.queue_free()
		await step(2)
	if collect:
		quit()
		return


func _shots() -> void:
	# 2) HUD + prizes in each cabin
	var g = await _game({"car": "besouro", "road": "br", "weather": "chuva", "time": "entardecer"})
	g.store_set("hodometro", "besouro", 1283.6)
	g.begin()
	await step(120)
	g.hud.toast_t = 0.0
	g.hud.notice("ESTE BESOURO JÁ RODOU 1.000 KM", 5.0)
	await shot("hud_besouro")
	var pen = g.get_node("penduricalhos")
	g.store_set("cabine", "besouro", {"hang": ["cristovao", "cd"], "dash": "aparecida"})
	pen.apply()
	await step(30)
	await shot("cab_besouro_premios")
	g.store_set("cabine", "besouro", {"hang": ["rosary", "urso"], "dash": "flor"})
	pen.apply()
	g.dice_v += 3.0
	await step(20)
	await shot("cab_besouro_premios2")
	for car in ["picape", "gt"]:
		g.cfg.car = car
		g.setup()
		g.set_cam(0)
		g.store_set("cabine", car, {"hang": ["bonfim", "flamula"] if car == "picape" else ["figa", "pine"], "dash": "dog" if car == "picape" else "aparecida"})
		pen.apply()
		await step(40)
		await shot("cab_%s_premios" % car)

	# 3) the screens
	var cad = g.get_node("caderneta")
	var n := 0
	for s in cad.STICKERS:
		n += 1
		if n % 3 != 0:
			g.store_set("caderneta", s.id, true)
	g.store_set("hodometro", "gt", 40.0)
	g.pause()
	await step(3)
	await shot("pausa")
	cad.open()
	await step(3)
	await shot("caderneta_terra")
	cad._key(KEY_E)
	cad._key(KEY_RIGHT)
	cad._key(KEY_DOWN)
	await shot("caderneta_br")
	cad._key(KEY_E)
	cad._key(KEY_E)
	cad._key(KEY_DOWN)
	cad._key(KEY_DOWN)
	await shot("caderneta_ceu")
	g.menu.close_screen()
	await step(2)
	pen.open()
	pen._key(KEY_DOWN)
	pen._key(KEY_DOWN)
	pen._key(KEY_DOWN)
	pen._key(KEY_DOWN)
	await step(30)
	await shot("cabine_gt")
	pen._key(KEY_E)
	pen._key(KEY_DOWN)
	pen._key(KEY_ENTER)
	await step(30)
	await shot("cabine_besouro")
	g.menu.close_screen()
	g.to_menu()
	g.cfg.car = "besouro"
	g.setup()
	g.menu.show_main()
	await step(10)
	await shot("menu")
	quit()

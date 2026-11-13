extends SceneTree
# Paradas e memórias: the stop scene, the dozing passenger, photo mode and the postcard / diary.
#   xvfb-run godot --path . --fixed-fps 60 --rendering-driver opengl3 --audio-driver Dummy --script res://tests/feat_paradas.gd -- <out_dir>
const MAIN := preload("res://main.tscn")
var out := "/tmp"
var g
var fails: Array = []

func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() > 0:
		out = a[0]
	_run.call_deferred()

func step(n: int) -> void:
	for i in n:
		await process_frame

func shot(name: String) -> void:
	await step(2)
	root.get_texture().get_image().save_png("%s/%s.png" % [out, name])

func check(ok: bool, what: String) -> void:
	print(("ok   " if ok else "FAIL ") + what)
	if not ok:
		fails.append(what)

func make(car: String, road: String, wx: String, tm: String) -> void:
	if g:
		g.queue_free()
		await step(2)
	Engine.set_meta("test_seed", 5)
	Engine.set_meta("feat_paradas", true)
	Engine.set_meta("foto_dir", out + "/fotos")
	g = MAIN.instantiate()
	root.add_child(g)
	await process_frame
	g.cfg = {"car": car, "road": road, "weather": wx, "time": tm}
	g.setup()
	g.menu.show_main()

func companion(who: String) -> void:
	var p = g.get_node("passageiro")
	while p.who != who:
		p._cycle()

func _run() -> void:
	# --- menu with the new items, and the passenger in the cabin preview
	await make("besouro", "br", "chuva", "entardecer")
	companion("vo")
	await step(30)
	await shot("menu")
	check(g.menu.extras.size() >= 2, "menu has DIÁRIO and COMPANHIA")

	# --- the vó dozes off with smooth driving and wakes on a pothole
	g.begin()
	g.set_auto(true)
	g.set_cam(0)
	g.clean = 120.0
	await step(30 * 60)
	var pas = g.get_node("passageiro")
	check(pas.sleep > 0.8, "vó asleep after smooth driving (sleep %.2f)" % pas.sleep)
	g.hud.toast_t = 0.0
	await shot("cab_vo_dormindo")
	pas._jolt(true)
	await step(6)
	check(pas.sleep < 0.1 and pas.startle > 0.0, "vó wakes up on a jolt")
	await shot("cab_vo_acorda")
	g.pause()
	await step(3)
	await shot("pausa_companhia")
	g.resume()

	# --- photo mode: caption band, then polaroid, saved to disk
	g.feature_call("drive_key", [KEY_F])
	check(g.state == "foto", "F enters photo mode")
	var fot = g.get_node("foto")
	await step(4)
	await shot("foto_modo")
	await fot.shoot()
	await step(2)
	check(fot.last_path != "" and FileAccess.file_exists(fot.last_path), "photo saved: %s" % fot.last_path)
	if fot.last_path != "":
		var img := Image.load_from_file(fot.last_path)
		img.save_png(out + "/foto_salva_legenda.png")
	fot.style = 1
	fot._build_frame()
	g.set_cam(1)
	await fot.shoot()
	await step(2)
	if fot.last_path != "":
		Image.load_from_file(fot.last_path).save_png(out + "/foto_salva_polaroid.png")
	fot._leave()
	check(g.state == "drive", "F leaves photo mode")
	g.set_cam(0)

	# --- the stop: natural entry (right lane, slow) on the BR
	var par = g.get_node("parada")
	var p0: int = g.postos[0]
	g.set_auto(false)
	g.pos = (p0 - 20) * g.SEG
	g.px = g.LANES.back()
	g.lane = g.LANES.size() - 1
	g.v = 28.0
	g.target = 28.0
	for i in 400:
		await process_frame
		if g.state == "parada":
			break
	check(g.state == "parada", "slow in the right lane at the posto stops the car")
	await step(30)
	await shot("parada_posto_chega")
	par.order(par.menu_ids[0])
	par.order(par.menu_ids[2])
	par.sel = 2
	await step(40)
	await shot("parada_posto")
	par.leave()
	await step(40)
	check(g.state == "drive" and g.fuel > 0.98, "back on the road with a full tank")
	await step(240)
	check(g.v > 10.0 and not is_nan(g.px), "drives off again (v %.0f)" % g.v)

	# --- the postcard at the end (with the last photo), then the diary
	g.km_trip = maxf(g.km_trip, 3.4)
	g.to_menu()
	await step(10)
	var dia = g.get_node("diario")
	check(dia.layer.visible, "postcard shown at the end of the trip")
	await shot("postal_foto")
	dia.layer.visible = false

	# a second trip: the caramelo in the pickup on the dirt road, a stop at the venda by key, no photo
	g.cfg = {"car": "picape", "road": "terra", "weather": "sol", "time": "dia"}
	g.setup()
	companion("caramelo")
	g.begin()
	g.set_cam(0)
	g.set_auto(true)
	await step(120)
	await shot("cab_caramelo_acordado")
	g.clean = 120.0
	await step(30 * 60)
	g.get_node("passageiro").sleep = 1.0
	await shot("cab_caramelo_dormindo")
	g.pos = (g.postos[1] - 100) * g.SEG
	g.feature_call("drive_key", [KEY_E])
	check(g.state == "parada", "E near the venda stops")
	await step(30)
	par.order(par.menu_ids[0])
	par.order(par.menu_ids[2])
	par.order(par.menu_ids[3])
	await step(40)
	await shot("parada_venda")
	par.leave()
	await step(40)
	g.km_trip = 6.2
	g.trip_time = 13 * 60.0
	g.to_menu()
	await step(10)
	await shot("postal_terra")
	dia.layer.visible = false

	# expressway at night, GT, the vó, the loja
	g.cfg = {"car": "gt", "road": "expressa", "weather": "chuva", "time": "noite"}
	g.setup()
	companion("vo")
	g.begin()
	g.set_cam(0)
	g.set_auto(true)
	await step(200)
	await shot("cab_gt_vo_noite")
	par.enter(g.postos[0])
	await step(30)
	par.order(par.menu_ids[1])
	await step(30)
	await shot("parada_loja")
	par.leave()
	await step(40)
	g.km_trip = 12.0
	g.to_menu()
	await step(10)
	await shot("postal_expressa")
	dia.layer.visible = false

	dia.open_diary()
	await step(4)
	await shot("diario_viagens")
	dia._key(KEY_RIGHT)
	await step(4)
	await shot("diario_passaporte")
	dia._key(KEY_LEFT)
	dia._key(KEY_ENTER)
	await step(4)
	await shot("diario_postal")
	print("FAILS: %d" % fails.size())
	quit()

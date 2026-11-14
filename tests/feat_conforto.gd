extends SceneTree
# Exercises the "conforto e modos" features (ajustes, código, viagem de hoje, descanso, manobras) and takes screenshots.
#   xvfb-run godot --path . --fixed-fps 60 --rendering-driver opengl3 --audio-driver Dummy --script res://tests/feat_conforto.gd -- <out_dir>
# Headless (no shots): godot --headless --path . --fixed-fps 60 --script res://tests/feat_conforto.gd
const MAIN := preload("res://main.tscn")
var out := ""
var g
var fails := 0

func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() > 0:
		out = a[0]
	_run.call_deferred()

func step(n: int) -> void:
	for i in n:
		await process_frame

func shot(name: String) -> void:
	if out != "" and DisplayServer.get_name() != "headless":
		root.get_texture().get_image().save_png("%s/%s.png" % [out, name])

func check(ok: bool, what: String) -> void:
	print(("ok   " if ok else "FAIL ") + what)
	if not ok:
		fails += 1

func holes() -> Array:
	var r := []
	for s in g.segs:
		for f in s.feat:
			if f.t == 0:
				r.append([s.i, snappedf(f.x, 0.001)])
	return r

func make() -> void:
	Engine.set_meta("test_seed", 5)
	g = MAIN.instantiate()
	root.add_child(g)
	await process_frame
	await process_frame

func _run() -> void:
	await make()
	var cod = g.get_node("codigo")
	var aj = g.get_node("ajustes")
	var dd = g.get_node("viagem_do_dia")
	var ds = g.get_node("descanso")
	var mn = g.get_node("manobras")

	# --- code: round trip and the same road from the same code
	var p: Dictionary = cod.parse("sitio-picape-sol-dia-4821")
	check(p.seed == 4821 and p.cfg.road == "terra" and p.cfg.car == "picape" and p.cfg.time == "dia", "parse code")
	check(cod.parse("BR-116 GT CHUVA NOITE 77").cfg.road == "br", "parse loose code")
	check(cod.parse("SITIO-PICAPE-4821").is_empty(), "reject incomplete code")
	g.cfg = p.cfg.duplicate()
	g.next_seed = p.seed
	g.setup()
	check(cod.current() == "SITIO-PICAPE-SOL-DIA-4821", "current code " + cod.current())
	var h1 := holes()
	var c1: float = g.cars[3].z
	g.next_seed = 4821
	g.setup()
	check(h1 == holes() and c1 == g.cars[3].z, "same seed, same holes and traffic")
	g.next_seed = 4822
	g.setup()
	check(h1 != holes(), "other seed, other road")

	# --- holes and traffic amounts
	g.next_seed = 4821
	g.setup()
	var n_h: int = holes().size()
	var n_c: int = g.cars.size()
	aj.val["holes"] = 0
	aj.val["traffic"] = 0
	g.next_seed = 4821
	g.setup()
	var few: int = holes().size()
	var light: int = g.cars.size()
	aj.val["holes"] = 2
	aj.val["traffic"] = 2
	g.next_seed = 4821
	g.setup()
	print("holes few/normal/bad %d/%d/%d  cars light/normal/busy %d/%d/%d" % [few, n_h, holes().size(), light, n_c, g.cars.size()])
	check(few < n_h and holes().size() > n_h and light < n_c and g.cars.size() > n_c, "hole and traffic scales")
	aj.val["holes"] = 1
	aj.val["traffic"] = 1

	# --- audio buses
	check(g.a_music.bus == "Radio" and g.a_rain.bus == "Chuva" and g.a_engine.bus == "Motor" and g.sfx.hole.bus == "Efeitos", "players on their buses")

	# --- menu with the new buttons, ajustes screen, code screen, trip of the day
	g.cfg = {"car": "besouro", "road": "br", "weather": "chuva", "time": "entardecer"}
	g.setup()
	g.menu.show_main()
	g.menu.sel = 5
	g.menu.refresh()
	await step(60)
	await shot("c01_menu")
	aj.open()
	aj.sel = 3
	aj._refresh()
	await step(3)
	await shot("c02_ajustes")
	g.menu.key(KEY_ESCAPE)
	cod.open()
	for k in [KEY_S, KEY_I, KEY_T, KEY_I, KEY_O, KEY_MINUS, KEY_G, KEY_T, KEY_MINUS, KEY_S, KEY_O, KEY_L]:
		g.menu.key(k)
	await step(3)
	await shot("c03_codigo")
	for k in [KEY_MINUS, KEY_N, KEY_O, KEY_I, KEY_T, KEY_E, KEY_MINUS, KEY_1, KEY_2, KEY_3, KEY_4]:
		g.menu.key(k)
	g.menu.key(KEY_ENTER)
	await step(5)
	check(g.started and g.cfg.road == "terra" and g.cfg.car == "gt" and g.trip_seed == 1234, "typed code starts that trip")
	g.to_menu()
	await step(3)
	g.menu.close_screen()
	dd.open()
	await step(3)
	await shot("c04_viagem_de_hoje")
	var t1: Dictionary = dd.trip_for({"year": 2026, "month": 11, "day": 13})
	var t2: Dictionary = dd.trip_for({"year": 2026, "month": 11, "day": 13})
	var t3: Dictionary = dd.trip_for({"year": 2026, "month": 11, "day": 14})
	check(t1.hash() == t2.hash() and t1.hash() != t3.hash(), "trip of the day depends only on the date " + str(t1))
	g.menu.key(KEY_ENTER)
	await step(5)
	var td: Dictionary = dd.trip_for(dd.today())
	check(g.started and g.trip_seed == td.seed and g.cfg.road == td.cfg.road, "trip of the day started")

	# --- pause: code line, rest mode screen
	g.to_menu()
	await step(2)
	g.menu.close_screen()
	g.cfg = {"car": "picape", "road": "terra", "weather": "chuva", "time": "noite"}
	g.next_seed = 4821
	g.setup()
	g.begin()
	await step(120)
	g.pause()
	await step(3)
	await shot("c05_pausa")
	check(cod.l_pause.text.contains("SITIO-PICAPE-CHUVA-NOITE-4821"), "code in the pause")
	ds.open()
	ds.timer_i = 1
	ds._refresh()
	await step(3)
	await shot("c06_descanso_tela")
	g.menu.key(KEY_DOWN)
	g.menu.key(KEY_UP)
	g.menu.key(KEY_ENTER)   # start resting with a 15 min timer
	await step(30)
	check(ds.resting and g.auto and not g.hud.visible and ds.sleep_total == 900.0, "rest mode on with timer")
	await shot("c07_descanso")
	var cam0: int = g.cam
	ds.cam_t = 39.0
	await step(60 + 50)
	await shot("c08_descanso_troca")
	await step(120)
	check(g.cam != cam0, "rest mode changed camera")
	ds.sleep_left = 200.0   # fast forward: inside the fade
	await step(60)
	check(AudioServer.get_bus_volume_db(0) < -3.0, "timer fades the sound (%.1f dB)" % AudioServer.get_bus_volume_db(0))
	ds.sleep_left = 6.0
	await step(400)
	check(g.state == "menu" and ds.silenced and not ds.resting and g.hud.visible, "timer ended: menu in silence")
	await shot("c09_fim_da_viagem")
	var dia = g.get_node_or_null("diario")   # with the logbook package the postcard is the end-of-trip card
	check(g.menu.screen_open() or (dia != null and dia.layer.visible), "end-of-trip card shown")
	var ev := InputEventKey.new()
	ev.pressed = true
	ev.physical_keycode = KEY_ENTER
	Input.parse_input_event(ev)
	await step(150)
	check(not ds.silenced and AudioServer.get_bus_volume_db(0) > -1.0, "a key brings the sound back (silenced %s, %.1f dB, state %s)" % [ds.silenced, AudioServer.get_bus_volume_db(0), g.state])
	g.menu.close_screen()

	# --- maneuvers
	g.cfg = {"car": "besouro", "road": "br", "weather": "chuva", "time": "entardecer"}
	g.setup()
	g.begin()
	g.set_auto(false)
	await step(30)
	g._hit_feat({"t": 0, "x": g.px + 0.01, "w": 0.07}, 0.7)
	check(mn.trip.get("ENTRE AS RODAS", 0) == 1, "between the wheels")
	mn.last_hole_hit = -10.0   # a real pothole hit by chance in the last second would (rightly) cancel the award
	for e in mn.hist:   # the hole was in our path a moment ago, then we moved over
		e[1] = g.px + 0.5
	g._hit_feat({"t": 0, "x": g.px + 0.4, "w": 0.1}, 0.7)
	check(mn.trip.get("DESVIO LIMPO", 0) == 1, "clean dodge")
	mn.drive_key(KEY_Q)
	await step(40)
	g.px = g.LANES[1]
	g.vx = 0.0
	await step(5)
	check(mn.trip.get("TROCA DE FAIXA COM SETA", 0) == 1, "lane change with signal")
	mn.drive_key(KEY_E)
	g.set_cam(0)
	await step(5)
	await shot("c10_seta_cabine")
	g.set_cam(1)
	await step(5)
	await shot("c11_seta_fora")
	mn.blink = 0

	# --- bigger notices, no sway, no shake
	aj.val["notice"] = 2
	aj.val["sway"] = 0
	aj.val["shake"] = 2
	aj._apply()
	g.set_cam(0)
	g.hud.toast("PILOTO AUTOMÁTICO: SÓ CURTA A VIAGEM", 3.0)
	g.hud.notice("POÇA DESVIADA", 3.0)
	await step(5)
	await shot("c12_avisos_grandes")
	check(g.view_sway == 0.0 and g.view_shake == 0.0, "sway and shake off")
	aj.val["essential"] = 1
	g.hud.toast("EITA, BURACO!", 2.0)
	await step(2)
	check(g.hud.l_toast.modulate.a == 0.0, "non-essential toast hidden")
	g.hud.toast("NA RESERVA: POSTO NA FAIXA DA DIREITA", 2.0)
	await step(2)
	check(g.hud.l_toast.modulate.a > 0.0, "essential toast shown")
	g.to_menu()
	await step(5)
	await shot("c13_cartao")
	print("FAILS: %d" % fails)
	quit()

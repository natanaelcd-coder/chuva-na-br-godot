extends SceneTree
# Radio package check: the program (announcer, ads, forecast, time), reception by hour and place, the stations
# R cycles through on each car, the Besouro's tape (recording, sides, spools) and the radio screen.
#   xvfb-run godot --path . --fixed-fps 60 --audio-driver Dummy --script res://tests/feat_radio.gd -- <out_dir>
#   (headless also works: then no screenshots)
const MAIN := preload("res://main.tscn")
var out := ""
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
	print(("ok   " if ok else "FAIL ") + what)
	if not ok:
		fails += 1

func shot(name: String) -> void:
	if out == "" or DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("%s/%s.png" % [out, name])

func make(car: String, road: String, weather: String, time: String):
	Engine.set_meta("test_seed", 5)
	var g = MAIN.instantiate()
	root.add_child(g)
	await process_frame
	g.cfg = {"car": car, "road": road, "weather": weather, "time": time}
	g.setup()
	return g

func _run() -> void:
	var g = await make("besouro", "br", "chuva", "entardecer")
	var r = g.get_node("radio")
	g.begin()
	g.hud.toast_t = 0.0
	await step(30)
	check(g.STATIONS.size() == 4 and g.STATIONS[3].id == "fita", "besouro: 3 radios + tape")
	check(r.shown_text.begins_with("TOCANDO:"), "song on the strip: " + r.shown_text)

	# every kind of line, every station
	for si in 3:
		var p: Dictionary = r.prog[si]
		p.next = 0
		for k in ["slogan", "ad", "recado", "hora", "tempo", "estrada", "intro"]:
			var l: String = r._line(k, si, p)
			check(l != "" and l.length() < 220, "%d %s (%d): %s" % [si, k, l.length(), l])

	# the song ends: jingle, talk on the strip, then the next song
	var p0: Dictionary = r.prog[0]
	r.tuned_from_start = true
	p0.t = p0.dur - 0.2
	await step(30)
	check(p0.kind == "talk", "break after the song")
	check(not r.shown_text.begins_with("TOCANDO"), "talk on the strip: " + r.shown_text)
	g.hud.notice_t = 0.0
	await step(150)
	await shot("radio_talk")
	var guard := 0
	while p0.kind == "talk" and guard < 60 * 120:
		await step(60)
		guard += 60
	check(p0.kind == "song", "next song after the break (%.0f s of talk)" % (guard / 60.0))
	check(r.heard.size() >= 1, "song heard to the end counted: %s" % [r.heard])
	check(r.fita_a.size() == 4 or r.fita_b.size() >= 1 or r.fita_a.has(p0.song), "recorded on the tape: A %s B %s" % [r.fita_a, r.fita_b])

	# reception: AM by hour, FM by place
	g.tday = 0.0
	var am_day: float = r._reception(r.RADIOS[2])
	g.tday = 2.0
	var am_night: float = r._reception(r.RADIOS[2])
	check(am_night > am_day + 0.4, "AM: day %.2f, night %.2f" % [am_day, am_night])
	g.tday = 1.0
	var lo := 1.0
	var hi := 0.0
	for i in range(0, g.N, 10):
		g.pos = i * g.SEG
		var qq: float = r._reception(r.RADIOS[0])
		lo = minf(lo, qq)
		hi = maxf(hi, qq)
	check(hi - lo > 0.3, "FM along the BR: %.2f .. %.2f" % [lo, hi])

	# R: radios, tape, off, and the static between them
	g.next_station()
	check(g.static_t > 0.0, "static while tuning")
	await step(40)
	check(r.cur().id == "litoral", "R -> Litoral")
	g.next_station()
	g.next_station()
	check(r.cur().id == "fita", "R -> tape")
	await step(60)
	check(r.shown_text.begins_with("FITA K7 LADO A"), "tape on the strip: " + r.shown_text)
	g.t = 1.0
	r.tape.t = 30.0
	await step(2)
	await shot("radio_fita_a")
	var key := InputEventKey.new()
	key.physical_keycode = KEY_T
	key.pressed = true
	g._unhandled_input(key)
	await step(200)
	check(g.STATIONS[3].label == 6 or not r.tape.flipped, "T turns the tape over: side %d, label %d" % [r.tape.side, g.STATIONS[3].label])
	await shot("radio_fita_b")
	g.next_station()
	check(r.cur().is_empty(), "R -> off")
	await step(40)
	check(r.shown_text.begins_with("TOCANDO: SÓ"), "off: " + r.shown_text)
	g.next_station()

	# night on the dirt road, AM
	g.queue_free()
	await step(2)
	g = await make("gt", "terra", "sol", "noite")
	r = g.get_node("radio")
	check(g.STATIONS.size() == 3, "GT: no tape")
	g.begin()
	g.next_station()
	g.next_station()
	await step(60)
	check(r.cur().id == "noite" and r.q > 0.7, "Noite AM at night: q %.2f" % r.q)
	r.prog[2].kind = "talk"
	r.prog[2].items = ["tempo"]
	r.prog[2].ti = 0
	r._set_text(r.prog[2], 2)
	await step(90)
	await shot("radio_gt_noite")
	g.pause()
	await step(2)
	g.menu._pause_pick(g.menu.PAUSE_ITEMS.find("RÁDIO E FITA"))
	await step(4)
	await shot("radio_screen")
	g.queue_free()
	await step(2)

	# day: the AM chiando, a notice
	g = await make("picape", "terra", "chuva", "dia")
	r = g.get_node("radio")
	g.begin()
	for i in 2:
		g.next_station()
	await step(400)
	check(r.q < 0.45, "Noite AM by day chia: q %.2f" % r.q)
	await shot("radio_picape_dia")
	g.queue_free()
	await step(2)
	print("FAILS: %d" % fails)
	quit(1 if fails > 0 else 0)

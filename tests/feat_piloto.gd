extends SceneTree
# The three autopilot modes: P cycles LIGADO -> ASSISTIDO -> DESLIGADO; steering on LIGADO hands over to ASSISTIDO;
# DESLIGADO really lets go: no cruise control (the car coasts), no lane keeping, no braking for the car ahead.
#   godot --headless --path . --fixed-fps 60 --audio-driver Dummy --script res://tests/feat_piloto.gd
const MAIN := preload("res://main.tscn")
var fails := 0

func _initialize() -> void:
	_run.call_deferred()

func check(ok: bool, what: String) -> void:
	print(("ok   " if ok else "FAIL ") + what)
	if not ok:
		fails += 1

func key(k: int) -> void:
	var ev := InputEventKey.new()
	ev.pressed = true
	ev.physical_keycode = k
	root.get_viewport().push_input(ev)

func _run() -> void:
	Engine.set_meta("test_seed", 5)
	var g = MAIN.instantiate()
	root.add_child(g)
	await process_frame
	g.cfg = {"car": "besouro", "road": "br", "weather": "sol", "time": "dia"}
	g.setup()
	g.begin()
	check(g.drive_mode == 1 and not g.auto, "a trip starts on ASSISTIDO")
	for i in 240: await process_frame
	g.set_mode(2)
	check(g.auto, "LIGADO is the autopilot")
	key(KEY_P)
	await process_frame
	check(g.drive_mode == 1, "P: LIGADO -> ASSISTIDO (%d)" % g.drive_mode)
	key(KEY_P)
	await process_frame
	check(g.drive_mode == 0 and not g.auto, "P: ASSISTIDO -> DESLIGADO (%d)" % g.drive_mode)
	# DESLIGADO with hands off: the car coasts down and does not hold the lane through bends
	var v0: float = g.v
	var drift := 0.0
	var x0: float = g.px
	for i in 360:
		await process_frame
		drift = maxf(drift, absf(g.px - x0))
	check(g.v < v0 - 15.0, "DESLIGADO: no cruise control, it coasts (%.0f -> %.0f km/h)" % [v0, g.v])
	g.bot_speed = 1.0
	for i in 180: await process_frame
	g.bot_speed = 0.0
	check(g.v > v0 - 10.0, "DESLIGADO: the up key is the throttle (%.0f km/h)" % g.v)
	key(KEY_P)
	await process_frame
	check(g.drive_mode == 2 and g.auto, "P: DESLIGADO -> LIGADO")
	g.bot_steer = 1.0
	await process_frame
	await process_frame
	g.bot_steer = 0.0
	check(g.drive_mode == 1, "steering while on LIGADO hands over to ASSISTIDO, not to DESLIGADO")
	g.set_auto(false)
	check(g.drive_mode == 1, "set_auto(false) keeps the old meaning (ASSISTIDO)")
	print("drift on DESLIGADO hands-off: %.2f" % drift)
	print("FAILS: %d" % fails)
	quit()

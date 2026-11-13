extends Node
# Nice driving, noticed (brainstorm idea 17). Only when you are at the wheel (not the autopilot), only the
# good things, and only a discreet line (hud.notice), never points:
#   ENTRE AS RODAS!       a pothole went between the tyres
#   DESVIO LIMPO          a pothole that was in your path a moment ago went by beside the car
#   POÇA DESVIADA         the same with a puddle
#   ULTRAPASSAGEM LIMPA   Estrada do Sítio: out through the oncoming lane and back, nobody had to flash or honk
#   CURVA NO TRAÇADO      a long strong bend at speed, line set before it and hands off all the way through
#   TROCA DE FAIXA COM SETA  the turn signal (Q left, E right) on before changing lane
# Counts go into the trip summary (summary.manobras) and a lifetime tally in viagem.cfg [manobras].

const COOLDOWN := 10.0   # the same kind is announced at most this often (it always counts)

var g
var hist: Array = []     # [time, px] over the last ~1.5 s
var clock := 0.0
var trip := {}           # kind -> count this trip
var last_notice := {}    # kind -> clock
var queue: Array = []
var queue_t := 0.0
var last_hole_hit := -10.0
var last_puddle_hit := -10.0
var last_bump := -10.0
var last_input := -10.0
# overtaking on the dirt road
var ot_on := false
var ot_cars: Array = []
var ot_fail := false
var ot_t := 0.0
# bends
var cv_on := false
var cv_t := 0.0
var cv_ok := false
var cv_prep := false
# turn signal
var blink := 0           # -1 left, 1 right
var blink_t := 0.0
var blink_lane := -1
var click: AudioStreamPlayer

func _ready() -> void:
	g = get_parent()
	g.hole_missed.connect(_on_hole_missed)
	g.hole_hit.connect(func(_f, _s, _k): last_hole_hit = clock)
	g.puddle_hit.connect(func(_f): last_puddle_hit = clock)
	g.bumped.connect(_on_bumped)
	g.seg_passed.connect(_on_seg)
	g.trip_started.connect(_on_trip_started)
	g.trip_ended.connect(_on_trip_ended)
	click = AudioStreamPlayer.new()
	click.stream = _click_sound()
	click.volume_db = -14.0
	add_child(click)
	(func(): click.bus = "Efeitos" if AudioServer.get_bus_index("Efeitos") >= 0 else "Master").call_deferred()

func _hands() -> bool:   # the player is driving
	return g.started and g.state == "drive" and not g.auto

func _px_ago(s: float) -> float:
	for i in range(hist.size() - 1, -1, -1):
		if clock - hist[i][0] >= s:
			return hist[i][1]
	return hist[0][1] if hist.size() > 0 else g.px

func award(kind: String, text: String) -> void:
	trip[kind] = trip.get(kind, 0) + 1
	g.store_set("manobras", kind, int(g.store_get("manobras", kind, 0)) + 1)
	var aj = g.get_node_or_null("ajustes")
	if aj and aj.essential_only():
		return
	if clock - last_notice.get(kind, -100.0) < COOLDOWN:
		return
	last_notice[kind] = clock
	if queue.size() < 3:
		queue.append(text)

func _on_trip_started() -> void:
	trip.clear()
	ot_on = false
	cv_on = false
	blink = 0

func _on_trip_ended(summary: Dictionary) -> void:
	summary["manobras"] = trip.duplicate()
	blink = 0

func _on_bumped(_kind: String) -> void:
	last_bump = clock
	ot_fail = true
	cv_ok = false

func _on_hole_missed(f: Dictionary, d: float) -> void:
	if not _hands() or g.v < 15.0:
		return
	if absf(d) < 0.2:
		award("ENTRE AS RODAS", "ENTRE AS RODAS!")
		return
	# beside the car now: was it under a wheel a moment ago?
	var then: float = f.x - _px_ago(0.8)
	var would: bool = absf(then + 0.2) < f.w + 0.06 or absf(then - 0.2) < f.w + 0.06
	if would and absf(d) < 0.2 + f.w + 0.4 and clock - last_hole_hit > 1.0:
		award("DESVIO LIMPO", "DESVIO LIMPO")

func _on_seg(i: int) -> void:
	if not _hands() or g.v < 15.0 or clock - last_puddle_hit < 1.0:
		return
	for f in g.segs[i].feat:
		if f.t == 2 and f.get("a", 0.0) == 1.0:   # the middle of a puddle
			var reach: float = f.w + 0.24
			if absf(f.x - g.px) > reach and absf(f.x - _px_ago(0.8)) < reach:
				award("POÇA DESVIADA", "POÇA DESVIADA")
				return

func drive_key(k: int) -> bool:
	if k == KEY_Q or k == KEY_E:
		var d := -1 if k == KEY_Q else 1
		blink = 0 if blink == d else d
		blink_t = 0.0
		blink_lane = g.nearest_lane(g.px)
		if blink != 0:
			click.play()
		return true
	return false

func _process(dt: float) -> void:
	dt = minf(dt, 0.05)
	if g.state == "pause":
		return
	clock += dt
	hist.append([clock, g.px])
	while hist.size() > 2 and clock - hist[0][0] > 1.6:
		hist.pop_front()
	if g.prev_input != 0.0:
		last_input = clock
	queue_t -= dt
	if queue.size() > 0 and queue_t <= 0.0:
		g.hud.notice(queue.pop_front(), 3.0)
		queue_t = 3.2
	_signal_step(dt)
	if not _hands():
		ot_on = false
		cv_on = false
		return
	_overtake_step(dt)
	_curve_step(dt)

func _signal_step(dt: float) -> void:
	if blink == 0:
		return
	var was := fmod(blink_t, 0.7) < 0.35
	blink_t += dt
	if (fmod(blink_t, 0.7) < 0.35) != was:
		click.pitch_scale = 1.0 if was else 0.8   # tic... tac
		click.play()
	if blink_t > 10.0 or not g.started:
		blink = 0
		return
	var ln: int = g.nearest_lane(g.px)
	if ln != blink_lane:
		if signi(ln - blink_lane) == blink and blink_t > 0.4 and _hands():
			award("TROCA DE FAIXA COM SETA", "TROCA DE FAIXA COM SETA")
		blink = 0   # the stalk clicks back after the lane change

func _overtake_step(dt: float) -> void:
	if not g.road.two_way:
		return
	if not ot_on:
		if g.px < 0.0:   # out in the oncoming lane: is there someone of ours ahead to pass?
			ot_cars.clear()
			for c in g.cars:
				if c.dir > 0 and absf(c.x - g.LANES[1]) < 0.3 and fposmod(c.z - g.pos, g.TRACK) < 4000.0:
					ot_cars.append(c)
			if ot_cars.size() > 0:
				ot_on = true
				ot_fail = false
				ot_t = 0.0
		return
	ot_t += dt
	for c in g.cars:
		if c.dir < 0 and c.get("flash_t", 0.0) > 0.0:   # an oncoming car had to flash and honk
			ot_fail = true
	if g.px > 0.3:
		var passed := false
		for c in ot_cars:
			if fposmod(c.z - g.pos, g.TRACK) > g.TRACK * 0.5:
				passed = true
		if passed and not ot_fail:
			award("ULTRAPASSAGEM LIMPA", "ULTRAPASSAGEM LIMPA")
		ot_on = false
	elif ot_t > 25.0:
		ot_on = false

func _curve_step(dt: float) -> void:
	var cur: float = g.segs[int(g.pos / g.SEG) % g.N].curve
	if not cv_on:
		if absf(cur) >= 2.2:
			cv_on = true
			cv_t = 0.0
			cv_ok = true
			cv_prep = clock - last_input < 4.0   # the line was set just before the bend
		return
	cv_t += dt
	if g.prev_input != 0.0 or g.off_t > 0.0 or g.v < 45.0:
		cv_ok = false
	if absf(cur) < 1.0:
		if cv_ok and cv_prep and cv_t > 2.5:
			award("CURVA NO TRAÇADO", "CURVA NO TRAÇADO")
		cv_on = false

# ---- the turn signal on the dashboard and on the car
func draw_cabin_over(ck) -> void:
	if blink == 0 or g.cam != 0:
		return
	var sp: Array = ck.lay.speedo
	var lit := fmod(blink_t, 0.7) < 0.35
	var col := Color("5ef07a") if lit else Color("1d4a2a")
	var cx: float = sp[0] + blink * 5.0
	var cy: float = sp[1] - sp[2] - 4.0
	ck.draw_colored_polygon(PackedVector2Array([Vector2(cx + blink * 3.0, cy), Vector2(cx - blink * 1.0, cy - 2.5), Vector2(cx - blink * 1.0, cy + 2.5)]), col)
	ck.draw_rect(Rect2(cx - blink * 3.0 - (0.0 if blink > 0 else 2.0), cy - 1.0, 2.0, 2.0), col)

func draw_world_over(w) -> void:
	if blink == 0 or g.cam != 1 or not g.has_car_scr or fmod(blink_t, 0.7) >= 0.35:
		return
	var sx: float = g.car_scr.x
	var sy: float = g.car_scr.y
	var k: float = g.car_scr.z
	var s := k * 64.0 / (1000.0 * 192.0)
	var e: float = clampf((g.zb - g.zr) * s * g.view.hh, -5.0 * k, 6.0 * k)
	var p := Vector2(sx + g.vx * 2.5 * k + blink * (g.car.brake_x + 4.0) * k, sy - 6.0 * k - e + g.pitch * 42.0 * k + g.car.brake_y * k)
	w.draw_circle(p, 2.2 * k, Color("ffc04a"))
	w._glow(p.x, p.y, 10.0 * k, Color(1.0, 0.7, 0.2), 0.8)

static func _click_sound() -> AudioStreamWAV:
	var rate := 22050
	var n := int(rate * 0.025)
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in n:
		var env := exp(-float(i) / (rate * 0.003))
		var x := sin(i * 0.9) * 0.6 + sin(i * 2.3) * 0.4
		data.encode_s16(i * 2, int(clampf(x * env, -1.0, 1.0) * 26000.0))
	var st := AudioStreamWAV.new()
	st.format = AudioStreamWAV.FORMAT_16_BITS
	st.mix_rate = rate
	st.data = data
	return st

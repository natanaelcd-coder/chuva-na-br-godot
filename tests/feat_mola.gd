extends SceneTree
# Mola, rolagem e pulo (rodada 10): a carroceria rola para FORA (troca de faixa e curva, nas duas câmeras),
# a mola assenta rápido sem ficar dura, e as cristas da pista tiram o carro do chão só acima de certa velocidade.
#   números:   godot --headless --path . --fixed-fps 60 --script res://tests/feat_mola.gd
#   + imagens: xvfb-run -a godot --path . --fixed-fps 60 --rendering-driver opengl3 --audio-driver Dummy --script res://tests/feat_mola.gd -- <dir_saida>
# Imprime FAILS: N.

const MAIN := preload("res://main.tscn")
const DT := 1.0 / 60.0
var g
var fails := 0
var out_dir := ""

func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() > 0:
		out_dir = a[0]
		DirAccess.make_dir_recursive_absolute(out_dir)
	_run.call_deferred()

func check(ok: bool, what: String) -> void:
	print(("ok    " if ok else "FALHA ") + what)
	if not ok:
		fails += 1

func step(n: int) -> void:
	for i in n:
		await process_frame

func make(car: String, road: String, weather := "sol", clean := true):
	Engine.set_meta("test_seed", 1)
	g = MAIN.instantiate()
	g.cfg = {"car": car, "road": road, "weather": weather, "time": "dia"}
	root.add_child(g)
	await process_frame
	if clean:
		for s in g.segs:
			s.feat.clear()
		g.NOISE.fill(0.0)
	g.cars.clear()
	seed(7920)
	g.begin()
	g.hud.toast_t = 0.0
	g.set_auto(false)

func drop() -> void:
	g.queue_free()
	await process_frame

func flat() -> void:   # no undulation at all: only what the test does moves the body
	g.Y.fill(0.0)
	for s in g.segs:
		s.y1 = 0.0
		s.y2 = 0.0

func place(i: int, px: float, v: float) -> void:
	g.pos = i * g.SEG
	g.px = px
	g.cam_x = px
	g.hold_x = px
	g.vx = 0.0
	g.steer = 0.0
	g.v = v
	g.target = v
	g.zb = g.road_y(g.pos, 1.0)
	g.zr = g.zb
	g.zr_prev = g.zb
	g.cy = g.zb
	g.zb_v = 0.0
	g.pitch = 0.0
	g.pitch_v = 0.0
	g.roll = 0.0
	g.roll_v = 0.0
	g.slope = 0.0
	g.set("zw", g.zb)
	g.set("zw_v", 0.0)
	g.set("air", false)
	g.lane = g.nearest_lane(px)

func straight() -> int:
	var best := 0
	var best_len := 0
	var run := 0
	for i in g.N:
		if absf(g.segs[i].curve) < 0.001:
			run += 1
			if run > best_len:
				best_len = run
				best = i - run + 1
		else:
			run = 0
	return best + 10

func bend(sgn: float) -> int:   # middle of the sharpest bend turning that way (curve > 0: to the right)
	var best := 0
	for i in g.N:
		if g.segs[i].curve * sgn > g.segs[best].curve * sgn:
			best = i
	return best

func shot(name: String) -> void:
	if out_dir != "":
		await process_frame
		root.get_texture().get_image().save_png(out_dir.path_join(name + ".png"))

# ------------------------------------------------------------- rolagem

# lane change: the body must lean AWAY from the side it is pushed to first, then the other way as the car straightens
func lane_roll(car: String, dir: float, cam: int) -> void:
	await make(car, "br")
	flat()
	place(straight(), 0.0, 80.0)
	g.set_cam(cam)
	await step(60)
	g.bot_steer = dir
	var first := 0.0     # first lean beyond 0.01 rad
	var peak1 := 0.0
	var peak2 := 0.0
	var t_first := -1.0
	var released := false
	var swings := 0
	var last := 0.0
	for i in 240:
		await process_frame
		if not released and absf(g.px) > 0.5:
			g.bot_steer = 0.0
			released = true
		var r: float = g.roll
		if first == 0.0 and absf(r) > 0.01:
			first = signf(r)
			t_first = i * DT
		if not released:
			peak1 = r if absf(r) > absf(peak1) else peak1
		else:
			peak2 = r if r * -signf(peak1) > peak2 * -signf(peak1) else peak2
			if absf(r) > 0.012 and signf(r) != last:
				swings += 1
				last = signf(r)
		if i == 14:
			await shot("rolagem_faixa_%s_%s_%s" % ["dir" if dir > 0 else "esq", "cabine" if cam == 0 else "externa", car])
	var side := "direita" if dir > 0 else "esquerda"
	print("  troca p/ %s (%s, cam %d): 1ª inclinação %.3f rad em %.2f s, contra-inclinação %.3f, balanços depois de soltar %d" % [side, car, cam, peak1, t_first, peak2, swings])
	check(first == -dir, "troca de faixa para a %s: a carroceria rola para o lado oposto (%s)" % [side, car])
	check(absf(peak1) >= 0.02 and absf(peak1) <= 0.11, "rolagem visível mas contida (%.3f rad)" % absf(peak1))
	check(signf(peak2) == dir and absf(peak2) < absf(peak1) * 1.3, "ao endireitar, a volta é para o outro lado e não maior que a ida (%.3f)" % peak2)
	check(swings <= 2, "depois de soltar, no máximo um vai e volta (%d)" % swings)
	check(absf(g.roll) < 0.006, "termina nivelado (%.4f)" % g.roll)
	await drop()

func curve_roll(car: String, sgn: float, cam: int) -> void:
	await make(car, "br")
	flat()
	var i0 := bend(sgn)
	place(i0 - 60, 0.0, 90.0)
	g.set_cam(cam)
	var mean := 0.0
	var n := 0
	for i in 200:
		g.bot_steer = clampf((0.0 - g.px) * 6.0 - g.vx * 2.0, -1.0, 1.0)
		await process_frame
		if absf(g.segs[int(g.pos / g.SEG) % g.N].curve) > 1.5:
			mean += g.roll
			n += 1
			if n == 40:
				await shot("rolagem_curva_%s_%s_%s" % ["dir" if sgn > 0 else "esq", "cabine" if cam == 0 else "externa", car])
	mean /= maxf(1.0, n)
	g.bot_steer = 0.0
	print("  curva p/ %s (%s, cam %d): rolagem média %.3f rad em %d quadros" % ["direita" if sgn > 0 else "esquerda", car, cam, mean, n])
	check(n > 30 and signf(mean) == -sgn and absf(mean) > 0.012, "curva para a %s: carroceria inclinada para fora" % ["direita" if sgn > 0 else "esquerda"])
	await drop()

# what the two cameras do with a given roll: outside, the car's roof moves to the side the body leans to;
# inside, the world turns the other way (the cabin is the fixed frame)
func draw_signs() -> void:
	await make("besouro", "br")
	g.roll = -0.1   # leaning to the left (out of a right-hand bend)
	g.set_cam(0)
	await step(2)
	var w = g.get_node("World")
	check(w.transform.get_rotation() > 0.05, "cabine: carroceria para a esquerda -> o mundo gira no sentido horário (horizonte desce à direita)")
	g.roll = -0.1
	g.set_cam(1)
	await step(2)
	check(w.transform.get_rotation() == 0.0, "externa: o mundo não gira")
	check(w.body_tilt() < -0.05, "externa: o teto do carro vai para a esquerda (rotação anti-horária)")
	await drop()

# brake dive and squat: the nose goes down under braking (the horizon climbs in the windscreen, the tail rises
# in the chase view) and up under power
func dive(cam: int) -> void:
	await make("besouro", "br")
	flat()
	place(straight(), 0.0, 90.0)
	g.set_cam(cam)
	await step(60)
	var w = g.get_node("World")
	var y0: float = w.transform.origin.y if cam == 0 else w.body_at(0.0, 0.0, 1.0).y
	g.target = 30.0
	await step(30)
	var y1: float = w.transform.origin.y if cam == 0 else w.body_at(0.0, 0.0, 1.0).y
	await shot("freada_%s" % ("cabine" if cam == 0 else "externa"))
	check(g.pitch < -0.015, "freando, o nariz mergulha (arfagem %.3f)" % g.pitch)
	check(y1 < y0 - 1.0, "%s: %s (%.1f un.)" % ["cabine" if cam == 0 else "externa", "o horizonte sobe no para-brisa" if cam == 0 else "a traseira levanta", y1 - y0])
	g.target = 100.0
	await step(90)
	check(g.pitch > 0.004, "acelerando, o nariz levanta (arfagem %.3f)" % g.pitch)
	await drop()

# ------------------------------------------------------------- mola

func spring(car: String) -> Dictionary:
	await make(car, "br")
	flat()
	place(straight(), 0.0, 70.0)
	await step(60)
	g._hit_feat({"t": 0, "x": 0.2, "w": 0.1}, 0.7)
	var samples: Array = []
	var peak := 0.0
	var pitch_peak := 0.0
	var roll_peak := 0.0
	for i in 360:
		await process_frame
		var rel: float = g.zb - g.zr
		samples.append(rel)
		peak = maxf(peak, absf(rel))
		pitch_peak = maxf(pitch_peak, absf(g.pitch))
		roll_peak = maxf(roll_peak, absf(g.roll))
	var settle := 0.0
	for i in range(samples.size() - 1, -1, -1):
		if absf(samples[i]) > peak * 0.1:
			settle = (i + 1) * DT
			break
	var cross := 0
	var last := 0.0
	for x in samples:
		if absf(x) > peak * 0.1:
			if last != 0.0 and signf(x) != last:
				cross += 1
			last = signf(x)
	var res := {"car": car, "peak": peak, "settle": settle, "osc": cross / 2.0, "pitch": pitch_peak, "roll": roll_peak}
	print("  mola %s: pico %.1f un., assenta %.2f s, %.1f oscilações, arfagem %.3f, rolagem %.3f" % [car, peak, settle, cross / 2.0, pitch_peak, roll_peak])
	await drop()
	return res

# ------------------------------------------------------------- pulo

# drive over the first crest of the road at v; returns air time, height and what the landing did
func crest(car: String, road: String, v: float, cam := 0, shots := "", shot_at := 8) -> Dictionary:
	await make(car, road)
	var ci := -1
	for i in g.N:
		if g.CREST[i] > 0.0 and g.CREST[posmod(i - 1, g.N)] == 0.0:
			ci = i
			break
	if ci < 0:
		await drop()
		return {"found": false}
	if shots == "":   # numbers: nothing but the crests, so hills and washboard do not pollute them
		for i in g.N:
			g.Y[i] = g.CREST[i]
			g.segs[i].y1 = g.Y[i]
			g.segs[posmod(i - 1, g.N)].y2 = g.Y[i]
	var has_sign := false
	for q in g.segs[posmod(ci - 71, g.N)].spr:
		has_sign = has_sign or q.name == "placa_lombada"
	place(ci - 40, g.LANES[g.road.ours.back()], v)
	g.set_cam(cam)
	var px_air := 0.0
	var after := 0
	var air_t := 0.0
	var hmax := 0.0
	var land_peak := 0.0
	var landed := false
	var px0: float = g.px
	var drift := 0.0
	var v_min := v
	var n_air := 0
	for i in int((40 + 60) * g.SEG / (v * g.UPK) / DT) + 90:
		await process_frame
		v_min = minf(v_min, g.v)
		if g.air and air_t == 0.0:
			px_air = g.px
		if g.air or (air_t > 0.0 and after < 40):
			drift = maxf(drift, absf(g.px - px_air))
			after += 0 if g.air else 1
		if g.air:
			air_t += DT
			n_air += 1
			hmax = maxf(hmax, g.zw - g.zr)
			if shots == "go" and n_air == shot_at:
				await shot("pulo_%s_%s_%s" % [road, "cabine" if cam == 0 else "externa", car])
		elif air_t > 0.0:
			landed = true
			land_peak = maxf(land_peak, g.zw - g.zb)
			if shots == "go" and land_peak > 0.0 and g.zb_v > g.zw_v:
				await shot("pouso_%s_%s_%s" % [road, "cabine" if cam == 0 else "externa", car])
				shots = "done"
	var res := {"found": true, "sign": has_sign, "air": air_t, "h": hmax, "land": land_peak, "landed": landed or air_t == 0.0, "drift": drift, "lost": v - v_min, "nan": is_nan(g.zb) or is_nan(g.px)}
	await drop()
	return res

func _run() -> void:
	print("== rolagem: troca de faixa ==")
	for car in ["besouro", "picape", "gt"]:
		for dir in [-1.0, 1.0]:
			await lane_roll(car, dir, 0)
	for dir in [-1.0, 1.0]:
		await lane_roll("besouro", dir, 1)
	print("== rolagem: curva ==")
	for sgn in [-1.0, 1.0]:
		for cam in [0, 1]:
			await curve_roll("besouro", sgn, cam)
	await draw_signs()

	print("== arfagem ==")
	await dive(0)
	await dive(1)

	print("== mola ==")
	var sp := {}
	for car in ["besouro", "picape", "gt"]:
		sp[car] = await spring(car)
		check(sp[car].osc >= 0.5 and sp[car].osc <= 1.5, "%s: no máximo ~1 oscilação visível (%.1f)" % [car, sp[car].osc])
		check(sp[car].settle >= 0.5 and sp[car].settle <= 1.6, "%s: assenta entre 0,5 e 1,6 s (%.2f)" % [car, sp[car].settle])
	check(sp.besouro.settle > sp.gt.settle, "o besouro flutua mais tempo que o GT")
	check(sp.picape.peak > sp.besouro.peak and sp.besouro.peak > sp.gt.peak, "a picape quica mais, o GT menos")

	print("== pulo ==")
	for road in ["terra", "br", "expressa"]:
		var slow: Dictionary = await crest("besouro", road, 35.0)
		check(slow.found, "%s: a estrada tem cristas" % road)
		if not slow.found:
			continue
		check(slow.air == 0.0, "%s a 35 km/h: só ondula, as rodas não saem do chão" % road)
		check(slow.sign, "%s: placa amarela de saliência ~70 segmentos antes da crista" % road)
		var top: float = 135.0 if road == "expressa" else 95.0
		var fast: Dictionary = await crest("gt" if road == "expressa" else "besouro", road, top)
		print("  %s a %.0f km/h: no ar %.2f s, altura %.0f un., mola comprime %.0f un. no pouso, desvio lateral %.3f, perdeu %.1f km/h" % [road, top, fast.air, fast.h, fast.land, fast.drift, fast.lost])
		check(fast.air >= 0.12 and fast.air <= 0.75, "%s a %.0f km/h: fase aérea curta (%.2f s)" % [road, top, fast.air])
		check(fast.landed and fast.land > 8.0, "%s: pousa e a mola comprime (%.0f un.)" % [road, fast.land])
		check(fast.drift < 0.06 and fast.lost < 4.0 and not fast.nan, "%s: não perde o controle nem a velocidade" % road)
	var t70: Dictionary = await crest("besouro", "terra", 70.0)
	var t95: Dictionary = await crest("besouro", "terra", 95.0)
	check(t95.air > t70.air and t70.air > 0.0, "na terra, mais velocidade = mais tempo no ar (%.2f s a 70, %.2f s a 95)" % [t70.air, t95.air])
	var e80: Dictionary = await crest("besouro", "expressa", 80.0)
	check(e80.air == 0.0, "na expressa, a 80 km/h ainda não decola (só acima de ~100)")
	var b50: Dictionary = await crest("besouro", "br", 50.0)
	check(b50.air == 0.0, "na BR, a 50 km/h não decola")
	for car in ["picape", "gt"]:
		var r: Dictionary = await crest(car, "br", 95.0)
		print("  %s na BR a 95: no ar %.2f s, compressão no pouso %.0f un." % [car, r.air, r.land])
		check(r.air > 0.1 and r.landed, "%s também pula na BR" % car)
	if out_dir != "":
		for road in ["terra", "br", "expressa"]:
			for cam in [0, 1]:
				var v := 138.0 if road == "expressa" else 95.0
				var r: Dictionary = await crest("gt" if road == "expressa" else ("picape" if road == "terra" else "besouro"), road, v, cam, "go", 6 if road == "expressa" else 10)
				print("  captura %s cam %d: no ar %.2f s" % [road, cam, r.air])
	print("FAILS: %d" % fails)
	quit(1 if fails > 0 else 0)

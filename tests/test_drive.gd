extends SceneTree
# Automated test drive. Runs fixed scenarios with simulated keyboard input and writes metrics as JSON.
#   metrics:  godot --headless --path . --fixed-fps 60 --script res://tests/test_drive.gd
#   + images: xvfb-run godot --path . --fixed-fps 60 --script res://tests/test_drive.gd -- --shots
# Output: qa/metrics/latest.json and, with --shots, qa/shots/*.png

const MAIN := preload("res://main.tscn")
const DT := 1.0 / 60.0
var out := {}
var shots := false
var g

func _initialize() -> void:
	shots = OS.get_cmdline_user_args().has("--shots")
	_run.call_deferred()

func step(n: int) -> void:
	for i in n:
		await process_frame

func make(seed_v: int, clean: bool, traffic := false):
	Engine.set_meta("test_seed", seed_v)
	g = MAIN.instantiate()
	root.add_child(g)
	await process_frame
	if clean:
		for s in g.segs:
			s.feat.clear()
		g.NOISE.fill(0.0)
	if not traffic:
		g.cars.clear()
	g.begin()
	g.hud.toast_t = 0.0
	return g

func drop() -> void:
	g.queue_free()
	await process_frame

# start index of the longest straight and of the sharpest bend
func longest_straight() -> int:
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

func sharpest_bend() -> int:
	var best := 0
	for i in g.N:
		if absf(g.segs[i].curve) > absf(g.segs[best].curve):
			best = i
	return best

func place(i: int, px: float, v: float) -> void:
	g.pos = i * g.SEG
	g.px = px
	g.cam_x = px
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
	g.lane = 0 if px < -0.33 else (2 if px > 0.33 else 1)

func shot(name: String) -> void:
	if shots:
		await process_frame
		root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://qa/shots/%s.png" % name))

func r3(x: float) -> float:
	return snappedf(x, 0.001)

# ------------------------------------------------------------- scenarios

# A player changes lane right -> centre holding the key and letting go when close.
func lane_change(v: float) -> Dictionary:
	await make(1, true)
	place(longest_straight(), 0.667, v)
	g.set_auto(false)
	await step(60)
	var t := 0.0
	var t_move := -1.0
	var t_reach := -1.0
	var t_settle := -1.0
	var still := 0.0
	var min_px := 1.0
	var released := false
	var roll_peak := 0.0
	g.bot_steer = -1.0
	for i in 360:
		await process_frame
		t += DT
		if t_move < 0.0 and g.px < 0.637:
			t_move = t
		if not released and g.px <= 0.1:
			g.bot_steer = 0.0
			released = true
		if t_reach < 0.0 and g.px <= 0.05:
			t_reach = t
		min_px = minf(min_px, g.px)
		roll_peak = maxf(roll_peak, absf(g.roll))
		if released:
			if absf(g.px) < 0.04 and absf(g.vx) < 0.04:
				still += DT
				if still >= 0.5 and t_settle < 0.0:
					t_settle = t - 0.5
			else:
				still = 0.0
		if v == 70.0 and shots and i == 30 and g.cam == 0:
			pass
	var res := {"speed_kmh": v, "response_delay_s": r3(t_move), "time_to_target_s": r3(t_reach),
		"overshoot_road": r3(maxf(0.0, -min_px)), "settle_s": r3(t_settle), "roll_peak_rad": r3(roll_peak)}
	await drop()
	return res

# A short tap: how much does a 0.15 s press move the car? (fine control)
func tap(v: float) -> Dictionary:
	await make(1, true)
	place(longest_straight(), 0.0, v)
	g.set_auto(false)
	await step(30)
	g.bot_steer = 1.0
	await step(9)
	g.bot_steer = 0.0
	var peak_px := 0.0
	for i in 150:
		await process_frame
		peak_px = maxf(peak_px, absf(g.px))
	var res = {"speed_kmh": v, "tap_s": 0.15, "lateral_move_peak_road": r3(peak_px), "lateral_move_after_2_5s_road": r3(g.px), "lane_width_road": 0.667}
	await drop()
	return res

# Keyboard bot with human reaction delay keeps the lane centre through the sharpest bend.
func curve_follow(v: float, delay_s: float) -> Dictionary:
	await make(1, true)
	var b := sharpest_bend()
	place(b - 80, 0.667, v)
	g.set_auto(false)
	var buf: Array = []
	var err2 := 0.0
	var max_err := 0.0
	var presses := 0
	var held := 0.0
	var key_t := 0.0
	var n := 0
	var off_t := 0.0
	var dl := int(delay_s / DT)
	for i in 600:
		var e: float = 0.667 - g.px
		buf.append(e)
		var seen: float = buf[maxi(0, buf.size() - 1 - dl)]
		var k := 0.0
		if seen > 0.05:
			k = 1.0
		elif seen < -0.05:
			k = -1.0
		if k != 0.0 and k != held:
			presses += 1
		held = k
		g.bot_steer = k
		if k != 0.0:
			key_t += DT
		await process_frame
		err2 += e * e
		max_err = maxf(max_err, absf(e))
		if absf(g.px) > 1.02:
			off_t += DT
		n += 1
		if shots and v == 70.0 and i == 300:
			g.set_cam(1)
			await shot("chase_curve")
			g.set_cam(0)
	var res = {"speed_kmh": v, "reaction_delay_s": delay_s, "curve_strength": r3(g.segs[b].curve),
		"rms_error_road": r3(sqrt(err2 / n)), "max_error_road": r3(max_err), "key_presses_per_s": r3(presses / (n * DT)),
		"key_held_fraction": r3(key_t / (n * DT)), "offroad_s": r3(off_t)}
	await drop()
	return res

# One wheel drops into a pothole on a smooth straight: how does the body move and settle?
func pothole_response(v: float) -> Dictionary:
	await make(1, true)
	# flat road, so only the pothole moves the body (round-01 report: undulations polluted settle time)
	g.Y.fill(0.0)
	for s in g.segs:
		s.y1 = 0.0
		s.y2 = 0.0
	place(longest_straight(), 0.0, v)
	g.set_auto(false)
	await step(60)
	g._hit_feat({"t": 0, "x": 0.2, "w": 0.1}, v / 100.0)
	var peak := 0.0
	var roll_peak := 0.0
	var pitch_peak := 0.0
	var samples: Array = []
	var px0: float = g.px
	var kick_peak := 0.0
	var v_min: float = g.v
	for i in 360:
		await process_frame
		kick_peak = maxf(kick_peak, absf(g.px - px0))
		v_min = minf(v_min, g.v)
		var rel: float = g.zb - g.zr
		samples.append(rel)
		peak = maxf(peak, absf(rel))
		roll_peak = maxf(roll_peak, absf(g.roll))
		pitch_peak = maxf(pitch_peak, absf(g.pitch))
		if shots and v == 70.0 and i == 8:
			await shot("cockpit_pothole")
	var settle := -1.0
	for i in range(samples.size() - 1, -1, -1):
		if absf(samples[i]) > peak * 0.1:
			settle = (i + 1) * DT
			break
	# count swings: sign changes between samples that are each beyond 10% of the peak
	var crossings := 0
	var last_sign := 0.0
	for x in samples:
		if absf(x) > peak * 0.1:
			if last_sign != 0.0 and signf(x) != last_sign:
				crossings += 1
			last_sign = signf(x)
	var res = {"speed_kmh": v, "body_peak_units": r3(peak), "body_peak_screen_px": r3(peak * g.view.hh * 0.84 / 900.0 * 2.0),
		"settle_s": r3(settle), "oscillations": crossings / 2.0, "roll_peak_rad": r3(roll_peak), "pitch_peak_rad": r3(pitch_peak),
		"pitch_peak_screen_px": r3(pitch_peak * 190.0 * 2.0), "lateral_kick_peak_road": r3(kick_peak), "speed_lost_peak_kmh": r3(v - v_min)}
	await drop()
	return res

# Lap with a perfect lane keeper and no potholes: how much does the body move over the undulations?
func ride(v: float, seconds: float) -> Dictionary:
	await make(1, true)
	place(0, 0.0, v)
	g.set_auto(false)
	var p2 := 0.0
	var pmax := 0.0
	var b2 := 0.0
	var r2 := 0.0
	var n := 0
	for i in int(seconds / DT):
		g.bot_steer = clampf((0.0 - g.px) * 6.0 - g.vx * 2.0, -1.0, 1.0)
		await process_frame
		p2 += g.pitch * g.pitch
		pmax = maxf(pmax, absf(g.pitch))
		var rel: float = g.zb - g.zr
		b2 += rel * rel
		r2 += g.roll * g.roll
		n += 1
	var res := {"speed_kmh": v, "seconds": seconds, "pitch_rms_rad": r3(sqrt(p2 / n)), "pitch_max_rad": r3(pmax),
		"pitch_max_screen_px": r3(pmax * 190.0 * 2.0), "body_rms_units": r3(sqrt(b2 / n)), "roll_rms_rad": r3(sqrt(r2 / n))}
	await drop()
	return res

# Full drive with potholes, puddles and traffic. A careful bot looks ahead and swaps lanes to dodge.
func full_drive(v: float, seconds: float, look_s: float) -> Dictionary:
	await make(7, false, true)
	place(60, 0.667, v)
	g.set_auto(false)
	var tgt_lane := 2
	var off_t := 0.0
	var feats := 0
	var counted := {}
	var laps := 0
	var last_si := -1
	var lane_changes := 0
	for i in int(seconds / DT):
		var lookahead = int(g.v * g.UPK * look_s / g.SEG) + 1
		var base = int(g.pos / g.SEG)
		var danger := func(l: int) -> float:
			var d := 0.0
			for k in range(2, lookahead):
				var s = g.segs[(base + k) % g.N]
				for f in s.feat:
					if f.t != 1 and absf(f.x - g.LANES[l]) < f.w + 0.25:
						d += 1.0 / k
				for c in s.cars:
					if c.dir > 0 and absf(c.x - g.LANES[l]) < 0.3 and c.v < g.v:
						d += 2.0 / k
			return d
		if i % 6 == 0:
			var cur: float = danger.call(tgt_lane)
			if cur > 0.0:
				var best := tgt_lane
				for l in [tgt_lane - 1, tgt_lane + 1]:
					if l >= 0 and l < 3 and danger.call(l) < danger.call(best) * 0.5:
						best = l
				if best != tgt_lane:
					lane_changes += 1
				tgt_lane = best
		var e: float = g.LANES[tgt_lane] - g.px
		g.bot_steer = clampf(e * 5.0 - g.vx * 1.5, -1.0, 1.0)
		if absf(g.bot_steer) < 0.2:
			g.bot_steer = 0.0
		else:
			g.bot_steer = signf(g.bot_steer)
		await process_frame
		if absf(g.px) > 1.02:
			off_t += DT
		var si = int(g.pos / g.SEG)
		if si < last_si:
			laps += 1
		last_si = si
		var key = si + laps * g.N
		if not counted.has(key):
			counted[key] = true
			for f in g.segs[si % g.N].feat:
				if f.t == 0 or (f.t == 2 and f.a == 1.0):
					feats += 1
		if shots and i == 240:
			await shot("cockpit_drive")
		if shots and i == 480:
			g.set_cam(1)
			await step(30)
			await shot("chase_drive")
			g.set_cam(0)
	var minutes := seconds / 60.0
	var res := {"speed_kmh": v, "seconds": seconds, "lookahead_s": look_s, "hazards_passed": feats,
		"hazards_per_min": r3(feats / minutes), "holes_hit": g.n_holes, "puddles_hit": g.n_puddles, "car_bumps": g.n_bumps,
		"lane_changes": lane_changes, "offroad_s": r3(off_t), "score": int(g.score)}
	await drop()
	return res

func autopilot(seconds: float) -> Dictionary:
	await make(3, false, true)
	g.set_auto(true)
	await step(int(seconds / DT))
	var res = {"seconds": seconds, "holes_hit": g.n_holes, "puddles_hit": g.n_puddles, "car_bumps": g.n_bumps}
	await drop()
	return res

# How early a pothole becomes readable on screen (4 real pixels wide) vs. how long a lane change takes.
func visibility(v: float, lane_change_s: float) -> Dictionary:
	await make(1, false)
	var w := 0.09
	var z_vis := 0.84 * 2000.0 * 384.0 / 2.0 * 2.0 * w / 2.0   # logical units wide = 64512*w*... /z  -> solve for 2 logical units
	z_vis = minf(z_vis, g.DRAW * g.SEG)
	var lead = z_vis / (v * g.UPK)
	var res = {"speed_kmh": v, "hole_readable_at_units": r3(z_vis), "lead_time_s": r3(lead),
		"lane_change_s": lane_change_s, "margin_s": r3(lead - lane_change_s)}
	await drop()
	return res

func _run() -> void:
	var t0 := Time.get_ticks_msec()
	if OS.get_cmdline_user_args().has("--shots-only"):
		shots = true
		await _shots_only()
		quit()
		return
	out["lane_change"] = [await lane_change(50.0), await lane_change(70.0), await lane_change(95.0)]
	out["tap"] = [await tap(50.0), await tap(90.0)]
	out["curve_follow"] = [await curve_follow(70.0, 0.15), await curve_follow(95.0, 0.15)]
	out["pothole"] = [await pothole_response(40.0), await pothole_response(70.0), await pothole_response(95.0)]
	out["ride"] = [await ride(50.0, 40.0), await ride(70.0, 40.0), await ride(95.0, 40.0)]
	out["full_drive"] = [await full_drive(70.0, 120.0, 1.6), await full_drive(90.0, 120.0, 1.6)]
	out["autopilot"] = await autopilot(90.0)
	out["visibility"] = "medida na imagem renderizada: veja visibility_rendered (qa/shots/visibility.json, gerado por run_qa.sh)"
	if shots:
		await make(1, false, true)
		place(60, 0.667, 70.0)
		await step(180)
		await shot("cockpit_straight")
		g.set_cam(1)
		g._hit_feat({"t": 2, "x": g.px, "w": 0.2, "a": 1.0, "b": 1.0}, 0.7)
		await step(6)
		await shot("chase_puddle")
		g.bot_steer = -1.0
		await step(20)
		await shot("chase_lane_change")
		g.bot_steer = 0.0
		await drop()
	out["wall_time_s"] = (Time.get_ticks_msec() - t0) / 1000.0
	out["generated_at"] = Time.get_datetime_string_from_system()
	var f := FileAccess.open(ProjectSettings.globalize_path("res://qa/metrics/latest.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify(out, "  "))
	f.close()
	print(JSON.stringify(out, "  "))
	quit()


# Quick visual pass: a few seconds per picture, no metrics.
func _shots_only() -> void:
	await make(1, false, true)
	place(60, 0.667, 70.0)
	g.cars = g.cars.filter(func(c): return c.dir < 0 or fposmod(c.z - g.pos, g.TRACK) > 6000.0)   # nobody parked on our bumper at the start
	g.set_auto(true)
	await step(150)
	await shot("cockpit_drive")
	var fps_t := Time.get_ticks_msec()
	await step(60)
	var fps := 60000.0 / maxf(1.0, Time.get_ticks_msec() - fps_t)
	g._hit_feat({"t": 0, "x": g.px + 0.2, "w": 0.1}, 0.7)
	await step(8)
	await shot("cockpit_pothole")
	g.set_cam(1)
	await step(60)
	await shot("chase_drive")
	g._hit_feat({"t": 2, "x": g.px, "w": 0.2, "a": 1.0, "b": 1.0}, 0.7)
	await step(6)
	await shot("chase_puddle")
	g.bot_steer = -1.0
	await step(24)
	await shot("chase_lane_change")
	g.bot_steer = 0.0
	place(sharpest_bend() - 10, 0.667, 70.0)
	await step(90)
	await shot("chase_curve")
	await drop()
	var f := FileAccess.open(ProjectSettings.globalize_path("res://qa/shots/fps.txt"), FileAccess.WRITE)
	f.store_string("render fps (software renderer): %.1f\n" % fps)
	f.close()
	await _visibility_rendered()

# How far away is a pothole readable? Render the road with and without one hole and count changed pixels.
func _diff(a: Image, b: Image) -> int:
	var n := 0
	for y in range(0, a.get_height()):
		for x in range(0, a.get_width()):
			if a.get_pixel(x, y) != b.get_pixel(x, y):
				n += 1
	return n

func _visibility_rendered() -> void:
	var res := {"threshold_px": 30, "hole_w": 0.09, "cams": {}}
	for cam in [0, 1]:
		await make(1, true)
		g.Y.fill(0.0)
		for s in g.segs:
			s.y1 = 0.0
			s.y2 = 0.0
		var i0 := longest_straight()
		place(i0, 0.0, 0.0)
		g.target = 0.0
		g.rain = 0.0
		g.rain_goal = 0.0
		g.drops.clear()
		g.set_cam(cam)
		g.get_node("Cockpit").visible = false   # judge the road itself, not the cabin in front of it
		await step(20)
		var rows := []
		var readable := 0.0
		for z in [3000, 4000, 5000, 6000, 8000, 10000, 12000, 15000, 18000, 21000, 25000]:
			await step(2)
			var ref := root.get_texture().get_image()
			var cam_seg := int((g.pos - g.view.back) / g.SEG)
			var si := cam_seg + int((z + g.view.back) / g.SEG)
			g.segs[si % g.N].feat.append({"t": 0, "x": 0.667, "w": 0.09})
			await step(2)
			var img := root.get_texture().get_image()
			g.segs[si % g.N].feat.clear()
			var d := _diff(ref, img)
			rows.append([z, d])
			if d >= 30:
				readable = z
		res.cams["cockpit" if cam == 0 else "chase"] = {"pixels_changed_by_distance": rows, "readable_until_units": readable,
			"lead_time_70kmh_s": snappedf(readable / (70.0 * g.UPK), 0.01), "lead_time_95kmh_s": snappedf(readable / (95.0 * g.UPK), 0.01)}
		await drop()
	var f := FileAccess.open(ProjectSettings.globalize_path("res://qa/shots/visibility.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify(res, "  "))
	f.close()

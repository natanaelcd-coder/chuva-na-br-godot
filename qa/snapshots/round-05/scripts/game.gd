extends Node2D
# Chuva na BR: state, track, physics, traffic, weather, input and audio.
# World and Cockpit read this node every frame and only draw.

const Seg = preload("res://scripts/seg.gd")

const W := 384.0   # logical screen units; the viewport is 2 real pixels per unit
const H := 216.0
const SEG := 200.0
const DRAW := 150
const ROADW := 2000.0
const DEPTH := 0.84
const UPK := 95.0   # world units per km/h per second
const LANES := [-0.667, 0.0, 0.667]
const VIEWS := [
	{"hy": 64.0, "hh": 112.0, "camh": 820.0, "back": 0.0, "maxy": 140.0},      # inside
	{"hy": 86.0, "hh": 150.0, "camh": 1450.0, "back": 2300.0, "maxy": 232.0}]  # chase
const STATIONS := [
	{"name": "SERRA FM 98,7", "songs": [["TRIO ASFALTO", "CHUVA NA SERRA"], ["TRIO ASFALTO", "FAROL BAIXO"], ["DONA NEBLINA", "CAFÉ DE BEIRA DE ESTRADA"]]},
	{"name": "LITORAL FM 102,3", "songs": [["OS VAGALUMES", "JANELA ABERTA"], ["OS VAGALUMES", "MARESIA NO PAINEL"], ["ZÉ DA BALSA", "SAMBA DO ACOSTAMENTO"]]},
	{"name": "NOITE AM 1040", "songs": [["BANDA NEON", "KM 43"], ["BANDA NEON", "LUZ DE FREIO"], ["SINTONIA FINA", "ÚLTIMO PEDÁGIO"]]}]
const SIGN_COUNT := 6
const BOARD_COUNT := 4
const SAVE_PATH := "user://hiscore.txt"

@onready var hud = $HUD

# track
var segs: Array = []
var N := 0
var TRACK := 0.0
var Y := PackedFloat32Array()
var ROUGH := PackedFloat32Array()
var NOISE := PackedFloat32Array()
var postos: Array = []
var cars: Array = []
var tex := {}
var _last_y := 0.0
var _car_segs: Array = []

# driving state
var pos := 0.0
var px := 0.667      # lateral position, -1..1 is the road
var v := 0.0         # km/h
var target := 70.0
var steer := 0.0
var fuel := 0.8
var score := 0.0
var hi := 0.0
var clean := 0.0
var mult := 1
var tday := 0.0
var rain := 0.8
var rain_t := 20.0
var rain_goal := -1.0
var auto := true
var started := false
var bump_t := 0.0
var lane := 2
var low_warn := false
var sky := 0.0
var t := 0.0
var save_t := 0.0

# suspension: body height, pitch and roll on soft, lightly damped springs
var zb := 0.0
var zb_v := 0.0
var zr := 0.0
var zr_prev := 0.0
var cy := 0.0
var pitch := 0.0
var pitch_v := 0.0
var roll := 0.0
var roll_v := 0.0
var slope := 0.0
var vx := 0.0
var al := 0.0
var aqua := 0.0
var splash_t := 0.0
var kick := 0.0
var cam_x := 0.667
var brake := false
var car_scr := Vector3.ZERO   # player's car on screen in the chase view: x, y, scale
var has_car_scr := false

# camera
var cam := 0
var view: Dictionary = VIEWS[0]

# things that dangle in the cabin
var dice := 0.0
var dice_v := 0.0
var bob := 0.0
var bob_v := 0.0
var fan_a := 0.0
var wheel_a := 0.0
var lat := 0.0

# weather
var rain_p: Array = []   # [x, y, length, speed]
var drops: Array = []    # [x, y, size] on the windscreen
var parts: Array = []    # [x, y, vx, vy, life] spray in the chase view
var wip_s := 0.0
var wip_phase := 0.0
var wip_wait := 0.0
var wip_a := -0.1
var wip_prev := -0.1
const WIP := [Vector2(118, 124), Vector2(232, 124)]
const WLEN := 80.0
var stars: Array = []
var clouds: Array = []
var hill_f := PackedFloat32Array()
var hill_n := PackedFloat32Array()
var city_l: Array = []

# light of the hour
var SKY: Array = []
var e_top := Color.BLACK
var e_hor := Color.BLACK
var e_hf := Color.BLACK
var e_hn := Color.BLACK
var e_gr := Color.BLACK
var e_fog := Color.BLACK
var e_road0 := Color.BLACK
var e_road1 := Color.BLACK
var e_line := Color.WHITE
var e_amb := 0.7

# input
var touch_steer := 0.0
var press_lane := -1
var free_t := 0.0
var hold_x := 0.0
var prev_input := 0.0
# test hooks (tests/test_drive.gd): simulated keys and event counters
var bot_steer := 0.0
var bot_speed := 0.0
var n_holes := 0
var n_puddles := 0
var n_bumps := 0

# audio
var radio_st := 0
var radio_song := 0
var radio_time := 0.0
var static_t := 0.0
var sound_on := true
var a_music: AudioStreamPlayer
var a_rain: AudioStreamPlayer
var a_engine: AudioStreamPlayer
var a_rumble: AudioStreamPlayer
var a_hiss: AudioStreamPlayer
var sfx := {}
var music_streams: Array = []


func _ready() -> void:
	if Engine.has_meta("test_seed"):
		seed(Engine.get_meta("test_seed"))
	else:
		randomize()
	for n in ["tree0", "tree1", "araucaria", "bush", "pole", "lamp", "posto", "sign_posto", "player", "cockpit"]:
		tex[n] = load("res://assets/sprites/%s.png" % n)
	for i in 8:
		tex["car%d" % i] = load("res://assets/sprites/car%d.png" % i)
	for i in 3:
		tex["front%d" % i] = load("res://assets/sprites/front%d.png" % i)
	for i in SIGN_COUNT:
		tex["sign%d" % i] = load("res://assets/sprites/sign%d.png" % i)
	for i in BOARD_COUNT:
		tex["board%d" % i] = load("res://assets/sprites/board%d.png" % i)
	for i in 5:
		tex["label%d" % i] = load("res://assets/sprites/label%d.png" % i)
	SKY = [  # dusk, night, dawn, overcast morning
		{"top": Color("1e2c52"), "hor": Color("6f7fb0"), "hf": Color("2b3a63"), "hn": Color("152238"), "gr": Color("10261f"), "amb": 0.7},
		{"top": Color("070b18"), "hor": Color("1a2547"), "hf": Color("0f1730"), "hn": Color("090e1c"), "gr": Color("0a1614"), "amb": 0.38},
		{"top": Color("2a3560"), "hor": Color("e0957a"), "hf": Color("4a3f66"), "hn": Color("1c2238"), "gr": Color("14291f"), "amb": 0.75},
		{"top": Color("4a6a94"), "hor": Color("a9c0d8"), "hf": Color("4d6a88"), "hn": Color("27405a"), "gr": Color("1d4030"), "amb": 1.0}]
	_build_track()
	_populate()
	_build_surface()
	for i in range(1, N):   # warn before every rough stretch
		if ROUGH[i] > 0.25 and ROUGH[i - 1] <= 0.25:
			_add_spr(i - 70, "sign3", 1.38, 1700.0)
	_spawn_cars()
	_init_weather()
	_init_audio()
	if FileAccess.file_exists(SAVE_PATH):
		hi = float(FileAccess.get_file_as_string(SAVE_PATH))
	zb = road_y(pos, 1.0)
	zr = zb
	zr_prev = zb
	cy = zb
	_env()
	_now_playing()


# ---------------------------------------------------------------- track

func _add_seg(curve: float, y: float) -> void:
	var s = Seg.new()
	s.i = segs.size()
	s.curve = curve
	s.y1 = _last_y
	s.y2 = y
	segs.append(s)
	_last_y = y

func _eio(a: float, b: float, k: float) -> float:
	return a + (b - a) * (-cos(k * PI) / 2.0 + 0.5)

func _road(n: int, curve: float, hill: float) -> void:
	var e := n >> 2
	var hold := n - 2 * e
	var y0 := _last_y
	var y1 := y0 + hill * SEG
	for i in e:
		_add_seg(curve * pow(float(i) / e, 2.0), _eio(y0, y1, float(i) / n))
	for i in hold:
		_add_seg(curve, _eio(y0, y1, float(e + i) / n))
	for i in e:
		_add_seg(curve * pow(1.0 - float(i) / e, 2.0), _eio(y0, y1, float(e + hold + i) / n))

func _build_track() -> void:
	for r in [[80, 0, 0], [160, 1.6, 12], [120, 0, -10], [140, -2.2, 0], [100, 0, 22], [180, 2.6, -14], [220, 0, 0], [120, -1.4, 18], [120, 1.4, -18],
			[160, 0, 10], [200, -2.8, -20], [140, 0, 0], [160, 2, 26], [120, 0, -16], [200, -1.8, 0], [240, 0, 8], [160, 3, -10], [140, -3, 10], [200, 0, 0]]:
		_road(r[0], r[1], r[2])
	_road(120, 0.0, -_last_y / SEG)
	N = segs.size()
	TRACK = N * SEG

func _add_spr(i: int, t_name: String, off: float, ww: float, kind := 0) -> void:
	segs[posmod(i, N)].spr.append({"tex": tex[t_name], "off": off, "ww": ww, "kind": kind})

func _populate() -> void:
	var trees := ["tree0", "tree1", "araucaria", "araucaria"]
	for i in range(0, N, 14):
		_add_spr(i, "pole", 1.42, 1100.0, 1)
	for i in N:
		if randf() < 0.22:
			_add_spr(i, trees.pick_random(), randf_range(1.9, 5.5), randf_range(1500, 2400))
		if randf() < 0.2:
			_add_spr(i, trees.pick_random(), -randf_range(3.9, 7.0), randf_range(1500, 2400))
		if randf() < 0.1:
			_add_spr(i, "bush", randf_range(1.25, 1.7), 800.0)
	for k in 9:
		_add_spr(120 + k * int(N / 9.0), "sign%d" % [0, 1, 2, 4, 5][k % 5], 1.38, 1700.0)
	for k in 6:
		_add_spr(300 + k * int(N / 6.0), "board%d" % (k % BOARD_COUNT), 2.3, 2600.0)
	for f in [0.3, 0.78]:
		var i := int(N * f)
		postos.append(i)
		for d in range(-20, 21):   # clear the forecourt
			var s = segs[posmod(i + d, N)]
			s.spr = s.spr.filter(func(q): return q.kind == 1 or q.off < 0.0)
		_add_spr(i, "posto", 2.75, 5600.0, 3)
		_add_spr(i - 150, "sign_posto", 1.38, 1700.0)
		for d in range(-60, 61, 20):
			if absi(d) > 10:
				_add_spr(i + d, "lamp", 1.25, 1100.0, 2)

# Long undulations baked into the road height, rough stretches, potholes, patches, and puddles in the dips.
func _build_surface() -> void:
	Y.resize(N)
	ROUGH.resize(N)
	NOISE.resize(N)
	var zone := PackedFloat32Array()
	zone.resize(N)
	for i in N:
		var a := float(i) / N * TAU
		zone[i] = pow(maxf(0.0, sin(a * 6.0 + 1.0)), 1.5)
		Y[i] = segs[i].y1 + zone[i] * (70.0 * sin(a * 40.0) + 26.0 * sin(a * 187.0 + 2.0))
		ROUGH[i] = clampf(sin(a * 9.0 + 4.0) * 1.6 - 0.3, 0.0, 1.0)
		NOISE[i] = randf() * 2.0 - 1.0
	for i in N:
		segs[i].y1 = Y[i]
		segs[i].y2 = Y[(i + 1) % N]
	var last_hole := -100
	for i in range(60, N):
		if i - last_hole >= 12 and randf() < 0.001 + ROUGH[i] * 0.008:
			last_hole = i
			segs[i].feat.append({"t": 0, "x": LANES.pick_random() + randf_range(-0.22, 0.22), "w": randf_range(0.07, 0.12)})
		if ROUGH[i] > 0.25 and randf() < 0.3:
			segs[i].feat.append({"t": 1, "x": randf_range(-0.85, 0.85), "w": randf_range(0.1, 0.26)})
		if zone[i] > 0.25 and Y[i] < Y[i - 1] and Y[i] <= Y[(i + 1) % N] and randf() < 0.2:
			var fx: float = [-0.8, 0.8, -0.667, 0.0, 0.667].pick_random()
			var fw := randf_range(0.16, 0.3)
			for q in [[-2, 0.3, 0.8], [-1, 0.8, 1.0], [0, 1.0, 0.9], [1, 0.9, 0.35]]:
				segs[posmod(i + q[0], N)].feat.append({"t": 2, "x": fx, "w": fw, "a": q[1], "b": q[2]})

func road_y(z: float, rough := 0.0) -> float:
	z = fposmod(z, TRACK)
	var i := int(z / SEG) % N
	var j := (i + 1) % N
	var k := fmod(z, SEG) / SEG
	var y := lerpf(Y[i], Y[j], k)
	if rough > 0.0:
		y += lerpf(NOISE[i] * (0.25 + ROUGH[i]), NOISE[j] * (0.25 + ROUGH[j]), k) * rough * 16.0
	return y

func _spawn_cars() -> void:
	for i in 26:
		var l := i % 3
		var sp := randf_range(55, 68) if l == 0 else (randf_range(45, 58) if l == 1 else randf_range(34, 48))
		var name := "car7" if (l == 2 and randf() < 0.35) else "car%d" % (randi() % 7)
		cars.append({"z": randf_range(0, TRACK), "x": LANES[l], "v": sp, "tex": tex[name], "dir": 1})
	for i in 9:
		cars.append({"z": randf_range(0, TRACK), "x": -2.1 if i % 2 else -2.8, "v": -randf_range(50, 70), "tex": tex["front%d" % (randi() % 3)], "dir": -1})

func _init_weather() -> void:
	for i in 90:
		rain_p.append([randf_range(0, W), randf_range(0, 130), randf_range(3, 7), randf_range(160, 260)])
	for i in 50:
		stars.append(Vector2(floor(randf_range(0, W)), floor(randf_range(12, 50))))
	for i in 7:
		clouds.append([randf_range(0, 500), randf_range(14, 44), randf_range(40, 110), randf_range(5, 11)])
	hill_f.resize(512)
	hill_n.resize(512)
	for i in 512:
		var a := i / 512.0 * TAU
		hill_f[i] = 12.0 + 7.0 * sin(a * 3.0) + 4.0 * sin(a * 7.0 + 1.0) + 2.0 * sin(a * 17.0)
		hill_n[i] = 6.0 + 4.0 * sin(a * 5.0 + 2.0) + 3.0 * sin(a * 11.0) + 1.5 * sin(a * 29.0)
	for i in 34:
		city_l.append([randi() % 512, randi() % 5, randf() < 0.3])

func _env() -> void:
	var i := int(tday) % 4
	var f := tday - floorf(tday)
	var k := clampf((f - 0.45) / 0.55, 0.0, 1.0)
	var s := k * k * (3.0 - 2.0 * k)
	var a: Dictionary = SKY[i]
	var b: Dictionary = SKY[(i + 1) % 4]
	e_top = a.top.lerp(b.top, s)
	e_hor = a.hor.lerp(b.hor, s)
	e_hf = a.hf.lerp(b.hf, s)
	e_hn = a.hn.lerp(b.hn, s)
	e_gr = a.gr.lerp(b.gr, s)
	e_amb = lerpf(a.amb, b.amb, s)
	e_fog = e_hor.lerp(e_hn, 0.45)
	e_road0 = Color8(13, 17, 25).lerp(Color8(58, 67, 82), e_amb)
	e_road1 = Color8(14, 18, 27).lerp(Color8(60, 69, 85), e_amb)
	e_line = Color8(74, 77, 87).lerp(Color8(214, 220, 232), e_amb * 0.7 + 0.3)


# ---------------------------------------------------------------- audio

func _player(stream: AudioStream) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.stream = stream
	add_child(p)
	return p

func _init_audio() -> void:
	for i in 3:
		var m: AudioStreamOggVorbis = load("res://assets/audio/radio%d.ogg" % i)
		m.loop = true
		music_streams.append(m)
	a_music = _player(null)
	var r: AudioStreamOggVorbis = load("res://assets/audio/rain.ogg")
	r.loop = true
	a_rain = _player(r)
	a_rain.volume_db = -80.0
	var e: AudioStreamWAV = load("res://assets/audio/engine.wav")
	e.loop_mode = AudioStreamWAV.LOOP_FORWARD
	e.loop_begin = 0
	e.loop_end = int(e.get_length() * e.mix_rate)
	a_engine = _player(e)
	a_engine.volume_db = -80.0
	a_rumble = _player(_noise_loop(true))
	a_rumble.volume_db = -80.0
	a_hiss = _player(_noise_loop(false))
	a_hiss.volume_db = -80.0
	for n in ["hole", "bump", "splash", "static", "wiper", "horn"]:
		sfx[n] = _player(load("res://assets/audio/%s.wav" % n))

# 1 s noise loops made at start-up: low rumble for rough asphalt and the shoulder, hiss for wet tyres
func _noise_loop(low: bool) -> AudioStreamWAV:
	var rate := 22050
	var data := PackedByteArray()
	data.resize(rate * 2)
	var y := 0.0
	var prev := 0.0
	for i in rate:
		var w := randf() * 2.0 - 1.0
		var x: float
		if low:
			y += (w - y) * 0.04   # one-pole low-pass: gravelly rumble
			x = y * 3.0
		else:
			x = (w - prev) * 0.5    # first difference: hiss
			prev = w
		var fade := minf(1.0, minf(i, rate - i) / 400.0)
		data.encode_s16(i * 2, int(clampf(x * fade, -1.0, 1.0) * 30000.0))
	var st := AudioStreamWAV.new()
	st.format = AudioStreamWAV.FORMAT_16_BITS
	st.mix_rate = rate
	st.data = data
	st.loop_mode = AudioStreamWAV.LOOP_FORWARD
	st.loop_end = rate
	return st

func _sfx(n: String) -> void:
	if started:
		sfx[n].play()

func _now_playing() -> void:
	if radio_st < STATIONS.size():
		var st: Dictionary = STATIONS[radio_st]
		var song: Array = st.songs[radio_song]
		hud.set_now("TOCANDO: %s - %s - %s" % [song[0], song[1], st.name])
	else:
		hud.set_now("TOCANDO: SÓ A CHUVA")

func _tune() -> void:
	radio_song = 0
	radio_time = 0.0
	a_music.stop()
	if radio_st < STATIONS.size():
		a_music.stream = music_streams[radio_st]
		a_music.play()
	_now_playing()

func next_station() -> void:
	radio_st = (radio_st + 1) % (STATIONS.size() + 1)
	static_t = 0.35
	_sfx("static")
	_tune()

func set_sound(on: bool) -> void:
	sound_on = on
	AudioServer.set_bus_mute(0, not on)
	hud.toast("SOM LIGADO" if on else "SOM DESLIGADO", 1.5)


# ---------------------------------------------------------------- input

func begin() -> void:
	if started:
		return
	started = true
	target = 70.0
	hud.hide_start()
	set_auto(false)
	a_rain.play()
	a_engine.play()
	a_rumble.play()
	a_hiss.play()
	_tune()
	hud.toast("BOA VIAGEM", 3.0)

func set_auto(on: bool) -> void:
	auto = on
	if started:
		hud.toast("PILOTO AUTOMÁTICO: SÓ CURTA A VIAGEM" if on else "VOCÊ NO VOLANTE")

func set_cam(c: int) -> void:
	cam = c
	view = VIEWS[c]
	$Cockpit.visible = c == 0
	if started:
		hud.toast("CÂMERA EXTERNA" if c == 1 else "CÂMERA INTERNA", 1.5)

func _unhandled_input(ev: InputEvent) -> void:
	if ev is InputEventKey and ev.pressed and not ev.echo:
		var k: int = ev.physical_keycode
		if k == KEY_F11:
			var full := DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if full else DisplayServer.WINDOW_MODE_FULLSCREEN)
		elif not started:
			if k == KEY_ENTER or k == KEY_KP_ENTER or k == KEY_SPACE:
				begin()
		elif k == KEY_R:
			next_station()
		elif k == KEY_P:
			set_auto(not auto)
		elif k == KEY_M:
			set_sound(not sound_on)
		elif k == KEY_V:
			set_cam(1 - cam)
		elif k == KEY_B or k == KEY_H:
			_sfx("horn")
	elif ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT:
		if not ev.pressed:
			touch_steer = 0.0
		elif not started:
			begin()
		else:
			var p: Vector2 = ev.position / 2.0
			if cam == 0 and p.x > 182 and p.x < 254 and p.y > 136 and p.y < 172:
				next_station()   # the radio on the dashboard
			else:
				touch_steer = -1.0 if p.x < W * 0.42 else (1.0 if p.x > W * 0.58 else 0.0)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_save_hi()

func _save_hi() -> void:
	if Engine.has_meta("test_seed"):
		return
	if score > hi:
		var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
		if f:
			f.store_string(str(int(score)))


# ---------------------------------------------------------------- update

func _splash() -> void:
	for i in 60:
		drops.append([randf_range(34, 350), randf_range(40, 119), 2.0 if randf() < 0.5 else 1.0])
	if cam == 1 and has_car_scr:
		for i in 40:
			var side := -1.0 if i % 2 else 1.0   # two fans of spray, one off each side
			parts.append([car_scr.x + side * randf_range(18, 32) * car_scr.z, car_scr.y - randf_range(0, 6), side * randf_range(60, 140), randf_range(-140, -40), randf_range(0.4, 0.9)])
	sfx["splash"].volume_db = linear_to_db(0.4 + 0.6 * clampf(v / 100.0, 0.0, 1.0))
	_sfx("splash")

func _hit_feat(f: Dictionary, sp: float) -> void:
	var d: float = f.x - px
	if f.t == 0:   # pothole: which wheel took it?
		var l: bool = absf(d + 0.2) < f.w + 0.06
		var r: bool = absf(d - 0.2) < f.w + 0.06
		if not l and not r:
			return
		var side := 0.0 if (l and r) else (-1.0 if l else 1.0)
		var k := 0.5 + sp
		zb_v += 500.0 * k
		roll_v += side * 0.36 * k
		pitch_v += 0.7 * minf(k, 1.35)
		vx += side * 0.25 * k / 1.45   # the wheel is yanked toward the hole
		aqua = maxf(aqua, 0.2)         # a moment with loose grip and no lane magnet
		kick = side * 0.4 if side != 0.0 else randf_range(-0.25, 0.25)
		v = maxf(0.0, v - 3.0)
		bob_v += 10.0
		dice_v += randf_range(-3, 3)
		clean = maxf(0.0, clean - 8.0)
		n_holes += 1
		sfx["hole"].volume_db = linear_to_db(0.35 + 0.65 * clampf(k / 1.45, 0.0, 1.0))
		_sfx("hole")
		if started and hud.toast_t <= 0.0:
			hud.toast(["EITA, BURACO!", "OPA, BURACO!", "ESSE PEGOU..."].pick_random(), 1.3)
	elif f.t == 2:   # puddle: drag, a tug on the wheel, a moment of aquaplaning
		if absf(d) > f.w + 0.24 or splash_t > 0.0 or sp < 0.15:
			return
		splash_t = 0.7
		aqua = 0.5
		vx += (1.0 if d >= 0.0 else -1.0) * 0.24 * sp
		v = maxf(0.0, v - 5.0 * sp)
		zb_v -= 60.0
		n_puddles += 1
		_splash()

# autopilot: weigh potholes, puddles and slower cars over the next ~1.6 s in each lane
func _danger(l: int, bi: int) -> float:
	var look := int(v * UPK * 1.6 / SEG) + 1
	var d := 0.0
	for k in range(2, look):
		for f in segs[(bi + k) % N].feat:
			if f.t != 1 and absf(f.x - LANES[l]) < f.w + 0.25:
				d += 1.0 / k
	return d + (2.0 if _car_ahead(l) < 3000.0 else 0.0)

var _dodge_t := 0.0
func _auto_dodge(bi: int) -> void:
	_dodge_t -= get_process_delta_time()
	if _dodge_t > 0.0:
		return
	_dodge_t = 0.1
	var cur := _danger(lane, bi)
	if cur <= 0.0:
		return
	var best := lane
	for l in [lane - 1, lane + 1]:
		if l >= 0 and l < 3 and not _lane_busy(l, 1600.0, false) and _danger(l, bi) < _danger(best, bi) * 0.5:
			best = l
	lane = best

func _car_ahead(l: int) -> float:
	var best := 1e9
	for c in cars:
		if c.dir > 0 and absf(c.x - LANES[l]) < 0.3 and c.v < v:
			var d := fposmod(c.z - pos, TRACK)
			if d < best:
				best = d
	return best

func _lane_busy(l: int, back: float, slower_only: bool) -> bool:
	for c in cars:
		if c.dir > 0 and absf(c.x - LANES[l]) < 0.3 and fposmod(c.z - pos + back, TRACK) < 5200.0:
			if not slower_only or c.v < v + 4.0:
				return true
	return false

func _process(dt: float) -> void:
	dt = minf(dt, 0.05)
	t += dt
	tday = fmod(tday + dt / 110.0, 4.0)
	_env()
	# rain comes and goes
	rain_t -= dt
	if rain_t <= 0.0:
		rain_goal = 0.0 if randf() < 0.25 else randf_range(0.35, 1.0)
		rain_t = randf_range(35, 80)
	if rain_goal >= 0.0:
		rain += clampf(rain_goal - rain, -dt * 0.04, dt * 0.04)

	# speed: cruise control
	var up := Input.is_physical_key_pressed(KEY_UP) or Input.is_physical_key_pressed(KEY_W) or bot_speed > 0.0
	var dn := Input.is_physical_key_pressed(KEY_DOWN) or Input.is_physical_key_pressed(KEY_S) or bot_speed < 0.0
	if started:
		target = clampf(target + (float(up) - float(dn)) * 28.0 * dt, 0.0, 100.0)
	var tgt := target if started else 55.0
	if fuel <= 0.0:
		tgt = minf(tgt, 25.0)
	var off := absf(px) > 1.02
	if off:
		tgt = minf(tgt, 30.0)
	var close := false
	if started and not auto:   # cruise control yields to the car ahead instead of ramming it
		for c in cars:
			if c.dir > 0 and absf(c.x - px) < 0.46:
				var dd := fposmod(c.z - pos, TRACK)
				if dd > 250.0 and dd < 9000.0:   # square-root braking curve: always enough room to slow down
					tgt = minf(tgt, c.v + signf(dd - 1600.0) * sqrt(absf(dd - 1600.0) * 0.5))
					close = close or (dd < 4000.0 and v > c.v + 15.0)   # someone slow just appeared close: brake firmly
	var v0 := v
	v += clampf(tgt - v, (-70.0 if close else -34.0) * dt, 13.0 * dt)
	brake = tgt < v - 1.5
	var sp := v / 100.0
	var base = segs[int(pos / SEG) % N]
	var curve: float = base.curve

	# steering: slow steering box -> tyres that take a moment to bite -> lateral velocity
	var right := Input.is_physical_key_pressed(KEY_RIGHT) or Input.is_physical_key_pressed(KEY_D)
	var left := Input.is_physical_key_pressed(KEY_LEFT) or Input.is_physical_key_pressed(KEY_A)
	var dir := clampf(float(right) - float(left) + touch_steer + bot_steer, -1.0, 1.0)
	if dir != 0.0 and auto and started:
		set_auto(false)
	var is_auto := auto or not started
	if is_auto:
		_auto_dodge(base.i)
		var ahead := _car_ahead(lane)
		if ahead < 2500.0:
			v = maxf(v - 30.0 * dt * (1.0 - ahead / 2500.0), 25.0)
		if _lane_busy(lane, 0.0, true) and absf(px - LANES[lane]) < 0.25:
			var moved := false
			for l in [lane - 1, lane + 1]:
				if l >= 0 and l < 3 and not _lane_busy(l, 1600.0, false):
					lane = l
					moved = true
					break
			if not moved:
				v = maxf(v - 40.0 * dt, 30.0)
		if fuel < 0.6 and not _lane_busy(2, 1600.0, false):
			for p in postos:
				if posmod(p - base.i, N) < 220:
					lane = 2
		dir = clampf((LANES[lane] - px) * 2.4 - vx * 1.6, -0.4, 0.4)
	else:
		lane = 0 if px < -0.33 else (2 if px > 0.33 else 1)
		if dir != 0.0 and prev_input == 0.0:
			press_lane = lane
		free_t = 0.0 if dir != 0.0 else free_t + dt
		if free_t > 0.5 and free_t - dt <= 0.5 and lane == press_lane:   # the nudge is over: keep the line the player chose
			hold_x = clampf(px, LANES[lane] - 0.2, LANES[lane] + 0.2)
	prev_input = dir if not is_auto else 0.0
	var rate := 5.0 if absf(dir) > absf(steer) else 12.0   # quick to centre, a little slower to turn in
	steer += clampf(dir - steer, -dt * rate, dt * rate)
	aqua = maxf(0.0, aqua - dt)
	splash_t = maxf(0.0, splash_t - dt)
	var grip := (1.0 - 0.3 * rain * sp) * (0.3 if aqua > 0.0 else 1.0)
	var vx0 := vx
	vx += (steer * 1.0 * minf(1.0, sp * 2.5) - vx) * minf(1.0, dt * 9.0 * grip)
	if dir == 0.0 and not is_auto and aqua <= 0.0 and absf(px) < 1.02:
		if lane != press_lane:   # just changed lane (or never steered): settle into the lane centre
			px += (LANES[lane] - px) * minf(1.0, 2.5 * dt)
		elif free_t > 0.5:       # hands off after a nudge: hold that line, even through the bend
			px += (hold_x - px) * minf(1.0, 2.5 * dt) + curve * sp * sp * dt * 0.16
		else:                    # small correction in the same lane: only a weak pull, fine control stays
			vx += (LANES[lane] - px) * 1.5 * dt
	px += vx * dt - (0.0 if is_auto else curve * sp * sp * dt * 0.16)
	if px < -1.06:
		px = -1.06
		vx = maxf(vx, 0.0)
	if px > 1.7:
		px = 1.7
		vx = minf(vx, 0.0)
	al = lerpf(al, (vx - vx0) / maxf(dt, 0.001), minf(1.0, dt * 9.0))
	lat = lerpf(lat, vx * 0.5 + curve * sp * 0.22, minf(1.0, dt * 5.0))
	kick *= 1.0 - minf(1.0, dt * 7.0)
	wheel_a = lerpf(wheel_a, clampf(steer * 0.95 + curve * sp * 0.1 + kick, -1.2, 1.2), minf(1.0, dt * 12.0))

	# move, and whatever the wheels run over
	var prev_i: int = base.i
	pos = fmod(pos + v * UPK * dt, TRACK)
	sky += curve * sp * dt * 26.0
	var cur_i := int(pos / SEG) % N
	if cur_i != prev_i:
		var i := (prev_i + 1) % N
		for n in 4:
			for f in segs[i].feat:
				_hit_feat(f, sp)
			if postos.has(i):
				if px > 0.25:
					fuel = 1.0
					low_warn = false
					if started:
						score += 500.0
						hud.toast("TANQUE CHEIO  +500")
				elif fuel < 0.5 and started:
					hud.toast("O POSTO PASSOU... NA PRÓXIMA, ENCOSTE À DIREITA")
			if i == cur_i:
				break
			i = (i + 1) % N

	# suspension: the body floats over the undulations and takes a while to settle
	var rough := 1.7 if off else (1.3 if px > 0.33 else (0.6 if px < -0.33 else 1.0))
	zr = road_y(pos, rough)
	var zr_v := (zr - zr_prev) / maxf(dt, 0.001)
	if absf(zr_v) > 5000.0:
		zr_v = 0.0
	zr_prev = zr
	zb_v += (-46.0 * (zb - zr) - 3.0 * (zb_v - zr_v)) * dt
	zb = clampf(zb + zb_v * dt, zr - 240.0, zr + 240.0)
	cy += (zr - cy) * minf(1.0, dt * 3.0)
	if absf(zr - cy) > 700.0:
		cy = zr
	var sl := (road_y(pos + 700.0) - road_y(pos - 700.0)) / 1400.0
	slope += (sl - slope) * minf(1.0, dt * 1.6)
	var pt := (0.025 + 0.015 * sp) * tanh((sl - slope) / 0.05) - clampf((v - v0) / maxf(dt, 0.001), -40.0, 20.0) * 0.0011
	pitch_v += (-58.0 * (pitch - pt) - 6.0 * pitch_v) * dt
	pitch = clampf(pitch + pitch_v * dt, -0.12, 0.12)
	var rt := -clampf(al * 0.013 + curve * sp * sp * 0.024, -0.1, 0.1)
	roll_v += (-36.0 * (roll - rt) - 2.5 * roll_v + (randf_range(-3, 3) * sp if off else 0.0)) * dt
	roll = clampf(roll + roll_v * dt, -0.16, 0.16)
	cam_x += (px - cam_x) * minf(1.0, dt * 2.4)

	if started:
		fuel = maxf(0.0, fuel - dt / 250.0 * (v / 70.0))
		if fuel < 0.2 and not low_warn:
			low_warn = true
			hud.toast("NA RESERVA: POSTO NA FAIXA DA DIREITA", 4.0)
		if not off and v > 20.0:
			clean += dt
		elif off:
			clean = 0.0
		var m := 1 + mini(3, int(clean / 25.0))
		if m > mult:
			hud.toast("DIREÇÃO SUAVE  x%d" % m)
		mult = m
		score += v * dt * 2.0 * mult
		save_t += dt
		if save_t > 3.0:
			save_t = 0.0
			_save_hi()

	# traffic
	for s in _car_segs:
		s.cars.clear()
	_car_segs.clear()
	bump_t -= dt
	for c in cars:
		var cv: float = c.v
		if c.dir > 0:
			for o in cars:
				if o != c and o.dir > 0 and o.x == c.x and o.v < cv and fposmod(o.z - c.z, TRACK) < 1500.0:
					cv = o.v
			var d := fposmod(c.z - pos, TRACK)
			var dxl := absf(c.x - px)
			if d > TRACK - 1400.0 and dxl < 0.5:
				cv = minf(cv, v)
			if d < 1250.0 and d > 250.0 and dxl < 0.46 and v > c.v:
				sfx["bump"].volume_db = linear_to_db(0.4 + 0.6 * clampf((v - c.v) / 40.0, 0.0, 1.0))
				v = lerpf(v, maxf(0.0, cv - 6.0), 0.6)
				if bump_t <= 0.0 and started:   # a nudge costs one step of the multiplier, not all of it
					bump_t = 2.0
					mult = maxi(1, mult - 1)
					clean = minf(clean, (mult - 1) * 25.0)
					bob_v += 9.0
					dice_v += 3.0
					pitch_v -= 0.5
					hud.toast("OPA! SEM PRESSA")
					n_bumps += 1
					_sfx("bump")
		c.z = fposmod(c.z + cv * UPK * dt, TRACK)
		var cs = segs[int(c.z / SEG) % N]
		cs.cars.append(c)
		_car_segs.append(cs)

	# dangling things follow the body
	dice_v += (-dice * 30.0 - dice_v * 1.6 - lat * 26.0 - roll_v * 6.0) * dt
	dice = clampf(dice + dice_v * dt, -0.9, 0.9)
	bob_v += (-bob * 90.0 - bob_v * 3.0 + (randf() - 0.5) * sp * 60.0 + lat * 20.0 + (zb_v - zr_v) * 0.12) * dt
	bob = clampf(bob + bob_v * dt, -1.0, 1.0)
	fan_a += dt * 14.0

	# rain streaks, wheel spray, drops on the glass, wipers
	var rb := H if cam == 1 else 126.0
	for p in rain_p:
		p[1] += p[3] * dt
		p[0] -= p[3] * dt * 0.35 + sp * 30.0 * dt
		if p[1] > rb:
			p[1] = -8.0
			p[0] = randf_range(0, W + 40)
	if cam == 1 and has_car_scr and rain > 0.15 and sp > 0.2 and randf() < rain * sp * 1.6:
		var sd := -23.0 if randf() < 0.5 else 23.0
		parts.append([car_scr.x + (sd + randf_range(-3, 3)) * car_scr.z, car_scr.y - 2.0, randf_range(-12, 12) + sd * 0.4, randf_range(-45, -15), randf_range(0.15, 0.4)])
	for i in range(parts.size() - 1, -1, -1):
		var p: Array = parts[i]
		p[4] -= dt
		p[3] += 260.0 * dt
		p[0] += p[2] * dt
		p[1] += p[3] * dt
		if p[4] <= 0.0:
			parts.remove_at(i)
	var spawn := rain * 110.0 * dt
	while spawn > randf() and drops.size() < 260:
		drops.append([randf_range(34, 350), randf_range(40, 119), 2.0 if randf() < 0.3 else 1.0])   # keep the horizon band clear so the road ahead reads
		spawn -= 1.0
	for d in drops:
		d[1] -= sp * 2.5 * dt * d[2]
	wip_prev = wip_a
	if wip_phase > 0.0 or rain > 0.08:
		if wip_phase <= 0.0:
			wip_wait -= dt
		if wip_phase > 0.0 or wip_wait <= 0.0:
			wip_phase += dt / 1.5
			if wip_phase >= 1.0:
				wip_phase = 0.0
				wip_wait = (1.0 - rain) * 5.0
				if cam == 0:
					_sfx("wiper")
			wip_s = sin(wip_phase * PI)
	wip_a = lerpf(-0.1, -2.05, wip_s)
	if wip_a != wip_prev:
		var lo := minf(wip_a, wip_prev) - 0.03
		var hi2 := maxf(wip_a, wip_prev) + 0.03
		for i in range(drops.size() - 1, -1, -1):
			var d: Array = drops[i]
			for w in WIP:
				var dd := Vector2(d[0] - w.x, d[1] - w.y)
				if dd.length_squared() < WLEN * WLEN:
					var a := dd.angle()
					if a >= lo and a <= hi2:
						drops.remove_at(i)
						break
	for i in range(drops.size() - 1, -1, -1):
		if drops[i][1] < 13.0:
			drops.remove_at(i)
	if (drops.size() > 230 or rain < 0.05) and drops.size() > 0:
		drops.remove_at(0)

	# audio follows the drive
	if started:
		a_rain.volume_db = linear_to_db(maxf(rain * 0.09, 0.0001))
		a_engine.volume_db = linear_to_db(0.05 + sp * 0.03)
		a_engine.pitch_scale = (38.0 + v * 0.75) / 60.0
		a_rumble.volume_db = linear_to_db(maxf(0.0001, ((rough - 0.6) * 0.04 + ROUGH[int(pos / SEG) % N] * 0.10) * sp + (0.1 if off else 0.0)))
		a_rumble.pitch_scale = 0.8 + 0.4 * sp
		a_hiss.volume_db = linear_to_db(maxf(0.0001, clampf(absf(curve * sp * sp) * 0.04 + aqua * 0.12 + rain * sp * 0.015, 0.0, 0.15)))
		if off:
			kick += randf_range(-0.05, 0.05)
		static_t = maxf(0.0, static_t - dt)
		if radio_st < STATIONS.size():
			radio_time += dt
			if radio_time >= music_streams[radio_st].get_length():
				radio_time = 0.0
				radio_song = (radio_song + 1) % STATIONS[radio_st].songs.size()
				_now_playing()

	var gear := "N" if v < 1.0 else ("1ª" if v < 16.0 else ("2ª" if v < 32.0 else ("3ª" if v < 52.0 else "4ª")))
	hud.set_values(score, hi, v, gear, fuel)

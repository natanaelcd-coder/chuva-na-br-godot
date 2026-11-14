extends Node2D
# Chuva na BR: state, track, physics, traffic, weather, input and audio.
# World and Cockpit read this node every frame and only draw.

const Seg = preload("res://scripts/seg.gd")
const Cat = preload("res://scripts/catalog.gd")

const W := 384.0   # logical screen units; the viewport is 2 real pixels per unit
const H := 216.0
const SEG := 200.0
const DRAW := 150
const DEPTH := 0.84
const UPK := 95.0   # world units per km/h per second
const VIEWS := [
	{"hy": 64.0, "hh": 112.0, "camh": 820.0, "back": 0.0, "maxy": 140.0},      # inside
	{"hy": 86.0, "hh": 150.0, "camh": 1450.0, "back": 2300.0, "maxy": 232.0}]  # chase
const SIGN_COUNT := 6
const BOARD_COUNT := 4
const SAVE_PATH := "user://hiscore.txt"
const CFG_PATH := "user://viagem.cfg"
const SPRITES := ["tree0", "tree1", "araucaria", "bush", "pole", "lamp", "posto", "sign_posto", "player", "cockpit",
	"cockpit_picape", "player_picape", "cockpit_gt", "player_gt", "trator", "onibus", "mod0", "mod1", "mod2", "mod3",
	"front_mod0", "front_mod1", "cerca", "eucalipto", "cafe", "casa_sitio", "capela", "vaca0", "vaca1", "porteira",
	"placa_queijo", "placa_ovos", "placa_gado", "venda", "ipe", "bambu", "placa_sitio0", "placa_sitio1", "placa_sitio2",
	"placa_venda", "luminaria", "muro", "portico", "led0", "led1", "sos", "placa_radar", "placa_saida", "placa_pedagio",
	"placa_parada", "parada", "boiadeiro", "moto0", "moto1", "front_moto0", "front_moto1", "van0", "van1", "front_van0"]

# the trip the player picked (menu), and what it resolves to
var cfg := {"car": "besouro", "road": "br", "weather": "chuva", "time": "entardecer"}
var car: Dictionary = Cat.CARS["besouro"]
var road: Dictionary = Cat.ROADS["br"]
var LANES: Array = [-0.667, 0.0, 0.667]
var ROADW := 2000.0
var state := "menu"   # menu | drive | pause | parada | foto (the last two belong to features and freeze the drive)
var fog_k := 1.0      # how thick the haze is: rain 1.0, sun lighter
var headlight := 0.16
var his := {}         # best score per road

# --- extension points for scripts/features/*.gd (each feature is a Node child of this one; see scripts/features/README.md)
signal setup_done                                   # the trip was (re)built: new road, car, weather
signal trip_started                                 # the player took the wheel
signal trip_ended(summary: Dictionary)              # back to the menu: km, minutes, holes, puddles, bumps, score
signal seg_passed(i: int)                           # the car crossed road segment i
signal hole_hit(f: Dictionary, side: float, k: float)
signal hole_missed(f: Dictionary, d: float)         # a pothole passed under the car without touching a wheel
signal puddle_hit(f: Dictionary)
signal bumped(kind: String)                         # "rear", "side", "oncoming", "rail"
signal refueled(stop_i: int)
signal jumped(air_s: float, k: float)               # the car landed after flying off a crest: seconds in the air, how hard (0..1)
var features: Array = []
var store := ConfigFile.new()   # one save file for everything (user://viagem.cfg); use store_get/store_set
var km_trip := 0.0              # km driven since the player took the wheel
var trip_time := 0.0            # seconds since then
var view_sway := 1.0            # comfort: scales how much the view rolls and pitches with the body
var view_shake := 1.0           # comfort: 0 keeps the inside camera on the road line instead of the bouncing body
var trip_seed := 0              # seed this trip's road and traffic were drawn with (0: not reseeded, as in tests)
var next_seed := 0              # set before setup() to rebuild a given trip (trip code, trip of the day)

@onready var hud = $HUD
@onready var menu = $Menu

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
var wet_k := 1.0            # how wet the world looks (road, puddles): 1 rain, 0 dry; follows the rain when the weather varies
var sky_k := 1.0            # how overcast the sky is: 1 rain palette, 0 clear palette (sun, moon, stars)
var mixed_weather := false  # weather that comes and goes (VARIÁVEL, summer showers): a feature drives rain_goal, wet_k and sky_k
var showers := false        # summer showers also on a sunny trip (set by a feature before setup)
var auto := true
# who drives: 0 DESLIGADO (you steer and hold the speed yourself), 1 ASSISTIDO (cruise control, lane keeping,
# keeps the distance to the car ahead; you choose the lane), 2 LIGADO (the autopilot drives). P cycles them.
var drive_mode := 1
const MODE_NAMES := ["DESLIGADO", "ASSISTIDO", "LIGADO"]
var started := false
var bump_t := 0.0
var lane := 2
var low_warn := false
var sky := 0.0
var t := 0.0
var save_t := 0.0

# suspension: body height, pitch and roll on springs that settle in about a second (per car, catalog.gd)
# pitch > 0: nose up (the world sinks in the windscreen, the tail squats in the chase view)
# roll > 0: leaning to the right, i.e. out of a left-hand bend (the world turns anticlockwise in the windscreen)
const GRAV := 7000.0   # units/s2 pulling the car back down when a crest throws it in the air
var zb := 0.0
var zb_v := 0.0
var zw := 0.0        # height of the wheels: the road, except during a jump
var zw_v := 0.0
var air := false     # wheels off the ground
var air_t := 0.0
var land_t := 0.0    # counts down after a landing (dust, spray)
var land_k := 0.0    # how hard that landing was, 0..1
var n_jumps := 0
var CREST := PackedFloat32Array()   # height each segment owes to a crest (already included in Y)
var _crest_at := {}                 # block -> absolute start segment of its crest (-1: none)
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
var WIP: Array = [Vector2(118, 124), Vector2(232, 124)]
var WLEN := 80.0
var glass := Rect2(34, 40, 316, 79)
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
var last_gear_lo := -1.0
var off_t := 0.0
var gear_i := 0
var gear_cand_t := 0.0
var GEAR_LO: Array = [0.0, 16.0, 32.0, 52.0]
var GEAR_HI: Array = [16.0, 32.0, 52.0, 110.0]
var auto_off := 0.0
var overtaking := false   # autopilot borrowing the oncoming lane on a two-way road   # autopilot's offset inside its lane (dirt road: it dodges without leaving the lane)
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
var STATIONS: Array = []   # what R cycles through ({name, short, label, ...}); scripts/features/radio.gd fills it and runs the radio
var radio_song := 0
var radio_time := 0.0
var static_t := 0.0
var sound_on := true
var a_music: AudioStreamPlayer
var a_rain: AudioStreamPlayer
var a_roof: AudioStreamPlayer   # rain drumming on the roof, loud from the cockpit (assets/audio/chuva_teto.ogg)
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
	for n in SPRITES:
		tex[n] = AnimTex.load_sprite(n)
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
	_load_cfg()
	_load_features()
	setup()
	_init_audio()
	a_rain.play()
	a_roof.play()
	_tune()
	menu.show_main()

# Rebuilds the whole trip from cfg: car, road, traffic, weather, time. Called again whenever the menu changes something.
func setup() -> void:
	trip_seed = next_seed if next_seed > 0 else (0 if Engine.has_meta("test_seed") else randi_range(1, 9999))
	next_seed = 0
	if trip_seed > 0:   # the same seed and options draw the same road and traffic
		seed(trip_seed)
	mixed_weather = cfg.weather == "variavel" or (cfg.weather == "sol" and showers)
	car = Cat.CARS[cfg.car]
	road = Cat.ROADS[cfg.road]
	LANES = road.lanes
	ROADW = road.roadw
	GEAR_LO = car.gear_lo
	GEAR_HI = car.gear_hi
	var lay: Dictionary = car.layout
	WIP = [Vector2(lay.wipers[0][0], lay.wipers[0][1]), Vector2(lay.wipers[1][0], lay.wipers[1][1])]
	WLEN = lay.wlen
	glass = Rect2(lay.glass[0], lay.glass[1], lay.glass[2] - lay.glass[0], lay.glass[3] - lay.glass[1])
	segs.clear()
	postos.clear()
	cars.clear()
	_car_segs.clear()
	parts.clear()
	drops.clear()
	rain_p.clear()
	stars.clear()
	clouds.clear()
	city_l.clear()
	_last_y = 0.0
	_build_track()
	_populate()
	_build_surface()
	for i in range(1, N):   # warn before every rough stretch
		if ROUGH[i] > 0.25 and ROUGH[i - 1] <= 0.25:
			_add_spr(i - 95, "sign3" if cfg.road != "terra" else "placa_gado", 1.38, 1700.0, 4)   # ~2 s of warning at 100 km/h
	_spawn_cars()
	_init_weather()
	rain = 0.8 if cfg.weather == "chuva" else 0.0
	rain_goal = -1.0
	fog_k = 1.0 if cfg.weather == "chuva" else 0.55
	wet_k = 1.0 if cfg.weather == "chuva" else 0.0
	sky_k = wet_k
	tday = Cat.TIMES[cfg.time].tday
	hi = float(his.get(cfg.road, 0.0))
	pos = 0.0
	lane = road.ours.back()
	overtaking = false
	px = LANES[lane]
	cam_x = px
	vx = 0.0
	steer = 0.0
	press_lane = -1
	hold_x = px
	v = 55.0 if not started else v
	gear_i = 0
	last_gear_lo = -1.0
	view = _view_for(cam)
	zb = road_y(pos, 1.0)
	zr = zb
	zr_prev = zb
	cy = zb
	zb_v = 0.0
	zw = zb
	zw_v = 0.0
	air = false
	land_t = 0.0
	n_jumps = 0
	pitch = 0.0
	pitch_v = 0.0
	roll = 0.0
	roll_v = 0.0
	_env()
	_now_playing()
	$Cockpit.setup()
	setup_done.emit()

func _view_for(c: int) -> Dictionary:
	var vw: Dictionary = VIEWS[c].duplicate()
	if c == 0:
		vw.camh = car.camh   # seat height: the pickup sits high, the GT sits low
	return vw

# chase view, for a car drawn at scale k: how far above the road line the wheels (x) and the body (y) sit, in screen units
func lift_px(k: float) -> Vector2:
	var q: float = k * 64.0 / (1000.0 * W / 2.0) * view.hh
	var w := maxf(0.0, zw - zr) * q
	return Vector2(w, w + clampf((zb - zw) * q, -5.0 * k, 6.0 * k))

func nearest_lane(x: float) -> int:
	var best := 0
	for i in LANES.size():
		if absf(LANES[i] - x) < absf(LANES[best] - x):
			best = i
	return best

func _load_features() -> void:
	var dir := DirAccess.open("res://scripts/features")
	if dir == null:
		return
	var names: Array = []
	for f in dir.get_files():
		f = f.trim_suffix(".remap")   # exported builds list scripts as *.gd.remap
		if f.ends_with(".gd") and not names.has(f):
			names.append(f)
	names.sort()
	for f in names:
		var n := Node.new()
		n.set_script(load("res://scripts/features/" + f))
		n.name = f.get_basename()
		add_child(n)
		features.append(n)

# calls method on every feature that has it; returns true if one of them returned true (consumed)
func feature_call(method: String, args: Array = []) -> bool:
	var used := false
	for f in features:
		if f.has_method(method):
			if f.callv(method, args) == true:
				used = true
	return used

func store_get(section: String, key: String, default = null):
	return store.get_value(section, key, default)

func store_set(section: String, key: String, value) -> void:
	store.set_value(section, key, value)

func store_save() -> void:
	if Engine.has_meta("test_seed"):
		return
	store.save(CFG_PATH)

func _load_cfg() -> void:
	if Engine.has_meta("test_seed"):
		return
	var c := store
	if c.load(CFG_PATH) == OK:
		for k in cfg.keys():
			var v0 = c.get_value("viagem", k, cfg[k])
			var ids: Array = {"car": Cat.CAR_IDS, "road": Cat.ROAD_IDS, "weather": Cat.WEATHER_IDS, "time": Cat.TIME_IDS}[k]
			if ids.has(v0):
				cfg[k] = v0
		for r in Cat.ROAD_IDS:
			his[r] = c.get_value("recordes", r, 0.0)
	if his.is_empty() and FileAccess.file_exists(SAVE_PATH):   # older single high score belongs to the BR
		his["br"] = float(FileAccess.get_file_as_string(SAVE_PATH))

func _save_cfg() -> void:
	for k in cfg.keys():
		store.set_value("viagem", k, cfg[k])
	for r in his.keys():
		store.set_value("recordes", r, his[r])
	store_save()


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
	for r in road.track:
		_road(r[0], r[1], r[2])
	_road(120, 0.0, -_last_y / SEG)
	N = segs.size()
	TRACK = N * SEG

# vegetation redrawn by AI is wider than the old pixel sprites: the width follows so the height stays the same
const OLD_ASPECT := {"tree0": 1.333, "tree1": 1.333, "araucaria": 1.667, "bambu": 1.6, "bush": 0.4375, "eucalipto": 3.0,
	"ipe": 1.333, "ipe_amarelo": 1.333, "ipe_roxo": 1.333, "ipe_branco": 1.333, "ipe_rosa": 1.333}

func ww_fit(t_name: String, ww: float) -> float:
	if OLD_ASPECT.has(t_name) and tex.has(t_name):
		var tx: Texture2D = tex[t_name]
		return ww * OLD_ASPECT[t_name] * tx.get_width() / tx.get_height()
	return ww

func _add_spr(i: int, t_name: String, off: float, ww: float, kind := 0) -> void:
	segs[posmod(i, N)].spr.append({"tex": tex[t_name], "off": off, "ww": ww_fit(t_name, ww), "kind": kind, "name": t_name})

func _clear_around(i: int, r: int) -> void:   # keep a stop's forecourt free of trees and signs
	for d in range(-r, r + 1):
		var s = segs[posmod(i + d, N)]
		s.spr = s.spr.filter(func(q): return q.kind == 1 or q.kind == 6 or q.off < 0.0)

func _add_stops() -> void:
	for f in [0.3, 0.78]:
		var i := int(N * f)
		postos.append(i)
		_clear_around(i, 20)
		_add_spr(i, road.stop, 2.75, road.stop_ww, 3)
		_add_spr(i - 150, road.stop_sign, 1.38, 1700.0, 4)
		if cfg.road == "br":
			for d in range(-60, 61, 20):
				if absi(d) > 10:
					_add_spr(i + d, "lamp", 1.25, 1100.0, 2)

func _populate() -> void:
	if cfg.road == "terra":
		_populate_terra()
	elif cfg.road == "expressa":
		_populate_expressa()
	else:
		_populate_br()

func _populate_br() -> void:
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
		_add_spr(120 + k * int(N / 9.0), "sign%d" % [0, 1, 2, 4, 5][k % 5], 1.38, 1700.0, 4)
	for k in 6:
		_add_spr(300 + k * int(N / 6.0), "board%d" % (k % BOARD_COUNT), 2.3, 2600.0, 5)
	_add_stops()

# farmland in stretches: coffee rows, pasture with cattle, eucalyptus groves, native woods
func _populate_terra() -> void:
	var kinds := ["cafe", "pasto", "eucalipto", "mata"]
	for i in range(0, N, 28):
		_add_spr(i, "pole", 1.5, 1000.0, 1)
	for i in N:
		var zone: String = kinds[(i / 110 + 1) % 4]
		for side in [-1.0, 1.0]:
			if i % 3 == 0 and zone != "mata":
				_add_spr(i, "cerca", side * 1.28, 700.0)
			match zone:
				"cafe":
					if i % 4 == 0:
						for k in 3:
							_add_spr(i, "cafe", side * (1.8 + k * 0.9 + randf() * 0.2), 1100.0)
				"pasto":
					if randf() < 0.025:
						_add_spr(i, ["vaca0", "vaca1"].pick_random(), side * randf_range(1.9, 4.5), 900.0)
					if randf() < 0.03:
						_add_spr(i, ["tree0", "ipe"].pick_random(), side * randf_range(3.0, 6.0), randf_range(1600, 2300))
				"eucalipto":
					if randf() < 0.35:
						_add_spr(i, "eucalipto", side * randf_range(1.8, 5.5), randf_range(1500, 2100))
				"mata":
					if randf() < 0.3:
						_add_spr(i, ["tree0", "tree1", "araucaria", "bambu", "ipe"].pick_random(), side * randf_range(1.5, 5.0), randf_range(1500, 2400))
					elif randf() < 0.1:
						_add_spr(i, "bush", side * randf_range(1.3, 1.8), 800.0)
	for k in 6:   # farmhouses with their gate, a chapel, roadside stands and brown signs
		var i := 200 + k * int(N / 6.0)
		var side := 1.0 if k % 2 == 0 else -1.0
		_clear_around(i, 3)
		_add_spr(i, "casa_sitio" if k != 3 else "capela", side * 3.0, 2600.0)
		_add_spr(i - 6, "porteira", side * 1.42, 900.0)
		_add_spr(i - 60, ["placa_queijo", "placa_ovos"][k % 2], 1.36, 900.0, 4)
		_add_spr(i - 120, "placa_sitio%d" % (k % 3), 1.4, 1700.0, 4)
	_add_stops()

# the expressway: lit median, sound walls through towns, gantries, LED panels and SOS phones
func _populate_expressa() -> void:
	for i in range(0, N, 8):
		_add_spr(i, "luminaria", -1.1, 1900.0, 6)
	for i in N:
		var town: bool = (i / 260) % 3 == 1
		if town and i % 2 == 0:
			_add_spr(i, "muro", 1.55, 1700.0)
		elif not town:
			if randf() < 0.12:
				_add_spr(i, ["tree0", "tree1", "bush"].pick_random(), randf_range(1.8, 5.0), randf_range(1300, 2200))
		if randf() < 0.08:
			_add_spr(i, ["tree0", "tree1"].pick_random(), -randf_range(3.6, 6.0), randf_range(1500, 2200))
		if i % 60 == 30:
			_add_spr(i, "sos", 1.3, 500.0)
	for k in 5:
		_add_spr(150 + k * int(N / 5.0), "portico", 0.0, ROADW / 2000.0 * 4600.0, 8)
	for k in 6:
		_add_spr(400 + k * int(N / 6.0), ["led0", "led1"][k % 2], 2.2, 2600.0, 5)
		_add_spr(250 + k * int(N / 6.0), ["placa_radar", "placa_saida", "placa_pedagio"][k % 3], 1.4, 1700.0, 4)
	_add_stops()

# Long undulations baked into the road height, rough stretches, potholes, patches, and puddles in the dips.
func _build_surface() -> void:
	Y.resize(N)
	ROUGH.resize(N)
	NOISE.resize(N)
	CREST.resize(N)
	CREST.fill(0.0)
	_crest_at.clear()
	var zone := PackedFloat32Array()
	zone.resize(N)
	var und: float = road.undulation
	for i in N:
		var a := float(i) / N * TAU
		zone[i] = pow(maxf(0.0, sin(a * 6.0 + 1.0)), 1.5)
		Y[i] = segs[i].y1 + zone[i] * (70.0 * sin(a * 40.0) + 26.0 * sin(a * 187.0 + 2.0)) * und
		ROUGH[i] = clampf(sin(a * 9.0 + 4.0) * 1.6 - 0.3 + road.rough_base, 0.0, 1.0)
		NOISE[i] = (randf() * 2.0 - 1.0) * road.noise
	for i in N:
		segs[i].y1 = Y[i]
		segs[i].y2 = Y[(i + 1) % N]
	var last_hole := -100
	var wet: bool = cfg.weather != "sol" or mixed_weather   # where the weather varies, puddles only show while it is wet
	var pud_x: Array = [-0.8, 0.8] + LANES
	for i in range(60, N):
		if i - last_hole >= road.hole_gap and randf() < road.hole_p + ROUGH[i] * road.hole_k:
			last_hole = i
			segs[i].feat.append({"t": 0, "x": LANES.pick_random() + randf_range(-0.22, 0.22), "w": randf_range(0.07, 0.12)})
		if ROUGH[i] > 0.25 and randf() < road.patch_p:
			segs[i].feat.append({"t": 1, "x": randf_range(-0.85, 0.85), "w": randf_range(0.1, 0.26)})
		if wet and zone[i] > 0.25 and Y[i] < Y[i - 1] and Y[i] <= Y[(i + 1) % N] and randf() < road.puddle_p:
			var fx: float = pud_x.pick_random()
			var fw := randf_range(0.16, 0.3)
			for q in [[-2, 0.3, 0.8], [-1, 0.8, 1.0], [0, 1.0, 0.9], [1, 0.9, 0.35]]:
				segs[posmod(i + q[0], N)].feat.append({"t": 2, "x": fx, "w": fw, "a": q[1], "b": q[2]})
	for i in N:
		crest_dress(i)

# Crests: natural humps of the road, one per stretch of road.crest_gap segments, on a straight. Where each one sits
# depends only on the trip seed and on the absolute segment (laps * N + i), so every lap brings them somewhere else
# and scripts/features/estrada.gd can re-dress the road behind the car with the same function.
func crest_start(b: int) -> int:
	if _crest_at.has(b):
		return _crest_at[b]
	var gap: int = road.get("crest_gap", 0)
	var L: int = road.get("crest_len", 0)
	var at := -1
	if gap > L + 140:
		for n in 4:   # a few tries to find a straight piece
			var a0: int = b * gap + 90 + absi([b, n, trip_seed, cfg.road].hash()) % (gap - L - 120)
			var ok := true
			for k in range(-6, L + 14):   # room to take off and to land in a straight line
				if absf(segs[posmod(a0 + k, N)].curve) > 0.05:
					ok = false
					break
			if ok:
				at = a0
				break
	_crest_at[b] = at
	return at

func crest_h_at(A: int) -> float:
	var gap: int = road.get("crest_gap", 0)
	if gap <= 0 or A < 0:
		return 0.0
	var a0 := crest_start(int(A / float(gap)))
	var L: int = road.crest_len
	if a0 < 0 or A <= a0 or A >= a0 + L:
		return 0.0
	return road.crest_h * 0.5 * (1.0 - cos(TAU * (A - a0) / L))

func crest_dress(A: int) -> void:
	var i := A % N
	var h := crest_h_at(A)
	if h != CREST[i]:
		Y[i] += h - CREST[i]
		CREST[i] = h
		segs[i].y1 = Y[i]
		segs[posmod(i - 1, N)].y2 = Y[i]

func road_y(z: float, rough := 0.0) -> float:
	z = fposmod(z, TRACK)
	var i := int(z / SEG) % N
	var j := (i + 1) % N
	var k := fmod(z, SEG) / SEG
	var y := lerpf(Y[i], Y[j], k)
	if rough > 0.0:
		y += lerpf(NOISE[i] * (0.25 + ROUGH[i]), NOISE[j] * (0.25 + ROUGH[j]), k) * rough * 16.0
	return y

# traffic entry for the vehicles that are not car-wide (motorbikes, vans): the sprite width follows the picture (94 px = 900 units)
func _veh(z: float, x: float, v: float, t_name: String, dir: int) -> Dictionary:
	var tx: Texture2D = tex[t_name]
	var e := {"z": z, "x": x, "v": v, "tex": tx, "dir": dir, "ww": 900.0 * tx.get_width() / 94.0}
	if t_name.contains("moto"):
		e["hb"] = 0.34
	return e

func _spawn_cars() -> void:
	if cfg.road == "terra":
		for i in 12:   # our side: tractors and old cars; you overtake them through the oncoming lane
			var tr := i % 4 == 0
			var boi := i % 6 == 5   # the cattle truck, slow on the dirt
			if i == 7 or i == 9:   # a motorbike on the dirt
				cars.append(_veh(randf_range(0, TRACK), LANES[1], randf_range(40, 52), "moto%d" % (0 if i == 7 else 1), 1))
				continue
			cars.append({"z": randf_range(0, TRACK), "x": LANES[1], "v": randf_range(18, 24) if tr else (randf_range(28, 36) if boi else randf_range(38, 52)),
				"tex": tex["trator"] if tr else (tex["boiadeiro"] if boi else tex["car%d" % (randi() % 7)]), "dir": 1})
		for i in 7:
			if i == 2:
				cars.append(_veh(randf_range(0, TRACK), LANES[0], -randf_range(40, 55), "front_moto%d" % randi_range(0, 1), -1))
			elif i == 5:
				cars.append(_veh(randf_range(0, TRACK), LANES[0], -randf_range(40, 52), "front_van0", -1))
			else:
				cars.append({"z": randf_range(0, TRACK), "x": LANES[0], "v": -randf_range(40, 58), "tex": tex["front%d" % (randi() % 3)], "dir": -1})
	elif cfg.road == "expressa":
		var spd := [[100, 115], [88, 100], [74, 86], [58, 70]]
		for i in 32:
			var l := i % 4
			var heavy := l == 3 and randf() < 0.6
			var t_name: String = (["car7", "onibus"].pick_random() if heavy else ["mod0", "mod1", "mod2", "mod3", "mod0"].pick_random())
			if i == 5 or i == 18:
				t_name = "van%d" % (i % 2)
			elif i == 9 or i == 26:
				t_name = "moto%d" % (i % 2)
			var ev := _veh(randf_range(0, TRACK), LANES[l], randf_range(spd[l][0], spd[l][1]), t_name, 1)
			if t_name.begins_with("car") or t_name.begins_with("mod") or t_name == "onibus":
				ev = {"z": ev.z, "x": ev.x, "v": ev.v, "tex": tex[t_name], "dir": 1}
			cars.append(ev)
		for i in 12:
			var fn: String = ["front_mod0", "front_mod1", "front0"][i % 3]
			if i == 4 or i == 11:
				fn = "front_van0" if i == 4 else "front_moto1"
			if fn.contains("van") or fn.contains("moto"):
				cars.append(_veh(randf_range(0, TRACK), -2.4 if i % 2 else -3.1, -randf_range(80, 105), fn, -1))
			else:
				cars.append({"z": randf_range(0, TRACK), "x": -2.4 if i % 2 else -3.1, "v": -randf_range(80, 105), "tex": tex[fn], "dir": -1})
	else:
		for i in 26:
			var l := i % 3
			var sp := randf_range(55, 68) if l == 0 else (randf_range(45, 58) if l == 1 else randf_range(34, 48))
			var name: String = ["car7", "car7", "boiadeiro"].pick_random() if (l == 2 and randf() < 0.35) else "car%d" % (randi() % 7)
			if i == 4 or i == 16:   # a motorbike keeping up with the left lane
				cars.append(_veh(randf_range(0, TRACK), LANES[l], randf_range(55, 68), "moto%d" % (i % 2), 1))
			elif i == 7 or i == 19 or i == 23:
				cars.append(_veh(randf_range(0, TRACK), LANES[l], sp, "van%d" % (i % 2), 1))
			else:
				cars.append({"z": randf_range(0, TRACK), "x": LANES[l], "v": sp, "tex": tex[name], "dir": 1})
		for i in 9:
			var fn := "front%d" % (randi() % 3)
			if i == 3:
				fn = "front_moto0"
			elif i == 6:
				fn = "front_van0"
			if fn.contains("van") or fn.contains("moto"):
				cars.append(_veh(randf_range(0, TRACK), -2.1 if i % 2 else -2.8, -randf_range(50, 70), fn, -1))
			else:
				cars.append({"z": randf_range(0, TRACK), "x": -2.1 if i % 2 else -2.8, "v": -randf_range(50, 70), "tex": tex[fn], "dir": -1})

func _init_weather() -> void:
	for i in 90:
		rain_p.append([randf_range(0, W), randf_range(0, 130), randf_range(3, 7), randf_range(160, 260)])
	for i in (50 if cfg.weather == "chuva" else 120):
		stars.append(Vector2(floor(randf_range(0, W)), floor(randf_range(12, 50))))
	for i in (7 if cfg.weather == "chuva" else (5 if mixed_weather else 3)):
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
	var sk: Array = Cat.SKIES["chuva" if sky_k >= 1.0 else "sol"]
	var i := int(tday) % 4
	var f := tday - floorf(tday)
	var k := clampf((f - 0.45) / 0.55, 0.0, 1.0)
	var s := k * k * (3.0 - 2.0 * k)
	var a: Dictionary = sk[i]
	var b: Dictionary = sk[(i + 1) % 4]
	e_top = Color(a.top).lerp(Color(b.top), s)
	e_hor = Color(a.hor).lerp(Color(b.hor), s)
	e_hf = Color(a.hf).lerp(Color(b.hf), s)
	e_hn = Color(a.hn).lerp(Color(b.hn), s)
	e_gr = Color(a.gr).lerp(Color(b.gr), s)
	e_amb = lerpf(a.amb, b.amb, s)
	if sky_k > 0.0 and sky_k < 1.0:   # weather on the move: the clear sky clouds over toward the rainy one
		var a2: Dictionary = Cat.SKIES.chuva[i]
		var b2: Dictionary = Cat.SKIES.chuva[(i + 1) % 4]
		e_top = e_top.lerp(Color(a2.top).lerp(Color(b2.top), s), sky_k)
		e_hor = e_hor.lerp(Color(a2.hor).lerp(Color(b2.hor), s), sky_k)
		e_hf = e_hf.lerp(Color(a2.hf).lerp(Color(b2.hf), s), sky_k)
		e_hn = e_hn.lerp(Color(a2.hn).lerp(Color(b2.hn), s), sky_k)
		e_gr = e_gr.lerp(Color(a2.gr).lerp(Color(b2.gr), s), sky_k)
		e_amb = lerpf(e_amb, lerpf(a2.amb, b2.amb, s), sky_k)
	e_fog = e_hor.lerp(e_hn, 0.45)
	var wet: bool = wet_k >= 1.0
	var wk := wet_k
	match road.surface:
		"terra":   # red earth, darker when it rains
			e_road0 = Color8(44, 24, 15).lerp(Color8(30, 16, 10), wk).lerp(Color8(150, 84, 50).lerp(Color8(110, 58, 36), wk), minf(e_amb, 1.1))
			e_road1 = e_road0.lerp(Color.BLACK, 0.06)
			e_line = e_road0.lerp(Color.BLACK, 0.25)   # wheel ruts
		"concreto":
			e_road0 = Color8(24, 26, 30).lerp(Color8(140, 142, 140).lerp(Color8(118, 122, 126), wk), minf(e_amb, 1.1))
			e_road1 = e_road0.lerp(Color.WHITE, 0.03)
			e_line = Color8(80, 82, 90).lerp(Color8(230, 232, 238), e_amb * 0.7 + 0.3)
		_:
			e_road0 = Color8(13, 17, 25).lerp(Color8(72, 76, 84).lerp(Color8(58, 67, 82), wk), minf(e_amb, 1.1))
			e_road1 = Color8(14, 18, 27).lerp(Color8(76, 80, 88).lerp(Color8(60, 69, 85), wk), minf(e_amb, 1.1))
			e_line = Color8(74, 77, 87).lerp(Color8(214, 220, 232), e_amb * 0.7 + 0.3)
	headlight = 0.16 + clampf((0.6 - e_amb) * 0.4, 0.0, 0.1) if wet else lerpf(clampf((0.9 - e_amb) * 0.5, 0.0, 0.3), 0.16 + clampf((0.6 - e_amb) * 0.4, 0.0, 0.1), wk)


# ---------------------------------------------------------------- audio

func _player(stream: AudioStream) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.stream = stream
	add_child(p)
	return p

func _init_audio() -> void:
	a_music = _player(null)   # the radio and the tape play here (scripts/features/radio.gd)
	var r: AudioStreamOggVorbis = load("res://assets/audio/rain.ogg")
	r.loop = true
	a_rain = _player(r)
	a_rain.volume_db = -80.0
	var rf: AudioStreamOggVorbis = load("res://assets/audio/chuva_teto.ogg")
	rf.loop = true
	a_roof = _player(rf)
	a_roof.volume_db = -80.0
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
	for n in ["hole", "bump", "splash", "static", "wiper", "horn", "pouso"]:
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
	feature_call("radio_now_playing")

func _tune() -> void:
	feature_call("radio_tune")

func next_station() -> void:
	feature_call("radio_next")

func set_sound(on: bool) -> void:
	sound_on = on
	AudioServer.set_bus_mute(0, not on)
	hud.toast("SOM LIGADO" if on else "SOM DESLIGADO", 1.5)


# ---------------------------------------------------------------- input

func begin() -> void:
	if started:
		return
	started = true
	state = "drive"
	target = minf(70.0, car.top)
	score = 0.0
	mult = 1
	clean = 0.0
	fuel = 0.8
	low_warn = false
	n_holes = 0
	n_puddles = 0
	n_bumps = 0
	km_trip = 0.0
	trip_time = 0.0
	menu.hide_all()
	hud.set_drive(true)
	set_mode(clampi(int(store_get("viagem", "modo", 1)), 0, 1))
	set_cam(cam)
	a_engine.play()
	a_rumble.play()
	a_hiss.play()
	hud.toast("BOA VIAGEM", 3.0)
	trip_started.emit()

# back to the trip planner: the car keeps rolling on autopilot behind the menu
func to_menu() -> void:
	_save_hi()
	if started:
		trip_ended.emit({"km": km_trip, "minutes": trip_time / 60.0, "holes": n_holes, "puddles": n_puddles,
			"bumps": n_bumps, "score": score, "car": cfg.car, "road": cfg.road, "weather": cfg.weather, "time": cfg.time})
	store_save()
	started = false
	state = "menu"
	drive_mode = 2   # behind the menu the car drives itself
	auto = true
	_set_paused_audio(false)
	a_engine.stop()
	a_rumble.stop()
	a_hiss.stop()
	hud.set_drive(false)
	menu.show_main()

func pause() -> void:
	if state != "drive":
		return
	state = "pause"
	_set_paused_audio(true)
	menu.show_pause()

func resume() -> void:
	if state != "pause":
		return
	state = "drive"
	_set_paused_audio(false)
	menu.hide_all()

func _set_paused_audio(p: bool) -> void:
	for pl in [a_engine, a_rumble, a_hiss, a_rain, a_roof]:
		pl.stream_paused = p

# the menu changed one option: rebuild the trip and remember the choice
func choose(key: String, value: String) -> void:
	if cfg[key] == value:
		return
	cfg[key] = value
	_save_cfg()
	setup()

func set_auto(on: bool) -> void:
	set_mode(2 if on else maxi(1, drive_mode if drive_mode < 2 else 1))

func set_mode(m: int) -> void:
	var was := drive_mode
	drive_mode = clampi(m, 0, 2)
	auto = drive_mode == 2
	if drive_mode == 0:
		overtaking = false
	if was == 2 and drive_mode < 2:
		target = v   # taking over keeps the speed you have
	hud.set_mode(drive_mode)
	if started and was != drive_mode:
		hud.toast(["PILOTO DESLIGADO: TUDO COM VOCÊ", "PILOTO ASSISTIDO: VOCÊ ESCOLHE A FAIXA", "PILOTO AUTOMÁTICO: SÓ CURTA A VIAGEM"][drive_mode])
		store_set("viagem", "modo", drive_mode)

func set_cam(c: int) -> void:
	cam = c
	view = _view_for(c)
	$Cockpit.visible = c == 0
	if state == "drive" and t > 0.5:
		hud.toast("CÂMERA EXTERNA" if c == 1 else "CÂMERA INTERNA", 1.5)

func _unhandled_input(ev: InputEvent) -> void:
	if ev is InputEventKey and ev.pressed and not ev.echo:
		var k: int = ev.physical_keycode
		if k == KEY_F11:
			var full := DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if full else DisplayServer.WINDOW_MODE_FULLSCREEN)
		elif state == "menu" or state == "pause":
			menu.key(k)
		elif feature_call("drive_key", [k]):
			pass
		elif k == KEY_ESCAPE:
			pause()
		elif k == KEY_R:
			next_station()
		elif k == KEY_P:
			set_mode((drive_mode + 2) % 3)   # LIGADO -> ASSISTIDO -> DESLIGADO -> LIGADO
		elif k == KEY_M:
			set_sound(not sound_on)
		elif k == KEY_V:
			set_cam(1 - cam)
		elif k == KEY_B or k == KEY_H:
			_sfx("horn")
	elif ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT:
		if state == "menu" or state == "pause":
			if ev.pressed:
				menu.click(ev.position)
			return
		if not ev.pressed:
			touch_steer = 0.0
		else:
			var p: Vector2 = ev.position / 2.0
			var rh: Array = car.layout.radio_hit
			if cam == 0 and Rect2(rh[0], rh[1], rh[2], rh[3]).has_point(p):
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
		hi = score
		his[cfg.road] = int(score)
		_save_cfg()


# ---------------------------------------------------------------- update

func _splash() -> void:
	for i in 60:
		drops.append([randf_range(glass.position.x, glass.end.x), randf_range(glass.position.y, glass.end.y), 2.0 if randf() < 0.5 else 1.0])
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
		if not l and not r:   # it went between or beside the wheels
			hole_missed.emit(f, d)
			return
		var side := 0.0 if (l and r) else (-1.0 if l else 1.0)
		var k := (0.5 + sp) * (0.75 + 5.0 * clampf(f.w - 0.07, 0.0, 0.05)) * (1.3 if side == 0.0 else 1.0)   # bigger hole, harder hit; both wheels, harder still
		zb_v += 500.0 * k * car.hole_gain
		roll_v += side * 0.36 * k * car.hole_gain
		pitch_v -= 0.7 * minf(k, 1.35)   # the nose drops into it, then comes back up
		vx += side * 0.25 * k / 1.45   # the wheel is yanked toward the hole
		aqua = maxf(aqua, 0.2)         # a moment with loose grip and no lane magnet
		kick = side * 0.4 if side != 0.0 else randf_range(-0.25, 0.25)
		v = maxf(0.0, v - 3.0)
		bob_v += 10.0
		dice_v += randf_range(-3, 3)
		clean = maxf(0.0, clean - 8.0)
		n_holes += 1
		hole_hit.emit(f, side, k)
		sfx["hole"].pitch_scale = 1.0
		sfx["hole"].volume_db = linear_to_db(0.35 + 0.65 * clampf(k / 1.45, 0.0, 1.0))
		_sfx("hole")
		if started and hud.toast_t <= 0.0:
			hud.toast(["EITA, BURACO!", "OPA, BURACO!", "ESSE PEGOU..."].pick_random(), 1.3)
	elif f.t == 2:   # puddle: drag, a tug on the wheel, a moment of aquaplaning
		if absf(d) > f.w + 0.24 or splash_t > 0.0 or sp < 0.15 or wet_k < 0.35:   # a dried-up puddle is just road
			return
		splash_t = 0.7
		aqua = 0.5
		vx += (1.0 if d >= 0.0 else -1.0) * 0.24 * sp
		v = maxf(0.0, v - 5.0 * sp)
		zb_v -= 60.0
		n_puddles += 1
		puddle_hit.emit(f)
		_splash()
	elif f.t == 3:   # speed bump: the body is lifted, the nose pitches, then the springs float it back down
		var kb := clampf(sp, 0.15, 1.4)
		zb_v += (150.0 + 520.0 * kb) * car.hole_gain
		pitch_v += 0.35 * kb   # front wheels climb first: nose up
		roll_v += randf_range(-0.05, 0.05) * kb
		bob_v += 6.0 + 10.0 * kb
		dice_v += randf_range(-2, 2) * kb
		if sp > 0.5:
			v = maxf(0.0, v - 4.0 * sp)
			sfx["hole"].pitch_scale = 1.0
			sfx["hole"].volume_db = linear_to_db(0.25 + 0.4 * clampf(sp, 0.0, 1.0))
			_sfx("hole")
			if started:
				hud.notice("LOMBADA! NA CIDADE, DEVAGAR", 3.0)

# touchdown after a jump: the springs swallow it, a thud and a puff of dust as big as the fall. Nothing is lost.
func _land(zr_v: float) -> void:
	air = false
	if air_t < 0.07:   # a skip of a frame or two is not a jump
		return
	var k := clampf((zr_v - zw_v) / 1700.0, 0.2, 1.0)
	# the longer the flight, the more of the fall the springs have to swallow (tyres and bump stops take the rest)
	zb_v = zr_v - clampf((zr_v - zb_v) * (0.15 + 1.2 * minf(air_t, 0.45)), 60.0, 800.0) * car.hole_gain
	pitch_v -= 0.4 * k   # the nose dips as the front lands
	roll_v += randf_range(-0.08, 0.08) * k
	kick = randf_range(-0.2, 0.2) * k
	bob_v += 8.0 + 10.0 * k
	dice_v += randf_range(-2, 2) * k
	land_t = 0.6
	land_k = k
	n_jumps += 1
	sfx["pouso"].pitch_scale = randf_range(0.92, 1.05)   # the springs bottoming out, a deeper thud than a pothole
	sfx["pouso"].volume_db = linear_to_db(0.2 + 0.55 * k)
	_sfx("pouso")
	if cam == 1 and has_car_scr and wet_k > 0.35:   # wet road: both wheels throw a little spray
		for i in int(10 + 20 * k):
			var side := -1.0 if i % 2 else 1.0
			parts.append([car_scr.x + side * randf_range(18, 30) * car_scr.z, car_scr.y - randf_range(0, 4), side * randf_range(30, 90), randf_range(-90, -30), randf_range(0.3, 0.6)])
	if started:
		score += 100.0 * mult * k   # a small treat, never a penalty
		if n_jumps == 1:
			hud.notice("UPA! A CRISTA TIROU O CARRO DO CHÃO. DEVAGAR, ELA SÓ BALANÇA", 4.0)
		elif air_t >= 0.3:
			hud.notice("NO AR: %s s" % ("%.1f" % air_t).replace(".", ","), 2.0)
	jumped.emit(air_t, k)

# autopilot: weigh potholes, puddles and slower cars over the next ~1.6 s in each lane
func _danger(l: int, bi: int) -> float:
	var look := int(v * UPK * 1.6 / SEG) + 1
	var d := 0.0
	for k in range(2, look):
		for f in segs[(bi + k) % N].feat:
			if f.t != 1 and f.t != 3 and (f.t != 2 or wet_k > 0.35) and absf(f.x - LANES[l]) < f.w + 0.25:
				d += 1.0 / k
	return d + (2.0 if _car_ahead(l) < 3000.0 else 0.0)

# speed the autopilot allows with a speed bump ahead: a gentle braking curve down to ~28 km/h over it
func _bump_limit() -> float:
	var bi := int(pos / SEG)
	for k in 110:
		for f in segs[(bi + k) % N].feat:
			if f.t == 3:
				return 28.0 + sqrt(maxf(0.0, k * SEG - fmod(pos, SEG) - 300.0) * 0.25)
	# a crest ahead: ease off below the speed that throws the car in the air, so the autopilot ride stays calm
	if CREST.size() == N:
		for k in 90:
			if CREST[(bi + k) % N] > 0.0:
				return {"terra": 46.0, "br": 58.0}.get(cfg.road, 95.0)
	return 999.0

var _dodge_t := 0.0
# two-way road: pass a slow car only with a long clear view of the oncoming lane, then pull back in
func _auto_overtake() -> void:
	var home: int = road.ours.back()
	var other := 0 if home != 0 else 1
	if not overtaking:
		if lane == home and _car_ahead(home) < 3200.0 and _oncoming_clear(60000.0):
			overtaking = true
			lane = other
			auto_off = 0.0
		return
	var not_past := false
	var still_behind := false
	for c in cars:
		if c.dir > 0 and absf(c.x - LANES[home]) < 0.3:
			var d := fposmod(c.z - pos + 1400.0, TRACK)
			if d < 3000.0:   # from 1400 behind to 1600 ahead: not past it yet
				not_past = true
			if d > 2300.0 and d < 3000.0:   # its tail still 900+ ahead of us: we can still give up
				still_behind = true
	if not not_past or (still_behind and not _oncoming_clear(16000.0)):
		overtaking = false
		lane = home

func _oncoming_clear(dist: float) -> bool:
	for c in cars:
		if c.dir < 0 and absf(c.x) < 1.0 and fposmod(c.z - pos, TRACK) < dist:
			return false
	return true

func _danger_x(x: float, bi: int) -> float:
	var look := int(v * UPK * 1.6 / SEG) + 1
	var d := 0.0
	for k in range(2, look):
		for f in segs[(bi + k) % N].feat:
			if f.t == 0 and absf(f.x - x) < f.w + 0.26:
				d += 1.0 / k
	return d

func _auto_dodge(bi: int) -> void:
	_dodge_t -= get_process_delta_time()
	if _dodge_t > 0.0:
		return
	_dodge_t = 0.1
	if road.ours.size() == 1:   # nowhere to go: shift inside the lane, wheels either side of the hole
		var best_off := 0.0
		var best_d := _danger_x(LANES[lane], bi)
		for o in [-0.24, 0.24]:
			var d := _danger_x(LANES[lane] + o, bi)
			if d < best_d * 0.7:
				best_d = d
				best_off = o
		auto_off = best_off
		return
	var cur := _danger(lane, bi)
	if cur <= 0.0:
		return
	var best := lane
	for l in [lane - 1, lane + 1]:
		if road.ours.has(l) and not _lane_busy(l, 1600.0, false) and _danger(l, bi) < _danger(best, bi) * 0.5:
			best = l
	lane = best

func _car_ahead(l: int) -> float:
	var best := 1e9
	for c in cars:
		if c.dir > 0 and absf(c.x - LANES[l]) < 0.3 and c.get("cur", c.v) < v:
			var d := fposmod(c.z - pos, TRACK)
			if d < best:
				best = d
	return best

func _lane_busy(l: int, back: float, slower_only: bool) -> bool:
	for c in cars:
		if c.dir > 0 and absf(c.x - LANES[l]) < 0.3 and fposmod(c.z - pos + back, TRACK) < 5200.0:
			if not slower_only or c.get("cur", c.v) < v + 4.0:
				return true
	return false

func _process(dt: float) -> void:
	dt = minf(dt, 0.05)
	if state != "drive" and state != "menu":   # pause, or a feature's own frozen state ("parada", "foto")
		return
	t += dt
	if cfg.time == "ciclo":
		tday = fmod(tday + dt / 110.0, 4.0)
	_env()
	# rain comes and goes, but stays rain
	rain_t -= dt
	if rain_t <= 0.0 and not mixed_weather:   # weather that varies is driven by a feature (mundo_clima)
		rain_goal = randf_range(0.55, 1.0) if cfg.weather == "chuva" else 0.0
		rain_t = randf_range(35, 80)
	if rain_goal >= 0.0:
		rain += clampf(rain_goal - rain, -dt * 0.04, dt * 0.04)

	# speed: cruise control
	var up := Input.is_physical_key_pressed(KEY_UP) or Input.is_physical_key_pressed(KEY_W) or bot_speed > 0.0
	var dn := Input.is_physical_key_pressed(KEY_DOWN) or Input.is_physical_key_pressed(KEY_S) or bot_speed < 0.0
	var manual := started and drive_mode == 0
	if manual:   # no cruise control: the throttle is the up key, down brakes, letting go coasts
		target = v
	elif started:
		target = clampf(target + (float(up) - float(dn)) * 28.0 * dt, 0.0, car.top)
	var tgt := target if started else 55.0
	if manual:
		tgt = car.top if up else (0.0 if dn else maxf(0.0, v - 5.0 * dt))
	if auto or not started:
		tgt = minf(tgt, _bump_limit())   # the autopilot eases off before a speed bump
	if fuel <= 0.0:
		tgt = minf(tgt, 25.0)
	var walled: bool = road.median != "none"
	var off := px > 1.02 if walled else absf(px) > 1.02   # with a median, the left side is the barrier's job
	off_t = off_t + dt if off else 0.0
	if off_t > 0.4:   # a wheel over the line for a moment is not leaving the road
		tgt = minf(tgt, 30.0)
	var on_rail: bool = walled and px <= -1.04
	if on_rail:   # held against the guard rail: it scrubs speed (through the cruise target, or the cruise would refill it)
		tgt = minf(tgt, maxf(30.0, v - 12.0 * dt))
	var close := false
	if started and not manual:   # cruise control (and the autopilot) yields to the car ahead instead of ramming it
		for c in cars:
			if c.dir > 0 and (absf(c.x - px) < c.get("hb", 0.46) or (auto and absf(c.x - LANES[lane]) < 0.3)):
				var dd := fposmod(c.z - pos, TRACK)
				var cvv: float = c.get("cur", c.v)   # what it is actually doing, e.g. stuck behind a tractor
				if dd > 250.0 and dd < 9000.0:   # square-root braking curve: always enough room to slow down
					if dd < 1600.0:   # already inside the gap: settle just under its speed, don't sink below it
						tgt = minf(tgt, cvv - (1600.0 - dd) * 0.005)
					else:
						tgt = minf(tgt, cvv + sqrt((dd - 1600.0) * 0.5))
					close = close or (dd < 4000.0 and v > cvv + 15.0)   # someone slow just appeared close: brake firmly
	var v0 := v
	v += clampf(tgt - v, (-(car.brake + 36.0) if close else -car.brake) * dt, car.acc * dt)
	brake = tgt < v - 1.5
	var sp := v / 100.0
	var base = segs[int(pos / SEG) % N]
	var curve: float = base.curve

	# steering: slow steering box -> tyres that take a moment to bite -> lateral velocity
	var right := Input.is_physical_key_pressed(KEY_RIGHT) or Input.is_physical_key_pressed(KEY_D)
	var left := Input.is_physical_key_pressed(KEY_LEFT) or Input.is_physical_key_pressed(KEY_A)
	var dir := clampf(float(right) - float(left) + touch_steer + bot_steer, -1.0, 1.0)
	if dir != 0.0 and auto and started:
		set_mode(1)
	var is_auto := auto or not started
	if is_auto:
		_auto_dodge(base.i)
		var ahead := _car_ahead(lane)
		if ahead < 2500.0:
			v = maxf(v - 30.0 * dt * (1.0 - ahead / 2500.0), minf(v, 25.0))   # a floor for braking, never a push
		if _lane_busy(lane, 0.0, true) and absf(px - LANES[lane]) < 0.25:
			var moved := false
			for l in [lane - 1, lane + 1]:
				if road.ours.has(l) and not _lane_busy(l, 1600.0, false):
					lane = l
					moved = true
					break
			if not moved:
				v = maxf(v - 40.0 * dt, minf(v, 30.0))
		var right_lane: int = road.ours.back()
		if fuel < 0.6 and not _lane_busy(right_lane, 1600.0, false):
			for p in postos:
				if posmod(p - base.i, N) < 220:
					lane = right_lane
		if road.two_way:
			_auto_overtake()
		if not road.ours.has(lane) and not overtaking:
			lane = right_lane
		dir = clampf((LANES[lane] + auto_off - px) * 2.4 - vx * 1.6, -0.4, 0.4)
	else:
		lane = nearest_lane(px)
		if dir != 0.0 and prev_input == 0.0:
			press_lane = lane
		free_t = 0.0 if dir != 0.0 else free_t + dt
		if free_t > 0.5 and free_t - dt <= 0.5 and lane == press_lane:   # the nudge is over: keep the line the player chose
			hold_x = clampf(px, LANES[lane] - 0.2, LANES[lane] + 0.2)
	prev_input = dir if not is_auto else 0.0
	var rate: float = car.steer_rate if absf(dir) > absf(steer) else car.steer_rate * 2.0   # quick to centre, a little slower to turn in
	if air:
		rate *= 1.5   # nothing pushes back on the wheel in the air
	steer += clampf(dir - steer, -dt * rate, dt * rate)
	aqua = maxf(0.0, aqua - dt)
	splash_t = maxf(0.0, splash_t - dt)
	var grip := (1.0 - 0.3 * rain * sp) * (0.3 if aqua > 0.0 else 1.0) * (0.2 if air else 1.0)   # in the air the car keeps the line it left with
	var vx0 := vx
	vx += (steer * 1.0 * minf(1.0, sp * 2.5) - vx) * minf(1.0, dt * car.grip * grip)
	if dir == 0.0 and not is_auto and not manual and aqua <= 0.0 and (px < 1.02 if walled else absf(px) < 1.02):
		if lane != press_lane:   # just changed lane (or never steered): settle into the lane centre
			px += (LANES[lane] - px) * minf(1.0, 2.5 * dt)
		elif free_t > 0.5:       # hands off after a nudge: hold that line, even through the bend
			px += (hold_x - px) * minf(1.0, 2.5 * dt) + curve * sp * sp * dt * car.curve_push * 0.343   # the bend still leans you out a little
		else:                    # small correction in the same lane: only a weak pull, fine control stays
			vx += (LANES[lane] - px) * 1.5 * dt
	px += vx * dt - (0.0 if is_auto else curve * sp * sp * dt * car.curve_push)
	if not walled and px < -1.7:
		px = -1.7
		vx = maxf(vx, 0.0)
	if walled and px < -1.06:
		if vx < -0.2 and started and bump_t <= 0.0:   # scraping the median guard rail: you hear and feel it
			bump_t = 2.0
			sfx["bump"].volume_db = linear_to_db(clampf(absf(vx), 0.3, 1.0))
			_sfx("bump")
			kick = -0.4
			roll_v += 0.3
			mult = maxi(1, mult - 1)   # a scrape costs a step, like a nudge
			clean = minf(clean, (mult - 1) * 25.0)
			hud.toast("EPA, GUARD-RAIL!" if road.median == "rail" else "EPA, MURETA!", 1.5)
			bumped.emit("rail")
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
			if not air:   # a jump clears whatever is on the road
				for f in segs[i].feat:
					_hit_feat(f, sp)
			seg_passed.emit(i)
			if postos.has(i):
				if px > LANES.back() - 0.42:
					fuel = 1.0
					low_warn = false
					refueled.emit(i)
					if started:
						score += 500.0
						hud.toast("TANQUE CHEIO  +500")
				elif fuel < 0.5 and started:
					hud.toast("O POSTO PASSOU... NA PRÓXIMA, ENCOSTE À DIREITA")
			if i == cur_i:
				break
			i = (i + 1) % N

	# suspension: the wheels follow the road, or fly a short arc off a crest taken fast; the body rides its springs above them
	var rough := 1.7 if off else ((1.3 if px > 0.33 else (0.6 if px < -0.33 else 1.0)) if cfg.road == "br" else 1.0)
	zr = road_y(pos, rough)
	var zr_v := (zr - zr_prev) / maxf(dt, 0.001)
	if absf(zr_v) > 5000.0:
		zr_v = 0.0
	zr_prev = zr
	land_t = maxf(0.0, land_t - dt)
	if air and absf(zw - zr) > 900.0:   # moved somewhere else (a test, a new trip)
		air = false
	if not air:
		zw = zr
		zw_v = zr_v
		var u := v * UPK
		if CREST[cur_i] > 0.0 and u > 0.0:
			var y0 := road_y(pos)
			var ya := road_y(pos + SEG)
			var yb := road_y(pos - SEG)
			if (ya - 2.0 * y0 + yb) / (SEG * SEG) * u * u < -GRAV:   # the road drops away faster than the wheels can fall
				air = true
				air_t = 0.0
				zw_v = (ya - yb) / (2.0 * SEG) * u
				pitch_v += 0.2   # the nose lifts as it goes
				bob_v -= 6.0
	else:
		air_t += dt
		zw_v -= GRAV * dt
		zw += zw_v * dt
		if zw <= zr:
			zw = zr
			if air_t < 0.05 and CREST[cur_i] > 0.0:   # still leaving the ground
				zw_v = maxf(zw_v, zr_v)
			else:
				_land(zr_v)
				zw_v = zr_v
	# in the air body and wheels fall together and the wheels hang a little lower (the springs stretch)
	zb_v += (-car.spring_k * (zb - zw - (22.0 if air else 0.0)) - car.spring_c * (zb_v - zw_v) - (GRAV if air else 0.0)) * dt
	zb = clampf(zb + zb_v * dt, zw - 240.0, zw + 240.0)
	cy += (zr - cy) * minf(1.0, dt * 3.0)
	if absf(zr - cy) > 700.0:
		cy = zr
	var sl := (road_y(pos + 700.0) - road_y(pos - 700.0)) / 1400.0
	slope += (sl - slope) * minf(1.0, dt * 1.6)
	# the nose rises into a climb and under power, and dives under braking
	var pt := (0.025 + 0.015 * sp) * tanh((sl - slope) / 0.05) + clampf((v - v0) / maxf(dt, 0.001), -40.0, 20.0) * 0.0011
	pitch_v += (-car.pitch_k * (pitch - pt) - car.pitch_c * pitch_v) * dt
	pitch = clampf(pitch + pitch_v * dt, -0.12, 0.12)
	# the body leans away from the lateral acceleration: out of the bend, and against each half of a lane change
	# (a hard flick of the wheel does not throw it further than a firm one: the lean going in and coming back match)
	var rt := 0.0 if air else -clampf((4.0 * tanh(al / 4.0) * 0.018 + curve * sp * sp * 0.024) * car.roll_gain, -0.14, 0.14)
	roll_v += (-car.roll_k * (roll - rt) - car.roll_c * roll_v + (randf_range(-3, 3) * sp if off else 0.0)) * dt
	roll = clampf(roll + roll_v * dt, -0.16, 0.16)
	cam_x += (px - cam_x) * minf(1.0, dt * 2.4)

	if started:
		fuel = maxf(0.0, fuel - dt / 600.0 * (v / 70.0))   # a full tank is ~11.7 km; stops come every few km
		if fuel < 0.2 and not low_warn:
			low_warn = true
			hud.toast("NA RESERVA: POSTO NA FAIXA DA DIREITA", 4.0)
		if not off and v > 20.0:
			clean += dt
		elif off_t > 0.4 and int(off_t / 0.4) > int((off_t - dt) / 0.4):   # on the grass: one step of the multiplier every 0.4 s, like any other slip
			mult = maxi(1, mult - 1)
			clean = minf(clean, (mult - 1) * 25.0)
		var m := 1 + mini(3, int(clean / 25.0))
		if m > mult:
			hud.toast("DIREÇÃO SUAVE  x%d" % m)
		mult = m
		score += v * dt * 2.0 * mult
		km_trip += v * dt / 3600.0
		trip_time += dt
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
			var hb: float = c.get("hb", 0.46)   # a motorbike is narrow: a smaller bubble
			if d > TRACK - 1400.0 and dxl < 0.5:   # following us: keep a gap instead of creeping onto our bumper
				cv = minf(cv, maxf(0.0, v + (TRACK - d - 1000.0) * 0.02))
			# we cut in front of a faster car close behind: it brakes for about a second and honks, we keep our lane
			if d > TRACK - 1200.0 and dxl < hb and c.v > v and c.get("honk_t", 0.0) <= 0.0:
				c.hold_t = 1.2
				c.honk_t = 5.0
				_sfx("horn")
			c.honk_t = maxf(0.0, c.get("honk_t", 0.0) - dt)
			if c.get("hold_t", 0.0) > 0.0:
				c.hold_t -= dt
				cv = minf(cv, maxf(0.0, v - 20.0))
			var behind_overlap := d > TRACK - 500.0 and dxl < hb
			var swipe := d <= 250.0 and dxl < hb   # alongside a car ahead: no driving through it
			if swipe:
				var sgn := 1.0 if px >= c.x else -1.0
				px = c.x + sgn * hb
				vx = sgn * 0.45
				kick = sgn * 0.5
			if (d < 1250.0 and d > 250.0 and dxl < hb and v > c.v) or swipe or behind_overlap:
				sfx["bump"].volume_db = linear_to_db(0.4 + 0.6 * clampf((v - c.v) / 40.0, 0.0, 1.0))
				if not swipe and not behind_overlap:
					v = lerpf(v, maxf(0.0, cv - 6.0), minf(1.0, dt * 10.0))   # a firm shove over ~0.2 s, not a wall
				if bump_t <= 0.0 and started:   # a nudge costs one step of the multiplier, not all of it
					bump_t = 2.0
					if not auto:   # the autopilot's fault is not the player's
						mult = maxi(1, mult - 1)
						clean = minf(clean, (mult - 1) * 25.0)
					bob_v += 9.0
					dice_v += 3.0
					pitch_v -= 0.5
					hud.toast("OPA! SEM PRESSA")
					bumped.emit("side" if swipe else "rear")
					n_bumps += 1
					_sfx("bump")
		elif road.two_way and absf(c.x) < 1.0:   # oncoming, on our road: flashes and honks, a touch costs a step
			var d2 := fposmod(c.z - pos, TRACK)
			var dxo := absf(c.x - px)
			var hbo: float = c.get("hb", 0.46)
			c.honk_t = maxf(0.0, c.get("honk_t", 0.0) - dt)
			c.flash_t = maxf(0.0, c.get("flash_t", 0.0) - dt)
			if started and dxo < hbo and d2 < 9000.0 and c.honk_t <= 0.0:
				c.honk_t = 6.0
				c.flash_t = 1.4
				_sfx("horn")
			if (d2 < 450.0 or d2 > TRACK - 250.0) and dxo < hbo:
				px = c.x + 0.48
				vx = 0.5
				kick = 0.6
				if bump_t <= 0.0 and started:
					bump_t = 2.0
					v *= 0.75
					mult = maxi(1, mult - 1)
					clean = minf(clean, (mult - 1) * 25.0)
					bob_v += 9.0
					dice_v += 3.0
					roll_v += 0.4
					hud.toast("OLHA A CONTRAMÃO!")
					bumped.emit("oncoming")
					n_bumps += 1
					sfx["bump"].volume_db = 0.0
					_sfx("bump")
		c.cur = cv
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
		drops.append([randf_range(glass.position.x, glass.end.x), randf_range(glass.position.y, glass.end.y), 2.0 if randf() < 0.3 else 1.0])   # keep the horizon band clear so the road ahead reads
		spawn -= 1.0
	for d in drops:
		d[1] -= sp * 2.5 * dt * d[2]
	wip_prev = wip_a
	if wip_phase > 0.0 or rain > 0.08:
		if wip_phase <= 0.0:
			wip_wait -= dt
		if wip_phase > 0.0 or wip_wait <= 0.0:
			var ph0 := wip_phase
			wip_phase += dt / 1.5
			if cam == 0 and (ph0 <= 0.0 or (ph0 < 0.5 and wip_phase >= 0.5)):   # one swish up the glass, one back down
				sfx["wiper"].pitch_scale = 1.0 if ph0 <= 0.0 else 0.94
				_sfx("wiper")
			if wip_phase >= 1.0:
				wip_phase = 0.0
				wip_wait = (1.0 - rain) * 5.0
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
		if drops[i][1] < glass.position.y - 27.0:
			drops.remove_at(i)
	if (drops.size() > 230 or rain < 0.05) and drops.size() > 0:
		drops.remove_at(0)

	# audio follows the drive
	if started:
		a_rain.volume_db = linear_to_db(maxf(rain * (0.06 if cam == 0 else 0.09), 0.0001))   # from the cockpit the roof covers the road
		a_roof.volume_db = linear_to_db(maxf(rain * (0.11 if cam == 0 else 0.025), 0.0001))
		a_engine.volume_db = linear_to_db(0.05 + sp * 0.03)
		# four-speed box: revs climb within each gear and sag at every shift
		# at a steady speed an old car shifts up early instead of holding the top of a gear
		var cruising := absf(v - v0) / maxf(dt, 0.001) < 2.0
		var early := 8.0 if cruising else 0.0
		var cand := 0
		for gi in range(1, GEAR_LO.size()):
			if v >= GEAR_LO[gi] - early:
				cand = gi
		var outside: bool = v < GEAR_LO[gear_i] - 8.5 or v > GEAR_HI[gear_i] + 0.5   # fixed hysteresis going down: braking behind a car does not hunt gears
		if cand != gear_i:
			gear_cand_t += dt
			if gear_cand_t > 0.5 or outside:
				gear_i = cand
				gear_cand_t = 0.0
		else:
			gear_cand_t = 0.0
		var g_lo: float = GEAR_LO[gear_i] - (8.0 if gear_i > 0 else 0.0)   # revs count from where the gear can really come in
		var g_hi: float = GEAR_HI[gear_i]
		var rpm := clampf((v - g_lo) / (g_hi - g_lo), 0.0, 1.0)
		a_engine.pitch_scale = lerpf(a_engine.pitch_scale, (car.eng_base + car.eng_span * rpm) * (1.08 if air else 1.0), minf(1.0, dt * (20.0 if air else 8.0)))   # wheels in the air: the revs flare
		if g_lo != last_gear_lo:
			if g_lo > last_gear_lo and last_gear_lo >= 0.0:
				pitch_v -= 0.15   # small lurch of the body on the upshift
			last_gear_lo = g_lo
		a_rumble.volume_db = linear_to_db(maxf(0.0001, 0.0 if air else ((rough - 0.6) * 0.04 + ROUGH[int(pos / SEG) % N] * 0.10) * sp + (0.1 if off or on_rail else 0.0)))   # no tyre noise in the air; the rail growls for as long as you lean on it
		a_rumble.pitch_scale = 0.8 + 0.4 * sp
		a_hiss.volume_db = linear_to_db(maxf(0.0001, 0.0 if air else clampf(absf(curve * sp * sp) * 0.04 + aqua * 0.12 + rain * sp * 0.015, 0.0, 0.15)))
		if off:
			kick += randf_range(-0.05, 0.05)

	var gear: String = "N" if v < 1.0 else ["1ª", "2ª", "3ª", "4ª", "5ª"][gear_i]   # the same gear the engine sound uses
	hud.set_values(score, hi, v, gear, fuel)

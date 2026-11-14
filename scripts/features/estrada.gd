extends Node
# Estrada: the road no longer repeats every lap.
# - The stretch left behind (BEHIND segments back, out of sight) is dressed again with new zones, signs,
#   billboards, potholes, puddles and rough stretches, and finished bends may turn the other way.
# - Fuel stops are placed by distance driven (every few km), not at fixed points of the loop.
# - Green (brown on the dirt road) distance signs name real towns with real km, counting down as you go;
#   the expressway gets gantries instead. An optional DESTINO (main menu) ends in a small celebration.
# - Now and then the road runs through a small town with two painted speed bumps (feat t = 3).
# - The crests of the road (game.gd, crest_dress) move every lap too, each with its warning sign.
# Everything random here comes from one RandomNumberGenerator seeded per trip (Engine "test_seed" in tests).

const Cat = preload("res://scripts/catalog.gd")
const SEGS_KM := 1710.0    # segments per km: 1 km = 342,000 units (UPK 95 units per km/h per second)
const BEHIND := 200        # re-dress this far behind the car: the camera draws 150 ahead, the chase view ~12 back
const AHEAD := 420         # events are planned this far ahead of the dressing cursor (their signs sit up to 170 before)
const TANK_KM := 11.67     # a full tank, with game.gd burning dt / 600 s at 70 km/h
const INK := Color("e6e8ee")
const ART := ["placa_km_verde", "placa_km_marrom", "placa_cidade", "placa_volte", "portico_branco", "placa_lombada",
	"placa_reduza", "casa_vila0", "casa_vila1", "casa_vila2", "casa_vila3", "casa_vila4", "igreja", "bar", "ponto_onibus",
	"orelhao", "gente0", "gente1", "gente2", "bandeirinhas"]
const ROADS := {
	"terra": {"town_km": [4.0, 7.0], "stop_km": [4.0, 6.0], "km_sign": [1.0, 1.6], "town_len": 200, "town_pre": 200,
		"zones": ["cafe", "pasto", "eucalipto", "mata"], "zone_len": [80, 160], "stop_name": "VENDA"},
	"br": {"town_km": [6.0, 10.0], "stop_km": [5.0, 8.0], "km_sign": [1.5, 2.5], "town_len": 240, "town_pre": 200,
		"zones": ["campo", "campo", "araucaria", "pasto", "eucalipto", "mata"], "zone_len": [150, 450], "stop_name": "POSTO"},
	"expressa": {"town_km": [8.0, 13.0], "stop_km": [6.0, 9.0], "km_sign": [2.0, 3.0], "town_len": 520, "town_pre": 360,
		"zones": ["aberto", "aberto", "bairro"], "zone_len": [200, 340], "stop_name": "PARADA"},
}
# the 5x7 font of the sprite sheet (tools/art), one dot per logical unit on the signs
const GL := {"A": [14, 17, 17, 31, 17, 17, 17], "B": [30, 17, 17, 30, 17, 17, 30], "C": [14, 17, 16, 16, 16, 17, 14],
	"D": [30, 17, 17, 17, 17, 17, 30], "E": [31, 16, 16, 30, 16, 16, 31], "F": [31, 16, 16, 30, 16, 16, 16],
	"G": [14, 17, 16, 23, 17, 17, 15], "H": [17, 17, 17, 31, 17, 17, 17], "I": [14, 4, 4, 4, 4, 4, 14], "J": [7, 2, 2, 2, 2, 18, 12],
	"K": [17, 18, 20, 24, 20, 18, 17], "L": [16, 16, 16, 16, 16, 16, 31], "M": [17, 27, 21, 21, 17, 17, 17],
	"N": [17, 25, 21, 19, 17, 17, 17], "O": [14, 17, 17, 17, 17, 17, 14], "P": [30, 17, 17, 30, 16, 16, 16],
	"Q": [14, 17, 17, 17, 21, 18, 13], "R": [30, 17, 17, 30, 20, 18, 17], "S": [15, 16, 16, 14, 1, 1, 30], "T": [31, 4, 4, 4, 4, 4, 4],
	"U": [17, 17, 17, 17, 17, 17, 14], "V": [17, 17, 17, 17, 17, 10, 4], "W": [17, 17, 17, 21, 21, 27, 17],
	"X": [17, 17, 10, 4, 10, 17, 17], "Y": [17, 17, 10, 4, 4, 4, 4], "Z": [31, 1, 2, 4, 8, 16, 31],
	"0": [14, 17, 19, 21, 25, 17, 14], "1": [4, 12, 4, 4, 4, 4, 14], "2": [14, 17, 1, 2, 4, 8, 31], "3": [31, 2, 4, 2, 1, 17, 14],
	"4": [2, 6, 10, 18, 31, 2, 2], "5": [31, 16, 30, 1, 1, 17, 14], "6": [6, 8, 16, 30, 17, 17, 14], "7": [31, 1, 2, 4, 8, 8, 8],
	"8": [14, 17, 17, 14, 17, 17, 14], "9": [14, 17, 17, 15, 1, 2, 12], "-": [0, 0, 0, 31, 0, 0, 0], ".": [0, 0, 0, 0, 0, 0, 4],
	",": [0, 0, 0, 0, 0, 4, 8]}
const ACC := {"Á": "Aa", "À": "Ag", "Ã": "At", "Â": "Ac", "É": "Ea", "Ê": "Ec", "Í": "Ia", "Ó": "Oa", "Ô": "Oc", "Õ": "Ot", "Ú": "Ua", "Ç": "Cd"}
const ACM := {"a": [[3, -3], [2, -2]], "g": [[1, -3], [2, -2]], "c": [[1, -2], [2, -3], [3, -2]], "t": [[1, -2], [2, -3], [3, -2], [4, -3]],
	"d": [[2, 7], [1, 8]]}

var g
var rng := RandomNumberGenerator.new()   # everything on the road
var fx_rng := RandomNumberGenerator.new()   # fireworks and other looks: never touches the road's sequence
var R: Dictionary = ROADS["br"]
var road_id := "br"
var N := 0
var cursor := -1          # absolute index (laps * N + i) of the last dressed segment
var abs_c := 0            # absolute index of the car's segment
var last_ci := 0
var horizon := -1
var pending := {}         # absolute index -> sprites waiting for that segment to be dressed
var pending_feat := {}    # absolute index -> features (speed bumps, the far end of a puddle)
var towns: Array = []     # {a, len, name, planned, bunting}: the road runs through them, in order
var stops: Array = []     # {a, planned}: fuel stops by distance
var stop_at := {}         # absolute index -> true, for the stops already planned
var zones: Array = []     # [start, end, kind]: landscape stretches
var rough: Array = []     # [start, end, sign]: half waves of the rough-road profile
var quiet := {}           # absolute index -> true: no landscape clutter (around a farmhouse)
var next_at := {}
var last_hole := -1000
var names: Array = []
var name_i := 0
var base_km := 0
var period := 300
var tex_cache := {}
var _clear_r := false

# the trip: destination, towns announced, a few fireworks on arrival
var dest_k := 0           # 0: no destination, k: the k-th town ahead when the trip starts
var dest: Dictionary = {}
var town_next := 0
var warned := {}
var low_seen := false
var fw: Array = []        # [x, y, age, colour]
var fw_t := 0.0
var fw_spawn := 0.0
var sky_x := 192.0
var menu_item: Dictionary = {}
var dest_rows: Array = []
var dest_sel := 0
var dest_txt: Array = []
var arrived_km := 0.0

func _ready() -> void:
	g = get_parent()
	for n in ART:
		g.tex[n] = AnimTex.load_sprite(n)
	g.setup_done.connect(_on_setup)
	g.trip_started.connect(_on_start)
	dest_k = int(g.store_get("estrada", "destino", 0))
	fx_rng.randomize()
	_add_menu.call_deferred()

# ---------------------------------------------------------------- the road, dressed piece by piece

func _on_setup() -> void:
	road_id = g.cfg.road
	R = ROADS[road_id]
	N = g.N
	if g.trip_seed > 0:   # a trip code or the trip of the day: the same seed dresses the same road
		rng.seed = hash([g.trip_seed, road_id])
		fx_rng.seed = 7
	elif Engine.has_meta("test_seed"):
		rng.seed = hash([Engine.get_meta("test_seed"), road_id])
		fx_rng.seed = 7
	else:
		rng.randomize()
	cursor = -1
	abs_c = 0
	last_ci = 0
	horizon = -1
	for d in [pending, pending_feat, stop_at, quiet, warned, tex_cache]:
		d.clear()
	for a in [towns, stops, zones, rough, fw]:
		a.clear()
	dest = {}
	town_next = 0
	last_hole = -1000
	period = maxi(120, N / 9)
	names = Cat.TOWNS[road_id].duplicate()
	for i in range(names.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = names[i]
		names[i] = names[j]
		names[j] = tmp
	name_i = 0
	base_km = rng.randi_range(12, 280)
	next_at = {"sign": rng.randi_range(100, 250), "board": rng.randi_range(250, 450), "km": rng.randi_range(160, 420),
		"farm": rng.randi_range(150, 300), "led": rng.randi_range(300, 500), "placa": rng.randi_range(200, 350)}
	stops.append({"a": int(rng.randf_range(2.5, 4.0) * SEGS_KM), "planned": false})
	rough.append([0, 260 + rng.randi_range(0, period / 2), -1])   # start on a smooth stretch: its warning needs room
	g.postos.clear()
	for s in g.segs:
		s.spr.clear()
		s.feat.clear()
	_dress_to(N - 1)
	_update_menu()

func _process(dt: float) -> void:
	if N == 0 or N != g.N:
		return
	var ci := int(g.pos / g.SEG) % N
	var d := posmod(ci - last_ci, N)
	last_ci = ci
	if d > 0 and d < N - 350:   # a jump back (tests teleport the car) is not driving
		abs_c += d
		_dress_to(abs_c + N - BEHIND)
		_trip_events()
	_fireworks(dt)

func _dress_to(target: int) -> void:
	while cursor < target:
		cursor += 1
		_plan(cursor + AHEAD)
		_fuel_check()
		_dress(cursor)

func _pick(a: Array):
	return a[rng.randi_range(0, a.size() - 1)]

func _spr(name: String, off: float, ww: float, kind := 0, keep := false) -> Dictionary:
	return {"tex": g.tex[name], "off": off, "ww": ww, "kind": kind, "name": name, "keep": keep}

func _put(a: int, name: String, off: float, ww: float, kind := 0, keep := false) -> void:
	if not pending.has(a):
		pending[a] = []
	pending[a].append(_spr(name, off, ww, kind, keep))

func _put_tex(a: int, tx: Texture2D, name: String, off: float, ww: float, kind: int, far: float) -> void:
	if not pending.has(a):
		pending[a] = []
	pending[a].append({"tex": tx, "off": off, "ww": ww, "kind": kind, "name": name, "keep": true, "far": far})

func _town_at(a: int, before := 0, after := 0) -> Dictionary:
	for t in towns:
		if a >= t.a - before and a < t.a + t.len + after:
			return t
	return {}

func _near_stop(a: int, r: int) -> bool:
	for s in stops:
		if absi(a - s.a) <= r:
			return true
	return false

func _blocked(a: int, m: int) -> bool:   # keep minor signs out of towns and away from the stops and their signs
	if not _town_at(a, R.town_pre + m, 30 + m).is_empty():
		return true
	for s in stops:
		if a > s.a - 160 - m and a < s.a + 25 + m:
			return true
	return false

func _rough_at(a: int) -> float:
	var rb: float = g.road.rough_base
	for k in range(rough.size() - 1, -1, -1):
		var p: Array = rough[k]
		if a >= p[0] and a < p[1]:
			return clampf(sin(float(a - p[0]) / (p[1] - p[0]) * PI) * p[2] * 1.6 - 0.3 + rb, 0.0, 1.0)
	return clampf(rb - 0.3, 0.0, 1.0)

func _zone_kind(a: int) -> String:
	for k in range(zones.size() - 1, -1, -1):
		if a >= zones[k][0] and a < zones[k][1]:
			return zones[k][2]
	return R.zones[0]

# decide what comes next, far enough ahead that signs can stand before what they announce
func _plan(h: int) -> void:
	if h > horizon:
		horizon = h
		while towns.size() < 4 or towns[towns.size() - 4].a < h + 400:   # the signs name two towns, the menu three
			var last: int = 0 if towns.is_empty() else towns.back().a + towns.back().len
			towns.append({"a": last + int(rng.randf_range(R.town_km[0], R.town_km[1]) * SEGS_KM), "len": R.town_len,
				"name": names[name_i % names.size()], "planned": false, "bunting": rng.randf() < 0.4})
			name_i += 1
		while stops.back().a < h + 600:
			var a: int = stops.back().a + int(rng.randf_range(R.stop_km[0], R.stop_km[1]) * SEGS_KM)
			var t := _town_at(a, 420, 160)
			if not t.is_empty():
				a = t.a + t.len + 220
			stops.append({"a": a, "planned": false})
		while zones.is_empty() or zones.back()[1] <= h:
			var z0: int = 0 if zones.is_empty() else zones.back()[1]
			zones.append([z0, z0 + rng.randi_range(R.zone_len[0], R.zone_len[1]), _pick(R.zones)])
		while rough.back()[1] <= h + 200:
			var r0: int = rough.back()[1]
			rough.append([r0, r0 + rng.randi_range(int(period * 0.3), int(period * 0.75)), -rough.back()[2]])
		while zones.size() > 2 and zones[0][1] < cursor - 10:
			zones.pop_front()
		while rough.size() > 2 and rough[0][1] < cursor - 10:
			rough.pop_front()
		_streams(h)
	for t in towns:
		if not t.planned and t.a <= h:
			t.planned = true
			if road_id == "expressa":
				_plan_city(t)
			else:
				_plan_town(t)
	for s in stops:
		if not s.planned and s.a <= h:
			s.planned = true
			_plan_stop(s.a)
	while stops.size() > 2 and stops[0].a < abs_c - N:
		stops.pop_front()

# signs, billboards and farmhouses at their own irregular spacing
func _streams(h: int) -> void:
	while next_at.km <= h:
		var a: int = next_at.km
		next_at.km += int(rng.randf_range(R.km_sign[0], R.km_sign[1]) * SEGS_KM)
		if not _blocked(a, 40):
			if road_id == "expressa":
				_plan_gantry(a)
			else:
				_plan_km_sign(a)
	match road_id:
		"br":
			while next_at.sign <= h:
				var a: int = next_at.sign
				next_at.sign += rng.randi_range(250, 450)
				if not _blocked(a, 10):
					_put(a, "sign%d" % _pick([0, 2, 4, 5]), 1.38, 1700.0, 4)   # sign1 ("SÃO PAULO 408 KM") would lie now
			while next_at.board <= h:
				var a: int = next_at.board
				next_at.board += rng.randi_range(350, 700)
				if not _blocked(a, 10):
					_put(a, "board%d" % rng.randi_range(0, 3), 2.3, 2600.0, 5)
		"terra":
			while next_at.farm <= h:   # a farmhouse with its gate, a chapel now and then, and the signs before it
				var a: int = next_at.farm
				next_at.farm += rng.randi_range(220, 400)
				if _blocked(a, 130):
					continue
				var side := 1.0 if rng.randf() < 0.5 else -1.0
				for d in range(-3, 4):
					quiet[a + d] = true
				_put(a, "capela" if rng.randf() < 0.18 else "casa_sitio", side * 3.0, 2600.0)
				_put(a - 6, "porteira", side * 1.42, 900.0)
				_put(a - 60, _pick(["placa_queijo", "placa_ovos"]), 1.36, 900.0, 4)
				_put(a - 120, "placa_sitio%d" % rng.randi_range(0, 2), 1.4, 1700.0, 4)
		"expressa":
			while next_at.led <= h:
				var a: int = next_at.led
				next_at.led += rng.randi_range(400, 700)
				if not _blocked(a, 10):
					_put(a, _pick(["led0", "led1"]), 2.2, 2600.0, 5)
			while next_at.placa <= h:
				var a: int = next_at.placa
				next_at.placa += rng.randi_range(400, 700)
				if not _blocked(a, 10):
					_put(a, _pick(["placa_radar", "placa_saida", "placa_pedagio"]), 1.4, 1700.0, 4)

func _plan_stop(a: int) -> void:
	stop_at[a] = true
	_put(a, g.road.stop, 2.75, g.road.stop_ww, 3, true)
	_put(a - 150, g.road.stop_sign, 1.38, 1700.0, 4, true)
	if road_id == "br":
		for d in range(-60, 61, 20):
			if absi(d) > 10:
				_put(a + d, "lamp", 1.25, 1100.0, 2, true)

# low on fuel and the next stop is too far: open one as soon as it can be out of sight
func _fuel_check() -> void:
	if not g.started:
		return
	var nxt := {}
	for s in stops:
		if s.a > abs_c + 20:
			nxt = s
			break
	if nxt.is_empty():
		return
	var a := cursor + 165
	if g.fuel * TANK_KM < (nxt.a - abs_c) / SEGS_KM + 0.4 and a < nxt.a - 400 and _town_at(a, 420, 160).is_empty():
		stops.insert(stops.find(nxt), {"a": a, "planned": false})

# ---------------------------------------------------------------- signs with text

func _tw(s: String, p := 1.0) -> float:
	return s.length() * 6.0 * p - p

func _text(img: Image, s: String, x: float, y: float, col: Color, p := 1.0) -> void:
	var d := maxi(1, int(roundf(2.0 * p)))
	for ch in s:
		var ac: String = ACC.get(ch, "")
		var key: String = ac[0] if ac != "" else ch
		if GL.has(key):
			var gl: Array = GL[key]
			for r in 7:
				for b in 5:
					if (int(gl[r]) >> (4 - b)) & 1:
						img.fill_rect(Rect2i(int(roundf((x + b * p) * 2.0)), int(roundf((y + r * p) * 2.0)), d, d), col)
		if ac != "":
			for m in ACM[ac[1]]:
				img.fill_rect(Rect2i(int(roundf((x + m[0] * p) * 2.0)), int(roundf((y + m[1] * p) * 2.0)), d, d), col)
		x += 6.0 * p

# a blank sign with lines written on it: [text, x, y, align "l" | "r" | "c"], in the sprite's logical units
func _sign_tex(base: String, items: Array) -> Texture2D:
	var key := base + str(items)
	if tex_cache.has(key):
		return tex_cache[key]
	if tex_cache.size() > 48:
		tex_cache.clear()   # the sprites keep their own reference
	var img: Image = g.tex[base].get_image().duplicate()
	if img.is_compressed():
		img.decompress()
	img.convert(Image.FORMAT_RGBA8)
	for it in items:
		var s: String = it[0]
		var x: float = it[1]
		if it[3] == "r":
			x -= _tw(s)
		elif it[3] == "c":
			x -= _tw(s) / 2.0
		_text(img, s, roundf(x * 2.0) / 2.0, it[2], INK)
	var tx := ImageTexture.create_from_image(img)
	tex_cache[key] = tx
	return tx

func _ahead_of(a: int, n: int) -> Array:
	var out: Array = []
	for t in towns:
		if t.a > a + 30:
			out.append(t)
			if out.size() == n:
				break
	return out

func _km_txt(km: int) -> String:
	return "%d KM" % maxi(1, km)

# green (brown on the dirt road) sign: the next two towns and how far they are from right here
func _plan_km_sign(a: int) -> void:
	var items: Array = []
	var row := 0
	for t in _ahead_of(a, 2):
		items.append([t.name, 5.0, 5.0 + row * 10.0, "l"])
		items.append([_km_txt(roundi((t.a - a) / SEGS_KM)), 123.0, 5.0 + row * 10.0, "r"])
		row += 1
	var base := "placa_km_marrom" if road_id == "terra" else "placa_km_verde"
	var ww: float = 3000.0 * clampf(g.ROADW / 2000.0, 0.8, 1.0)
	_put_tex(a, _sign_tex(base, items), "placa_km", 1.05 + ww / g.ROADW / 2.0, ww, 4, 46.0)

# expressway gantry: straight on to the next town, and the exit to a neighbourhood
func _plan_gantry(a: int) -> void:
	var nx := _ahead_of(a, 1)
	var t: Dictionary = nx[0]
	var exit_n := base_km + int(a / SEGS_KM) + 1
	var items: Array = [[t.name, 72.0, 5.0, "c"], [_km_txt(roundi((t.a - a) / SEGS_KM)), 72.0, 16.0, "c"],
		["SAÍDA %d" % exit_n, 178.0, 5.0, "c"], [_pick(Cat.TOWNS.exits), 178.0, 16.0, "c"]]
	_put_tex(a, _sign_tex("portico_branco", items), "portico", 0.0, g.ROADW / 2000.0 * 4600.0, 8, 0.0)

# ---------------------------------------------------------------- the small town

func _plan_town(t: Dictionary) -> void:
	var a: int = t.a
	var L: int = t.len
	var rw: float = g.ROADW
	var two: bool = road_id == "terra"
	_put(a - 170, "placa_reduza", 1.42, 1500.0, 4, true)
	_put_tex(a - 12, _sign_tex("placa_cidade", [[t.name, 64.0, 14.0, "c"]]), "placa_cidade", 1.05 + 3000.0 / rw / 2.0, 3000.0, 4, 46.0)
	for b in [a + 40, a + L - 40]:   # two painted speed bumps, each with its yellow sign
		if not pending_feat.has(b):
			pending_feat[b] = []
		pending_feat[b].append({"t": 3, "x": 0.0, "w": 1.0})
		_put(b - 45, "placa_lombada", 1.3, 1000.0, 4, true)
	var edge := {1: 1.12, -1: (1.12 if two else 3.55)}   # on the BR the left side is past the other carriageway
	var mid := a + L / 2
	var cs := -1 if (two and rng.randf() < 0.5) else 1
	var marks: Array = [[mid - 8, "igreja", 3600.0, cs], [a + 72 + rng.randi_range(0, 20), "bar", 3000.0, -cs if two else 1],
		[a + 24, "ponto_onibus", 1700.0, 1]]
	for m in marks:
		var ww: float = m[2]
		_put(m[0], m[1], m[3] * (edge[m[3]] + 0.05 + ww / rw / 2.0), ww, 0, true)
	for side in [1, -1]:   # row houses on both sides, with a gap where the landmarks stand
		var k := 4 + rng.randi_range(0, 4)
		while k < L - 8:
			var free := true
			for m in marks:
				if m[3] == side and absi(a + k - m[0]) < 13:
					free = false
			if free:
				var ww := 2400.0
				_put(a + k, "casa_vila%d" % rng.randi_range(0, 4), side * (edge[side] + 0.05 + ww / rw / 2.0), ww, 0, true)
			k += 12 + rng.randi_range(0, 6)
	_put(a + int(L * 0.6), "orelhao", 1.2, 650.0, 0, true)
	for n in 5:   # people on the pavement
		var side := 1 if (not two or rng.randf() < 0.6) else -1
		_put(a + rng.randi_range(8, L - 8), "gente%d" % rng.randi_range(0, 2), side * (1.14 + rng.randf() * 0.1), 330.0, 0, true)
	for k in range(6, L, 24):
		_put(a + k, "lamp", 1.22, 1100.0, 2, true)
	if t.bunting or (not dest.is_empty() and dest.a == t.a):   # festa: bunting across the street
		for o in [-22, 18]:
			_put(mid + o, "bandeirinhas", 0.0, rw * 2.215, 0, true)
	_put(a + L + 8, "placa_volte", 1.38, 1700.0, 4, true)
	_plan_km_sign(a + L + 120)

# the expressway passes a city: sound walls, a gantry with its exit, and the skyline beyond
func _plan_city(t: Dictionary) -> void:
	var a: int = t.a
	var nx := _ahead_of(a, 1)
	var items: Array = [[nx[0].name, 72.0, 5.0, "c"], [_km_txt(roundi((nx[0].a - a + 340) / SEGS_KM)), 72.0, 16.0, "c"],
		["SAÍDA %d" % (base_km + int(a / SEGS_KM)), 178.0, 5.0, "c"], [t.name, 178.0, 16.0, "c"]]
	_put_tex(a - 340, _sign_tex("portico_branco", items), "portico", 0.0, g.ROADW / 2000.0 * 4600.0, 8, 0.0)
	_put_tex(a, _sign_tex("placa_cidade", [[t.name, 64.0, 14.0, "c"]]), "placa_cidade", 1.05 + 3000.0 / g.ROADW / 2.0, 3000.0, 4, 46.0)

# ---------------------------------------------------------------- one segment

func _dress(A: int) -> void:
	var i := A % N
	var sg = g.segs[i]
	if A >= N:
		_maybe_flip(i)
	g.crest_dress(A)   # this lap's crests (game.gd), wherever they fall now
	g.postos.erase(i)
	sg.spr.clear()
	sg.feat.clear()
	g.ROUGH[i] = _rough_at(A)
	g.NOISE[i] = (rng.randf() * 2.0 - 1.0) * g.road.noise
	var town := _town_at(A)
	_clear_r = _near_stop(A, 20)   # the stop's forecourt: nothing on the right
	if not quiet.has(A):
		_clutter(A, i, not town.is_empty())
	quiet.erase(A)
	var signed := false
	if pending.has(A):
		for q in pending[A]:
			signed = signed or q.kind == 4
			if not (_clear_r and q.off > 0.0 and not q.keep):
				sg.spr.append(q)
		pending.erase(A)
	if pending_feat.has(A):
		sg.feat.append_array(pending_feat[A])
		pending_feat.erase(A)
	if stop_at.has(A):
		g.postos.append(i)
		stop_at.erase(A)
	if _rough_at(A + 95) > 0.25 and _rough_at(A + 94) <= 0.25 and town.is_empty() and not signed and not _near_stop(A, 30):
		var w := "sign3" if road_id != "terra" else "placa_gado"   # ~2 s of warning at 100 km/h
		sg.spr.append(_spr(w, 1.38, 1700.0, 4))
	if g.crest_h_at(A + 70) == 0.0 and g.crest_h_at(A + 71) > 0.0 and not _near_stop(A, 30):   # a crest begins ahead: the yellow diamond warns ~2 s before
		sg.spr.append(_spr("placa_lombada", 1.36 if signed else 1.3, 1000.0, 4, true))
	if town.is_empty() and A >= 60:
		_surface(A, i)

func _add(i: int, name: String, off: float, ww: float, kind := 0) -> void:
	if _clear_r and off > 0.0 and kind != 1 and kind != 6:
		return
	g._add_spr(i, name, off, ww, kind)

func _clutter(A: int, i: int, in_town: bool) -> void:
	var zk := _zone_kind(A)
	match road_id:
		"br":
			if A % 14 == 0:
				_add(i, "pole", 1.42, 1100.0, 1)
			if in_town:
				return
			var trees := ["tree0", "tree1", "araucaria", "araucaria"]
			match zk:
				"campo":
					if rng.randf() < 0.22:
						_add(i, _pick(trees), rng.randf_range(1.9, 5.5), rng.randf_range(1500, 2400))
					if rng.randf() < 0.1:
						_add(i, "bush", rng.randf_range(1.25, 1.7), 800.0)
				"araucaria":
					if rng.randf() < 0.3:
						_add(i, "araucaria", rng.randf_range(1.8, 5.5), rng.randf_range(1700, 2500))
				"pasto":
					if A % 3 == 0:
						_add(i, "cerca", 1.28, 700.0)
					if rng.randf() < 0.025:
						_add(i, _pick(["vaca0", "vaca1"]), rng.randf_range(1.9, 4.5), 900.0)
					if rng.randf() < 0.03:
						_add(i, _pick(["tree0", "ipe"]), rng.randf_range(3.0, 6.0), rng.randf_range(1600, 2300))
				"eucalipto":
					if rng.randf() < 0.35:
						_add(i, "eucalipto", rng.randf_range(1.8, 5.5), rng.randf_range(1500, 2100))
				"mata":
					if rng.randf() < 0.3:
						_add(i, _pick(["tree0", "tree1", "araucaria", "bambu", "ipe"]), rng.randf_range(1.6, 5.0), rng.randf_range(1500, 2400))
					elif rng.randf() < 0.12:
						_add(i, "bush", rng.randf_range(1.25, 1.7), 800.0)
			if rng.randf() < (0.3 if zk == "araucaria" or zk == "mata" else 0.2):
				_add(i, _pick(trees), -rng.randf_range(3.9, 7.0), rng.randf_range(1500, 2400))
		"terra":
			if A % 28 == 0:
				_add(i, "pole", 1.5, 1000.0, 1)
			if in_town:
				return
			for side in [-1.0, 1.0]:
				if A % 3 == 0 and zk != "mata":
					_add(i, "cerca", side * 1.28, 700.0)
				match zk:
					"cafe":
						if A % 4 == 0:
							for k in 3:
								_add(i, "cafe", side * (1.8 + k * 0.9 + rng.randf() * 0.2), 1100.0)
					"pasto":
						if rng.randf() < 0.025:
							_add(i, _pick(["vaca0", "vaca1"]), side * rng.randf_range(1.9, 4.5), 900.0)
						if rng.randf() < 0.03:
							_add(i, _pick(["tree0", "ipe"]), side * rng.randf_range(3.0, 6.0), rng.randf_range(1600, 2300))
					"eucalipto":
						if rng.randf() < 0.35:
							_add(i, "eucalipto", side * rng.randf_range(1.8, 5.5), rng.randf_range(1500, 2100))
					"mata":
						if rng.randf() < 0.3:
							_add(i, _pick(["tree0", "tree1", "araucaria", "bambu", "ipe"]), side * rng.randf_range(1.5, 5.0), rng.randf_range(1500, 2400))
						elif rng.randf() < 0.1:
							_add(i, "bush", side * rng.randf_range(1.3, 1.8), 800.0)
		"expressa":
			if A % 8 == 0:
				_add(i, "luminaria", -1.1, 1900.0, 6)
			if in_town or zk == "bairro":
				if A % 2 == 0:
					_add(i, "muro", 1.55, 1700.0)
			elif rng.randf() < 0.12:
				_add(i, _pick(["tree0", "tree1", "bush"]), rng.randf_range(1.8, 5.0), rng.randf_range(1300, 2200))
			if rng.randf() < 0.08:
				_add(i, _pick(["tree0", "tree1"]), -rng.randf_range(3.6, 6.0), rng.randf_range(1500, 2200))
			if A % 60 == 30:
				_add(i, "sos", 1.3, 500.0)

func _hole_factor() -> float:
	var aj = g.get_node_or_null("ajustes")
	if aj == null or not aj.has_method("get_idx"):
		return 1.0
	return [0.5, 1.0, 2.0][clampi(aj.get_idx("holes"), 0, 2)]

# potholes, patches and puddles, with the odds of game.gd's _build_surface
func _surface(A: int, i: int) -> void:
	var rd: Dictionary = g.road
	var r: float = g.ROUGH[i]
	var sg = g.segs[i]
	var hf := _hole_factor()   # AJUSTES > BURACOS: fewer, normal, or a bad road
	if A - last_hole >= int(rd.hole_gap / hf) and rng.randf() < (rd.hole_p + r * rd.hole_k) * hf:
		last_hole = A
		sg.feat.append({"t": 0, "x": _pick(g.LANES) + rng.randf_range(-0.22, 0.22), "w": rng.randf_range(0.07, 0.12)})
	if r > 0.25 and rng.randf() < rd.patch_p:
		sg.feat.append({"t": 1, "x": rng.randf_range(-0.85, 0.85), "w": rng.randf_range(0.1, 0.26)})
	var Y: PackedFloat32Array = g.Y
	var zone := pow(maxf(0.0, sin(float(i) / N * TAU * 6.0 + 1.0)), 1.5)   # where game.gd baked the long undulations
	if g.cfg.weather == "chuva" and zone > 0.25 and Y[i] < Y[posmod(i - 1, N)] and Y[i] <= Y[(i + 1) % N] and rng.randf() < rd.puddle_p:
		var fx: float = _pick([-0.8, 0.8] + g.LANES)
		var fwid := rng.randf_range(0.16, 0.3)
		for q in [[-2, 0.3, 0.8], [-1, 0.8, 1.0], [0, 1.0, 0.9], [1, 0.9, 0.35]]:
			var f := {"t": 2, "x": fx, "w": fwid, "a": q[1], "b": q[2]}
			if q[0] <= 0:
				g.segs[posmod(i + q[0], N)].feat.append(f)
			else:
				if not pending_feat.has(A + q[0]):
					pending_feat[A + q[0]] = []
				pending_feat[A + q[0]].append(f)

# a bend that is now well behind us may turn the other way next time (it starts and ends straight)
func _maybe_flip(i: int) -> void:
	if g.segs[i].curve == 0.0 or g.segs[(i + 1) % N].curve != 0.0:
		return
	if rng.randf() < 0.5:
		return
	var j := i
	var n := 0
	while g.segs[j].curve != 0.0 and n < N - 400:
		g.segs[j].curve = -g.segs[j].curve
		j = posmod(j - 1, N)
		n += 1

# ---------------------------------------------------------------- the trip: towns, destination, arrival

func _trip_events() -> void:
	while town_next < towns.size() and abs_c >= towns[town_next].a:
		var t: Dictionary = towns[town_next]
		town_next += 1
		if g.started:
			if not dest.is_empty() and dest.a == t.a:
				_arrive(t)
			else:
				g.hud.notice("PASSANDO POR %s" % t.name, 4.0)
	if not g.started:
		return
	if not dest.is_empty():
		var km: float = (dest.a - abs_c) / SEGS_KM
		for m in [10, 5, 2, 1]:
			if km <= m and km > m - 0.6 and not warned.has(m):
				warned[m] = true
				g.hud.notice(("%s LOGO ALI: 1 KM" % dest.name) if m == 1 else ("FALTAM %d KM PARA %s" % [m, dest.name]), 5.0)
	if g.low_warn and not low_seen:
		low_seen = true
		for s in stops:
			if s.a > abs_c:
				g.hud.notice("%s EM %s KM, NA FAIXA DA DIREITA" % [R.stop_name, _km1((s.a - abs_c) / SEGS_KM)], 6.0)
				break
	elif not g.low_warn:
		low_seen = false

func _km1(km: float) -> String:
	return ("%.1f" % km).replace(".", ",")

func _arrive(t: Dictionary) -> void:
	g.hud.toast("CHEGAMOS A %s!" % t.name, 3.5)
	var mins := int(g.trip_time / 60.0)
	g.hud.notice("%s KM EM %d MIN. A ESTRADA CONTINUA, SEM PRESSA" % [_km1(g.km_trip - arrived_km), maxi(1, mins)], 7.0)
	arrived_km = g.km_trip
	fw_t = 6.0
	fw_spawn = 0.0
	var seen: Array = g.store_get("estrada", "visitadas", [])
	if not seen.has(t.name):
		seen.append(t.name)
	g.store_set("estrada", "visitadas", seen)
	g.store_save()
	dest = {}
	_update_menu()

func _on_start() -> void:
	warned.clear()
	low_seen = false
	arrived_km = 0.0
	dest = {}
	if dest_k > 0:
		var ahead := _ahead_of(abs_c, dest_k)
		if ahead.size() >= dest_k:
			dest = ahead[dest_k - 1]
			if not dest.planned:
				dest.bunting = true
			g.hud.notice("DESTINO: %s, A %s KM" % [dest.name, _km1((dest.a - abs_c) / SEGS_KM)], 6.0)

# ---------------------------------------------------------------- menu: DESTINO

func _add_menu() -> void:
	g.menu.add_main_item(_menu_label(), _open_dest)
	menu_item = g.menu.extras.back()

func _menu_label() -> String:
	if dest_k == 0:
		return "DESTINO: LIVRE"
	var ahead := _ahead_of(abs_c, dest_k)
	if ahead.size() < dest_k:
		return "DESTINO"
	return "DESTINO: %d KM" % roundi((ahead[dest_k - 1].a - abs_c) / SEGS_KM)

func _update_menu() -> void:
	if menu_item.is_empty():
		return
	menu_item.label = _menu_label()
	g.menu.refresh()

func _open_dest() -> void:
	g.menu.open_screen("DESTINO", _build_dest, _dest_key)

func _build_dest(body: Control) -> void:
	dest_rows.clear()
	dest_sel = dest_k
	var opts: Array = ["SEM DESTINO: SÓ ESTRADA"]
	for t in _ahead_of(abs_c, 3):
		opts.append("%s  %d KM" % [t.name, roundi((t.a - abs_c) / SEGS_KM)])
	g.menu.label("PARA ONDE VAMOS PELA %s?" % g.road.name, 8, Color("9bbbe0"), Vector2(20, 6), body)
	dest_txt = opts
	for i in opts.size():
		dest_rows.append(g.menu.label(opts[i], 16, INK, Vector2(20, 34 + i * 32), body))
	g.menu.label("AS PLACAS DE KM CONTAM A DISTÂNCIA. AO CHEGAR, A VIAGEM SEGUE.", 8, Color("6f86a8"), Vector2(20, 176), body)
	var seen: Array = g.store_get("estrada", "visitadas", [])
	var txt := "NENHUMA CIDADE VISITADA AINDA"
	if not seen.is_empty():
		txt = "CIDADES VISITADAS: %d  (%s)" % [seen.size(), ", ".join(seen.slice(maxi(0, seen.size() - 3)))]
	g.menu.label(txt, 8, Color("6f86a8"), Vector2(20, 194), body)
	g.menu.label("SETAS ESCOLHEM  ENTER CONFIRMA", 8, Color("6f86a8"), Vector2(20, 310), body)
	_paint_dest()

func _paint_dest() -> void:
	for i in dest_rows.size():
		var on := i == dest_sel
		dest_rows[i].text = ("> " if on else "  ") + dest_txt[i]
		dest_rows[i].label_settings.font_color = Color("f2a62a") if on else INK

func _dest_key(k: int) -> void:
	match k:
		KEY_UP, KEY_W:
			dest_sel = (dest_sel + dest_rows.size() - 1) % dest_rows.size()
			_paint_dest()
		KEY_DOWN, KEY_S:
			dest_sel = (dest_sel + 1) % dest_rows.size()
			_paint_dest()
		KEY_ENTER, KEY_KP_ENTER, KEY_SPACE:
			dest_k = dest_sel
			g.store_set("estrada", "destino", dest_k)
			g.store_save()
			g.menu.close_screen()
			_update_menu()

# ---------------------------------------------------------------- drawing: the next town on the horizon, fireworks

func _fireworks(dt: float) -> void:
	for f in fw:
		f[2] += dt
	fw = fw.filter(func(f): return f[2] < 1.5)
	if fw_t > 0.0:
		fw_t -= dt
		fw_spawn -= dt
		if fw_spawn <= 0.0:
			fw_spawn = fx_rng.randf_range(0.35, 0.7)
			var cols := [Color("ffd65a"), Color("f0484a"), Color("8ec5ff"), Color("8fe07a"), Color("fff3b0")]
			fw.append([sky_x + fx_rng.randf_range(-70, 70), g.view.hy - fx_rng.randf_range(22, 52), 0.0, cols[fx_rng.randi_range(0, cols.size() - 1)]])

func draw_sky(w: Node2D, hy: float) -> void:
	if N == 0 or g.segs.size() != N:
		return
	var far = g.segs[(int(g.pos / g.SEG) + 120) % N]
	sky_x = lerpf(sky_x, clampf(far.a_sx, 40.0, 344.0), 0.04)
	var t: Dictionary = towns[town_next] if town_next < towns.size() else {}
	if not t.is_empty():
		var d: float = (t.a - abs_c) / SEGS_KM
		if d < 3.0:
			_skyline(w, hy, t, clampf(1.0 - d / 3.0, 0.0, 1.0))
	for f in fw:
		var age: float = f[2]
		var r := 4.0 + 16.0 * sqrt(age / 1.5)
		var c: Color = f[3]
		c.a = clampf(1.0 - age / 1.5, 0.0, 1.0) * 0.9
		for k in 12:
			var an := k * TAU / 12.0
			w.draw_rect(Rect2(f[0] + cos(an) * r, f[1] + sin(an) * r + age * age * 6.0, 1.0, 1.0), c)

# the town grows on the hilltop as you get closer: roofs and a church in the dusk, lit windows at night
func _skyline(w: Node2D, hy: float, t: Dictionary, f: float) -> void:
	var lr := RandomNumberGenerator.new()
	lr.seed = t.a
	var hf: PackedFloat32Array = g.hill_f
	var base_y := hy + 2.0 - hf[int(sky_x + g.sky * 0.5) & 511] + 1.0
	var col: Color = g.e_hf.lerp(g.e_hor, 0.35 * (1.0 - f)).lerp(Color.BLACK, 0.12)
	col.a = clampf(f * 2.5, 0.0, 1.0)
	var night := clampf((0.62 - g.e_amb) * 4.0, 0.0, 1.0)
	var lit := Color(1.0, 0.84, 0.35, night * col.a)
	var sc := 0.45 + 0.75 * f
	var city: bool = road_id == "expressa"
	var n := 12 if city else 9
	var x := sky_x - (n * (7.0 if city else 5.0)) * sc / 2.0
	for k in n:
		var bw := (lr.randf_range(4, 9) if city else lr.randf_range(3, 6)) * sc
		var bh := (lr.randf_range(6, 26) if city else lr.randf_range(2, 5)) * sc
		if not city and k == n / 2:   # the church: a tower with a cross
			w.draw_rect(Rect2(x, base_y - 11.0 * sc, 3.0 * sc, 11.0 * sc), col)
			w.draw_rect(Rect2(x + 1.0 * sc, base_y - 13.5 * sc, 1.0 * sc, 2.5 * sc), col)
			w.draw_rect(Rect2(x + 3.0 * sc, base_y - 5.0 * sc, 5.0 * sc, 5.0 * sc), col)
			x += 8.0 * sc
			continue
		w.draw_rect(Rect2(x, base_y - bh, bw, bh), col)
		if night > 0.0:
			var wy := base_y - bh + 1.5
			while wy < base_y - 1.0:
				if lr.randf() < 0.45:
					w.draw_rect(Rect2(x + lr.randf_range(0.5, maxf(0.6, bw - 1.0)), wy, 0.5, 0.5), lit)
				wy += 2.5
		x += bw + lr.randf_range(0.0, 1.5) * sc

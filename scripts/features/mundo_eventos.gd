extends Node
# Ideia 11: rare roadside events. About one every three minutes, never the same twice in a row, each tied to a road
# and to the light: a herd of cattle walking down the dirt road, a cart, pilgrims, the pamonha van, a quermesse,
# a cyclist, a caramel mutt, a tyre shop, a funny LED panel, a balloon, a helicopter, parakeets, fireflies.
# Nothing blocks the way for long or asks for reflexes: what walks on the road is slow, and the cruise control and
# the autopilot already follow the vehicle ahead. Definitions and the discreet lines are in catalog.gd (EVENTOS).

const Cat = preload("res://scripts/catalog.gd")
const AHEAD := 26000.0   # spawn distance: just inside the drawn road (150 segments of 200)

var g
var rng := RandomNumberGenerator.new()   # own dice, so the game's random sequence stays the same
var auto_on := true      # the scheduler; tests start events by hand
var next_t := 0.0
var last_id := ""
var cur := ""            # the event happening now
var t := 0.0             # seconds since it started
var said := false
var e_cars: Array = []   # vehicles/animals the event added to g.cars
var e_spr: Array = []    # [segment index, sprite dict] it added to the roadside
var e_hidden: Array = [] # [segment index, sprite dict] it moved out of the way, put back at the end
var seg_i := -1          # where a roadside event stands
var close_t := -1.0      # seconds since the player caught up with the slow ones
var sky := {}            # balloon, helicopter, parakeets, fireflies
var _tex := {}

func _ready() -> void:
	g = get_parent()
	if Engine.has_meta("test_seed"):
		rng.seed = Engine.get_meta("test_seed")
		auto_on = Engine.has_meta("mundo_eventos")   # keep the regression runs free of surprises
	else:
		rng.randomize()
	g.setup_done.connect(_on_setup)
	g.trip_started.connect(func(): next_t = rng.randf_range(70.0, 120.0))

func _on_setup() -> void:
	# the track was rebuilt: whatever the event had placed is gone with it
	cur = ""
	e_cars.clear()
	e_spr.clear()
	e_hidden.clear()
	sky.clear()

func tx(n: String) -> Texture2D:
	if not _tex.has(n):
		_tex[n] = load("res://assets/sprites/%s.png" % n)
	return _tex[n]

func _light_ok(luz: String) -> bool:
	var td: float = g.tday
	var day := td < 1.1 or td >= 3.25
	var night := td > 1.55 and td < 2.95
	return luz == "" or (luz == "dia" and day) or (luz == "noite" and night)

func eligible() -> Array:
	var out: Array = []
	for id in Cat.EVENTOS:
		var e: Dictionary = Cat.EVENTOS[id]
		if id != last_id and e.roads.has(g.cfg.road) and _light_ok(e.luz):
			out.append(id)
	return out

func active() -> bool:
	return cur != ""

# how far ahead the event is (for tests and the discreet line)
func distance() -> float:
	if seg_i >= 0:
		return float(posmod(seg_i - int(g.pos / g.SEG), g.N)) * g.SEG
	var best := 1e9
	for c in e_cars:
		var d: float = fposmod(c.z - g.pos, g.TRACK)
		if d < g.TRACK - 3000.0:
			best = minf(best, d)
	return best if not e_cars.is_empty() else (0.0 if not sky.is_empty() else 1e9)

func _say() -> void:
	if said:
		return
	said = true
	if g.started:
		g.hud.notice(Cat.EVENTOS[cur].aviso, 5.0)
	g.feature_call("world_event", [cur])

func _process(dt: float) -> void:
	if g.state == "pause":
		return
	if cur == "":
		if auto_on and g.started and g.state == "drive":
			next_t -= dt
			if next_t <= 0.0:
				var ids := eligible()
				next_t = rng.randf_range(150.0, 230.0)
				if not ids.is_empty():
					start(ids[rng.randi() % ids.size()])
		return
	t += dt
	match cur:
		"boiada", "carroca", "ciclista", "romeiros", "pamonha", "carro_som":
			if seg_i >= 0:
				_tick_static()
			else:
				_tick_movers(dt)
		"cavalo", "caramelo", "quermesse", "borracharia", "led":
			_tick_static()
		_:
			_tick_sky(dt)

# ---------------------------------------------------------------- start

func start(id: String) -> void:
	if cur != "":
		_end()
	cur = id
	last_id = id
	t = 0.0
	said = false
	seg_i = -1
	close_t = -1.0
	var home: float = g.LANES[g.road.ours.back()]
	var shoulder: float = 1.32 if g.cfg.road == "terra" else 1.2   # clear of the lane even when the autopilot sidesteps a hole
	match id:
		"boiada":
			_make_room(AHEAD - 2000.0, AHEAD + 4000.0, home)
			var z0: float = g.pos + AHEAD
			_car(z0, home, 8.0, "peao")
			for k in 6:
				_car(z0 + 450.0 + k * 480.0, home, 8.0, "boiada%d" % (k % 2))
			_spr(int(g.pos / g.SEG) + 118, "placa_gado", 1.38, 1700.0, 4)
		"carroca":
			_car(g.pos + AHEAD, shoulder, 12.0, "carroca")
		"ciclista":
			_car(g.pos + AHEAD, shoulder, 20.0, "ciclista")
		"romeiros":
			_car(g.pos + AHEAD, shoulder + 0.05, 4.5, "romeiros")
			_car(g.pos + AHEAD + 900.0, shoulder + 0.08, 4.5, "romeiros")
		"pamonha":
			if g.cfg.road == "terra" and rng.randf() < 0.5:   # sometimes a stand by a gate instead of the van
				_place(["barraca_pamonha", 2.0, 1900.0, 0])
			else:
				_make_room(AHEAD - 2000.0, AHEAD + 2000.0, home)
				var c := _car(g.pos + AHEAD, home, 22.0 if g.cfg.road == "terra" else 30.0, "kombi_pamonha")
				c.seta = true
		"carro_som":
			_make_room(AHEAD - 2000.0, AHEAD + 2000.0, home)
			var c := _car(g.pos + AHEAD, home, 22.0 if g.cfg.road == "terra" else 30.0, "kombi_som")
			c.seta = true
		"cavalo":
			_place(["cavalo", rng.randf_range(1.5, 2.2), 1300.0, 0])
		"caramelo":
			_place(["caramelo", 1.3, 520.0, 0])
		"quermesse":
			_place(["quermesse", 2.9, 3600.0, 0])
		"borracharia":
			_place(["borracharia", 2.4, 2600.0, 0])
		"led":
			_place(["led_fun%d" % (rng.randi() % Cat.LED_RECADOS.size()), 2.2, 2600.0, 5])
		"balao":
			sky = {"x": rng.randf_range(80.0, 300.0) + g.sky * 0.3, "y": 70.0, "life": 70.0, "drift": rng.randf_range(-2.0, 2.0)}
		"helicoptero":
			sky = {"x": 430.0, "y": rng.randf_range(24.0, 40.0), "life": 26.0, "dir": -1.0}
		"periquitos":
			var birds: Array = []
			for i in 16:
				birds.append(Vector3(rng.randf_range(-30.0, 0.0) - i * 3.0, rng.randf_range(-8.0, 8.0), rng.randf() * TAU))
			sky = {"x": -20.0, "y": rng.randf_range(26.0, 44.0), "life": 16.0, "birds": birds}
		"vagalumes":
			var flies: Array = []
			for i in 34:
				flies.append(Vector3(rng.randf_range(0.0, 384.0), rng.randf_range(8.0, 70.0), rng.randf() * TAU))
			sky = {"life": 45.0, "flies": flies}
	if not sky.is_empty():
		_say()

func _car(z: float, x: float, v: float, tex: String) -> Dictionary:
	var c := {"z": fposmod(z, g.TRACK), "x": x, "v": v, "tex": tx(tex), "dir": 1, "evento": cur}
	g.cars.append(c)
	e_cars.append(c)
	return c

# no other car may sit inside the stretch where the slow ones appear
func _make_room(d0: float, d1: float, x: float) -> void:
	for c in g.cars:
		if c.dir > 0 and absf(c.x - x) < 0.3 and not c.has("evento"):
			var d: float = fposmod(c.z - g.pos, g.TRACK)
			if d > d0 and d < d1:
				c.z = fposmod(g.pos + d1 + 800.0 + (d - d0) * 0.3, g.TRACK)

func _spr(i: int, n: String, off: float, ww: float, kind: int) -> Dictionary:
	i = posmod(i, g.N)
	var q := {"tex": tx(n) if not g.tex.has(n) else g.tex[n], "off": off, "ww": ww, "kind": kind, "name": n, "evento": true}
	g.segs[i].spr.append(q)
	e_spr.append([i, q])
	return q

func _place(p: Array) -> void:
	seg_i = posmod(int(g.pos / g.SEG) + 140, g.N)
	for d in range(-4, 5):   # clear the roadside it stands on (put back afterwards)
		var j := posmod(seg_i + d, g.N)
		for q in g.segs[j].spr.duplicate():
			if q.off > 1.2 and q.kind != 1 and q.kind != 3 and not q.has("evento"):
				g.segs[j].spr.erase(q)
				e_hidden.append([j, q])
	var q := _spr(seg_i, p[0], p[1], p[2], p[3])
	if p[0] == "quermesse":
		q.draw = _draw_bulbs

# ---------------------------------------------------------------- run

func _tick_static() -> void:
	var d := distance()
	if d < 11000.0:
		_say()
	var behind := posmod(int(g.pos / g.SEG) - seg_i, g.N)
	if (behind > 3 and behind < g.N / 2) or t > 150.0:
		_end()

func _tick_movers(dt: float) -> void:
	var near := 1e9
	var gone := true
	for c in e_cars:
		var d: float = fposmod(c.z - g.pos, g.TRACK)
		if d < g.TRACK - 3000.0:
			near = minf(near, d)
			gone = false
	if near < 9000.0:
		_say()
	if close_t < 0.0 and near < 3500.0:
		close_t = 0.0
	if close_t >= 0.0:
		close_t += dt
	# the herd turns off into a pasture after ~20 s with you behind it; the van turns off after a while too
	var leave_after := 20.0 if cur == "boiada" else 60.0
	var leaving := (close_t > leave_after and cur in ["boiada", "pamonha", "carro_som"]) or t > 140.0
	for c in e_cars.duplicate():
		if leaving and not cur in ["carroca", "ciclista", "romeiros"]:
			c.x = minf(2.2, c.x + dt * 0.35)
			c.v = maxf(c.v, 6.0)
		if c.x >= 2.15 or (leaving and cur in ["carroca", "ciclista", "romeiros"]):
			_drop_car(c)
	if gone or e_cars.is_empty():
		_end()

func _drop_car(c: Dictionary) -> void:
	g.cars.erase(c)
	e_cars.erase(c)

func _tick_sky(dt: float) -> void:
	sky.life -= dt
	match cur:
		"balao":
			sky.y = maxf(8.0, sky.y - dt * 1.1)
			sky.x += sky.drift * dt
		"helicoptero":
			sky.x += sky.dir * dt * 19.0
		"periquitos":
			sky.x += dt * 34.0
	if sky.life <= 0.0:
		_end()

func _end() -> void:
	for c in e_cars:
		g.cars.erase(c)
	for p in e_spr:
		g.segs[p[0]].spr.erase(p[1])
	for p in e_hidden:
		g.segs[p[0]].spr.append(p[1])
	e_cars.clear()
	e_spr.clear()
	e_hidden.clear()
	sky.clear()
	seg_i = -1
	cur = ""

# ---------------------------------------------------------------- draw

func _draw_bulbs(w: Node2D, q: Dictionary, r: Rect2, alpha: float) -> void:   # quermesse lights along the flags
	var night := clampf((0.95 - g.e_amb) * 2.0, 0.0, 1.0)
	if night <= 0.05 or r.size.x < 30.0:
		return
	var cols := [Color(1.0, 0.85, 0.4), Color(1.0, 0.4, 0.35), Color(0.5, 0.85, 1.0), Color(0.6, 1.0, 0.5)]
	for i in 15:
		var u := (i + 0.5) / 15.0
		var x := r.position.x + r.size.x * (0.04 + 0.92 * u)
		var y := r.position.y + r.size.y * (0.2 + sin(u * PI) * 0.15)
		var on := 0.6 + 0.4 * sin(g.t * 2.0 + i * 1.7)
		var c: Color = cols[i % cols.size()]
		w._glow(x, y, maxf(2.0, r.size.x * 0.03), c, 0.6 * night * alpha * on)
		w.draw_rect(Rect2(x - 0.5, y - 0.5, 1.0, 1.0), Color(c.r, c.g, c.b, alpha * night))

func draw_sky(w: Node2D, hy: float) -> void:
	if sky.is_empty():
		return
	match cur:
		"balao":
			var x := fposmod(sky.x - g.sky * 0.3, 520.0) - 60.0
			var a := clampf(sky.life / 6.0, 0.0, 1.0) * clampf((70.0 - sky.life) / 4.0, 0.0, 1.0)
			w.draw_texture_rect(tx("balao"), Rect2(roundf(x), roundf(sky.y), 12.0, 17.0), false, Color(1, 1, 1, a))
		"helicoptero":
			var x: float = sky.x - fposmod(g.sky * 0.3, 1.0)
			var y: float = sky.y + sin(g.t * 1.3) * 1.5
			w.draw_texture_rect(tx("helicoptero"), Rect2(roundf(x), roundf(y), 20.0, 9.0), false)
			var blade := 9.0 if int(g.t * 20.0) % 2 == 0 else 5.0   # the rotor flickering
			w.draw_rect(Rect2(x + 10.0 - blade, y, blade * 2.0, 0.5), Color(0.1, 0.1, 0.12, 0.8))
		"periquitos":
			var col := Color(0.35, 0.78, 0.3) if g.e_amb > 0.7 else Color(0.08, 0.1, 0.1)   # green by day, silhouettes at dusk
			for b in sky.birds:
				var bx: float = sky.x + b.x
				var by: float = sky.y + b.y + sin(g.t * 2.0 + b.z) * 2.0
				var flap := 1.0 if sin(g.t * 16.0 + b.z) > 0.0 else -0.5
				w.draw_rect(Rect2(bx, by, 1.0, 1.0), col)
				w.draw_rect(Rect2(bx - 1.5, by - flap, 1.5, 0.5), col)
				w.draw_rect(Rect2(bx + 1.0, by - flap, 1.5, 0.5), col)

func draw_world_over(w: Node2D) -> void:
	if cur != "vagalumes" or sky.is_empty():
		return
	var hy: float = g.view.hy
	var a := clampf(sky.life / 6.0, 0.0, 1.0) * clampf((45.0 - sky.life) / 4.0, 0.0, 1.0)
	for f in sky.flies:
		var x: float = fposmod(f.x - g.sky * 0.6 + sin(g.t * 0.5 + f.z) * 6.0, 384.0)
		if absf(x - 192.0) < 40.0 + f.y * 1.2:   # over the grass, not the road
			continue
		var on := sin(g.t * 1.8 + f.z * 3.0)
		if on < 0.2:
			continue
		var y: float = hy + 2.0 + f.y + sin(g.t * 0.8 + f.z) * 2.0
		w._glow(x, y, 5.0, Color(0.85, 1.0, 0.3), 0.8 * on * a)
		w.draw_rect(Rect2(x - 0.5, y - 0.5, 1.0, 1.0), Color(1.0, 1.0, 0.6, on * a))

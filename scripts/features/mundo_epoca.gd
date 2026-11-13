extends Node
# Ideia 14: a real calendar. The game reads the system date: summer showers in January, festa junina in June and
# July (bandeirinhas across the road, bonfires, balloons), flowering ipês in August and September, Christmas lights
# in December. Any season can be picked all year long in the main menu (ÉPOCA): no "you missed it".

const Cat = preload("res://scripts/catalog.gd")
const LIGHTS := [Color(1.0, 0.3, 0.3), Color(1.0, 0.85, 0.3), Color(0.4, 1.0, 0.45), Color(0.45, 0.7, 1.0), Color(1.0, 0.55, 0.95)]
# roof lines (fractions of the sprite) where the pisca-pisca hangs
const ROOFS := {
	"casa_sitio": [Vector2(0.04, 0.41), Vector2(0.5, 0.1), Vector2(0.96, 0.41)],
	"capela": [Vector2(0.04, 0.45), Vector2(0.5, 0.29), Vector2(0.96, 0.45), Vector2(0.68, 0.09), Vector2(0.5, 0.0), Vector2(0.32, 0.09)],
	"venda": [Vector2(0.0, 0.28), Vector2(1.0, 0.28)],
	"posto": [Vector2(0.05, 0.14), Vector2(0.95, 0.14)],
	"parada": [Vector2(0.32, 0.31), Vector2(0.98, 0.31)],
}

var g
var rng := RandomNumberGenerator.new()
var pick := "hoje"     # what the player chose in the menu
var now := ""          # the season in effect: "" | verao | junina | ipes | natal
var sel := 0
var balloons: Array = []

func _ready() -> void:
	g = get_parent()
	if Engine.has_meta("test_seed"):
		pick = Engine.get_meta("mundo_epoca", "nenhuma")   # regression runs stay as they were
	else:
		pick = g.store_get("mundo", "epoca", "hoje")
		if not Cat.EPOCA_IDS.has(pick):
			pick = "hoje"
	_resolve()
	g.setup_done.connect(_decorate)
	g.trip_started.connect(_hello)
	g.menu.add_main_item("ÉPOCA", open)

static func from_month(m: int) -> String:
	for id in Cat.EPOCAS:
		if Cat.EPOCAS[id].get("months", []).has(m):
			return id
	return ""

func _resolve() -> void:
	if pick == "hoje":
		now = from_month(int(Time.get_date_dict_from_system().month))
	elif pick == "nenhuma":
		now = ""
	else:
		now = pick
	g.showers = now == "verao"   # read by game.setup(): summer showers even on a sunny trip

func _hello() -> void:
	var msg: String = {"verao": "JANEIRO: TARDE DE VERÃO, PANCADA DE CHUVA A QUALQUER HORA",
		"junina": "TEMPO DE FESTA JUNINA: BANDEIRINHA, FOGUEIRA E QUENTÃO",
		"ipes": "OS IPÊS ESTÃO FLORIDOS NA BEIRA DA ESTRADA",
		"natal": "DEZEMBRO: PISCA-PISCA NAS CASAS E NOS POSTES"}.get(now, "")
	if msg != "":
		g.hud.notice(msg, 5.0)

# ---------------------------------------------------------------- the world for the season

func _decorate() -> void:
	rng.seed = 4242 + g.N
	balloons.clear()
	match now:
		"ipes":
			var kinds := ["ipe_amarelo", "ipe_amarelo", "ipe_roxo", "ipe_roxo", "ipe_branco", "ipe_rosa"]
			var p := 0.55 if g.cfg.road == "terra" else 0.35
			for s in g.segs:
				for q in s.spr:
					if q.name in ["tree0", "tree1", "ipe", "bambu"] and rng.randf() < p:
						q.tex = _tx(kinds[rng.randi() % kinds.size()])
		"junina":
			for i in _spots():
				_add(i - 8, "bandeirinhas", 0.0, g.ROADW / 2000.0 * 4600.0, 0)
				var f := _add(i + 4, "fogueira", 1.9 if g.cfg.road == "terra" else 2.3, 650.0, 0)
				f.draw = _fire
			for i in 7:
				balloons.append(Vector3(rng.randf_range(0.0, 520.0), rng.randf_range(10.0, 50.0), rng.randf() * TAU))
		"natal":
			for s in g.segs:
				for q in s.spr:
					if ROOFS.has(q.name):
						q.draw = _xmas_roof
					elif q.kind == 1 or q.name == "lamp" or q.name == "luminaria":
						q.draw = _xmas_pole
			for i in _spots():
				var tr := _add(i + 6, "arvore_natal", 1.75 if g.cfg.road == "terra" else 2.2, 900.0, 0)
				tr.draw = _xmas_tree

func _spots() -> Array:   # houses, chapel and stops: where the party is
	var out: Array = g.postos.duplicate()
	if g.cfg.road == "terra":
		for s in g.segs:
			for q in s.spr:
				if q.name == "casa_sitio" or q.name == "capela":
					out.append(s.i)
	else:
		for k in 3:
			out.append(int(g.N * (0.12 + k * 0.3)))
	return out

func _tx(n: String) -> Texture2D:
	return load("res://assets/sprites/%s.png" % n)

func _add(i: int, n: String, off: float, ww: float, kind: int) -> Dictionary:
	var q := {"tex": _tx(n), "off": off, "ww": ww, "kind": kind, "name": n}
	g.segs[posmod(i, g.N)].spr.append(q)
	return q

func _night() -> float:
	return clampf((1.0 - g.e_amb) * 2.2, 0.15, 1.0)

func _bulb(w: Node2D, p: Vector2, c: Color, sz: float, a: float, glow: float) -> void:
	w.draw_rect(Rect2(p.x - sz * 0.5, p.y - sz * 0.5, sz, sz), Color(c.r, c.g, c.b, a))
	if glow > 0.05:
		w._glow(p.x, p.y, sz * 3.5 + 1.0, c, glow)

func _xmas_roof(w: Node2D, q: Dictionary, r: Rect2, alpha: float) -> void:
	if r.size.x < 14.0:
		return
	var pts: Array = ROOFS[q.name]
	var nt := _night()
	var sz := clampf(r.size.x / 70.0, 0.5, 2.0)
	var k := 0
	for j in pts.size() - 1:
		var a: Vector2 = r.position + r.size * pts[j]
		var b: Vector2 = r.position + r.size * pts[j + 1]
		var n := maxi(2, int(a.distance_to(b) / (sz * 3.5)))
		for m in n:
			var u := (m + 0.5) / n
			var p := a.lerp(b, u) + Vector2(0, sin(u * PI) * sz * 1.5)
			var on := fmod(g.t * 1.5 + k * 0.37, 1.0) < 0.7
			if on:
				_bulb(w, p, LIGHTS[k % LIGHTS.size()], sz, alpha, 0.5 * nt * alpha)
			k += 1

func _xmas_pole(w: Node2D, q: Dictionary, r: Rect2, alpha: float) -> void:
	if r.size.y < 20.0:
		return
	var nt := _night()
	var sz := clampf(r.size.y / 90.0, 0.5, 1.5)
	var cx := r.position.x + r.size.x * 0.5
	for i in 7:
		var u := i / 7.0
		var p := Vector2(cx + sin(u * TAU * 2.0) * r.size.x * 0.06, r.position.y + r.size.y * (0.14 + u * 0.4))
		if fmod(g.t * 2.0 + i * 0.29, 1.0) < 0.65:
			_bulb(w, p, LIGHTS[i % LIGHTS.size()], sz, alpha, 0.45 * nt * alpha)

func _xmas_tree(w: Node2D, q: Dictionary, r: Rect2, alpha: float) -> void:
	var nt := _night()
	for i in 10:
		var p := r.position + r.size * Vector2(0.2 + fmod(i * 0.37, 0.6), 0.25 + fmod(i * 0.53, 0.5))
		if fmod(g.t * 1.2 + i * 0.41, 1.0) < 0.6:
			_bulb(w, p, LIGHTS[i % LIGHTS.size()], maxf(0.5, r.size.x / 40.0), alpha, 0.4 * nt * alpha)

func _fire(w: Node2D, q: Dictionary, r: Rect2, alpha: float) -> void:
	var fl := 0.8 + 0.2 * sin(g.t * 13.0) * sin(g.t * 7.3)
	var nt := _night()
	w._glow(r.position.x + r.size.x * 0.5, r.position.y + r.size.y * 0.55, r.size.x * (1.2 + nt * 1.4) * fl, Color(1.0, 0.55, 0.15), (0.35 + 0.45 * nt) * alpha)

func draw_sky(w: Node2D, hy: float) -> void:
	if now != "junina":
		return
	var nt := clampf((0.95 - g.e_amb) * 2.0, 0.0, 1.0)
	for b in balloons:   # small paper balloons, glowing from the inside after dark
		var x := fposmod(b.x - g.sky * 0.3 + sin(g.t * 0.2 + b.z) * 4.0, 520.0) - 60.0
		var y := fposmod(b.y - g.t * 0.6, 60.0) + 6.0
		if y > hy - 4.0:
			continue
		var c := Color(1.0, 0.45 + 0.3 * sin(b.z), 0.2)
		w.draw_colored_polygon(PackedVector2Array([Vector2(x - 1.5, y), Vector2(x + 1.5, y), Vector2(x + 1.0, y + 3.0), Vector2(x - 1.0, y + 3.0)]), Color(c.r, c.g, c.b, 0.9))
		w.draw_rect(Rect2(x - 0.5, y + 3.0, 1.0, 0.5), Color(1.0, 0.9, 0.4))
		if nt > 0.05:
			w._glow(x, y + 2.0, 5.0, c, 0.5 * nt)

# ---------------------------------------------------------------- menu: ÉPOCA

func open() -> void:
	sel = Cat.EPOCA_IDS.find(pick)
	_show()

func _show() -> void:
	g.menu.open_screen("ÉPOCA DO ANO", _build, _key)

func _build(body: Control) -> void:
	var d := Time.get_date_dict_from_system()
	var today := from_month(int(d.month))
	var tname: String = Cat.EPOCAS[today].name if today != "" else "SEM FESTA NO CALENDÁRIO"
	g.menu.label("HOJE É %02d/%02d: %s" % [d.day, d.month, tname], 8, Color("8fa3bf"), Vector2(0, 0), body)
	for i in Cat.EPOCA_IDS.size():
		var id: String = Cat.EPOCA_IDS[i]
		var on := i == sel
		var y := 22.0 + i * 40.0
		if on:
			g.menu.box(Rect2(-8, y - 4, 4, 32), Color("ffd65a"), body)
		g.menu.label(("> " if on else "  ") + Cat.EPOCAS[id].name + ("   (ESCOLHIDA)" if id == pick else ""), 16, Color("ffd65a") if on else Color("e6e8ee"), Vector2(0, y), body)
		g.menu.label("    " + Cat.EPOCAS[id].desc, 8, Color("8fa3bf"), Vector2(0, y + 20), body)
	g.menu.label("SETAS ESCOLHEM  ENTER APLICA  ESC VOLTA", 8, Color("8fa3bf"), Vector2(0, 318), body)

func _key(k: int) -> void:
	match k:
		KEY_UP, KEY_W:
			sel = (sel + Cat.EPOCA_IDS.size() - 1) % Cat.EPOCA_IDS.size()
			_show()
		KEY_DOWN, KEY_S:
			sel = (sel + 1) % Cat.EPOCA_IDS.size()
			_show()
		KEY_ENTER, KEY_KP_ENTER, KEY_SPACE:
			pick = Cat.EPOCA_IDS[sel]
			g.store_set("mundo", "epoca", pick)
			g.store_save()
			_resolve()
			if not g.started:
				g.setup()   # rebuild the preview trip with the season's look
			g.menu.close_screen()

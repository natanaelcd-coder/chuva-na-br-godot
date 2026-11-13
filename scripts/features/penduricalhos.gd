extends Node
# Ideia 7: penduricalhos e santinhos ganhos com km e figurinhas. Prêmios para o retrovisor e o painel, que balançam com
# a mesma física dos atuais (g.dice, g.bob). Tela "CABINE" para escolher, por carro, até 2 pendurados e 1 no painel.
# Os quatro originais (terço, dados, fitas, pinheirinho) e o cachorrinho ficam livres para todos os carros.
# Gravado em [cabine] (escolha por carro) e [penduricalhos] (o que já foi ganho).

const Cat = preload("res://scripts/catalog.gd")
const HANG_IDS := ["rosary", "dice", "ribbons", "pine", "cristovao", "bonfim", "urso", "figa", "cd", "flamula"]
const DASH_IDS := ["", "dog", "flor", "aparecida"]
const BUILTIN := ["rosary", "dice", "ribbons", "pine"]   # drawn by cockpit.gd itself
# km: total km of all cars; fig: stickers in the caderneta
const ITEMS := {
	"rosary": {"name": "TERÇO DE MADEIRA", "desc": "DE CONTA EM CONTA, A VIAGEM PASSA."},
	"dice": {"name": "DADOS DE PELÚCIA", "desc": "SORTE PARA A ESTRADA."},
	"ribbons": {"name": "FITAS DA QUERMESSE", "desc": "UMA PARA CADA PEDIDO."},
	"pine": {"name": "PINHEIRINHO", "desc": "CHEIRO DE CARRO NOVO. JÁ FOI."},
	"cristovao": {"name": "SÃO CRISTÓVÃO", "desc": "SANTINHO DO PADROEIRO DOS MOTORISTAS.", "km": 10},
	"bonfim": {"name": "FITA DO BONFIM", "desc": "TRÊS NÓS, TRÊS PEDIDOS.", "fig": 6},
	"urso": {"name": "URSINHO DE PELÚCIA", "desc": "CHAVEIRO GANHO NA PESCARIA DA FESTA.", "km": 30},
	"figa": {"name": "FIGA DE MADEIRA", "desc": "CONTRA MAU-OLHADO E PNEU FURADO.", "fig": 15},
	"cd": {"name": "CD VELHO", "desc": "DIZEM QUE ENGANA O RADAR. NÃO ENGANA.", "km": 60},
	"flamula": {"name": "FLÂMULA DO TIME", "desc": "E.C. ESTRADA, CAMPEÃO DE 1974.", "fig": 25},
	"": {"name": "NADA NO PAINEL", "desc": "PAINEL LIMPO, VISTA LIVRE."},
	"dog": {"name": "CACHORRINHO", "desc": "BALANÇA A CABEÇA E CONCORDA COM TUDO."},
	"flor": {"name": "FLOR DE PLÁSTICO", "desc": "NUNCA PRECISA REGAR.", "fig": 10},
	"aparecida": {"name": "NOSSA SENHORA", "desc": "APARECIDA, PROTETORA DE QUEM VIAJA.", "km": 45},
}
const DEFAULTS := {"besouro": {"hang": ["rosary", "dice"], "dash": "dog"}, "picape": {"hang": ["ribbons"], "dash": ""}, "gt": {"hang": ["pine"], "dash": ""}}
const DASH_AT := {"besouro": Vector2(239.5, 106.0), "picape": Vector2(236.0, 119.0), "gt": Vector2(255.0, 117.0)}   # bottom centre on the dash
const SPOTS := [-12.0, 12.0, 0.0]   # where along the mirror a new item hangs
const AMBER := Color("f2a62a")
const LINE := Color("9bbbe0")
const INK := Color("e6e8ee")
const DIM := Color("6f86a8")
const CROP := Rect2(150, 0, 130, 125)   # the part of the cabin the preview shows, in logical units

var g
var _check_t := 1.0
var _offs := {}            # new hanging item -> x offset on the mirror (current car)
var _base := Transform2D.IDENTITY
var body: Control
var edit_car := "besouro"
var row := 0

class Preview extends Control:
	var owner_f
	var t := 0.0
	func _process(dt: float) -> void:
		t += dt
		queue_redraw()
	func _draw() -> void:
		owner_f.draw_preview(self, t)

func _ready() -> void:
	g = get_parent()
	g.setup_done.connect(apply)
	g.menu.add_main_item("CABINE", open)
	g.menu.add_pause_item("CABINE", open)

# --- what is chosen and what is earned
func choice(car: String) -> Dictionary:
	var d = g.store_get("cabine", car, {})
	if not (d is Dictionary) or not d.has("hang"):
		d = DEFAULTS[car].duplicate(true)
	return d

func _set_choice(car: String, d: Dictionary) -> void:
	g.store_set("cabine", car, d)
	g.store_save()
	if car == g.cfg.car:
		apply()

func _km() -> float:
	var h = g.get_node_or_null("hodometro")
	if h != null and h.has_method("total_km"):
		return h.total_km()
	return 0.0

func _figs() -> int:
	var c = g.get_node_or_null("caderneta")
	if c != null and c.has_method("count"):
		return c.count()[0]
	return 0

func unlocked(id: String) -> bool:
	var it: Dictionary = ITEMS[id]
	return (not it.has("km") or _km() >= it.km) and (not it.has("fig") or _figs() >= it.fig)

func _need(id: String) -> String:   # "FALTAM 12 KM" or ""
	var it: Dictionary = ITEMS[id]
	if it.has("km") and _km() < it.km:
		return "FALTAM %d KM" % maxi(1, ceili(it.km - _km()))
	if it.has("fig") and _figs() < it.fig:
		var n: int = it.fig - _figs()
		return "FALTAM %d FIGURINHA%s" % [n, "S" if n > 1 else ""]
	return ""

# hand the cockpit the car's own items that stay, and work out where the new ones hang
func apply() -> void:
	var ck = g.get_node_or_null("Cockpit")
	if ck == null:
		return
	var d := choice(g.cfg.car)
	var keep: Array = []
	var taken: Array = []
	for id in d.hang:
		if BUILTIN.has(id):
			keep.append(id)
			taken.append(12.0 if id == "dice" else 0.0)
	_offs.clear()
	for id in d.hang:
		if not BUILTIN.has(id):
			for s in SPOTS:
				if not taken.has(s):
					_offs[id] = s
					taken.append(s)
					break
	ck.hang_items = keep
	var at: Vector2 = DASH_AT[g.cfg.car]
	ck.dog_at = [at.x - 6.5, at.y - 11.0] if d.dash == "dog" else []

func _process(dt: float) -> void:
	if g == null or not (g.started and g.state == "drive"):
		return
	_check_t -= dt
	if _check_t > 0.0:
		return
	_check_t = 1.0
	var got: Array = g.store_get("penduricalhos", "ganhos", [])
	for id in ITEMS.keys():
		if id == "" or got.has(id) or not (ITEMS[id].has("km") or ITEMS[id].has("fig")) or not unlocked(id):
			continue
		got.append(id)
		g.store_set("penduricalhos", "ganhos", got)
		var d := choice(g.cfg.car)   # a new prize goes straight up in this car; the CABINE screen changes it back
		if HANG_IDS.has(id):
			if d.hang.size() < 2:
				d.hang.append(id)
			else:
				d.hang[1] = id
			g.hud.notice("PRÊMIO: %s NO RETROVISOR  (TROQUE EM CABINE)" % ITEMS[id].name, 6.0)
		else:
			if d.dash == "":
				d.dash = id
				g.hud.notice("PRÊMIO: %s NO PAINEL  (TROQUE EM CABINE)" % ITEMS[id].name, 6.0)
			else:
				g.hud.notice("PRÊMIO: %s  (PONHA NO PAINEL EM CABINE)" % ITEMS[id].name, 6.0)
		_set_choice(g.cfg.car, d)

# --- cockpit hooks
func draw_hang(c, anchor: Vector2) -> void:
	_base = Transform2D.IDENTITY
	var d := choice(g.cfg.car)
	var k := 0
	for id in d.hang:
		if not BUILTIN.has(id):
			_hang(c, id, anchor + Vector2(_offs.get(id, 0.0), 0.0), g.dice * (0.9 + k * 0.15), g.t)
			k += 1
	c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func draw_cabin_mid(c) -> void:
	var d := choice(g.cfg.car)
	if d.dash != "" and d.dash != "dog":
		_base = Transform2D.IDENTITY
		_dash(c, d.dash, DASH_AT[g.cfg.car], g.bob, g.t)
		c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

# --- drawing (logical units; _base scales it up for the CABINE preview)
func _xf(c, xf := Transform2D.IDENTITY) -> void:
	c.draw_set_transform_matrix(_base * xf)

func _r(c, col: String, x: float, y: float, w: float, h: float) -> void:
	c.draw_rect(Rect2(x, y, w, h), Color(col))

func _hang(c, id: String, p: Vector2, a: float, t: float) -> void:
	match id:
		"rosary", "dice", "ribbons", "pine":
			_builtin(c, id, p, a, t)
			return
	var fr := Transform2D(-a, p).scaled_local(Vector2(1.7, 1.7))   # the string hangs along +y; swinging rotates the whole frame
	_xf(c, fr)
	match id:
		"cristovao":   # laminated holy card on a white thread
			c.draw_line(Vector2.ZERO, Vector2(0, 18), Color("e6e8ee"), 0.5)
			_xf(c, fr * Transform2D(a * 0.5, Vector2(0, 18)))
			_r(c, "f0e6c8", -3, 0, 6, 9)
			_r(c, "6f97c4", -2, 1, 4, 7)
			_r(c, "ffd65a", -1, 1.5, 2.5, 0.5)
			_r(c, "e3ab7c", -0.5, 2, 1.5, 1.5)
			_r(c, "c22630", -1.5, 3.5, 3, 4.5)
			_r(c, "e3ab7c", -1.5, 2.5, 1, 1)
			_r(c, "6e4526", 1.5, 2.5, 0.5, 5.5)
			_r(c, "3fae5a", -2, 7.5, 4, 0.5)
		"bonfim":      # two long wish ribbons with their white lettering
			var cols := ["6fc3e8", "ffd65a"]
			for k in 2:
				var len := 36.0 - k * 5.0
				var pts := PackedVector2Array()
				for j in 9:
					var f := j / 8.0
					pts.append(Vector2((k - 0.5) * 1.6 + sin(t * 2.6 + k * 1.7 + f * 4.0) * 1.2 * f, f * len))
				c.draw_polyline(pts, Color(cols[k]), 1.5)
				for j in range(2, 8, 2):
					c.draw_rect(Rect2(pts[j].x - 0.25, pts[j].y, 0.5, 0.5), Color("f6f6f6"))
			_r(c, "c22630", -1.5, 0, 3, 1.5)
		"urso":        # little teddy-bear key ring
			c.draw_line(Vector2.ZERO, Vector2(0, 8), Color("a8acb5"), 0.5)
			c.draw_arc(Vector2(0, 8.5), 1.0, 0.0, TAU, 8, Color("a8acb5"), 0.5)
			c.draw_circle(Vector2(-2.5, 10), 1.2, Color("6e4526"))
			c.draw_circle(Vector2(2.5, 10), 1.2, Color("6e4526"))
			c.draw_circle(Vector2(0, 12.5), 3.0, Color("96643a"))
			c.draw_circle(Vector2(0, 18.5), 3.5, Color("96643a"))
			c.draw_circle(Vector2(0, 19), 2.0, Color("c68a5a"))
			_r(c, "e3ab7c", -1, 13, 2, 1.5)
			_r(c, "0a0a0f", -1.5, 11.5, 0.5, 0.5)
			_r(c, "0a0a0f", 1, 11.5, 0.5, 0.5)
			_r(c, "0a0a0f", -0.25, 13, 0.5, 0.5)
			_r(c, "96643a", -4.5, 16, 1.5, 3)
			_r(c, "96643a", 3, 16, 1.5, 3)
			_r(c, "6e4526", -2.5, 21.5, 2, 1.5)
			_r(c, "6e4526", 0.5, 21.5, 2, 1.5)
			_r(c, "c22630", -1.5, 15, 3, 0.5)
		"figa":        # carved wooden fist on a leather cord, red bow on top
			c.draw_line(Vector2.ZERO, Vector2(0, 13), Color("c68a5a"), 0.5)
			_r(c, "c22630", -1.5, 12.5, 3, 1)
			_r(c, "8a5a2a", -2, 14, 4, 5)
			_r(c, "a06a3a", -2, 14, 1, 5)
			_r(c, "c68a5a", -0.25, 13.5, 1, 2.5)
			_r(c, "6e4526", -1.5, 19, 3, 3.5)
			_r(c, "5a3820", -1.5, 21.5, 3, 1)
		"cd":          # an old CD spinning on its thread, flashing the sky back
			c.draw_line(Vector2.ZERO, Vector2(0, 16), Color("e6e8ee"), 0.5)
			var spin := t * 1.7
			var sx := maxf(0.12, absf(cos(spin)))
			_xf(c, fr * Transform2D(0.0, Vector2(sx, 1.0), 0.0, Vector2(0, 22)))
			c.draw_circle(Vector2.ZERO, 6.0, Color("c8ccd4"))
			var glint := Color.from_hsv(fposmod(spin * 0.25, 1.0), 0.5, 1.0)
			c.draw_arc(Vector2.ZERO, 4.0, -1.2, 0.4, 8, glint, 1.0)
			c.draw_arc(Vector2.ZERO, 4.5, 2.0, 3.2, 8, Color("8fd0e8"), 0.5)
			c.draw_circle(Vector2.ZERO, 1.6, Color("e6e8ee"))
			c.draw_circle(Vector2.ZERO, 0.8, Color("16202b"))
		"flamula":     # the club pennant
			_r(c, "6e4526", -6.5, 2, 13, 1)
			c.draw_line(Vector2(0, 0), Vector2(0, 2), Color("e6e8ee"), 0.5)
			c.draw_colored_polygon(PackedVector2Array([Vector2(-6, 3), Vector2(6, 3), Vector2(0, 21)]), Color("c22630"))
			c.draw_colored_polygon(PackedVector2Array([Vector2(-6, 3), Vector2(6, 3), Vector2(5.3, 5), Vector2(-5.3, 5)]), Color("e6e8ee"))
			c.draw_circle(Vector2(0, 9), 2.0, Color("ffd65a"))
			_r(c, "c22630", -0.5, 8.5, 1, 1)
			_r(c, "ffd65a", -0.5, 21, 1, 3)
	_xf(c)

# the cockpit's own four, redrawn here only for the preview
func _builtin(c, id: String, p: Vector2, dice: float, t: float) -> void:
	var ax := p.x
	var ay := p.y
	_xf(c)
	match id:
		"rosary":
			for i in range(1, 10):
				var l := i * 6.0
				var a := dice * (0.6 + i * 0.04)
				_r(c, "6e4526" if i % 3 else "c68a5a", roundf(ax - 2.0 + sin(a) * l), roundf(ay + cos(a) * l), 2, 2)
			var rx := roundf(ax - 2.0 + sin(dice * 0.96) * 60.0)
			var ry := roundf(ay + cos(dice * 0.96) * 60.0)
			_r(c, "ffd65a", rx, ry, 2, 7)
			_r(c, "ffd65a", rx - 2, ry + 2, 6, 2)
			_r(c, "c47a1c", rx - 1, ry + 8, 4, 6)
		"dice":
			var die := [[8.0, 66.0, 0.15, [[-3, -3], [3, 3], [-3, 3], [3, -3]]], [15.0, 72.0, -0.2, [[-3, -3], [3, 3], [0, 0]]]]
			for k in 2:
				var d: Array = die[k]
				var a := dice * (1.05 + k * 0.1)
				var q := Vector2(ax + d[0] + sin(a) * d[1], ay + cos(a) * d[1])
				c.draw_line(Vector2(ax + 1.0, ay), q, Color("e6e8ee"), 0.5)
				_xf(c, Transform2D(d[2] - a * 0.6, q + Vector2(0, 5)))
				_r(c, "c22630", -6, -6, 12, 12)
				_r(c, "f0484a", -6, -6, 12, 2)
				_r(c, "7a1620", -6, 4, 12, 2)
				for pip in d[3]:
					_r(c, "e6e8ee", pip[0] - 1, pip[1] - 1, 2, 2)
				_xf(c)
		"ribbons":
			var cols := ["c22630", "ffd65a", "3fae5a", "3d5f94", "e6e8ee", "f2a62a"]
			for k in cols.size():
				var a := dice * (1.0 + k * 0.08) + (k - 2.5) * 0.06
				var len := 30.0 + (k % 3) * 6.0
				var p0 := Vector2(ax + (k - 2.5) * 1.2, ay)
				var p1 := p0 + Vector2(sin(a) * len * 0.5 + sin(t * 3.0 + k) * 0.6, len * 0.5)
				var p2 := p0 + Vector2(sin(a * 1.2) * len, len)
				c.draw_polyline(PackedVector2Array([p0, p1, p2]), Color(cols[k]), 1.0)
		"pine":
			var q := Vector2(ax + sin(dice) * 34.0, ay + cos(dice) * 34.0)
			c.draw_line(Vector2(ax, ay), q, Color("e6e8ee"), 0.5)
			_xf(c, Transform2D(-dice * 0.8, q))
			c.draw_colored_polygon(PackedVector2Array([Vector2(0, 0), Vector2(6, 9), Vector2(3, 9), Vector2(7, 15), Vector2(-7, 15), Vector2(-3, 9), Vector2(-6, 9)]), Color("23743f"))
			_r(c, "3fae5a", -3, 7, 6, 1)
			_r(c, "16482c", -1, 15, 2, 3)
	_xf(c)

func _dash(c, id: String, p: Vector2, bob: float, _t: float) -> void:
	match id:
		"dog":   # same as cockpit.gd's, for the preview
			_xf(c)
			var hx := roundf(p.x - 6.5 + bob * 1.5)
			var hy := roundf(p.y - 11.0 + bob * 3.0)
			_r(c, "96643a", hx, hy, 13, 11)
			_r(c, "6e4526", hx - 2, hy + 1, 3, 8)
			_r(c, "6e4526", hx + 12, hy + 1, 3, 8)
			_r(c, "e3ab7c", hx + 3, hy + 6, 7, 5)
			_r(c, "0a0a0f", hx + 3, hy + 4, 2, 2)
			_r(c, "0a0a0f", hx + 8, hy + 4, 2, 2)
			_r(c, "0a0a0f", hx + 5, hy + 7, 3, 2)
			_r(c, "f0484a", hx + 6, hy + 10, 2, 1)
		"flor":   # plastic flower in a little clay pot, nodding on the bumps
			_xf(c, Transform2D(0.0, p))
			var top := Vector2(bob * 2.5, -15.0)
			c.draw_line(Vector2(0, -5), top, Color("3fae5a"), 1.0)
			c.draw_colored_polygon(PackedVector2Array([Vector2(0, -8), Vector2(-4, -10), Vector2(-1, -7)]), Color("3fae5a"))
			c.draw_colored_polygon(PackedVector2Array([Vector2(0.5, -10), Vector2(4, -12), Vector2(1, -9)]), Color("23743f"))
			for k in 5:
				var a := TAU * k / 5.0 + bob
				c.draw_circle(top + Vector2(cos(a), sin(a)) * 2.0, 1.5, Color("f0484a"))
			c.draw_circle(top, 1.0, Color("ffd65a"))
			_r(c, "c47a1c", -3, -5, 6, 5)
			_r(c, "f2a62a", -3.5, -5.5, 7, 1)
			_r(c, "8a5a2a", -3, -1, 6, 1)
		"aparecida":   # the small statue in her blue mantle and gold crown
			_xf(c, Transform2D(bob * 0.08, p))
			_r(c, "e6e8ee", -3.5, -2, 7, 2)
			c.draw_colored_polygon(PackedVector2Array([Vector2(0, -15), Vector2(4.5, -2), Vector2(-4.5, -2)]), Color("1d3a7a"))
			_r(c, "3d5f94", -1.5, -10, 3, 8)
			_r(c, "ffd65a", -1, -9, 2, 0.5)
			c.draw_circle(Vector2(0, -12), 1.3, Color("5a3820"))
			c.draw_colored_polygon(PackedVector2Array([Vector2(-2, -14), Vector2(2, -14), Vector2(2.5, -17), Vector2(1, -15.5), Vector2(0, -18), Vector2(-1, -15.5), Vector2(-2.5, -17)]), Color("ffd65a"))
	_xf(c)

# --- the CABINE screen: list on the left, a live look at the mirror and the dash on the right
func _rows() -> Array:   # [kind, id]
	var out: Array = []
	for id in HANG_IDS:
		out.append(["hang", id])
	for id in DASH_IDS:
		out.append(["dash", id])
	return out

func open() -> void:
	edit_car = g.cfg.car
	row = 0
	g.menu.open_screen("CABINE", _build, _key)

func _build(b: Control) -> void:
	body = b
	_fill()

func _key(k: int) -> void:
	var n := _rows().size()
	match k:
		KEY_UP, KEY_W:
			row = (row + n - 1) % n
		KEY_DOWN, KEY_S:
			row = (row + 1) % n
		KEY_Q, KEY_LEFT, KEY_A:
			edit_car = Cat.CAR_IDS[(Cat.CAR_IDS.find(edit_car) + Cat.CAR_IDS.size() - 1) % Cat.CAR_IDS.size()]
		KEY_E, KEY_RIGHT, KEY_D:
			edit_car = Cat.CAR_IDS[(Cat.CAR_IDS.find(edit_car) + 1) % Cat.CAR_IDS.size()]
		KEY_ENTER, KEY_KP_ENTER, KEY_SPACE:
			_toggle(_rows()[row])
		_:
			return
	_fill()

func _toggle(r: Array) -> void:
	var id: String = r[1]
	if not unlocked(id):
		return
	var d := choice(edit_car)
	if r[0] == "hang":
		if d.hang.has(id):
			d.hang.erase(id)
		else:
			if d.hang.size() >= 2:
				d.hang.pop_front()   # only two fit: the oldest comes down
			d.hang.append(id)
	else:
		d.dash = id
	_set_choice(edit_car, d)

func _fill() -> void:
	if body == null:
		return
	for c in body.get_children():
		c.queue_free()
	var m = g.menu
	m.screen_title.text = "CABINE: " + Cat.CARS[edit_car].name
	m.label("< Q   E >  OUTRO CARRO", 8, DIM, Vector2(0, 2), body)
	var d := choice(edit_car)
	var rows := _rows()
	var y := 20.0
	for i in rows.size():
		var r: Array = rows[i]
		if i == 0 or (r[0] == "dash" and rows[i - 1][0] == "hang"):
			m.label("NO RETROVISOR (ATÉ 2)" if r[0] == "hang" else "NO PAINEL (1)", 8, LINE, Vector2(0, y + (0 if i == 0 else 6)), body)
			y += 14 if i == 0 else 20
		var id: String = r[1]
		var on: bool = d.hang.has(id) if r[0] == "hang" else d.dash == id
		var free := unlocked(id)
		var mark := "[X] " if on else ("[ ] " if free else " -  ")
		var col: Color = AMBER if i == row else (INK if free else DIM)
		m.label(("> " if i == row else "  ") + mark + ITEMS[id].name, 8, col, Vector2(0, y), body)
		if not free:
			m.label(_need(id), 8, Color(DIM, 0.9), Vector2(250, y), body)
		y += 14
	var sel: String = rows[row][1]
	m.label(ITEMS[sel].desc, 8, INK, Vector2(0, 300), body)
	var how := "ENTER: PENDURAR / TIRAR" if rows[row][0] == "hang" else "ENTER: PÔR NO PAINEL"
	if not unlocked(sel):
		how = "AINDA NÃO GANHOU: " + _need(sel)
	m.label(how, 8, LINE if unlocked(sel) else DIM, Vector2(0, 314), body)
	m.label("%s KM RODADOS, %d FIGURINHAS" % [_fmt(_km()), _figs()], 8, DIM, Vector2(420, 300), body)
	var pv := Preview.new()
	pv.owner_f = self
	pv.position = Vector2(420, 20)
	pv.size = Vector2(CROP.size.x * 2.0, CROP.size.y * 2.0)
	pv.clip_contents = true
	pv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(pv)
	m._frame(Rect2(418, 18, pv.size.x + 4, pv.size.y + 4), Color(0, 0, 0, 0), Color(LINE, 0.6), body)

func _fmt(x: float) -> String:
	var h = g.get_node_or_null("hodometro")
	return h.thousands(int(x)) if h != null else str(int(x))

func draw_preview(c: Control, t: float) -> void:
	var car: Dictionary = Cat.CARS[edit_car]
	var lay: Dictionary = car.layout
	c.draw_rect(Rect2(Vector2.ZERO, c.size), Color("4a6a94"))
	c.draw_rect(Rect2(0, c.size.y * 0.45, c.size.x, c.size.y * 0.55), Color("2f5a3a"))
	c.draw_texture_rect_region(g.tex[car.cockpit], Rect2(Vector2.ZERO, c.size), Rect2(CROP.position * 2.0, CROP.size * 2.0))
	_base = Transform2D(0.0, Vector2(2, 2), 0.0, -CROP.position * 2.0)
	var swing := sin(t * 1.3) * 0.35 + sin(t * 3.1) * 0.06
	var m: Array = lay.mirror
	_xf(c)
	_r(c, "1a2547", m[0], m[1], m[2], m[3])
	var anchor := Vector2(lay.anchor[0], lay.anchor[1])
	var d := choice(edit_car)
	var taken: Array = []
	for id in d.hang:
		if BUILTIN.has(id):
			taken.append(12.0 if id == "dice" else 0.0)
			_hang(c, id, anchor, swing, t)
	var k := 0
	for id in d.hang:
		if not BUILTIN.has(id):
			for s in SPOTS:
				if not taken.has(s):
					taken.append(s)
					_hang(c, id, anchor + Vector2(s, 0), swing * (0.9 + k * 0.15), t)
					break
			k += 1
	if d.dash != "":
		_dash(c, d.dash, DASH_AT[edit_car], sin(t * 2.0) * 0.3, t)
	_base = Transform2D.IDENTITY
	c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

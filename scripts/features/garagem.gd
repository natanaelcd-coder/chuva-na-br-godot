extends Node
# Garagem (idea 18): paint, seat cover, floor mat and a rear-window sticker for each car. Only looks, never driving.
# Main menu > GARAGEM: arrows choose and change, Esc goes back. Every change is saved for that car at once.
# Some choices open up with the car's km (the odometer, if there is one); without an odometer everything is open,
# and nothing chosen is ever taken back. Art: tools/art/art_garagem.js (sprites gar_*.png).

const Cat = preload("res://scripts/catalog.gd")
const AMBER := Color("f2a62a")
const LINE := Color("9bbbe0")
const INK := Color("e6e8ee")
const DIM := Color("6f86a8")

# [id, name, km of that car to open it]; id "" is the car as it comes from the catalog
const PAINTS := {
	"besouro": [["", "AZUL DE FÁBRICA", 0], ["limao", "VERDE-LIMÃO", 0], ["bege", "BEGE AREIA", 10],
		["calcinha", "AZUL-CALCINHA", 25], ["laranja", "LARANJA", 50], ["branco", "BRANCO GELO", 100]],
	"picape": [["", "VERDE DE FÁBRICA", 0], ["vermelha", "VERMELHA COM FAIXA", 0], ["saia", "SAIA E BLUSA", 10],
		["azul", "AZUL", 25], ["saia_azul", "SAIA E BLUSA AZUL", 50], ["amarela", "AMARELO OURO", 100]],
	"gt": [["", "VERMELHO DE FÁBRICA", 0], ["prata", "PRATA", 0], ["preto", "PRETO", 15],
		["branco", "BRANCO", 40], ["azul", "AZUL-MARINHO", 80]],
}
const COVERS := [["", "DE FÁBRICA", 0], ["bolinhas", "BOLINHAS DE MADEIRA", 0], ["xadrez", "XADREZ", 5],
	["couro", "COURO", 15], ["pelucia", "PELÚCIA", 30], ["oncinha", "ONCINHA", 60]]
const MATS := [["", "SEM TAPETE", 0], ["branco", "FELPUDO BRANCO", 0], ["rosa", "FELPUDO ROSA", 10], ["azul", "FELPUDO AZUL", 30]]
const MAT_COL := {"branco": ["e6e8ee", "a8acb5", "ffffff"], "rosa": ["e88aa8", "a8506e", "ffc8d8"], "azul": ["5279ad", "30465a", "9bbbe0"]}
# stickers: [id, name, km, printed on paper (seen from inside as its white back) or cut vinyl letters]
const STICKERS := [["", "SEM ADESIVO", 0, false], ["pago", "TÁ PAGO", 0, false], ["chuva", "XÔ CHUVA", 0, false],
	["deus", "SÓ DEUS", 5, true], ["br", "PÉ NA BR", 10, false], ["devagar", "DEVAGAR", 20, true],
	["volto", "VOLTO JÁ", 35, false], ["indo", "TÔ INDO", 60, true]]
const ROWS := ["CARRO", "COR", "CAPAS DE BANCO E VOLANTE", "TAPETE", "ADESIVO"]
const SLOTS := ["", "cor", "capa", "tapete", "adesivo"]
# where things sit, per car: passenger seat (bottom-left, top-left, top-right corners), floor mat (x, y, w, h),
# sticker on the rear glass (centre x and bottom y in sprite units), mirror glass in the cabin (x, y, w, h)
const SPOTS := {
	"besouro": {"seat": [284, 216, 294, 186, 184], "mat": [222, 199, 56, 14], "sticker": [32.0, 15.5], "mirror": [171, 28, 42, 11],
		"rim": 11.0, "crop": [204, 130]},
	"picape": {"seat": [262, 216, 274, 190, 188], "mat": [226, 194, 72, 22], "sticker": [32.0, 13.5], "mirror": [168, 8, 48, 11],
		"rim": 7.0, "crop": [196, 128]},
	"gt": {"seat": [276, 216, 286, 186, 184], "mat": [246, 196, 52, 18], "sticker": [32.0, 17.0], "mirror": [169, 23, 46, 11],
		"rim": 12.0, "crop": [190, 126]},
}

var g
var row := 0
var edit_car := "besouro"
var shown := {}            # what the garage screen shows per slot (may be a locked choice being tried on)
var info_lbl: Label
var val_lbls: Array = []
var arrow_lbls: Array = []
var name_lbls: Array = []
var km_lbl: Label
var preview: Control
var _tex := {}

func _ready() -> void:
	g = get_parent()
	g.setup_done.connect(_apply)
	g.menu.add_main_item("GARAGEM", _open)

# ---- saved choices
func choice(car: String, slot: String) -> String:
	return str(g.store_get("garagem", "%s_%s" % [car, slot], ""))

func _list(slot: String, car: String) -> Array:
	match slot:
		"cor": return PAINTS[car]
		"capa": return COVERS
		"tapete": return MATS
		"adesivo": return STICKERS
	return []

func _find(slot: String, car: String, id: String) -> Array:
	for it in _list(slot, car):
		if it[0] == id:
			return it
	return _list(slot, car)[0]

func _tx(name: String) -> Texture2D:
	if not _tex.has(name):
		var p := "res://assets/sprites/%s.png" % name
		_tex[name] = load(p) if ResourceLoader.exists(p) else null
	return _tex[name]

# km this car has run, or -1 when the game keeps no odometer (then everything is open)
func odo_km(car: String) -> float:
	var v = g.store_get("hodometro", car, false)   # (ConfigFile takes a null default as no default)
	if v is float or v is int:
		return float(v)
	if v is Dictionary and v.has("km"):
		return float(v.km)
	for f in g.features:
		if String(f.name).begins_with("hodometro") or String(f.name).begins_with("odometro"):
			return 0.0
	return -1.0

func is_open(car: String, it: Array) -> bool:
	var km := odo_km(car)
	return km < 0.0 or km >= float(it[2])

# ---- the look of the car being driven
func body_tex(car: String, paint: String) -> Texture2D:
	return _tx("gar_player_%s_%s" % [car, paint]) if paint != "" else g.tex[Cat.CARS[car].player]

func cabin_tex(car: String, paint: String) -> Texture2D:
	return _tx("gar_cockpit_%s_%s" % [car, paint]) if paint != "" else g.tex[Cat.CARS[car].cockpit]

func _apply() -> void:
	var car: String = g.cfg.car
	var paint := choice(car, "cor")
	var w = g.get_node_or_null("World")
	if w:
		w.player_tex = body_tex(car, paint) if paint != "" else null
	var ck = g.get_node_or_null("Cockpit")
	if ck and ck.get("cock") != null:
		var t := cabin_tex(car, paint)
		if t:
			ck.cock = t

func draw_player(world: CanvasItem, k: float) -> void:
	var car: String = g.cfg.car
	_sticker(world, car, choice(car, "adesivo"), k)

func draw_wheel(ck: CanvasItem, wr: float) -> void:
	var car: String = g.cfg.car
	draw_wheel_cover(ck, car, choice(car, "capa"), wr)

func draw_cabin_mid(ck: CanvasItem) -> void:
	var car: String = g.cfg.car
	draw_mat(ck, car, choice(car, "tapete"))
	draw_seat(ck, car, choice(car, "capa"))
	_mirror_sticker(ck, car, choice(car, "adesivo"))

# rear-window sticker on the body sprite: sprite unit (u, v) sits at at + ((u - 32) k, (v - 44) k)
func _sticker(ci: CanvasItem, car: String, id: String, k: float, at := Vector2.ZERO) -> void:
	if id == "":
		return
	var t := _tx("gar_adesivo_" + id)
	if t == null:
		return
	var sz := t.get_size() / 2.0
	var sp: Array = SPOTS[car].sticker
	ci.draw_texture_rect(t, Rect2(at + Vector2(sp[0] - sz.x / 2.0 - 32.0, sp[1] - sz.y - 44.0) * k, sz * k), false)

# from the driver's seat the sticker shows in the rear-view mirror: letters backwards, or the paper's white back
func _mirror_sticker(ci: CanvasItem, car: String, id: String) -> void:
	if id == "":
		return
	var it := _find("adesivo", car, id)
	var t := _tx("gar_adesivo_" + id)
	if t == null:
		return
	var sz := t.get_size() / 2.0
	var m: Array = SPOTS[car].mirror
	var x: float = m[0] + m[2] / 2.0 - sz.x / 2.0
	var y: float = m[1] + m[3] - sz.y
	if it[3]:
		ci.draw_rect(Rect2(x, y + 0.5, sz.x, sz.y - 0.5), Color(0.78, 0.8, 0.84, 0.55))
	else:
		ci.draw_set_transform(Vector2(x + sz.x, y), 0.0, Vector2(-1, 1))
		ci.draw_texture_rect(t, Rect2(Vector2.ZERO, sz), false, Color(1, 1, 1, 0.7))
		ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

# ---- passenger seat cover, drawn over the seat painted in the cabin
func _seat_geo(car: String) -> Dictionary:
	var s: Array = SPOTS[car].seat
	return {"x0": float(s[0]), "yb": float(s[1]), "x1": float(s[2]), "y1": float(s[3]), "y2": float(s[4])}

static func _row_x(q: Dictionary, y: float) -> float:   # leftmost x of the seat on row y
	var xl: float = q.x0 + (q.x1 - q.x0) * (q.yb - y) / (q.yb - q.y1)
	if y < q.y1:   # the top edge slopes up to the right
		xl = maxf(xl, q.x1 + (q.y1 - y) * (384.0 - q.x1) / (q.y1 - q.y2))
	return xl

static func _inside(q: Dictionary, x: float, y: float) -> bool:
	return y <= q.yb and x <= 384.0 and x >= _row_x(q, y) and y >= minf(q.y1, q.y2)

static func _h(i: int) -> float:   # small fixed noise, so fur and spots do not crawl
	return fposmod(sin(i * 12.9898) * 43758.5453, 1.0)

func draw_seat(ci: CanvasItem, car: String, id: String) -> void:
	if id == "":
		return
	var q := _seat_geo(car)
	var poly := PackedVector2Array([Vector2(q.x0, q.yb), Vector2(q.x1, q.y1), Vector2(384, q.y2), Vector2(384, q.yb)])
	var top := minf(q.y1, q.y2)
	match id:
		"bolinhas":   # the taxi driver's wooden beads
			ci.draw_colored_polygon(poly, Color("2b1a12"))
			var r := 0
			for y in range(int(top) + 2, 218, 4):
				var x := 384.0 - (r % 2) * 2.0
				while x > q.x0 - 2.0:
					if _inside(q, x - 1.0, y - 1.0):
						ci.draw_circle(Vector2(x, y), 1.8, Color("c68a5a" if posmod(int(x / 4.0) + r, 5) else "96643a"))
						ci.draw_rect(Rect2(x - 1.0, y - 1.0, 0.5, 0.5), Color("f3cfa6"))
					x -= 4.0
				r += 1
		"xadrez":
			ci.draw_colored_polygon(poly, Color("c22630"))
			for y in range(int(top), 216):
				var xl := _row_x(q, y + 0.5)
				var band := posmod(y - int(top), 8)
				if band < 3:
					ci.draw_rect(Rect2(xl, y, 384.0 - xl, 1), Color("7a1620"))
				elif band == 5:
					ci.draw_rect(Rect2(xl, y, 384.0 - xl, 0.5), Color("ffd65a"))
				var x := 384.0 - 2.0
				while x > xl:
					var bx := posmod(int(384.0 - x), 8)
					ci.draw_rect(Rect2(maxf(x, xl), y, minf(3.0, 384.0 - maxf(x, xl)), 1), Color("16202b", 0.45 if band < 3 else 0.3))
					if bx == 0:
						ci.draw_rect(Rect2(maxf(x - 3.0, xl), y, 0.5, 1), Color("ffd65a", 0.7))
					x -= 8.0
		"couro":   # brown leather in tucked channels
			ci.draw_colored_polygon(poly, Color("5a3420"))
			for y in range(int(top) + 1, 216):
				var xl := _row_x(q, y + 0.5)
				var ch := posmod(y - int(top), 5)
				if ch == 0:
					ci.draw_rect(Rect2(xl, y, 384.0 - xl, 0.5), Color("2b1a12"))
				elif ch == 1:
					ci.draw_rect(Rect2(xl + 1.0, y, 384.0 - xl, 0.5), Color("8a5432"))
			for i in 6:
				var y := top + 3.5 + i * 5.0
				var x := 384.0 - 6.0 - (i % 2) * 6.0
				while y < 216.0 and x > _row_x(q, y) + 2.0:
					ci.draw_rect(Rect2(x, y, 1, 1), Color("2b1a12"))
					x -= 12.0
		"pelucia":   # plush: soft, light, with tufts all over and over the edge
			ci.draw_colored_polygon(poly, Color("d8ccd0"))
			for i in 220:
				var y: float = top + _h(i) * (q.yb - top)
				var x: float = 384.0 - _h(i + 999) * (384.0 - q.x0)
				if _inside(q, x, y):
					ci.draw_rect(Rect2(roundf(x * 2.0) / 2.0, roundf(y * 2.0) / 2.0, 1, 1.5), Color("f4eef0" if i % 3 else "a8979e"))
			for i in 40:
				var x: float = q.x1 + _h(i + 77) * (384.0 - q.x1)
				var y: float = q.y1 + (q.y2 - q.y1) * (x - q.x1) / (384.0 - q.x1)
				ci.draw_rect(Rect2(roundf(x * 2.0) / 2.0, y - 1.0, 0.5, 1.5), Color("f4eef0"))
		"oncinha":
			ci.draw_colored_polygon(poly, Color("d9a24a"))
			for i in 34:
				var y: float = top + 2.0 + _h(i + 5) * (q.yb - top - 2.0)
				var x: float = 384.0 - _h(i + 555) * (384.0 - q.x0)
				if _inside(q, x - 2.0, y - 1.5):
					ci.draw_circle(Vector2(x, y), 2.0, Color("2b1a12"))
					ci.draw_circle(Vector2(x + 0.3, y), 1.1, Color("a8682a"))
	# piping along the top edge
	ci.draw_line(Vector2(q.x1, q.y1), Vector2(384, q.y2), Color(1, 1, 1, 0.18), 0.5)

# the steering-wheel cover that goes with the seat cover (drawn in the wheel's frame, rim of radius wr)
func draw_wheel_cover(ci: CanvasItem, car: String, id: String, wr: float) -> void:
	if id == "":
		return
	var t: float = SPOTS[car].rim
	match id:
		"bolinhas":
			var rows := [-t * 0.25, t * 0.25] if t >= 9.0 else [0.0]
			var br := t / (4.0 if rows.size() > 1 else 2.4)
			ci.draw_arc(Vector2.ZERO, wr, 0.0, TAU, 72, Color("2b1a12"), t)
			for ri in rows.size():
				var r: float = wr + rows[ri]
				var n := int(TAU * r / (br * 2.2))
				for i in n:
					var a := TAU * (i + ri * 0.5) / n
					var p := Vector2(cos(a), sin(a)) * r
					ci.draw_circle(p, br, Color("c68a5a" if (i + ri) % 4 else "96643a"))
					ci.draw_rect(Rect2(p.x - br * 0.5, p.y - br * 0.5, 0.5, 0.5), Color("f3cfa6"))
		"xadrez":
			ci.draw_arc(Vector2.ZERO, wr, 0.0, TAU, 72, Color("c22630"), t)
			for i in 36:
				var a := TAU * i / 36.0
				ci.draw_arc(Vector2.ZERO, wr, a, a + TAU / 90.0, 4, Color("7a1620"), t)
			ci.draw_arc(Vector2.ZERO, wr, 0.0, TAU, 72, Color("7a1620"), t * 0.3)
			ci.draw_arc(Vector2.ZERO, wr + t * 0.3, 0.0, TAU, 72, Color("ffd65a"), 0.5)
		"couro":
			ci.draw_arc(Vector2.ZERO, wr, 0.0, TAU, 72, Color("5a3420"), t)
			ci.draw_arc(Vector2.ZERO, wr - t * 0.2, 0.0, TAU, 72, Color("8a5432"), 1.0)
			for i in 60:   # the stitching
				var a := TAU * i / 60.0
				ci.draw_arc(Vector2.ZERO, wr + t * 0.5 - 1.0, a, a + TAU / 160.0, 2, Color("e3ab7c"), 0.5)
		"pelucia":
			ci.draw_arc(Vector2.ZERO, wr, 0.0, TAU, 72, Color("d8ccd0"), t + 1.5)
			for i in 260:
				var a := TAU * _h(i + 17)
				var r := wr + (_h(i + 41) - 0.5) * (t + 2.5)
				ci.draw_rect(Rect2(cos(a) * r, sin(a) * r, 1, 1), Color("f4eef0" if i % 3 else "a8979e"))
		"oncinha":
			ci.draw_arc(Vector2.ZERO, wr, 0.0, TAU, 72, Color("d9a24a"), t)
			for i in 30:
				var a := TAU * _h(i + 91)
				var r := wr + (_h(i + 13) - 0.5) * t * 0.5
				var p := Vector2(cos(a), sin(a)) * r
				ci.draw_circle(p, t * 0.18, Color("2b1a12"))
				ci.draw_circle(p, t * 0.09, Color("a8682a"))

# ---- fluffy floor mat on the passenger side
func draw_mat(ci: CanvasItem, car: String, id: String) -> void:
	if id == "" or not MAT_COL.has(id):
		return
	var c: Array = MAT_COL[id]
	var m: Array = SPOTS[car].mat
	var x: float = m[0]
	var y: float = m[1]
	var w: float = m[2]
	var hh: float = m[3]
	var inset := hh * 0.25   # seen from above and behind: the far edge is narrower
	ci.draw_colored_polygon(PackedVector2Array([Vector2(x + inset, y), Vector2(x + w - inset, y), Vector2(x + w, y + hh), Vector2(x, y + hh)]), Color(c[1]))
	ci.draw_colored_polygon(PackedVector2Array([Vector2(x + inset + 1, y + 1), Vector2(x + w - inset - 1, y + 1), Vector2(x + w - 1, y + hh), Vector2(x + 1, y + hh)]), Color(c[0]))
	var n := int(w * hh / 3.0)
	for i in n:
		var fy := _h(i + 31) * hh
		var e := inset * (1.0 - fy / hh)
		var fx := x + e + _h(i + 3) * (w - 2.0 * e)
		ci.draw_rect(Rect2(roundf(fx * 2.0) / 2.0, roundf((y + fy) * 2.0) / 2.0, 0.5, 1.5), Color(c[2] if i % 3 else c[1]))
	for i in int(w / 2.0):   # shaggy fringe over the far edge
		var fx := x + inset + i * 2.0 * (w - 2.0 * inset) / w
		ci.draw_rect(Rect2(fx, y - 0.5 - _h(i + 8) * 0.5, 0.5, 1.5), Color(c[0]))

# ---- the garage screen
func _open() -> void:
	edit_car = g.cfg.car
	row = 1
	_load_shown()
	g.menu.open_screen("GARAGEM", _build, _key)

func _load_shown() -> void:
	shown = {}
	for s in SLOTS:
		if s != "":
			shown[s] = choice(edit_car, s)

func _build(body: Control) -> void:
	val_lbls.clear()
	arrow_lbls.clear()
	name_lbls.clear()
	for i in ROWS.size():
		var y := 6.0 + i * 46.0
		name_lbls.append(g.menu.label(ROWS[i], 8, LINE, Vector2(0, y), body))
		var l: Label = g.menu.label("<", 16, DIM, Vector2(0, y + 12), body)
		var r: Label = g.menu.label(">", 16, DIM, Vector2(300, y + 12), body)
		var v: Label = g.menu.label("", 16, INK, Vector2(20, y + 12), body)
		v.size = Vector2(280, 18)
		v.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		val_lbls.append(v)
		arrow_lbls.append([l, r])
	km_lbl = g.menu.label("", 8, DIM, Vector2(0, 238), body)
	info_lbl = g.menu.label("", 8, INK, Vector2(0, 254), body)
	info_lbl.size = Vector2(320, 40)
	info_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	g.menu.label("SETAS ESCOLHEM E TROCAM", 8, DIM, Vector2(0, 302), body)
	g.menu.label("TUDO É SALVO NA HORA", 8, DIM, Vector2(0, 316), body)
	preview = Control.new()
	preview.position = Vector2(340, 0)
	preview.size = Vector2(348, 330)
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview.draw.connect(_draw_preview)
	body.add_child(preview)
	_refresh()

func _refresh() -> void:
	if val_lbls.is_empty() or not is_instance_valid(val_lbls[0]):
		return
	var km := odo_km(edit_car)
	var locked_note := ""
	for i in ROWS.size():
		var on := i == row
		var txt: String = Cat.CARS[edit_car].name
		var open := true
		if i > 0:
			var it := _find(SLOTS[i], edit_car, shown[SLOTS[i]])
			txt = it[1]
			open = is_open(edit_car, it)
			if on and not open:
				locked_note = "ESSA SAI COM %d KM NESTE CARRO. FALTAM %d KM DE ESTRADA." % [it[2], ceili(it[2] - km)]
		val_lbls[i].text = txt
		val_lbls[i].label_settings.font_color = (AMBER if on else INK) if open else Color(DIM, 0.9)
		name_lbls[i].label_settings.font_color = LINE if on else DIM
		for a in arrow_lbls[i]:
			a.label_settings.font_color = AMBER if on else Color(DIM, 0.6)
	km_lbl.text = "" if km < 0.0 else "%s: %d KM RODADOS" % [Cat.CARS[edit_car].name, int(km)]
	if locked_note != "":
		info_lbl.text = locked_note
		info_lbl.label_settings.font_color = AMBER
	else:
		info_lbl.text = ["ESCOLHA O CARRO PARA ARRUMAR.", "SÓ MUDA A APARÊNCIA: O CARRO ANDA IGUAL.",
			"NO BANCO DO CARONA E NO VOLANTE, COMBINANDO.", "NO CHÃO, DO LADO DO CARONA.", "NO VIDRO DE TRÁS. DE DENTRO, APARECE NO RETROVISOR."][row]
		info_lbl.label_settings.font_color = INK
	if preview:
		preview.queue_redraw()

func _key(k: int) -> void:
	match k:
		KEY_UP, KEY_W:
			row = (row + ROWS.size() - 1) % ROWS.size()
		KEY_DOWN, KEY_S:
			row = (row + 1) % ROWS.size()
		KEY_LEFT, KEY_A:
			_change(-1)
		KEY_RIGHT, KEY_D, KEY_ENTER, KEY_KP_ENTER, KEY_SPACE:
			_change(1)
	_refresh()

func _change(d: int) -> void:
	if row == 0:
		var ids: Array = Cat.CAR_IDS
		edit_car = ids[(ids.find(edit_car) + d + ids.size()) % ids.size()]
		_load_shown()
		return
	var slot: String = SLOTS[row]
	var l := _list(slot, edit_car)
	var i := 0
	for j in l.size():
		if l[j][0] == shown[slot]:
			i = j
	var it: Array = l[(i + d + l.size()) % l.size()]
	shown[slot] = it[0]
	if is_open(edit_car, it):   # a locked one can be tried on here, but only an open one is kept
		g.store_set("garagem", "%s_%s" % [edit_car, slot], it[0])
		g.store_save()
		if edit_car == g.cfg.car:
			_apply()

func _draw_preview() -> void:
	var p := preview
	var car := edit_car
	# the car from behind, in a garage with a lamp
	var box := Rect2(4, 0, 340, 164)
	p.draw_rect(box, Color("16202b"))
	p.draw_rect(Rect2(box.position.x, 120, box.size.x, 44), Color("2a2c33"))
	p.draw_rect(Rect2(box.position.x, 120, box.size.x, 1), Color("4a4d57"))
	for i in 7:
		p.draw_rect(Rect2(box.position.x + 8 + i * 48, 4, 30, 2), Color("ffd65a", 0.15))
	var k := 3.0
	var c := Vector2(174, 150)
	p.draw_set_transform(c + Vector2(0, -k), 0.0, Vector2(31.0 * k, 4.0 * k))
	p.draw_circle(Vector2.ZERO, 1.0, Color(0, 0, 0, 0.5))
	p.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var info: Dictionary = Cat.CARS[car]
	for wx in info.wheel_x:
		var ww: float = info.get("wheel_w", 9.0)
		p.draw_rect(Rect2(c.x + wx * k, c.y - 7.0 * k, ww * k, 7.0 * k), Color("05070c"))
		p.draw_rect(Rect2(c.x + (wx + 1.0) * k, c.y - 7.0 * k, (ww - 2.0) * k, 2.0 * k), Color("2a2c33"))
	var o := c + Vector2(0, -6.0 * k)
	var bt := body_tex(car, shown.get("cor", ""))
	if bt:
		p.draw_texture_rect(bt, Rect2(o + Vector2(-32.0, -44.0) * k, Vector2(64.0, 46.0) * k), false)
	_sticker(p, car, shown.get("adesivo", ""), k, o)
	# a spare steering wheel hanging on the wall, wearing the cover
	var wl: Array = info.layout.wheel
	var wr: float = wl[2]
	var ws := 22.0 / wr
	p.draw_rect(Rect2(41, 29, 3, 3), Color("a8acb5"))
	p.draw_set_transform(Vector2(42.5, 54), 0.0, Vector2(ws, ws))
	p.draw_line(Vector2(-wr, 4), Vector2(wr, 4), Color("16202b"), 7.0)
	p.draw_circle(Vector2(0, 4), 11.0, Color("0a0a0f"))
	p.draw_arc(Vector2.ZERO, wr, 0.0, TAU, 64, Color({"picape": "e6e8ee", "gt": "0a0a0f"}.get(car, "3d5f94")), SPOTS[car].rim)
	draw_wheel_cover(p, car, shown.get("capa", ""), wr)
	p.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# the passenger side of the cabin: painted dash, seat cover and mat
	var cr: Array = SPOTS[car].crop   # 1:1 with the game's pixels
	var src := Rect2(cr[0], cr[1], 170, 80)
	var s := 2.0
	var dst := Rect2(Vector2(4, 170), src.size * s)
	p.draw_rect(dst, Color("4a6a94"))
	var ct := cabin_tex(car, shown.get("cor", ""))
	if ct:
		p.draw_texture_rect_region(ct, dst, Rect2(src.position * 2.0, src.size * 2.0))
	p.draw_set_transform(dst.position - src.position * s, 0.0, Vector2(s, s))
	draw_mat(p, car, shown.get("tapete", ""))
	draw_seat(p, car, shown.get("capa", ""))
	p.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	p.draw_rect(dst, LINE, false, 1.0)
	p.draw_rect(box, LINE, false, 1.0)

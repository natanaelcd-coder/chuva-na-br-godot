extends CanvasLayer
# Trip planner (car, road, weather, time) over a live preview of that trip, and the pause screen.
# Keyboard: arrows choose and change, Enter starts. Mouse: click the arrows, values or the button.

const Cat = preload("res://scripts/catalog.gd")
const AMBER := Color("f2a62a")
const LINE := Color("9bbbe0")
const INK := Color("e6e8ee")
const DIM := Color("6f86a8")
const PANEL := Color(0.027, 0.043, 0.094, 0.78)
const KEYS := ["car", "road", "weather", "time"]
const LABELS := ["CARRO", "ESTRADA", "CLIMA", "HORA"]
const ROW_Y := [88, 178, 250, 300]
const BTN := Rect2(28, 346, 392, 30)
const PAUSE_ITEMS := ["CONTINUAR", "MUDAR A VIAGEM", "SOM", "SAIR DO JOGO"]

var font: FontFile = preload("res://assets/fonts/Estrada2P.ttf")
var g
var main_root: Control
var pause_root: Control
var sel := 0
var psel := 0
var rows: Array = []        # per row: {bar, label, left, value, right, desc}
var stat_boxes: Array = []  # 3 x 5 ColorRects
var btn_panel: Panel
var btn_label: Label
var record: Label
var pause_labels: Array = []

func _ready() -> void:
	g = get_parent()
	layer = 3
	_build_main()
	_build_pause()
	hide_all()

func _lbl(txt: String, size: int, col: Color, pos: Vector2, parent: Node, shadow := false) -> Label:
	var l := Label.new()
	var ls := LabelSettings.new()
	ls.font = font
	ls.font_size = size
	ls.font_color = col
	if shadow:
		ls.shadow_color = Color.BLACK
		ls.shadow_offset = Vector2(2, 2)
	l.label_settings = ls
	l.text = txt
	l.position = pos
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	return l

func _rect(r: Rect2, col: Color, parent: Node) -> ColorRect:
	var c := ColorRect.new()
	c.position = r.position
	c.size = r.size
	c.color = col
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(c)
	return c

func _frame(r: Rect2, bg: Color, border: Color, parent: Node) -> Panel:
	var p := Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(4)
	sb.anti_aliasing = false
	p.add_theme_stylebox_override("panel", sb)
	p.position = r.position
	p.size = r.size
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(p)
	return p

func _build_main() -> void:
	main_root = Control.new()
	main_root.size = Vector2(768, 432)
	main_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(main_root)
	_rect(Rect2(0, 0, 452, 432), PANEL, main_root)
	_rect(Rect2(452, 0, 2, 432), Color(LINE, 0.5), main_root)
	var t := _lbl("CHUVA NA BR", 32, AMBER, Vector2(26, 18), main_root, true)
	t.label_settings.shadow_offset = Vector2(3, 3)
	_lbl("UMA VIAGEM SEM PRESSA", 8, LINE, Vector2(28, 56), main_root)
	record = _lbl("", 8, DIM, Vector2(28, 68), main_root)
	for i in KEYS.size():
		var y: float = ROW_Y[i]
		var r := {}
		r.bar = _rect(Rect2(12, y, 4, (78 if i < 2 else 44)), AMBER, main_root)
		r.label = _lbl(LABELS[i], 8, LINE, Vector2(28, y), main_root)
		r.left = _lbl("<", 16, DIM, Vector2(28, y + 12), main_root)
		r.value = _lbl("", 16, INK, Vector2(52, y + 12), main_root)
		r.value.size = Vector2(364, 18)
		r.value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		r.right = _lbl(">", 16, DIM, Vector2(406, y + 12), main_root)
		r.desc = _lbl("", 8, INK, Vector2(28, y + 34), main_root)
		r.desc.size = Vector2(400, 20)
		r.desc.autowrap_mode = TextServer.AUTOWRAP_WORD
		rows.append(r)
	var sx := [[28, "VELOCIDADE"], [164, "CONFORTO"], [294, "DIREÇÃO"]]
	for k in 3:
		_lbl(sx[k][1], 8, DIM, Vector2(sx[k][0], 150), main_root)
		var boxes := []
		for b in 5:
			boxes.append(_rect(Rect2(sx[k][0] + b * 10, 160, 8, 5), DIM, main_root))
		stat_boxes.append(boxes)
	btn_panel = _frame(BTN, Color("0b1120"), DIM, main_root)
	btn_label = _lbl("PEGAR A ESTRADA", 16, INK, BTN.position + Vector2(0, 7), main_root)
	btn_label.size = Vector2(BTN.size.x, 18)
	btn_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl("SETAS: ESCOLHER E TROCAR    ENTER: PARTIR", 8, LINE, Vector2(28, 388), main_root)
	_lbl("NA ESTRADA: ESC PAUSA  V CÂMERA  R RÁDIO", 8, DIM, Vector2(28, 400), main_root)
	_lbl("PRÉVIA AO VIVO", 8, Color(INK, 0.6), Vector2(640, 12), main_root, true)

func _build_pause() -> void:
	pause_root = Control.new()
	pause_root.size = Vector2(768, 432)
	pause_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(pause_root)
	_rect(Rect2(0, 0, 768, 432), Color(0.02, 0.03, 0.07, 0.6), pause_root)
	_frame(Rect2(214, 104, 340, 214), Color("0b1120"), LINE, pause_root)
	var t := _lbl("PAUSA", 32, AMBER, Vector2(214, 124), pause_root, true)
	t.size = Vector2(340, 34)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	for i in PAUSE_ITEMS.size():
		var l := _lbl("", 16, INK, Vector2(214, 180 + i * 30), pause_root)
		l.size = Vector2(340, 18)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		pause_labels.append(l)

func hide_all() -> void:
	main_root.visible = false
	pause_root.visible = false

func show_main() -> void:
	pause_root.visible = false
	main_root.visible = true
	_preview_cam()
	refresh()

func show_pause() -> void:
	main_root.visible = false
	pause_root.visible = true
	psel = 0
	refresh()

func _ids(k: String) -> Array:
	return {"car": Cat.CAR_IDS, "road": Cat.ROAD_IDS, "weather": Cat.WEATHER_IDS, "time": Cat.TIME_IDS}[k]

func _info(k: String, id: String) -> Dictionary:
	return {"car": Cat.CARS, "road": Cat.ROADS, "weather": Cat.WEATHER, "time": Cat.TIMES}[k][id]

func refresh() -> void:
	for i in KEYS.size():
		var r: Dictionary = rows[i]
		var on := i == sel
		var info := _info(KEYS[i], g.cfg[KEYS[i]])
		r.value.text = info.name
		r.desc.text = info.desc
		r.bar.visible = on
		r.value.label_settings.font_color = AMBER if on else INK
		r.left.label_settings.font_color = AMBER if on else DIM
		r.right.label_settings.font_color = AMBER if on else DIM
		r.desc.label_settings.font_color = INK if on else DIM
	var st: Array = Cat.CARS[g.cfg.car].stats
	for k in 3:
		for b in 5:
			stat_boxes[k][b].color = (AMBER if sel == 0 else LINE) if b < st[k] else Color(DIM, 0.4)
	var bon := sel == KEYS.size()
	(btn_panel.get_theme_stylebox("panel") as StyleBoxFlat).border_color = AMBER if bon else DIM
	btn_label.label_settings.font_color = AMBER if bon else INK
	var rec: float = g.his.get(g.cfg.road, 0.0)
	record.text = "RECORDE NESTA ESTRADA: %s" % _fmt(rec) if rec > 0.0 else "SEM RECORDE NESTA ESTRADA AINDA"
	for i in PAUSE_ITEMS.size():
		var txt: String = PAUSE_ITEMS[i]
		if txt == "SOM":
			txt = "SOM: LIGADO" if g.sound_on else "SOM: DESLIGADO"
		pause_labels[i].text = ("> " + txt + " <") if i == psel else txt
		pause_labels[i].label_settings.font_color = AMBER if i == psel else INK

static func _fmt(n: float) -> String:
	var s := "%06d" % mini(999999, int(n))
	return s.substr(0, 3) + "." + s.substr(3)

func _preview_cam() -> void:   # the car row shows the cabin; the rest show the car on its road
	g.set_cam(0 if sel == 0 else 1)

func _change(row: int, d: int) -> void:
	var k: String = KEYS[row]
	var ids := _ids(k)
	var i := (ids.find(g.cfg[k]) + d + ids.size()) % ids.size()
	g.choose(k, ids[i])
	_preview_cam()
	refresh()

func _select(i: int) -> void:
	sel = clampi(i, 0, KEYS.size())
	_preview_cam()
	refresh()

func key(k: int) -> void:
	if pause_root.visible:
		match k:
			KEY_UP, KEY_W:
				psel = (psel + PAUSE_ITEMS.size() - 1) % PAUSE_ITEMS.size()
			KEY_DOWN, KEY_S:
				psel = (psel + 1) % PAUSE_ITEMS.size()
			KEY_ENTER, KEY_KP_ENTER, KEY_SPACE:
				_pause_pick(psel)
				return
			KEY_ESCAPE:
				g.resume()
				return
		refresh()
		return
	if not main_root.visible:
		return
	match k:
		KEY_UP, KEY_W:
			_select((sel + KEYS.size()) % (KEYS.size() + 1))
		KEY_DOWN, KEY_S:
			_select((sel + 1) % (KEYS.size() + 1))
		KEY_LEFT, KEY_A:
			if sel < KEYS.size():
				_change(sel, -1)
		KEY_RIGHT, KEY_D:
			if sel < KEYS.size():
				_change(sel, 1)
		KEY_ENTER, KEY_KP_ENTER, KEY_SPACE:
			g.begin()

func _pause_pick(i: int) -> void:
	match PAUSE_ITEMS[i]:
		"CONTINUAR":
			g.resume()
		"MUDAR A VIAGEM":
			g.to_menu()
		"SOM":
			g.set_sound(not g.sound_on)
			refresh()
		"SAIR DO JOGO":
			g.to_menu()
			get_tree().quit()

func click(p: Vector2) -> void:
	if pause_root.visible:
		for i in PAUSE_ITEMS.size():
			if Rect2(214, 176 + i * 30, 340, 26).has_point(p):
				psel = i
				_pause_pick(i)
				return
		return
	if not main_root.visible:
		return
	if BTN.has_point(p):
		g.begin()
		return
	for i in KEYS.size():
		var y: float = ROW_Y[i]
		if Rect2(20, y - 4, 432, (80 if i < 2 else 48)).has_point(p):
			if sel != i:
				_select(i)
			if Rect2(20, y + 8, 30, 26).has_point(p):
				_change(i, -1)
			elif Rect2(52, y + 8, 390, 26).has_point(p):
				_change(i, 1)
			return

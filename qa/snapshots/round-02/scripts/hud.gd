extends CanvasLayer
# Score, toast, now-playing strip, speed/gear/fuel panel and the start screen.

const AMBER := Color("f2a62a")
const LINE := Color("9bbbe0")
const PANEL := Color("0b1120")
var font: FontFile = preload("res://assets/fonts/PressStart2P.ttf")
var l_score: Label
var l_hi: Label
var l_toast: Label
var l_now: Label
var l_kmh: Label
var l_gear: Label
var bars: Array = []
var start: Control
var toast_t := 0.0
var _fuel := -1

func _label(txt: String, size: int, col: Color, pos: Vector2, parent: Node = self, shadow := true) -> Label:
	var l := Label.new()
	var ls := LabelSettings.new()
	ls.font = font
	ls.font_size = size
	ls.font_color = col
	if shadow:
		ls.shadow_color = Color.BLACK
		ls.shadow_offset = Vector2(2, 2)
		ls.shadow_size = 0
	l.label_settings = ls
	l.text = txt
	l.position = pos
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	return l

func _box(rect: Rect2, radius: int, borders: Array, parent: Node = self) -> Panel:
	var p := Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = PANEL
	sb.border_color = LINE
	sb.border_width_left = borders[0]
	sb.border_width_top = borders[1]
	sb.border_width_right = borders[2]
	sb.border_width_bottom = borders[3]
	sb.set_corner_radius_all(radius)
	sb.anti_aliasing = false
	p.add_theme_stylebox_override("panel", sb)
	p.position = rect.position
	p.size = rect.size
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(p)
	return p

func _centered(txt: String, size: int, col: Color, y: float, parent: Node = self) -> Label:
	var l := _label(txt, size, col, Vector2(0, y), parent)
	l.size = Vector2(768, size + 4)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l

func _ready() -> void:
	font.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	font.hinting = TextServer.HINTING_NONE
	font.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
	l_score = _label("1P: 000.000", 16, Color("e6e8ee"), Vector2(11, 11))
	l_hi = _centered("HI-SCORE: 000.000", 16, Color("e6e8ee"), 11)
	l_toast = _centered("", 16, AMBER, 46)
	l_toast.modulate.a = 0.0
	_box(Rect2(-2, 408, 450, 26), 0, [0, 2, 2, 0])
	l_now = _label("", 8, Color("e6e8ee"), Vector2(10, 417), self, false)
	l_now.size = Vector2(428, 10)
	l_now.clip_text = true
	l_now.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_box(Rect2(538, 352, 224, 74), 6, [2, 2, 2, 2])
	l_kmh = _label("0", 32, Color("3fe0e8"), Vector2(550, 364), self, false)
	l_kmh.size = Vector2(96, 34)
	l_kmh.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_label("KM/H", 8, LINE, Vector2(550, 406), self, false)
	l_gear = _label("N", 24, AMBER, Vector2(658, 370), self, false)
	_label("TANQUE", 8, LINE, Vector2(706, 406), self, false)
	for i in 6:
		var b := ColorRect.new()
		var h := 8.0 + i * 3.0
		b.position = Vector2(708 + i * 7, 398 - h)
		b.size = Vector2(5, h)
		b.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(b)
		bars.append(b)
	# start screen
	start = ColorRect.new()
	start.color = Color(0.027, 0.043, 0.094, 0.55)
	start.size = Vector2(768, 432)
	start.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(start)
	var title := _centered("CHUVA NA BR", 40, AMBER, 130, start)
	title.label_settings.shadow_offset = Vector2(3, 3)
	_centered("Sem pressa, sem game over.", 8, Color("e6e8ee"), 196, start)
	_centered("Só a estrada, o rádio e o limpador.", 8, Color("e6e8ee"), 212, start)
	_centered("ENTER OU CLIQUE: GIRAR A CHAVE", 16, AMBER, 250, start)
	_centered("SETAS DIRIGEM E AJUSTAM A VELOCIDADE - V CÂMERA - R RÁDIO", 8, LINE, 300, start)
	_centered("P PILOTO AUTOMÁTICO - B BUZINA - M SOM - F11 TELA CHEIA", 8, LINE, 316, start)
	set_values(0, 0, 0, "N", 0.8)

func _process(dt: float) -> void:
	if toast_t > 0.0:
		toast_t -= dt
		l_toast.modulate.a = clampf(toast_t / 0.4, 0.0, 1.0)

static func fmt(n: float) -> String:
	var s := "%06d" % mini(999999, int(n))
	return s.substr(0, 3) + "." + s.substr(3)

func set_values(score: float, hi: float, kmh: float, gear: String, fuel: float) -> void:
	l_score.text = "1P: " + fmt(score)
	l_hi.text = "HI-SCORE: " + fmt(maxf(hi, score))
	l_kmh.text = str(int(round(kmh)))
	l_gear.text = gear
	var n := int(ceil(fuel * 6.0))
	if n != _fuel:
		_fuel = n
		for i in 6:
			bars[i].color = (Color("f0484a") if n <= 1 else Color("3fae5a")) if i < n else Color("1a2547")

func toast(msg: String, dur := 2.6) -> void:
	l_toast.text = msg
	toast_t = dur

func set_now(txt: String) -> void:
	l_now.text = txt

func hide_start() -> void:
	start.visible = false

extends CanvasLayer
# Score, toast, now-playing strip and the speed/gear/fuel panel. The trip menu lives in menu.gd.

const AMBER := Color("f2a62a")
const LINE := Color("9bbbe0")
const PANEL := Color("0b1120")
var font: FontFile = preload("res://assets/fonts/Estrada2P.ttf")
var l_score: Label
var l_hi: Label
var l_toast: Label
var l_now: Label
var l_kmh: Label
var l_gear: Label
var bars: Array = []
var drive_nodes: Array = []
var now_clip: Control
var now_w := 0.0
var now_t := 0.0
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
	drive_nodes.append_array([l_score, l_hi])
	l_toast = _centered("", 16, AMBER, 74)   # below the rear-view mirror
	l_toast.modulate.a = 0.0
	_box(Rect2(-2, 408, 450, 26), 0, [0, 2, 2, 0])
	now_clip = Control.new()   # window the now-playing text scrolls through
	now_clip.position = Vector2(10, 415)
	now_clip.size = Vector2(428, 14)
	now_clip.clip_contents = true
	now_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(now_clip)
	l_now = _label("", 8, Color("e6e8ee"), Vector2(0, 2), now_clip, false)
	var n0 := get_child_count()
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
	for i in range(n0, get_child_count()):   # the speed panel only shows while driving
		drive_nodes.append(get_child(i))
	set_drive(false)
	set_values(0, 0, 0, "N", 0.8)

func _process(dt: float) -> void:
	if notice_t > 0.0:
		notice_t -= dt
		l_notice.modulate.a = clampf(notice_t / 0.6, 0.0, 1.0)
	if now_w > 0.0:   # marquee: pause at the start, then scroll and loop
		now_t += dt
		l_now.position.x = -floorf(fmod(maxf(0.0, now_t - 2.0) * 30.0, now_w))
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
	var gap := "      "
	var w := font.get_string_size(txt + gap, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
	now_t = 0.0
	l_now.position.x = 0.0
	if font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x > now_clip.size.x:
		now_w = w
		l_now.text = txt + gap + txt
	else:
		now_w = 0.0
		l_now.text = txt

# a discreet line over the radio strip, for things that shouldn't shout (new sticker, km milestone...)
var l_notice: Label
var notice_t := 0.0
func notice(txt: String, dur := 4.0) -> void:
	if l_notice == null:
		l_notice = _label("", 8, Color("ffd65a"), Vector2(10, 396), self, true)
	l_notice.text = txt
	notice_t = dur
	l_notice.modulate.a = 1.0

func set_drive(on: bool) -> void:
	for n in drive_nodes:
		n.visible = on
	if not on:
		toast_t = 0.0
		l_toast.modulate.a = 0.0

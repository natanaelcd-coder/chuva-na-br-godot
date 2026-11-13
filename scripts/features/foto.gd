extends Node
# Ideia 21: modo foto. F while driving freezes the frame (g.state = "foto"), hides the HUD and shows the
# framing with its caption. V swaps the inside/outside camera, L the frame (caption band, polaroid, clean),
# Enter takes the picture: a PNG in user://fotos/ with the caption (road, km, hour, weather, car, date).
# F or Esc goes back to the road. The last picture of the trip goes on the postcard (diario.gd).

const STYLES := ["LEGENDA", "POLAROID", "LIMPA"]
const KM0 := {"terra": 3, "br": 84, "expressa": 105}   # roadside km marker where the trip starts
const INK := Color("e6e8ee")
const DIM := Color("9bbbe0")

var g
var font: FontFile = preload("res://assets/fonts/Estrada2P.ttf")
var layer: CanvasLayer
var frame_root: Control
var hint: Label
var msg: Label
var flash: ColorRect
var active := false
var shooting := false
var style := 0
var msg_t := 0.0
var last_image: Image    # last picture of this trip
var last_path := ""
var n_trip := 0
var _seq := 0

func _ready() -> void:
	g = get_parent()
	style = clampi(int(g.store_get("fotos", "moldura", 0)), 0, STYLES.size() - 1)
	layer = CanvasLayer.new()
	layer.layer = 5
	layer.visible = false
	add_child(layer)
	frame_root = Control.new()
	frame_root.size = Vector2(768, 432)
	frame_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(frame_root)
	flash = ColorRect.new()
	flash.size = Vector2(768, 432)
	flash.color = Color(1, 1, 1, 0)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(flash)
	hint = _lbl("", 8, INK, Vector2(12, 10), layer, true)
	msg = _lbl("", 8, Color("ffd65a"), Vector2(12, 24), layer, true)
	g.trip_started.connect(func():
		last_image = null
		last_path = ""
		n_trip = 0)

func _lbl(txt: String, size: int, col: Color, pos: Vector2, parent: Node, shadow := false) -> Label:
	var l := Label.new()
	var ls := LabelSettings.new()
	ls.font = font
	ls.font_size = size
	ls.font_color = col
	if shadow:
		ls.shadow_color = Color.BLACK
		ls.shadow_offset = Vector2(1, 1)
	l.label_settings = ls
	l.text = txt
	l.position = pos
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	return l

func hour_text() -> String:
	var h := fposmod(14.0 + g.tday * 6.0, 24.0)
	return "%02d:%02d" % [int(h), int((h - int(h)) * 60.0)]

func date_text() -> String:
	var d := Time.get_date_dict_from_system()
	return "%02d/%02d/%d" % [d.day, d.month, d.year]

func km_marker() -> int:
	return int(KM0.get(g.cfg.road, 0) + g.km_trip)

func _sep() -> String:
	return "  ·  " if font.has_char(0xB7) else "  -  "

func caption() -> String:
	return _sep().join([g.road.name, "KM %d" % km_marker(), hour_text(), g.cfg.weather.to_upper(), g.car.name])

# ---- in and out
func drive_key(k: int) -> bool:
	if k != KEY_F or g.state != "drive" or not g.started:
		return false
	active = true
	g.state = "foto"
	g.hud.visible = false
	for p in [g.a_engine, g.a_rumble, g.a_hiss]:
		p.stream_paused = true
	_build_frame()
	_hint()
	msg.text = ""
	layer.visible = true
	return true

func _leave() -> void:
	active = false
	layer.visible = false
	g.state = "drive"
	g.hud.visible = true
	for p in [g.a_engine, g.a_rumble, g.a_hiss]:
		p.stream_paused = false

func _hint() -> void:
	hint.text = "MODO FOTO   ENTER: FOTOGRAFAR   V: CÂMERA   L: MOLDURA (%s)   F: SAIR" % STYLES[style]

func _input(ev: InputEvent) -> void:
	if not active:
		return
	if ev is InputEventKey and ev.pressed and not ev.echo:
		var k: int = ev.physical_keycode
		if k == KEY_F11:
			return
		get_viewport().set_input_as_handled()
		if shooting:
			return
		match k:
			KEY_F, KEY_ESCAPE:
				_leave()
			KEY_V:
				g.set_cam(1 - g.cam)
			KEY_L:
				style = (style + 1) % STYLES.size()
				g.store_set("fotos", "moldura", style)
				_build_frame()
				_hint()
			KEY_ENTER, KEY_KP_ENTER, KEY_SPACE:
				shoot()
	elif ev is InputEventMouseButton and ev.pressed:
		get_viewport().set_input_as_handled()
		if ev.button_index == MOUSE_BUTTON_LEFT and not shooting:
			shoot()

# the caption band or the polaroid border, over the frozen frame (they go into the picture)
func _build_frame() -> void:
	for c in frame_root.get_children():
		c.queue_free()
	match STYLES[style]:
		"LEGENDA":
			var band := ColorRect.new()
			band.color = Color(0.02, 0.03, 0.07, 0.72)
			band.position = Vector2(0, 404)
			band.size = Vector2(768, 28)
			frame_root.add_child(band)
			_lbl(caption(), 8, INK, Vector2(12, 414), frame_root)
			var d := _lbl(date_text(), 8, DIM, Vector2(0, 414), frame_root)
			d.size = Vector2(756, 10)
			d.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		"POLAROID":
			var paper := Color("e6e8ee")
			for r in [Rect2(0, 0, 768, 14), Rect2(0, 0, 14, 432), Rect2(754, 0, 14, 432), Rect2(0, 370, 768, 62)]:
				var b := ColorRect.new()
				b.color = paper
				b.position = r.position
				b.size = r.size
				frame_root.add_child(b)
			var sh := ColorRect.new()
			sh.color = Color(0, 0, 0, 0.25)
			sh.position = Vector2(14, 14)
			sh.size = Vector2(740, 2)
			frame_root.add_child(sh)
			_lbl("%s, %s" % [g.road.name, hour_text()], 16, Color("24345f"), Vector2(30, 382), frame_root)
			_lbl(_sep().join(["KM %d" % km_marker(), g.cfg.weather.to_upper(), g.car.name, date_text()]), 8, Color("4a4d57"), Vector2(32, 408), frame_root)

func shoot() -> void:
	shooting = true
	_build_frame()   # km and hour as they are now
	hint.visible = false
	msg.visible = false
	flash.color.a = 0.0
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	hint.visible = true
	msg.visible = true
	shooting = false
	last_image = img
	n_trip += 1
	g.store_set("fotos", "total", int(g.store_get("fotos", "total", 0)) + 1)
	var dir := ""
	if Engine.has_meta("foto_dir"):
		dir = Engine.get_meta("foto_dir")
	elif not Engine.has_meta("test_seed"):
		dir = "user://fotos"
	var name := "foto_%s_%d.png" % [Time.get_datetime_string_from_system().replace(":", "-").replace("T", "_"), _seq]
	_seq += 1
	if OS.has_feature("web"):
		JavaScriptBridge.download_buffer(img.save_png_to_buffer(), name, "image/png")
		msg.text = "FOTO BAIXADA: %s" % name.to_upper()
	elif dir != "":
		DirAccess.make_dir_recursive_absolute(dir)
		last_path = dir.path_join(name)
		if img.save_png(last_path) == OK:
			msg.text = "FOTO GUARDADA EM FOTOS/%s" % name.to_upper()
		else:
			last_path = ""
			msg.text = "NÃO DEU PARA GUARDAR A FOTO"
	else:
		msg.text = "FOTO TIRADA"
	g.store_save()
	msg_t = 3.0
	flash.color.a = 0.8

func _process(dt: float) -> void:
	if flash.color.a > 0.0:
		flash.color.a = maxf(0.0, flash.color.a - dt * 2.5)
	if msg_t > 0.0:
		msg_t -= dt
		if msg_t <= 0.0:
			msg.text = ""

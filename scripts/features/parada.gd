extends Node
# Ideia 15: parar de verdade. Slow down in the right lane at a stop (or press E near one) and the car pulls in:
# a still pixel-art scene of the venda / posto / loja da parada, rain on the awning, the radio low and muffled,
# a menu board that changes with the road and the hour, and a stamp in the passport of stops. Esc or
# SEGUIR VIAGEM puts you back on the road with a full tank. The drive is frozen meanwhile (g.state = "parada").

const FOODS := {   # id: [board name, short name for the diary, what the counter says, hot?]
	"cafe": ["CAFÉ NO COPO", "CAFÉ", "PASSADO NA HORA, NO COPO AMERICANO.", true],
	"pingado": ["PINGADO", "PINGADO", "CAFÉ COM LEITE NO COPO, PRA ACORDAR.", true],
	"pao_queijo": ["PÃO DE QUEIJO", "PÃO DE QUEIJO", "QUENTINHO, SAIU AGORA DO FORNO.", true],
	"pastel": ["PASTEL DE CARNE", "PASTEL", "ESTALANDO, DO TAMANHO DO PRATO.", true],
	"caldo_cana": ["CALDO DE CANA", "CALDO DE CANA", "MOÍDO NA HORA, COM LIMÃO.", false],
	"coxinha": ["COXINHA", "COXINHA", "COM CATUPIRY. A DE VERDADE.", true],
	"queijo_doce": ["QUEIJO COM DOCE", "QUEIJO COM DOCE", "QUEIJO DA ROÇA E DOCE DE LEITE NO PONTO.", false],
	"pamonha": ["PAMONHA", "PAMONHA", "DOCE, AINDA NA PALHA.", true],
	"bolo_fuba": ["BOLO DE FUBÁ", "BOLO DE FUBÁ", "COM ERVA-DOCE, IGUAL AO DE CASA.", false],
	"pao_chapa": ["PÃO NA CHAPA", "PÃO NA CHAPA", "COM MANTEIGA, BEM TOSTADINHO.", true],
	"caldinho": ["CALDINHO DE FEIJÃO", "CALDINHO", "COM TORRESMO E CHEIRO-VERDE.", true],
	"misto": ["MISTO QUENTE", "MISTO QUENTE", "O QUEIJO ESCORRENDO PELO LADO.", true],
	"agua_coco": ["ÁGUA DE COCO", "ÁGUA DE COCO", "GELADINHA, DIRETO DO COCO.", false],
	"milho": ["MILHO VERDE", "MILHO VERDE", "COZIDO, COM SAL E MANTEIGA.", true],
}
# what the board offers: per kind of stop, per hour (day, dusk, night, dawn)
const MENUS := {
	"venda": [["cafe", "pao_queijo", "queijo_doce", "pamonha", "bolo_fuba"], ["cafe", "pao_queijo", "bolo_fuba", "milho", "queijo_doce"],
		["cafe", "caldinho", "pao_queijo", "queijo_doce", "pamonha"], ["cafe", "pingado", "pao_queijo", "bolo_fuba", "queijo_doce"]],
	"posto": [["cafe", "pao_queijo", "pastel", "caldo_cana", "coxinha"], ["pastel", "caldo_cana", "coxinha", "cafe", "misto"],
		["cafe", "caldinho", "coxinha", "misto", "pao_queijo"], ["pingado", "pao_chapa", "cafe", "pao_queijo", "coxinha"]],
	"loja": [["cafe", "pao_queijo", "pao_chapa", "agua_coco", "coxinha"], ["cafe", "coxinha", "misto", "pastel", "agua_coco"],
		["cafe", "caldinho", "misto", "coxinha", "pao_queijo"], ["pingado", "pao_chapa", "cafe", "pao_queijo", "misto"]],
}
const KIND := {"terra": "venda", "br": "posto", "expressa": "loja"}
const PLACES := {"terra": ["VENDA DO ZÉ", "VENDA DO SEU ZICO"], "br": ["POSTO ESTRELA KM 87", "POSTO ESTRELA KM 132"],
	"expressa": ["PARADA EXPRESSA KM 112", "PARADA EXPRESSA KM 168"]}
const PREP := {"venda": "NA", "posto": "NO", "loja": "NA"}
const GREET := {   # [day, dusk, night, dawn]
	"venda": ["%s: VAI UM CAFEZINHO? ACABEI DE PASSAR.", "%s: CHEGOU NA HORA DO BOLO, SÔ.", "%s: ENTRA, QUE A NOITE TÁ FRESCA.", "%s: MADRUGOU, HEIN? O CAFÉ TÁ NO FOGO."],
	"posto": ["FRENTISTA: COMPLETA? ... PRONTO, TANQUE CHEIO!", "FRENTISTA: COMPLETA, CHEFE? JÁ ENCHI.", "FRENTISTA: BOA NOITE! TANQUE CHEIO, PODE DESCANSAR.", "FRENTISTA: ACORDADO ESSA HORA? COMPLETEI PRA VOCÊ."],
	"loja": ["ATENDENTE: BOM DIA! O CAFÉ SAI NA HORA.", "ATENDENTE: BOA TARDE! TEM MISTO SAINDO.", "ATENDENTE: BOA NOITE! O CALDINHO TÁ QUENTE.", "ATENDENTE: AQUI É 24 HORAS. FIQUE À VONTADE."],
}
const CAR_X := {"venda": 118.0, "posto": 114.0, "loja": 96.0}     # where your car sits in the forecourt
const ITEM_X := {"venda": 98.0, "posto": 140.0, "loja": 100.0}   # where what you ordered lands on the counter
const SIGN_COL := {"venda": Color("c22630"), "posto": Color("c22630"), "loja": Color("3fe0e8")}
const OUT := Rect2(12, 22, 252, 124)   # the view outside, in logical units (the scene PNG is clear there)
const AMBER := Color("f2a62a")
const INK := Color("e6e8ee")
const CHALK := Color("e6e8ee")
const CHALK_HI := Color("ffd65a")
const DIM := Color("9bbbe0")

var g
var font: FontFile = preload("res://assets/fonts/Estrada2P.ttf")
var layer: CanvasLayer
var art: Node2D
var ui: Node2D
var scenes := {}
var food_tex := {}
var active := false
var leaving := false
var fade := 0.0
var t := 0.0
var stop_i := -1
var kind := "posto"
var place := ""
var place_id := ""
var menu_ids: Array = []
var sel := 0
var ordered: Array = []
var stamp_t := -1.0
var visits := 1
var line1 := ""
var line2 := ""
var line3 := ""
var trip_stops: Array = []   # this trip: [{place, prep, foods: [ids]}], read by diario.gd
var music_db := 0.0
var lpf: AudioEffectLowPassFilter

func _ready() -> void:
	g = get_parent()
	for k in ["venda", "posto", "loja"]:
		scenes[k] = load("res://assets/sprites/parada_%s.png" % k)
	for id in FOODS:
		food_tex[id] = load("res://assets/sprites/lanche_%s.png" % id)
	layer = CanvasLayer.new()
	layer.layer = 4
	layer.visible = false
	add_child(layer)
	art = Node2D.new()
	art.scale = Vector2(2, 2)
	art.draw.connect(_draw_art)
	layer.add_child(art)
	ui = Node2D.new()
	ui.draw.connect(_draw_ui)
	layer.add_child(ui)
	lpf = AudioEffectLowPassFilter.new()
	lpf.cutoff_hz = 900.0
	g.seg_passed.connect(_on_seg)
	g.trip_started.connect(func(): trip_stops.clear())

func _hour() -> int:
	return int(floor(g.tday + 0.5)) % 4

# ---- getting in
func _on_seg(i: int) -> void:
	if not g.started or g.state != "drive" or active:
		return
	for p in g.postos:
		if posmod(p - i, g.N) == 300:
			var nm: String = PLACES[g.cfg.road][g.postos.find(p)]
			g.hud.notice("%s A 1 KM: ENCOSTE DEVAGAR À DIREITA OU APERTE ENTER PARA PARAR" % nm, 6.0)
	if g.postos.has(i) and g.px > g.LANES.back() - 0.42 and g.v < 35.0:
		if Engine.has_meta("test_seed") and not Engine.has_meta("feat_paradas"):
			return   # the regression bench drives slowly past stops: leave it alone
		enter.call_deferred(i)

func drive_key(k: int) -> bool:
	if not (k == KEY_ENTER or k == KEY_KP_ENTER) or not g.started or g.state != "drive":   # Q/E are the turn signals
		return false
	var cur: int = int(g.pos / g.SEG) % g.N
	for p in g.postos:
		if posmod(p - cur, g.N) < 340 or posmod(cur - p, g.N) < 25:
			enter(p)
			return true
	g.hud.notice("NENHUMA PARADA POR PERTO. ELAS TÊM PLACA: PARADA A 1 KM", 3.0)
	return false

func enter(p: int) -> void:
	if active or g.state != "drive":
		return
	active = true
	leaving = false
	g.state = "parada"
	stop_i = p
	kind = KIND.get(g.cfg.road, "posto")
	var idx: int = maxi(0, g.postos.find(p))
	place = PLACES[g.cfg.road][idx]
	place_id = "%s:%d" % [g.cfg.road, idx]
	menu_ids = MENUS[kind][_hour()].duplicate()
	if g.cfg.weather == "chuva" and menu_ids.has("agua_coco"):   # rain: something warm instead
		menu_ids[menu_ids.find("agua_coco")] = "caldinho" if not menu_ids.has("caldinho") else "pingado"
	sel = 0
	ordered.clear()
	fade = 0.0
	t = 0.0
	stamp_t = -0.5   # the stamp lands a moment after the scene fades in
	g.fuel = 1.0
	g.low_warn = false
	g.refueled.emit(p)
	var st: Dictionary = g.store_get("paradas", "carimbos", {})
	visits = int(st.get(place_id, 0)) + 1
	st[place_id] = visits
	g.store_set("paradas", "carimbos", st)
	g.store_save()
	trip_stops.append({"place": place, "prep": PREP[kind], "foods": []})
	line1 = GREET[kind][_hour()]
	if kind == "venda":
		line1 = line1 % ["SEU ZÉ", "SEU ZICO"][idx]
	line2 = ""
	var pas = g.get_node_or_null("passageiro")
	if pas and pas.has_method("parada_line"):
		line2 = pas.parada_line()
	line3 = "CARIMBO NOVO NO PASSAPORTE: %s" % place if visits == 1 else "%dª VISITA. JÁ CONHECEM VOCÊ POR AQUI." % visits
	g.hud.visible = false
	g._set_paused_audio(true)
	g.a_rain.stream_paused = false
	if g.rain > 0.05:
		g.a_rain.volume_db = linear_to_db(maxf(g.rain * 0.14, 0.0001))   # rain on the awning
	music_db = g.a_music.volume_db
	g.a_music.volume_db = music_db - 12.0
	if not _has_lpf():
		AudioServer.add_bus_effect(0, lpf)
	layer.visible = true

func _has_lpf() -> bool:
	for i in AudioServer.get_bus_effect_count(0):
		if AudioServer.get_bus_effect(0, i) == lpf:
			return true
	return false

# ---- inside
func order(id: String) -> void:
	ordered.append(id)
	var pr: Dictionary = g.store_get("paradas", "provados", {})
	var first := not pr.has(id)
	pr[id] = int(pr.get(id, 0)) + 1
	g.store_set("paradas", "provados", pr)
	g.store_save()
	trip_stops.back().foods.append(id)
	line2 = "%s: %s" % [FOODS[id][1], FOODS[id][2]]
	if first:
		line3 = "NOVO NO PASSAPORTE: %s (%d DE %d LANCHES)" % [FOODS[id][1], pr.size(), FOODS.size()]
	else:
		line3 = "%s DE NOVO. JÁ FORAM %d NA VIDA." % [FOODS[id][1], pr[id]]

func leave() -> void:
	if active and not leaving:
		leaving = true

func _finish() -> void:
	active = false
	leaving = false
	layer.visible = false
	g.state = "drive"
	g.hud.visible = true
	g.hud.set_drive(true)
	g._set_paused_audio(false)
	g.a_music.volume_db = music_db
	for i in range(AudioServer.get_bus_effect_count(0) - 1, -1, -1):
		if AudioServer.get_bus_effect(0, i) == lpf:
			AudioServer.remove_bus_effect(0, i)
	# back on the road from the forecourt: right lane, standing start, nobody on our bumper
	g.pos = fposmod((stop_i + 3) * g.SEG, g.TRACK)
	g.lane = g.road.ours.back()
	g.px = g.LANES[g.lane]
	g.cam_x = g.px
	g.hold_x = g.px
	g.press_lane = -1
	g.vx = 0.0
	g.v = 0.0
	g.overtaking = false
	for c in g.cars:
		if c.dir > 0:
			var d: float = fposmod(c.z - g.pos, g.TRACK)
			if d < 3000.0 or d > g.TRACK - 5000.0:
				c.z = fposmod(g.pos - randf_range(9000.0, 16000.0), g.TRACK)
	g.hud.notice("DE VOLTA À ESTRADA, TANQUE CHEIO. BOA VIAGEM!", 3.5)

func _input(ev: InputEvent) -> void:
	if not active:
		return
	if ev is InputEventKey and ev.pressed and not ev.echo:
		var k: int = ev.physical_keycode
		if k == KEY_F11:
			return
		get_viewport().set_input_as_handled()
		if leaving or fade < 0.5:
			return
		var n := menu_ids.size()
		match k:
			KEY_UP, KEY_W:
				sel = (sel + n) % (n + 1)
			KEY_DOWN, KEY_S:
				sel = (sel + 1) % (n + 1)
			KEY_ENTER, KEY_KP_ENTER, KEY_SPACE:
				if sel == n:
					leave()
				else:
					order(menu_ids[sel])
			KEY_ESCAPE, KEY_E:
				leave()
	elif ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT:
		get_viewport().set_input_as_handled()
		if not ev.pressed or leaving:
			return
		var r := _row_at(ev.position)
		if r >= 0:
			sel = r
			if r == menu_ids.size():
				leave()
			else:
				order(menu_ids[r])

func _row_at(p: Vector2) -> int:
	for r in menu_ids.size() + 1:
		if Rect2(544, _row_y(r) - 12, 188, 18).has_point(p):
			return r
	return -1

func _row_y(r: int) -> float:
	return 108.0 + r * 20.0 + (8.0 if r == menu_ids.size() else 0.0)

func _process(dt: float) -> void:
	if not active:
		return
	t += dt
	stamp_t += dt
	if leaving:
		fade -= dt / 0.35
		if fade <= 0.0:
			_finish()
			return
	else:
		fade = minf(1.0, fade + dt / 0.35)
	art.queue_redraw()
	ui.queue_redraw()

# ---- drawing: the outside (sky, road, your car, rain), the scene, what you ordered
func _draw_art() -> void:
	var o := OUT
	var bands := 14
	for b in bands:   # sky of this hour, down to the hills
		var k := float(b) / bands
		art.draw_rect(Rect2(o.position.x, o.position.y + k * 70.0, o.size.x, 70.0 / bands + 0.5), g.e_top.lerp(g.e_hor, k))
	for x in range(int(o.position.x), int(o.end.x), 2):
		var hh := 6.0 + 4.0 * sin(x * 0.05 + 1.0) + 2.0 * sin(x * 0.13)
		art.draw_rect(Rect2(x, 92.0 - hh, 2, hh + 1), g.e_hf)
	art.draw_rect(Rect2(o.position.x, 92, o.size.x, 54), g.e_gr)
	art.draw_rect(Rect2(o.position.x, 100, o.size.x, 14), g.e_road0)
	for x in range(int(o.position.x), int(o.end.x), 20):
		art.draw_rect(Rect2(x, 106.5, 9, 1), Color(g.e_line, 0.8))
	art.draw_rect(Rect2(o.position.x, 114, o.size.x, 32), g.e_road1.lerp(g.e_gr, 0.25))   # the forecourt
	if g.e_amb < 0.6:   # at night a car goes by now and then: two lights sliding along the road
		var lx := fmod(t * 90.0, 600.0) - 60.0
		if lx < o.end.x:
			art.draw_rect(Rect2(lx, 107, 3, 1.5), Color("fff3b0"))
			art.draw_rect(Rect2(lx + 10, 107, 3, 1.5), Color("fff3b0"))
	var ct: Texture2D = g.tex[g.car.player]
	var cx: float = CAR_X[kind]
	art.draw_rect(Rect2(cx + 2, 136, 48, 3), Color(0, 0, 0, 0.4))
	art.draw_texture_rect(ct, Rect2(cx, 101, 52, 37.4), false, Color(1, 1, 1, 1).lerp(Color(g.e_amb, g.e_amb, g.e_amb * 1.05), 0.35))
	if g.rain > 0.05:   # rain outside, and drips off the awning edge
		var n := int(40 * g.rain)
		for i in n:
			var sx := o.position.x + fmod(i * 47.3 + t * 30.0, o.size.x)
			var sy := o.position.y + fmod(i * 23.7 + t * 170.0, o.size.y)
			art.draw_line(Vector2(sx, sy), Vector2(sx - 1.2, sy + 5), Color(0.66, 0.78, 0.9, 0.55), 0.5)
		for x in range(int(o.position.x) + 6, int(o.end.x), 12):
			var ph := fmod(t * 1.3 + x * 0.37, 1.0)
			art.draw_rect(Rect2(x, 22 + ph * ph * 120.0, 0.5, 2.5), Color(0.8, 0.88, 0.95, 0.8))
	art.draw_texture_rect(scenes[kind], Rect2(0, 0, 384, 216), false)
	var shown: Array = ordered.slice(maxi(0, ordered.size() - 3))
	for k in shown.size():
		var id: String = shown[k]
		var x: float = ITEM_X[kind] + k * 22.0
		art.draw_texture_rect(food_tex[id], Rect2(x, 126, 32, 24), false)
		if FOODS[id][3]:   # steam
			for s in 3:
				var ph := fmod(t * 0.6 + s * 0.33 + k * 0.2, 1.0)
				art.draw_rect(Rect2(x + 13 + s * 3 + sin(t * 2.0 + s + ph * 5.0) * 1.5, 124 - ph * 16.0, 1, 1), Color(0.9, 0.92, 0.95, 0.6 * (1.0 - ph)))

func _text(s: String, pos: Vector2, size: int, col: Color, shadow := true) -> void:
	if shadow:
		ui.draw_string(font, pos + Vector2(1, 1) * (size / 8.0), s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color(0, 0, 0, 0.8))
	ui.draw_string(font, pos, s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)

func _ctext(s: String, cx: float, y: float, size: int, col: Color, shadow := true) -> void:
	_text(s, Vector2(roundf(cx - font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x / 2.0), y), size, col, shadow)

func _draw_ui() -> void:
	# the stop's name painted on the sign over the counter
	var nm_size := 16 if font.get_string_size(place, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x < 500 else 8
	_ctext(place, 384, 28 if nm_size == 16 else 24, nm_size, SIGN_COL[kind], false)
	# the board, in chalk
	var hours := fposmod(14.0 + g.tday * 6.0, 24.0)
	_text("HOJE TEM", Vector2(552, 82), 8, CHALK_HI, false)
	_text("%02dH%02d" % [int(hours), int((hours - int(hours)) * 60.0)], Vector2(680, 82), 8, Color(CHALK, 0.6), false)
	ui.draw_rect(Rect2(552, 88, 168, 1), Color(CHALK, 0.35))
	for r in menu_ids.size() + 1:
		var on := r == sel
		var label: String = "SEGUIR VIAGEM" if r == menu_ids.size() else FOODS[menu_ids[r]][0]
		var col := CHALK_HI if on else (Color(CHALK, 0.85) if r < menu_ids.size() else DIM)
		if r < menu_ids.size() and ordered.has(menu_ids[r]) and not on:
			col = Color(CHALK, 0.55)
		var y := _row_y(r)
		_text(label, Vector2(560, y), 8, col, false)
		if on:
			_text(">", Vector2(550, y), 8, CHALK_HI, false)
	# the counter front: what people say, and how to use the place
	ui.draw_rect(Rect2(12, 326, 744, 98), Color(0.02, 0.03, 0.07, 0.72))
	ui.draw_rect(Rect2(12, 326, 744, 2), Color(AMBER, 0.6))
	_text(line1, Vector2(26, 348), 8, INK)
	var desc := line2
	if sel < menu_ids.size() and ordered.is_empty() and line2 == "":
		desc = FOODS[menu_ids[sel]][2]
	_text(desc, Vector2(26, 366), 8, Color("cfe0f2"))
	_text(line3, Vector2(26, 384), 8, Color("ffd65a"))
	var pr: Dictionary = g.store_get("paradas", "provados", {})
	var st: Dictionary = g.store_get("paradas", "carimbos", {})
	_text("SETAS: ESCOLHER   ENTER: PEDIR   ESC: VOLTAR PRA ESTRADA", Vector2(26, 410), 8, DIM)
	var pas := "PASSAPORTE: %d/6 LUGARES  %d/%d LANCHES" % [st.size(), pr.size(), FOODS.size()]
	_text(pas, Vector2(742 - font.get_string_size(pas, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x, 348), 8, Color(DIM, 0.9))
	# the stamp lands on the window and stays there
	if stamp_t > 0.0:
		var k := clampf(stamp_t / 0.22, 0.0, 1.0)
		var s := lerpf(1.8, 1.0, k * k)
		var ink := Color("c22630") if visits == 1 else Color("3d5f94")
		ink.a = 0.85 * k
		var c := Vector2(150, 118)
		ui.draw_set_transform(c, -0.12, Vector2(s, s))
		var w := maxf(150.0, font.get_string_size(place, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x + 24.0)
		var r := Rect2(-w / 2.0, -30, w, 60)
		ui.draw_rect(Rect2(r.position - Vector2(3, 3), r.size + Vector2(6, 6)), Color(0.95, 0.81, 0.65, 0.88 * k))
		ui.draw_rect(r, ink, false, 2.0)
		ui.draw_rect(r.grow(-4), ink, false, 1.0)
		var d := Time.get_date_dict_from_system()
		for row in [["PASSAPORTE DE PARADAS", -14.0], [place, 2.0], ["%02d/%02d/%d  VISITA %d" % [d.day, d.month, d.year, visits], 18.0]]:
			var tw := font.get_string_size(row[0], HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
			ui.draw_string(font, Vector2(-tw / 2.0, row[1] + 4.0), row[0], HORIZONTAL_ALIGNMENT_LEFT, -1, 8, ink)
		ui.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if fade < 1.0:
		ui.draw_rect(Rect2(0, 0, 768, 432), Color(0.02, 0.03, 0.07, 1.0 - fade))

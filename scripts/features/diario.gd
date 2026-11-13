extends Node
# Ideia 22: diário de bordo e cartão-postal. Back at the menu after a trip (trip_ended), a postcard: the last
# photo of the trip (foto.gd) or an illustrated card of the road under that trip's sky, and on the back the
# summary: km, time, potholes taken and dodged, the stops and what you ate, the passenger's nap, a phrase of
# the day. Every trip goes into the diary (DIÁRIO in the main menu), with the passport of stops on a second page.

const Cat = preload("res://scripts/catalog.gd")
const AMBER := Color("f2a62a")
const INK := Color("e6e8ee")
const DIM := Color("6f86a8")
const LINE := Color("9bbbe0")
const CARD := Color("f3cfa6")
const BROWN := Color("4a2d1c")
const RED := Color("c22630")
const MAX_TRIPS := 80
const ROWS := 13

var g
var font: FontFile = preload("res://assets/fonts/Estrada2P.ttf")
var layer: CanvasLayer
var card: Node2D
var shown := {}           # the entry on the postcard
var photo: Texture2D
var postal := {}
var missed := 0
var page := 0             # diary: 0 trips, 1 passport
var sel := 0
var top := 0
var body: Control

func _ready() -> void:
	g = get_parent()
	for r in ["terra", "br", "expressa"]:
		postal[r] = load("res://assets/sprites/postal_%s.png" % r)
	layer = CanvasLayer.new()
	layer.layer = 6
	layer.visible = false
	add_child(layer)
	card = Node2D.new()
	card.draw.connect(_draw_card)
	layer.add_child(card)
	g.menu.add_main_item("DIÁRIO", open_diary)
	g.trip_started.connect(func(): missed = 0)
	g.hole_missed.connect(func(_f, d): if absf(d) < 0.5 and g.started: missed += 1)
	g.trip_ended.connect(_on_trip_ended)

func trips() -> Array:
	var a = g.store_get("diario", "viagens", [])
	return a if a is Array else []

# ---- end of a trip: write it down and show the postcard
func _on_trip_ended(s: Dictionary) -> void:
	var par = g.get_node_or_null("parada")
	var pas = g.get_node_or_null("passageiro")
	var fot = g.get_node_or_null("foto")
	var stops: Array = par.trip_stops.duplicate(true) if par else []
	if s.km < 0.1 and s.minutes < 0.5 and stops.is_empty():
		return   # just a peek at the road: nothing to remember yet
	var e := {
		"date": fot.date_text() if fot else "", "hour": fot.hour_text() if fot else "",
		"car": s.car, "road": s.road, "weather": s.weather, "time": s.time, "tday": g.tday,
		"km": snappedf(s.km, 0.1), "min": int(round(s.minutes)), "holes": s.holes, "missed": missed,
		"puddles": s.puddles, "bumps": s.bumps, "stops": stops,
		"comp": pas.diary_line() if pas else "", "photos": fot.n_trip if fot else 0,
		"photo": fot.last_path if fot else "",
	}
	e.frase = _frase(e)
	var a := trips()
	a.insert(0, e)
	if a.size() > MAX_TRIPS:
		a.resize(MAX_TRIPS)
	g.store_set("diario", "viagens", a)
	g.store_save()
	var img: Image = fot.last_image if fot and fot.n_trip > 0 else null
	show_card(e, img)

func _frase(e: Dictionary) -> String:
	var f: Array = []
	if e.weather == "chuva":
		f.append_array(["CHUVA NO VIDRO, CAFÉ NO COPO. DIA BOM.", "O LIMPADOR TRABALHOU MAIS QUE EU HOJE.", "NADA COMO O BARULHO DA CHUVA NA LATARIA."])
	else:
		f.append_array(["SOL NA JANELA E A ESTRADA INTEIRA PELA FRENTE.", "BRAÇO PRA FORA DA JANELA, VENTO NA CARA."])
	match int(floor(float(e.tday) + 0.5)) % 4:
		1: f.append("O CÉU FICOU LARANJA BEM NA HORA DA CURVA.")
		2: f.append("A LUA FOI JUNTO O CAMINHO TODO.")
		3: f.append("VI O DIA NASCER DE DENTRO DO CARRO.")
	match e.road:
		"terra": f.append("LAMA ATÉ O PARA-CHOQUE, SORRISO ATÉ A ORELHA." if e.weather == "chuva" else "POEIRA NO CARRO É LEMBRANÇA DA ROÇA.")
		"br": f.append("CAMINHONEIRO BUZINOU DE VOLTA. AMIZADE DE ESTRADA.")
		"expressa": f.append("NA EXPRESSA ATÉ O PENSAMENTO ANDA LISO.")
	if e.holes == 0 and e.km >= 1.0:
		return "NENHUM BURACO! A SUSPENSÃO AGRADECE."
	if String(e.comp).contains("DORMIU"):
		f.append("A VÓ DORMIU QUE NEM UM ANJO." if String(e.comp).begins_with("A VÓ") else "O CARAMELO SONHOU COM COXINHA.")
	for st in e.stops:
		if st.foods.size() > 0:
			f.append("%s: VALEU A VIAGEM." % _food_short(st.foods[0]))
	return f.pick_random()

func _food_short(id: String) -> String:
	var par = g.get_node_or_null("parada")
	return par.FOODS[id][1] if par and par.FOODS.has(id) else id.to_upper()

func _num(x: float) -> String:
	return ("%.1f" % x).replace(".", ",")

func summary_lines(e: Dictionary) -> Array:
	var out: Array = []
	out.append("%s KM EM %d MIN" % [_num(e.km), e.min])
	if e.holes > 0 or e.missed > 0:
		out.append("%d BURACO%s, %d DESVIADO%s" % [e.holes, "" if e.holes == 1 else "S", e.missed, "" if e.missed == 1 else "S"])
	else:
		out.append("NENHUM BURACO NO CAMINHO")
	if e.puddles > 0:
		out.append("%d POÇA%s ESPIRRADA%s" % [e.puddles, "" if e.puddles == 1 else "S", "" if e.puddles == 1 else "S"])
	for st in e.stops:
		if st.foods.is_empty():
			out.append("PAROU %s %s PRA ESTICAR AS PERNAS" % [st.prep, st.place])
		else:
			var names: Array = []
			for id in st.foods:
				var n := _food_short(id)
				if not names.has(n):
					names.append(n)
			var lst: String = ", ".join(names.slice(0, names.size() - 1)) + " E " + names.back() if names.size() > 1 else names[0]
			out.append("%s %s %s" % [lst, st.prep, st.place])
	if e.stops.is_empty():
		out.append("SEM PARADAS DESTA VEZ")
	if e.comp != "":
		out.append(e.comp)
	if e.photos > 0:
		out.append("%d FOTO%s" % [e.photos, "" if e.photos == 1 else "S"])
	return out

func show_card(e: Dictionary, img: Image = null) -> void:
	shown = e
	photo = null
	if img == null and String(e.get("photo", "")) != "" and FileAccess.file_exists(e.photo):
		img = Image.load_from_file(e.photo)
	if img:
		photo = ImageTexture.create_from_image(img)
	layer.visible = true
	card.queue_redraw()

func _input(ev: InputEvent) -> void:
	if not layer.visible:
		return
	if ev is InputEventKey and ev.pressed and not ev.echo:
		if ev.physical_keycode == KEY_F11:
			return
		get_viewport().set_input_as_handled()
		if ev.physical_keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE, KEY_ESCAPE]:
			layer.visible = false
	elif ev is InputEventMouseButton and ev.pressed:
		get_viewport().set_input_as_handled()
		layer.visible = false

# ---- the postcard, in screen pixels
func _text(s: String, pos: Vector2, size: int, col: Color) -> void:
	card.draw_string(font, pos, s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)

func _wrap(s: String, chars: int) -> Array:
	var out: Array = []
	var cur := ""
	for w in s.split(" "):
		if cur != "" and (cur + " " + w).length() > chars:
			out.append(cur)
			cur = w
		else:
			cur = w if cur == "" else cur + " " + w
	if cur != "":
		out.append(cur)
	return out

func _draw_card() -> void:
	var e := shown
	if e.is_empty():
		return
	card.draw_rect(Rect2(0, 0, 768, 432), Color(0.02, 0.03, 0.07, 0.78))
	var c := Rect2(32, 30, 704, 362)
	card.draw_rect(Rect2(c.position + Vector2(6, 6), c.size), Color(0, 0, 0, 0.5))
	card.draw_rect(c, CARD)
	card.draw_rect(c, Color("c68a5a"), false, 2.0)
	# the picture: the trip's last photo, or the road's postcard under that trip's sky
	var pic := Rect2(48, 46, 384, 216)
	card.draw_rect(pic.grow(4), INK)
	if photo:
		card.draw_texture_rect(photo, pic, false)
	else:
		var ti := 0 if e.time == "ciclo" else Cat.TIME_IDS.find(e.time)
		var sk: Dictionary = Cat.SKIES[e.weather][clampi(ti, 0, 3)]
		for b in 24:
			card.draw_rect(Rect2(pic.position.x, pic.position.y + b * 6, pic.size.x, 6), Color(sk.top).lerp(Color(sk.hor), b / 20.0))
		card.draw_texture_rect(postal.get(e.road, postal.br), pic, false, Color(1, 1, 1).lerp(Color(sk.amb, sk.amb, sk.amb), 0.4) if sk.amb < 0.9 else Color.WHITE)
		if e.weather == "chuva":
			for i in 70:
				var x := pic.position.x + fmod(i * 53.7, pic.size.x - 6)
				var y := pic.position.y + fmod(i * 31.3, pic.size.y - 12)
				card.draw_line(Vector2(x, y), Vector2(x - 2, y + 8), Color(0.75, 0.84, 0.95, 0.5), 1.0)
	var road_name: String = Cat.ROADS[e.road].name
	_text({"terra": "LEMBRANÇA DO SÍTIO", "br": "LEMBRANÇA DA BR-116", "expressa": "LEMBRANÇA DA EXPRESSA"}.get(e.road, road_name), Vector2(48, 296), 16, RED)
	_text("%s  %s  %s" % [e.date, Cat.TIMES[e.time].name, Cat.WEATHER[e.weather].name], Vector2(48, 320), 8, BROWN)
	_text(Cat.CARS[e.car].name, Vector2(48, 336), 8, BROWN)
	var fr := _wrap("\"%s\"" % e.frase, 46)
	for i in fr.size():
		_text(fr[i], Vector2(48, 360 + i * 14), 8, Color("7a1620"))
	# back of the card: stamp, postmark, lines
	card.draw_line(Vector2(448, 50), Vector2(448, 376), Color("c68a5a"), 1.0)
	var st := Rect2(652, 44, 64, 76)
	card.draw_rect(st, INK)
	for k in 9:   # perforations
		card.draw_circle(Vector2(st.position.x + 4 + k * 7, st.position.y), 2.0, CARD)
		card.draw_circle(Vector2(st.position.x + 4 + k * 7, st.end.y), 2.0, CARD)
	card.draw_rect(st.grow(-5), Color("3d5f94"))
	card.draw_rect(Rect2(st.position.x + 5, st.position.y + 46, 54, 25), Color("23743f"))
	var ptex: Texture2D = g.tex[Cat.CARS[e.car].player]
	card.draw_texture_rect(ptex, Rect2(st.position.x + 8, st.position.y + 22, 48, 34.5), false)
	card.draw_string(font, Vector2(st.position.x + 8, st.position.y + 16), "R$1", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color("ffd65a"))
	var pm := Vector2(616, 92)
	card.draw_arc(pm, 30.0, 0.0, TAU, 40, Color(BROWN, 0.6), 2.0)
	card.draw_arc(pm, 24.0, 0.0, TAU, 40, Color(BROWN, 0.6), 1.0)
	var dt := String(e.date).substr(0, 5)
	card.draw_string(font, pm + Vector2(-font.get_string_size(dt, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x / 2.0, 4), dt, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(BROWN, 0.7))
	for k in 3:
		var y := pm.y - 12 + k * 12
		var pts := PackedVector2Array()
		for x in range(470, 586, 4):
			pts.append(Vector2(x, y + sin(x * 0.18) * 2.0))
		card.draw_polyline(pts, Color(BROWN, 0.45), 1.0)
	var y := 150.0
	for ln in summary_lines(e):
		for w in _wrap(ln, 32):
			if y > 372.0:
				break
			card.draw_line(Vector2(464, y + 4), Vector2(720, y + 4), Color("c68a5a", 0.6), 1.0)
			_text(w, Vector2(464, y), 8, BROWN)
			y += 16.0
	var hint := "ENTER: FECHAR  ·  GUARDADO NO DIÁRIO" if font.has_char(0xB7) else "ENTER: FECHAR  -  GUARDADO NO DIÁRIO"
	card.draw_string(font, Vector2(384 - font.get_string_size(hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x / 2.0, 416), hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, LINE)

# ---- DIÁRIO in the main menu: trips, and the passport of stops
func open_diary() -> void:
	page = 0
	sel = 0
	top = 0
	g.menu.open_screen("DIÁRIO DE BORDO", _build, _key)

func _key(k: int) -> void:
	var n := trips().size()
	match k:
		KEY_LEFT, KEY_A, KEY_RIGHT, KEY_D, KEY_TAB:
			page = 1 - page
		KEY_UP, KEY_W:
			sel = maxi(0, sel - 1)
		KEY_DOWN, KEY_S:
			sel = mini(maxi(0, n - 1), sel + 1)
		KEY_ENTER, KEY_KP_ENTER, KEY_SPACE:
			if page == 0 and n > 0:
				show_card(trips()[sel])
			return
		_:
			return
	top = clampi(top, sel - ROWS + 1, sel)
	_build(body)

func _build(b: Control) -> void:
	body = b
	for c in b.get_children():
		c.queue_free()
	var m = g.menu
	m.label("VIAGENS", 8, AMBER if page == 0 else DIM, Vector2(0, 0), b)
	m.label("PASSAPORTE DE PARADAS", 8, AMBER if page == 1 else DIM, Vector2(80, 0), b)
	m.label("SETAS: TROCAR DE PÁGINA E ESCOLHER", 8, DIM, Vector2(400, 0), b)
	m.box(Rect2(0, 14, 688, 1), Color(LINE, 0.4), b)
	if page == 0:
		_page_trips(b)
	else:
		_page_passport(b)

func _page_trips(b: Control) -> void:
	var m = g.menu
	var a := trips()
	if a.is_empty():
		m.label("NENHUMA VIAGEM AINDA.", 16, INK, Vector2(0, 40), b)
		m.label("PEGUE A ESTRADA: NA VOLTA, O CARTÃO-POSTAL FICA GUARDADO AQUI.", 8, LINE, Vector2(0, 70), b)
		return
	var km := 0.0
	var stops := 0
	for e in a:
		km += float(e.get("km", 0.0))
		stops += e.get("stops", []).size()
	m.label("%d VIAGENS   %s KM   %d PARADAS   %d FOTOS" % [a.size(), _num(km), stops, int(g.store_get("fotos", "total", 0))], 8, LINE, Vector2(0, 26), b)
	for r in range(top, mini(a.size(), top + ROWS)):
		var e: Dictionary = a[r]
		var on := r == sel
		var y := 46 + (r - top) * 20
		var txt := "%s  %-16s %-6s %-11s %6s KM %4d MIN" % [String(e.date).substr(0, 5), Cat.ROADS[e.road].name, Cat.WEATHER[e.weather].name,
			Cat.TIMES[e.time].name, _num(e.km), e.min]
		m.label(("> " if on else "  ") + txt, 8, AMBER if on else INK, Vector2(0, y), b)
		if e.get("stops", []).size() > 0:
			m.label("PARADA", 8, Color("ffd65a") if on else DIM, Vector2(630, y), b)
	m.label("ENTER: VER O CARTÃO-POSTAL", 8, DIM, Vector2(0, 318), b)

func _page_passport(b: Control) -> void:
	var m = g.menu
	var par = g.get_node_or_null("parada")
	if par == null:
		return
	var st: Dictionary = g.store_get("paradas", "carimbos", {})
	var pr: Dictionary = g.store_get("paradas", "provados", {})
	m.label("LUGARES %d/6" % st.size(), 8, LINE, Vector2(0, 26), b)
	var roads := ["terra", "br", "expressa"]
	for ri in 3:
		for k in 2:
			var id := "%s:%d" % [roads[ri], k]
			var r := Rect2(ri * 230, 42 + k * 62, 216, 52)
			var v := int(st.get(id, 0))
			var ink := RED if v > 0 else Color(DIM, 0.5)
			for e in [Rect2(r.position, Vector2(r.size.x, 2)), Rect2(r.position + Vector2(0, r.size.y - 2), Vector2(r.size.x, 2)),
					Rect2(r.position, Vector2(2, r.size.y)), Rect2(r.position + Vector2(r.size.x - 2, 0), Vector2(2, r.size.y))]:
				m.box(e, ink, b)
			if v > 0:
				m.label(par.PLACES[roads[ri]][k], 8, Color("f0484a"), r.position + Vector2(10, 12), b)
				m.label("%d VISITA%s" % [v, "" if v == 1 else "S"], 8, INK, r.position + Vector2(10, 30), b)
			else:
				m.label("? ? ?", 8, Color(DIM, 0.8), r.position + Vector2(10, 12), b)
				m.label(Cat.ROADS[roads[ri]].name, 8, Color(DIM, 0.8), r.position + Vector2(10, 30), b)
	m.label("LANCHES %d/%d" % [pr.size(), par.FOODS.size()], 8, LINE, Vector2(0, 176), b)
	var ids: Array = par.FOODS.keys()
	var fav := ""
	var best := 0
	for i in ids.size():
		var id: String = ids[i]
		var tr := TextureRect.new()
		tr.texture = par.food_tex[id]
		tr.position = Vector2((i % 7) * 98, 192 + (i / 7) * 66)
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if not pr.has(id):
			tr.modulate = Color(0, 0, 0, 0.45)
		b.add_child(tr)
		if pr.has(id):
			m.label("x%d" % pr[id], 8, INK, tr.position + Vector2(66, 36), b)
			if int(pr[id]) > best:
				best = int(pr[id])
				fav = par.FOODS[id][1]
	if fav != "":
		m.label("O PREFERIDO: %s" % fav, 8, Color("ffd65a"), Vector2(200, 176), b)

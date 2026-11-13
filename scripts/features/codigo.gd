extends Node
# Trip code (brainstorm idea 24): every trip has a short readable code, ROAD-CAR-WEATHER-TIME-SEED
# ("SITIO-PICAPE-SOL-DIA-4821"), that rebuilds the same road, scenery and traffic with the same options.
# Shown in the pause and on the end-of-trip card; the "CÓDIGO" screen in the menu takes one and leaves.
# On the web build, ?viagem=<code> in the address opens that trip.
# Other features: get_node("../codigo").current() / .code_for(cfg, seed) / .parse(text) / .start(cfg, seed)

const Cat = preload("res://scripts/catalog.gd")
const AMBER := Color("f2a62a")
const INK := Color("e6e8ee")
const DIM := Color("6f86a8")
const LINE := Color("9bbbe0")
const ROAD := {"terra": "SITIO", "br": "BR116", "expressa": "EXPRESSA"}
const CAR := {"besouro": "BESOURO", "picape": "PICAPE", "gt": "GT"}
const WEATHER := {"sol": "SOL", "chuva": "CHUVA"}
const TIME := {"dia": "DIA", "entardecer": "TARDE", "noite": "NOITE", "ciclo": "CICLO"}
const KEYCH := {KEY_MINUS: "-", KEY_KP_SUBTRACT: "-", KEY_SPACE: "-"}

var g
var typed := ""
var msg := ""
var l_input: Label
var l_msg: Label
var l_pause: Label
var last_code := ""
var _blink := 0.0

func _ready() -> void:
	g = get_parent()
	g.trip_ended.connect(_on_trip_ended)
	_late_ready.call_deferred()

func _late_ready() -> void:
	g.menu.add_main_item("CÓDIGO", open)
	l_pause = g.menu.label("", 8, LINE, Vector2(0, 418), g.menu.pause_root)
	l_pause.size = Vector2(768, 10)
	l_pause.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if OS.has_feature("web"):   # a shared link: ?viagem=SITIO-PICAPE-SOL-DIA-4821
		var q = JavaScriptBridge.eval("new URLSearchParams(window.location.search).get('viagem') || ''")
		if q is String and q != "":
			var p := parse(q)
			if not p.is_empty():
				start(p.cfg, p.seed, false)

# ---- the code itself
func code_for(cfg: Dictionary, s: int) -> String:
	return "%s-%s-%s-%s-%04d" % [ROAD[cfg.road], CAR[cfg.car], WEATHER[cfg.weather], TIME[cfg.time], s]

func current() -> String:
	return code_for(g.cfg, g.trip_seed)

# reads a code in any order and any case; returns {cfg, seed} or {} if something is missing
func parse(text: String) -> Dictionary:
	var t := text.strip_edges().to_upper().replace("BR-116", "BR116").replace("Í", "I").replace("Ã", "A")
	for ch in [" ", "_", ".", "/", ","]:
		t = t.replace(ch, "-")
	var cfg := {}
	var s := -1
	for tok in t.split("-", false):
		if tok.is_valid_int():
			s = int(tok)
			continue
		for pair in [["road", ROAD], ["car", CAR], ["weather", WEATHER], ["time", TIME]]:
			for id in pair[1]:
				if pair[1][id] == tok or (pair[0] == "time" and tok == "ENTARDECER" and id == "entardecer"):
					cfg[pair[0]] = id
	if cfg.size() < 4 or s < 1 or s > 99999:
		return {}
	return {"cfg": cfg, "seed": s}

# rebuild that trip; leave the menu right away if asked
func start(cfg: Dictionary, s: int, go := true) -> void:
	if g.started:
		g.to_menu()
	for k in cfg:
		g.cfg[k] = cfg[k]
	g._save_cfg()
	g.next_seed = s
	g.setup()
	if g.menu.screen_open():
		g.menu.close_screen()
	g.menu.show_main()
	if go:
		g.begin()

# ---- pause line and end-of-trip card
func _process(dt: float) -> void:
	if l_pause and g.menu.pause_root.visible:
		l_pause.text = "CÓDIGO: " + current()
		var fr: Control = g.menu.pause_frame
		l_pause.position.y = minf(fr.position.y + fr.size.y + 8.0, 404.0)   # just under the pause box
	if l_input and is_instance_valid(l_input) and l_input.is_visible_in_tree():
		_blink += dt
		l_input.text = typed + ("_" if fmod(_blink, 1.0) < 0.6 else " ")

func _on_trip_ended(summary: Dictionary) -> void:
	summary["code"] = current()   # dictionaries are shared: features connected after this one see it
	last_code = summary.code
	_card.call_deferred(summary)

func _card(s: Dictionary) -> void:
	if g.state != "menu" or g.menu.screen_open() or s.get("minutes", 0.0) < 0.2:
		return
	if g.get_node_or_null("diario") != null:   # the logbook's postcard already shows the code: one card is enough
		return
	g.menu.open_screen("FIM DA VIAGEM", _build_card.bind(s), _card_key)

func _card_key(k: int) -> void:
	if k == KEY_ENTER or k == KEY_KP_ENTER or k == KEY_SPACE:
		g.menu.close_screen()

func _build_card(body: Control, s: Dictionary) -> void:
	var m = g.menu
	var title := "%s  ·  %s  ·  %s  ·  %s" % [Cat.CARS[s.car].name, Cat.ROADS[s.road].name, Cat.WEATHER[s.weather].name, Cat.TIMES[s.time].name]
	m.label(title, 8, LINE, Vector2(0, 0), body)
	var km: float = s.get("km", 0.0)
	var mins := int(round(s.get("minutes", 0.0)))
	var tm := ("%d MIN" % mins) if mins > 0 else "MENOS DE 1 MIN"
	m.label("%s KM  ·  %s" % [("%.1f" % km).replace(".", ","), tm], 16, INK, Vector2(0, 26), body)
	var lines: Array = []
	var man: Dictionary = s.get("manobras", {})
	var between: int = man.get("ENTRE AS RODAS", 0)
	lines.append("BURACOS: %d%s" % [s.get("holes", 0), (" (MAIS %d ENTRE AS RODAS)" % between) if between > 0 else ""])
	if s.weather == "chuva":
		lines.append("POÇAS: %d" % s.get("puddles", 0))
	lines.append("ESBARRÕES: %d" % s.get("bumps", 0) if s.get("bumps", 0) > 0 else "NENHUM ESBARRÃO")
	for k in man:
		if k != "ENTRE AS RODAS" and man[k] > 0:
			lines.append("%s: %d" % [k, man[k]])
	var y := 62
	for ln in lines:
		m.label(ln, 8, INK, Vector2(0, y), body)
		y += 16
	m.box(Rect2(0, 236, 688, 2), Color(LINE, 0.4), body)
	m.label("CÓDIGO DA VIAGEM", 8, DIM, Vector2(0, 250), body)
	m.label(s.get("code", ""), 16, AMBER, Vector2(0, 266), body)
	m.label("PASSE O CÓDIGO A QUEM QUISER FAZER A MESMA ESTRADA (MENU > CÓDIGO).", 8, DIM, Vector2(0, 296), body)
	m.label("ENTER OU ESC: FECHAR", 8, DIM, Vector2(0, 312), body)

# ---- the screen to type a code
func open() -> void:
	typed = ""
	msg = ""
	g.menu.open_screen("CÓDIGO DA VIAGEM", _build, _key)

func _build(body: Control) -> void:
	var m = g.menu
	m.label("DIGITE O CÓDIGO DE UMA VIAGEM PARA FAZER A MESMA ESTRADA, COM O MESMO", 8, INK, Vector2(0, 0), body)
	m.label("TRÂNSITO, CARRO, CLIMA E HORA. EX.: SITIO-PICAPE-SOL-DIA-4821", 8, INK, Vector2(0, 14), body)
	m.box(Rect2(0, 40, 688, 34), Color("05070c"), body)
	l_input = m.label("", 16, AMBER, Vector2(12, 49), body)
	l_msg = m.label("", 8, LINE, Vector2(0, 84), body)
	m.label("CÓDIGO DA VIAGEM ATUAL", 8, DIM, Vector2(0, 120), body)
	m.label(current(), 16, INK, Vector2(0, 136), body)
	if last_code != "" and last_code != current():
		m.label("ÚLTIMA VIAGEM FEITA", 8, DIM, Vector2(0, 170), body)
		m.label(last_code, 16, INK, Vector2(0, 186), body)
	m.label("BACKSPACE APAGA   CTRL+V COLA   CTRL+C COPIA O ATUAL   ENTER PARTE", 8, DIM, Vector2(0, 312), body)
	_show_msg()

func _show_msg() -> void:
	if l_msg and is_instance_valid(l_msg):
		l_msg.text = msg

func _key(k: int) -> void:
	var ctrl := Input.is_key_pressed(KEY_CTRL) or Input.is_key_pressed(KEY_META)
	if ctrl and k == KEY_V:
		typed = DisplayServer.clipboard_get().strip_edges().to_upper().substr(0, 40)
	elif ctrl and k == KEY_C:
		DisplayServer.clipboard_set(current())
		msg = "CÓDIGO ATUAL COPIADO"
	elif k == KEY_BACKSPACE:
		typed = typed.substr(0, maxi(0, typed.length() - 1))
	elif k == KEY_ENTER or k == KEY_KP_ENTER:
		var p := parse(typed if typed != "" else current())
		if p.is_empty():
			msg = "NÃO RECONHECI ESSE CÓDIGO. CONFIRA A ESTRADA, O CARRO, O CLIMA, A HORA E O NÚMERO."
		else:
			start(p.cfg, p.seed)
			return
	elif k >= KEY_A and k <= KEY_Z:
		typed += char(k)
	elif k >= KEY_0 and k <= KEY_9:
		typed += char(k)
	elif k >= KEY_KP_0 and k <= KEY_KP_9:
		typed += str(k - KEY_KP_0)
	elif KEYCH.has(k):
		typed += KEYCH[k]
	typed = typed.substr(0, 40)
	_show_msg()

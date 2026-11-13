extends Node
# Ideia 5: caderneta de figurinhas da estrada. Cada coisa vista pela primeira vez cola uma figurinha: o que passa pela
# janela (sprites com "name" nos segmentos, via seg_passed), o trânsito que você encontra e alguns momentos da viagem
# (buraco entre as rodas, poça, ultrapassagem, lua...). Uma página por estrada e uma do céu e da estrada. As raras
# dependem da hora ou do clima. Nada se compra nem se sorteia: ver é o único requisito. Gravado em [caderneta].

const PAGES := ["terra", "br", "expressa", "ceu"]
const PAGE_NAME := {"terra": "SÍTIO", "br": "BR-116", "expressa": "EXPRESSA", "ceu": "CÉU E ESTRADA"}
const ROAD_HINT := {"terra": "NA ESTRADA DO SÍTIO", "br": "NA BR-116", "expressa": "NA RODOVIA EXPRESSA", "ceu": "EM QUALQUER ESTRADA"}
const COND_HINT := {"dia": "SÓ SE VÊ DE DIA", "noite": "SÓ SE VÊ DE NOITE", "tarde": "SÓ NO ENTARDECER", "aurora": "SÓ QUANDO O DIA NASCE",
	"chuva": "SÓ COM CHUVA", "sol": "SÓ COM TEMPO ABERTO"}
# id, page, name, caption, what makes it ("src": sprite/traffic names, or "ev": an event), "cond", "rare", "icon", "hint"
const STICKERS := [
	{"id": "vaca_malhada", "page": "terra", "name": "VACA MALHADA", "leg": "VACA. NÃO DÁ SETA.", "src": ["vaca1"], "icon": "vaca1"},
	{"id": "vaca_nelore", "page": "terra", "name": "VACA NELORE", "leg": "OLHA, MAS NÃO JULGA.", "src": ["vaca0"], "icon": "vaca0"},
	{"id": "porteira", "page": "terra", "name": "PORTEIRA", "leg": "FECHE AO PASSAR, FAZ FAVOR.", "src": ["porteira"], "icon": "porteira"},
	{"id": "casa_sitio", "page": "terra", "name": "CASA DO SÍTIO", "leg": "TEM CAFÉ NO FOGÃO A LENHA.", "src": ["casa_sitio"], "icon": "casa_sitio"},
	{"id": "capela", "page": "terra", "name": "CAPELA", "leg": "MISSA DE DOMINGO ÀS 7.", "src": ["capela"], "icon": "capela"},
	{"id": "cafezal", "page": "terra", "name": "CAFEZAL", "leg": "O CAFEZINHO COMEÇA AQUI.", "src": ["cafe"], "icon": "cafe"},
	{"id": "eucalipto", "page": "terra", "name": "EUCALIPTAL", "leg": "CHEIRO DE GRIPE CURADA.", "src": ["eucalipto"], "icon": "eucalipto"},
	{"id": "bambu", "page": "terra", "name": "BAMBUZAL", "leg": "RANGE QUANDO VENTA.", "src": ["bambu"], "icon": "bambu"},
	{"id": "araucaria_t", "page": "terra", "name": "ARAUCÁRIA", "leg": "PINHÃO SÓ NO INVERNO.", "src": ["araucaria"], "icon": "araucaria"},
	{"id": "ipe", "page": "terra", "name": "IPÊ-AMARELO", "leg": "FLORIU SÓ PRA VOCÊ VER.", "src": ["ipe"], "icon": "ipe", "cond": "dia", "rare": true},
	{"id": "queijo", "page": "terra", "name": "QUEIJO CASEIRO", "leg": "1 KM. MENTIRA, SÃO 4.", "src": ["placa_queijo"], "icon": "placa_queijo"},
	{"id": "ovos", "page": "terra", "name": "OVOS CAIPIRA", "leg": "A GALINHA ASSINA EMBAIXO.", "src": ["placa_ovos"], "icon": "placa_ovos"},
	{"id": "placa_gado", "page": "terra", "name": "PLACA DE GADO", "leg": "A VACA LEU E NÃO LIGOU.", "src": ["placa_gado"], "icon": "placa_gado"},
	{"id": "venda", "page": "terra", "name": "VENDA DO ZÉ", "leg": "PINGA, FUMO E FIADO.", "src": ["venda"], "icon": "venda"},
	{"id": "trator", "page": "terra", "name": "TRATOR", "leg": "LENTO, COMO DIZ A PLACA.", "src": ["trator"], "icon": "trator", "hint": "VEM DEVAGAR NA SUA MÃO"},
	{"id": "ultrapassagem", "page": "terra", "name": "ULTRAPASSAGEM", "leg": "OLHOU, PASSOU, VOLTOU.", "ev": "pass", "icon": "@pass", "hint": "PASSE ALGUÉM PELA CONTRAMÃO, OLHANDO"},
	{"id": "lama", "page": "terra", "name": "POÇA DE LAMA", "leg": "O CARRO AGORA É MARROM.", "ev": "puddle", "icon": "@lama", "cond": "chuva", "rare": true, "hint": "PASSE NUMA POÇA DA ESTRADA DE TERRA"},
	{"id": "poeira", "page": "terra", "name": "TERRA VERMELHA", "leg": "TERRA ROXA NO RETROVISOR.", "ev": "dust", "icon": "@dust", "cond": "sol", "rare": true, "hint": "TERRA SECA E UM POUCO DE EMBALO"},

	{"id": "caminhao", "page": "br", "name": "CAMINHÃO", "leg": "PINHÃO EXPRESS, SEMPRE À DIREITA.", "src": ["car7"], "icon": "car7", "hint": "ANDAM NA FAIXA DA DIREITA"},
	{"id": "posto", "page": "br", "name": "POSTO ESTRELA", "leg": "COMPLETA?", "src": ["posto"], "icon": "posto"},
	{"id": "tanque_br", "page": "br", "name": "TANQUE CHEIO", "leg": "O FRENTISTA ACENOU.", "ev": "refuel", "icon": "@refuel", "hint": "PASSE PELO POSTO NA FAIXA DA DIREITA"},
	{"id": "pamonha", "page": "br", "name": "PAMONHA", "leg": "QUENTINHA DESDE 1987.", "src": ["board0"], "icon": "board0"},
	{"id": "borracharia", "page": "br", "name": "BORRACHARIA", "leg": "24 HORAS, MAS O DONO DORME.", "src": ["board1"], "icon": "board1"},
	{"id": "pinhao", "page": "br", "name": "PINHÃO COZIDO", "leg": "NA HORA, COM SAL GROSSO.", "src": ["board2"], "icon": "board2"},
	{"id": "caldo", "page": "br", "name": "CALDO DE CANA", "leg": "COM LIMÃO, POR FAVOR.", "src": ["board3"], "icon": "board3"},
	{"id": "curitiba", "page": "br", "name": "SAÍDA CURITIBA", "leg": "UM DIA, QUEM SABE.", "src": ["sign0"], "icon": "sign0"},
	{"id": "sao_paulo", "page": "br", "name": "SÃO PAULO 408", "leg": "AINDA FALTA UM BOCADO.", "src": ["sign1"], "icon": "sign1"},
	{"id": "neblina", "page": "br", "name": "SERRA NEBLINA", "leg": "FAROL BAIXO, CORAÇÃO CALMO.", "src": ["sign2"], "icon": "sign2"},
	{"id": "irregular", "page": "br", "name": "IRREGULAR", "leg": "ELA AVISOU.", "src": ["sign3"], "icon": "sign3"},
	{"id": "reduza", "page": "br", "name": "REDUZA", "leg": "PEDIU COM EDUCAÇÃO.", "src": ["sign4"], "icon": "sign4"},
	{"id": "siga_em_paz", "page": "br", "name": "SIGA EM PAZ", "leg": "AMÉM.", "src": ["sign5"], "icon": "sign5"},
	{"id": "placa_posto", "page": "br", "name": "POSTO A 1 KM", "leg": "À DIREITA, COMO SEMPRE.", "src": ["sign_posto"], "icon": "sign_posto"},
	{"id": "araucaria_b", "page": "br", "name": "ARAUCÁRIA", "leg": "A GRALHA AZUL QUE PLANTOU.", "src": ["araucaria"], "icon": "araucaria"},
	{"id": "luz_posto", "page": "br", "name": "LUZ DO POSTO", "leg": "MARIPOSA FAZ FILA.", "src": ["lamp"], "icon": "lamp", "cond": "noite", "rare": true},
	{"id": "passa_caminhao", "page": "br", "name": "ADEUS CAMINHÃO", "leg": "TCHAU, PINHÃO EXPRESS.", "ev": "pass_truck", "icon": "@pass_truck", "hint": "ULTRAPASSE UM CAMINHÃO"},
	{"id": "chuva_na_br", "page": "br", "name": "CHUVA NA BR", "leg": "O NOME DO JOGO. VOCÊ ACHOU.", "ev": "chuva_na_br", "icon": "@chuva_na_br", "cond": "noite+chuva", "rare": true, "hint": "UNS KM NA BR, DE NOITE, COM CHUVA"},

	{"id": "portico", "page": "expressa", "name": "PÓRTICO", "leg": "PASSA SEM ABAIXAR A CABEÇA.", "src": ["portico"], "icon": "portico"},
	{"id": "led_chuva", "page": "expressa", "name": "PAINEL DE LED", "leg": "O PAINEL SE IMPORTA COM VOCÊ.", "src": ["led0"], "icon": "led0"},
	{"id": "led_cafe", "page": "expressa", "name": "CAFÉ 24H", "leg": "KM 112. ANOTADO.", "src": ["led1"], "icon": "led1"},
	{"id": "sos", "page": "expressa", "name": "TELEFONE SOS", "leg": "ALÔ? SÓ O VENTO RESPONDE.", "src": ["sos"], "icon": "sos"},
	{"id": "muro", "page": "expressa", "name": "MURO DE SOM", "leg": "DO OUTRO LADO, ALGUÉM DORME.", "src": ["muro"], "icon": "muro"},
	{"id": "radar", "page": "expressa", "name": "RADAR 110", "leg": "ELE NÃO DORME.", "src": ["placa_radar"], "icon": "placa_radar"},
	{"id": "saida", "page": "expressa", "name": "SAÍDA 45", "leg": "RIO CLARO FICA PRA PRÓXIMA.", "src": ["placa_saida"], "icon": "placa_saida"},
	{"id": "pedagio", "page": "expressa", "name": "PEDÁGIO", "leg": "ELETRÔNICO E SEM TROCO.", "src": ["placa_pedagio"], "icon": "placa_pedagio"},
	{"id": "placa_parada", "page": "expressa", "name": "PARADA A 1 KM", "leg": "SEGURA MAIS UM POUCO.", "src": ["placa_parada"], "icon": "placa_parada"},
	{"id": "parada", "page": "expressa", "name": "PARADA", "leg": "BANHEIRO LIMPO, DIZ A PLACA.", "src": ["parada"], "icon": "parada"},
	{"id": "onibus", "page": "expressa", "name": "VIAÇÃO SERRANA", "leg": "TODO DIA ÀS 6, PONTUAL.", "src": ["onibus"], "icon": "onibus", "hint": "ANDA NA FAIXA DA DIREITA"},
	{"id": "carro_novo", "page": "expressa", "name": "CARRO NOVO", "leg": "TEM ATÉ AR-CONDICIONADO.", "src": ["mod0", "mod1", "mod2", "mod3"], "icon": "mod1", "hint": "O TRÂNSITO DA EXPRESSA"},
	{"id": "tanque_ex", "page": "expressa", "name": "TANQUE CHEIO", "leg": "GASOLINA E UM PÃO DE QUEIJO.", "ev": "refuel", "icon": "@refuel", "hint": "PASSE PELA PARADA NA FAIXA DA DIREITA"},
	{"id": "luz_continua", "page": "expressa", "name": "LUZ CONTÍNUA", "leg": "FILEIRA DE LUA NO CANTEIRO.", "src": ["luminaria"], "icon": "luminaria", "cond": "noite", "rare": true},

	{"id": "entre_rodas", "page": "ceu", "name": "ENTRE AS RODAS", "leg": "NEM ENCOSTOU.", "ev": "between", "icon": "@between", "rare": true, "hint": "DEIXE UM BURACO PASSAR ENTRE OS PNEUS"},
	{"id": "desviou", "page": "ceu", "name": "QUASE BURACO", "leg": "PASSOU RASPANDO, MAS PASSOU.", "ev": "dodge", "icon": "@dodge", "hint": "DESVIE DE UM BURACO POR POUCO"},
	{"id": "poca", "page": "ceu", "name": "POÇA D'ÁGUA", "leg": "SPLASH!", "ev": "puddle", "icon": "@puddle", "hint": "AS POÇAS SÓ APARECEM COM CHUVA"},
	{"id": "lua", "page": "ceu", "name": "A LUA", "leg": "VEIO JUNTO A VIAGEM INTEIRA.", "ev": "lua", "icon": "@lua", "cond": "noite+sol", "rare": true},
	{"id": "por_do_sol", "page": "ceu", "name": "PÔR DO SOL", "leg": "LARANJA DE PROPAGANDA.", "ev": "por_do_sol", "icon": "@por_do_sol", "cond": "tarde+sol"},
	{"id": "nascer", "page": "ceu", "name": "NASCER DO SOL", "leg": "O GALO DO SÍTIO JÁ SABIA.", "ev": "nascer", "icon": "@nascer", "cond": "aurora+sol", "rare": true, "hint": "DIA INTEIRO, TEMPO ABERTO, DEPOIS DA NOITE"},
	{"id": "madrugada", "page": "ceu", "name": "MADRUGADA", "leg": "SÓ VOCÊ E OS CAMINHONEIROS.", "ev": "madrugada", "icon": "@madrugada", "rare": true, "hint": "NO DIA INTEIRO, DIRIJA ATÉ TARDE DA NOITE"},
	{"id": "arco_iris", "page": "ceu", "name": "ARCO-ÍRIS", "leg": "O POTE DE OURO FICA NO KM 43.", "ev": "arco", "icon": "@arco", "rare": true, "hint": "QUANDO A CHUVA PASSA, DE DIA"},
	{"id": "chuva_forte", "page": "ceu", "name": "CHUVA FORTE", "leg": "LIMPADOR SEM DESCANSO.", "ev": "forte", "icon": "@forte", "cond": "chuva", "hint": "A CHUVA ENGROSSA DE VEZ EM QUANDO"},
	{"id": "garoa", "page": "ceu", "name": "GAROA", "leg": "MOLHA BOBO.", "ev": "garoa", "icon": "@garoa", "cond": "chuva", "hint": "A CHUVA AFINA DE VEZ EM QUANDO"},
	{"id": "so_a_chuva", "page": "ceu", "name": "SÓ A CHUVA", "leg": "O MELHOR SOM DO MUNDO.", "ev": "so_a_chuva", "icon": "@so_a_chuva", "cond": "chuva", "hint": "DESLIGUE O RÁDIO (R) E ESCUTE UM POUCO"},
	{"id": "piloto", "page": "ceu", "name": "PILOTO AUTO", "leg": "VOCÊ SÓ CURTIU.", "ev": "auto", "icon": "@auto", "hint": "5 KM NO PILOTO AUTOMÁTICO (P)"},
	{"id": "suave", "page": "ceu", "name": "DIREÇÃO SUAVE", "leg": "NEM O CAFÉ DO COPO MEXEU.", "ev": "suave", "icon": "@suave", "hint": "DIRIJA LISO ATÉ O x4"},
	{"id": "viagem_longa", "page": "ceu", "name": "VIAGEM LONGA", "leg": "30 KM DE PERNA DORMENTE.", "ev": "longa", "icon": "@longa", "hint": "30 KM NUMA VIAGEM SÓ"},
]

const AMBER := Color("f2a62a")
const LINE := Color("9bbbe0")
const INK := Color("e6e8ee")
const DIM := Color("6f86a8")
const CARD := Color("1a2547")
const CARD_ON := Color("24365c")
const COLS := 6
const CW := 112.0
const CH := 84.0

var g
var font: FontFile = preload("res://assets/fonts/Estrada2P.ttf")
var _queue: Array = []        # notices waiting their turn
var _notice_t := 0.0
var _tick_t := 0.0
var _tex_name := {}           # traffic texture -> sprite name
var _rel := {}                # traffic index -> where it was relative to us last tick
var _dust_t := 0.0
var _quiet_t := 0.0
var _auto_km := 0.0
var _rain_hi := 0.0           # how hard it rained lately, for the rainbow
var page := 0
var cur := 0
var body: Control

class Icon extends Control:
	var key := ""
	var sil := false
	var painter: Callable
	func _draw() -> void:
		painter.call(self, key, sil)

func _ready() -> void:
	g = get_parent()
	for k in g.tex.keys():
		_tex_name[g.tex[k]] = k
	g.seg_passed.connect(_on_seg)
	g.hole_missed.connect(_on_hole_missed)
	g.puddle_hit.connect(func(_f): _event("puddle"))
	g.refueled.connect(func(_i): _event("refuel"))
	g.setup_done.connect(func(): _rel.clear())
	g.trip_started.connect(func(): _auto_km = 0.0)
	g.trip_ended.connect(func(_s): g.hud.notice("", 0.01))   # the menu has its own bottom line
	g.menu.add_main_item("CADERNETA", open)
	g.menu.add_pause_item("CADERNETA", open)

# --- what counts
func has(id: String) -> bool:
	return g.store_get("caderneta", id, false) == true

func count(pg := "") -> Array:
	var n := 0
	var tot := 0
	for s in STICKERS:
		if pg == "" or s.page == pg:
			tot += 1
			if has(s.id):
				n += 1
	return [n, tot]

func _phase() -> String:
	var td := fposmod(g.tday, 4.0)
	if td < 0.8 or td >= 3.5:
		return "dia"
	if td < 1.5:
		return "tarde"
	if td < 3.0:
		return "noite"
	return "aurora"

func _cond_ok(s: Dictionary) -> bool:
	var c: String = s.get("cond", "")
	if c == "":
		return true
	var ph := _phase()
	for tok in c.split("+"):
		if tok == "chuva" or tok == "sol":
			if g.cfg.weather != tok:
				return false
		elif tok != ph:
			return false
	return true

func _live() -> bool:
	return g.started and g.state == "drive"

func _grant(s: Dictionary) -> void:
	if has(s.id) or not _cond_ok(s):
		return
	g.store_set("caderneta", s.id, true)
	g.store_save()
	var c := count(s.page)
	_queue.append("FIGURINHA NOVA: %s  (%s %d/%d)" % [s.name, PAGE_NAME[s.page], c[0], c[1]])

func _event(ev: String) -> void:
	if not _live():
		return
	for s in STICKERS:
		if s.get("ev", "") == ev and (s.page == g.cfg.road or s.page == "ceu"):
			_grant(s)

func _seen(name: String) -> void:
	for s in STICKERS:
		if s.page == g.cfg.road and s.has("src") and s.src.has(name):
			_grant(s)

func _on_seg(i: int) -> void:
	if not _live():
		return
	for q in g.segs[i].spr:
		var n: String = q.get("name", "")
		if n != "" and absf(q.off) < 7.5:
			_seen(n)

func _on_hole_missed(f: Dictionary, d: float) -> void:
	var ad := absf(d)
	if ad < 0.2:
		_event("between")
	elif ad < f.w + 0.42:
		_event("dodge")

func _process(dt: float) -> void:
	if g == null or g.segs.is_empty():
		return
	_notice_t -= dt
	if _notice_t <= 0.0 and not _queue.is_empty() and _live():
		g.hud.notice(_queue.pop_front(), 4.0)
		_notice_t = 4.3
	if not _live():
		return
	if g.auto:
		_auto_km += g.v * dt / 3600.0
	_tick_t -= dt
	if _tick_t > 0.0:
		return
	_tick_t = 0.5
	_traffic()
	var ph := _phase()
	var wet: bool = g.cfg.weather == "chuva"
	_dust_t = _dust_t + 0.5 if (g.road.surface == "terra" and not wet and g.v > 40.0) else 0.0
	if _dust_t >= 5.0:
		_event("dust")
	if g.cfg.road == "br" and wet and ph == "noite" and g.km_trip > 2.0:
		_event("chuva_na_br")
	if not wet and ph == "noite":
		_event("lua")
	if not wet and ph == "tarde":
		_event("por_do_sol")
	if not wet and ph == "aurora":
		_event("nascer")
	var td := fposmod(g.tday, 4.0)
	if td > 2.45 and td < 3.0:
		_event("madrugada")
	if wet and g.rain > 0.93:
		_event("forte")
	if wet and g.rain < 0.62:
		_event("garoa")
	_quiet_t = _quiet_t + 0.5 if (wet and g.radio_st >= g.STATIONS.size()) else 0.0
	if _quiet_t >= 30.0:
		_event("so_a_chuva")
	if _auto_km >= 5.0:
		_event("auto")
	if g.mult >= 4:
		_event("suave")
	if g.km_trip >= 30.0:
		_event("longa")
	# the rainbow: when the rain stops in daylight, or when another feature draws one (a "rainbow" value above 0.3)
	_rain_hi = maxf(_rain_hi * 0.995, g.rain)
	var bow: bool = _rain_hi > 0.4 and g.rain < 0.1 and ph == "dia"
	for f in g.features:
		var r = f.get("rainbow")
		if (r is float or r is int) and r > 0.3:
			bow = true
	if bow:
		_event("arco")

# traffic you meet: seen when close ahead; overtaken when it goes from just ahead to just behind
func _traffic() -> void:
	var tr: float = g.TRACK
	for idx in g.cars.size():
		var c: Dictionary = g.cars[idx]
		if c.dir <= 0:
			continue
		var rel := fposmod(c.z - g.pos + tr / 2.0, tr) - tr / 2.0
		var n: String = _tex_name.get(c.tex, "")
		if rel > 0.0 and rel < 2500.0 and n != "":
			_seen(n)
		var was = _rel.get(idx)
		if was != null and was > 0.0 and rel <= 0.0 and rel > -3000.0 and was < 3000.0:
			_event("pass")
			if n == "car7":
				_event("pass_truck")
		_rel[idx] = rel

# --- the album screen
func open() -> void:
	page = maxi(0, PAGES.find(g.cfg.road))
	cur = 0
	g.menu.open_screen("CADERNETA", _build, _key)

func _page_items() -> Array:
	var out: Array = []
	for s in STICKERS:
		if s.page == PAGES[page]:
			out.append(s)
	return out

func _build(b: Control) -> void:
	body = b
	_fill()

func _key(k: int) -> void:
	var n := _page_items().size()
	match k:
		KEY_LEFT, KEY_A:
			if cur % COLS == 0:
				_turn(-1)
				return
			cur -= 1
		KEY_RIGHT, KEY_D:
			if cur % COLS == COLS - 1 or cur == n - 1:
				_turn(1)
				return
			cur += 1
		KEY_UP, KEY_W:
			cur = cur - COLS if cur >= COLS else cur
		KEY_DOWN, KEY_S:
			cur = mini(n - 1, cur + COLS)
		KEY_Q, KEY_PAGEUP:
			_turn(-1)
			return
		KEY_E, KEY_TAB, KEY_PAGEDOWN:
			_turn(1)
			return
		_:
			return
	_fill()

func _turn(d: int) -> void:
	page = (page + d + PAGES.size()) % PAGES.size()
	cur = clampi(cur, 0, _page_items().size() - 1)
	_fill()

func _fill() -> void:
	if body == null:
		return
	for c in body.get_children():
		c.queue_free()
	var m = g.menu
	var tot := count()
	m.screen_title.text = "CADERNETA  %d/%d" % [tot[0], tot[1]]
	var x := 0.0
	for i in PAGES.size():
		var c := count(PAGES[i])
		var txt := "%s %d/%d" % [PAGE_NAME[PAGES[i]], c[0], c[1]]
		m.label(txt, 8, AMBER if i == page else DIM, Vector2(x, 2), body)
		if i == page:
			m.box(Rect2(x, 12, txt.length() * 8, 2), AMBER, body)
		x += (txt.length() + 3) * 8
	m.label("Q/E: PÁGINA", 8, DIM, Vector2(600, 2), body)
	var items := _page_items()
	for i in items.size():
		var s: Dictionary = items[i]
		var got := has(s.id)
		var r := Rect2((i % COLS) * (CW + 2), 20 + (i / COLS) * (CH + 2), CW, CH)
		var border: Color = INK if i == cur else (AMBER.darkened(0.25) if s.get("rare", false) and got else CARD.lightened(0.15))
		m._frame(r, CARD_ON if got else CARD, border, body)
		var ic: String = s.icon
		if ic.begins_with("@"):
			var icon := Icon.new()
			icon.key = ic.substr(1)
			icon.sil = not got
			icon.painter = draw_icon
			icon.position = r.position + Vector2(4, 4)
			icon.size = Vector2(CW - 8, 56)
			icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
			body.add_child(icon)
		else:
			var tr := TextureRect.new()
			tr.texture = g.tex[ic]
			tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			var ts: Vector2 = tr.texture.get_size()
			tr.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED if ts.x <= CW - 8 and ts.y <= 56 else TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			if ts.x > (CW - 8) * 2.0 or ts.y > 112.0:
				tr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR   # big sprites shrink smoother
			tr.position = r.position + Vector2(4, 4)
			tr.size = Vector2(CW - 8, 56)
			tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
			if not got:
				tr.modulate = Color(0, 0, 0, 0.55)   # silhouette
			body.add_child(tr)
		var nm: Label = m.label(s.name, 8, INK if got else DIM, r.position + Vector2(0, 63), body)
		nm.size = Vector2(CW, 16)
		nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		m.label("%02d" % (i + 1), 8, AMBER if (got and s.get("rare", false)) else Color(DIM, 0.7), r.position + Vector2(4, 4), body)
	if items.is_empty():
		return
	var sel: Dictionary = items[clampi(cur, 0, items.size() - 1)]
	var gotsel := has(sel.id)
	var rare: bool = sel.get("rare", false)
	m.label(sel.name + ("  (RARA)" if rare else ""), 16, AMBER if gotsel else DIM, Vector2(0, 284), body)
	if gotsel:
		m.label(sel.leg, 8, INK, Vector2(0, 306), body)
	else:
		m.label("AINDA NÃO COLADA.", 8, DIM, Vector2(0, 306), body)
		m.label("DICA: " + _hint(sel), 8, LINE, Vector2(0, 318), body)

func _hint(s: Dictionary) -> String:
	var parts: Array = []
	if s.has("hint"):
		parts.append(s.hint)
	var c: String = s.get("cond", "")
	if c != "":
		for tok in c.split("+"):
			parts.append(COND_HINT.get(tok, ""))
	parts.append(ROAD_HINT[s.page])
	return ", ".join(parts)

# --- drawn icons for the moments (104x56 box). sil: dark silhouette for the ones still missing
func draw_icon(c: Control, key: String, sil: bool) -> void:
	var S := Color(0, 0, 0, 0.55)
	var col := func(h: String) -> Color: return S if sil else Color(h)
	var w := c.size.x
	match key:
		"between", "dodge":
			c.draw_rect(Rect2(8, 8, w - 16, 44), col.call("3a4352"))
			c.draw_rect(Rect2(w / 2 - 1, 12, 2, 8), col.call("d6dce8"))
			var tx: Array = [30.0, 66.0] if key == "between" else [18.0, 46.0]
			var hx := w / 2.0 if key == "between" else 80.0
			c.draw_set_transform(Vector2(hx, 40), 0.0, Vector2(1.0, 0.45))
			c.draw_circle(Vector2.ZERO, 9.0, col.call("12161e"))
			c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			for x in tx:
				c.draw_rect(Rect2(x - 5, 22, 10, 22), col.call("05070c"))
				c.draw_rect(Rect2(x - 4, 22, 8, 3), col.call("2a2c33"))
		"puddle", "lama":
			var water: String = "6f97c4" if key == "puddle" else "6e4526"
			c.draw_set_transform(Vector2(w / 2, 42), 0.0, Vector2(1.0, 0.3))
			c.draw_circle(Vector2.ZERO, 34.0, col.call(water))
			c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			for i in 9:
				var a := PI + PI * (i + 0.5) / 9.0
				var p := Vector2(w / 2, 40) + Vector2(cos(a) * 30.0, sin(a) * 26.0)
				c.draw_rect(Rect2(p.x - 2, p.y - 2, 4, 4), col.call("cfe0f2" if key == "puddle" else "96643a"))
		"dust":
			for i in 7:
				c.draw_circle(Vector2(18 + i * 11, 36 - (i % 3) * 6), 9.0 + (i % 2) * 4.0, col.call("c4683a" if i % 2 else "a0522d"))
		"pass", "pass_truck":
			c.draw_rect(Rect2(8, 8, w - 16, 44), col.call("5a4030" if key == "pass" else "3a4352"))
			if key == "pass_truck":
				c.draw_rect(Rect2(60, 14, 22, 32), col.call("cfd4dc"))
				c.draw_rect(Rect2(60, 40, 22, 6), col.call("2a2c33"))
			else:
				c.draw_rect(Rect2(62, 26, 18, 14), col.call("c22630"))
			c.draw_rect(Rect2(24, 30, 18, 14), col.call("6f97c4"))
			c.draw_polyline(PackedVector2Array([Vector2(33, 26), Vector2(40, 14), Vector2(58, 10), Vector2(88, 14)]), col.call("ffd65a"), 2.0)
			c.draw_rect(Rect2(86, 12, 4, 4), col.call("ffd65a"))
		"refuel":
			c.draw_rect(Rect2(38, 6, 26, 44), col.call("c22630"))
			c.draw_rect(Rect2(42, 10, 18, 10), col.call("e6e8ee"))
			c.draw_rect(Rect2(34, 48, 34, 4), col.call("2a2c33"))
			c.draw_polyline(PackedVector2Array([Vector2(64, 24), Vector2(74, 26), Vector2(74, 44), Vector2(68, 46)]), col.call("16202b"), 3.0)
			c.draw_rect(Rect2(46, 28, 10, 4), col.call("ffd65a"))
		"chuva_na_br":
			c.draw_rect(Rect2(4, 4, w - 8, 48), col.call("0f1730"))
			c.draw_rect(Rect2(26, 12, 52, 26), col.call("23743f"))
			c.draw_rect(Rect2(28, 14, 48, 22), col.call("16482c"))
			if not sil:
				c.draw_string(font, Vector2(36, 31), "BR", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, INK)
			for i in 14:
				var x := fmod(i * 23.0, w - 12) + 6
				c.draw_line(Vector2(x, 6 + (i % 4) * 10), Vector2(x - 3, 14 + (i % 4) * 10), col.call("9bbbe0"), 1.0)
		"lua", "madrugada":
			c.draw_rect(Rect2(4, 4, w - 8, 48), col.call("070b18"))
			for i in 16:
				c.draw_rect(Rect2(fmod(i * 37.0, w - 14) + 6, fmod(i * 17.0, 40) + 7, 2, 2), col.call("cfe0f2"))
			if key == "lua":
				c.draw_circle(Vector2(w / 2, 27), 14.0, col.call("e6e8ee"))
				c.draw_circle(Vector2(w / 2 + 4, 23), 3.0, col.call("a8acb5"))
				c.draw_circle(Vector2(w / 2 - 5, 31), 2.0, col.call("a8acb5"))
			else:
				c.draw_rect(Rect2(8, 40, w - 16, 12), col.call("0a1614"))
				c.draw_rect(Rect2(40, 42, 3, 2), col.call("fff3b0"))
				c.draw_rect(Rect2(48, 42, 3, 2), col.call("fff3b0"))
		"por_do_sol", "nascer":
			var top: String = "3a2a55" if key == "por_do_sol" else "2a3560"
			var hor: String = "f2a62a" if key == "por_do_sol" else "e89a7a"
			c.draw_rect(Rect2(4, 4, w - 8, 24), col.call(top))
			c.draw_rect(Rect2(4, 24, w - 8, 18), col.call(hor))
			c.draw_circle(Vector2(w / 2, 42 if key == "por_do_sol" else 36), 12.0, col.call("fff3b0" if key == "nascer" else "ffd65a"))
			c.draw_rect(Rect2(4, 42, w - 8, 10), col.call("1d3020"))
		"arco":
			c.draw_rect(Rect2(4, 4, w - 8, 48), col.call("6f97c4"))
			var cols := ["c22630", "f2a62a", "ffd65a", "3fae5a", "3d5f94", "6a4a7a"]
			for i in cols.size():
				c.draw_arc(Vector2(w / 2, 54), 40.0 - i * 3.0, PI, TAU, 32, col.call(cols[i]), 3.0)
			c.draw_rect(Rect2(4, 48, w - 8, 4), col.call("2f7a40"))
		"forte", "garoa":
			c.draw_rect(Rect2(4, 4, w - 8, 48), col.call("27405a"))
			var n := 36 if key == "forte" else 8
			for i in n:
				var x := fmod(i * 29.0, w - 14) + 8
				var y := fmod(i * 13.0, 36) + 8
				if key == "forte":
					c.draw_line(Vector2(x, y), Vector2(x - 3, y + 9), col.call("cfe0f2"), 1.0)
				else:
					c.draw_rect(Rect2(x, y, 2, 2), col.call("cfe0f2"))
		"so_a_chuva":
			c.draw_rect(Rect2(20, 16, 64, 30), col.call("16202b"))
			c.draw_rect(Rect2(26, 22, 34, 10), col.call("05070c"))
			c.draw_circle(Vector2(72, 31), 6.0, col.call("a8acb5"))
			if not sil:
				c.draw_string(font, Vector2(29, 31), "OFF", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color("f0484a"))
			for i in 6:
				c.draw_rect(Rect2(14 + i * 15, 6 + (i % 2) * 4, 2, 4), col.call("9bbbe0"))
		"auto", "suave":
			c.draw_circle(Vector2(w / 2, 28), 22.0, col.call("16202b"))
			c.draw_arc(Vector2(w / 2, 28), 22.0, 0.0, TAU, 40, col.call("3fe0e8" if key == "auto" else "f2a62a"), 2.0)
			if not sil:
				var t := "AUTO" if key == "auto" else "x4"
				var sz := 8 if key == "auto" else 16
				var tw := font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x
				c.draw_string(font, Vector2(w / 2 - tw / 2, 28 + sz / 2.0 - 1), t, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, Color("3fe0e8") if key == "auto" else AMBER)
		"longa":
			c.draw_rect(Rect2(4, 4, w - 8, 24), col.call("3d6fb8"))
			c.draw_rect(Rect2(4, 28, w - 8, 24), col.call("2f7a40"))
			c.draw_colored_polygon(PackedVector2Array([Vector2(w / 2 - 2, 28), Vector2(w / 2 + 2, 28), Vector2(w / 2 + 34, 52), Vector2(w / 2 - 34, 52)]), col.call("3a4352"))
			for i in 3:
				c.draw_rect(Rect2(w / 2 - 1, 31 + i * 7, 2, 3 + i), col.call("ffd65a"))

extends Node
# Comfort settings (brainstorm idea 23): a "AJUSTES" screen in the main menu and in the pause.
# Camera sway and shake, how fast the day goes by, how many potholes and cars, separate volumes
# (radio, rain, engine, effects: each on its own audio bus), size of the on-screen notices, only the
# essential notices, and the score on or off. Everything is saved in viagem.cfg, section [ajustes].

const AMBER := Color("f2a62a")
const INK := Color("e6e8ee")
const DIM := Color("6f86a8")
const LINE := Color("9bbbe0")
const BUSES := ["Radio", "Chuva", "Motor", "Efeitos"]
const PCT := ["0%", "10%", "20%", "30%", "40%", "50%", "60%", "70%", "80%", "90%", "100%"]
# key, label, value names, default index, description
const OPTS := [
	["sway", "BALANÇO DA CÂMERA", ["0%", "25%", "50%", "75%", "100%"], 4, "QUANTO A VISTA DE DENTRO INCLINA COM A CARROCERIA. MENOS BALANÇO, MENOS ENJOO."],
	["shake", "TREMOR DA TELA", ["LIGADO", "SUAVE", "DESLIGADO"], 0, "O SOLAVANCO DOS BURACOS E DA TERRA NA VISTA DE DENTRO. O CARRO CONTINUA SENTINDO."],
	["day", "CICLO DO DIA", ["RÁPIDO (7 MIN)", "CALMO (20 MIN)", "LENTO (45 MIN)"], 0, "QUANTO DURA UM DIA INTEIRO NA HORA \"DIA INTEIRO\"."],
	["holes", "BURACOS", ["POUCOS", "NORMAL", "ESTRADA RUIM"], 1, "QUANTOS BURACOS A ESTRADA TEM. VALE QUANDO A ESTRADA FOR MONTADA DE NOVO."],
	["traffic", "TRÂNSITO", ["LEVE", "NORMAL", "CHEIO"], 1, "QUANTOS CARROS NA ESTRADA. VALE QUANDO A ESTRADA FOR MONTADA DE NOVO."],
	["vol_radio", "VOLUME DO RÁDIO", PCT, 10, "SÓ O RÁDIO. A TECLA M CONTINUA DESLIGANDO TODO O SOM."],
	["vol_chuva", "VOLUME DA CHUVA", PCT, 10, "A CHUVA NO TETO E NO VIDRO."],
	["vol_motor", "VOLUME DO MOTOR", PCT, 10, "MOTOR, PNEU NO MOLHADO E RONCO DO CHÃO."],
	["vol_efeitos", "VOLUME DOS EFEITOS", PCT, 10, "BURACO, POÇA, BUZINA, LIMPADOR E ESTÁTICA DO RÁDIO."],
	["notice", "TAMANHO DOS AVISOS", ["PEQUENO", "NORMAL", "GRANDE"], 1, "O TAMANHO DO TEXTO DOS AVISOS NA TELA."],
	["essential", "AVISOS", ["TODOS", "SÓ OS ESSENCIAIS"], 0, "SÓ OS ESSENCIAIS: RESERVA, POSTO, CONTRAMÃO E PILOTO AUTOMÁTICO."],
	["score", "PLACAR", ["VISÍVEL", "ESCONDIDO"], 0, "OS PONTOS NO ALTO DA TELA DURANTE A VIAGEM."],
]
const SWAY := [0.0, 0.25, 0.5, 0.75, 1.0]
const SHAKE := [1.0, 0.5, 0.0]
const DAY := [1.0, 440.0 / 1200.0, 440.0 / 2700.0]   # the game's cycle is 4 x 110 s = 7 min 20 s
const NOTICE_SIZE := [[8, 8], [16, 8], [24, 16]]      # [toast, notice] font sizes
const ESSENTIAL := ["RESERVA", "POSTO", "TANQUE", "CONTRAMÃO", "PILOTO", "VOLANTE", "SOM "]

var g
var val := {}           # key -> chosen index
var sel := 0
var rows: Array = []    # [label, value] per option
var desc: Label
var _routed := false

func _ready() -> void:
	g = get_parent()
	process_priority = 1000   # after the HUD and the other features: filter toasts in the same frame
	for o in OPTS:
		val[o[0]] = clampi(int(g.store_get("ajustes", o[0], o[3])), 0, o[2].size() - 1)
	_make_buses()
	g.setup_done.connect(_on_setup)
	g.trip_started.connect(_route)
	_late_ready.call_deferred()

func _late_ready() -> void:
	g.menu.add_main_item("AJUSTES", open)
	g.menu.add_pause_item("AJUSTES", open)
	_route()
	_apply()

func get_idx(key: String) -> int:
	return val.get(key, 0)

func essential_only() -> bool:
	return get_idx("essential") == 1

# ---- audio buses: one per kind of sound, all into Master (so M still mutes everything)
func _make_buses() -> void:
	for n in BUSES:
		if AudioServer.get_bus_index(n) == -1:
			AudioServer.add_bus()
			var i := AudioServer.bus_count - 1
			AudioServer.set_bus_name(i, n)
			AudioServer.set_bus_send(i, "Master")

func _route() -> void:
	if g.a_music == null:
		return
	g.a_music.bus = "Radio"
	g.a_rain.bus = "Chuva"
	if g.a_roof:
		g.a_roof.bus = "Chuva"
	for p in [g.a_engine, g.a_rumble, g.a_hiss]:
		p.bus = "Motor"
	for k in g.sfx:
		g.sfx[k].bus = "Efeitos"
	_routed = true

func _apply() -> void:
	g.view_sway = SWAY[get_idx("sway")]
	g.view_shake = SHAKE[get_idx("shake")]
	var keys := ["vol_radio", "vol_chuva", "vol_motor", "vol_efeitos"]
	for i in 4:
		var b := AudioServer.get_bus_index(BUSES[i])
		var lv := get_idx(keys[i]) / 10.0
		AudioServer.set_bus_mute(b, lv <= 0.0)
		AudioServer.set_bus_volume_db(b, linear_to_db(maxf(lv, 0.0001)))
	if g.hud.l_score and g.state != "menu":
		var on := get_idx("score") == 0
		g.hud.l_score.visible = on
		g.hud.l_hi.visible = on

# ---- potholes and traffic: thinned out or added to the road that setup() just built
func _on_setup() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = g.trip_seed * 7919 + 17
	var h := get_idx("holes")
	if g.get_node_or_null("estrada") != null:
		h = 1   # the road package re-dresses the road itself and asks us for the factor (estrada.gd, _hole_factor)
	if h == 0:   # every other pothole goes away
		var n := 0
		for s in g.segs:
			for k in range(s.feat.size() - 1, -1, -1):
				if s.feat[k].t == 0:
					n += 1
					if n % 2 == 0:
						s.feat.remove_at(k)
	elif h == 2:   # bad road: about twice as many, never closer than half the road's usual gap
		var has := PackedByteArray()
		has.resize(g.N)
		for i in g.N:
			for f in g.segs[i].feat:
				if f.t == 0:
					has[i] = 1
		var gap: int = maxi(3, int(g.road.hole_gap) / 2)
		var last := -1000
		for i in range(60, g.N):
			if has[i] == 1:
				last = i
				continue
			if i - last < gap:
				continue
			var free := true
			for j in range(i + 1, mini(g.N, i + gap)):
				if has[j] == 1:
					free = false
					break
			if free and rng.randf() < (g.road.hole_p + g.ROUGH[i] * g.road.hole_k) * 1.2:
				last = i
				has[i] = 1
				g.segs[i].feat.append({"t": 0, "x": g.LANES[rng.randi() % g.LANES.size()] + rng.randf_range(-0.22, 0.22), "w": rng.randf_range(0.07, 0.12)})
	var tr := get_idx("traffic")
	if tr == 0:   # light: every other car in each direction
		var keep: Array = []
		var cnt := {1: 0, -1: 0}
		for c in g.cars:
			if cnt[c.dir] % 2 == 0:
				keep.append(c)
			cnt[c.dir] += 1
		g.cars.clear()
		g.cars.append_array(keep)
	elif tr == 2:   # busy: half as many again, spread elsewhere on the loop
		var more: Array = []
		var n := 0
		for c in g.cars:
			n += 1
			if n % 2 == 0:
				var d: Dictionary = c.duplicate()
				d.z = fposmod(c.z + g.TRACK * rng.randf_range(0.3, 0.7), g.TRACK)
				d.v = c.v * rng.randf_range(0.94, 1.06)
				d.erase("cur")
				more.append(d)
		g.cars.append_array(more)

func _process(dt: float) -> void:
	dt = minf(dt, 0.05)
	# day cycle: the game moves tday by dt/110; nudge it to the chosen pace
	var dk: float = DAY[get_idx("day")]
	if dk != 1.0 and g.cfg.time == "ciclo" and g.state != "pause":
		g.tday = fposmod(g.tday + dt / 110.0 * (dk - 1.0), 4.0)
	var hud = g.hud
	var sz: Array = NOTICE_SIZE[get_idx("notice")]
	var ls: LabelSettings = hud.l_toast.label_settings
	if ls.font_size != sz[0]:
		ls.font_size = sz[0]
		hud.l_toast.autowrap_mode = TextServer.AUTOWRAP_WORD if sz[0] > 16 else TextServer.AUTOWRAP_OFF
		hud.l_toast.size = Vector2(768, sz[0] + 4)
	if hud.l_notice and hud.l_notice.label_settings.font_size != sz[1]:
		hud.l_notice.label_settings.font_size = sz[1]
		hud.l_notice.position.y = 396.0 - (sz[1] - 8) * 1.25
	if essential_only() and hud.toast_t > 0.0 and not _is_essential(hud.l_toast.text):
		hud.toast_t = 0.0
		hud.l_toast.modulate.a = 0.0
	if get_idx("score") == 1 and hud.l_score.visible:
		hud.l_score.visible = false
		hud.l_hi.visible = false

static func _is_essential(txt: String) -> bool:
	for w in ESSENTIAL:
		if txt.contains(w):
			return true
	return txt.begins_with("SOM")

# ---- the screen
func open() -> void:
	sel = 0
	g.menu.open_screen("AJUSTES", _build, _key)

func _build(body: Control) -> void:
	rows.clear()
	var m = g.menu
	for i in OPTS.size():
		var y := i * 23
		var l: Label = m.label(OPTS[i][1], 16, INK, Vector2(16, y), body)
		var v: Label = m.label("", 16, INK, Vector2(352, y), body)
		v.size = Vector2(320, 18)
		v.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		rows.append([l, v])
	desc = m.label("", 8, LINE, Vector2(16, 284), body)
	desc.size = Vector2(660, 20)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	m.label("SETAS ESCOLHEM E TROCAM   ESC VOLTA   TUDO FICA GUARDADO", 8, DIM, Vector2(16, 312), body)
	_refresh()

func _refresh() -> void:
	if rows.is_empty() or not is_instance_valid(rows[0][0]):
		return
	for i in OPTS.size():
		var on := i == sel
		var names: Array = OPTS[i][2]
		var nm: String = names[get_idx(OPTS[i][0])]
		rows[i][0].label_settings.font_color = AMBER if on else INK
		rows[i][1].text = ("< %s >" % nm) if on else nm
		rows[i][1].label_settings.font_color = AMBER if on else LINE
	var d: String = OPTS[sel][4]
	if (OPTS[sel][0] == "holes" or OPTS[sel][0] == "traffic") and g.state != "menu":
		d += " (NA PRÓXIMA VIAGEM)"
	desc.text = d

func _key(k: int) -> void:
	match k:
		KEY_UP, KEY_W:
			sel = (sel + OPTS.size() - 1) % OPTS.size()
		KEY_DOWN, KEY_S:
			sel = (sel + 1) % OPTS.size()
		KEY_LEFT, KEY_A:
			_change(-1)
		KEY_RIGHT, KEY_D, KEY_ENTER, KEY_KP_ENTER, KEY_SPACE:
			_change(1)
	_refresh()

func _change(d: int) -> void:
	var o: Array = OPTS[sel]
	var n: int = o[2].size()
	var pct: bool = o[2] == PCT
	var i := get_idx(o[0]) + d
	i = clampi(i, 0, n - 1) if pct else posmod(i, n)   # volumes stop at the ends, the rest go round
	val[o[0]] = i
	g.store_set("ajustes", o[0], i)
	g.store_save()
	if o[0] == "score" and i == 0 and g.started:
		g.hud.l_score.visible = true
		g.hud.l_hi.visible = true
	_apply()
	if (o[0] == "holes" or o[0] == "traffic") and g.state == "menu":   # the preview behind the menu: same road, new amount
		g.next_seed = g.trip_seed
		g.setup()

extends Node
# Trip of the day (brainstorm idea 20): "VIAGEM DE HOJE" in the menu. Car, road, weather, time and the
# seed of the road and traffic come from today's date, so everyone gets the same trip on the same day.
# No ranking and no streak: each day you take it leaves a stamp ("13/11: BR-116, CHUVA, ENTARDECER").

const Cat = preload("res://scripts/catalog.gd")
const AMBER := Color("f2a62a")
const INK := Color("e6e8ee")
const DIM := Color("6f86a8")
const LINE := Color("9bbbe0")

var g

func _ready() -> void:
	g = get_parent()
	g.menu.add_main_item("VIAGEM DE HOJE", open)

static func date_key(d: Dictionary) -> String:
	return "%04d-%02d-%02d" % [d.year, d.month, d.day]

# FNV-1a over the date text: the same number on every machine
static func _hash(s: String) -> int:
	var h := 2166136261
	for b in s.to_utf8_buffer():
		h = ((h ^ b) * 16777619) & 0xFFFFFFFF
	return h

static func trip_for(d: Dictionary) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = _hash("chuva-na-br " + date_key(d))
	var cfg := {"car": Cat.CAR_IDS[rng.randi() % Cat.CAR_IDS.size()], "road": Cat.ROAD_IDS[rng.randi() % Cat.ROAD_IDS.size()],
		"weather": Cat.WEATHER_IDS[rng.randi() % Cat.WEATHER_IDS.size()], "time": Cat.TIME_IDS[rng.randi() % Cat.TIME_IDS.size()]}
	return {"cfg": cfg, "seed": rng.randi_range(1, 9999)}

static func describe(cfg: Dictionary) -> String:
	return "%s, %s, %s" % [Cat.ROADS[cfg.road].name, Cat.WEATHER[cfg.weather].name, Cat.TIMES[cfg.time].name]

func today() -> Dictionary:
	return Time.get_date_dict_from_system()

func open() -> void:
	g.menu.open_screen("VIAGEM DE HOJE", _build, _key)

func _build(body: Control) -> void:
	var m = g.menu
	var d := today()
	var tr := trip_for(d)
	var c: Dictionary = tr.cfg
	m.label("%02d/%02d  ·  A MESMA VIAGEM PARA TODO MUNDO HOJE. É SÓ IR VER COMO ESTÁ A ESTRADA." % [d.day, d.month], 8, LINE, Vector2(0, 0), body)
	var items := [["CARRO", Cat.CARS[c.car].name], ["ESTRADA", Cat.ROADS[c.road].name], ["CLIMA", Cat.WEATHER[c.weather].name], ["HORA", Cat.TIMES[c.time].name]]
	for i in items.size():
		m.label(items[i][0], 8, DIM, Vector2(0, 26 + i * 34), body)
		m.label(items[i][1], 16, INK, Vector2(0, 38 + i * 34), body)
	var cod = g.get_node_or_null("codigo")
	if cod:
		m.label("CÓDIGO", 8, DIM, Vector2(0, 162), body)
		m.label(cod.code_for(c, tr.seed), 16, AMBER, Vector2(0, 174), body)
	# stamps from the days you took it, newest first
	m.label("CARIMBOS", 8, DIM, Vector2(400, 26), body)
	var keys: Array = g.store.get_section_keys("viagem_do_dia") if g.store.has_section("viagem_do_dia") else []
	keys.sort()
	keys.reverse()
	if keys.is_empty():
		m.label("NENHUM AINDA", 8, Color(DIM, 0.7), Vector2(400, 40), body)
	for i in mini(keys.size(), 14):
		var k: String = keys[i]
		m.label("%s/%s: %s" % [k.substr(8, 2), k.substr(5, 2), g.store_get("viagem_do_dia", k, "")], 8, INK, Vector2(400, 40 + i * 14), body)
	m.box(Rect2(0, 214, 380, 30), Color("0b1120"), body)
	var b: Label = m.label("> PEGAR A ESTRADA <", 16, AMBER, Vector2(0, 221), body)
	b.size = Vector2(380, 18)
	b.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	m.label("ENTER PARTE   ESC VOLTA   (SEM SEQUÊNCIA DE DIAS: VENHA QUANDO QUISER)", 8, DIM, Vector2(0, 312), body)

func _key(k: int) -> void:
	if k == KEY_ENTER or k == KEY_KP_ENTER or k == KEY_SPACE:
		start()

func start() -> void:
	var d := today()
	var tr := trip_for(d)
	g.store_set("viagem_do_dia", date_key(d), describe(tr.cfg))
	var cod = g.get_node_or_null("codigo")
	if cod:
		cod.start(tr.cfg, tr.seed)   # saves, rebuilds, closes the screen and leaves
	else:
		for k in tr.cfg:
			g.cfg[k] = tr.cfg[k]
		g.next_seed = tr.seed
		g.setup()
		g.menu.close_screen()
		g.begin()
	g.hud.notice("VIAGEM DE HOJE: %02d/%02d  ·  %s" % [d.day, d.month, describe(tr.cfg)], 6.0)

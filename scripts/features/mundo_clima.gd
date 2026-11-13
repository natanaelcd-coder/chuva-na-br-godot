extends Node
# Ideia 13: weather that comes and goes. With VARIÁVEL (or summer showers on a sunny trip, see mundo_epoca)
# the sky clouds over, a downpour of 2 to 3 minutes falls (the wipers wake up by themselves, puddles fill up)
# and when it clears, a rainbow may show on the horizon. Sometimes it is just a sun shower: sun and rain together.
# Drives g.rain_goal, g.sky_k (overcast sky), g.wet_k (wet road and puddles) and g.fog_k; game.gd and world.gd
# blend sun and rain by those values instead of the fixed choice in cfg.weather.

var g
var phase := "sol"     # sol | nublando | pancada | abrindo | garoa
var phase_t := 0.0     # seconds left in this phase
var sky_goal := 0.0
var bow := 0.0         # rainbow strength 0..1
var bow_t := 0.0       # seconds the rainbow still holds
var bow_x := 0.0       # where on the sky band it stands
var curtain := 0.0     # the grey rain curtain coming over the hills before a downpour
var heavy := 0.0       # how hard this downpour falls
var rng := RandomNumberGenerator.new()   # own dice, so the game's random sequence stays the same

func _ready() -> void:
	g = get_parent()
	if Engine.has_meta("test_seed"):
		rng.seed = Engine.get_meta("test_seed")
	g.setup_done.connect(_on_setup)

func _on_setup() -> void:
	bow = 0.0
	bow_t = 0.0
	curtain = 0.0
	if not g.mixed_weather:
		return
	_go("sol")
	phase_t = rng.randf_range(25.0, 50.0) if g.cfg.weather == "variavel" else rng.randf_range(60.0, 120.0)
	g.sky_k = 0.0
	g.wet_k = 0.0
	g.rain = 0.0
	g.rain_goal = 0.0
	sky_goal = 0.0

func _daylight() -> bool:
	return g.tday < 1.25 or g.tday >= 3.15

func _say(txt: String) -> void:
	if g.started and g.state == "drive":
		g.hud.notice(txt, 4.0)

func _go(p: String) -> void:
	phase = p
	match p:
		"sol":
			sky_goal = 0.08
			g.rain_goal = 0.0
			var sunny_trip: bool = g.cfg.weather == "sol"   # summer showers on a sunny trip: longer dry spells
			phase_t = rng.randf_range(150.0, 280.0) if sunny_trip else rng.randf_range(70.0, 140.0)
		"nublando":
			sky_goal = 1.0
			g.rain_goal = 0.0
			phase_t = 40.0
			_say("O CÉU ESTÁ FECHANDO... VEM CHUVA AÍ")
		"pancada":
			heavy = rng.randf_range(0.8, 1.0)
			g.rain_goal = heavy
			sky_goal = 1.0
			phase_t = rng.randf_range(120.0, 180.0) if g.cfg.weather == "variavel" else rng.randf_range(70.0, 120.0)
			_say("PANCADA DE VERÃO! O LIMPADOR ACORDOU SOZINHO")
		"abrindo":
			g.rain_goal = 0.0
			sky_goal = 0.35
			phase_t = 60.0
		"garoa":   # sun shower: rain with the sun out
			heavy = rng.randf_range(0.3, 0.45)
			g.rain_goal = heavy
			sky_goal = 0.32
			phase_t = rng.randf_range(30.0, 50.0)
			_say("CHUVA COM SOL: CASAMENTO DE VIÚVA")

# for tests: jump straight into a phase
func force(p: String) -> void:
	_go(p)
	if p == "pancada":
		g.sky_k = 1.0
		g.rain = heavy
	elif p == "arco":
		_go("sol")
		g.rain = 0.0
		g.sky_k = 0.15
		_rainbow()

func _rainbow() -> void:
	if not _daylight() or bow_t > 0.0:
		return
	bow_t = rng.randf_range(50.0, 70.0)
	bow_x = rng.randf_range(60.0, 330.0) + g.sky * 0.3
	_say("OLHA O ARCO-ÍRIS!")
	g.feature_call("world_event", ["arco_iris"])

func _process(dt: float) -> void:
	if g.state == "pause":
		return
	if bow_t > 0.0:
		bow_t -= dt
	bow = move_toward(bow, 1.0 if bow_t > 0.0 else 0.0, dt / (6.0 if bow_t > 0.0 else 10.0))
	if not g.mixed_weather:
		curtain = 0.0
		return
	phase_t -= dt
	match phase:
		"sol":
			if phase_t <= 0.0:
				_go("garoa" if rng.randf() < 0.3 and _daylight() else "nublando")
		"nublando":
			if g.sky_k > 0.75 or phase_t <= 0.0:
				_go("pancada")
		"pancada":
			if phase_t <= 0.0:
				_go("abrindo")
		"abrindo":
			if g.rain < 0.35:
				sky_goal = 0.12
			if g.rain < 0.06:
				_say("ABRIU O SOL")
				if rng.randf() < 0.85:
					_rainbow()
				_go("sol")
		"garoa":
			if phase_t <= 0.0:
				g.rain_goal = 0.0
				if g.rain < 0.06:
					_rainbow()
					_go("sol")
	# a downpour arrives faster than game.gd's slow drift (which still runs on top of this)
	if phase == "pancada" or phase == "garoa":
		g.rain = move_toward(g.rain, g.rain_goal, dt * 0.06)
	g.sky_k = move_toward(g.sky_k, sky_goal, dt * (0.04 if sky_goal > g.sky_k else 0.02))
	# the road gets wet at once and dries out slowly
	var wet_goal := clampf(g.rain * 1.8, 0.0, 1.0)
	g.wet_k = move_toward(g.wet_k, wet_goal, dt * (0.12 if wet_goal > g.wet_k else 0.012))
	g.fog_k = lerpf(0.55, 1.0, maxf(g.rain, g.sky_k * 0.8))
	curtain = move_toward(curtain, 1.0 if phase == "nublando" else 0.0, dt / 8.0)

func draw_sky(w: Node2D, hy: float) -> void:
	if curtain > 0.01:   # the downpour seen coming: a dark cloud bank with grey streaks down to the hills
		var cx := fposmod(250.0 - g.sky * 0.3, 500.0) - 50.0
		var cc: Color = g.e_top.lerp(Color(0.25, 0.28, 0.34), 0.6)
		cc.a = 0.65 * curtain
		w.draw_rect(Rect2(cx - 70.0, 18.0, 140.0, 14.0), cc)
		w.draw_rect(Rect2(cx - 50.0, 12.0, 90.0, 8.0), cc)
		var sc := Color(cc.r, cc.g, cc.b, 0.35 * curtain)
		var pts := PackedVector2Array()
		for i in 34:
			var x := cx - 66.0 + i * 4.0 + fmod(i * 7.3, 3.0)
			pts.append(Vector2(x, 32.0))
			pts.append(Vector2(x - 6.0, hy + 2.0))
		w.draw_multiline(pts, sc, 1.0)
		w.draw_colored_polygon(PackedVector2Array([Vector2(cx - 66, 32), Vector2(cx + 70, 32), Vector2(cx + 64, hy + 2), Vector2(cx - 72, hy + 2)]), Color(cc.r, cc.g, cc.b, 0.18 * curtain))
	if bow > 0.01:
		var a := bow * clampf((g.e_amb - 0.55) * 2.5, 0.0, 1.0)
		if a <= 0.01:
			return
		var cx := fposmod(bow_x - g.sky * 0.3, 900.0) - 250.0
		var cols := [Color("e8434a"), Color("f2a62a"), Color("ffe45a"), Color("6ad65a"), Color("4aa8e8"), Color("5a5ae0"), Color("a05ae0")]
		var r0 := 96.0
		for i in cols.size():
			var c: Color = cols[i]
			c.a = 0.45 * a
			w.draw_arc(Vector2(cx, hy + 14.0), r0 - i * 2.0, PI, TAU, 72, c, 2.0)
		var glow := Color(1, 1, 1, 0.06 * a)   # the sky is a touch brighter inside the bow
		w.draw_arc(Vector2(cx, hy + 14.0), r0 - 20.0, PI, TAU, 72, glow, 10.0)

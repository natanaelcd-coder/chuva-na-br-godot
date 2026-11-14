extends Node
# Ideia 16: passageiro que cochila. Optional company on the passenger seat (COMPANHIA, in the main menu and
# in the pause): the vó or a vira-lata caramelo. Smooth driving (multiplier x3, x4) lulls them to sleep;
# a pothole or a nudge wakes them with one discreet line. Nothing is ever taken away from the player.

const WHO := ["ninguem", "vo", "caramelo"]
const LABEL := {"ninguem": "COMPANHIA: SÓ EU", "vo": "COMPANHIA: VÓ", "caramelo": "COMPANHIA: CÃO"}
const HELLO := {"ninguem": "VIAGEM SÓ VOCÊ E A ESTRADA.", "vo": "A VÓ VAI DE CARONA, COM O CROCHÊ NO COLO.",
	"caramelo": "O CARAMELO VAI JUNTO, DE OLHO NA JANELA."}
const NECK := {"besouro": Vector2(340, 104), "picape": Vector2(338, 98), "gt": Vector2(342, 110)}   # logical units, per car
const LINES := {
	"vo": {
		"wake": ["VÓ: AI, MEU FILHO! QUE SUSTO.", "VÓ: HEIN? JÁ CHEGAMOS?", "VÓ: EU NÃO TAVA DORMINDO, TAVA DESCANSANDO O OLHO.", "VÓ: ESSA ESTRADA TÁ PRECISANDO DE PREFEITO."],
		"minor": ["VÓ: EITA.", "VÓ: DEVAGARINHO, FILHO.", "VÓ: CUIDADO COM O CROCHÊ."],
		"idle": ["VÓ: NO MEU TEMPO ISSO AQUI ERA TUDO TERRA.", "VÓ: VOCÊ TÁ COMENDO DIREITO?", "VÓ: LIGA NA AM, QUE TOCA AS ANTIGAS.", "VÓ: OLHA QUE CÉU BONITO."],
		"rain": ["VÓ: QUE CHUVINHA BOA PRA DORMIR...", "VÓ: FECHA ESSA JANELA QUE ENTRA ÁGUA."],
		"sleep": "A VÓ COCHILOU. VAI COM CALMA.",
		"stop": "VÓ: AI, QUE BOM. UM CAFEZINHO CAI BEM.",
	},
	"caramelo": {
		"wake": ["CARAMELO: AU!", "CARAMELO: AU! AU!", "(O CARAMELO LEVANTOU AS ORELHAS, ASSUSTADO)"],
		"minor": ["(O CARAMELO DEU UM ESPIRRO)", "(O CARAMELO OLHOU PRA VOCÊ, SÉRIO)"],
		"idle": ["(O CARAMELO PÔS A CABEÇA PRA FORA DA JANELA)", "(O RABO DO CARAMELO BATE NO BANCO)", "(O CARAMELO VIU UM PASSARINHO)"],
		"rain": ["(O CARAMELO OLHA AS GOTAS NO VIDRO)"],
		"sleep": "O CARAMELO DORMIU ENROLADINHO.",
		"stop": "CARAMELO: (DE OLHO FIRME NA COXINHA)",
	},
}

var g
var who := "ninguem"
var tex := {}
var sleep := 0.0       # 0 awake .. 1 asleep
var startle := 0.0
var say_cd := 0.0
var idle_t := 90.0
var slept := 0.0       # seconds asleep this trip
var told_sleep := false
var blink_t := 3.0
var t := 0.0
var main_item := {}
var pause_label := ""
var bust := {}   # "vo" / "caramelo" -> frame strip, when the PixelLab art exists
const BUST_SIZE := {"vo": Vector2(64, 80), "caramelo": Vector2(56, 56)}
const BUST_FALL := 9      # frames 0..8: awake .. fast asleep
const BUST_START := 4     # frames 9..12: the jolt awake
const BUST_BLINK := 2     # the frame used for a blink while awake

func _ready() -> void:
	g = get_parent()
	var w = g.store_get("companhia", "quem", "ninguem")
	who = w if WHO.has(w) else "ninguem"
	for n in ["vo_corpo", "vo_cabeca", "caramelo_corpo", "caramelo_cabeca"]:
		tex[n] = load("res://assets/sprites/%s.png" % n)
	# PixelLab bust frames (strip: BUST_FALL frames of dozing off, then BUST_START of waking up scared); old drawing as fallback
	for n in ["vo", "caramelo"]:
		var p := "res://assets/sprites/%s_busto_anim.png" % n
		if ResourceLoader.exists(p):
			bust[n] = load(p)
	g.menu.add_main_item(LABEL[who], _cycle)
	main_item = g.menu.extras.back()
	pause_label = LABEL[who]
	g.menu.add_pause_item(pause_label, _cycle)
	g.hole_hit.connect(func(_f, _side, k): _jolt(k > 0.7))
	g.jumped.connect(func(_air, k): if k > 0.5: _jolt(k > 0.85))   # a real landing after a crest: a start, and it wakes whoever was dozing
	g.bumped.connect(func(_kind): _jolt(true))
	g.trip_started.connect(func():
		slept = 0.0
		sleep = 0.0
		told_sleep = false
		idle_t = randf_range(60.0, 120.0))

func _cycle() -> void:
	who = WHO[(WHO.find(who) + 1) % WHO.size()]
	g.store_set("companhia", "quem", who)
	g.store_save()
	main_item.label = LABEL[who]
	var i: int = g.menu.PAUSE_ITEMS.find(pause_label)
	if i >= 0:
		var cb = g.menu.pause_cbs[pause_label]
		g.menu.pause_cbs.erase(pause_label)
		pause_label = LABEL[who]
		g.menu.PAUSE_ITEMS[i] = pause_label
		g.menu.pause_cbs[pause_label] = cb
	g.menu.refresh()
	g.hud.notice(HELLO[who], 3.0)
	sleep = 0.0

func _say(kind: String) -> void:
	if who == "ninguem" or say_cd > 0.0 or not g.started:
		return
	var l: Array = LINES[who][kind]
	g.hud.notice(l.pick_random(), 3.5)
	say_cd = 7.0

func _jolt(hard: bool) -> void:
	if who == "ninguem" or not g.started or g.state != "drive":
		return
	var was := sleep
	startle = 1.0 if hard or was > 0.4 else 0.5
	sleep = 0.0
	told_sleep = false
	if was > 0.4:
		_say("wake")
	elif hard and randf() < 0.5:
		_say("minor")

func _process(dt: float) -> void:
	t += dt
	startle = maxf(0.0, startle - dt)
	say_cd = maxf(0.0, say_cd - dt)
	blink_t -= dt
	if blink_t < -0.14:
		blink_t = randf_range(2.5, 5.0)
	if who == "ninguem" or g.state != "drive" or not g.started:
		if not g.started:
			sleep = 0.0
		return
	var goal := 0.0
	if g.mult >= 4:
		goal = 1.0
	elif g.mult == 3:
		goal = 0.55
	sleep += clampf(goal - sleep, -dt / 3.0, dt / 18.0)   # dozes off slowly, wakes quickly
	if sleep > 0.85:
		slept += dt
		if not told_sleep:
			told_sleep = true
			if say_cd <= 0.0:
				g.hud.notice(LINES[who].sleep, 3.0)
	if sleep < 0.3:
		idle_t -= dt
		if idle_t <= 0.0:
			idle_t = randf_range(110.0, 200.0)
			_say("rain" if g.rain > 0.3 and randf() < 0.5 else "idle")

# ---- for the other features (parada, diário)
func parada_line() -> String:
	return "" if who == "ninguem" else LINES[who].stop

func diary_line() -> String:
	if who == "ninguem":
		return ""
	var nm := "A VÓ" if who == "vo" else "O CARAMELO"
	if slept >= 30.0:
		return "%s DORMIU %d MIN" % [nm, maxi(1, int(round(slept / 60.0)))]
	return "%s FOI JUNTO, %s" % [nm, "ACORDADA" if who == "vo" else "ACORDADO"]

# ---- drawn on the passenger seat, over the right end of the dash (cockpit.gd: draw_cabin_mid)
func draw_cabin_mid(ck) -> void:
	if who == "ninguem":
		return
	var neck: Vector2 = NECK.get(g.cfg.car, NECK.besouro)
	neck.y += clampf((g.zb - g.zr) * 0.012, -4.0, 4.0) - startle * 3.0
	var mood := 0
	if startle > 0.35:
		mood = 3
	elif sleep > 0.8:
		mood = 2
	elif sleep > 0.35:
		mood = 1
	elif blink_t < 0.0:
		mood = 2
	if bust.has(who):
		_draw_bust(ck, neck, mood)
		return
	if who == "vo":
		ck.draw_texture_rect(tex.vo_corpo, Rect2(neck.x - 40, neck.y - 14, 80, 128), false)
		var a := sleep * 0.32 + sin(t * 0.7) * 0.03 * sleep
		var nod := sin(t * 1.4) * 1.2 if sleep > 0.35 and sleep < 0.8 else 0.0
		ck.draw_set_transform(neck + Vector2(0, nod), a, Vector2.ONE)
		ck.draw_texture_rect_region(tex.vo_cabeca, Rect2(-20, -36, 40, 44), Rect2(mood * 80, 0, 80, 88))
		ck._reset()
		if mood == 2 and sleep > 0.8:
			_zzz(ck, neck + Vector2(14, -38))
	else:
		var body := Vector2(neck.x - 35, neck.y - 14)
		ck.draw_texture_rect(tex.caramelo_corpo, Rect2(body.x, body.y, 72, 96), false)
		var a := sin(t * 9.0) * 0.03 * clampf(g.v / 80.0, 0.0, 1.0) if mood == 0 else 0.0
		var off := Vector2.ZERO
		if sleep > 0.8:   # head down on the seat
			off = Vector2(4, 16)
			a = -0.35
		ck.draw_set_transform(neck + off, a, Vector2.ONE)
		ck.draw_texture_rect_region(tex.caramelo_cabeca, Rect2(-22, -32, 44, 40), Rect2(mood * 88, 0, 88, 80))
		ck._reset()
		if mood == 2 and sleep > 0.8:
			_zzz(ck, neck + Vector2(16, -22))

func _draw_bust(ck, neck: Vector2, mood: int) -> void:
	var sz: Vector2 = BUST_SIZE[who]
	var fr := 0
	if startle > 0.35:   # the jolt: frames BUST_FALL.. while the scare fades
		fr = BUST_FALL + clampi(int((1.0 - startle) / 0.65 * BUST_START), 0, BUST_START - 1)
	elif sleep > 0.05:
		fr = clampi(int(round(sleep * (BUST_FALL - 1))), 0, BUST_FALL - 1)
	elif blink_t < 0.0:
		fr = BUST_BLINK
	var off := Vector2(0, 8 if who == "vo" else 14)
	var breathe := sin(t * (1.1 if sleep < 0.5 else 0.6)) * 0.6
	var r := Rect2(roundf(neck.x - sz.x / 2.0), roundf(neck.y - sz.y * 0.55 + off.y + breathe), sz.x, sz.y)
	var a := 0.0
	if who == "caramelo" and fr == 0:   # wags and leans a little with the speed, like a dog watching the road
		a = sin(t * 9.0) * 0.025 * clampf(g.v / 80.0, 0.0, 1.0)
	ck.draw_set_transform(Vector2(r.position.x + sz.x / 2.0, r.end.y), a, Vector2.ONE)
	ck.draw_texture_rect_region(bust[who], Rect2(-sz.x / 2.0, -sz.y, sz.x, sz.y), Rect2(fr * sz.x, 0, sz.x, sz.y))
	ck._reset()
	if sleep > 0.8 and startle < 0.1:
		_zzz(ck, Vector2(neck.x + 14, r.position.y + 8))

func _zzz(ck, p: Vector2) -> void:
	for i in 3:
		var ph := fmod(t * 0.35 + i / 3.0, 1.0)
		var q := p + Vector2(ph * 10.0 + sin(ph * 6.0 + i) * 2.0, -ph * 22.0)
		var s := 2.0 + ph * 2.0
		var c := Color(0.9, 0.92, 0.95, 0.9 * (1.0 - ph))
		ck.draw_line(q, q + Vector2(s, 0), c, 0.6)
		ck.draw_line(q + Vector2(s, 0), q + Vector2(0, s), c, 0.6)
		ck.draw_line(q + Vector2(0, s), q + Vector2(s, s), c, 0.6)

extends Node
# Ideia 1: hodômetro de verdade. O placar de fliperama ("1P / HI-SCORE") vira km: os da viagem de hoje e os da vida
# do carro, que cada carro guarda para sempre (seção [hodometro] do viagem.cfg). Marcos discretos no rodapé.
# Também desenha o hodômetro de tambor no painel, embaixo do velocímetro. A pontuação continua existindo em g.score.

const Cat = preload("res://scripts/catalog.gd")
const SHORT := {"besouro": "BESOURO", "picape": "PICAPE", "gt": "SEDÃ GT"}
const ARTICLE := {"besouro": "ESTE BESOURO", "picape": "ESTA PICAPE", "gt": "ESTE GT"}
const MILESTONES := [10, 50, 100, 250, 500, 1000, 2000, 3000, 5000, 7500, 10000, 15000, 20000, 30000, 50000, 75000, 100000]
const TRIP_STEP := 25.0   # a quiet line every 25 km of the same trip

var g
var _last_trip := 0.0
var _save_t := 0.0
var _trip_mark := 0.0

func _ready() -> void:
	g = get_parent()
	g.trip_started.connect(_on_start)
	g.trip_ended.connect(_on_end)

func _on_start() -> void:
	_last_trip = 0.0
	_trip_mark = TRIP_STEP

func _on_end(_s: Dictionary) -> void:
	_flush()

# km this car has done in its whole life (live, including the trip under way)
func car_km(id: String = "") -> float:
	if id == "":
		id = g.cfg.car
	return float(g.store_get("hodometro", id, 0.0))

func total_km() -> float:   # every car together: what unlocks the cabin prizes
	var s := 0.0
	for id in Cat.CAR_IDS:
		s += car_km(id)
	return s

func _process(dt: float) -> void:
	if g == null or g.segs.is_empty():
		return
	if g.started:
		var d: float = g.km_trip - _last_trip
		_last_trip = g.km_trip
		if d > 0.0 and d < 1.0:
			var before := car_km()
			var after := before + d
			g.store_set("hodometro", g.cfg.car, after)
			for m in MILESTONES:
				if before < m and after >= m:
					g.hud.notice("%s JÁ RODOU %s KM" % [ARTICLE.get(g.cfg.car, "ESTE CARRO"), thousands(m)], 5.0)
			if g.km_trip >= _trip_mark:
				g.hud.notice("%s KM NESTA VIAGEM. SEM PRESSA." % thousands(int(_trip_mark)), 4.0)
				_trip_mark += TRIP_STEP
		_save_t += dt
		if _save_t > 10.0:
			_flush()
	if g.hud.has_method("set_odo"):
		g.hud.set_odo("HOJE: %s KM" % km1(g.km_trip if g.started else 0.0), "%s: %s KM" % [SHORT.get(g.cfg.car, "CARRO"), thousands(int(car_km()))])

func _flush() -> void:
	_save_t = 0.0
	g.store_save()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and g != null:
		g.store_save()

# 1284 -> "1.284"; no ceiling, the number only grows
static func thousands(n: int) -> String:
	var s := str(absi(n))
	var out := ""
	while s.length() > 3:
		out = "." + s.substr(s.length() - 3) + out
		s = s.substr(0, s.length() - 3)
	return s + out

# 12.34 -> "12,3"
static func km1(x: float) -> String:
	var tenths := int(floorf(x * 10.0))
	return "%s,%d" % [thousands(tenths / 10), tenths % 10]

# the menu line under the title: this car's life, and how the collections are going
func menu_info() -> String:
	var txt := "SEU %s: %s KM" % [SHORT.get(g.cfg.car, "CARRO"), thousands(int(car_km()))]
	var cad = g.get_node_or_null("caderneta")
	if cad != null and cad.has_method("count"):
		var c: Array = cad.count()
		txt += "  FIGURINHAS %d/%d" % [c[0], c[1]]
	return txt

# --- the drum odometer on the dashboard, under the speedometer: five white wheels and a red one for tenths
func draw_cabin_mid(c) -> void:
	var sp: Array = g.car.layout.speedo
	var km := car_km()
	var digits := "%06d" % (int(floorf(km * 10.0)) % 1000000)   # like the real one, it rolls over at 99.999,9
	var dw := 2.5
	var x0: float = roundf(sp[0] - dw * 3.0)
	var y0: float = roundf(sp[1] + sp[2] * 0.5 + 0.5)
	c.draw_rect(Rect2(x0 - 0.5, y0 - 0.5, dw * 6.0 + 1.0, 4.0), Color("05070c"))
	c.draw_rect(Rect2(x0 + dw * 5.0, y0 - 0.5, dw + 0.5, 4.0), Color("7a1620"))
	for i in 6:
		_digit3(c, digits[i], x0 + i * dw + 0.5, y0, Color("e6e8ee") if i < 5 else Color("ffd6d6"))

# a 3-unit-tall seven-segment digit (the GT clock's are 4.5 tall; the drum is smaller)
func _digit3(c, ch: String, x: float, y: float, col: Color) -> void:
	var s: String = c.SEG7.get(ch, "0000000")
	var r := [Rect2(x, y, 1.5, 0.5), Rect2(x + 1.0, y, 0.5, 1.5), Rect2(x + 1.0, y + 1.5, 0.5, 1.5), Rect2(x, y + 2.5, 1.5, 0.5),
		Rect2(x, y + 1.5, 0.5, 1.5), Rect2(x, y, 0.5, 1.5), Rect2(x, y + 1.25, 1.5, 0.5)]
	for i in 7:
		if s[i] == "1":
			c.draw_rect(r[i], col)

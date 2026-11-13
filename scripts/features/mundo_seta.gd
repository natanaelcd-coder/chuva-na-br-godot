extends Node
# Ideia 12: on a two-way road (Estrada do Sítio) the slow tractor or truck ahead of you gives the right
# blinker when the oncoming lane is clear, the road custom for "pode passar". Overtake while it blinks
# and it thanks you with two short toots.

const CLEAR := 42000.0    # how much empty oncoming lane it wants to see before waving you by
var g
var a_horn: AudioStreamPlayer
var _beeps: Array = []    # times (s) of the thank-you toots still to play
var _check_t := 0.0
var thanks := 0           # thank-you toots this trip (tests read it)

func _ready() -> void:
	g = get_parent()
	a_horn = AudioStreamPlayer.new()
	a_horn.stream = load("res://assets/audio/horn.wav")
	a_horn.pitch_scale = 1.4
	a_horn.volume_db = -5.0
	add_child(a_horn)
	g.trip_started.connect(func(): thanks = 0)

func _slow(c: Dictionary) -> bool:   # the kind of vehicle that waves you past
	return c.tex == g.tex["trator"] or c.get("slow", false) or c.get("cur", c.v) < g.v - 6.0 or c.get("cur", c.v) < g.target - 10.0

func _process(dt: float) -> void:
	if g.state == "pause":
		return
	if a_horn.playing and a_horn.get_playback_position() > 0.14:
		a_horn.stop()   # short toots, not the full horn
	if not _beeps.is_empty():
		_beeps[0] -= dt
		if _beeps[0] <= 0.0:
			_beeps.pop_front()
			if g.started:
				a_horn.play()
	if not g.road.two_way:
		return
	_check_t -= dt
	var check := _check_t <= 0.0
	if check:
		_check_t = 0.2
	var clear := true
	if check:
		clear = g._oncoming_clear(CLEAR)
	var home: float = g.LANES[g.road.ours.back()]
	var track: float = g.TRACK
	for c in g.cars:
		if c.dir < 0 or absf(c.x - home) > 0.3:
			continue
		var d := fposmod(c.z - g.pos, track)
		var prev: float = c.get("seta_d", d)
		c.seta_d = d
		# passed it: it was ahead of us a moment ago and now it is behind
		if prev < 2500.0 and d > track - 2500.0:
			if c.get("blink_t", 0.0) > 0.0 or c.get("blink_hold", 0.0) > 0.0:
				_thank(c)
			c.blink_t = 0.0
			c.behind_t = 0.0
			continue
		c.blink_hold = maxf(0.0, c.get("blink_hold", 0.0) - dt)
		if not check:
			continue
		var behind: bool = d > 500.0 and d < 4200.0 and absf(g.px - c.x) < 0.5 and _slow(c)
		var alongside: bool = d < 2200.0 and absf(g.px - c.x) >= 0.5   # we are already overtaking: keep blinking
		c.behind_t = c.get("behind_t", 0.0) + 0.2 if behind else 0.0
		if (behind and c.behind_t > 1.2 and clear) or (alongside and c.get("blink_t", 0.0) > 0.0):
			if c.get("blink_t", 0.0) <= 0.0:
				g.feature_call("world_event", ["seta"])
			c.blink_t = c.get("blink_t", 0.0) + 0.2
			c.blink_hold = 2.5   # passing just after it stopped blinking still counts
		else:
			c.blink_t = 0.0

func _thank(c: Dictionary) -> void:
	c.blink_hold = 0.0
	if not g.started:
		return
	thanks += 1
	_beeps = [0.35, 0.25]
	g.hud.notice("BI-BI! O MOTORISTA AGRADECEU A ULTRAPASSAGEM", 3.5)
	g.feature_call("world_event", ["camaradagem"])

func draw_car(w: Node2D, c: Dictionary, r: Rect2, alpha: float) -> void:
	if c.get("blink_t", 0.0) <= 0.0 or c.dir < 0:
		return
	if fmod(g.t, 0.8) > 0.42:   # about 75 blinks a minute, like the real relay
		return
	var tr: bool = c.tex == g.tex["trator"]
	var x := r.position.x + r.size.x * (0.69 if tr else 0.86)
	var y := r.position.y + r.size.y * (0.62 if tr else 0.53)
	var s := maxf(1.0, r.size.x * 0.07)
	w.draw_rect(Rect2(x - s * 0.5, y - s * 0.5, s, s), Color(1.0, 0.72, 0.15, alpha))
	w._glow(x, y, s * 3.0 + 2.0, Color(1.0, 0.65, 0.1), 0.85 * alpha)
	w._reflect(x, r.position.y + r.size.y, s * 1.6, r.size.y * 0.3, Color(1.0, 0.65, 0.1, 0.25 * alpha))

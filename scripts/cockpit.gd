extends Node2D
# Inside view: rain on the glass and wipers, the painted cabin of the chosen car, and everything in it that moves.
# Where things sit (wheel, gauges, radio, mirror, ornaments) comes from that car's "layout" in catalog.gd.

const W := 384.0
var g
var cock: Texture2D
var lay: Dictionary
const SEG7 := {   # tiny seven-segment digits for the GT's dashboard clock: a b c d e f g
	"0": "1111110", "1": "0110000", "2": "1101101", "3": "1111001", "4": "0110011",
	"5": "1011011", "6": "1011111", "7": "1110000", "8": "1111111", "9": "1111011"}

func _ready() -> void:
	g = get_parent()

func setup() -> void:
	lay = g.car.layout
	cock = g.tex[g.car.cockpit]
	queue_redraw()

func _process(_dt: float) -> void:
	if visible:
		queue_redraw()

func R(c: String, x: float, y: float, w: float, h: float) -> void:
	draw_rect(Rect2(x, y, w, h), Color(c))

func _reset() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _cap_line(a: Vector2, b: Vector2, c: Color, w: float) -> void:
	draw_line(a, b, c, w)
	draw_circle(a, w / 2.0, c)
	draw_circle(b, w / 2.0, c)

func _dashes(r: float, count: int, span: float, c: Color, w: float) -> void:
	for i in count:
		var a := TAU * i / count
		draw_arc(Vector2.ZERO, r, a, a + span, 4, c, w)

func _needle(c: Vector2, len: float, frac: float, col: Color) -> void:
	var a := PI * 0.8 + clampf(frac, 0.0, 1.0) * PI * 1.4
	draw_line(c, c + Vector2(cos(a), sin(a)) * len, col, 1.0)
	R("e6e8ee", c.x - 0.5, c.y - 0.5, 1, 1)

func _digit(ch: String, x: float, y: float, col: Color) -> void:
	var s: String = SEG7.get(ch, "0000000")
	var segs := [Rect2(x, y, 2, 0.5), Rect2(x + 2, y, 0.5, 2), Rect2(x + 2, y + 2, 0.5, 2), Rect2(x, y + 4, 2, 0.5),
		Rect2(x, y + 2, 0.5, 2), Rect2(x, y, 0.5, 2), Rect2(x, y + 2, 2, 0.5)]
	for i in 7:
		if s[i] == "1":
			draw_rect(segs[i], col)

func _draw() -> void:
	if lay.is_empty():
		return
	# --- on the glass, outside
	var drop_c := Color(0.61, 0.73, 0.88, 0.75)
	var drop_s := Color(0.03, 0.05, 0.09, 0.5)
	for d in g.drops:
		var dx := roundf(d[0] * 2.0) / 2.0
		var dy := roundf(d[1] * 2.0) / 2.0
		if d[2] > 1.0:
			draw_rect(Rect2(dx, dy, 1.0, 1.5), drop_c)
			draw_rect(Rect2(dx, dy + 1.5, 1.0, 0.5), drop_s)
		else:
			draw_rect(Rect2(dx, dy, 0.5, 0.75), drop_c)
	var wa: float = g.wip_a
	for w in g.WIP:
		draw_line(w, w + Vector2(cos(wa), sin(wa)) * g.WLEN, Color("05070c"), 1.5)

	draw_texture_rect(cock, Rect2(0, 0, 384, 216), false)

	# --- mirrors: whoever is behind
	var behind := 1e9
	for c in g.cars:
		if c.dir > 0:
			behind = minf(behind, fposmod(g.pos - c.z, g.TRACK))
	var m: Array = lay.mirror
	var mc: float = m[0] + m[2] / 2.0 - 6.0
	R("1a2547", m[0], m[1], m[2], m[3])
	R("fff3b0", m[0] + m[2] - 9, m[1] - 1, 1, 1)
	R("fff3b0", m[0] + m[2] - 6, m[1] - 1, 1, 1)
	var sd: Array = lay.side
	if behind < 9000.0:
		var k := 1.0 - behind / 9000.0
		var w := 2.0 + k * 8.0
		var mh := 2.0 if k > 0.5 else 1.0
		R("fff3b0", mc - w / 2.0, m[1] - 2.0 + k * 2.0, 2, mh)
		R("fff3b0", mc + w / 2.0, m[1] - 2.0 + k * 2.0, 2, mh)
		R("ffd65a", sd[0] + 6, sd[1] - 3, 2, 2)
		R("ffd65a", sd[0] + 12, sd[1] - 3, 2, 2)
	R("1a2547", sd[0], sd[1], sd[2], sd[3])

	# --- fan and bobble dog (the Besouro's dashboard friends)
	if not lay.fan.is_empty():
		var fc := Vector2(lay.fan[0], lay.fan[1])
		draw_arc(fc, 8.0, 0.0, TAU, 24, Color("a8acb5"), 1.0)
		for i in 3:
			var a: float = g.fan_a + i * 2.094
			draw_line(fc, fc + Vector2(cos(a), sin(a)) * 6.0, Color("6f97c4"), 2.0)
		R("e6e8ee", fc.x - 0.5, fc.y - 0.5, 1, 1)
	if not lay.dog.is_empty():
		var bob: float = g.bob
		var hy := roundf(lay.dog[1] + bob * 3.0)
		var hx := roundf(lay.dog[0] + bob * 1.5)
		R("96643a", hx, hy, 13, 11)
		R("6e4526", hx - 2, hy + 1, 3, 8)
		R("6e4526", hx + 12, hy + 1, 3, 8)
		R("e3ab7c", hx + 3, hy + 6, 7, 5)
		R("0a0a0f", hx + 3, hy + 4, 2, 2)
		R("0a0a0f", hx + 8, hy + 4, 2, 2)
		R("0a0a0f", hx + 5, hy + 7, 3, 2)
		R("f0484a", hx + 6, hy + 10, 2, 1)

	# --- whatever hangs from the rear-view mirror
	var dice: float = g.dice
	var ax: float = lay.anchor[0]
	var ay: float = lay.anchor[1]
	for item in lay.hang:
		match item:
			"rosary":
				for i in range(1, 10):
					var l := i * 6.0
					var a := dice * (0.6 + i * 0.04)
					R("6e4526" if i % 3 else "c68a5a", roundf(ax - 2.0 + sin(a) * l), roundf(ay + cos(a) * l), 2, 2)
				var rx := roundf(ax - 2.0 + sin(dice * 0.96) * 60.0)
				var ry := roundf(ay + cos(dice * 0.96) * 60.0)
				R("ffd65a", rx, ry, 2, 7)
				R("ffd65a", rx - 2, ry + 2, 6, 2)
				R("c47a1c", rx - 1, ry + 8, 4, 6)
			"dice":
				var die := [[8.0, 66.0, 0.15, [[-3, -3], [3, 3], [-3, 3], [3, -3]]], [15.0, 72.0, -0.2, [[-3, -3], [3, 3], [0, 0]]]]
				for k in 2:
					var d: Array = die[k]
					var a := dice * (1.05 + k * 0.1)
					var p := Vector2(ax + d[0] + sin(a) * d[1], ay + cos(a) * d[1])
					draw_line(Vector2(ax + 1.0, ay), p, Color("e6e8ee"), 0.5)
					draw_set_transform(p + Vector2(0, 5), d[2] - a * 0.6, Vector2.ONE)
					R("c22630", -6, -6, 12, 12)
					R("f0484a", -6, -6, 12, 2)
					R("7a1620", -6, 4, 12, 2)
					for pip in d[3]:
						R("e6e8ee", pip[0] - 1, pip[1] - 1, 2, 2)
					_reset()
			"ribbons":   # wish ribbons from a church fair, the pickup's good-luck charm
				var cols := ["c22630", "ffd65a", "3fae5a", "3d5f94", "e6e8ee", "f2a62a"]
				for k in cols.size():
					var a := dice * (1.0 + k * 0.08) + (k - 2.5) * 0.06
					var len := 30.0 + (k % 3) * 6.0
					var p0 := Vector2(ax + (k - 2.5) * 1.2, ay)
					var p1 := p0 + Vector2(sin(a) * len * 0.5 + sin(g.t * 3.0 + k) * 0.6, len * 0.5)
					var p2 := p0 + Vector2(sin(a * 1.2) * len, len)
					draw_polyline(PackedVector2Array([p0, p1, p2]), Color(cols[k]), 1.0)
			"pine":      # pine-tree air freshener
				var a := dice * 1.0
				var p := Vector2(ax + sin(a) * 34.0, ay + cos(a) * 34.0)
				draw_line(Vector2(ax, ay), p, Color("e6e8ee"), 0.5)
				draw_set_transform(p, -a * 0.8, Vector2.ONE)
				draw_colored_polygon(PackedVector2Array([Vector2(0, 0), Vector2(6, 9), Vector2(3, 9), Vector2(7, 15), Vector2(-7, 15), Vector2(-3, 9), Vector2(-6, 9)]), Color("23743f"))
				R("3fae5a", -3, 7, 6, 1)
				R("16482c", -1, 15, 2, 3)
				_reset()

	g.feature_call("draw_hang", [self, Vector2(ax, ay)])   # features: more things hanging from the mirror
	g.feature_call("draw_cabin_mid", [self])              # features: passenger, dash items (under the wheel and arm)

	# --- gauges, clock and radio
	var sp_: Array = lay.speedo
	_needle(Vector2(sp_[0], sp_[1]), sp_[2], g.v / sp_[3], Color("f2a62a"))
	if not lay.tach.is_empty():
		var lo: float = g.GEAR_LO[g.gear_i]
		var hi: float = g.GEAR_HI[g.gear_i]
		var rpm := 0.12 + 0.85 * clampf((g.v - lo) / maxf(1.0, hi - lo), 0.0, 1.0) if g.v > 1.0 else 0.12
		_needle(Vector2(lay.tach[0], lay.tach[1]), lay.tach[2], rpm, Color("f0484a"))
	if not lay.fuel.is_empty():
		var fa: float = PI * 1.2 + g.fuel * PI * 0.6
		var fc2 := Vector2(lay.fuel[0], lay.fuel[1])
		draw_line(fc2, fc2 + Vector2(cos(fa), sin(fa)) * lay.fuel[2], Color("e6e8ee"), 1.0)
	if not lay.clock.is_empty():   # the in-game hour, from the sky
		var hours := fposmod(14.0 + g.tday * 6.0, 24.0)
		var hh := int(hours)
		var mm := int((hours - hh) * 60.0)
		var txt := "%02d%02d" % [hh, mm]
		var cx0: float = lay.clock[0]
		for i in 4:
			_digit(txt[i], cx0 + i * 3.5 + (1.0 if i > 1 else 0.0), lay.clock[1], Color("3fe0e8"))
		if int(g.t * 2.0) % 2 == 0:
			R("3fe0e8", cx0 + 7.2, lay.clock[1] + 1.2, 0.5, 0.5)
			R("3fe0e8", cx0 + 7.2, lay.clock[1] + 3.0, 0.5, 0.5)
	var on: bool = g.radio_st < g.STATIONS.size()
	var label: int = 4 if g.static_t > 0.0 else g.radio_st
	draw_texture_rect(g.tex["label%d" % label], Rect2(lay.label[0], lay.label[1], 40, 5), false)
	if on:
		var sp: float = g.t * 3.0
		for r in lay.reels:   # tape reels turning
			draw_circle(Vector2(r[0] + cos(sp) * 0.8, r[1] + sin(sp) * 0.8), 0.7, Color("2b1a12"))
		if not lay.eq.is_empty():   # equalizer bars dancing to the radio
			var e: Array = lay.eq
			for i in 12:
				var hgt: float = (0.3 + 0.7 * absf(sin(g.t * (3.0 + i * 0.7) + i * 1.3))) * e[3]
				var col := "3fae5a" if hgt < e[3] * 0.6 else ("ffd65a" if hgt < e[3] * 0.85 else "f0484a")
				R(col, e[0] + i * 5.2, e[1] + e[3] - hgt, 3.5, hgt)

	# --- steering wheel
	var wheel: float = g.wheel_a
	var cx: float = lay.wheel[0]
	var cy: float = lay.wheel[1]
	var wr: float = lay.wheel[2]
	draw_set_transform_matrix(Transform2D(0.0, Vector2(1.0, 0.94), 0.0, Vector2(cx, cy)) * Transform2D(wheel, Vector2.ZERO))
	match lay.wheel_style:
		"picape":   # big thin ivory wheel, two spokes and a chrome horn ring
			draw_polyline(PackedVector2Array([Vector2(-wr + 2, 2), Vector2(-10, 4), Vector2(10, 4), Vector2(wr - 2, 2)]), Color("cfe0f2"), 4.0)
			draw_arc(Vector2(0, 2), 22.0, 0.0, TAU, 40, Color("a8acb5"), 1.5)
			draw_arc(Vector2.ZERO, wr, 0.0, TAU, 72, Color("a8acb5"), 6.0)
			draw_arc(Vector2.ZERO, wr, 0.0, TAU, 72, Color("e6e8ee"), 4.0)
			_dashes(wr - 1.0, 40, 2.0 / wr, Color("cfe0f2"), 1.0)
			draw_circle(Vector2(0, 3), 9.0, Color("a8acb5"))
			draw_circle(Vector2(0, 3), 7.0, Color("e6e8ee"))
			R("c22630", -2, 1, 4, 4)
		"gt":       # chunky three-spoke leather sport wheel with a red top marker
			draw_polyline(PackedVector2Array([Vector2(-wr + 3, 6), Vector2(0, 8), Vector2(wr - 3, 6)]), Color("2a2c33"), 8.0)
			draw_line(Vector2(0, 8), Vector2(0, wr - 3), Color("2a2c33"), 9.0)
			draw_arc(Vector2.ZERO, wr, 0.0, TAU, 64, Color("0a0a0f"), 11.0)
			_dashes(wr, 36, 1.0 / wr, Color("2a2c33"), 9.0)
			draw_arc(Vector2.ZERO, wr, -PI * 0.53, -PI * 0.47, 6, Color("c22630"), 11.0)
			draw_circle(Vector2(0, 7), 12.0, Color("16202b"))
			draw_circle(Vector2(0, 7), 9.0, Color("0a0a0f"))
			R("c22630", -4, 6, 8, 1.5)
		_:          # the Besouro's wheel with its knitted cover
			draw_polyline(PackedVector2Array([Vector2(-50, 8), Vector2(0, 4), Vector2(50, 8)]), Color("16202b"), 7.0)
			draw_arc(Vector2(0, 4), 26.0, 0.12 * PI, 0.88 * PI, 24, Color("a8acb5"), 2.0)
			draw_arc(Vector2.ZERO, 52.0, 0.0, TAU, 64, Color("1a2547"), 10.0)
			_dashes(52.0, 30, 6.0 / 52.0, Color("3d5f94"), 8.0)
			_dashes(54.0, 31, 3.0 / 54.0, Color("6f97c4"), 2.0)
			for i in 100:
				var a := TAU * i / 100.0
				draw_rect(Rect2(cos(a) * 48.5 - 0.25, sin(a) * 48.5 - 0.25, 0.5, 0.5), Color("cfe0f2"))
			draw_circle(Vector2(0, 4), 12.0, Color("0a0a0f"))
			draw_circle(Vector2(0, 4), 9.0, Color("2a2c33"))
			draw_arc(Vector2(0, 4), 5.0, 0.0, TAU, 20, Color("a8acb5"), 1.0)
			R("a8acb5", -1, 1, 2, 6)
	g.feature_call("draw_wheel", [self, wr])   # features: wheel covers (in the turning wheel's frame; rim of radius wr at the origin)
	_reset()

	# --- arm, watch, hand
	var ha := PI + 0.28 + wheel * 0.55
	var h := Vector2(cx + cos(ha) * wr, cy + sin(ha) * wr * 0.94)
	var e := Vector2(-8, 212)
	_cap_line(e + Vector2(0, 2), h + Vector2(-4, 5), Color("96643a"), 19.0)
	_cap_line(e, h + Vector2(-4, 4), Color("c68a5a"), 16.0)
	draw_set_transform(e.lerp(h, 0.62), (h - e).angle(), Vector2.ONE)
	R("777b86", -5, -10, 9, 20)
	R("2a2c33", -7, -7, 13, 14)
	R("8fe07a", -4, -4, 7, 8)
	R("16482c", -3, -1, 5, 1)
	_reset()
	draw_circle(h, 10.0, Color("c68a5a"))
	draw_circle(h + Vector2(2, -3), 6.0, Color("e3ab7c"))
	for i in range(-1, 3):
		draw_line(h + Vector2(1 + i, -8 + i * 4), h + Vector2(8, -6 + i * 4), Color("96643a"), 0.5)
	g.feature_call("draw_cabin_over", [self])   # features: anything over the whole cabin

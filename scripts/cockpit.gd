extends Node2D
# Inside view: rain on the glass and wipers, the painted cabin (cockpit.png), and everything in it that moves.

const W := 384.0
var g
var cock: Texture2D = preload("res://assets/sprites/cockpit.png")

func _ready() -> void:
	g = get_parent()

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

func _draw() -> void:
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
	R("1a2547", 170, 25, 44, 5)
	R("fff3b0", 205, 24, 1, 1)
	R("fff3b0", 208, 24, 1, 1)
	if behind < 9000.0:
		var k := 1.0 - behind / 9000.0
		var w := 2.0 + k * 8.0
		var mx := 186.0 - w / 2.0
		var my := 23.0 + k * 2.0
		var mh := 2.0 if k > 0.5 else 1.0
		R("fff3b0", mx, my, 2, mh)
		R("fff3b0", mx + w, my, 2, mh)
		R("ffd65a", 9, 87, 2, 2)
		R("ffd65a", 15, 87, 2, 2)
	R("1a2547", 3, 90, 19, 4)

	# --- fan
	var fc := Vector2(160.5, 104.5)
	draw_arc(fc, 8.0, 0.0, TAU, 24, Color("a8acb5"), 1.0)
	for i in 3:
		var a: float = g.fan_a + i * 2.094
		draw_line(fc, fc + Vector2(cos(a), sin(a)) * 6.0, Color("6f97c4"), 2.0)
	R("e6e8ee", 160, 104, 1, 1)

	# --- bobble dog
	var bob: float = g.bob
	var hy := roundf(95.0 + bob * 3.0)
	var hx := roundf(233.0 + bob * 1.5)
	R("96643a", hx, hy, 13, 11)
	R("6e4526", hx - 2, hy + 1, 3, 8)
	R("6e4526", hx + 12, hy + 1, 3, 8)
	R("e3ab7c", hx + 3, hy + 6, 7, 5)
	R("0a0a0f", hx + 3, hy + 4, 2, 2)
	R("0a0a0f", hx + 8, hy + 4, 2, 2)
	R("0a0a0f", hx + 5, hy + 7, 3, 2)
	R("f0484a", hx + 6, hy + 10, 2, 1)

	# --- rosary and dice hanging from the mirror
	var dice: float = g.dice
	var ax := 192.0
	var ay := 33.0
	for i in range(1, 10):
		var l := i * 6.0
		var a := dice * (0.6 + i * 0.04)
		R("6e4526" if i % 3 else "c68a5a", roundf(ax - 2.0 + sin(a) * l), roundf(ay + cos(a) * l), 2, 2)
	var rx := roundf(ax - 2.0 + sin(dice * 0.96) * 60.0)
	var ry := roundf(ay + cos(dice * 0.96) * 60.0)
	R("ffd65a", rx, ry, 2, 7)
	R("ffd65a", rx - 2, ry + 2, 6, 2)
	R("c47a1c", rx - 1, ry + 8, 4, 6)
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

	# --- gauges and radio
	var na := PI * 0.8 + clampf(g.v / 120.0, 0.0, 1.0) * PI * 1.4
	draw_line(Vector2(120.5, 138.5), Vector2(120.5 + cos(na) * 9.0, 138.5 + sin(na) * 9.0), Color("f2a62a"), 1.0)
	R("e6e8ee", 120, 138, 1, 1)
	var fa: float = PI * 1.2 + g.fuel * PI * 0.6
	draw_line(Vector2(148.5, 150.5), Vector2(148.5 + cos(fa) * 6.0, 150.5 + sin(fa) * 6.0), Color("e6e8ee"), 1.0)
	var on: bool = g.radio_st < g.STATIONS.size()
	var label: int = 4 if g.static_t > 0.0 else g.radio_st
	draw_texture_rect(g.tex["label%d" % label], Rect2(198, 144, 40, 5), false)
	if on:   # tape reels turning
		var sp: float = g.t * 3.0
		draw_circle(Vector2(210.0 + cos(sp) * 0.8, 162.0 + sin(sp) * 0.8), 0.7, Color("2b1a12"))
		draw_circle(Vector2(226.0 + cos(sp) * 0.8, 162.0 + sin(sp) * 0.8), 0.7, Color("2b1a12"))

	# --- steering wheel
	var wheel: float = g.wheel_a
	var cx := 112.0
	var cy := 164.0
	draw_set_transform_matrix(Transform2D(0.0, Vector2(1.0, 0.94), 0.0, Vector2(cx, cy)) * Transform2D(wheel, Vector2.ZERO))
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
	_reset()

	# --- arm, watch, hand
	var ha := PI + 0.28 + wheel * 0.55
	var h := Vector2(cx + cos(ha) * 52.0, cy + sin(ha) * 52.0 * 0.94)
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

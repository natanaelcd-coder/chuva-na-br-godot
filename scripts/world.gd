extends Node2D
# Draws sky, hills, the pseudo-3D road, roadside sprites, traffic and (in the chase view) the player's car.
# Works in logical 384x216 units; the node is scaled 2x, so half a unit is one real pixel.

const W := 384.0
const SEG := 200.0
const DRAW := 150
const DEPTH := 0.84
const X0 := -40.0
const XW := 464.0
const NONE := Rect2(0, 0, 0, 0)
const LIGHT := Color(1.0, 0.88, 0.59)

var g
var glow_tex: GradientTexture2D

func _ready() -> void:
	g = get_parent()
	var gr := Gradient.new()
	gr.set_color(0, Color(1, 1, 1, 1))
	gr.set_color(1, Color(1, 1, 1, 0))
	glow_tex = GradientTexture2D.new()
	glow_tex.gradient = gr
	glow_tex.fill = GradientTexture2D.FILL_RADIAL
	glow_tex.fill_from = Vector2(0.5, 0.5)
	glow_tex.fill_to = Vector2(1.0, 0.5)
	glow_tex.width = 64
	glow_tex.height = 64

func _process(_dt: float) -> void:
	# inside the car the world tilts and bobs against the cabin: roll and pitch of the body
	if g.cam == 0:
		var c := Vector2(W / 2.0, g.view.hy + 40.0)
		var r: float = -g.roll * 1.5 * g.view_sway
		var o: Vector2 = c + (Vector2(0.0, g.pitch * 190.0 * g.view_sway) - c).rotated(r)
		transform = Transform2D(r, Vector2(2, 2), 0.0, o * 2.0)
	else:
		transform = Transform2D(0.0, Vector2(2, 2), 0.0, Vector2.ZERO)
	queue_redraw()

func _quad(c: Color, p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2) -> void:
	draw_primitive(PackedVector2Array([p0, p1, p2, p3]), PackedColorArray([c]), PackedVector2Array())

func _trap(c: Color, x1: float, y1: float, w1: float, x2: float, y2: float, w2: float) -> void:
	_quad(c, Vector2(x1 - w1, y1), Vector2(x2 - w2, y2), Vector2(x2 + w2, y2), Vector2(x1 + w1, y1))

# light smeared on wet asphalt: three thin stripes that narrow and fade toward the viewer
func _reflect(cx: float, y: float, w: float, h: float, c: Color) -> void:
	for i in 3:
		var t := i / 3.0
		var ww := w * (1.0 - t * 0.6)
		draw_rect(Rect2(cx - ww / 2.0, y + h * t + h * 0.08, ww, maxf(0.5, h * 0.18)), Color(c.r, c.g, c.b, c.a * (1.0 - t * 0.55)))

func _glow(x: float, y: float, r: float, col: Color, a: float) -> void:
	if r >= 1.0:
		draw_texture_rect(glow_tex, Rect2(x - r, y - r, r * 2.0, r * 2.0), false, Color(col.r, col.g, col.b, a))

func _sprite(tx: Texture2D, ww: float, s: float, sx: float, sy: float, clip: float, alpha: float) -> Rect2:
	var w := s * ww * W / 2.0
	var h := w * tx.get_height() / tx.get_width()
	if w < 0.8:
		return NONE
	var x := roundf((sx - w / 2.0) * 2.0) / 2.0
	var y := roundf((sy - h) * 2.0) / 2.0
	var cut := sy - clip if clip < sy else 0.0
	if cut >= h:
		return NONE
	draw_texture_rect_region(tx, Rect2(x, y, ceilf(w * 2.0) / 2.0, ceilf((h - cut) * 2.0) / 2.0),
			Rect2(0, 0, tx.get_width(), tx.get_height() * (1.0 - cut / h)), Color(1, 1, 1, alpha))
	return Rect2(x, y, w, h)

var _sign_cols := {}
func _sign_far(tx: Texture2D, w: float, sx: float, sy: float, clip: float, alpha: float) -> void:
	if w < 0.8:
		return
	if not _sign_cols.has(tx):
		var img := tx.get_image()
		_sign_cols[tx] = img.get_pixel(8, 8)
	var bg: Color = _sign_cols[tx]
	var h := w * tx.get_height() / tx.get_width()
	var x := roundf((sx - w / 2.0) * 2.0) / 2.0
	var y := roundf((sy - h) * 2.0) / 2.0
	if y + h * 0.5 > clip:
		return
	draw_rect(Rect2(x + w * 0.14, y + h * 0.45, maxf(0.5, w * 0.04), h * 0.55), Color(0.29, 0.30, 0.34, alpha))
	draw_rect(Rect2(x + w * 0.82, y + h * 0.45, maxf(0.5, w * 0.04), h * 0.55), Color(0.29, 0.30, 0.34, alpha))
	draw_rect(Rect2(x, y, w, h * 0.45), Color(0.90, 0.91, 0.93, alpha))
	draw_rect(Rect2(x + 0.5, y + 0.5, w - 1.0, h * 0.45 - 1.0), Color(bg.r, bg.g, bg.b, alpha))
	if w >= 6.0:
		draw_rect(Rect2(x + w * 0.2, y + h * 0.13, w * 0.6, 0.5), Color(0.90, 0.91, 0.93, alpha))
		draw_rect(Rect2(x + w * 0.28, y + h * 0.28, w * 0.44, 0.5), Color(0.90, 0.91, 0.93, alpha))

var _board_cols := {}
func _board_far(tx: Texture2D, w: float, sx: float, sy: float, clip: float, alpha: float) -> void:
	if w < 0.8:
		return
	if not _board_cols.has(tx):
		var img := tx.get_image()
		var bg0 := img.get_pixel(8, 8)
		var fg0 := bg0
		var row := int(img.get_height() * 0.3)
		for x in range(8, img.get_width() - 8):   # first colour on that row that isn't the background: the lettering
			var c := img.get_pixel(x, row)
			if c.a > 0.5 and absf(c.get_luminance() - bg0.get_luminance()) > 0.15:
				fg0 = c
				break
		_board_cols[tx] = [bg0, fg0]
	var bg: Color = _board_cols[tx][0]
	var fg: Color = _board_cols[tx][1]
	if fg.is_equal_approx(bg):
		fg = Color(1.0, 0.95, 0.69)
	var h := w * 58.0 / 80.0
	var x := roundf((sx - w / 2.0) * 2.0) / 2.0
	var y := roundf((sy - h) * 2.0) / 2.0
	if y + h * 0.6 > clip:
		return
	draw_rect(Rect2(x + w * 0.17, y + h * 0.6, maxf(0.5, w * 0.05), h * 0.4), Color(0.17, 0.10, 0.07, alpha))
	draw_rect(Rect2(x + w * 0.77, y + h * 0.6, maxf(0.5, w * 0.05), h * 0.4), Color(0.17, 0.10, 0.07, alpha))
	draw_rect(Rect2(x, y, w, h * 0.62), Color(0.90, 0.91, 0.93, alpha))
	draw_rect(Rect2(x + 0.5, y + 0.5, w - 1.0, h * 0.62 - 1.0), Color(bg.r, bg.g, bg.b, alpha))
	if w >= 8.0:
		draw_rect(Rect2(x + w * 0.18, y + h * 0.2, w * 0.64, 0.5), Color(fg.r, fg.g, fg.b, alpha))
		draw_rect(Rect2(x + w * 0.26, y + h * 0.38, w * 0.48, 0.5), Color(fg.r, fg.g, fg.b, alpha))

var dust_c := Color(0.6, 0.45, 0.32)
func _dust(x: float, y: float, w: float, alpha: float) -> void:   # red-earth dust rolling behind wheels on a dry day
	var t: float = g.t
	for i in 4:
		var ph := fmod(t * 0.9 + i * 0.25, 1.0)
		var r := w * (0.25 + ph * 0.45)
		var c := Color(dust_c.r, dust_c.g, dust_c.b, 0.28 * alpha * (1.0 - ph))
		draw_circle(Vector2(x + sin(i * 2.1 + t) * w * 0.3, y - ph * w * 0.35), r, c)

# sun by day, a big low sun at dusk and dawn, the moon at night (clear weather only)
func _sun_moon(hy: float, night: float) -> void:
	var td: float = g.tday
	var sun_y := 0.0
	var sun_x := 0.0
	if td < 1.0:
		sun_y = lerpf(16.0, hy - 4.0, td)
		sun_x = lerpf(300.0, 250.0, td)
	elif td < 1.4:
		sun_y = lerpf(hy - 4.0, hy + 14.0, (td - 1.0) / 0.4)
		sun_x = 250.0
	elif td >= 3.0:
		sun_y = lerpf(hy + 6.0, 16.0, td - 3.0)
		sun_x = lerpf(110.0, 300.0, td - 3.0)
	else:
		sun_y = 999.0
	if sun_y < hy + 10.0:
		var low := clampf((sun_y - 16.0) / (hy - 20.0), 0.0, 1.0)
		var col := Color("fff3b0").lerp(Color("f2a62a"), low)
		_glow(sun_x, sun_y, 30.0 + low * 50.0, col, 0.55)
		draw_circle(Vector2(sun_x, sun_y), 5.0 + low * 6.0, col)
		draw_circle(Vector2(sun_x - 1.5, sun_y - 1.5), 2.0 + low * 3.0, col.lerp(Color.WHITE, 0.5))
	if night > 0.05:
		var mx := 92.0
		var my := 22.0
		_glow(mx, my, 22.0, Color("cfe0f2"), 0.25 * night)
		draw_circle(Vector2(mx, my), 6.0, Color(0.9, 0.92, 0.95, night))
		draw_circle(Vector2(mx + 2.0, my - 1.0), 1.4, Color(0.75, 0.78, 0.85, night))
		draw_circle(Vector2(mx - 2.0, my + 2.0), 1.0, Color(0.75, 0.78, 0.85, night))

func _draw_player(sx: float, sy: float, s: float) -> void:
	var hh: float = g.view.hh
	var k := s * 1000.0 * W / 2.0 / 64.0
	var e: float = clampf((g.zb - g.zr) * s * hh, -5.0 * k, 6.0 * k)
	g.car_scr = Vector3(sx, sy, k)
	g.has_car_scr = true
	_glow(sx, sy - 46.0 * k, 105.0 * k, LIGHT, 0.2)
	draw_set_transform(Vector2(sx, sy - k), 0.0, Vector2(31.0 * k, 4.0 * k))
	draw_circle(Vector2.ZERO, 1.0, Color(0, 0, 0, 0.5))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var car: Dictionary = g.car
	if g.road.surface == "terra" and g.wet_k < 0.15 and g.v > 15.0:
		for i in 3:
			_dust(sx + (i - 1) * 24.0 * k, sy - 4.0 * k, 34.0 * k * (0.6 + g.v / 140.0), 0.9)
	for wx in car.wheel_x:   # wheels stay on the road; the body rides above them
		draw_rect(Rect2(sx + wx * k, sy - 7.0 * k, 9.0 * k, 7.0 * k), Color("05070c"))   # top tucked behind the bumper
		draw_rect(Rect2(sx + (wx + 1.0) * k, sy - 7.0 * k, 7.0 * k, 2.0 * k), Color("2a2c33"))   # wet tyre catching the light
		for tx in [1.5, 4.5, 7.0]:
			draw_rect(Rect2(sx + (wx + tx) * k, sy - 5.0 * k, 0.5, 4.0 * k), Color("2a2c33"))
	var bx0: float = car.brake_x
	_reflect(sx - bx0 * k, sy + 2.0 * k, 4.0 * k, 12.0 * k, Color(0.78, 0.12, 0.14, 0.3 if g.brake else 0.12))
	_reflect(sx + bx0 * k, sy + 2.0 * k, 4.0 * k, 12.0 * k, Color(0.78, 0.12, 0.14, 0.3 if g.brake else 0.12))
	draw_set_transform(Vector2(sx + g.vx * 2.5 * k, sy - 6.0 * k - e + g.pitch * 42.0 * k), g.roll * 1.9, Vector2.ONE)
	draw_texture_rect(g.tex[car.player], Rect2(-32.0 * k, -44.0 * k, 64.0 * k, 46.0 * k), false)
	if g.brake:
		for bx in [-bx0, bx0]:
			draw_circle(Vector2(bx * k, car.brake_y * k), 2.4 * k, Color("ff9a8a"))
			_glow(bx * k, car.brake_y * k, 12.0 * k, Color(1.0, 0.24, 0.2), 0.8)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw() -> void:
	var ck: bool = g.cam == 0
	var hy: float = g.view.hy
	var hh: float = g.view.hh
	var segs: Array = g.segs
	var n_seg: int = g.N
	var track: float = g.TRACK
	var top: Color = g.e_top
	var hor: Color = g.e_hor
	var fog: Color = g.e_fog
	var amb: float = g.e_amb

	# sky
	draw_rect(Rect2(X0, -70.0, XW, 70.0), top)
	draw_primitive(PackedVector2Array([Vector2(X0, 0), Vector2(X0 + XW, 0), Vector2(X0 + XW, hy + 6.0), Vector2(X0, hy + 6.0)]),
			PackedColorArray([top, top, hor, hor]), PackedVector2Array())
	var night := clampf((0.62 - amb) * 4.0, 0.0, 1.0)
	if night > 0.0:
		var sc := Color(0.81, 0.88, 0.95, night * 0.8)
		for i in g.stars.size():
			var sz := 0.5 if i % 5 else 1.0
			draw_rect(Rect2(g.stars[i], Vector2(sz, sz)), sc)
	var sunny: bool = g.sky_k < 0.6   # clear, or the sun still showing through a passing shower
	if sunny:
		_sun_moon(hy, night)
	var cc: Color = top.lerp(hor, 0.35)
	if sunny:
		cc = top.lerp(Color.WHITE, 0.45 * clampf(amb, 0.3, 1.0)).lerp(cc, g.sky_k / 0.6)
	cc.a = 0.55
	var sky_off: float = g.sky
	for c in g.clouds:
		var cx := fposmod(c[0] - sky_off * 0.3, 520.0) - 110.0
		draw_rect(Rect2(cx, c[1], c[2], c[3]), cc)
		draw_rect(Rect2(cx + c[2] * 0.2, c[1] - c[3] * 0.5, c[2] * 0.5, c[3]), cc)
	g.feature_call("draw_sky", [self, hy])   # features: rainbow, fireworks, balloons...
	var hf: PackedFloat32Array = g.hill_f
	var hn: PackedFloat32Array = g.hill_n
	var col_f: Color = g.e_hf
	var col_n: Color = g.e_hn
	for xi in range(int(X0), int(W) + 40):
		var h := hf[int(xi + sky_off * 0.5) & 511]
		draw_rect(Rect2(xi, hy + 2.0 - h, 1.0, h + 4.0), col_f)
	if night > 0.0:
		for c in g.city_l:
			var lx := fposmod(c[0] - sky_off * 0.5, 512.0)
			if lx < W:
				draw_rect(Rect2(floorf(lx), hy - c[1], 0.5, 0.5), Color(0.94, 0.28, 0.29, night) if c[2] else Color(1.0, 0.84, 0.35, night))
	for xi in range(int(X0), int(W) + 40):
		var h := hn[int(xi + sky_off) & 511]
		draw_rect(Rect2(xi, hy + 3.0 - h, 1.0, h + 3.0), col_n)
	draw_rect(Rect2(X0, hy + 2.0, XW, 260.0), fog)

	# road, front to back
	var cpos := fposmod(g.pos - g.view.back, track)
	var bi := int(cpos / SEG) % n_seg
	var pct := fmod(cpos, SEG) / SEG
	var cam_y: float = (g.zb if ck else g.cy) + g.view.camh
	var ROADW: float = g.ROADW
	var cam_x: float = (g.px if ck else g.cam_x) * ROADW
	var maxy: float = g.view.maxy
	var x := 0.0
	var dx: float = -segs[bi].curve * pct
	var road0: Color = g.e_road0
	var road1: Color = g.e_road1
	var grass: Color = g.e_gr
	var grass2 := grass.lerp(Color.BLACK, 0.18)
	var line: Color = g.e_line
	var hole_c := road0.lerp(Color.BLACK, 0.8)
	var rim_c := road0.lerp(Color.WHITE, 0.2)
	var patch_c := road0.lerp(Color.BLACK, 0.32)
	var pud_c := hor.lerp(road0, 0.35)
	var pud_h := hor.lerp(Color.WHITE, 0.25)
	var rail_c := Color8(70, 76, 88).lerp(Color8(168, 172, 181), amb)
	var rail_h := Color8(110, 116, 128).lerp(Color8(220, 224, 232), amb)
	var edge_c := Color("c47a1c")
	var median: String = g.road.median
	var fog_k: float = g.fog_k
	var jersey_c := Color8(90, 94, 100).lerp(Color8(196, 198, 200), minf(amb, 1.0))
	var jersey_d := jersey_c.lerp(Color.BLACK, 0.3)
	var nightish := clampf((0.9 - amb) * 1.6, 0.0, 1.0)
	var stud_c := Color(0.85, 0.87, 0.9).lerp(Color(1.0, 1.0, 0.9), nightish)
	var stud_y := Color("c47a1c").lerp(Color("ffd65a"), nightish)
	if g.road.surface == "terra":
		pud_c = hor.lerp(road0, 0.6)   # muddy water
	var feat_list: Array = []
	for n in DRAW:
		var sg = segs[(bi + n) % n_seg]
		var cz := cpos - (track if sg.i < bi else 0.0)
		var z: float = sg.i * SEG - cz
		var s := DEPTH / maxf(z, 1.0)
		var asx := W / 2.0 - s * (cam_x - x) * W / 2.0
		var asy: float = hy - s * (sg.y1 - cam_y) * hh
		var asw := s * ROADW * W / 2.0
		sg.a_cz = z
		sg.a_s = s
		sg.a_sx = asx
		sg.a_sy = asy
		sg.a_sw = asw
		var s2 := DEPTH / maxf(z + SEG, 1.0)
		var bsx := W / 2.0 - s2 * (cam_x - x - dx) * W / 2.0
		var bsy: float = hy - s2 * (sg.y2 - cam_y) * hh
		var bsw := s2 * ROADW * W / 2.0
		sg.b_s = s2
		sg.b_sx = bsx
		sg.b_sy = bsy
		sg.b_sw = bsw
		x += dx
		dx += sg.curve
		sg.clip = maxy
		if z <= DEPTH or bsy >= asy or bsy >= maxy:
			continue
		var alt: bool = (int(sg.i / 3.0) & 1) == 1
		var hgt := asy - bsy + 0.5
		var rc := road1 if alt else road0
		var band_y := roundf(bsy * 2.0) / 2.0   # whole half-units, so neighbouring bands meet without overlapping
		var band_h := roundf(asy * 2.0) / 2.0 - band_y
		draw_rect(Rect2(X0, band_y, XW, band_h), grass if alt else grass2)
		var lw1 := maxf(asw / 55.0, 0.3)
		var lw2 := maxf(bsw / 55.0, 0.3)
		match median:
			"none":   # dirt road: soft grassy edges, two ruts per lane, a grassy crown in the middle
				_trap(rc.lerp(grass, 0.55), asx, asy, asw * 1.22, bsx, bsy, bsw * 1.22)
				_trap(rc, asx, asy, asw, bsx, bsy, bsw)
				for lx in g.LANES:
					for o in [-0.2, 0.2]:
						_trap(line, asx + asw * (lx + o), asy, asw * 0.05, bsx + bsw * (lx + o), bsy, bsw * 0.05)
				_trap(rc.lerp(grass, 0.35 if alt else 0.2), asx, asy, asw * 0.06, bsx, bsy, bsw * 0.06)
			"jersey":   # concrete expressway: the other carriageway beyond a concrete barrier
				_quad(rc.lerp(Color.BLACK, 0.06), Vector2(asx - asw * 3.0, asy), Vector2(bsx - bsw * 3.0, bsy), Vector2(bsx - bsw * 1.2, bsy), Vector2(asx - asw * 1.2, asy))
				_trap(rc.lerp(Color.BLACK, 0.08), asx, asy, asw * 1.14, bsx, bsy, bsw * 1.14)
				_trap(rc, asx, asy, asw, bsx, bsy, bsw)
				_trap(edge_c, asx - asw * 0.96, asy, lw1, bsx - bsw * 0.96, bsy, lw2)
				_trap(line, asx + asw * 0.96, asy, lw1, bsx + bsw * 0.96, bsy, lw2)
				if alt:
					for lx in [-0.5, 0.0, 0.5]:
						_trap(line, asx + asw * lx, asy, lw1, bsx + bsw * lx, bsy, lw2)
				if sg.i % 2 == 0 and hgt > 0.6:   # road studs, catching our headlights at night
					for lx in [-0.96, -0.5, 0.0, 0.5, 0.96]:
						draw_rect(Rect2(asx + asw * lx - lw1, asy - maxf(0.5, hgt * 0.3), lw1 * 2.0, maxf(0.5, hgt * 0.3)), stud_c if lx > -0.9 else stud_y)
				var j1 := s * 420.0 * hh
				var j2 := s2 * 420.0 * hh
				var jx1 := asx - asw * 1.12
				var jx2 := bsx - bsw * 1.12
				var jw1 := asw * 0.05
				var jw2 := bsw * 0.05
				_quad(jersey_d, Vector2(jx1 - jw1, asy), Vector2(jx2 - jw2, bsy), Vector2(jx2 - jw2 * 0.4, bsy - j2), Vector2(jx1 - jw1 * 0.4, asy - j1))
				_quad(jersey_c, Vector2(jx1 + jw1, asy), Vector2(jx2 + jw2, bsy), Vector2(jx2 + jw2 * 0.4, bsy - j2), Vector2(jx1 + jw1 * 0.4, asy - j1))
				draw_rect(Rect2(jx1 - jw1 * 0.4, asy - j1, jw1 * 0.8, maxf(0.5, j1 * 0.08)), jersey_c.lerp(Color.WHITE, 0.2))
			_:
				_quad(rc, Vector2(asx - asw * 3.4, asy), Vector2(bsx - bsw * 3.4, bsy), Vector2(bsx - bsw * 1.5, bsy), Vector2(asx - asw * 1.5, asy))   # the other carriageway
				_trap(rc.lerp(grass, 0.35), asx, asy, asw * 1.16, bsx, bsy, bsw * 1.16)
				_trap(rc, asx, asy, asw, bsx, bsy, bsw)
				_trap(edge_c, asx - asw * 0.95, asy, lw1, bsx - bsw * 0.95, bsy, lw2)
				_trap(line, asx + asw * 0.95, asy, lw1, bsx + bsw * 0.95, bsy, lw2)
				if alt:
					_trap(line, asx - asw / 3.0, asy, lw1, bsx - bsw / 3.0, bsy, lw2)
					_trap(line, asx + asw / 3.0, asy, lw1, bsx + bsw / 3.0, bsy, lw2)
				# guard rail on the median
				var r1 := s * 330.0 * hh
				var r2 := s2 * 330.0 * hh
				var gx1 := asx - asw * 1.27
				var gx2 := bsx - bsw * 1.27
				_quad(rail_c, Vector2(gx1, asy - r1), Vector2(gx2, bsy - r2), Vector2(gx2, bsy - r2 * 0.55), Vector2(gx1, asy - r1 * 0.55))
				_quad(rail_h, Vector2(gx1, asy - r1), Vector2(gx2, bsy - r2), Vector2(gx2, bsy - r2 * 0.9), Vector2(gx1, asy - r1 * 0.9))
				if sg.i % 4 == 0:
					draw_rect(Rect2(gx1, asy - r1, maxf(0.5, asw * 0.012), r1), Color("2a2c33"))
		if not sg.feat.is_empty():
			feat_list.append([sg, hgt, n])   # drawn after the road, back to front, so nearer rows can't erase them
		var fa := pow(float(n) / DRAW, 1.6) * 0.92 * fog_k
		if fa > 0.02:
			draw_rect(Rect2(X0, band_y, XW, band_h), Color(fog.r, fog.g, fog.b, fa))
		maxy = bsy

	# potholes, patches and puddles: at least 1 logical unit tall so they read from far away
	for idx in range(feat_list.size() - 1, -1, -1):
		var e: Array = feat_list[idx]
		var sg = e[0]
		var hgt: float = e[1]
		var fa := pow(float(e[2]) / DRAW, 1.6) * 0.92 * 0.35 * fog_k
		var asx: float = sg.a_sx
		var asy: float = sg.a_sy
		var asw: float = sg.a_sw
		var bsx: float = sg.b_sx
		var bsw: float = sg.b_sw
		var ty := minf(sg.b_sy, asy - 1.0)
		var th := asy - ty
		var hy2 := minf(sg.b_sy, asy - 2.0)   # potholes get 2 logical units minimum, so they read as a dark dash far ahead
		for f in sg.feat:
			var f1: float = asx + asw * f.x
			var f2: float = bsx + bsw * f.x
			var fw: float = f.w * 1.3
			if f.t == 1:
				_trap(patch_c.lerp(fog, fa), f1, asy, asw * fw, f2, ty, bsw * fw)
			elif f.t == 2:
				if g.wet_k < 1.0:   # weather that varies: puddles fill up with the rain and dry out after it
					fw *= clampf(g.wet_k * 1.4 - 0.2, 0.0, 1.0)
					if fw <= 0.0:
						continue
				_trap(pud_c.lerp(fog, fa), f1, asy, asw * fw * f.a, f2, ty, bsw * fw * f.b)
				if th > 2.0:
					_trap(pud_h.lerp(fog, fa), f1 - asw * fw * 0.3, asy - th * 0.4, asw * fw * f.a * 0.35, f2 - bsw * fw * 0.3, asy - th * 0.6, bsw * fw * f.b * 0.35)
			else:
				var hw := maxf(bsw * fw, 1.5)
				_trap(rim_c.lerp(fog, fa), f1, asy, maxf(asw * fw * 0.8, 1.5), f2, hy2, hw)
				_trap(hole_c.lerp(fog, fa), f1, asy - (asy - hy2) * 0.25, maxf(asw * fw * 0.9, 1.2), f2, hy2, hw * 0.8)
				var glint := pud_h.lerp(Color("8ec5ff"), 0.6)   # sky-blue water, not the white of the lane paint
				draw_rect(Rect2(f2 - hw * 1.2, hy2 - 0.5, hw * 2.4, 2.0), hole_c.lerp(fog, fa * 0.3))   # the hole is the dark part, and the widest
				draw_rect(Rect2(f2 - hw * 0.9, hy2 - 1.0, hw * 1.2, 1.0), glint.lerp(fog, fa * 0.3))   # a small water glint off-centre on its far lip

	# rain in the air
	var rain: float = g.rain
	if rain > 0.05:
		var pts := PackedVector2Array()
		var nr := int(rain * g.rain_p.size())
		for i in nr:
			var p: Array = g.rain_p[i]
			pts.append(Vector2(p[0], p[1]))
			pts.append(Vector2(p[0] - p[2] * 0.35, p[1] + p[2]))
		if pts.size() >= 2:
			draw_multiline(pts, Color(0.61, 0.73, 0.88, 0.42), 0.5)

	# sprites and cars, back to front
	var has_pole := false
	var pp := Vector3.ZERO
	var pseg := int(g.pos / SEG) % n_seg
	var wire := Color(0.03, 0.04, 0.06, 0.8)
	var dusty: bool = g.road.surface == "terra" and g.wet_k < 0.15
	dust_c = g.e_road0.lerp(Color(0.9, 0.78, 0.62), 0.45)
	g.has_car_scr = false
	for n in range(DRAW - 1, 0, -1):
		var sg = segs[(bi + n) % n_seg]
		var alpha := clampf(1.25 - (float(n) / DRAW) * 1.15, 0.0, 1.0)
		var asx: float = sg.a_sx
		var asy: float = sg.a_sy
		var asw: float = sg.a_sw
		var a_s: float = sg.a_s
		var clip: float = sg.clip
		for q in sg.spr:
			if q.kind == 4 and a_s * q.ww * W / 2.0 < 24.0:   # road sign too small for its text: draw a clean blank sign
				_sign_far(q.tex, a_s * q.ww * W / 2.0, asx + asw * q.off, asy, clip, alpha)
				continue
			if q.kind == 5 and a_s * q.ww * W / 2.0 < 40.0:   # billboard too small for its text: plain panel in its own colours
				_board_far(q.tex, a_s * q.ww * W / 2.0, asx + asw * q.off, asy, clip, alpha)
				continue
			var r := _sprite(q.tex, q.ww, a_s, asx + asw * q.off, asy, clip, alpha)
			if r.size.x == 0.0:
				continue
			if q.has("draw"):   # features: lights or fire on a roadside sprite (pisca-pisca, fogueira)
				q.draw.call(self, q, r, alpha)
			if q.kind == 1:   # pole: string the wires to the previous one
				var tx := r.position.x + r.size.x / 2.0
				var ty := r.position.y + r.size.y * 0.08
				if has_pole:
					for o in [-0.38, 0.38]:
						var p0 := Vector2(pp.x + pp.z * o, pp.y)
						var p2 := Vector2(tx + r.size.x * o, ty)
						var p1 := Vector2((pp.x + tx) / 2.0, (pp.y + ty) / 2.0 + r.size.y * 0.06)
						var pl := PackedVector2Array()
						for j in 7:
							var u := j / 6.0
							pl.append(p0.lerp(p1, u).lerp(p1.lerp(p2, u), u))
						draw_polyline(pl, wire, 0.5)
				pp = Vector3(tx, ty, r.size.x)
				has_pole = true
			elif q.kind == 2:
				_glow(r.position.x + r.size.x * 0.78, r.position.y + r.size.y * 0.13, r.size.x * 1.1, LIGHT, 0.7 * alpha)
			elif q.kind == 3:
				_glow(r.position.x + r.size.x * 0.5, r.position.y + r.size.y * 0.45, r.size.x * 0.5, LIGHT, 0.45 * alpha)
			elif q.kind == 6:   # double lamp over the median, lit once the light drops
				var la := alpha * clampf((1.05 - amb) * 1.6, 0.0, 0.8)
				var lr := minf(r.size.x * 0.3, 12.0)   # a lamp close by is a bright spot, not a blown-out cloud
				la *= clampf(12.0 / maxf(r.size.x * 0.3, 1.0), 0.3, 0.7)
				if la > 0.02:
					_glow(r.position.x + r.size.x * 0.11, r.position.y + r.size.y * 0.06, lr, LIGHT, la)
					_glow(r.position.x + r.size.x * 0.89, r.position.y + r.size.y * 0.06, lr, LIGHT, la)
		var bsx: float = sg.b_sx
		var bsy: float = sg.b_sy
		var bsw: float = sg.b_sw
		var b_s: float = sg.b_s
		for c in sg.cars:
			var k: float = fmod(c.z, SEG) / SEG
			var sy := lerpf(asy, bsy, k)
			var r := _sprite(c.tex, 900.0, lerpf(a_s, b_s, k), lerpf(asx, bsx, k) + lerpf(asw, bsw, k) * c.x, sy, clip, alpha)
			if r.size.x == 0.0:
				continue
			var rx := r.position.x
			var rw := r.size.x
			var rh := r.size.y
			if dusty:
				_dust(rx + rw * 0.5, sy - rh * 0.15, rw, alpha)
			g.feature_call("draw_car", [self, c, r, alpha])   # features: bumper phrases, blinkers...
			if c.dir < 0 and c.get("flash_t", 0.0) > 0.0 and int(c.flash_t * 6.0) % 2 == 0:   # high beams: get back in your lane
				_glow(rx + rw * 0.16, r.position.y + rh * 0.55, rw * 1.6 + 6.0, Color(1.0, 0.97, 0.85), alpha)
				_glow(rx + rw * 0.84, r.position.y + rh * 0.55, rw * 1.6 + 6.0, Color(1.0, 0.97, 0.85), alpha)
			if c.dir > 0:   # tail lights smeared on the wet asphalt
				var rf := Color(0.78, 0.12, 0.14, 0.3 * alpha)
				_reflect(rx + rw * 0.16, sy, rw * 0.2, rh * 0.35, rf)
				_reflect(rx + rw * 0.84, sy, rw * 0.2, rh * 0.35, rf)
			else:
				var rf := Color(1.0, 0.93, 0.67, 0.22 * alpha)
				_reflect(rx + rw * 0.16, sy, rw * 0.2, rh * 0.5, rf)
				_reflect(rx + rw * 0.84, sy, rw * 0.2, rh * 0.5, rf)
				_glow(rx + rw * 0.16, r.position.y + rh * 0.55, rw * 0.7 + 3.0, Color(1.0, 0.94, 0.7), 0.8 * alpha)
				_glow(rx + rw * 0.84, r.position.y + rh * 0.55, rw * 0.7 + 3.0, Color(1.0, 0.94, 0.7), 0.8 * alpha)
		if not ck and sg.i == pseg:
			var k := fmod(g.pos, SEG) / SEG
			_draw_player(lerpf(asx, bsx, k) + lerpf(asw, bsw, k) * g.px, lerpf(asy, bsy, k), lerpf(a_s, b_s, k))
	g.feature_call("draw_world_over", [self])   # features: anything drawn over the road and traffic
	if ck:
		_glow(W / 2.0, 150.0, 150.0, LIGHT, g.headlight)   # own headlights on the road
	else:
		var sc := Color(0.81, 0.88, 0.95, 0.75)
		for p in g.parts:
			var sz := 1.5 if p[4] > 0.3 else 1.0
			draw_rect(Rect2(p[0], p[1], sz, sz), sc)

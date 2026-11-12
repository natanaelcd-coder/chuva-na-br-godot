extends Node2D
# Draws sky, hills, the pseudo-3D road, roadside sprites, traffic and (in the chase view) the player's car.
# Works in logical 384x216 units; the node is scaled 2x, so half a unit is one real pixel.

const W := 384.0
const SEG := 200.0
const DRAW := 150
const ROADW := 2000.0
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
		var r: float = -g.roll * 1.5
		var o: Vector2 = c + (Vector2(0.0, g.pitch * 190.0) - c).rotated(r)
		transform = Transform2D(r, Vector2(2, 2), 0.0, o * 2.0)
	else:
		transform = Transform2D(0.0, Vector2(2, 2), 0.0, Vector2.ZERO)
	queue_redraw()

func _quad(c: Color, p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2) -> void:
	draw_primitive(PackedVector2Array([p0, p1, p2, p3]), PackedColorArray([c]), PackedVector2Array())

func _trap(c: Color, x1: float, y1: float, w1: float, x2: float, y2: float, w2: float) -> void:
	_quad(c, Vector2(x1 - w1, y1), Vector2(x2 - w2, y2), Vector2(x2 + w2, y2), Vector2(x1 + w1, y1))

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
	for wx in [-28.0, 19.0]:   # wheels stay on the road; the body rides above them
		draw_rect(Rect2(sx + wx * k, sy - 12.0 * k, 9.0 * k, 12.0 * k), Color("05070c"))
		for tx in [1.5, 4.5, 7.0]:
			draw_rect(Rect2(sx + (wx + tx) * k, sy - 10.0 * k, 0.5, 8.0 * k), Color("2a2c33"))
	var refl := Color(0.78, 0.12, 0.14, 0.4 if g.brake else 0.22)
	draw_rect(Rect2(sx - 27.0 * k, sy, 8.0 * k, 18.0 * k), refl)
	draw_rect(Rect2(sx + 19.0 * k, sy, 8.0 * k, 18.0 * k), refl)
	draw_set_transform(Vector2(sx + g.vx * 2.5 * k, sy - 6.0 * k - e + g.pitch * 42.0 * k), g.roll * 1.9, Vector2.ONE)
	draw_texture_rect(g.tex["player"], Rect2(-32.0 * k, -44.0 * k, 64.0 * k, 46.0 * k), false)
	if g.brake:
		for bx in [-22.5, 22.5]:
			draw_circle(Vector2(bx * k, -17.0 * k), 2.4 * k, Color("ff9a8a"))
			_glow(bx * k, -17.0 * k, 12.0 * k, Color(1.0, 0.24, 0.2), 0.8)
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
	var cc: Color = top.lerp(hor, 0.35)
	cc.a = 0.55
	var sky_off: float = g.sky
	for c in g.clouds:
		var cx := fposmod(c[0] - sky_off * 0.3, 520.0) - 110.0
		draw_rect(Rect2(cx, c[1], c[2], c[3]), cc)
		draw_rect(Rect2(cx + c[2] * 0.2, c[1] - c[3] * 0.5, c[2] * 0.5, c[3]), cc)
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
	var cam_x: float = (g.px if ck else g.cam_x) * ROADW
	var maxy: float = g.view.maxy
	var x := 0.0
	var dx: float = -segs[bi].curve * pct
	var road0: Color = g.e_road0
	var road1: Color = g.e_road1
	var grass: Color = g.e_gr
	var grass2 := grass.lerp(Color.BLACK, 0.18)
	var line: Color = g.e_line
	var hole_c := road0.lerp(Color.BLACK, 0.7)
	var rim_c := road0.lerp(Color.WHITE, 0.2)
	var patch_c := road0.lerp(Color.BLACK, 0.32)
	var pud_c := hor.lerp(road0, 0.35)
	var pud_h := hor.lerp(Color.WHITE, 0.25)
	var rail_c := Color8(70, 76, 88).lerp(Color8(168, 172, 181), amb)
	var rail_h := Color8(110, 116, 128).lerp(Color8(220, 224, 232), amb)
	var edge_c := Color("c47a1c")
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
		draw_rect(Rect2(X0, bsy, XW, hgt), grass if alt else grass2)
		_quad(rc, Vector2(asx - asw * 3.4, asy), Vector2(bsx - bsw * 3.4, bsy), Vector2(bsx - bsw * 1.5, bsy), Vector2(asx - asw * 1.5, asy))   # the other carriageway
		_trap(rc.lerp(grass, 0.35), asx, asy, asw * 1.16, bsx, bsy, bsw * 1.16)
		_trap(rc, asx, asy, asw, bsx, bsy, bsw)
		for f in sg.feat:
			var f1: float = asx + asw * f.x
			var f2: float = bsx + bsw * f.x
			var fw: float = f.w
			if f.t == 1:
				_trap(patch_c, f1, asy, asw * fw, f2, bsy, bsw * fw)
			elif f.t == 2:
				_trap(pud_c, f1, asy, asw * fw * f.a, f2, bsy, bsw * fw * f.b)
				if hgt > 2.0:
					_trap(pud_h, f1 - asw * fw * 0.3, asy - hgt * 0.4, asw * fw * f.a * 0.35, f2 - bsw * fw * 0.3, asy - hgt * 0.6, bsw * fw * f.b * 0.35)
			else:
				_trap(rim_c, f1, asy, asw * fw * 0.8, f2, bsy, bsw * fw)
				_trap(hole_c, f1, asy - hgt * 0.25, asw * fw * 0.9, f2, bsy, bsw * fw * 0.8)
		var lw1 := maxf(asw / 55.0, 0.3)
		var lw2 := maxf(bsw / 55.0, 0.3)
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
		var fa := pow(float(n) / DRAW, 1.6) * 0.92
		if fa > 0.02:
			draw_rect(Rect2(X0, bsy, XW, hgt), Color(fog.r, fog.g, fog.b, fa))
		maxy = bsy

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
			var r := _sprite(q.tex, q.ww, a_s, asx + asw * q.off, asy, clip, alpha)
			if r.size.x == 0.0:
				continue
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
			if c.dir > 0:   # tail lights smeared on the wet asphalt
				var rf := Color(0.78, 0.12, 0.14, 0.3 * alpha)
				draw_rect(Rect2(rx + rw * 0.06, sy, rw * 0.2, rh * 0.55), rf)
				draw_rect(Rect2(rx + rw * 0.74, sy, rw * 0.2, rh * 0.55), rf)
			else:
				var rf := Color(1.0, 0.93, 0.67, 0.22 * alpha)
				draw_rect(Rect2(rx + rw * 0.06, sy, rw * 0.2, rh * 0.8), rf)
				draw_rect(Rect2(rx + rw * 0.74, sy, rw * 0.2, rh * 0.8), rf)
				_glow(rx + rw * 0.16, r.position.y + rh * 0.55, rw * 0.7 + 3.0, Color(1.0, 0.94, 0.7), 0.8 * alpha)
				_glow(rx + rw * 0.84, r.position.y + rh * 0.55, rw * 0.7 + 3.0, Color(1.0, 0.94, 0.7), 0.8 * alpha)
		if not ck and sg.i == pseg:
			var k := fmod(g.pos, SEG) / SEG
			_draw_player(lerpf(asx, bsx, k) + lerpf(asw, bsw, k) * g.px, lerpf(asy, bsy, k), lerpf(a_s, b_s, k))
	if ck:
		_glow(W / 2.0, 150.0, 150.0, LIGHT, 0.16)   # own headlights on the wet asphalt
	else:
		var sc := Color(0.81, 0.88, 0.95, 0.75)
		for p in g.parts:
			var sz := 1.0 if p[4] > 0.3 else 0.5
			draw_rect(Rect2(p[0], p[1], sz, sz), sc)

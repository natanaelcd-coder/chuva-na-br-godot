extends SceneTree
# Captures of the second round of PixelLab characters: seu Zé and the attendant (9-frame loops), the animals by the road
# (horse, dog, cows, hens), the horse cart and the tractor; plus frame strips that prove the animation.
#   xvfb-run godot --path . --fixed-fps 60 --rendering-driver opengl3 --audio-driver Dummy --script res://tests/pers2_capturas.gd -- <dir> [only]
const MAIN := preload("res://main.tscn")
var out := "/tmp"
var only := ""
var g

func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() > 0:
		out = a[0]
	if a.size() > 1:
		only = a[1]
	_run.call_deferred()

func step(n: int) -> void:
	for i in n:
		await process_frame

func shot(name: String) -> void:
	await step(2)
	root.get_texture().get_image().save_png("%s/%s.png" % [out, name])

func make(car: String, road: String, wx: String, tm: String, seed_ := 5) -> void:
	if g:
		g.queue_free()
		await step(2)
	Engine.set_meta("test_seed", seed_)
	g = MAIN.instantiate()
	root.add_child(g)
	await process_frame
	g.cfg = {"car": car, "road": road, "weather": wx, "time": tm}
	g.setup()

func want(n: String) -> bool:
	return only == "" or only == n

# the frames of the animated sprites, one row per sprite (read from the _anim.png strips the game uses)
func sprite_strip(names: Array, cols: int, scale: int, name: String) -> void:
	var rows: Array = []
	var cw := 0
	var rh := 0
	for n in names:
		var s: Image = load("res://assets/sprites/%s_anim.png" % n).get_image()
		var base: Image = load("res://assets/sprites/%s.png" % n).get_image()
		cw = maxi(cw, base.get_width() + 4)
		rh = maxi(rh, base.get_height() + 4)
		rows.append([s, base.get_width(), base.get_height()])
	var img := Image.create(cw * cols, rh * names.size(), false, Image.FORMAT_RGBA8)
	img.fill(Color(0.42, 0.58, 0.36))
	for r in rows.size():
		var s: Image = rows[r][0]
		var fw: int = rows[r][1]
		var fh: int = rows[r][2]
		for c in mini(cols, s.get_width() / fw):
			img.blend_rect(s, Rect2i(c * fw, 0, fw, fh), Vector2i(c * cw + 2, r * rh + 2))
	img.convert(Image.FORMAT_RGBA8)
	img.resize(img.get_width() * scale, img.get_height() * scale, Image.INTERPOLATE_NEAREST)
	img.save_png("%s/%s.png" % [out, name])

func _run() -> void:
	if want("parada"):
		for r in [["terra", "venda"], ["expressa", "loja"]]:
			await make("besouro", r[0], "chuva", "entardecer")
			g.begin()
			var par = g.get_node("parada")
			par.enter(0)
			par.order(par.menu_ids[0])
			await step(50)
			await shot("parada_%s" % r[1])
			var imgs: Array = []
			for k in 8:
				await step(20)
				imgs.append(root.get_texture().get_image().get_region(Rect2i(300, 130, 280, 200)))
			var s := Image.create(280 * 4, 200 * 2, false, Image.FORMAT_RGBA8)
			for k in 8:
				s.blit_rect(imgs[k], Rect2i(0, 0, 280, 200), Vector2i((k % 4) * 280, (k / 4) * 200))
			s.save_png("%s/tira_parada_%s.png" % [out, r[1]])
	if want("animais"):
		await make("besouro", "terra", "sol", "dia", 7)
		g.begin()
		g.set_auto(true)
		g.v = 3.0
		g.target = 3.0
		var ev = g.get_node("mundo_eventos")
		for id in ["cavalo", "caramelo"]:
			for c in g.cars.duplicate():
				var d: float = fposmod(c.z - g.pos, g.TRACK)
				if d < 12000.0 or d > g.TRACK - 3000.0:
					g.cars.erase(c)
			ev.start(id)
			g.pos = fmod(g.pos + (ev.seg_i - 9 - int(g.pos / g.SEG)) * g.SEG, g.TRACK)
			g.set_cam(1)
			await step(40)
			await shot("%s_a" % id)
			await step(25)
			await shot("%s_b" % id)
			ev._end()
		# hens and cows planted by the fence, close ahead
		var i0 := int(g.pos / g.SEG) + 10
		for k in 3:
			g.segs[i0 % g.N].spr.append({"tex": g.tex["galinhas"], "off": 1.7, "ww": 440.0, "kind": 0, "name": "galinhas"})
			g.segs[(i0 + 4) % g.N].spr.append({"tex": g.tex[["vaca0", "vaca1"][k % 2]], "off": -2.2, "ww": 900.0, "kind": 0, "name": "vaca"})
		g.segs[(i0 + 8) % g.N].spr.append({"tex": g.tex["vaca1"], "off": 2.6, "ww": 900.0, "kind": 0, "name": "vaca1"})
		await step(20)
		await shot("galinhas_vacas_a")
		await step(21)
		await shot("galinhas_vacas_b")
		sprite_strip(["vaca0", "vaca1", "cavalo", "caramelo", "galinhas"], 9, 2, "tira_animais")
	if want("veiculos"):
		await make("besouro", "terra", "sol", "dia", 7)
		g.begin()
		g.set_auto(true)
		for c in g.cars.duplicate():
			var d: float = fposmod(c.z - g.pos, g.TRACK)
			if d < 12000.0 or d > g.TRACK - 3000.0:
				g.cars.erase(c)
		var ev = g.get_node("mundo_eventos")
		ev.start("carroca")
		g.cars.append({"z": fposmod(g.pos + 2600.0, g.TRACK), "x": g.LANES[1], "v": 5.0, "tex": g.tex["trator"], "dir": 1})
		g.v = 14.0
		g.target = 14.0
		g.set_cam(1)
		for k in 30:
			await step(60)
			if ev.distance() < 1500.0:
				break
		await shot("carroca_trator_a")
		await step(21)
		await shot("carroca_trator_b")
		sprite_strip(["trator", "carroca"], 9, 3, "tira_veiculos")
	sprite_strip(["pessoa_vend", "pessoa_atend"], 9, 3, "tira_zé_atendente".replace("é", "e"))
	quit()

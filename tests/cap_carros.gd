extends SceneTree
# Capturas dos carros do jogador vistos de fora (câmera externa): dia, noite com luzes e freio, chuva, curva com rolagem
# e cada cor da garagem.
#   xvfb-run -a godot --path . --fixed-fps 60 --rendering-driver opengl3 --audio-driver Dummy --script res://tests/cap_carros.gd -- <dir_saida>
const MAIN := preload("res://main.tscn")
const PAINTS := {
	"besouro": ["limao", "bege", "calcinha", "laranja", "branco"],
	"picape": ["vermelha", "saia", "azul", "saia_azul", "amarela"],
	"gt": ["prata", "preto", "branco", "azul"],
}
const ROAD := {"besouro": "br", "picape": "terra", "gt": "expressa"}
var out := "/tmp"
var g

func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() > 0:
		out = a[0]
	DirAccess.make_dir_recursive_absolute(out)
	_run.call_deferred()

func step(n: int) -> void:
	for i in n:
		await process_frame

func make(car: String, road: String, wx: String, tm: String, paint := "", sticker := ""):
	Engine.set_meta("test_seed", 3)
	g = MAIN.instantiate()
	root.add_child(g)
	await process_frame
	g.store_set("garagem", "%s_cor" % car, paint)
	g.store_set("garagem", "%s_adesivo" % car, sticker)
	g.cfg = {"car": car, "road": road, "weather": wx, "time": tm}
	g.setup()
	g.begin()
	g.set_cam(1)
	g.hud.toast_t = 0.0

func shot(name: String) -> void:
	await process_frame
	root.get_texture().get_image().save_png(out.path_join(name + ".png"))

func drop() -> void:
	g.queue_free()
	await process_frame

func bend(sgn: float) -> int:
	var best := 0
	for i in g.N:
		if g.segs[i].curve * sgn > g.segs[best].curve * sgn:
			best = i
	return best

func _run() -> void:
	for car in ["besouro", "picape", "gt"]:
		var road: String = ROAD[car]
		await make(car, road, "sol", "dia")
		await step(150)
		await shot("%s_dia" % car)
		await drop()
		await make(car, road, "sol", "noite")
		await step(120)
		g.target = 20.0
		await step(40)
		await shot("%s_noite_freio" % car)
		await drop()
		await make(car, road, "chuva", "entardecer", "", "deus")
		await step(180)
		await shot("%s_chuva" % car)
		await drop()
		await make(car, road, "sol", "dia")
		var i0 := bend(1.0)
		g.pos = (i0 - 60) * g.SEG
		g.v = 90.0
		g.target = 90.0
		var n := 0
		for i in 240:
			g.bot_steer = clampf((0.0 - g.px) * 6.0 - g.vx * 2.0, -1.0, 1.0)
			await process_frame
			if absf(g.segs[int(g.pos / g.SEG) % g.N].curve) > 1.5:
				n += 1
				if n == 40:
					await shot("%s_curva" % car)
					break
		await drop()
		for p in PAINTS[car]:
			await make(car, road, "sol", "dia", p, "br")
			await step(120)
			await shot("%s_cor_%s" % [car, p])
			await drop()
	quit(0)

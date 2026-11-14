extends SceneTree
# The three cabins (PixelLab art, tools/art/cabines_ia.py) at every light, with the wheel turned, and every garage paint.
#   xvfb-run godot --path . --fixed-fps 60 --script res://tests/cabines.gd -- <out_dir> [paints]
const MAIN := preload("res://main.tscn")
# name, car, road, weather, time, paint, steer (-1 left .. 1 right)
const SHOTS := [
	["besouro_dia_sol", "besouro", "br", "sol", "dia", "", 0.0],
	["besouro_entardecer_chuva", "besouro", "br", "chuva", "entardecer", "", 0.0],
	["besouro_entardecer_sol_curva", "besouro", "terra", "sol", "entardecer", "", -1.0],
	["besouro_noite_chuva", "besouro", "br", "chuva", "noite", "", 0.0],
	["picape_dia_sol", "picape", "terra", "sol", "dia", "", 0.0],
	["picape_entardecer_sol", "picape", "terra", "sol", "entardecer", "", 1.0],
	["picape_dia_chuva_curva", "picape", "terra", "chuva", "dia", "", -1.0],
	["picape_noite_chuva", "picape", "br", "chuva", "noite", "", 0.0],
	["gt_dia_sol", "gt", "expressa", "sol", "dia", "", 0.0],
	["gt_entardecer_chuva", "gt", "expressa", "chuva", "entardecer", "", 0.0],
	["gt_entardecer_sol_curva", "gt", "expressa", "sol", "entardecer", "", 1.0],
	["gt_noite_sol", "gt", "expressa", "sol", "noite", "", 0.0],
]
const PAINTS := {"besouro": ["limao", "bege", "calcinha", "laranja", "branco"], "picape": ["vermelha", "saia", "azul", "saia_azul", "amarela"],
	"gt": ["prata", "preto", "branco", "azul"]}
var out := "/tmp"

func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() > 0:
		out = a[0]
	_run.call_deferred(a.size() > 1 and a[1] == "paints")

func step(n: int) -> void:
	for i in n:
		await process_frame

func _shot(sh: Array) -> void:
	Engine.set_meta("test_seed", 5)
	var g = MAIN.instantiate()
	root.add_child(g)
	await process_frame
	var car: String = sh[1]
	for slot in ["cor", "capa", "tapete", "adesivo"]:
		g.store_set("garagem", "%s_%s" % [car, slot], sh[5] if slot == "cor" else "")
	g.cfg = {"car": car, "road": sh[2], "weather": sh[3], "time": sh[4]}
	g.setup()
	g.menu.show_main()
	g.begin()
	g.set_cam(0)
	await step(150)
	if sh[6] != 0.0:
		for i in 40:
			g.touch_steer = sh[6]
			await process_frame
	g.hud.toast_t = 0.0
	await step(2)
	root.get_texture().get_image().save_png("%s/%s.png" % [out, sh[0]])
	g.queue_free()
	await step(2)

func _run(paints: bool) -> void:
	if paints:
		for car in PAINTS:
			for p in PAINTS[car]:
				await _shot(["cor_%s_%s" % [car, p], car, "br", "sol", "dia", p, 0.0])
		await _shot(["cor_besouro_fabrica", "besouro", "br", "sol", "dia", "", 0.0])
	else:
		for sh in SHOTS:
			await _shot(sh)
	quit()

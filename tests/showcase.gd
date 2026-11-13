extends SceneTree
# Screenshots of the menu, pause screen and a spread of car / road / weather / time combinations.
#   xvfb-run godot --path . --fixed-fps 60 --script res://tests/showcase.gd -- <out_dir>
const MAIN := preload("res://main.tscn")
const SHOTS := [
	["menu", "besouro", "br", "chuva", "entardecer", -1],
	["cab_besouro_br", "besouro", "br", "chuva", "entardecer", 0],
	["cab_picape_terra", "picape", "terra", "sol", "dia", 0],
	["cab_gt_expressa", "gt", "expressa", "sol", "entardecer", 0],
	["cab_gt_noite", "gt", "expressa", "chuva", "noite", 0],
	["ext_picape_terra_sol", "picape", "terra", "sol", "dia", 1],
	["ext_besouro_terra_chuva", "besouro", "terra", "chuva", "entardecer", 1],
	["ext_besouro_br_sol", "besouro", "br", "sol", "dia", 1],
	["ext_gt_expressa_noite", "gt", "expressa", "chuva", "noite", 1],
	["ext_gt_expressa_dia", "gt", "expressa", "sol", "dia", 1],
	["pause", "picape", "terra", "sol", "entardecer", -2],
]
var out := "/tmp"

func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() > 0:
		out = a[0]
	_run.call_deferred()

func step(n: int) -> void:
	for i in n:
		await process_frame

func _run() -> void:
	for sh in SHOTS:
		Engine.set_meta("test_seed", 5)
		var g = MAIN.instantiate()
		root.add_child(g)
		await process_frame
		g.cfg = {"car": sh[1], "road": sh[2], "weather": sh[3], "time": sh[4]}
		g.setup()
		g.menu.show_main()
		if sh[5] >= 0 or sh[5] == -2:
			g.begin()
			g.set_cam(maxi(0, sh[5]) if sh[5] >= 0 else 0)
			g.hud.toast_t = 0.0
		await step(200)
		if sh[5] == -2:
			g.pause()
			await step(3)
		root.get_texture().get_image().save_png("%s/%s.png" % [out, sh[0]])
		g.queue_free()
		await step(2)
	quit()

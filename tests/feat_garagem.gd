extends SceneTree
# Garagem (features/garagem.gd): the garage screen, and each car with a paint, seat cover, mat and sticker,
# from outside and from the driver's seat.
#   xvfb-run godot --path . --fixed-fps 60 --script res://tests/feat_garagem.gd -- <out_dir>
const MAIN := preload("res://main.tscn")
# name, car, road, weather, time, camera (-1: garage screen), paint, cover, mat, sticker, odometer km (-1: none)
const SHOTS := [
	["garagem_besouro", "besouro", "br", "chuva", "entardecer", -1, "limao", "xadrez", "branco", "chuva", -1],
	["garagem_picape_trancado", "picape", "terra", "sol", "dia", -1, "saia", "couro", "rosa", "deus", 12],
	["garagem_gt", "gt", "expressa", "sol", "entardecer", -1, "prata", "oncinha", "azul", "br", -1],
	["ext_besouro_limao", "besouro", "br", "sol", "dia", 1, "limao", "", "", "chuva", -1],
	["ext_besouro_calcinha", "besouro", "terra", "chuva", "entardecer", 1, "calcinha", "", "", "deus", -1],
	["ext_picape_saia", "picape", "terra", "sol", "dia", 1, "saia", "", "", "pago", -1],
	["ext_picape_vermelha", "picape", "br", "sol", "entardecer", 1, "vermelha", "", "", "devagar", -1],
	["ext_gt_prata", "gt", "expressa", "sol", "dia", 1, "prata", "", "", "indo", -1],
	["ext_gt_preto_noite", "gt", "expressa", "chuva", "noite", 1, "preto", "", "", "volto", -1],
	["cab_besouro_limao", "besouro", "br", "sol", "dia", 0, "limao", "xadrez", "branco", "pago", -1],
	["cab_besouro_bege", "besouro", "br", "chuva", "entardecer", 0, "bege", "pelucia", "rosa", "deus", -1],
	["cab_picape_saia", "picape", "terra", "sol", "dia", 0, "saia", "couro", "rosa", "chuva", -1],
	["cab_picape_vermelha", "picape", "terra", "sol", "entardecer", 0, "vermelha", "oncinha", "azul", "devagar", -1],
	["cab_gt_prata", "gt", "expressa", "sol", "entardecer", 0, "prata", "bolinhas", "branco", "volto", -1],
	["cab_gt_branco", "gt", "expressa", "sol", "dia", 0, "branco", "xadrez", "rosa", "br", -1],
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
	var fails := 0
	for sh in SHOTS:
		Engine.set_meta("test_seed", 5)
		var g = MAIN.instantiate()
		root.add_child(g)
		await process_frame
		var car: String = sh[1]
		for pair in [["cor", sh[6]], ["capa", sh[7]], ["tapete", sh[8]], ["adesivo", sh[9]]]:
			g.store_set("garagem", "%s_%s" % [car, pair[0]], pair[1])
		if sh[10] >= 0:
			g.store_set("hodometro", car, float(sh[10]))
		g.cfg = {"car": car, "road": sh[2], "weather": sh[3], "time": sh[4]}
		g.setup()
		g.menu.show_main()
		var gar = g.get_node("garagem")
		if sh[5] >= 0:
			g.begin()
			g.set_cam(sh[5])
			g.hud.toast_t = 0.0
			await step(200)
			var want = gar.body_tex(car, sh[6])
			if g.get_node("World").player_tex != want or g.get_node("Cockpit").cock != gar.cabin_tex(car, sh[6]):
				print("FAIL textures not applied: ", sh[0])
				fails += 1
		else:
			await step(30)
			gar._open()
			if sh[10] >= 0:   # try on a locked paint: shown, not kept
				gar._key(KEY_RIGHT)
				gar._key(KEY_RIGHT)
				gar._key(KEY_RIGHT)
				if gar.choice(car, "cor") != sh[6]:
					print("FAIL a locked choice was saved: ", gar.choice(car, "cor"))
					fails += 1
			await step(5)
		root.get_texture().get_image().save_png("%s/%s.png" % [out, sh[0]])
		g.queue_free()
		await step(2)
	print("feat_garagem: %d failures" % fails)
	quit()

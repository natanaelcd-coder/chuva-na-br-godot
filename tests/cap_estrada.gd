extends SceneTree
# Captures of the roadside pieces: drives on autopilot and shoots when a target sprite is a few segments ahead.
#   xvfb-run -a godot --path . --fixed-fps 60 --rendering-driver opengl3 --audio-driver Dummy --script res://tests/cap_estrada.gd -- <dir> [road] [time] [weather] [cam]
const MAIN := preload("res://main.tscn")
const WANT := {"terra": ["banca_frutas", "caldo_cana", "cruz_flores", "placa_mel", "caixa_dagua", "casa_sitio", "porteira", "ipe_amarelo", "ipe_roxo", "mangueira", "jabuticabeira", "boiadeiro", "capela"],
	"br": ["banca_frutas", "caldo_cana", "cruz_flores", "ponto_onibus", "mangueira", "tree2", "araucaria2", "boiadeiro", "car7", "onibus", "bar", "igreja", "casa_vila1"],
	"expressa": ["coqueiro", "coqueiro2", "torre_celular", "mangueira", "onibus", "car7"]}
var out := "/tmp"

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() > 0:
		out = a[0]
	var road: String = a[1] if a.size() > 1 else "terra"
	var tm: String = a[2] if a.size() > 2 else "dia"
	var wx: String = a[3] if a.size() > 3 else "sol"
	var cam := int(a[4]) if a.size() > 4 else 1
	Engine.set_meta("test_seed", 5)
	var g = MAIN.instantiate()
	root.add_child(g)
	await process_frame
	g.cfg = {"car": "besouro", "road": road, "weather": wx, "time": tm}
	g.setup()
	g.begin()
	g.set_cam(cam)
	g.set_auto(true)
	g.hud.toast_t = 0.0
	await process_frame
	await process_frame
	var spots := {}   # sprite name -> segment where one stands near the road
	for k in g.N:
		for q in g.segs[k].spr:
			if WANT[road].has(q.name) and absf(q.off) < 6.5 and not spots.has(q.name):
				spots[q.name] = k
	for n in spots:
		g.pos = float(spots[n] - 13) * g.SEG
		for f in 14:
			await process_frame
		root.get_texture().get_image().save_png("%s/%s_%s_%s_%s_c%d.png" % [out, road, tm, wx, n, cam])
	print("shots: ", spots.keys())
	quit()

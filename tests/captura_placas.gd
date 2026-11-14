extends SceneTree
# Capturas das placas/pórticos/SOS em cada estrada, de dia e de noite (não é teste, só imagens):
#   xvfb-run godot --path . --fixed-fps 60 --script res://tests/captura_placas.gd -- <out_dir>
const MAIN := preload("res://main.tscn")
var out := ""
var g

func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	out = a[0] if a.size() > 0 else ""
	_run.call_deferred()

func step(n: int) -> void:
	for i in n:
		await process_frame

func ff(n: int) -> void:
	while n > 0:
		var k := mini(n, 300)
		g.pos = fmod(g.pos + k * g.SEG, g.TRACK)
		n -= k
		await process_frame

func find(names: Array, from_seg: int) -> int:
	for d in range(1, g.N):
		var i: int = (from_seg + d) % g.N
		for q in g.segs[i].spr:
			if names.has(q.name):
				return i
	return -1

func _run() -> void:
	for job in [["expressa", "dia", ["portico"], "portico_expressa_dia", 9], ["expressa", "noite", ["portico"], "portico_expressa_noite", 9],
			["expressa", "dia", ["placa_radar", "sos"], "radar_sos_expressa_dia", 14], ["expressa", "noite", ["sos"], "sos_expressa_noite", 10],
			["terra", "dia", ["placa_gado", "placa_lombada"], "gado_terra_dia", 14], ["br", "noite", ["placa_gado", "placa_lombada", "placa_radar"], "aviso_br_noite", 14]]:
		Engine.set_meta("test_seed", 5)
		g = MAIN.instantiate()
		root.add_child(g)
		await process_frame
		g.cfg = {"car": "gt" if job[0] == "expressa" else "besouro", "road": job[0], "weather": "sol", "time": job[1]}
		g.setup()
		g.begin()
		g.set_auto(true)
		g.hud.toast_t = 0.0
		await ff(g.N)
		await ff(600)
		var i := find(job[2], int(g.pos / g.SEG))
		if i < 0:
			print("nao achei ", job[3])
		else:
			var cur := int(g.pos / g.SEG)
			await ff((i - cur - job[4] + g.N) % g.N)
			g.set_cam(1)
			await step(4)
			root.get_texture().get_image().save_png("%s/%s.png" % [out, job[3]])
			print("ok ", job[3])
		g.queue_free()
		await step(2)
	quit(0)

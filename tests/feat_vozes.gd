extends SceneTree
# The announcers' recorded voices (tools/ai/vozes_radio.py): every file in the index loads as an AudioStream, every
# fixed line of every station has its recording, a talk segment plays its voice on the radio bus with the bed ducked
# under it, the strip shows the same line, the tape has no announcer, and without the files the radio falls back to text.
#   godot --headless --path . --fixed-fps 60 --audio-driver Dummy --script res://tests/feat_vozes.gd
const MAIN := preload("res://main.tscn")
var fails := 0

func _initialize() -> void:
	_run.call_deferred()

func step(n: int) -> void:
	for i in n:
		await process_frame

func check(ok: bool, what: String) -> void:
	print(("ok   " if ok else "FAIL ") + what)
	if not ok:
		fails += 1

func _run() -> void:
	# the index: each file exists and is a stream as long as the index says
	var idx = load("res://scripts/radio_vozes.gd")
	var bad := 0
	var kinds := {}
	for e in idx.VOZES:
		var st = load("res://assets/audio/voz/%s.ogg" % e.file) if ResourceLoader.exists("res://assets/audio/voz/%s.ogg" % e.file) else null
		if not (st is AudioStream) or absf(st.get_length() - float(e.dur)) > 0.3:
			bad += 1
			print("  bad: ", e.file)
		kinds[e.kind] = kinds.get(e.kind, 0) + 1
	check(idx.VOZES.size() >= 100 and bad == 0, "%d voices, all load as AudioStream (%s)" % [idx.VOZES.size(), kinds])

	Engine.set_meta("test_seed", 3)
	var g = MAIN.instantiate()
	root.add_child(g)
	await process_frame
	g.cfg = {"car": "besouro", "road": "br", "weather": "chuva", "time": "dia"}
	g.setup()
	var r = g.get_node("radio")
	g.begin()
	await step(10)

	# every fixed line has its recording in the station's voice
	var missing := 0
	for si in 3:
		for t in r.SLOGANS[si] + r.ADS_ST[si]:
			if not r.voz_text.has("%d|%s" % [si, t]):
				missing += 1
				print("  no voice: ", si, " ", t)
		for i in range(si, r.ADS.size(), 3):
			if not r.voz_text.has("%d|%s" % [si, r.ADS[i]]):
				missing += 1
				print("  no voice: ", si, " ", r.ADS[i])
		for road in r.ROAD_NEWS:
			for t in r.ROAD_NEWS[road]:
				if not r.voz_text.has("%d|%s" % [si, t]):
					missing += 1
					print("  no voice: ", si, " ", t)
		for k in ["recado", "tempo", "hora", "intro"]:
			if not r.has_voice(si, k):
				missing += 1
				print("  no voice: ", si, " ", k)
	check(missing == 0, "every slogan, ad, road news, message, forecast, time signal and song intro is recorded")

	# each kind of line on each station picks a recording, and the strip shows that recording's text
	for si in 3:
		var p: Dictionary = r.prog[si]
		p.next = [0, 4, 8][si]
		for k in ["slogan", "ad", "recado", "hora", "tempo", "estrada", "intro"]:
			r._picked = {}
			var l: String = r._line(k, si, p)
			var e: Dictionary = r._picked
			var same: bool = not e.is_empty() and (l.ends_with(e.tela) or k == "hora" and l.begins_with(e.tela.split("%s")[0]))
			check(same and e.st == si, "%d %s -> %s: %s" % [si, k, e.get("file", "-"), l])

	# a talk segment on the tuned station: the voice plays on the radio bus and the bed ducks under it
	var p0: Dictionary = r.prog[0]
	g.radio_st = 0
	r.cur_id = "serra"
	p0.kind = "talk"
	p0.items = ["slogan", "estrada"]
	p0.ti = 0
	p0.t = 0.0
	r._set_text(p0, 0)
	r.radio_tune()
	check(not p0.voice.is_empty() and p0.tdur >= p0.vdelay + p0.voice.dur, "segment waits for its voice: %.1f s (voice %.1f s after %.1f s)" % [p0.tdur, p0.voice.get("dur", 0.0), p0.vdelay])
	var bed_before: float = r.a_bed.volume_db
	await step(int((p0.vdelay + 1.0) * 60))
	check(r.a_voice.playing and r.voice_file == p0.voice.file, "voice on the air: %s" % r.voice_file)
	check(r.a_voice.bus == "Radio", "voice through the radio bus (reception filter, radio volume)")
	check(r.duck > 0.8 and r.a_bed.volume_db < bed_before - 4.0, "bed ducked under the voice: duck %.2f, bed %.1f -> %.1f dB" % [r.duck, bed_before, r.a_bed.volume_db])
	check(r.shown_text.ends_with(p0.text), "strip shows the spoken line: " + r.shown_text)

	# switching away and back drops into the middle of the line
	g.next_station()
	await step(5)
	check(not r.a_voice.playing or r.voice_file != p0.voice.get("file", ""), "voice stops when tuning away")
	g.radio_st = 0
	r.cur_id = "serra"
	r.radio_tune()
	await step(5)
	check(r.a_voice.playing and r.a_voice.get_playback_position() > 0.3, "back on the station: the voice resumes mid-line (%.1f s)" % r.a_voice.get_playback_position())

	# the tape: no announcer
	g.radio_st = 3
	r.cur_id = "fita"
	r.radio_tune()
	await step(30)
	check(r.cur().id == "fita" and not r.a_voice.playing, "tape: no announcer")

	# without the recordings: the old text-only radio
	r.voz_text.clear()
	r.voz_kind.clear()
	var p1: Dictionary = r.prog[1]
	for k in ["slogan", "ad", "recado", "hora", "tempo", "estrada", "intro"]:
		r._picked = {}
		var l: String = r._line(k, 1, p1)
		check(l != "" and r._picked.is_empty(), "fallback %s: %s" % [k, l])
	g.queue_free()
	await step(2)
	print("FAILS: %d" % fails)
	quit(1 if fails > 0 else 0)

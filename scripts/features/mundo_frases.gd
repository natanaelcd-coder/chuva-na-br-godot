extends Node
# Ideia 6: bumper phrases. Trucks, buses and tractors carry a hand-painted phrase on the back; from far away it is
# a plate with scribbles, and it becomes readable as you get close (or wait behind it).

const Cat = preload("res://scripts/catalog.gd")
var g
var font: FontFile = preload("res://assets/fonts/Estrada2P.ttf")
var _n := 0
var _kinds := {}   # texture -> "caminhao" | "onibus" | "trator"
var _wrap_cache := {}

func _ready() -> void:
	g = get_parent()
	g.setup_done.connect(_on_setup)

func _on_setup() -> void:
	_kinds.clear()
	for n in ["car7", "cegonha", "boiadeiro"]:
		if g.tex.has(n):
			_kinds[g.tex[n]] = "caminhao"
	_kinds[g.tex["onibus"]] = "onibus"
	_kinds[g.tex["trator"]] = "trator"

func frase_of(c: Dictionary) -> String:
	if not c.has("frase"):
		var kind: String = _kinds.get(c.tex, "")
		var list: Array = Cat.FRASES if kind == "caminhao" else (Cat.FRASES_ONIBUS if kind == "onibus" else Cat.FRASES_TRATOR)
		_n += 1
		c.frase = list[(_n * 7 + 3) % list.size()]   # no random draw: keeps the game's dice untouched
	return c.frase

func _wrap(txt: String, cols: int) -> Array:
	var key := "%s|%d" % [txt, cols]
	if _wrap_cache.has(key):
		return _wrap_cache[key]
	var lines: Array = []
	var cur := ""
	for word in txt.split(" "):
		if cur == "":
			cur = word
		elif cur.length() + 1 + word.length() <= cols:
			cur += " " + word
		else:
			lines.append(cur)
			cur = word
	lines.append(cur)
	for l in lines:
		if l.length() > cols:
			lines = []
			break
	_wrap_cache[key] = lines
	return lines

func draw_car(w: Node2D, c: Dictionary, r: Rect2, alpha: float) -> void:
	if c.dir < 0:
		return
	var kind: String = _kinds.get(c.tex, "")
	if kind == "" or r.size.x < 22.0:
		return
	var txt := frase_of(c)
	# where the phrase is painted: truck and bus bumper, the tractor's hitch plate
	var fw := 0.84 if kind != "trator" else 0.6
	var fy := 0.79 if kind == "caminhao" else (0.8 if kind == "onibus" else 0.93)
	var pw := r.size.x * fw
	var cx := r.position.x + r.size.x * 0.5
	var bottom := r.position.y + r.size.y * fy
	var big := r.size.x > 230.0
	var cs := 8.0 if big else 4.0          # one glyph in world units (8 or 16 real pixels)
	var cols := int((pw - 2.0) / cs)
	var lines: Array = _wrap(txt, cols) if cols >= 4 else []
	var legible := not lines.is_empty() and lines.size() <= 3 and lines.size() * (cs + 1.0) + 2.0 <= r.size.y * 0.22
	var ink := Color(0.48, 0.09, 0.13, alpha)
	var plate := Color(0.95, 0.9, 0.78, alpha)
	if not legible:   # too far: a plate with a couple of painted scribbles
		var ph := maxf(1.5, r.size.x * 0.05)
		var pr := Rect2(roundf(cx - pw * 0.5), roundf(bottom - ph), roundf(pw), ph)
		w.draw_rect(pr, plate)
		var lw := maxf(0.5, ph * 0.22)
		w.draw_rect(Rect2(pr.position.x + pw * 0.12, pr.position.y + ph * 0.25, pw * 0.76, lw), ink)
		if ph > 3.0:
			w.draw_rect(Rect2(pr.position.x + pw * 0.22, pr.position.y + ph * 0.6, pw * 0.56, lw), ink)
		return
	var lh := cs + 1.0
	var ph2 := lines.size() * lh + 2.0
	var longest := 0
	for l in lines:
		longest = maxi(longest, l.length())
	var pw2 := minf(pw, longest * cs + 6.0)
	var pr2 := Rect2(roundf(cx - pw2 * 0.5), roundf(bottom - ph2), roundf(pw2), ph2)
	w.draw_rect(Rect2(pr2.position - Vector2(0.5, 0.5), pr2.size + Vector2(1, 1)), Color(0.1, 0.06, 0.05, alpha))
	w.draw_rect(pr2, plate)
	# text at half scale so the 8 px pixel font lands on whole screen pixels
	for i in lines.size():
		var l: String = lines[i]
		var lx := roundf((cx - l.length() * cs * 0.5) * 2.0) / 2.0
		var ly := roundf((pr2.position.y + 1.5 + i * lh) * 2.0) / 2.0
		w.draw_set_transform(Vector2(lx, ly), 0.0, Vector2(0.5, 0.5))
		w.draw_string(font, Vector2(0, cs * 2.0 - 1.0), l, HORIZONTAL_ALIGNMENT_LEFT, -1, int(cs * 2.0), ink)
	w.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

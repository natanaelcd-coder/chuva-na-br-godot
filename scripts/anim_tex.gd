class_name AnimTex
extends Texture2D
# A Texture2D that flips frames by itself: used by the PixelLab characters and animals (people at the bus stop, herd,
# cyclist, cows, horse, dog, hens, tractor, cart). The frames sit side by side in assets/sprites/<name>_anim.png; <name>.png is frame 0 and the fallback:
# if the strip does not exist, load_sprite() just returns the plain sprite. Anything that draws a texture
# (draw_texture_rect, draw_texture_rect_region...) works as before, the current frame is picked at draw time.

# per sprite: fps, seq (frame order of one loop; ping-pong by default), phase (s, so figures do not move in unison)
const CFG := {
	"gente0": {"fps": 2.2, "phase": 0.0},
	"gente1": {"fps": 1.7, "phase": 0.9},
	"gente2": {"fps": 1.4, "phase": 1.7},
	"pessoa_frentista": {"fps": 3.0, "seq": [0, 1, 2, 3, 4, 3, 2, 1], "phase": 0.0},
	"pessoa_balc": {"fps": 1.6, "phase": 0.5},
	"pessoa_vend": {"fps": 2.4, "phase": 0.2},    # 9 frames: breathing, a slow blink at each end of the ping-pong
	"pessoa_atend": {"fps": 2.4, "phase": 0.8},
	"boiada0": {"fps": 4.5, "phase": 0.0},
	"boiada1": {"fps": 4.5, "phase": 0.35},
	"ciclista": {"fps": 7.0, "phase": 0.0},
	"vaca0": {"fps": 5.0, "phase": 0.0},     # grazing: the head bobs, the tail swishes
	"vaca1": {"fps": 4.2, "phase": 0.8},
	"cavalo": {"fps": 4.5, "phase": 0.3},
	"caramelo": {"fps": 7.0, "phase": 0.0},  # wagging tail, panting
	"galinhas": {"fps": 4.0, "phase": 0.4},  # three hens pecking
	"trator": {"fps": 7.0, "phase": 0.0},    # the engine shakes it, the farmer sways
	"carroca": {"fps": 6.0, "phase": 0.5},   # the cart bounces, the horse swishes its tail
}
static var _cache := {}
static var draw_phase := 0.0   # seconds added at draw time: world.gd sets it per roadside instance so two cows in a pasture are out of step

var strip: Texture2D
var n := 1
var fw := 1
var fps := 4.0
var seq: Array = []
var phase := 0.0

static func load_sprite(nm: String) -> Texture2D:
	if _cache.has(nm):
		return _cache[nm]
	var base: Texture2D = load("res://assets/sprites/%s.png" % nm)
	var res := base
	var p := "res://assets/sprites/%s_anim.png" % nm
	if base != null and ResourceLoader.exists(p):
		var s: Texture2D = load(p)
		var cnt := int(round(float(s.get_width()) / maxf(1.0, base.get_width())))
		if cnt >= 2 and s.get_height() == base.get_height():
			var a := AnimTex.new()
			var c: Dictionary = CFG.get(nm, {})
			a.strip = s
			a.n = cnt
			a.fw = base.get_width()
			a.fps = c.get("fps", 4.0)
			a.phase = c.get("phase", 0.0)
			a.seq = c.get("seq", [])
			if a.seq.is_empty():   # 0 1 2 3 2 1
				for i in cnt:
					a.seq.append(i)
				for i in range(cnt - 2, 0, -1):
					a.seq.append(i)
			res = a
	_cache[nm] = res
	return res

func _frame() -> int:
	var t := Time.get_ticks_msec() / 1000.0 + phase + draw_phase
	return seq[int(floor(t * fps)) % seq.size()]

func _src(r: Rect2) -> Rect2:
	return Rect2(r.position + Vector2(_frame() * fw, 0), r.size)

func _get_width() -> int:
	return fw

func _get_height() -> int:
	return strip.get_height()

func _has_alpha() -> bool:
	return true

func _draw(ci: RID, pos: Vector2, modulate: Color, transpose: bool) -> void:
	RenderingServer.canvas_item_add_texture_rect_region(ci, Rect2(pos, Vector2(fw, strip.get_height())), strip.get_rid(),
		_src(Rect2(Vector2.ZERO, Vector2(fw, strip.get_height()))), modulate, transpose)

func _draw_rect(ci: RID, rect: Rect2, tile: bool, modulate: Color, transpose: bool) -> void:
	RenderingServer.canvas_item_add_texture_rect_region(ci, rect, strip.get_rid(),
		_src(Rect2(Vector2.ZERO, Vector2(fw, strip.get_height()))), modulate, transpose)

func _draw_rect_region(ci: RID, rect: Rect2, src_rect: Rect2, modulate: Color, transpose: bool, clip_uv: bool) -> void:
	RenderingServer.canvas_item_add_texture_rect_region(ci, rect, strip.get_rid(), _src(src_rect), modulate, transpose, clip_uv)

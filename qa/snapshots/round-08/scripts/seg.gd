extends RefCounted
# One slice of road: geometry, what stands on it, and this frame's projection.
var i := 0
var curve := 0.0
var y1 := 0.0
var y2 := 0.0
var spr: Array = []   # roadside sprites: {tex, off, ww, kind}
var cars: Array = []  # traffic currently on this slice
var feat: Array = []  # potholes, patches, puddles: {t, x, w, a, b}
var a_s := 0.0
var a_sx := 0.0
var a_sy := 0.0
var a_sw := 0.0
var a_cz := 0.0
var b_s := 0.0
var b_sx := 0.0
var b_sy := 0.0
var b_sw := 0.0
var clip := 0.0

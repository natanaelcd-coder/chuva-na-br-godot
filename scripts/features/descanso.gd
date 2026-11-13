extends Node
# Rest mode and sleep timer (brainstorm idea 19). Pause > "MODO DESCANSO" opens a small screen:
#  - COMEÇAR O DESCANSO: autopilot on, no HUD, the camera drifts slowly between inside and outside with a
#    fade, only the radio and the rain. Any key (or touching the wheel) brings you back; R and M still work.
#  - TIMER DE SONO 15/30/60 min: in the last third the sound fades out, in the last half minute the car
#    slows to a stop, then the trip ends and the game waits in the menu in silence until a key is pressed.

const AMBER := Color("f2a62a")
const INK := Color("e6e8ee")
const DIM := Color("6f86a8")
const LINE := Color("9bbbe0")
const TIMERS := [0, 15, 30, 60]
const CAM_EVERY := 40.0   # seconds on each camera
const FADE := 1.6         # seconds of the fade to black and back

var g
var resting := false
var timer_i := 0          # choice on the screen
var sleep_total := 0.0    # seconds; 0 = no timer running
var sleep_left := 0.0
var silenced := false     # the timer ran out: Master stays quiet until someone touches a key
var unsilence := 0.0
var cam_t := 0.0
var fade_t := -1.0        # >= 0 while a camera change fades
var hint_t := 0.0
var sel := 0
var layer: CanvasLayer
var black: ColorRect
var hint: Label
var l_pause: Label
var rows: Array = []
var l_left: Label

func _ready() -> void:
	g = get_parent()
	g.move_child.call_deferred(self, -1)   # input goes to the last child first: see a key before the postcard takes it
	g.menu.add_pause_item("MODO DESCANSO", open)
	layer = CanvasLayer.new()
	layer.layer = 2   # over the world and cabin, under the menu
	add_child(layer)
	black = ColorRect.new()
	black.size = Vector2(768, 432)
	black.color = Color(0.0, 0.0, 0.0, 0.0)
	black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(black)
	hint = g.menu.label("MODO DESCANSO  ·  QUALQUER TECLA VOLTA AO VOLANTE  ·  R TROCA A RÁDIO", 8, Color(INK, 0.8), Vector2(0, 412), layer)
	hint.size = Vector2(768, 10)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.visible = false
	l_pause = g.menu.label("", 8, AMBER, Vector2(0, 380), g.menu.pause_root)
	l_pause.size = Vector2(768, 10)
	l_pause.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

func minutes_left() -> int:
	return int(ceil(sleep_left / 60.0))

# ---- the screen
func open() -> void:
	sel = 1
	g.menu.open_screen("MODO DESCANSO", _build, _key)

func _build(body: Control) -> void:
	var m = g.menu
	m.label("O PILOTO AUTOMÁTICO DIRIGE, A CÂMERA TROCA DEVAGAR ENTRE DENTRO E FORA", 8, INK, Vector2(0, 0), body)
	m.label("DO CARRO E O PLACAR SOME. FICA SÓ O RÁDIO E A CHUVA.", 8, INK, Vector2(0, 14), body)
	rows.clear()
	for i in 3:
		var l: Label = m.label("", 16, INK, Vector2(0, 52 + i * 34), body)
		l.size = Vector2(688, 18)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		rows.append(l)
	l_left = m.label("", 8, LINE, Vector2(0, 166), body)
	l_left.size = Vector2(688, 10)
	l_left.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	m.label("COM O TIMER, O SOM VAI BAIXANDO AOS POUCOS NO FIM, O CARRO PARA E A VIAGEM", 8, DIM, Vector2(0, 220), body)
	m.label("TERMINA NO MENU, EM SILÊNCIO. O TIMER TAMBÉM VALE SE VOCÊ VOLTAR A DIRIGIR.", 8, DIM, Vector2(0, 234), body)
	m.label("SETAS ESCOLHEM E TROCAM   ENTER CONFIRMA   ESC VOLTA", 8, DIM, Vector2(0, 312), body)
	_refresh()

func _refresh() -> void:
	if rows.is_empty() or not is_instance_valid(rows[0]):
		return
	var tm: int = TIMERS[timer_i]
	var txt := ["TIMER DE SONO: %s" % ("DESLIGADO" if tm == 0 else "%d MIN" % tm), "COMEÇAR O DESCANSO", "SÓ O TIMER, EU DIRIJO"]
	for i in 3:
		rows[i].text = ("< %s >" if i == 0 else "> %s <") % txt[i] if i == sel else txt[i]
		rows[i].label_settings.font_color = AMBER if i == sel else INK
	l_left.text = ("TIMER LIGADO: FALTAM %d MIN" % minutes_left()) if sleep_total > 0.0 else ""

func _key(k: int) -> void:
	match k:
		KEY_UP, KEY_W:
			sel = (sel + 2) % 3
		KEY_DOWN, KEY_S:
			sel = (sel + 1) % 3
		KEY_LEFT, KEY_A:
			if sel == 0:
				timer_i = (timer_i + TIMERS.size() - 1) % TIMERS.size()
		KEY_RIGHT, KEY_D:
			if sel == 0:
				timer_i = (timer_i + 1) % TIMERS.size()
		KEY_ENTER, KEY_KP_ENTER, KEY_SPACE:
			if sel == 0:
				timer_i = (timer_i + 1) % TIMERS.size()
			else:
				_arm_timer()
				g.resume()
				if sel == 1:
					start_rest()
				return
	_refresh()

func _arm_timer() -> void:
	var tm: int = TIMERS[timer_i]
	if tm == 0:
		if sleep_total > 0.0:
			_set_master(1.0)
		sleep_total = 0.0
	elif sleep_total <= 0.0 or int(round(sleep_total / 60.0)) != tm:   # a new choice starts it again
		sleep_total = tm * 60.0
		sleep_left = sleep_total
		if not resting:
			g.hud.notice("TIMER DE SONO: %d MIN" % tm)

# ---- rest mode
func start_rest() -> void:
	if g.state != "drive":
		return
	resting = true
	g.set_auto(true)
	g.hud.toast_t = 0.0
	g.hud.visible = false
	cam_t = 0.0
	hint_t = 6.0

func stop_rest(msg := true) -> void:
	if not resting:
		return
	resting = false
	fade_t = -1.0
	black.color.a = 0.0
	hint.visible = false
	g.hud.visible = true
	g.hud.toast_t = 0.0
	if msg and g.state == "drive":
		g.hud.notice("DE VOLTA. PILOTO AUTOMÁTICO LIGADO (P DESLIGA)" if g.auto else "DE VOLTA AO VOLANTE")

func drive_key(k: int) -> bool:
	if not resting:
		return false
	if k == KEY_R or k == KEY_M:   # the radio and the sound still work while resting
		return false
	stop_rest()
	if k == KEY_ESCAPE:
		g.pause()
	return true

func _input(ev: InputEvent) -> void:
	if silenced and ((ev is InputEventKey and ev.pressed) or (ev is InputEventMouseButton and ev.pressed)):
		silenced = false
		unsilence = 0.01

func _set_master(f: float) -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(f, 0.0001)))

func _process(dt: float) -> void:
	dt = minf(dt, 0.05)
	if silenced and Input.is_anything_pressed():   # also when another layer (the postcard) took the key event first
		silenced = false
		unsilence = 0.01
	if l_pause and l_pause.is_visible_in_tree():
		l_pause.text = ("TIMER DE SONO: FALTAM %d MIN" % minutes_left()) if sleep_total > 0.0 else ""
		var fr: Control = g.menu.pause_frame
		l_pause.position.y = minf(fr.position.y + fr.size.y + 22.0, 418.0)   # under the trip code line
	if unsilence > 0.0:   # someone woke up: bring the sound back over two seconds
		unsilence += dt / 2.0
		_set_master(minf(1.0, unsilence * unsilence))
		if unsilence >= 1.0:
			unsilence = 0.0
	if resting:
		if g.state != "drive" or not g.auto:   # back in a menu, or hands on the wheel
			stop_rest(g.state == "drive")
		else:
			_rest_step(dt)
	if sleep_total > 0.0 and g.state == "drive":
		_sleep_step(dt)

func _rest_step(dt: float) -> void:
	g.hud.visible = false
	hint_t -= dt
	hint.visible = hint_t > 0.0
	hint.modulate.a = clampf(hint_t / 1.5, 0.0, 1.0)
	cam_t += dt
	if fade_t < 0.0 and cam_t > CAM_EVERY:
		fade_t = 0.0
	if fade_t >= 0.0:
		var was := fade_t
		fade_t += dt
		if was < FADE and fade_t >= FADE:   # fully dark: change camera
			g.set_cam(1 - g.cam)
			g.hud.toast_t = 0.0
		black.color.a = clampf(1.0 - absf(fade_t - FADE) / FADE, 0.0, 1.0)
		if fade_t >= FADE * 2.0:
			fade_t = -1.0
			cam_t = 0.0
			black.color.a = 0.0

func _sleep_step(dt: float) -> void:
	sleep_left -= dt
	var fade_len := sleep_total / 3.0
	var f := clampf(sleep_left / fade_len, 0.0, 1.0)
	_set_master(f * f)
	if sleep_left < 30.0:   # the car eases to a stop
		g.target = minf(g.target, maxf(0.0, sleep_left - 5.0) * 2.0)
	if sleep_left <= 0.0:
		sleep_total = 0.0
		timer_i = 0
		stop_rest(false)
		silenced = true
		_set_master(0.0)
		g.to_menu()

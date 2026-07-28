extends Minigame
## LOCKPICK (WO2-T5) — job: burglary. Drag around the lock face to rotate the pick;
## an invisible sweet spot glows brighter and the tone tightens as you near it.
## Release to set the pin. Three pins, each a new spot, each on a timer. Audio/ò
## feedback is the channel, not the visual. Tools change the game: pick set widens
## the spot; a crowbar forces one pin but goes loud. 8–12s.

var _pins := 3
var _pin := 0
var _sweet: Array = []            # sweet-spot centre angle per pin
var _half := 0.18                 # sweet half-width (radians)
var _pick := 0.0                  # current pick angle
var _dragging := false
var _timer := 5.0
var _timer0 := 5.0
var _results: Array = []          # "clean" | "timeout" | "miss" per pin
var _running := false
var _crowbar := false
var _clunk_t := 0.0
var _rng := RandomNumberGenerator.new()
var _last_tick := 0.0

func run() -> void:
	_rng.seed = hash(ctx.get("job_id", "burglary")) + stage_index() * 19 + int(stat())
	mouse_filter = Control.MOUSE_FILTER_STOP
	_crowbar = has_tool("crowbar") or has_tool("bolt")
	if _crowbar:
		_running = true
		_crowbar_ui()
		return
	# sweet-spot width: 10° + SLK×0.3° (cap 26°), +8° with a pick set
	var deg := clampf(10.0 + stat() * 0.3, 10.0, 26.0)
	if has_tool("pick") or has_tool("key"): deg += 8.0
	_half = deg_to_rad(deg) * 0.5
	_pins = 3 + (1 if stage_index() >= 4 else 0)
	for i in range(_pins):
		_sweet.append(_rng.randf() * TAU)
	_timer0 = 5.0 - difficulty() * 2.0
	_timer = _timer0
	_pick = _rng.randf() * TAU
	_running = true
	set_process(true)
	queue_redraw()

func _crowbar_ui() -> void:
	var b := Pal.btn("PRISE IT", "danger", 110)
	b.custom_minimum_size = Vector2(360, 110)
	b.position = Vector2((size.x - 360) / 2.0, size.y * 0.5 - 55)
	b.pressed.connect(func():
		Audio.hit(1.0); _clunk_t = 0.2
		_finish(0.6, {"detail": "CROWBARRED", "result": "hit", "loud": true}))
	add_child(b)
	queue_redraw()

func current_score() -> float:
	return _score()

func _process(delta: float) -> void:
	if _clunk_t > 0.0: _clunk_t -= delta
	if not _running or _crowbar:
		queue_redraw(); return
	_timer -= delta
	if _timer <= 0.0:
		_commit(true)     # timed out
	# proximity audio tick — quicker/higher as the pick nears the sweet spot
	var prox := _proximity()
	_last_tick -= delta
	var interval: float = lerp(0.5, 0.08, prox)
	if _dragging and _last_tick <= 0.0:
		Audio._emit("tap", lerp(0.7, 1.9, prox), lerp(-16.0, -4.0, prox))
		_last_tick = interval
	queue_redraw()

func _proximity() -> float:
	if _pin >= _sweet.size(): return 0.0
	var d: float = abs(_ang_diff(_pick, _sweet[_pin]))
	return clampf(1.0 - d / (PI), 0.0, 1.0)

func _ang_diff(a: float, b: float) -> float:
	var d := fmod(a - b + PI, TAU) - PI
	return d if d >= -PI else d + TAU

func _gui_input(e: InputEvent) -> void:
	if not _running or _crowbar:
		return
	var c := size / 2.0
	if e is InputEventMouseButton or e is InputEventScreenTouch:
		if e.pressed:
			_dragging = true
			_pick = (e.position - c).angle()
		else:
			if _dragging:
				_dragging = false
				_commit(false)
	elif (e is InputEventMouseMotion or e is InputEventScreenDrag) and _dragging:
		_pick = (e.position - c).angle()

func _commit(timed_out: bool) -> void:
	if _pin >= _pins: return
	var within: bool = abs(_ang_diff(_pick, _sweet[_pin])) <= _half
	if timed_out:
		_results.append("timeout")
		Audio.error()
	elif within:
		_results.append("clean")
		_event("hit")
		Audio.hit(0.9); _clunk_t = 0.18
		if OS.has_feature("mobile"): Input.vibrate_handheld(35)
	else:
		_results.append("miss")
		Audio.error()
	_pin += 1
	_timer = _timer0
	if _pin >= _pins:
		_end()

func _score() -> float:
	if _crowbar: return 0.6
	var clean := 0; var setc := 0; var timeouts := 0
	for r in _results:
		if r == "clean": clean += 1; setc += 1
		elif r == "timeout": timeouts += 1; setc += 1
	if _pins == 0: return 0.0
	if setc >= _pins:
		return 1.0 if timeouts == 0 else 0.7
	var missed := _pins - setc
	return 0.45 if missed == 1 else 0.15

func _end() -> void:
	_running = false
	var s := _score()
	var det := "IT'S NOT GOING"
	if s >= 0.999: det = "OPEN. QUIET."
	elif s >= 0.7: det = "OPEN"
	elif s >= 0.45: det = "STIFF, BUT IN"
	await get_tree().create_timer(0.4).timeout
	_finish(s, {"detail": det, "result": ("gold" if s >= 0.999 else ("hit" if s >= 0.45 else "miss"))})

func _draw() -> void:
	var r := size
	var c := r / 2.0
	var rad: float = min(r.x, r.y) * 0.30
	if _crowbar:
		var f0 := Pal.mono_font(500)
		var t0 := "SOD THE PINS. ONE GO, BUT IT'S LOUD."
		draw_string(f0, Vector2((r.x - f0.get_string_size(t0, HORIZONTAL_ALIGNMENT_LEFT, -1, 24).x) / 2.0, c.y - rad - 30), t0, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Pal.DANGER_RED)
		return
	# lock face
	draw_circle(c, rad, Pal.INSET)
	draw_arc(c, rad, 0, TAU, 64, Pal.RAISED, 3.0)
	draw_arc(c, rad - 10, 0, TAU, 64, Pal.HAIRLINE, 1.0)
	# proximity glow ring — the ONLY hint where the sweet spot is
	var prox := _proximity()
	var glow := Color(Pal.SODIUM, 0.15 + prox * 0.7)
	draw_arc(c, rad + 8, 0, TAU, 48, glow, 4.0 + prox * 6.0)
	# pick
	var tip := c + Vector2(cos(_pick), sin(_pick)) * rad
	draw_line(c, tip, Pal.TEXT, 6.0)
	draw_circle(tip, 12.0 + (6.0 if _clunk_t > 0.0 else 0.0), Pal.GLOW if prox > 0.8 else Pal.TEXT2)
	# pin progress dots
	for i in range(_pins):
		var px := c.x - (_pins - 1) * 22 + i * 44
		var col := Pal.MUTED
		if i < _results.size():
			col = Pal.CLEAN if _results[i] == "clean" else (Pal.SODIUM if _results[i] == "timeout" else Pal.DANGER_RED)
		elif i == _pin:
			col = Pal.GLOW
		draw_rect(Rect2(px - 8, c.y + rad + 26, 16, 16), col)
	# timer ring
	draw_arc(c, rad - 22, -PI / 2, -PI / 2 + TAU * clampf(_timer / _timer0, 0.0, 1.0), 48, Color(Pal.DANGER_RED, 0.7), 4.0)
	# prompt
	var f := Pal.mono_font(500)
	var p := "DRAG THE PICK  ·  RELEASE ON THE GIVE" if _running else ""
	if p != "":
		draw_string(f, Vector2((r.x - f.get_string_size(p, HORIZONTAL_ALIGNMENT_LEFT, -1, 22).x) / 2.0, c.y + rad + 78), p, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Pal.TEXT2)

extends Minigame
## SMASH & LOAD (WO2-T8) — job: ram_raid. Two phases. 1) THE HIT: a power meter
## oscillates behind the van; one tap — nail it and the shutter goes in one, fumble
## and it costs 3 seconds. 2) THE LOAD: rapid-tap to throw stock in the van while an
## armed-response ETA bar fills. GET OUT from second 3. Stay too long = nicked. The
## loudest thing in the game. 10–12s.

enum { HIT, LOAD, DONE }
var _phase := HIT
var _meter := 0.0                 # 0..1 oscillating power
var _mdir := 1.0
var _mspeed := 1.6
var _second_go := false
var _loaded := 0
var _per_tap := 1
var _eta := 0.0                   # armed response, 0..1
var _eta_speed := 0.12
var _countdown := 7.0
var _running := false
var _shake := 0.0
var _flash_t := 0.0
var _flash := Color(0, 0, 0, 0)
var _getout: Button
var _hit_quality := 0.0
var _rng := RandomNumberGenerator.new()
var _auto_load := 0.0

func run() -> void:
	_rng.seed = hash(ctx.get("job_id", "ram_raid")) + stage_index() * 29 + int(stat())
	mouse_filter = Control.MOUSE_FILTER_STOP
	_per_tap = 2 if float(Game.eff_stat("strength")) >= 14.0 else 1
	_eta_speed = 0.10 + difficulty() * 0.06
	_countdown = 7.0 - stage_index() * 0.6
	_mspeed = 1.5 + difficulty() * 0.7
	if has_crew("enforcer"):
		_auto_load = 1.2                          # a loader working alongside your taps
	_phase = HIT
	_running = true
	set_process(true)
	queue_redraw()

func current_score() -> float:
	return clampf(_loaded / 14.0, 0.0, 1.0)

func _process(delta: float) -> void:
	if _flash_t > 0.0:
		_flash_t -= delta; _flash.a = clampf(_flash_t / 0.3, 0.0, 1.0) * 0.6
	if _shake > 0.0: _shake = max(0.0, _shake - delta * 30.0)
	if not _running:
		queue_redraw(); return
	if _phase == HIT:
		_meter += _mdir * _mspeed * delta
		if _meter >= 1.0: _meter = 1.0; _mdir = -1.0
		elif _meter <= 0.0: _meter = 0.0; _mdir = 1.0
	elif _phase == LOAD:
		_countdown -= delta
		_eta = min(1.0, _eta + _eta_speed * delta)
		if _auto_load > 0.0:
			_auto_load -= delta
			if _auto_load <= 0.0:
				_loaded += 1; _auto_load = 1.2
		if _eta >= 1.0:
			_flash = Color(Pal.POLICE, 0.7); _flash_t = 0.4
			_end(0.0, "BLUE LIGHTS IN THE MIRROR")
			return
		if _countdown <= 0.0:
			_cash_out_load()
	queue_redraw()

func _gui_input(e: InputEvent) -> void:
	if not _running:
		return
	if (e is InputEventMouseButton and e.pressed) or (e is InputEventScreenTouch and e.pressed):
		if _phase == HIT:
			_do_hit()
		elif _phase == LOAD:
			_do_load()

func _do_hit() -> void:
	# quality: 1.0 dead centre of the meter, tailing off toward the ends
	_hit_quality = 1.0 - abs(_meter - 0.72) / 0.72
	_hit_quality = clampf(_hit_quality, 0.0, 1.0)
	_shake = 10.0
	Audio.hit(1.0)
	if OS.has_feature("mobile"): Input.vibrate_handheld(60)
	if _hit_quality < 0.45 and not _second_go:
		# poor hit — shutter holds, second attempt burns 3 seconds
		_second_go = true
		_flash = Color(Pal.DANGER_RED, 0.4); _flash_t = 0.3
		_meter = 0.0; _mdir = 1.0
		return
	_flash = Color(Pal.SODIUM, 0.5); _flash_t = 0.3
	if _second_go: _countdown -= 3.0
	_phase = LOAD
	_getout = Pal.btn("GET OUT", "danger", 96)
	_getout.custom_minimum_size = Vector2(340, 96)
	_getout.position = Vector2((size.x - 340) / 2.0, size.y - 130)
	_getout.disabled = true
	_getout.pressed.connect(_cash_out_load)
	add_child(_getout)
	# GET OUT arms at second 3
	get_tree().create_timer(3.0).timeout.connect(func():
		if is_instance_valid(_getout): _getout.disabled = false)

func _do_load() -> void:
	_loaded += _per_tap
	_event("grab")
	_shake = max(_shake, 4.0)
	Audio.coin()
	_flash = Color(Pal.DIRTY, 0.18); _flash_t = 0.12

func _cash_out_load() -> void:
	if _phase != LOAD: return
	Audio.ui()
	var score := current_score()
	if _loaded >= 10: score = 1.0
	_end(score, "FULL VAN" if _loaded >= 10 else ("GOT A LOAD" if _loaded > 0 else "EMPTY-HANDED"))

func _end(score: float, det: String) -> void:
	_phase = DONE
	_running = false
	if is_instance_valid(_getout): _getout.disabled = true
	await get_tree().create_timer(0.4).timeout
	_finish(score, {"detail": det, "result": ("gold" if score >= 0.999 else ("hit" if score >= 0.4 else "miss"))})

func _draw() -> void:
	var r := size
	var so := Vector2(_rng.randf_range(-_shake, _shake), _rng.randf_range(-_shake, _shake)) if _shake > 0.0 else Vector2.ZERO
	var f := Pal.mono_font(500)
	if _phase == HIT:
		var t := "LINE IT UP.  ONE TAP."
		draw_string(f, Vector2((r.x - f.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, 26).x) / 2.0, r.y * 0.30), t, HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Pal.TEXT2)
		# power meter
		var mx := r.x * 0.10 + so.x
		var mw := r.x * 0.80
		var my := r.y * 0.5
		draw_rect(Rect2(mx, my, mw, 44), Pal.INSET)
		# sweet band around 0.72
		draw_rect(Rect2(mx + 0.60 * mw, my, 0.24 * mw, 44), Color(Pal.SODIUM, 0.35))
		draw_rect(Rect2(mx + _meter * mw - 5, my - 12, 10, 68), Pal.GLOW)
		draw_rect(Rect2(mx, my, mw, 44), Pal.RAISED, false, 2.0)
		if _second_go:
			draw_string(f, Vector2(mx, my + 96), "SHUTTER HELD — GO AGAIN, CLOCK'S RUNNING", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Pal.DANGER_RED)
	elif _phase == LOAD:
		# countdown + loaded
		draw_string(Pal.display_font(), Vector2(r.x * 0.10 + so.x, r.y * 0.22), "%0.1f" % max(0.0, _countdown), HORIZONTAL_ALIGNMENT_LEFT, -1, 64, Pal.TEXT)
		draw_string(f, Vector2(r.x * 0.10, r.y * 0.30), "IN THE VAN  ×%d" % _loaded, HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Pal.DIRTY)
		# the ETA bar — the most aggressive thing on screen
		var ey := r.y * 0.40
		var ew := r.x * 0.80
		var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.02)
		draw_rect(Rect2(r.x * 0.10, ey, ew, 40), Pal.INSET)
		draw_rect(Rect2(r.x * 0.10, ey, ew * _eta, 40), Color(Pal.DANGER_RED, 0.7 + pulse * 0.3))
		draw_rect(Rect2(r.x * 0.10, ey, ew, 40), Pal.DANGER_RED, false, 2.0 + pulse * 3.0)
		draw_string(f, Vector2(r.x * 0.10, ey - 8), "ARMED RESPONSE", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Pal.DANGER_RED)
		var p := "TAP TAP TAP  ·  GET OUT WHEN YOU'RE HEAVY"
		draw_string(f, Vector2((r.x - f.get_string_size(p, HORIZONTAL_ALIGNMENT_LEFT, -1, 22).x) / 2.0, r.y * 0.56), p, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Pal.TEXT2)
	if _flash_t > 0.0 and _flash.a > 0.0:
		draw_rect(Rect2(Vector2.ZERO, r), _flash)

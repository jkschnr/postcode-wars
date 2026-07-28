extends Minigame
## HOTWIRE & DRIVE (WO2-T7) — job: chop_run. Two phases in one. 1) HOTWIRE: match a
## short swipe sequence (↑↓←→); a wrong swipe costs time, not the job. 2) THE DRIVE:
## a road strip scrolls up, hold the left/right side to steer, dodge obstacles while
## a heat bar fills. Middle lane is fastest but busiest — a real trade. Speed stat
## sharpens handling; a Driver in the crew auto-hotwires and thins the traffic. 12–14s.

enum { HOTWIRE, DRIVE, DONE }
var _phase := HOTWIRE
var _seq: Array = []
var _seq_i := 0
var _hot_penalty := 0.0
var _press := Vector2.ZERO
var _pressing := false
var _steer := 0.0
var _car_x := 0.5
var _steer_rate := 1.4
var _scroll := 0.0
var _scroll_speed := 0.9
var _obstacles: Array = []        # [{x, y}]
var _spawn_t := 0.0
var _spawn_gap := 0.55
var _hits := 0
var _heat := 0.0
var _heat_speed := 0.08
var _drive_t := 8.0
var _running := false
var _shake := 0.0
var _flash_t := 0.0
var _flash := Color(0, 0, 0, 0)
var _rng := RandomNumberGenerator.new()

const DIRS := ["up", "down", "left", "right"]
const GLYPH := {"up": "▲", "down": "▼", "left": "◀", "right": "▶"}

func run() -> void:
	_rng.seed = hash(ctx.get("job_id", "chop_run")) + stage_index() * 31 + int(stat())
	mouse_filter = Control.MOUSE_FILTER_STOP
	var spd := float(Game.eff_stat("speed"))
	_steer_rate = 1.1 + spd * 0.05
	_scroll_speed = 0.85 + difficulty() * 0.5
	_heat_speed = 0.06 + difficulty() * 0.05
	_spawn_gap = clampf(0.65 - difficulty() * 0.25, 0.28, 0.65)
	_drive_t = 8.0 + stage_index() * 2.0
	var driver := has_crew("driver")
	if driver:
		_spawn_gap *= 1.43                        # −30% obstacles
	for i in range(3):
		_seq.append(DIRS[_rng.randi() % DIRS.size()])
	_running = true
	if driver:
		_start_drive()                            # Driver auto-completes the hotwire
	set_process(true)
	queue_redraw()

func current_score() -> float:
	return _score_for(_hits, _heat >= 1.0)

func _process(delta: float) -> void:
	if _flash_t > 0.0:
		_flash_t -= delta; _flash.a = clampf(_flash_t / 0.3, 0.0, 1.0) * 0.6
	if _shake > 0.0: _shake = max(0.0, _shake - delta * 26.0)
	if not _running or _phase != DRIVE:
		queue_redraw(); return
	_drive_t -= delta
	_scroll += _scroll_speed * delta
	# steering
	_car_x = clampf(_car_x + _steer * _steer_rate * delta, 0.08, 0.92)
	# heat fills; the middle lane is the fast line, so it heats slower
	var mid_bonus := 0.7 if abs(_car_x - 0.5) < 0.15 else 1.0
	_heat = min(1.0, _heat + _heat_speed * mid_bonus * delta)
	# spawn — biased to the centre lane
	_spawn_t -= delta
	if _spawn_t <= 0.0:
		_spawn_t = _spawn_gap
		var lane := 0.5 + _rng.randf_range(-0.35, 0.35) * (0.6 if _rng.randf() < 0.5 else 1.0)
		_obstacles.append({"x": clampf(lane, 0.1, 0.9), "y": -0.1})
	# move obstacles, test collisions at the car line (y≈0.86)
	var keep: Array = []
	for o in _obstacles:
		o.y += (_scroll_speed + 0.6) * delta
		if o.y > 0.80 and o.y < 0.92 and abs(o.x - _car_x) < 0.12 and not o.get("done", false):
			o.done = true
			_event("miss")
			_hits += 1
			_shake = 8.0
			_flash = Color(Pal.DANGER_RED, 0.4); _flash_t = 0.25
			Audio.hit(1.0)
			if OS.has_feature("mobile"): Input.vibrate_handheld(50)
		if o.y < 1.15:
			keep.append(o)
	_obstacles = keep
	if _heat >= 1.0 or _hits >= 5:
		_end(0.0, "YOU LEFT IT ON THE RING ROAD")
		return
	if _drive_t <= 0.0:
		_finish_drive()
	queue_redraw()

func _gui_input(e: InputEvent) -> void:
	if not _running:
		return
	if _phase == HOTWIRE:
		if e is InputEventMouseButton or e is InputEventScreenTouch:
			if e.pressed: _press = e.position; _pressing = true
			elif _pressing:
				_pressing = false
				_resolve_swipe(e.position - _press)
	elif _phase == DRIVE:
		if e is InputEventMouseButton or e is InputEventScreenTouch:
			if e.pressed:
				_pressing = true
				_steer = -1.0 if e.position.x < size.x / 2.0 else 1.0
			else:
				_pressing = false; _steer = 0.0
		elif (e is InputEventMouseMotion or e is InputEventScreenDrag) and _pressing:
			_steer = -1.0 if e.position.x < size.x / 2.0 else 1.0

func _resolve_swipe(d: Vector2) -> void:
	if d.length() < 40.0:
		return
	var dir := ""
	if abs(d.x) > abs(d.y):
		dir = "right" if d.x > 0 else "left"
	else:
		dir = "down" if d.y > 0 else "up"
	if dir == _seq[_seq_i]:
		Audio.tap()
		_seq_i += 1
		if _seq_i >= _seq.size():
			_flash = Color(Pal.SODIUM, 0.4); _flash_t = 0.3
			_start_drive()
	else:
		Audio.error()
		_hot_penalty += 0.6
		_flash = Color(Pal.DANGER_RED, 0.35); _flash_t = 0.25

func _start_drive() -> void:
	_phase = DRIVE
	Audio.whoosh()

func _finish_drive() -> void:
	var score := _score_for(_hits, false)
	var det := "NOT A MARK ON IT"
	if _hits >= 3: det = "DELROY WON'T BE PLEASED"
	elif _hits >= 1: det = "COUPLE OF SCUFFS"
	_end(score, det)

func _score_for(hits: int, busted: bool) -> float:
	if busted: return 0.0
	if hits == 0: return 1.0
	if hits <= 2: return 0.7
	if hits <= 4: return 0.4
	return 0.0

func _end(score: float, det: String) -> void:
	_phase = DONE
	_running = false
	await get_tree().create_timer(0.4).timeout
	_finish(score, {"detail": det, "result": ("gold" if score >= 0.999 else ("hit" if score >= 0.4 else "miss")), "damage": _hits})

func _draw() -> void:
	var r := size
	var so := Vector2(_rng.randf_range(-_shake, _shake), _rng.randf_range(-_shake, _shake)) if _shake > 0.0 else Vector2.ZERO
	var f := Pal.mono_font(500)
	if _phase == HOTWIRE:
		var t := "UNDER THE COLUMN.  MATCH THE PULLS."
		draw_string(f, Vector2((r.x - f.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, 24).x) / 2.0, r.y * 0.28), t, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Pal.TEXT2)
		var gx := r.x / 2.0 - (_seq.size() - 1) * 70.0
		for i in range(_seq.size()):
			var col := Pal.CLEAN if i < _seq_i else (Pal.GLOW if i == _seq_i else Pal.MUTED)
			draw_string(Pal.display_font(), Vector2(gx + i * 140.0 - 20, r.y * 0.52), GLYPH[_seq[i]], HORIZONTAL_ALIGNMENT_LEFT, -1, 72, col)
		draw_string(f, Vector2((r.x - 200) / 2.0, r.y * 0.66), "SWIPE THE ARROWS", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Pal.SODIUM)
	elif _phase == DRIVE:
		# road strip
		var rx := r.x * 0.14 + so.x
		var rw := r.x * 0.72
		draw_rect(Rect2(rx, 0, rw, r.y), Color("#15181C"))
		# lane dashes scrolling
		for i in range(-1, 20):
			var yy := fmod((i * 90.0 + _scroll * 300.0), r.y + 90.0)
			draw_rect(Rect2(rx + rw / 2.0 - 4, yy, 8, 46), Color(Pal.SODIUM, 0.5))
		# obstacles
		for o in _obstacles:
			var ox := rx + float(o.x) * rw
			var oy := float(o.y) * r.y
			draw_rect(Rect2(ox - 34, oy - 26, 68, 52), Color(Pal.DANGER_RED, 0.85 if not o.get("done", false) else 0.3))
		# the car
		var carx := rx + _car_x * rw
		draw_rect(Rect2(carx - 30, r.y * 0.86 - 44, 60, 88), Pal.GLOW)
		draw_rect(Rect2(carx - 30, r.y * 0.86 - 44, 60, 88), Pal.SODIUM, false, 2.0)
		# heat bar
		draw_rect(Rect2(r.x * 0.14, 20, rw, 26), Pal.INSET)
		draw_rect(Rect2(r.x * 0.14, 20, rw * _heat, 26), Color(Pal.DANGER_RED, 0.85))
		draw_string(f, Vector2(r.x * 0.14, 14), "HEAT", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Pal.DANGER_RED)
		draw_string(f, Vector2(r.x * 0.72, 14), "HITS %d/5" % _hits, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Pal.TEXT2)
		draw_string(f, Vector2((r.x - 260) / 2.0, r.y - 40), "HOLD A SIDE TO STEER", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Pal.TEXT2)
	if _flash_t > 0.0 and _flash.a > 0.0:
		draw_rect(Rect2(Vector2.ZERO, r), _flash)

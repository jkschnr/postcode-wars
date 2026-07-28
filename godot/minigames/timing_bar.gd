extends Minigame
## TIMING BAR (WO2-T2 · reworked WO3-T6) — job: phone_snatch. The bar IS the pavement:
## the mark walks along it, phone lit in hand. One tap when the marker hits the green
## (gold = dead-on = CLEAN LIFT). 1.6s sweep (was 0.54s), windows floored by window_ms
## so a first-timer can actually hit them. Fails tell you WHY: too soon / too late.

const BAR_X0 := 0.09
const BAR_X1 := 0.91

var _markers: Array = []          # [{pos, dir}]
var _green_c := 0.5               # green centre (0..1 along the bar)
var _green_hf := 0.12             # green half-width (fraction of bar)
var _gold_hf := 0.05              # gold half-width
var _sweep_s := 1.6
var _to_hit := 1
var _captured: Array = []         # per-tap scores
var _reasons: Array = []          # per-tap miss reasons
var _running := false
var _hitstop := 0.0
var _shake := 0.0
var _flash := Color(0, 0, 0, 0)
var _flash_t := 0.0
var _rng := RandomNumberGenerator.new()

func run() -> void:
	_rng.seed = hash(ctx.get("job_id", "phone")) + stage_index() * 7 + int(stat() * 10)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var two := stage_index() >= 4
	_to_hit = 2 if two else 1
	_sweep_s = 1.6 * (1.0 / 0.85 if two else 1.0)     # two markers → sweep slows 15%
	var ramp := training_mult()
	var sweep_ms := _sweep_s * 1000.0
	# zone widths derived from the reaction window (ms) so time-in-zone == the window
	_green_hf = (window_ms(400.0, 300.0) * ramp / sweep_ms) * 0.5
	_gold_hf = (window_ms(160.0, 120.0) * ramp / sweep_ms) * 0.5
	_green_c = _rng.randf_range(0.34, 0.66)
	for i in range(_to_hit):
		_markers.append({"pos": 0.06 + i * 0.42, "dir": 1.0})
	_running = false
	queue_redraw()

	await _ready_beat("TAP WHEN THE MARKER HITS GREEN")
	if _done:
		return
	_event("eyes")            # the mark's in view, phone lit
	_running = true
	set_process(true)
	queue_redraw()

## The reaction windows this minigame requires (for the WO3 table). [label, base, floor].
func req_windows() -> Array:
	return [["tap green", 400.0, 300.0], ["tap gold", 160.0, 120.0]]

func current_score() -> float:
	if _captured.is_empty():
		return 0.0
	var s := 0.0
	for v in _captured: s += v
	return s / float(_captured.size())

# marker eases at the turnaround ends (0–0.12, 0.88–1.0) so the eye can track it;
# the zones live in 0.17–0.83, the constant-speed region, so windows stay exact.
func _speed_at(pos: float) -> float:
	if pos < 0.12: return lerpf(0.55, 1.0, pos / 0.12)
	if pos > 0.88: return lerpf(1.0, 0.55, (pos - 0.88) / 0.12)
	return 1.0

func _process(delta: float) -> void:
	if _hitstop > 0.0:
		_hitstop -= delta; queue_redraw(); return
	if _flash_t > 0.0:
		_flash_t -= delta; _flash.a = clampf(_flash_t / 0.25, 0.0, 1.0) * 0.5
	if _shake > 0.0:
		_shake = maxf(0.0, _shake - delta * 26.0)
	if _running:
		var step := delta / _sweep_s
		for m in _markers:
			m.pos += m.dir * step * _speed_at(m.pos)
			if m.pos >= 1.0: m.pos = 1.0; m.dir = -1.0
			elif m.pos <= 0.0: m.pos = 0.0; m.dir = 1.0
	queue_redraw()

func _gui_input(e: InputEvent) -> void:
	if not _running or _hitstop > 0.0:
		return
	if (e is InputEventMouseButton and e.pressed) or (e is InputEventScreenTouch and e.pressed):
		_tap()

func _tap() -> void:
	var idx := _captured.size()
	if idx >= _markers.size():
		return
	var pos: float = _markers[idx].pos
	var res := _eval(pos)
	_captured.append(res.score)
	_reasons.append(res.reason)
	_event(res.result)
	Audio.tap()
	_hitstop = 0.08
	match res.result:
		"gold": _shake = 4.0; _flash = Color(Pal.DIRTY, 0.5); _flash_t = 0.25; Audio.crit()
		"hit": _flash = Color(Pal.CLEAN, 0.4); _flash_t = 0.25; Audio.coin()
		"graze": _flash = Color(Pal.SODIUM, 0.4); _flash_t = 0.25; Audio.error()
		_: _shake = 3.0; _flash = Color(Pal.DANGER_RED, 0.5); _flash_t = 0.25; Audio.error()
	if OS.has_feature("mobile"):
		Input.vibrate_handheld(40 if res.result == "gold" else 20)
	if _captured.size() >= _to_hit:
		_running = false
		await get_tree().create_timer(0.3).timeout
		_settle()

func _eval(pos: float) -> Dictionary:
	var d: float = absf(pos - _green_c)
	if d <= _gold_hf:
		return {"score": 1.0, "result": "gold", "reason": ""}
	if d <= _green_hf:
		var closeness: float = 1.0 - (d - _gold_hf) / maxf(0.001, _green_hf - _gold_hf)
		return {"score": 0.7 + 0.25 * clampf(closeness, 0.0, 1.0), "result": "hit", "reason": ""}
	if d <= _green_hf + 0.035:
		return {"score": 0.4, "result": "graze", "reason": "A hair off. Almost had it."}
	# a real miss — say why, in the fiction's voice
	var reason := ""
	if d > _green_hf + 0.20:
		reason = "You weren't even close. Nerves."
	elif pos < _green_c:
		reason = "Too soon. He hadn't passed you yet."
	else:
		reason = "A beat late. He was already gone."
	return {"score": 0.0, "result": "miss", "reason": reason}

func _settle() -> void:
	var s := current_score()
	var det := "HE FELT IT"
	if s >= 0.999: det = "CLEAN LIFT"
	elif s >= 0.7: det = "LIFTED"
	elif s > 0.0: det = "FUMBLED IT"
	_event("done")
	var reason := ""
	for r in _reasons:
		if String(r) != "": reason = String(r); break
	_end_with(s, {"detail": det, "reason": reason,
		"result": ("gold" if s >= 0.999 else ("hit" if s >= 0.7 else ("graze" if s > 0.0 else "miss")))})

func _draw() -> void:
	var r := size
	var so := Vector2(_rng.randf_range(-_shake, _shake), _rng.randf_range(-_shake, _shake)) if _shake > 0.0 else Vector2.ZERO
	var y := r.y * 0.56 + so.y
	var x0 := r.x * BAR_X0 + so.x
	var x1 := r.x * BAR_X1 + so.x
	var bw := x1 - x0
	# the pavement (the bar)
	draw_rect(Rect2(x0, y + 18, bw, 8), Pal.RAISED)                  # kerb line
	draw_rect(Rect2(x0, y - 20, bw, 40), Color(Pal.INSET, 0.65))     # pavement slab
	# green + gold zones (the spot on the pavement to take him)
	var gx := x0 + (_green_c - _green_hf) * bw
	draw_rect(Rect2(gx, y - 20, _green_hf * 2.0 * bw, 40), Color(Pal.CLEAN, 0.30))
	var ox := x0 + (_green_c - _gold_hf) * bw
	draw_rect(Rect2(ox, y - 20, _gold_hf * 2.0 * bw, 40), Color(Pal.DIRTY, 0.85))
	# the mark, walking the pavement, phone lit
	for i in range(_markers.size()):
		var m: Dictionary = _markers[i]
		var done: bool = i < _captured.size()
		var mx: float = x0 + float(m.pos) * bw
		# little silhouette
		var col := Pal.MUTED if done else Color(0.05, 0.05, 0.06)
		draw_rect(Rect2(mx - 9, y - 62, 18, 46), col)                # body
		draw_circle(Vector2(mx, y - 70), 9.0, col)                   # head
		if not done:
			draw_rect(Rect2(mx + 6, y - 44, 8, 12), Color(Pal.GLOW, 0.9))  # lit phone
		# thin track marker
		draw_rect(Rect2(mx - 2, y - 20, 4, 40), Pal.TEXT if not done else Pal.MUTED)
	# result flash
	if _flash.a > 0.0:
		draw_rect(Rect2(Vector2.ZERO, r), _flash)
	# small live prompt during play
	if _running:
		var p := "TAP" + ("  ·  %d LEFT" % (_to_hit - _captured.size()) if _to_hit > 1 else "")
		var f := Pal.mono_font(500)
		var ps := f.get_string_size(p, HORIZONTAL_ALIGNMENT_LEFT, -1, 24)
		draw_string(f, Vector2((r.x - ps.x) / 2.0, y + 96), p, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Pal.SODIUM)

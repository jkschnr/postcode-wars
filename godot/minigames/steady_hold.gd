extends Minigame
## STEADY HOLD (WO2-T3) — jobs: pickpocket, card_fraud, smuggle. Press and HOLD to
## fill a tension bar; a red snap line sits above and creeps down. Release before
## the line to keep it all, cross it and you lose the lot. Above 70% the whole thing
## shakes and desaturates — the nerve test IS the mechanic. 6–10s. Per-job reskin.

var _fill := 0.0
var _snap := 0.95
var _snap0 := 0.95          # where the snap started (for the % readout)
var _fill_rate := 0.30
var _snap_descend := 0.04
var _stutter := 0.3
var _holding := false
var _held_any := false
var _t := 0.0
var _running := false
var _shake := 0.0
var _flash_t := 0.0
var _flash := Color(0, 0, 0, 0)
var _rng := RandomNumberGenerator.new()
var _bar_label := "REACH"
var _snap_label := "HE NOTICES"
var _next_haptic := 0.0

const RESKIN := {
	"pickpocket": ["REACH", "HE NOTICES"],
	"card_fraud": ["READING THE CARD", "DECLINED"],
	"smuggle":    ["THROUGH THE GATE", "SECOND LOOK"],
}

func run() -> void:
	var jid := String(ctx.get("job_id", "pickpocket"))
	_rng.seed = hash(jid) + stage_index() * 13 + int(stat())
	var rk: Array = RESKIN.get(jid, ["HOLD", "SPOTTED"])
	_bar_label = rk[0]; _snap_label = rk[1]
	mouse_filter = Control.MOUSE_FILTER_STOP

	var slk := stat()
	# snap line: starts lower with difficulty and per stage; descends faster with
	# difficulty, slower with Slickness (a smooth operator has more room).
	_snap = clampf(0.98 - difficulty() * 0.22 - stage_index() * 0.08, 0.42, 0.98)
	_snap0 = _snap
	_snap_descend = clampf(0.030 + difficulty() * 0.05 - slk * 0.0015, 0.012, 0.12)
	_fill_rate = 0.28 + difficulty() * 0.06
	_stutter = clampf(0.45 - slk * 0.02, 0.06, 0.45)   # Slickness = steadier fill
	_running = true
	set_process(true)
	queue_redraw()

func current_score() -> float:
	if not _running:
		return 0.0
	if _fill >= _snap:
		return 0.0
	return _score_for(_fill / max(0.001, _snap))

func _process(delta: float) -> void:
	if not _running:
		if _flash_t > 0.0:
			_flash_t -= delta; _flash.a = clampf(_flash_t / 0.3, 0.0, 1.0) * 0.5
			queue_redraw()
		return
	_t += delta
	if _shake > 0.0: _shake = max(0.0, _shake - delta * 22.0)
	# snap line always creeps down
	_snap = max(0.05, _snap - _snap_descend * delta)
	if _holding:
		# stuttering, occasionally-surging climb
		var surge := 1.0 + sin(_t * 6.5) * _stutter * 0.6 + _rng.randf_range(-_stutter, _stutter) * 0.5
		if _rng.randf() < 0.03: surge += 1.4          # occasional lurch
		_fill += _fill_rate * max(0.1, surge) * delta
		if _fill >= 0.70:
			_shake = max(_shake, (_fill - 0.7) / 0.3 * 5.0)
			# haptic pulses that speed up as it climbs
			if OS.has_feature("mobile") and _t >= _next_haptic:
				Input.vibrate_handheld(12)
				_next_haptic = _t + lerp(0.28, 0.07, clampf((_fill - 0.7) / 0.3, 0.0, 1.0))
		if _fill >= _snap:
			# crossed the line — lost the lot
			_fill = _snap
			_event("bust")
			_burst(Pal.DANGER_RED)
			_end(0.0, "HE FELT THE PULL")
			return
	queue_redraw()

func _gui_input(e: InputEvent) -> void:
	if not _running:
		return
	if e is InputEventMouseButton or e is InputEventScreenTouch:
		if e.pressed:
			_holding = true; _held_any = true; Audio.tap()
		else:
			if _held_any:
				_release()

func _release() -> void:
	_holding = false
	if not _running:
		return
	var ratio: float = _fill / max(0.001, _snap)
	var score := _score_for(ratio)
	var det := "TOO CAREFUL"
	if score >= 0.999:
		det = "SILK"; _burst(Pal.DIRTY)
	elif score >= 0.7:
		det = "CLEAN"; _burst(Pal.CLEAN)
	_end(score, det)

func _score_for(ratio: float) -> float:
	if ratio >= 0.85 and ratio < 1.0:
		return 1.0
	if ratio >= 0.60:
		return 0.7 + (ratio - 0.60) / 0.25 * 0.25
	return 0.4

func _burst(c: Color) -> void:
	_flash = Color(c, 0.5); _flash_t = 0.3
	if c == Pal.DIRTY: Audio.crit()
	elif c == Pal.CLEAN: Audio.coin()
	else: Audio.error()

func _end(score: float, det: String) -> void:
	_running = false
	set_process(true)   # keep ticking for the flash fade
	await get_tree().create_timer(0.35).timeout
	_finish(score, {"detail": det, "result": ("gold" if score >= 0.999 else ("hit" if score >= 0.7 else ("graze" if score > 0.0 else "miss")))})

func _draw() -> void:
	var r := size
	var so := Vector2(_rng.randf_range(-_shake, _shake), _rng.randf_range(-_shake, _shake)) if _shake > 0.0 else Vector2.ZERO
	# desaturate wash above 70%
	if _fill > 0.7:
		draw_rect(Rect2(Vector2.ZERO, r), Color(0.5, 0.5, 0.52, (_fill - 0.7) / 0.3 * 0.22))
	# vertical tension bar in the centre
	var bw := 150.0
	var bh := r.y * 0.62
	var bx := (r.x - bw) / 2.0 + so.x
	var by := r.y * 0.16 + so.y
	# track
	draw_rect(Rect2(bx, by, bw, bh), Pal.INSET)
	draw_rect(Rect2(bx, by, bw, bh), Pal.RAISED, false, 2.0)
	# fill (from the bottom up)
	var fh := bh * clampf(_fill, 0.0, 1.0)
	var fill_col := Pal.CLEAN.lerp(Pal.SODIUM, clampf(_fill / max(0.01, _snap), 0.0, 1.0))
	if _fill > 0.7: fill_col = Pal.DANGER_RED
	draw_rect(Rect2(bx, by + bh - fh, bw, fh), Color(fill_col, 0.9))
	# snap line
	var sy := by + bh * (1.0 - clampf(_snap, 0.0, 1.0))
	draw_rect(Rect2(bx - 22, sy - 3, bw + 44, 6), Pal.DANGER_RED)
	var f := Pal.mono_font(500)
	draw_string(f, Vector2(bx + bw + 30, sy + 8), _snap_label, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Pal.DANGER_RED)
	# bar label
	var bl := Pal.mono_font(500)
	draw_string(bl, Vector2(bx - bl.get_string_size(_bar_label, HORIZONTAL_ALIGNMENT_LEFT, -1, 22).x - 30, by + bh), _bar_label, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Pal.TEXT2)
	# flash
	if _flash_t > 0.0 and _flash.a > 0.0:
		draw_rect(Rect2(Vector2.ZERO, r), _flash)
	# prompt
	if _running:
		var p := "PRESS & HOLD  ·  RELEASE BEFORE THE LINE" if not _held_any else "…RELEASE"
		var ps := f.get_string_size(p, HORIZONTAL_ALIGNMENT_LEFT, -1, 24)
		draw_string(f, Vector2((r.x - ps.x) / 2.0, by + bh + 64), p, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Pal.SODIUM if _held_any else Pal.TEXT2)

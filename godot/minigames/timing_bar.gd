extends Minigame
## TIMING BAR (WO2-T2) — jobs: phone_snatch. One tap. A marker sweeps a bar; land
## it in the gold perfect zone for a CLEAN LIFT. Slickness widens the green zone,
## job tier + city danger speed the marker, loud/quiet shift it. 4–6s.

const BAR_X0 := 0.09
const BAR_X1 := 0.91

var _markers: Array = []          # [{phase, speed, dir, trail:[]}]
var _green_c := 0.5               # green zone centre (0..1 along bar)
var _green_w := 0.26              # green zone width  (fraction of bar)
var _gold_w := 0.09               # gold zone width
var _to_hit := 1                  # markers still to tap
var _captured: Array = []         # scores captured per tap
var _running := false
var _hitstop := 0.0
var _shake := 0.0
var _flash := Color(0, 0, 0, 0)
var _flash_t := 0.0
var _copy := ""
var _rng := RandomNumberGenerator.new()

const COPY := [
	"He's got it out, screen up, headphones in.",
	"Two paces. One shot.",
	"He's walking and talking. Not looking.",
]

func run() -> void:
	_rng.seed = hash(ctx.get("job_id", "phone")) + stage_index() * 7 + int(stat() * 10)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_copy = COPY[_rng.randi() % COPY.size()]

	# green zone from Slickness (18% + SLK×0.4%, cap 34%); gold is a third of it
	_green_w = clampf(0.18 + stat() * 0.004, 0.18, 0.34)
	_gold_w = _green_w * 0.34
	_green_c = _rng.randf_range(0.24, 0.76)

	# marker speed from difficulty + approach
	var speed := 1.4 + difficulty() * 1.1
	if approach() == "loud": speed *= 1.25
	elif approach() == "quiet": speed *= 0.85

	# stage 3+ adds a second marker — both must be hit
	var n := 2 if stage_index() >= 3 else 1
	_to_hit = n
	for i in range(n):
		_markers.append({
			"phase": _rng.randf() * 2.0,
			"speed": speed * (1.0 + i * 0.12),
			"pos": 0.0,
			"trail": [] as Array,
		})
	_running = true
	set_process(true)
	queue_redraw()

func current_score() -> float:
	if _captured.is_empty():
		return 0.0
	var s := 0.0
	for v in _captured: s += v
	return s / float(_captured.size())

func _process(delta: float) -> void:
	if _hitstop > 0.0:
		_hitstop -= delta
		queue_redraw()
		return
	if _flash_t > 0.0:
		_flash_t -= delta
		_flash.a = clampf(_flash_t / 0.25, 0.0, 1.0) * 0.5
	if _shake > 0.0:
		_shake = max(0.0, _shake - delta * 26.0)
	if _running:
		for m in _markers:
			m.phase += m.speed * delta
			var ph: float = fmod(m.phase, 2.0)
			m.pos = ph if ph < 1.0 else 2.0 - ph
			var tr: Array = m.trail
			tr.push_front(m.pos)
			if tr.size() > 6: tr.pop_back()
	queue_redraw()

func _gui_input(e: InputEvent) -> void:
	if not _running or _hitstop > 0.0:
		return
	if (e is InputEventMouseButton and e.pressed) or (e is InputEventScreenTouch and e.pressed):
		_tap()

func _tap() -> void:
	# evaluate the next un-tapped marker
	var idx := _captured.size()
	if idx >= _markers.size():
		return
	var pos: float = _markers[idx].pos
	var score := _eval(pos)
	_captured.append(score)
	_event("gold" if score >= 0.999 else ("hit" if score >= 0.7 else "miss"))
	Audio.tap()
	# hit-stop makes the tap feel like an action
	_hitstop = 0.08
	if score >= 0.999:
		_shake = 4.0; _flash = Color(Pal.DIRTY, 0.5); _flash_t = 0.25; Audio.crit()
	elif score >= 0.7:
		_flash = Color(Pal.CLEAN, 0.4); _flash_t = 0.25; Audio.coin()
	elif score > 0.0:
		_flash = Color(Pal.SODIUM, 0.4); _flash_t = 0.25; Audio.error()
	else:
		_shake = 3.0; _flash = Color(Pal.DANGER_RED, 0.5); _flash_t = 0.25; Audio.error()
	if OS.has_feature("mobile"):
		Input.vibrate_handheld(20 if score < 1.0 else 40)
	if _captured.size() >= _to_hit:
		_running = false
		await get_tree().create_timer(0.32).timeout
		_settle()

func _eval(pos: float) -> float:
	var d: float = abs(pos - _green_c)
	if d <= _gold_w * 0.5:
		return 1.0
	if d <= _green_w * 0.5:
		# 0.7 at the green edge → 0.95 near the gold edge (closeness to centre)
		var closeness: float = 1.0 - (d - _gold_w * 0.5) / max(0.001, (_green_w - _gold_w) * 0.5)
		return 0.7 + 0.25 * clampf(closeness, 0.0, 1.0)
	if d <= _green_w * 0.5 + 0.05:
		return 0.35   # just outside — fumbled
	return 0.0

func _settle() -> void:
	var s := current_score()
	var det := "HE FELT IT"
	if s >= 0.999: det = "CLEAN LIFT"
	elif s >= 0.7: det = "LIFTED"
	elif s > 0.0: det = "FUMBLED IT"
	_finish(s, {"detail": det, "result": ("gold" if s >= 0.999 else ("hit" if s >= 0.7 else ("graze" if s > 0.0 else "miss")))})

func _draw() -> void:
	var r := size
	var shake_off := Vector2(_rng.randf_range(-_shake, _shake), _rng.randf_range(-_shake, _shake)) if _shake > 0.0 else Vector2.ZERO
	# copy above the bar
	var f := Pal.body_font(500)
	var cs := f.get_string_size(_copy, HORIZONTAL_ALIGNMENT_LEFT, -1, 26)
	draw_string(f, Vector2((r.x - cs.x) / 2.0, r.y * 0.30), _copy, HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Pal.TEXT2)

	var y := r.y * 0.52 + shake_off.y
	var x0 := r.x * BAR_X0 + shake_off.x
	var x1 := r.x * BAR_X1 + shake_off.x
	var bw := x1 - x0
	var h := 34.0
	# track
	draw_rect(Rect2(x0, y - h / 2, bw, h), Pal.INSET)
	draw_rect(Rect2(x0, y - h / 2, bw, h), Pal.RAISED, false, 2.0)
	# green + gold zones
	var gx := x0 + (_green_c - _green_w / 2.0) * bw
	draw_rect(Rect2(gx, y - h / 2, _green_w * bw, h), Color(Pal.CLEAN, 0.32))
	var ox := x0 + (_green_c - _gold_w / 2.0) * bw
	draw_rect(Rect2(ox, y - h / 2, _gold_w * bw, h), Color(Pal.DIRTY, 0.85))
	# markers + 6-frame trails
	for i in range(_markers.size()):
		var m: Dictionary = _markers[i]
		var done: bool = i < _captured.size()
		var tr: Array = m.trail
		for j in range(tr.size()):
			var tx: float = x0 + float(tr[j]) * bw
			var a := (1.0 - float(j) / 6.0) * 0.35
			draw_rect(Rect2(tx - 3, y - h / 2 - 10, 6, h + 20), Color(Pal.TEXT, a))
		var mx: float = x0 + float(m.pos) * bw
		var mc := Pal.MUTED if done else Pal.TEXT
		draw_rect(Rect2(mx - 4, y - h / 2 - 14, 8, h + 28), mc)
		draw_rect(Rect2(mx - 4, y - h / 2 - 14, 8, h + 28), Pal.GLOW if not done else Pal.MUTED, false, 2.0)
	# result flash
	if _flash.a > 0.0:
		draw_rect(Rect2(Vector2.ZERO, r), _flash)
	# prompt
	if _running:
		var p := "TAP TO LIFT" + ("  ·  %d LEFT" % (_to_hit - _captured.size()) if _to_hit > 1 else "")
		var ps := Pal.mono_font(500).get_string_size(p, HORIZONTAL_ALIGNMENT_LEFT, -1, 24)
		draw_string(Pal.mono_font(500), Vector2((r.x - ps.x) / 2.0, y + 90), p, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Pal.SODIUM)

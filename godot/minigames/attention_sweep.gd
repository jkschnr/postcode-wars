extends Minigame
## ATTENTION SWEEP (WO2-T4) — jobs: shoplift, warehouse, grow_harvest. A grid of
## grabbable tiles; an attention arc (gaze / torch / headlights) sweeps over them.
## Tap a tile ONLY when it isn't lit. Each grab speeds the arc 6% — escalation is
## self-inflicted. Tap a hot tile = caught, score 0. CASH OUT is always safe. 8–14s.

var _tiles: Array = []          # [{rect, val, grabbed}]
var _arc := 0.0                 # 0..1 sweep position across the grid
var _dir := 1.0
var _speed := 0.32              # sweeps/sec
var _cone := 0.26               # cone half-not... width as fraction of grid span
var _grid_x0 := 0.0
var _grid_x1 := 1.0
var _running := false
var _grabbed := 0
var _grabbed_val := 0
var _max_val := 1
var _flash_t := 0.0
var _flash := Color(0, 0, 0, 0)
var _rng := RandomNumberGenerator.new()
var _cash_btn: Button
var _caught_text := "SPOTTED"
var _light := Color(1.0, 0.85, 0.5)

const RESKIN := {
	"shoplift":     {"caught": "He's been watching you since aisle two.", "light": Color(1.0, 0.92, 0.7)},
	"warehouse":    {"caught": "Torch stops. Stays stopped.",             "light": Color(0.8, 0.9, 1.0)},
	"grow_harvest": {"caught": "Someone's slowing down outside.",         "light": Color(1.0, 0.8, 0.6)},
}

func run() -> void:
	var jid := String(ctx.get("job_id", "shoplift"))
	_rng.seed = hash(jid) + stage_index() * 17 + int(stat())
	var rk: Dictionary = RESKIN.get(jid, {"caught": "SPOTTED", "light": Color(1, 0.85, 0.5)})
	_caught_text = rk.caught
	_light = rk.light
	mouse_filter = Control.MOUSE_FILTER_STOP

	# 6–9 tiles; Slickness narrows the arc cone
	var n := 6 + (_rng.randi() % 4)
	var cols := 3
	var rows := int(ceil(n / float(cols)))
	var r := size
	_grid_x0 = r.x * 0.10
	_grid_x1 = r.x * 0.90
	var gy0 := r.y * 0.20
	var gy1 := r.y * 0.66
	var cw := (_grid_x1 - _grid_x0) / cols
	var ch := (gy1 - gy0) / rows
	for i in range(n):
		var cx := i % cols
		var cy := i / cols
		var pad := 12.0
		var rect := Rect2(_grid_x0 + cx * cw + pad, gy0 + cy * ch + pad, cw - pad * 2, ch - pad * 2)
		var val := 40 + _rng.randi() % 60
		_tiles.append({"rect": rect, "val": val, "grabbed": false})
		_max_val += val

	_speed = 0.28 + difficulty() * 0.22 + stage_index() * 0.06
	_cone = clampf(0.30 - stat() * 0.006, 0.12, 0.30)

	_cash_btn = Pal.btn("CASH OUT", "hivis", 84)
	_cash_btn.custom_minimum_size = Vector2(320, 84)
	_cash_btn.position = Vector2((r.x - 320) / 2.0, r.y - 120)
	_cash_btn.pressed.connect(_cash_out)
	add_child(_cash_btn)

	_running = true
	set_process(true)
	queue_redraw()

func current_score() -> float:
	return clampf(float(_grabbed_val) / float(_max_val), 0.0, 1.0)

func _process(delta: float) -> void:
	if _flash_t > 0.0:
		_flash_t -= delta; _flash.a = clampf(_flash_t / 0.3, 0.0, 1.0) * 0.5
	if not _running:
		queue_redraw(); return
	_arc += _dir * _speed * delta
	if _arc >= 1.0: _arc = 1.0; _dir = -1.0
	elif _arc <= 0.0: _arc = 0.0; _dir = 1.0
	queue_redraw()

func _tile_hot(t: Dictionary) -> bool:
	var cxf: float = ((t.rect.position.x + t.rect.size.x / 2.0) - _grid_x0) / max(1.0, (_grid_x1 - _grid_x0))
	return abs(cxf - _arc) <= _cone * 0.5

func _gui_input(e: InputEvent) -> void:
	if not _running:
		return
	if (e is InputEventMouseButton and e.pressed) or (e is InputEventScreenTouch and e.pressed):
		var p: Vector2 = e.position
		for t in _tiles:
			if t.grabbed: continue
			if (t.rect as Rect2).has_point(p):
				_hit_tile(t)
				return

func _hit_tile(t: Dictionary) -> void:
	if _tile_hot(t):
		# caught in the light
		_event("caught")
		_flash = Color(Pal.DANGER_RED, 0.55); _flash_t = 0.3
		Audio.error()
		if OS.has_feature("mobile"): Input.vibrate_handheld(60)
		_end(0.0, _caught_text)
		return
	# clean grab
	t.grabbed = true
	_event("grab")
	_grabbed += 1
	_grabbed_val += int(t.val)
	_speed *= 1.06                                   # self-inflicted escalation
	_flash = Color(Pal.CLEAN, 0.28); _flash_t = 0.22
	Audio.coin()
	queue_redraw()

func _cash_out() -> void:
	if not _running: return
	Audio.ui()
	var score := current_score()
	if _grabbed >= 6:
		score = 1.0
	var det := "CLEANED OUT" if _grabbed >= 6 else ("GOT SOME" if _grabbed > 0 else "WALKED")
	_end(score, det)

func _end(score: float, det: String) -> void:
	_running = false
	if is_instance_valid(_cash_btn): _cash_btn.disabled = true
	await get_tree().create_timer(0.35).timeout
	_finish(score, {"detail": det, "result": ("gold" if score >= 0.999 else ("hit" if score >= 0.5 else ("graze" if score > 0.0 else "miss")))})

func _draw() -> void:
	var r := size
	# bag counter
	var f := Pal.mono_font(500)
	draw_string(f, Vector2(r.x * 0.10, r.y * 0.14), "HAUL  ×%d  ·  %s" % [_grabbed, Pal.money(_grabbed_val)], HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Pal.DIRTY)
	# tiles
	for t in _tiles:
		var rect: Rect2 = t.rect
		if t.grabbed:
			draw_rect(rect, Color(Pal.INSET, 0.6))
			draw_rect(rect, Pal.RAISED, false, 2.0)
			var tickf := Pal.display_font()
			draw_string(tickf, rect.position + Vector2(rect.size.x / 2 - 10, rect.size.y / 2 + 12), "✓", HORIZONTAL_ALIGNMENT_LEFT, -1, 40, Color(Pal.CLEAN, 0.6))
			continue
		var hot := _tile_hot(t)
		draw_rect(rect, Pal.PANEL)
		draw_rect(rect, Pal.SODIUM if hot else Pal.HAIRLINE, false, 2.0)
	# light cone as a real gradient over the grid (not a flat overlay)
	var span := _grid_x1 - _grid_x0
	var cx := _grid_x0 + _arc * span
	var gy0 := r.y * 0.18
	var gy1 := r.y * 0.68
	var hw := _cone * 0.5 * span
	var steps := 10
	for i in range(steps):
		var frac := i / float(steps)
		var w := hw * (1.0 - frac)
		var a := (1.0 - frac) * 0.14
		draw_rect(Rect2(cx - w, gy0, w * 2.0, gy1 - gy0), Color(_light, a))
	# flash
	if _flash_t > 0.0 and _flash.a > 0.0:
		draw_rect(Rect2(Vector2.ZERO, r), _flash)
	# prompt
	if _running:
		var p := "GRAB THE DARK ONES  ·  CASH OUT WHEN YOU'RE HEAVY"
		var ps := f.get_string_size(p, HORIZONTAL_ALIGNMENT_LEFT, -1, 22)
		draw_string(f, Vector2((r.x - ps.x) / 2.0, r.y * 0.74), p, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Pal.TEXT2)

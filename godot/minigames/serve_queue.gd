extends Minigame
## SERVE QUEUE (WO2-T6) — jobs: corner_shotting, counterfeit. Customers step up one
## at a time; TAP to serve (+money) or SWIPE away to refuse (free, safe). Among them
## are undercovers, each showing exactly one tell. Serve one = BUST, score 0. Each
## serve raises the next one's odds. CASH OUT any time, always safe. 10–14s.

const TELLS := [
	"too clean — shoes wrong for the estate",
	"asks twice — \"how much again?\"",
	"no eye contact with the money",
	"a twenty that's never been folded",
	"looks past you, over your shoulder",
	"knows your name — you never told them",
]

var _running := false
var _served := 0
var _uc_rate := 0.16
var _cur: Dictionary = {}
var _walk := 0.0                  # 0 (bottom) → 1 (at the counter)
var _walk_speed := 0.9
var _flash_t := 0.0
var _flash := Color(0, 0, 0, 0)
var _swipe_dx := 0.0
var _press_x := 0.0
var _pressing := false
var _moved := false
var _rng := RandomNumberGenerator.new()
var _cash_btn: Button
var _busted := false
var _bad_word := "an undercover"

func run() -> void:
	var jid := String(ctx.get("job_id", "corner_shotting"))
	_rng.seed = hash(jid) + stage_index() * 23 + int(stat())
	_bad_word = "Trading Standards" if jid == "counterfeit" else "an undercover"
	mouse_filter = Control.MOUSE_FILTER_STOP
	_uc_rate = clampf(0.12 + difficulty() * 0.12 + stage_index() * 0.04, 0.10, 0.42)
	_walk_speed = 0.8 + difficulty() * 0.5
	_cash_btn = Pal.btn("CASH OUT", "hivis", 80)
	_cash_btn.custom_minimum_size = Vector2(300, 80)
	_cash_btn.position = Vector2((size.x - 300) / 2.0, size.y - 108)
	_cash_btn.pressed.connect(_cash_out)
	add_child(_cash_btn)
	_running = true
	_next_customer()
	set_process(true)

func current_score() -> float:
	return clampf(_served / 12.0, 0.0, 1.0)

func _next_customer() -> void:
	var is_uc := _rng.randf() < _uc_rate
	var face := _rng.randi() % Pal.PORTRAIT_COUNT
	var tell := ""
	if is_uc:
		tell = TELLS[_rng.randi() % TELLS.size()]
	# a legit punter also gets a harmless line so the read is a real decision
	var line := tell if is_uc else _punter_line()
	_cur = {"uc": is_uc, "face": face, "tell": tell, "line": line}
	_walk = 0.0

func _punter_line() -> String:
	var lines := ["reg from the block, nods, sorted", "quick one, keeps it moving",
		"knows the drill, exact money", "hood up, cold, just wants out of the rain",
		"seen 'em every day this week"]
	return lines[_rng.randi() % lines.size()]

func _process(delta: float) -> void:
	if _flash_t > 0.0:
		_flash_t -= delta; _flash.a = clampf(_flash_t / 0.3, 0.0, 1.0) * 0.55
	if not _running:
		queue_redraw(); return
	_walk = min(1.0, _walk + _walk_speed * delta * 0.35)
	queue_redraw()

func _gui_input(e: InputEvent) -> void:
	if not _running or _cur.is_empty():
		return
	if e is InputEventMouseButton or e is InputEventScreenTouch:
		if e.pressed:
			_pressing = true; _press_x = e.position.x; _swipe_dx = 0.0; _moved = false
		elif _pressing:
			_pressing = false
			if abs(_swipe_dx) > 90.0:
				_refuse()
			elif not _moved:
				_serve()
	elif (e is InputEventMouseMotion or e is InputEventScreenDrag) and _pressing:
		_swipe_dx = e.position.x - _press_x
		if abs(_swipe_dx) > 14.0: _moved = true
		queue_redraw()

func _serve() -> void:
	if _cur.get("uc", false):
		_busted = true
		_event("bust")
		_flash = Color(Pal.POLICE, 0.6); _flash_t = 0.4
		Audio.error()
		if OS.has_feature("mobile"): Input.vibrate_handheld(80)
		_end(0.0, "THAT WAS A COPPER")
		return
	_served += 1
	_event("serve")
	_uc_rate = min(0.6, _uc_rate + 0.04)     # heat rises with every serve
	_flash = Color(Pal.CLEAN, 0.28); _flash_t = 0.22
	Audio.coin()
	_swipe_dx = 0.0
	_next_customer()

func _refuse() -> void:
	# refusing a real customer costs a little; refusing a cop is free and smart
	Audio.ui()
	_swipe_dx = 0.0
	_next_customer()

func _cash_out() -> void:
	if not _running: return
	Audio.ui()
	var score := current_score()
	if _served >= 8: score = 1.0
	_end(score, "PATTERN" if _served >= 8 else ("GOOD TRADE" if _served > 0 else "QUIET NIGHT"))

func _end(score: float, det: String) -> void:
	_running = false
	if is_instance_valid(_cash_btn): _cash_btn.disabled = true
	await get_tree().create_timer(0.4).timeout
	_finish(score, {"detail": det, "result": ("gold" if score >= 0.999 else ("hit" if score >= 0.4 else "miss"))})

func _draw() -> void:
	var r := size
	var f := Pal.mono_font(500)
	# served counter
	draw_string(f, Vector2(r.x * 0.10, r.y * 0.12), "SERVED  ×%d" % _served, HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Pal.DIRTY)
	if _cur.is_empty():
		return
	# the customer walking up
	var cy: float = lerp(r.y * 0.72, r.y * 0.40, _walk)
	var cx := r.x / 2.0 + _swipe_dx
	var pr := 92.0
	# portrait chip
	var box := Rect2(cx - pr, cy - pr, pr * 2, pr * 2)
	draw_rect(box, Pal.PANEL)
	draw_rect(box, Pal.SODIUM if _swipe_dx == 0.0 else (Pal.DANGER_RED if _swipe_dx < 0 else Pal.CLEAN), false, 3.0)
	var tex := Pal.portrait_tex(int(_cur.face))
	if tex != null:
		draw_texture_rect(tex, box.grow(-6), false)
	# their one line of behaviour (readable in a glance)
	var line := String(_cur.get("line", ""))
	var lw := f.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, 24).x
	draw_string(f, Vector2(cx - lw / 2.0, cy + pr + 44), line, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Pal.TEXT)
	# skill 10+ marks suspicion subtly
	if Game.skill_level(String(ctx.get("job_id", ""))) >= 10 and _cur.get("uc", false):
		draw_string(f, Vector2(cx + pr - 10, cy - pr + 6), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, 40, Color(Pal.DANGER_RED, 0.5))
	# flash
	if _flash_t > 0.0 and _flash.a > 0.0:
		draw_rect(Rect2(Vector2.ZERO, r), _flash)
	# prompt
	if _running:
		var p := "TAP TO SERVE  ·  SWIPE TO WAVE OFF"
		draw_string(f, Vector2((r.x - f.get_string_size(p, HORIZONTAL_ALIGNMENT_LEFT, -1, 22).x) / 2.0, r.y - 150), p, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Pal.TEXT2)

extends Minigame
## PRESSURE DIAL (WO2-T9) — jobs: extortion, protection, gun_deal. A conversation as
## two meters: fill COMPLIANCE without letting PANIC max out. PRESS fills both fast;
## EASE fills compliance slowly but drains panic. Read the mark's face and pick the
## button. Panic maxed = it goes wrong. Strength powers PRESS, Slickness powers EASE,
## your rep lowers the starting panic, a visible weapon trades panic for compliance.

var _compliance := 0.0
var _panic := 0.0
var _running := false
var _press_gain := 0.14
var _press_panic := 0.10
var _ease_gain := 0.05
var _ease_drain := 0.09
var _self_fill := 0.02
var _t := 0.0
var _breath := 0.0
var _shake := 0.0
var _mark := "a shopkeeper"
var _panic_line := "It goes wrong."
var _portrait: Texture2D
var _flash_t := 0.0
var _flash := Color(0, 0, 0, 0)

const RESKIN := {
	"extortion":  {"mark": "a shopkeeper",        "panic": "He's got a cousin. You're about to meet him.", "face": "delroy"},
	"protection": {"mark": "a regular, paying late","panic": "He'd rather take the hiding than the arrangement.", "face": "nev"},
	"gun_deal":   {"mark": "a nervous buyer",       "panic": "He's walking backwards. Nobody good walks backwards.", "face": "hallow"},
}

func run() -> void:
	var jid := String(ctx.get("job_id", "extortion"))
	var rk: Dictionary = RESKIN.get(jid, {"mark": "the mark", "panic": "It goes wrong.", "face": "silas"})
	_mark = rk.mark; _panic_line = rk.panic
	_portrait = Pal.cast_portrait(rk.face)
	mouse_filter = Control.MOUSE_FILTER_STOP

	var strv := float(Game.eff_stat("strength"))
	var slk := float(Game.eff_stat("slickness"))
	var rep := float(Game.level())
	var weapon := has_tool("weapon") or has_tool("shooter") or has_tool("blade") or has_tool("piece")
	_press_gain = (0.13 + strv * 0.006) * (1.4 if weapon else 1.0)
	_press_panic = (0.11) * (1.6 if weapon else 1.0)
	_ease_gain = 0.05
	_ease_drain = 0.08 + slk * 0.004
	_self_fill = 0.016 + difficulty() * 0.03
	_panic = clampf(0.16 - rep * 0.004 + difficulty() * 0.05, 0.0, 0.35)

	var press := Pal.btn("PRESS", "danger", 108)
	press.custom_minimum_size = Vector2(0, 108)
	press.position = Vector2(size.x * 0.08, size.y - 150)
	press.size.x = size.x * 0.40
	press.pressed.connect(_do_press)
	add_child(press)
	var ease := Pal.btn("EASE", "secondary", 108)
	ease.custom_minimum_size = Vector2(0, 108)
	ease.position = Vector2(size.x * 0.52, size.y - 150)
	ease.size.x = size.x * 0.40
	ease.add_theme_color_override("font_color", Pal.CLEAN)
	ease.pressed.connect(_do_ease)
	add_child(ease)

	_running = true
	set_process(true)
	queue_redraw()

func current_score() -> float:
	if _panic >= 1.0: return 0.0
	# provisional: compliance carries it, panic docks it
	return clampf(_compliance * (1.0 - _panic * 0.4), 0.0, 1.0)

func _do_press() -> void:
	if not _running: return
	Audio.hit(0.7)
	_compliance = min(1.0, _compliance + _press_gain)
	_panic = min(1.0, _panic + _press_panic)
	_check()

func _do_ease() -> void:
	if not _running: return
	Audio.ui()
	_compliance = min(1.0, _compliance + _ease_gain)
	_panic = max(0.0, _panic - _ease_drain)
	_check()

func _check() -> void:
	_shake = _panic
	if _panic >= 1.0:
		_event("bust")
		_flash = Color(Pal.DANGER_RED, 0.6); _flash_t = 0.4
		Audio.error()
		_end(0.0, _panic_line)
	elif _compliance >= 1.0:
		var score := 1.0 if _panic < 0.40 else 0.7
		_flash = Color(Pal.CLEAN if score >= 0.999 else Pal.SODIUM, 0.4); _flash_t = 0.35
		Audio.coin()
		_end(score, "HE UNDERSTANDS" if score >= 0.999 else "HE'LL PAY. HE'LL ALSO TALK.")
	queue_redraw()

func _process(delta: float) -> void:
	if _flash_t > 0.0:
		_flash_t -= delta; _flash.a = clampf(_flash_t / 0.35, 0.0, 1.0) * 0.6
	if not _running:
		queue_redraw(); return
	_t += delta
	_panic = min(1.0, _panic + _self_fill * delta)
	if _shake > 0.0: _shake = max(0.0, _shake - delta * 1.5)
	# breathing audible above 70% panic, faster as it climbs
	if _panic > 0.70:
		_breath -= delta
		if _breath <= 0.0:
			Audio._emit("whoosh", lerp(0.8, 1.4, _panic), -18.0)
			_breath = lerp(0.7, 0.25, clampf((_panic - 0.7) / 0.3, 0.0, 1.0))
	if _panic >= 1.0:
		_check()
	queue_redraw()

func _mood() -> String:
	if _panic < 0.25: return "CALM"
	if _panic < 0.50: return "WARY"
	if _panic < 0.75: return "SCARED"
	return "HOSTILE"

func _end(score: float, det: String) -> void:
	_running = false
	for c in get_children():
		if c is Button: c.disabled = true
	await get_tree().create_timer(0.4).timeout
	_finish(score, {"detail": det, "result": ("gold" if score >= 0.999 else ("hit" if score >= 0.4 else "miss"))})

func _draw() -> void:
	var r := size
	var tremor := Vector2(randf_range(-_shake, _shake) * 6.0, randf_range(-_shake, _shake) * 6.0)
	# portrait of the mark, tinted by mood
	var pr := 150.0
	var cx := r.x / 2.0
	var box := Rect2(cx - pr + tremor.x, r.y * 0.10 + tremor.y, pr * 2, pr * 2)
	var mood := _mood()
	var mcol := Pal.CLEAN
	match mood:
		"WARY": mcol = Pal.SODIUM
		"SCARED": mcol = Pal.DIRTY
		"HOSTILE": mcol = Pal.DANGER_RED
	draw_rect(box, Pal.PANEL)
	if _portrait != null:
		draw_texture_rect(_portrait, box.grow(-6), false, Color(1, 1, 1).lerp(mcol, 0.25))
	draw_rect(box, mcol, false, 4.0)
	var f := Pal.mono_font(500)
	draw_string(f, Vector2(cx - f.get_string_size(mood, HORIZONTAL_ALIGNMENT_LEFT, -1, 26).x / 2.0, box.position.y + box.size.y + 40), mood + "  ·  " + _mark, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, mcol)
	# compliance bar (fill) + panic bar (danger)
	var by := r.y * 0.62
	_bar(Rect2(r.x * 0.08, by, r.x * 0.84, 26), _compliance, Pal.CLEAN, "COMPLIANCE")
	_bar(Rect2(r.x * 0.08, by + 54, r.x * 0.84, 26), _panic, Pal.DANGER_RED, "PANIC")
	if _flash_t > 0.0 and _flash.a > 0.0:
		draw_rect(Rect2(Vector2.ZERO, r), _flash)

func _bar(rect: Rect2, v: float, col: Color, label: String) -> void:
	draw_rect(rect, Pal.INSET)
	draw_rect(Rect2(rect.position, Vector2(rect.size.x * clampf(v, 0, 1), rect.size.y)), col)
	draw_rect(rect, Pal.RAISED, false, 2.0)
	draw_string(Pal.mono_font(500), rect.position + Vector2(0, -8), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, col)

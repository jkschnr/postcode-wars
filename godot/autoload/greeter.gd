extends Node
## Greeter (guide Step 6) — a character meets you on open, comments on what
## actually happened since you left, and hands you the day. Fires on the first
## session of each day and after 6+ hours away; on rapid re-opens it stays quiet.
## Chosen by context, never randomly.

const RAPID_S := 5400        # 90 min — under this, no greeter
const AWAY_S := 21600        # 6 h — over this, greet even same day

## Decide whether to greet, and run the card. Always calls on_done exactly once.
func maybe_greet(on_done: Callable) -> void:
	if not Game.s.get("prologue_done", false):
		on_done.call(); return
	var sess: Dictionary = Game.s.get("session", {})
	var last_end := float(sess.get("last_end", 0))
	var away := Game.now() - last_end if last_end > 0 else 999999.0
	var today := _date_str()
	var first_today: bool = String(Game.s.get("_greet_date", "")) != today
	if not first_today and away < AWAY_S:
		on_done.call(); return
	if away < RAPID_S and not first_today:
		on_done.call(); return
	Game.s["_greet_date"] = today
	Game.persist()
	var pick := _pick(away)
	if pick.is_empty():
		on_done.call(); return
	var card := _Card.new()
	card.setup(pick, on_done)
	App.I.overlay.add_child(card)

func _pick(away: float) -> Dictionary:
	var days_away := away / 86400.0
	var who := "nads"
	var early: bool = Game.day() <= 3
	var heat := Game.heat()
	if early or Game.in_jail():
		who = "uncle_t"
	# choose the set bucket by context, most-specific first
	var bucket := _time_bucket()
	if days_away >= 8: bucket = "return_8"
	elif days_away >= 4: bucket = "return_4_7"
	elif days_away >= 1: bucket = "return_1_3"
	elif heat >= 6.0: bucket = "high_heat"
	var g: Dictionary = Config.greeter.get(who, {})
	var sets: Dictionary = g.get("sets", {})
	var pool: Array = sets.get(bucket, [])
	if pool.is_empty(): pool = sets.get(_time_bucket(), [])
	if pool.is_empty(): pool = sets.get("default", [])
	if pool.is_empty(): return {}
	# exclude the last few used lines, pick stable-per-day
	var recent: Array = Game.s.get("_greet_recent", [])
	var fresh: Array = pool.filter(func(e): return not (e.get("id", "") in recent))
	if fresh.is_empty(): fresh = pool
	var idx := 0
	if fresh.size() > 1:
		idx = _daily_seed() % fresh.size()
	var entry: Dictionary = fresh[idx]
	recent.append(entry.get("id", ""))
	while recent.size() > 4: recent.pop_front()
	Game.s["_greet_recent"] = recent
	return {"character": who, "name": String(g.get("name", who)).to_upper(),
		"lines": entry.get("lines", []), "grants": entry.get("grants", "")}

func _time_bucket() -> String:
	var h: int = Time.get_datetime_dict_from_system(false).hour
	if h >= 5 and h < 12: return "morning"
	if h >= 12 and h < 18: return "afternoon"
	return "evening"

func _date_str() -> String:
	var d := Time.get_datetime_dict_from_system(false)
	return "%04d-%02d-%02d" % [int(d.year), int(d.month), int(d.day)]

func _daily_seed() -> int:
	return abs(hash(_date_str() + str(Game.s.get("seed", 0))))

# ------------------------------------------------------------------ the card
class _Card extends Control:
	var _lines: Array = []
	var _i := 0
	var _done: Callable
	var _label: Label
	var _hint: Label
	var _grants := ""

	func setup(pick: Dictionary, on_done: Callable) -> void:
		_lines = pick.get("lines", [])
		_done = on_done
		_grants = String(pick.get("grants", ""))
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		# the ROOT catches every tap/touch and advances — nothing below eats clicks
		mouse_filter = Control.MOUSE_FILTER_STOP
		gui_input.connect(_on_input)
		# dim (non-interactive)
		var dim := ColorRect.new(); dim.color = Color(0, 0, 0, 0.82)
		dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(dim)
		var col := Pal.vbox(18)
		col.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		col.grow_horizontal = Control.GROW_DIRECTION_BOTH
		col.grow_vertical = Control.GROW_DIRECTION_BOTH
		col.custom_minimum_size = Vector2(760, 0)
		col.alignment = BoxContainer.ALIGNMENT_CENTER
		col.mouse_filter = Control.MOUSE_FILTER_IGNORE   # taps fall through to the root
		add_child(col)
		# full pixel-art portrait — rectangular mugshot, NOT cropped to a circle
		var frame := PanelContainer.new()
		frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
		frame.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		frame.add_theme_stylebox_override("panel", Pal.sb(Color("#0C0E10"), 10, Pal.SODIUM, 2, 0))
		var tr := TextureRect.new()
		tr.texture = Pal.cast_portrait(pick.get("character", "nads"))
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		tr.custom_minimum_size = Vector2(300, 375)
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		frame.add_child(tr)
		col.add_child(frame)
		var nm := Pal.heading(String(pick.get("name", "")), 40, Pal.SODIUM)
		nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nm.mouse_filter = Control.MOUSE_FILTER_IGNORE
		col.add_child(nm)
		_label = Pal.text(_lines[0] if _lines.size() > 0 else "", 30, Pal.TEXT, 500, true)
		_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_label.custom_minimum_size = Vector2(700, 120)
		_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		col.add_child(_label)
		_hint = Pal.label("TAP TO CONTINUE", 18, Pal.MUTED, 500)
		_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
		col.add_child(_hint)
		_refresh_hint()
		Audio.ui()

	func _on_input(e: InputEvent) -> void:
		if (e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT) \
				or (e is InputEventScreenTouch and e.pressed):
			accept_event()
			_advance()

	func _refresh_hint() -> void:
		if _hint:
			_hint.text = "CONTINUE  ▸" if _i >= _lines.size() - 1 else "TAP TO CONTINUE"

	func _advance() -> void:
		if _i < _lines.size() - 1:
			_i += 1
			_label.text = _lines[_i]
			_refresh_hint()
			Audio.ui()
		else:
			_finish()

	func _finish() -> void:
		if _grants == "free_street_tip":
			Game.s["_free_tip"] = true
		var cb := _done
		queue_free()
		if cb.is_valid(): cb.call()

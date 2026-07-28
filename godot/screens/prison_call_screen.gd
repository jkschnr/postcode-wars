class_name PrisonCallScreen
extends Control
## Prison call (design screen 16). A real credit clock in mm:ss; every topic
## costs minutes; the transcript sits above the topics; the line cuts at zero.

var who := "kayo"
var _def: Dictionary
var _timer_lbl: Label
var _bar: Control
var _transcript: Label
var _topics_box: VBoxContainer
var _cut := false

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_def = Config.story_calls.get(who, {})
	var scroll := Pal.scroll()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(scroll)
	var v := Pal.vbox(18)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(v)

	# top row: back + status
	var top := Pal.hbox(10)
	var back := Pal.btn("← MESSAGES", "secondary", 64)
	back.custom_minimum_size = Vector2(240, 64)
	back.add_theme_font_override("font", Pal.mono_font(500))
	back.add_theme_font_size_override("font_size", 20)
	back.pressed.connect(func(): App.I.show_screen("messages"))
	top.add_child(back)
	top.add_child(Pal.spacer())
	top.add_child(Pal.label("● CALL CONNECTED · MONITORED", 20, Pal.POLICE.lightened(0.2), 500))
	v.add_child(top)

	# header: portrait, name, relation
	var port := Pal.portrait_frame(Pal.cast_portrait(str(_def.get("portrait", "kayo"))), 220, Pal.POLICE)
	port.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(port)
	var nm := Pal.heading(String(_def.get("name", "Kayo")).to_upper(), 56, Pal.TEXT)
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(nm)
	var rel := Pal.label("%s · %s" % [_def.get("rel", ""), _def.get("place", "")], 22, Pal.POLICE.lightened(0.2), 500)
	rel.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(rel)

	# credit clock
	var creditcap := Pal.label("CREDIT REMAINING", 22, Pal.TEXT2, 500)
	creditcap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(creditcap)
	_timer_lbl = Pal.heading(_fmt(Game.s.get("call_credit", 900)), 96, Pal.TEXT)
	_timer_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_timer_lbl)
	_bar = Pal.bar(float(Game.s.get("call_credit", 900)) / 900.0, Pal.POLICE.lightened(0.2), 12)
	v.add_child(_bar)
	var note := Pal.label("EVERY TOPIC COSTS MINUTES. THE LINE CUTS AT ZERO.", 20, Pal.MUTED, 400)
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(note)

	# transcript
	var tp := Pal.panel()
	var tm := MarginContainer.new()
	tm.add_theme_constant_override("margin_left", 24); tm.add_theme_constant_override("margin_right", 24)
	tm.add_theme_constant_override("margin_top", 20); tm.add_theme_constant_override("margin_bottom", 20)
	var tv := Pal.vbox(8)
	tv.add_child(Pal.label(String(_def.get("name", "Kayo")).to_upper(), 20, Pal.POLICE.lightened(0.2), 500))
	_transcript = Pal.text("“" + str(_def.get("greeting", "")) + "”", 28, Pal.TEXT, 500, true)
	_transcript.custom_minimum_size = Vector2(960, 0)
	tv.add_child(_transcript)
	tm.add_child(tv); tp.add_child(tm)
	v.add_child(tp)

	# topics
	v.add_child(Pal.sechead("WHAT DO YOU SPEND IT ON"))
	_topics_box = Pal.vbox(12)
	v.add_child(_topics_box)
	_rebuild_topics()

func _rebuild_topics() -> void:
	for c in _topics_box.get_children(): c.queue_free()
	var credit: int = int(Game.s.get("call_credit", 900))
	for t in _def.get("topics", []):
		var used: bool = bool(t.get("once", false)) and Game.s.get("call_topics_used", {}).get(t.id, false)
		var cost := int(t.cost)
		var afford := credit >= cost and not _cut and not used
		_topics_box.add_child(_topic_row(t, cost, afford, used))

func _topic_row(t: Dictionary, cost: int, afford: bool, used: bool) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(0, 100)
	b.focus_mode = Control.FOCUS_NONE
	b.disabled = not afford
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.add_theme_stylebox_override("normal", Pal.sb(Pal.RAISED, 14, Pal.HAIRLINE, 1, 0))
	b.add_theme_stylebox_override("hover", Pal.sb(Pal.RAISED.lightened(0.06), 14, Pal.POLICE, 1, 0))
	b.add_theme_stylebox_override("pressed", Pal.sb(Pal.RAISED, 14, Pal.HAIRLINE, 1, 0))
	b.add_theme_stylebox_override("disabled", Pal.sb(Color("#191B1F"), 14, Pal.RAISED, 1, 0))
	var m := MarginContainer.new()
	m.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	m.add_theme_constant_override("margin_left", 24); m.add_theme_constant_override("margin_right", 24)
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var row := Pal.hbox(12)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var lbl := Pal.text(("✓ " + str(t.label)) if used else str(t.label), 28, Pal.MUTED if (not afford) else Pal.TEXT, 500)
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(lbl)
	var ccol := Pal.CLEAN if cost <= 60 else (Pal.SODIUM if cost <= 120 else (Pal.DIRTY if cost <= 180 else Pal.DANGER_RED))
	row.add_child(Pal.label("−" + _fmt(cost), 24, ccol, 500))
	m.add_child(row); b.add_child(m)
	if afford:
		b.pressed.connect(func(): _spend(t, cost))
	return b

## A topic may carry `act_lines` — one line per story act — so the same question
## gets a different answer depending on where you are (§WO1-T5). Falls back to `line`.
func _line_for(t: Dictionary) -> String:
	var al = t.get("act_lines", null)
	if al is Array and al.size() > 0:
		return str(al[clampi(Story.act(), 0, al.size() - 1)])
	return str(t.get("line", ""))

func _spend(t: Dictionary, cost: int) -> void:
	Audio.ui()
	var credit: int = max(0, int(Game.s.get("call_credit", 900)) - cost)
	Game.s.call_credit = credit
	Game.s["_calls_made"] = int(Game.s.get("_calls_made", 0)) + 1   # objective: calls_made
	if bool(t.get("once", false)):
		Game.s.call_topics_used[t.id] = true
	# effects (trust, story flags — e.g. a call that hands you a lead or a warning)
	var eff: Dictionary = t.get("effects", {})
	for k in eff.get("trust", {}).keys():
		Cast.adjust_trust(str(k), int(eff.trust[k]))
	for f in eff.get("flags", []):
		Story.set_flag(str(f))
	Game.persist()
	# update transcript + clock (act_lines let a topic react to where you are in the story)
	_transcript.text = "“" + _line_for(t) + "”"
	_timer_lbl.text = _fmt(credit)
	_bar.queue_free()
	_bar = Pal.bar(float(credit) / 900.0, Pal.POLICE.lightened(0.2), 12)
	# re-insert bar under the timer (index 6ish) — simplest: rebuild topics + set colour
	if credit <= 0:
		_cut = true
		_timer_lbl.text = "00:00"
		_timer_lbl.add_theme_color_override("font_color", Pal.DANGER_RED)
		_transcript.text = "— The line cuts out. A recorded voice thanks you for using the service."
	_rebuild_topics()

func _fmt(secs: int) -> String:
	return "%02d:%02d" % [secs / 60, secs % 60]

func refresh() -> void:
	pass

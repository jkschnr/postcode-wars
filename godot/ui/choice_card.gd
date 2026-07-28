class_name ChoiceCard
extends Control
## Dialogue & decisions (design screen 06). Scrim over the street · a panel with
## portrait, speaker, place, typed dialogue, and 2–4 option rows (label left,
## cost/check tag right) · a state rail. Outcome resolves through the gateway.

var enc: Dictionary
var on_done: Callable
var _wrap: CenterContainer
var _pending_levels: Array = []

func setup(e: Dictionary, cb: Callable) -> void:
	enc = e
	on_done = cb

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.03, 0.04, 0.80)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	_wrap = CenterContainer.new()
	_wrap.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_wrap)
	_build_question()

func _card() -> VBoxContainer:
	for c in _wrap.get_children(): c.queue_free()
	var p := Pal.panel()
	p.custom_minimum_size = Vector2(1000, 0)
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 40); m.add_theme_constant_override("margin_right", 40)
	m.add_theme_constant_override("margin_top", 40); m.add_theme_constant_override("margin_bottom", 40)
	var v := Pal.vbox(24)
	m.add_child(v); p.add_child(m)
	_wrap.add_child(p)
	p.pivot_offset = Vector2(500, 320)
	p.scale = Vector2(0.96, 0.96)
	create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).tween_property(p, "scale", Vector2.ONE, 0.18)
	return v

func _build_question() -> void:
	var v := _card()
	var speaker: String = str(enc.get("speaker", ""))
	# portrait (sodium-outlined rect; empty slot if no art, per design)
	var slot := Pal.portrait_frame(Pal.portrait_for(speaker), 200, Pal.SODIUM)
	slot.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(slot)
	# name + place
	var nm := Pal.heading(speaker.to_upper(), 48, Pal.TEXT)
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(nm)
	var place := str(enc.get("place", enc.get("where", "")))
	var loc := "%s · %s" % [place, str(enc.get("city", "London")).to_upper()] if place != "" else str(enc.get("city", "LONDON")).to_upper()
	var pl := Pal.label(loc, 22, Pal.SODIUM, 500)
	pl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(pl)
	# dialogue
	var line := Pal.text(str(enc.get("text", "")), 30, Pal.TEXT, 500, true)
	line.custom_minimum_size = Vector2(920, 0)
	line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(line)
	v.add_child(Pal.hsep(Pal.RAISED))
	# options
	var has_check := false
	var has_cost := false
	for opt in enc.get("options", []):
		var o: Dictionary = opt
		if o.has("check"): has_check = true
		if o.has("cost") or o.has("req_dirty") or o.has("req_clean"): has_cost = true
		v.add_child(_option_row(o))
	# state rail
	var rail := Pal.hbox(16)
	rail.alignment = BoxContainer.ALIGNMENT_CENTER
	rail.add_child(Pal.label("CONVERSATION", 20, Pal.SODIUM if not (has_check or has_cost) else Pal.MUTED, 500))
	rail.add_child(Pal.label("·", 20, Pal.MUTED))
	rail.add_child(Pal.label("STAT CHECK", 20, Pal.SODIUM if has_check else Pal.MUTED, 500))
	rail.add_child(Pal.label("·", 20, Pal.MUTED))
	rail.add_child(Pal.label("COSTLY", 20, Pal.SODIUM if has_cost else Pal.MUTED, 500))
	v.add_child(rail)

func _option_row(opt: Dictionary) -> Button:
	var enabled: bool = ServerGateway.enc_option_enabled(opt)
	var b := Button.new()
	b.custom_minimum_size = Vector2(0, 96)
	b.focus_mode = Control.FOCUS_NONE
	b.disabled = not enabled
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.add_theme_stylebox_override("normal", Pal.sb(Pal.RAISED, 14, Pal.HAIRLINE, 1, 0))
	b.add_theme_stylebox_override("hover", Pal.sb(Pal.RAISED.lightened(0.06), 14, Pal.SODIUM, 1, 0))
	b.add_theme_stylebox_override("pressed", Pal.sb(Pal.RAISED, 14, Pal.HAIRLINE, 1, 0))
	b.add_theme_stylebox_override("disabled", Pal.sb(Color("#191B1F"), 14, Pal.RAISED, 1, 0))
	var m := MarginContainer.new()
	m.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	m.add_theme_constant_override("margin_left", 24); m.add_theme_constant_override("margin_right", 24)
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var row := Pal.hbox(12)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var lbl := Pal.text(str(opt.get("label", "…")), 28, Pal.TEXT if enabled else Pal.MUTED, 500, true)
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(lbl)
	var tag := _cost_tag(opt)
	if tag != null:
		tag.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(tag)
	m.add_child(row); b.add_child(m)
	if enabled:
		b.pressed.connect(func(): _choose(opt))
	return b

func _cost_tag(opt: Dictionary) -> Label:
	if opt.has("check"):
		return Pal.label("%s %d" % [str(opt.check.get("stat", "nv")).left(2).to_upper(), int(opt.check.get("dc", 10))], 22, Pal.NERVE, 500)
	if opt.has("req_dirty"):
		return Pal.label(Pal.money(int(opt.req_dirty)), 22, Pal.DIRTY, 500)
	if opt.has("req_clean"):
		return Pal.label(Pal.money(int(opt.req_clean)), 22, Pal.CLEAN, 500)
	if opt.has("hint"):
		return Pal.label(str(opt.hint).to_upper(), 20, Pal.TEXT2, 400)
	return Pal.label("FREE", 20, Pal.MUTED, 400)

func _choose(opt: Dictionary) -> void:
	Audio.ui()
	var res: Dictionary = await ServerGateway.resolve_encounter(opt)
	_build_result(res)

func _build_result(res: Dictionary) -> void:
	var v := _card()
	var word := "SORTED"
	var wc := Pal.SODIUM
	if res.get("checked", false):
		word = "PATTERNED" if res.ok else "GONE WRONG"
		wc = Pal.CLEAN if res.ok else Pal.DANGER_RED
	if res.get("ok", false): Audio.reveal()
	else: Audio.error()
	var stinger := Pal.heading(word, 80, wc)
	stinger.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(stinger)
	if str(res.get("text", "")) != "":
		var t := Pal.text(str(res.text), 28, Pal.TEXT, 400, true)
		t.custom_minimum_size = Vector2(920, 0)
		t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(t)
	var d: Dictionary = res.get("deltas", {})
	var chips := Pal.hbox(12)
	chips.alignment = BoxContainer.ALIGNMENT_CENTER
	_chip(chips, "dirty", int(d.get("dirty", 0)), Pal.DIRTY)
	_chip(chips, "clean", int(d.get("clean", 0)), Pal.CLEAN)
	_chip(chips, "XP", int(d.get("xp", 0)), Pal.SODIUM)
	_chip(chips, "heat", int(d.get("heat", 0)), Pal.DANGER_RED)
	if chips.get_child_count() > 0:
		v.add_child(chips)
	var carry := Pal.btn("CARRY ON", "hivis", 96)
	carry.pressed.connect(_close)
	v.add_child(carry)
	if d.has("leveled") and (d.leveled as Array).size() > 0:
		_pending_levels = d.leveled

func _chip(row: HBoxContainer, nm: String, val: int, col: Color) -> void:
	if val == 0: return
	var good := (val > 0) if nm != "heat" else (val < 0)
	var c := col if good else (Pal.DANGER_RED if nm != "heat" else Pal.DANGER_RED)
	row.add_child(Pal.chip("%s%d %s" % ["+" if val > 0 else "", val, nm.to_upper()], c, Color(c, 0.5)))

func _close() -> void:
	queue_free()
	App.I.play_levelups(_pending_levels, on_done)

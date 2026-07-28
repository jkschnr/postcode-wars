class_name CollectOverlay
extends Control
## Collect screen (guide Step 7) — everything claimable in one place, three rewards
## in the player's hand within seconds. Appears after the greeter when there's
## anything waiting; skipped entirely when there isn't.

var _done: Callable
var _list: VBoxContainer
var _rows: Array = []

## Returns true if there is anything to collect right now.
static func has_any() -> bool:
	return Game.gym_ready() > 0 or Game.wash_ready() > 0 \
		or Game.trapline_take() > 0 or Game.firm_cut_ready() \
		or Shadow.pending_reports().size() > 0

func setup(on_done: Callable) -> void:
	_done = on_done

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new(); dim.color = Color(0, 0, 0, 0.82)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	panel.custom_minimum_size = Vector2(880, 0)
	panel.add_theme_stylebox_override("panel", Pal.sb(Color(Pal.RAISED, 0.98), 20, Pal.HAIRLINE, 1, 0))
	add_child(panel)
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 34); m.add_theme_constant_override("margin_right", 34)
	m.add_theme_constant_override("margin_top", 30); m.add_theme_constant_override("margin_bottom", 30)
	panel.add_child(m)
	var v := Pal.vbox(18)
	v.add_child(Pal.label("WHILE YOU WERE OUT", 20, Pal.SODIUM, 500))
	var head := Pal.heading("COLLECT", 56, Pal.TEXT)
	v.add_child(head)
	_list = Pal.vbox(12)
	v.add_child(_list)
	_build_rows()
	var all := Pal.btn("COLLECT ALL", "hivis", 100)
	all.pressed.connect(_collect_all)
	v.add_child(all)
	m.add_child(v)
	# slide/fade in
	panel.modulate.a = 0.0
	create_tween().tween_property(panel, "modulate:a", 1.0, 0.18)
	Audio.ui()

func _sources() -> Array:
	var out: Array = []
	if Game.gym_ready() > 0:
		out.append({"id": "gym", "col": Pal.SODIUM, "title": "TRAINING DONE",
			"desc": "%d session%s — stat gains ready" % [Game.gym_ready(), "" if Game.gym_ready() == 1 else "s"]})
	if Game.wash_ready() > 0:
		out.append({"id": "wash", "col": Pal.CLEAN, "title": "MONEY'S CLEAN",
			"desc": "Laundered batch ready to bank"})
	var tk := Game.trapline_take()
	if tk > 0:
		out.append({"id": "trapline", "col": Pal.DIRTY, "title": "POSTCODE Ps",
			"desc": "The line's paid out %s dirty" % Pal.money(tk)})
	if Game.firm_cut_ready():
		out.append({"id": "firm", "col": Pal.CLEAN, "title": "FIRM CUT",
			"desc": "Your weekly cut is ready"})
	# defence reports — someone came for your shadow while you were away (Step 31)
	var reps := Shadow.pending_reports()
	for i in reps.size():
		var r: Dictionary = reps[i]
		var col: Color = Pal.CLEAN if r.get("result", "") == "won" else (Pal.DANGER_RED if r.get("result", "") == "lost" else Pal.SODIUM)
		out.append({"id": "report:%d" % i, "col": col,
			"title": "SOMEONE TRIED YOU", "desc": str(r.get("line", "")), "claim": "SEEN"})
	return out

func _build_rows() -> void:
	for r in _rows: if is_instance_valid(r): r.queue_free()
	_rows.clear()
	for src in _sources():
		var card := PanelContainer.new()
		card.add_theme_stylebox_override("panel", Pal.sb(Color("#0E1013", 0.9), 14, src.col, 1, 0))
		var cm := MarginContainer.new()
		cm.add_theme_constant_override("margin_left", 18); cm.add_theme_constant_override("margin_right", 14)
		cm.add_theme_constant_override("margin_top", 12); cm.add_theme_constant_override("margin_bottom", 12)
		var row := Pal.hbox(14)
		var dot := ColorRect.new(); dot.color = src.col; dot.custom_minimum_size = Vector2(12, 12)
		dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(dot)
		var col := Pal.vbox(2); col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col.add_child(Pal.heading(src.title, 28, Pal.TEXT))
		col.add_child(Pal.label(src.desc, 18, Pal.TEXT2, 400))
		row.add_child(col)
		var claim := Pal.btn(str(src.get("claim", "CLAIM")), "secondary", 72)
		claim.custom_minimum_size = Vector2(160, 72)
		claim.pressed.connect(func(): _claim(src.id))
		row.add_child(claim)
		cm.add_child(row); card.add_child(cm)
		_list.add_child(card)
		_rows.append(card)
	if _sources().is_empty():
		_finish()

func _claim(id: String) -> void:
	if id.begins_with("report:"):
		# acknowledging a defence report — no reward, just clears it (Step 31)
		Audio.ui()
		var idx := int(id.split(":")[1])
		var reps: Array = Shadow.pending_reports()
		if idx >= 0 and idx < reps.size():
			reps.remove_at(idx)
			if Game.s.has("shadow"): Game.s.shadow.pending_reports = reps
			Game.persist()
		_build_rows()
		return
	Audio.coin()
	match id:
		"gym":
			var g := Game.gym_collect()
			var parts := []
			for k in g.keys(): parts.append("+%d %s" % [int(g[k]), String(k).substr(0, 3).to_upper()])
			Game.toast.emit("Trained: %s" % ", ".join(parts), Pal.SODIUM)
		"wash":
			var got := Game.wash_collect()
			Game.toast.emit("Banked %s clean" % Pal.money(got), Pal.CLEAN)
		"trapline":
			var got := Game.trapline_collect()
			Game.toast.emit("Lifted %s off the line" % Pal.money(got), Pal.DIRTY)
		"firm":
			var got := Game.collect_firm_cut()
			Game.toast.emit("Firm cut: %s clean" % Pal.money(got), Pal.CLEAN)
	Game.changed.emit()
	_build_rows()

func _collect_all() -> void:
	for src in _sources():
		if str(src.id).begins_with("report:"): continue   # cleared in one go below
		_claim(src.id)
	if Shadow.pending_reports().size() > 0:
		Shadow.clear_reports()
	_finish()

func _finish() -> void:
	var cb := _done
	queue_free()
	if cb.is_valid(): cb.call()

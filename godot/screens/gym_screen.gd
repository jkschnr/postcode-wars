class_name GymScreen
extends Control
## The Gym (design screen 12): street band · 2×2 stat select grid · session
## intensity picker · queue with timer rings · collect. (Intensities are visual
## for Part 1; the training call is wired in Part 2.)

const STATS := [
	{"id": "strength", "label": "STRENGTH", "sub": "CARRY MORE, TAKE LESS", "train": true},
	{"id": "toughness", "label": "TOUGHNESS", "sub": "HOLD IT TOGETHER LONGER", "train": true},
	{"id": "speed", "label": "SPEED", "sub": "GET OFF THE ROAD FASTER", "train": true},
	{"id": "slickness", "label": "SLICKNESS", "sub": "LEARNED ON ROAD, NOT HERE", "train": false},
]
const CAP := 50
var _sel := "strength"
var _body: VBoxContainer
var _acc := 0.0

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var scroll := Pal.scroll()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(scroll)
	_body = Pal.vbox(18)
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_body)
	_rebuild()

func _process(dt: float) -> void:
	_acc += dt
	if _acc > 1.0:
		_acc = 0.0
		if Game.s.gym_queue.size() > 0 or Game.gym_ready() > 0:
			_rebuild()

func _rebuild() -> void:
	for c in _body.get_children(): c.queue_free()
	_body.add_child(_band())
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 16); grid.add_theme_constant_override("v_separation", 16)
	for st in STATS:
		grid.add_child(_stat_tile(st))
	_body.add_child(grid)
	_body.add_child(_session_panel())
	var sec := Pal.sechead("IN THE QUEUE")
	sec.add_child(Pal.label("%d OF 3 SLOTS" % Game.s.gym_queue.size(), 20, Pal.MUTED, 400))
	_body.add_child(sec)
	for q in Game.s.gym_queue:
		_body.add_child(_queue_row(q))
	if Game.gym_ready() > 0:
		var cb := Pal.btn("COLLECT GAINS", "hivis", 108)
		cb.pressed.connect(_collect)
		_body.add_child(cb)

func _band() -> Control:
	var band := PanelContainer.new()
	band.custom_minimum_size = Vector2(0, 320); band.clip_contents = true
	band.add_theme_stylebox_override("panel", Pal.sb(Pal.INSET, 12, Pal.RAISED, 1, 0))
	var bg := TextureRect.new()
	bg.texture = Pal.city_tex(Game.s.city)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	bg.modulate = Color(0.8, 0.75, 0.6); band.add_child(bg)
	var shade := ColorRect.new(); shade.color = Color(0.07, 0.08, 0.09, 0.5)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); band.add_child(shade)
	var wm := Pal.heading("IRON", 200, Color(Pal.TEXT, 0.06))
	wm.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT); wm.position = Vector2(-360, -130); band.add_child(wm)
	var back := Pal.btn("← CITY", "secondary", 60)
	back.add_theme_font_override("font", Pal.mono_font(500)); back.add_theme_font_size_override("font_size", 20)
	back.custom_minimum_size = Vector2(180, 60); back.position = Vector2(24, 20)
	back.pressed.connect(func(): App.I.show_screen("city")); band.add_child(back)
	var m := MarginContainer.new()
	m.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	m.add_theme_constant_override("margin_left", 32); m.add_theme_constant_override("margin_bottom", 24)
	var col := Pal.vbox(2); col.alignment = BoxContainer.ALIGNMENT_END
	col.add_child(Pal.label("PICK ONE, QUEUE THE REST", 22, Pal.SODIUM, 500))
	col.add_child(Pal.heading("THE GYM", 64, Pal.TEXT))
	col.add_child(Pal.label("BETHNAL GREEN IRON · OPEN 24H · NO MIRRORS", 20, Pal.TEXT2, 400))
	m.add_child(col); band.add_child(m)
	return band

func _stat_tile(st: Dictionary) -> Control:
	var val := int(Game.s.stats.get(st.id, 5))
	var maxed := val >= CAP
	var sel: bool = st.id == _sel and bool(st.train)
	var b := Button.new()
	b.custom_minimum_size = Vector2(0, 180)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.focus_mode = Control.FOCUS_NONE
	b.disabled = not st.train
	var bc := Pal.SODIUM if sel else Pal.RAISED
	var bg := Color(Pal.SODIUM, 0.06) if sel else Pal.PANEL
	b.add_theme_stylebox_override("normal", Pal.sb(bg, 16, bc, 2 if sel else 1, 0))
	b.add_theme_stylebox_override("hover", Pal.sb(bg.lightened(0.05), 16, Pal.SODIUM, 2, 0))
	b.add_theme_stylebox_override("pressed", Pal.sb(bg, 16, bc, 2, 0))
	b.add_theme_stylebox_override("disabled", Pal.sb(Pal.PANEL, 16, Pal.RAISED, 1, 0))
	var m := MarginContainer.new()
	m.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	m.add_theme_constant_override("margin_left", 20); m.add_theme_constant_override("margin_right", 20)
	m.add_theme_constant_override("margin_top", 16); m.add_theme_constant_override("margin_bottom", 16)
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var v := Pal.vbox(8); v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var top := Pal.hbox(10); top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var accent := Pal.SODIUM if sel else (Pal.RARITY.iconic if maxed else Pal.TEXT2)
	top.add_child(Pal.label(st.label, 22, accent, 500))
	top.add_child(Pal.spacer())
	top.add_child(Pal.heading(str(val), 44, Pal.RARITY.iconic if maxed else Pal.TEXT))
	v.add_child(top)
	v.add_child(Pal.bar(float(val) / float(CAP), Pal.RARITY.iconic if maxed else Pal.SODIUM, 12))
	v.add_child(Pal.label(("MAXED — NOTHING LEFT TO LEARN" if maxed else st.sub), 18, Pal.MUTED, 400))
	m.add_child(v); b.add_child(m)
	if st.train and not maxed:
		b.pressed.connect(func(): _sel = st.id; _rebuild())
	return b

func _session_panel() -> Control:
	var p := Pal.panel()
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 20); m.add_theme_constant_override("margin_right", 20)
	m.add_theme_constant_override("margin_top", 16); m.add_theme_constant_override("margin_bottom", 16)
	var v := Pal.vbox(14)
	var top := Pal.hbox(10)
	top.add_child(Pal.label("SESSION", 22, Pal.SODIUM, 500))
	top.add_child(Pal.spacer())
	top.add_child(Pal.label(_sel.to_upper(), 20, Pal.SODIUM, 500))
	v.add_child(top)
	var row := Pal.hbox(12)
	row.add_child(_intensity("LIGHT", "EN 10 · 30M · +1", false))
	row.add_child(_intensity("PROPER", "EN 24 · 2H · +3", true))
	row.add_child(_intensity("TILL IT HURTS", "EN 48 · 6H · +7", false))
	v.add_child(row)
	v.add_child(Pal.label("TRAINING RUNS WHILE THE APP IS SHUT. ENERGY IS SPENT UP FRONT.", 18, Pal.MUTED, 400))
	m.add_child(v); p.add_child(m)
	return p

func _intensity(name: String, detail: String, primary: bool) -> Control:
	var b := Button.new()
	b.custom_minimum_size = Vector2(0, 120)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.focus_mode = Control.FOCUS_NONE
	var bc := Pal.SODIUM if primary else Pal.RAISED
	b.add_theme_stylebox_override("normal", Pal.sb(Pal.INSET, 12, bc, 1, 0))
	b.add_theme_stylebox_override("hover", Pal.sb(Pal.INSET.lightened(0.05), 12, Pal.SODIUM, 1, 0))
	b.add_theme_stylebox_override("pressed", Pal.sb(Pal.INSET, 12, bc, 1, 0))
	var m := MarginContainer.new()
	m.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var v := Pal.vbox(6); v.alignment = BoxContainer.ALIGNMENT_CENTER; v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var t := Pal.heading(name, 26, Pal.SODIUM if primary else Pal.TEXT); t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var d := Pal.label(detail, 16, Pal.MUTED, 400); d.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t); v.add_child(d)
	m.add_child(v); b.add_child(m)
	b.pressed.connect(func(): _train(_sel))
	return b

func _queue_row(q: Dictionary) -> Control:
	var left: float = float(q.ends_at) - Game.now()
	var ready := left <= 0
	var p := Pal.panel()
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 20); m.add_theme_constant_override("margin_right", 20)
	m.add_theme_constant_override("margin_top", 16); m.add_theme_constant_override("margin_bottom", 16)
	var row := Pal.hbox(16)
	var ring := _Ring.new()
	ring.pct = clampf(1.0 - left / 120.0, 0.0, 1.0); ring.col = Pal.HIVIS if ready else Pal.SODIUM
	ring.custom_minimum_size = Vector2(56, 56); ring.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(ring)
	var tv := Pal.vbox(2); tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tv.add_child(Pal.label("SESSION", 18, Pal.MUTED, 500))
	tv.add_child(Pal.heading("%s +%d" % [String(q.stat).to_upper(), int(q.gain)], 30, Pal.TEXT))
	row.add_child(tv)
	row.add_child(Pal.heading("READY" if ready else Game.fmt_time(left), 30, Pal.HIVIS if ready else Pal.TEXT))
	m.add_child(row); p.add_child(m)
	return p

func _train(stat: String) -> void:
	var res: Dictionary = await ServerGateway.gym_queue(stat)
	if res.ok:
		Audio.ui(); Game.toast.emit("In training: %s" % stat.capitalize(), Pal.SODIUM)
	else:
		Audio.error(); Game.toast.emit(res.get("reason", "Can't"), Pal.DANGER_RED)
	_rebuild()

func _collect() -> void:
	var res: Dictionary = await ServerGateway.gym_collect()
	Audio.level_up()
	var parts := []
	for k in res.gains.keys():
		parts.append("+%d %s" % [res.gains[k], str(k).capitalize()])
	Game.toast.emit("Gains: " + ", ".join(parts), Pal.CLEAN)
	_rebuild()

func refresh() -> void:
	_rebuild()

class _Ring extends Control:
	var pct := 0.0
	var col := Color("#FFA94D")
	func _draw() -> void:
		var c := size / 2.0
		var r: float = min(size.x, size.y) / 2.0 - 3.0
		draw_arc(c, r, 0, TAU, 40, Pal.RAISED, 4.0, true)
		if pct > 0.0:
			draw_arc(c, r, -PI / 2, -PI / 2 + TAU * pct, 40, col, 4.0, true)

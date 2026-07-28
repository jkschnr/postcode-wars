class_name DailyPanel
extends Control
## Daily Graft — three rotating objectives with rewards + a daily streak.
## The classic return-trigger: there's always a bar near full.

var _wrap: CenterContainer

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	Game.ensure_daily()
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.03, 0.04, 0.82)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.gui_input.connect(_on_dim_input)
	add_child(dim)
	_wrap = CenterContainer.new()
	_wrap.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE  # let taps fall through to dim
	add_child(_wrap)
	_build()

func _on_dim_input(e: InputEvent) -> void:
	if (e is InputEventMouseButton and e.pressed) or (e is InputEventScreenTouch and e.pressed):
		_close()

func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and e.keycode == KEY_ESCAPE:
		_close()

func _close() -> void:
	Audio.ui()
	queue_free()

func _build() -> void:
	for c in _wrap.get_children(): c.queue_free()
	var p := Pal.paper_panel()
	p.custom_minimum_size = Vector2(800, 0)
	var v := Pal.vbox(14)
	p.add_child(v)
	_wrap.add_child(p)

	var hdr := Pal.hbox(8)
	hdr.add_child(Pal.ptext("DAILY GRAFT", 30, 700))
	hdr.add_child(Pal.spacer())
	hdr.add_child(Pal.ptext("streak %d" % int(Game.s.daily.get("streak", 0)), 20, 700))
	v.add_child(hdr)
	v.add_child(Pal.hsep(Color(Pal.PAPER_INK, 0.35)))

	var tasks: Array = Game.s.daily.get("tasks", [])
	for i in range(tasks.size()):
		v.add_child(_task_row(tasks[i], i))

	v.add_child(Pal.hsep(Color(Pal.PAPER_INK, 0.35)))
	var done := Pal.paper_button("CLOSE")
	done.pressed.connect(_close)
	v.add_child(done)

func _task_row(t: Dictionary, idx: int) -> Control:
	var claimed: bool = t.get("claimed", false)
	var ready: bool = Game.daily_ready(t)
	var wrap := PanelContainer.new()
	var s := Pal.sb(Color(Pal.PAPER_INK, 0.05), 6, Color(Pal.PAPER_INK, 0.35), 1, 12)
	wrap.add_theme_stylebox_override("panel", s)
	var row := Pal.hbox(14)
	var col := Pal.vbox(6)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_child(Pal.ptext(t.get("desc", "Task"), 22, 700))
	# progress bar
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 16)
	bar.max_value = float(t.target)
	bar.value = float(t.progress)
	var bg := Pal.sb(Color(Pal.PAPER_INK, 0.18), 8, Color(0,0,0,0), 0, 0)
	var fg := Pal.sb(Pal.MONEY.darkened(0.1) if not claimed else Color(Pal.PAPER_INK, 0.3), 8, Color(0,0,0,0), 0, 0)
	bar.add_theme_stylebox_override("background", bg)
	bar.add_theme_stylebox_override("fill", fg)
	col.add_child(bar)
	col.add_child(Pal.text("%d / %d      reward: +%s clean · +%d XP" % [int(t.progress), int(t.target), Pal.money(int(t.rc)).substr(1), int(t.rx)], 15, Pal.PAPER_INK, 400))
	row.add_child(col)
	# claim button / state
	var btn := Pal.paper_button("DONE" if claimed else "CLAIM", 90)
	btn.custom_minimum_size = Vector2(180, 90)
	btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	btn.disabled = claimed or not ready
	if not claimed and ready:
		btn.pressed.connect(func(): _claim(idx))
	row.add_child(btn)
	wrap.add_child(row)
	return wrap

func _claim(idx: int) -> void:
	var res: Dictionary = Game.daily_claim(idx)
	if res.is_empty(): return
	Audio.level_up()
	Game.toast.emit("Graft claimed: +%s clean · +%d XP" % [Pal.money(int(res.clean)), int(res.xp)], Pal.MONEY)
	_build()
	App.I.play_levelups(res.get("leveled", []), Callable())

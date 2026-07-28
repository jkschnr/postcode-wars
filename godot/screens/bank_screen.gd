class_name BankScreen
extends Control
## Bung (design screen 10): street band · dirty/clean panels · wash slider ·
## "in the wash" slots with timer rings.

var _body: VBoxContainer
var _acc := 0.0
var _front := ""
var _amount := 4000
var _amt_lbl: Label
var _out_lbl: Label

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_front = Economy.FRONTS.keys()[0]
	_amount = clampi(4000, 500, max(500, Game.dirty()))
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
		if Game.s.wash.size() > 0 or Game.wash_ready() > 0:
			_rebuild()

func _rebuild() -> void:
	for c in _body.get_children(): c.queue_free()
	_body.add_child(_band())
	# balances
	var row := Pal.hbox(16)
	row.add_child(_balance("DIRTY", Game.dirty(), Pal.DIRTY, "SEIZABLE · CAN'T BE SPENT ON GEAR", "RAID RISK %d/4 AT THIS BALANCE" % clampi(Game.dirty() / 4000 + 1, 1, 4), Pal.DANGER_RED))
	row.add_child(_balance("CLEAN", Game.clean(), Pal.CLEAN, "SAFE · SPENDABLE · COUNTS TOWARD DEBT", ("£%s OWED THIS WEEK" % Pal.money(Game.debt_left()).trim_prefix("£")) if Game.debt_active() else "NOTHING OWED THIS WEEK", Pal.CLEAN))
	_body.add_child(row)
	_body.add_child(_wash_panel())
	# in the wash
	var sec := Pal.sechead("IN THE WASH")
	sec.add_child(Pal.label("%d OF 4 SLOTS" % Game.s.wash.size(), 20, Pal.MUTED, 400))
	_body.add_child(sec)
	if Game.wash_ready() > 0:
		var cb := Pal.btn("COLLECT CLEAN — %d READY" % Game.wash_ready(), "hivis", 96)
		cb.pressed.connect(_collect)
		_body.add_child(cb)
	for w in Game.s.wash:
		_body.add_child(_wash_slot(w))

func _band() -> Control:
	var band := PanelContainer.new()
	band.custom_minimum_size = Vector2(0, 320)
	band.clip_contents = true
	band.add_theme_stylebox_override("panel", Pal.sb(Pal.INSET, 12, Pal.RAISED, 1, 0))
	var bg := TextureRect.new()
	bg.texture = Pal.city_tex(Game.s.city)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	bg.modulate = Color(0.8, 0.75, 0.6)
	band.add_child(bg)
	var shade := ColorRect.new(); shade.color = Color(0.07, 0.08, 0.09, 0.5)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); band.add_child(shade)
	var wm := Pal.heading("BUNG", 200, Color(Pal.TEXT, 0.06))
	wm.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT); wm.position = Vector2(-360, -130)
	band.add_child(wm)
	var back := Pal.btn("← CITY", "secondary", 60)
	back.add_theme_font_override("font", Pal.mono_font(500)); back.add_theme_font_size_override("font_size", 20)
	back.custom_minimum_size = Vector2(180, 60); back.position = Vector2(24, 20)
	back.pressed.connect(func(): App.I.show_screen("city")); band.add_child(back)
	var m := MarginContainer.new()
	m.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	m.add_theme_constant_override("margin_left", 32); m.add_theme_constant_override("margin_bottom", 24)
	var col := Pal.vbox(2); col.alignment = BoxContainer.ALIGNMENT_END
	col.add_child(Pal.label("YOUR MONEY, TWO WAYS", 22, Pal.SODIUM, 500))
	col.add_child(Pal.heading("BUNG", 64, Pal.TEXT))
	col.add_child(Pal.label("MARE STREET BRANCH · OPEN TILL MIDNIGHT", 20, Pal.TEXT2, 400))
	m.add_child(col); band.add_child(m)
	return band

func _balance(cap: String, val: int, col: Color, sub: String, note: String, notecol: Color) -> Control:
	var p := Pal.panel(Color(col, 0.5))
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var st := Pal.sb(Color(col, 0.06), 16, Color(col, 0.5), 1, 0)
	p.add_theme_stylebox_override("panel", st)
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 20); m.add_theme_constant_override("margin_right", 20)
	m.add_theme_constant_override("margin_top", 18); m.add_theme_constant_override("margin_bottom", 18)
	var v := Pal.vbox(8)
	v.add_child(Pal.label(cap, 22, col, 500))
	v.add_child(Pal.heading(Pal.money(val), 56, col))
	v.add_child(Pal.text(sub, 18, Pal.TEXT2, 400, true))
	v.add_child(Pal.bar(clampf(val / 20000.0, 0.05, 1.0), col, 8, 4))
	v.add_child(Pal.label(note, 18, notecol, 500))
	m.add_child(v); p.add_child(m)
	return p

func _wash_panel() -> Control:
	var f: Dictionary = Economy.FRONTS[_front]
	var p := Pal.panel()
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 24); m.add_theme_constant_override("margin_right", 24)
	m.add_theme_constant_override("margin_top", 20); m.add_theme_constant_override("margin_bottom", 20)
	var v := Pal.vbox(14)
	var top := Pal.hbox(10)
	top.add_child(Pal.label("WASH SOME THROUGH", 22, Pal.SODIUM, 500))
	top.add_child(Pal.spacer())
	top.add_child(Pal.label("FEE %d%% · 4H" % int(f.fee * 100), 20, Pal.MUTED, 400))
	v.add_child(top)
	var amtrow := Pal.hbox(14)
	_amt_lbl = Pal.heading(Pal.money(_amount), 64, Pal.DIRTY)
	amtrow.add_child(_amt_lbl)
	_out_lbl = Pal.heading("→ %s CLEAN" % Pal.money(int(_amount * (1.0 - float(f.fee)))), 30, Pal.CLEAN)
	_out_lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	amtrow.add_child(_out_lbl)
	v.add_child(amtrow)
	var slider := HSlider.new()
	slider.min_value = 500; slider.max_value = max(500, Game.dirty()); slider.step = 100
	slider.value = clampi(_amount, 500, max(500, Game.dirty()))
	slider.custom_minimum_size = Vector2(0, 40)
	slider.add_theme_stylebox_override("slider", Pal.sb(Pal.INSET, 6, Color(0, 0, 0, 0), 0, 0))
	var grab := StyleBoxFlat.new(); grab.bg_color = Pal.SODIUM; grab.set_corner_radius_all(16)
	grab.content_margin_left = 16; grab.content_margin_right = 16; grab.content_margin_top = 16; grab.content_margin_bottom = 16
	slider.add_theme_stylebox_override("grabber_area", Pal.sb(Pal.SODIUM, 6, Color(0, 0, 0, 0), 0, 0))
	slider.add_theme_stylebox_override("grabber_area_highlight", Pal.sb(Pal.GLOW, 6, Color(0, 0, 0, 0), 0, 0))
	slider.value_changed.connect(_on_slide)
	v.add_child(slider)
	var lr := Pal.hbox(10)
	lr.add_child(Pal.label("£500", 18, Pal.MUTED, 400))
	lr.add_child(Pal.spacer())
	lr.add_child(Pal.label("ALL OF IT · %s" % Pal.money(Game.dirty()), 18, Pal.MUTED, 400))
	v.add_child(lr)
	var can := Game.dirty() >= 500
	var send := Pal.btn("SEND IT THROUGH", "hivis" if can else "secondary", 108)
	send.disabled = not can
	send.pressed.connect(_send)
	v.add_child(send)
	m.add_child(v); p.add_child(m)
	return p

func _on_slide(val: float) -> void:
	_amount = int(val)
	var f: Dictionary = Economy.FRONTS[_front]
	_amt_lbl.text = Pal.money(_amount)
	_out_lbl.text = "→ %s CLEAN" % Pal.money(int(_amount * (1.0 - float(f.fee))))

func _wash_slot(w: Dictionary) -> Control:
	var left: float = float(w.ends_at) - Game.now()
	var total := 240.0
	var pct := clampf(1.0 - left / total, 0.0, 1.0)
	var ready := left <= 0
	var p := Pal.panel()
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 20); m.add_theme_constant_override("margin_right", 20)
	m.add_theme_constant_override("margin_top", 16); m.add_theme_constant_override("margin_bottom", 16)
	var row := Pal.hbox(16)
	var ring := _Ring.new()
	ring.pct = pct; ring.col = Pal.HIVIS if ready else Pal.DIRTY
	ring.custom_minimum_size = Vector2(56, 56)
	ring.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(ring)
	var tv := Pal.vbox(2)
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var fname: String = Economy.FRONTS.get(w.get("front", ""), {}).get("name", "Wash")
	tv.add_child(Pal.label(String(fname).to_upper(), 20, Pal.TEXT2, 500))
	tv.add_child(Pal.heading("+%s" % Pal.money(int(w.clean_out)), 32, Pal.CLEAN))
	row.add_child(tv)
	row.add_child(Pal.heading("READY" if ready else Game.fmt_time(left), 32, Pal.HIVIS if ready else Pal.TEXT))
	m.add_child(row); p.add_child(m)
	return p

func _send() -> void:
	var res: Dictionary = await ServerGateway.wash_start(_front, _amount)
	if res.ok:
		Audio.ui(); Game.toast.emit("Washing %s" % Pal.money(_amount), Pal.SODIUM)
	else:
		Audio.error(); Game.toast.emit(res.get("reason", "Can't"), Pal.DANGER_RED)
	_rebuild()

func _collect() -> void:
	var res: Dictionary = await ServerGateway.wash_collect()
	Audio.coin(); Game.toast.emit("Money's clean: +%s" % Pal.money(int(res.clean)), Pal.CLEAN)
	_rebuild()

func refresh() -> void:
	_rebuild()

class _Ring extends Control:
	var pct := 0.0
	var col := Color("#C9A227")
	func _draw() -> void:
		var c := size / 2.0
		var r: float = min(size.x, size.y) / 2.0 - 3.0
		draw_arc(c, r, 0, TAU, 40, Pal.RAISED, 4.0, true)
		if pct > 0.0:
			draw_arc(c, r, -PI / 2, -PI / 2 + TAU * pct, 40, col, 4.0, true)

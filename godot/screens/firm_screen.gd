class_name FirmScreen
extends Control
## The Firm (design screen 20): firm bank + territory, a war room, and the ranked
## roster. Display-level for Part 1; hooks to real firm state come in Part 2.

const ROSTER := [
	{"id": "pearl", "name": "AUNTY PEARL", "role": "BOSS · MANCHESTER", "lvl": 62, "in": "£48.0k"},
	{"id": "delroy", "name": "DELROY", "role": "FIXER · LONDON", "lvl": 57, "in": "£44.1k"},
	{"id": "shauna", "name": "SHAUNA", "role": "FIXER · LONDON", "lvl": 52, "in": "£40.2k"},
	{"id": "uncle_t", "name": "UNCLE T", "role": "ELDER · LONDON", "lvl": 47, "in": "£31.6k"},
	{"id": "maz", "name": "MAZ", "role": "WHEELS · MANCHESTER", "lvl": 44, "in": "£28.0k"},
	{"id": "nads", "name": "NADS", "role": "RUNNER · LONDON", "lvl": 39, "in": "£22.4k"},
]

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var scroll := Pal.scroll()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(scroll)
	var v := Pal.vbox(18)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(v)
	v.add_child(_band())
	var row := Pal.hbox(16)
	row.add_child(_stat("FIRM BANK", "£184.2K", "YOUR CUT THIS WEEK · £2,140", Pal.DIRTY))
	row.add_child(_territory())
	v.add_child(row)
	if Game.firm_cut_ready():
		var cc := Pal.btn("COLLECT YOUR CUT — £2,140 CLEAN", "hivis", 100)
		cc.pressed.connect(func():
			var got := Game.collect_firm_cut()
			Audio.level_up(); Game.toast.emit("Cut collected: +%s clean" % Pal.money(got), Pal.CLEAN)
			App.I.show_screen("firm"))
		v.add_child(cc)
	v.add_child(_war_room())
	var sec := Pal.sechead("THE FIRM")
	sec.add_child(Pal.label("%d OF 12 · RANKED" % ROSTER.size(), 20, Pal.MUTED, 400))
	v.add_child(sec)
	var i := 1
	for m in ROSTER:
		v.add_child(_member(i, m)); i += 1

func _band() -> Control:
	var band := PanelContainer.new()
	band.custom_minimum_size = Vector2(0, 340); band.clip_contents = true
	band.add_theme_stylebox_override("panel", Pal.sb(Pal.INSET, 12, Pal.RAISED, 1, 0))
	var bg := TextureRect.new()
	bg.texture = Pal.city_tex(Game.s.city)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	bg.modulate = Color(0.8, 0.75, 0.6); band.add_child(bg)
	var shade := ColorRect.new(); shade.color = Color(0.07, 0.08, 0.09, 0.5)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); band.add_child(shade)
	var wm := Pal.heading("FIRM", 200, Color(Pal.TEXT, 0.06))
	wm.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT); wm.position = Vector2(-360, -130); band.add_child(wm)
	var toprow := MarginContainer.new()
	toprow.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	toprow.add_theme_constant_override("margin_left", 24); toprow.add_theme_constant_override("margin_right", 24); toprow.add_theme_constant_override("margin_top", 20)
	var trh := Pal.hbox(10)
	trh.add_child(Pal.spacer())
	trh.add_child(Pal.chip("AT WAR", Pal.DANGER_RED, Pal.DANGER_RED))
	toprow.add_child(trh); band.add_child(toprow)
	var m := MarginContainer.new()
	m.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	m.add_theme_constant_override("margin_left", 32); m.add_theme_constant_override("margin_bottom", 24)
	var col := Pal.vbox(2); col.alignment = BoxContainer.ALIGNMENT_END
	col.add_child(Pal.label("THE MANOR, SPLIT NINE WAYS", 22, Pal.SODIUM, 500))
	col.add_child(Pal.heading("HOLLOW NINE", 64, Pal.TEXT))
	col.add_child(Pal.label("FOUNDED IN E8 · 14 BLOCKS HELD · RANK 7 NATIONALLY", 20, Pal.TEXT2, 400))
	m.add_child(col); band.add_child(m)
	return band

func _stat(cap: String, val: String, sub: String, col: Color) -> Control:
	var p := Pal.panel(Color(col, 0.5))
	p.add_theme_stylebox_override("panel", Pal.sb(Color(col, 0.06), 16, Color(col, 0.5), 1, 0))
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 20); m.add_theme_constant_override("margin_right", 20)
	m.add_theme_constant_override("margin_top", 18); m.add_theme_constant_override("margin_bottom", 18)
	var v := Pal.vbox(8)
	v.add_child(Pal.label(cap, 22, col, 500))
	v.add_child(Pal.heading(val, 56, col))
	v.add_child(Pal.label(sub, 18, Pal.TEXT2, 400))
	m.add_child(v); p.add_child(m)
	return p

func _territory() -> Control:
	var p := Pal.panel()
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 20); m.add_theme_constant_override("margin_right", 20)
	m.add_theme_constant_override("margin_top", 18); m.add_theme_constant_override("margin_bottom", 18)
	var v := Pal.vbox(8)
	v.add_child(Pal.label("TERRITORY", 22, Pal.TEXT2, 500))
	var big := Pal.hbox(8)
	big.add_child(Pal.heading("14", 56, Pal.TEXT))
	big.add_child(Pal.heading("/ 32 BLOCKS", 30, Pal.MUTED))
	v.add_child(big)
	v.add_child(Pal.bar(14.0 / 32.0, Pal.SODIUM, 10, 8))
	v.add_child(Pal.label("2 CONTESTED IN DALSTON", 18, Pal.DANGER_RED, 500))
	m.add_child(v); p.add_child(m)
	return p

func _war_room() -> Control:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", Pal.sb(Color(Pal.DANGER_RED, 0.06), 16, Pal.DANGER_RED, 2, 0))
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 24); m.add_theme_constant_override("margin_right", 24)
	m.add_theme_constant_override("margin_top", 20); m.add_theme_constant_override("margin_bottom", 20)
	var v := Pal.vbox(12)
	var top := Pal.hbox(10)
	top.add_child(Pal.label("WAR ROOM", 22, Pal.DANGER_RED, 500))
	top.add_child(Pal.spacer())
	top.add_child(Pal.label("ENDS IN 06:41:22", 20, Pal.TEXT2, 400))
	v.add_child(top)
	var mid := Pal.hbox(16)
	var tv := Pal.vbox(6)
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tv.add_child(Pal.heading("DALSTON, AGAINST THE LATIMER", 36, Pal.TEXT))
	tv.add_child(Pal.text("Four blocks in play. They've put nineteen bodies on it; you've got eleven and a better fence.", 24, Pal.TEXT2, 400, true))
	mid.add_child(tv)
	var pc := Pal.vbox(0); pc.alignment = BoxContainer.ALIGNMENT_CENTER
	pc.add_child(Pal.heading("61%", 56, Pal.CLEAN))
	pc.add_child(Pal.label("HOLDING", 18, Pal.MUTED, 400))
	mid.add_child(pc)
	v.add_child(mid)
	# split bar
	var split := HBoxContainer.new()
	split.add_theme_constant_override("separation", 0)
	split.custom_minimum_size = Vector2(0, 16)
	var green := ColorRect.new(); green.color = Pal.CLEAN; green.size_flags_horizontal = Control.SIZE_EXPAND_FILL; green.size_flags_stretch_ratio = 0.61
	var red := ColorRect.new(); red.color = Pal.DANGER_RED; red.size_flags_horizontal = Control.SIZE_EXPAND_FILL; red.size_flags_stretch_ratio = 0.39
	split.add_child(green); split.add_child(red)
	v.add_child(split)
	var acts := Pal.hbox(16)
	var send := Pal.btn("SEND THE CREW IN", "hivis", 108)
	send.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	send.pressed.connect(func():
		Game.add_heat(2.0); Game.add_dirty(1200)
		Audio.crit(); Game.toast.emit("Crew went in. Block held — +£1,200 dirty, heat up.", Pal.CLEAN))
	acts.add_child(send)
	var pull := Pal.btn("PULL BACK AND PAY", "secondary", 108)
	pull.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pull.pressed.connect(func(): Game.toast.emit("Firm wars wire up in Part 2", Pal.TEXT2))
	acts.add_child(pull)
	v.add_child(acts)
	m.add_child(v); p.add_child(m)
	return p

func _member(rank: int, m: Dictionary) -> Control:
	var p := Pal.panel()
	var mm := MarginContainer.new()
	mm.add_theme_constant_override("margin_left", 20); mm.add_theme_constant_override("margin_right", 20)
	mm.add_theme_constant_override("margin_top", 14); mm.add_theme_constant_override("margin_bottom", 14)
	var row := Pal.hbox(16)
	row.add_child(Pal.heading("%02d" % rank, 30, Pal.MUTED))
	var port := Pal.portrait_frame(Pal.cast_portrait(m.id), 72, Pal.SODIUM)
	port.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(port)
	var tv := Pal.vbox(2)
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tv.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	tv.add_child(Pal.heading(m.name, 30, Pal.TEXT))
	tv.add_child(Pal.label(m.role, 18, Pal.TEXT2, 400))
	row.add_child(tv)
	var rv := Pal.vbox(2); rv.alignment = BoxContainer.ALIGNMENT_CENTER
	rv.add_child(Pal.heading("LVL %d" % int(m.lvl), 28, Pal.TEXT))
	rv.add_child(Pal.label("%s IN" % m["in"], 18, Pal.DIRTY, 500))
	row.add_child(rv)
	mm.add_child(row); p.add_child(mm)
	return p

func refresh() -> void:
	pass

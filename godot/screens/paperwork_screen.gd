class_name PaperworkScreen
extends Control
## Paperwork (design screen 22): document art — warrants, receipts, seizure
## notices, evidence bags. 2026-era. A gallery of the game's real documents.

const DOCS := [
	{"kind": "WARRANT", "title": "SECTION 8 WARRANT", "ref": "W-4471-E8", "body": "Premises: Marlow Fields. Grounds: reasonable suspicion. Signed, a magistrate who's never been.", "stamp": "GRANTED", "stampcol": Pal.DANGER_RED},
	{"kind": "SEIZURE NOTICE", "title": "PROCEEDS OF CRIME", "ref": "POCA-2211", "body": "The following was removed and retained pending investigation: cash (dirty), one holdall.", "stamp": "SEIZED", "stampcol": Pal.DANGER_RED},
	{"kind": "RECEIPT", "title": "BUNG · MARE ST", "ref": "TXN-8830", "body": "In: £4,000 (misc takings). Out: £3,560. Handling: £440. Have a nice day.", "stamp": "CLEARED", "stampcol": Pal.CLEAN},
	{"kind": "EVIDENCE BAG", "title": "EXHIBIT JB/1", "ref": "BAG-0007", "body": "One burner handset. One SIM. Sealed at 23:52. Do not open outside continuity.", "stamp": "LOGGED", "stampcol": Pal.SODIUM},
]

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var scroll := Pal.scroll()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(scroll)
	var v := Pal.vbox(18)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(v)
	var head := Pal.vbox(2)
	head.add_child(Pal.label("WHAT THEY KEEP ON YOU", 22, Pal.SODIUM, 500))
	head.add_child(Pal.heading("PAPERWORK", 56, Pal.TEXT))
	v.add_child(head)
	for d in DOCS:
		v.add_child(_doc(d))

func _doc(d: Dictionary) -> Control:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", Pal.sb(Color("#141518"), 12, Pal.RAISED, 1, 0))
	p.clip_contents = true
	var stack := Control.new()
	stack.custom_minimum_size = Vector2(0, 300)
	# paper sheet
	var sheet := PanelContainer.new()
	sheet.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sheet.offset_left = 24; sheet.offset_right = -24; sheet.offset_top = 20; sheet.offset_bottom = -20
	sheet.add_theme_stylebox_override("panel", Pal.sb(Color("#cabf98"), 6, Color("#8f8460"), 1, 0))
	sheet.clip_contents = true
	var paper := TextureRect.new()
	paper.texture = Pal.tex("res://art/tex/tex-paper.png")
	paper.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	paper.stretch_mode = TextureRect.STRETCH_TILE
	paper.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	paper.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	paper.modulate = Color(1, 1, 1, 0.18)
	sheet.add_child(paper)
	var m := MarginContainer.new()
	m.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	m.add_theme_constant_override("margin_left", 26); m.add_theme_constant_override("margin_right", 26)
	m.add_theme_constant_override("margin_top", 22); m.add_theme_constant_override("margin_bottom", 22)
	var col := Pal.vbox(8)
	var top := Pal.hbox(10)
	top.add_child(_ink(d.kind, 22, 500))
	top.add_child(Pal.spacer())
	top.add_child(_ink("REF " + str(d.ref), 20, 400))
	col.add_child(top)
	col.add_child(_ink_line())
	col.add_child(_ink(str(d.title), 34, 700, false, 40))
	col.add_child(_ink(str(d.body), 22, 400, true))
	m.add_child(col)
	sheet.add_child(m)
	stack.add_child(sheet)
	# ink stamp (rotated)
	var stamp := _ink(str(d.stamp), 40, 700)
	stamp.add_theme_color_override("font_color", d.stampcol)
	var sc := PanelContainer.new()
	sc.add_theme_stylebox_override("panel", Pal.sb(Color(0, 0, 0, 0), 6, d.stampcol, 3, 10))
	sc.add_child(stamp)
	sc.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT)
	sc.position = Vector2(-260, 60)
	sc.rotation_degrees = -8
	sc.modulate.a = 0.9
	stack.add_child(sc)
	p.add_child(stack)
	return p

func _ink(t: String, size: int, weight: int, wrap := false, _mh := 0) -> Label:
	var l := Pal.text(t, size, Color("#2A2418"), weight, wrap)
	l.add_theme_font_override("font", Pal.mono_font(weight) if size < 30 else Pal.display_font())
	return l

func _ink_line() -> Control:
	var r := ColorRect.new(); r.color = Color("#2A2418", 0.4); r.custom_minimum_size = Vector2(0, 2)
	return r

func refresh() -> void:
	pass

class_name CreationScreen
extends Control
## WoW-style character creation (upgrade_04/09-creation-v2): a live procedural
## paperdoll you build slot by slot, then pick your CLASS, then your name & tag.
## No preset figures — every combination is legal and previews live.

const NAMES := ["Kess", "Ade", "Rico", "Dane", "Miki", "Sol", "Bex", "Ozzy", "Snap", "Tugz"]
const TAGS := ["KESS90", "E8 OWED", "NO SLEEP", "TENFOUR", "BROTHER"]
const GROUPS := [
	{"t": "BUILD", "keys": ["face", "skin", "top", "clothc"]},
	{"t": "HAIR", "keys": ["hair", "hairc", "beard"]},
	{"t": "FACE", "keys": ["brow", "eye", "eyec", "nose", "mouth", "mark"]},
	{"t": "KIT", "keys": ["head", "glass", "chain"]},
]
const CLASSES := [
	{"id": "road", "name": "GREW UP ON ROAD", "blurb": "You know the mandem by name. Contacts open doors nobody else can.",
		"perk": "+2 SLICKNESS · a face in every postcode", "tint": Color("#FFA94D")},
	{"id": "athlete", "name": "DROPOUT ATHLETE", "blurb": "Fast twitch, long legs. You're gone before they've turned round.",
		"perk": "+2 STRENGTH · +10 ENERGY", "tint": Color("#D63B3B")},
	{"id": "college", "name": "COLLEGE BOY", "blurb": "They rate you less at first, which is exactly how you like it.",
		"perk": "+£40 CLEAN · they underestimate you", "tint": Color("#4DA3FF")},
]

var _opts: Dictionary
var _order: Array
var step := 0                    # 0 look · 1 class · 2 name
var cfg: Dictionary
var cat := "hair"
var view := "bust"
var origin_i := -1
var cname := ""
var tag := ""
var _doll: DollView
var _name_le: LineEdit
var _tag_le: LineEdit
var _panel: VBoxContainer
var _editing: Label
var _editingval: Label
var _stepno: Label
var _title: Label
var _segs: HBoxContainer

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_opts = Doll.options()
	_order = []
	for g in GROUPS: _order.append_array(g.keys)
	cfg = Doll.DEF.duplicate()
	if OS.get_environment("ENDS_CSTEP") != "":
		step = int(OS.get_environment("ENDS_CSTEP")); origin_i = 0
	_build_static()
	_build()

# ---------- persistent frame ----------
func _build_static() -> void:
	var bg := ColorRect.new(); bg.color = Color("#0C0E10")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT); bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	# header
	var head := PanelContainer.new()
	head.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE); head.offset_bottom = 130
	var hsb := Pal.sb(Color("#15181C"), 0, Pal.HAIRLINE, 1, 0); hsb.border_width_bottom = 1
	head.add_theme_stylebox_override("panel", hsb)
	var hm := MarginContainer.new()
	hm.add_theme_constant_override("margin_left", 32); hm.add_theme_constant_override("margin_right", 32)
	hm.add_theme_constant_override("margin_top", 40); hm.add_theme_constant_override("margin_bottom", 16)
	var hv := Pal.vbox(10)
	var hrow := Pal.hbox(20)
	_title = Pal.heading("WHO ARE YOU", 42, Pal.TEXT); _title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hrow.add_child(_title)
	_stepno = Pal.label("STEP 1 OF 3 · LOOK", 22, Pal.SODIUM, 500)
	_stepno.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hrow.add_child(_stepno)
	hv.add_child(hrow)
	_segs = Pal.hbox(10)
	for i in range(3):
		var s := ColorRect.new(); s.custom_minimum_size = Vector2(0, 8); s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_segs.add_child(s)
	hv.add_child(_segs)
	hm.add_child(hv); head.add_child(hm); add_child(head)

	# portrait plate with the live doll
	var plate := Control.new()
	plate.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE); plate.offset_top = 130; plate.offset_bottom = 900
	plate.clip_contents = true
	var pbg := ColorRect.new(); pbg.color = Color("#1A1C19"); pbg.set_anchors_preset(Control.PRESET_FULL_RECT); pbg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plate.add_child(pbg)
	var tooth := Pal.tooth_layer(); tooth.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); tooth.modulate.a = 0.5
	plate.add_child(tooth)
	var floor := ColorRect.new(); floor.color = Color("#141613")
	floor.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE); floor.offset_top = -150; floor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plate.add_child(floor)
	# spotlight
	var spot := TextureRect.new(); spot.texture = Pal.radial_glow()
	spot.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); spot.offset_bottom = -180
	spot.stretch_mode = TextureRect.STRETCH_SCALE; spot.modulate = Color(Color("#FFC97A"), 0.16)
	spot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var spm := CanvasItemMaterial.new(); spm.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD; spot.material = spm
	plate.add_child(spot)
	# the doll
	_doll = DollView.new()
	_doll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); _doll.offset_top = 20; _doll.offset_bottom = -20
	plate.add_child(_doll)
	# vignette
	var vig := TextureRect.new(); vig.texture = _radial_vignette()
	vig.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); vig.stretch_mode = TextureRect.STRETCH_SCALE
	vig.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plate.add_child(vig)
	# corner ticks
	for corner in [Vector2(22, 22), Vector2(-44, 22), Vector2(22, -44), Vector2(-44, -44)]:
		var tk := ColorRect.new(); tk.color = Color(Pal.SODIUM, 0.55); tk.custom_minimum_size = Vector2(22, 3)
		tk.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT if corner.x > 0 else Control.PRESET_TOP_RIGHT)
	# EDITING label (top-left of plate)
	var edcol := Pal.vbox(6); edcol.position = Vector2(36, 40); edcol.mouse_filter = Control.MOUSE_FILTER_IGNORE
	edcol.add_child(Pal.label("EDITING", 20, Pal.MUTED, 500))
	_editing = Pal.heading("HAIR", 36, Pal.TEXT); edcol.add_child(_editing)
	_editingval = Pal.label("SKIN FADE", 22, Pal.SODIUM, 500); edcol.add_child(_editingval)
	plate.add_child(edcol)
	# rand / reset (top-right)
	var tools := Pal.vbox(12); tools.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	tools.offset_left = -114; tools.offset_top = 40; tools.offset_right = -36
	tools.add_child(_icon_btn("⚄", func(): cfg = Doll.random(); _doll.set_cfg(cfg); _build()))
	tools.add_child(_icon_btn("↺", func(): cfg = Doll.DEF.duplicate(); _doll.set_cfg(cfg); _build()))
	plate.add_child(tools)
	# prev / next variant (mid sides)
	var prevb := _icon_btn("‹", func(): _step_variant(-1)); prevb.position = Vector2(36, 400)
	var nextb := _icon_btn("›", func(): _step_variant(1))
	nextb.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT); nextb.offset_left = -114; nextb.offset_top = -39; nextb.offset_right = -36; nextb.offset_bottom = 39
	prevb.set_anchors_and_offsets_preset(Control.PRESET_CENTER_LEFT); prevb.offset_left = 36; prevb.offset_top = -39; prevb.offset_right = 114; prevb.offset_bottom = 39
	plate.add_child(prevb); plate.add_child(nextb)
	# zoom segmented (top-centre)
	var zoom := _zoom_seg(); zoom.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP); zoom.offset_top = 40
	plate.add_child(zoom)
	add_child(plate)
	_plate = plate

	# step panel (below plate)
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.offset_top = 910; scroll.offset_bottom = -300
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var pm := MarginContainer.new(); pm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pm.add_theme_constant_override("margin_left", 32); pm.add_theme_constant_override("margin_right", 32)
	_panel = Pal.vbox(16); pm.add_child(_panel); scroll.add_child(pm); add_child(scroll)

	# action dock (bottom)
	var dock := VBoxContainer.new(); dock.add_theme_constant_override("separation", 14)
	dock.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	dock.offset_left = 32; dock.offset_right = -32; dock.offset_top = -280; dock.offset_bottom = -40
	var arow := Pal.hbox(16)
	var backb := Pal.btn("BACK", "secondary", 96); backb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	backb.pressed.connect(_back)
	_nextb = Pal.btn("NEXT", "hivis", 96); _nextb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_nextb.size_flags_stretch_ratio = 2.0
	_nextb.pressed.connect(_next)
	arow.add_child(backb); arow.add_child(_nextb)
	dock.add_child(arow)
	add_child(dock)
	_dock = dock

var _plate: Control
var _nextb: Button
var _dock: Control

func _radial_vignette() -> GradientTexture2D:
	var g := Gradient.new(); g.offsets = PackedFloat32Array([0.0, 0.62, 1.0])
	g.colors = PackedColorArray([Color(0,0,0,0), Color(0,0,0,0), Color(0,0,0,0.66)])
	var t := GradientTexture2D.new(); t.gradient = g; t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.44); t.fill_to = Vector2(1.05, 1.05); t.width = 256; t.height = 256
	return t

func _icon_btn(txt: String, cb: Callable) -> Button:
	var b := Button.new(); b.text = txt; b.custom_minimum_size = Vector2(78, 78)
	b.focus_mode = Control.FOCUS_NONE; b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.add_theme_font_override("font", Pal.display_font()); b.add_theme_font_size_override("font_size", 34)
	b.add_theme_color_override("font_color", Pal.TEXT2)
	b.add_theme_color_override("font_hover_color", Pal.SODIUM)
	b.add_theme_stylebox_override("normal", Pal.sb(Color("#0C0E10", 0.82), 0, Pal.HAIRLINE, 1, 0))
	b.add_theme_stylebox_override("hover", Pal.sb(Color("#0C0E10", 0.82), 0, Pal.SODIUM, 1, 0))
	b.add_theme_stylebox_override("pressed", Pal.sb(Pal.SODIUM, 0, Pal.SODIUM, 1, 0))
	b.pressed.connect(cb)
	return b

func _zoom_seg() -> Control:
	var wrap := Pal.hbox(0)
	var sb := Pal.sb(Color("#0C0E10", 0.82), 0, Pal.HAIRLINE, 1, 0)
	var frame := PanelContainer.new(); frame.add_theme_stylebox_override("panel", sb)
	var row := Pal.hbox(0)
	for pair in [["full", "BODY"], ["bust", "BUST"], ["head", "FACE"]]:
		var seg := Button.new(); seg.text = pair[1]; seg.focus_mode = Control.FOCUS_NONE
		seg.custom_minimum_size = Vector2(0, 58); seg.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		seg.add_theme_font_override("font", Pal.mono_font(500)); seg.add_theme_font_size_override("font_size", 20)
		var on: bool = pair[0] == view
		seg.add_theme_color_override("font_color", Pal.INVERSE if on else Pal.MUTED)
		seg.add_theme_stylebox_override("normal", Pal.sb(Pal.SODIUM if on else Color(0,0,0,0), 0))
		seg.add_theme_stylebox_override("hover", Pal.sb(Pal.SODIUM if on else Color(0,0,0,0), 0))
		seg.add_theme_stylebox_override("pressed", Pal.sb(Pal.SODIUM if on else Color(0,0,0,0), 0))
		var v: String = pair[0]
		seg.pressed.connect(func(): view = v; _doll.set_view(v); _rebuild_zoom())
		row.add_child(seg)
	frame.add_child(row); wrap.add_child(frame)
	return wrap

func _rebuild_zoom() -> void:
	# cheap: rebuild the plate's zoom seg by rebuilding the whole static frame is heavy;
	# just re-skin existing segments
	Audio.ui()
	for seg in _find_zoom_segments():
		var on: bool = seg.text == {"full":"BODY","bust":"BUST","head":"FACE"}.get(view)
		seg.add_theme_color_override("font_color", Pal.INVERSE if on else Pal.MUTED)
		seg.add_theme_stylebox_override("normal", Pal.sb(Pal.SODIUM if on else Color(0,0,0,0), 0))

func _find_zoom_segments() -> Array:
	var out := []
	for seg in ["BODY", "BUST", "FACE"]: pass
	# walk plate for buttons with those labels
	_collect_buttons(_plate, ["BODY", "BUST", "FACE"], out)
	return out

func _collect_buttons(node: Node, labels: Array, out: Array) -> void:
	for ch in node.get_children():
		if ch is Button and ch.text in labels: out.append(ch)
		_collect_buttons(ch, labels, out)

# ---------- step dispatch ----------
func _build() -> void:
	_stepno.text = "STEP %d OF 3 · %s" % [step + 1, ["LOOK", "CLASS", "NAME"][step]]
	_title.text = ["WHO ARE YOU", "PICK YOUR CLASS", "MAKE YOUR NAME"][step]
	for i in range(3):
		_segs.get_child(i).color = Pal.SODIUM if i <= step else Pal.RAISED
	_doll.set_cfg(cfg)
	for ch in _panel.get_children(): ch.queue_free()
	match step:
		0: _build_look()
		1: _build_class()
		2: _build_name()
	_nextb.text = "LOCK IT IN" if step == 2 else "NEXT"
	var ready := step != 1 or origin_i >= 0
	_nextb.disabled = not ready

func _step_variant(d: int) -> void:
	if step != 0: return
	var n: int = _opts[cat].list.size()
	cfg[cat] = (int(cfg[cat]) + d + n) % n
	_doll.set_cfg(cfg); _build()

# ---------- LOOK ----------
func _build_look() -> void:
	_editing.visible = true; _editingval.visible = true
	_editing.text = String(_opts[cat].label)
	_editingval.text = String(_opts[cat].list[cfg[cat]]).to_upper()
	# category rail
	var rail := HBoxContainer.new(); rail.add_theme_constant_override("separation", 10)
	var railscroll := ScrollContainer.new(); railscroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	railscroll.custom_minimum_size = Vector2(0, 70); railscroll.add_child(rail)
	for g in GROUPS:
		rail.add_child(Pal.label(g.t, 19, Color("#3A3F45"), 500))
		for k in g.keys:
			rail.add_child(_catchip(k))
	_panel.add_child(railscroll)
	# options
	var o: Dictionary = _opts[cat]
	_panel.add_child(_sechead(String(o.label), "%d / %d" % [int(cfg[cat]) + 1, o.list.size()]))
	if o.has("swatch"):
		var sg := GridContainer.new(); sg.columns = 8
		sg.add_theme_constant_override("h_separation", 12); sg.add_theme_constant_override("v_separation", 12)
		for i in range(o.swatch.size()):
			sg.add_child(_swatch(i, o.swatch[i]))
		_panel.add_child(sg)
	else:
		var tg := GridContainer.new(); tg.columns = 4
		tg.add_theme_constant_override("h_separation", 12); tg.add_theme_constant_override("v_separation", 12)
		for i in range(o.list.size()):
			tg.add_child(_tile(i, String(o.list[i])))
		_panel.add_child(tg)

func _catchip(k: String) -> Button:
	var on: bool = k == cat
	var b := Button.new(); b.focus_mode = Control.FOCUS_NONE; b.custom_minimum_size = Vector2(0, 66)
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.text = String(_opts[k].label)
	b.add_theme_font_override("font", Pal.mono_font(500)); b.add_theme_font_size_override("font_size", 20)
	b.add_theme_color_override("font_color", Pal.SODIUM if on else Pal.TEXT2)
	b.add_theme_color_override("font_hover_color", Pal.SODIUM)
	var bg := Color(Pal.SODIUM, 0.10) if on else Color("#15181C")
	b.add_theme_stylebox_override("normal", Pal.sb(bg, 0, Pal.SODIUM if on else Pal.HAIRLINE, 1, 12))
	b.add_theme_stylebox_override("hover", Pal.sb(bg, 0, Pal.SODIUM, 1, 12))
	b.add_theme_stylebox_override("pressed", Pal.sb(bg, 0, Pal.SODIUM, 1, 12))
	b.pressed.connect(func(): cat = k; _build())
	return b

func _swatch(i: int, col: Color) -> Control:
	var b := Button.new(); b.focus_mode = Control.FOCUS_NONE; b.custom_minimum_size = Vector2(0, 92)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL; b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var on: bool = i == int(cfg[cat])
	b.add_theme_stylebox_override("normal", Pal.sb(col, 0, Pal.SODIUM if on else Pal.HAIRLINE, 3, 0))
	b.add_theme_stylebox_override("hover", Pal.sb(col, 0, Pal.SODIUM, 3, 0))
	b.add_theme_stylebox_override("pressed", Pal.sb(col, 0, Pal.SODIUM, 3, 0))
	b.pressed.connect(func(): cfg[cat] = i; _doll.set_cfg(cfg); _build())
	return b

func _tile(i: int, nm: String) -> Control:
	var on: bool = i == int(cfg[cat])
	var b := Button.new(); b.focus_mode = Control.FOCUS_NONE; b.custom_minimum_size = Vector2(0, 200)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL; b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.add_theme_stylebox_override("normal", Pal.sb(Color("#15181C"), 0, Pal.SODIUM if on else Pal.HAIRLINE, 2 if on else 1, 0))
	b.add_theme_stylebox_override("hover", Pal.sb(Color("#191d22"), 0, Pal.SODIUM, 1, 0))
	b.add_theme_stylebox_override("pressed", Pal.sb(Color("#15181C"), 0, Pal.SODIUM, 2, 0))
	var mm := MarginContainer.new(); mm.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); mm.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var v := Pal.vbox(0); v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mini := DollView.new(); mini.custom_minimum_size = Vector2(0, 150); mini.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var mc: Dictionary = cfg.duplicate(); mc[cat] = i
	mini.cfg = mc; mini.view = "head"
	mini.set_process(false)   # tiles don't blink
	v.add_child(mini)
	var cap := Pal.hbox(6); cap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var cm := MarginContainer.new(); cm.add_theme_constant_override("margin_left", 12); cm.add_theme_constant_override("margin_top", 8); cm.add_theme_constant_override("margin_bottom", 8)
	cm.add_child(Pal.label(nm.to_upper(), 18, Pal.SODIUM if on else Pal.TEXT2, 500)); cap.add_child(cm)
	v.add_child(cap)
	mm.add_child(v); b.add_child(mm)
	b.pressed.connect(func(): cfg[cat] = i; _doll.set_cfg(cfg); _build())
	return b

# ---------- CLASS ----------
func _build_class() -> void:
	_editing.visible = false; _editingval.visible = false
	_panel.add_child(_sechead("WHERE YOU CAME FROM", "PERMANENT"))
	for i in range(CLASSES.size()):
		_panel.add_child(_class_card(i))

func _class_card(i: int) -> Control:
	var cl: Dictionary = CLASSES[i]; var on: bool = i == origin_i
	var b := Button.new(); b.focus_mode = Control.FOCUS_NONE; b.custom_minimum_size = Vector2(0, 190)
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var bg := Color(cl.tint, 0.10) if on else Color(Pal.RAISED, 0.9)
	b.add_theme_stylebox_override("normal", Pal.sb(bg, 16, cl.tint if on else Pal.HAIRLINE, 1, 0))
	b.add_theme_stylebox_override("hover", Pal.sb(bg, 16, cl.tint, 1, 0))
	b.add_theme_stylebox_override("pressed", Pal.sb(bg, 16, cl.tint, 1, 0))
	var mm := MarginContainer.new(); mm.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); mm.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mm.add_theme_constant_override("margin_left", 26); mm.add_theme_constant_override("margin_right", 26)
	mm.add_theme_constant_override("margin_top", 22); mm.add_theme_constant_override("margin_bottom", 22)
	var v := Pal.vbox(10); v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(Pal.label("CLASS 0%d" % (i + 1), 20, cl.tint, 500))
	v.add_child(Pal.heading(String(cl.name), 38, Pal.TEXT))
	var blurb := Pal.text(String(cl.blurb), 22, Pal.TEXT2, 400, true); blurb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(blurb)
	v.add_child(Pal.label(String(cl.perk), 20, cl.tint, 500))
	mm.add_child(v); b.add_child(mm)
	b.pressed.connect(func(): origin_i = i; _build())
	return b

# ---------- NAME ----------
func _build_name() -> void:
	_editing.visible = false; _editingval.visible = false
	_panel.add_child(_sechead("NAME AND SPRAY TAG", "TYPE OR TAP"))
	var nrow := Pal.hbox(14)
	var name_field := _text_field("YOUR NAME", cname, "Type your name…", 12, false, true, func(t): cname = t)
	name_field.size_flags_stretch_ratio = 2.0
	nrow.add_child(name_field)
	nrow.add_child(_text_field("TAG", tag, "SPRAY TAG", 10, true, false, func(t): tag = t))
	_panel.add_child(nrow)
	# quick-pick chips fill the fields (still fully editable after)
	var nchips := HBoxContainer.new(); nchips.add_theme_constant_override("separation", 12)
	var nscroll := ScrollContainer.new(); nscroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	nscroll.custom_minimum_size = Vector2(0, 70); nscroll.add_child(nchips)
	for n in NAMES:
		var nm2: String = n
		nchips.add_child(_pick_chip(n, n == cname, func():
			cname = nm2
			if _name_le: _name_le.text = nm2))
	_panel.add_child(nscroll)
	var tchips := HBoxContainer.new(); tchips.add_theme_constant_override("separation", 12)
	var tscroll := ScrollContainer.new(); tscroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	tscroll.custom_minimum_size = Vector2(0, 70); tscroll.add_child(tchips)
	for t in TAGS:
		var tg2: String = t
		tchips.add_child(_pick_chip(t, t == tag, func():
			tag = tg2
			if _tag_le: _tag_le.text = tg2))
	_panel.add_child(tscroll)

## A styled, writable field. `disp` uses the Anton display font (for the name);
## otherwise the mono font (for the tag). Updates its bound var on every keystroke.
func _text_field(cap: String, val: String, placeholder: String, maxlen: int, upper: bool, disp: bool, on_change: Callable) -> Control:
	var wrap := Control.new(); wrap.custom_minimum_size = Vector2(0, 100)
	wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var cover := PanelContainer.new(); cover.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cover.add_theme_stylebox_override("panel", Pal.sb(Color("#0C0E10", 0.9), 14, Pal.HAIRLINE, 1, 0))
	wrap.add_child(cover)
	var lbl := Pal.label(cap, 15, Pal.MUTED, 500); lbl.position = Vector2(22, 12)
	wrap.add_child(lbl)
	var le := LineEdit.new()
	le.text = val; le.placeholder_text = placeholder; le.max_length = maxlen
	le.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	le.offset_left = 18; le.offset_right = -18; le.offset_top = 34
	le.add_theme_font_override("font", Pal.display_font() if disp else Pal.mono_font(500))
	le.add_theme_font_size_override("font_size", 34 if disp else 26)
	le.add_theme_color_override("font_color", Pal.TEXT if disp else Pal.SODIUM)
	le.add_theme_color_override("font_placeholder_color", Pal.MUTED)
	le.add_theme_color_override("caret_color", Pal.SODIUM)
	le.add_theme_constant_override("caret_width", 3)
	le.add_theme_stylebox_override("normal", Pal.sb(Color(0, 0, 0, 0), 0))
	le.add_theme_stylebox_override("focus", Pal.sb(Color(0, 0, 0, 0), 0))
	if upper:
		le.text_changed.connect(func(t):
			var up: String = String(t).to_upper()
			if up != String(t):
				var col: int = le.caret_column
				le.text = up; le.caret_column = col
			on_change.call(le.text))
	else:
		le.text_changed.connect(func(t): on_change.call(t))
	# glowing focus underline
	var ul := ColorRect.new(); ul.color = Pal.SODIUM
	ul.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	ul.offset_left = 12; ul.offset_right = -12; ul.offset_top = -3; ul.scale.x = 0.0; ul.pivot_offset = Vector2.ZERO
	le.focus_entered.connect(func(): ul.scale.x = 1.0)
	le.focus_exited.connect(func(): ul.scale.x = 0.0)
	wrap.add_child(le); wrap.add_child(ul)
	if disp: _name_le = le
	else: _tag_le = le
	return wrap

func _pick_chip(txt: String, on: bool, cb: Callable) -> Button:
	var b := Button.new(); b.text = txt; b.focus_mode = Control.FOCUS_NONE; b.custom_minimum_size = Vector2(0, 60)
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.add_theme_font_override("font", Pal.mono_font(500)); b.add_theme_font_size_override("font_size", 22)
	b.add_theme_color_override("font_color", Pal.SODIUM if on else Pal.TEXT2)
	b.add_theme_color_override("font_hover_color", Pal.SODIUM)
	b.add_theme_stylebox_override("normal", Pal.sb(Color(Pal.SODIUM, 0.1) if on else Color("#15181C"), 10, Pal.SODIUM if on else Pal.HAIRLINE, 1, 14))
	b.add_theme_stylebox_override("hover", Pal.sb(Color("#15181C"), 10, Pal.SODIUM, 1, 14))
	b.add_theme_stylebox_override("pressed", Pal.sb(Color("#15181C"), 10, Pal.SODIUM, 1, 14))
	b.pressed.connect(cb)
	return b

func _sechead(left: String, right: String) -> Control:
	var h := Pal.hbox(16)
	h.add_child(Pal.label(left, 20, Pal.SODIUM, 500))
	var rule := ColorRect.new(); rule.color = Pal.HAIRLINE; rule.custom_minimum_size = Vector2(0, 1)
	rule.size_flags_horizontal = Control.SIZE_EXPAND_FILL; rule.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(rule)
	if right != "": h.add_child(Pal.label(right, 20, Pal.MUTED, 500))
	return h

# ---------- flow ----------
func _next() -> void:
	if step == 1 and origin_i < 0: return
	if step < 2:
		Audio.ui(); step += 1; _build()
	else:
		_finish()

func _back() -> void:
	Audio.ui()
	if step > 0: step -= 1; _build()

func _finish() -> void:
	Audio.level_up()
	Game.new_character(cname if cname != "" else NAMES[0], 0, CLASSES[max(0, origin_i)].id)
	Game.s["doll"] = cfg.duplicate()
	Game.s["tag"] = tag
	Game.persist()
	App.I.show_screen("map")
	App.I._refresh_hud()
	App.I.start_prologue()

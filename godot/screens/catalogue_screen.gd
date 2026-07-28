class_name CatalogueScreen
extends Control
## The Item Catalogue (upgrade_05/item-catalogue.html) — everything you can wear.
## 12 slot tabs + a Sets tab, a rarity filter, a 3-up card grid of procedural gear
## icons, and a detail sheet with stats / source / trade-off. EQUIP fits owned gear.

var _slot := "head"
var _rfil := ""
var _tabs: HBoxContainer
var _rrow: HBoxContainer
var _grid_host: VBoxContainer
const ORDER := ["Ba", "De", "Pe", "Ce", "Ic"]

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var root := Pal.vbox(0)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	# header
	var head := PanelContainer.new()
	head.add_theme_stylebox_override("panel", Pal.sb(Color("#15181C"), 0, Pal.RAISED, 1, 0))
	var hm := MarginContainer.new()
	hm.add_theme_constant_override("margin_left", 28); hm.add_theme_constant_override("margin_right", 28)
	hm.add_theme_constant_override("margin_top", 20); hm.add_theme_constant_override("margin_bottom", 14)
	var hv := Pal.vbox(12)
	var titlerow := Pal.hbox(12)
	var back := Pal.btn("←", "secondary", 52); back.custom_minimum_size = Vector2(64, 52)
	back.pressed.connect(func(): App.I.show_screen("character"))
	titlerow.add_child(back)
	titlerow.add_child(Pal.heading("EVERYTHING YOU CAN WEAR", 34, Pal.TEXT))
	var sp := Control.new(); sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL; titlerow.add_child(sp)
	var total := 0
	for s in Config.item_slots(): total += (s.get("items", []) as Array).size()
	titlerow.add_child(Pal.label("%d ITEMS" % total, 20, Pal.SODIUM, 500))
	hv.add_child(titlerow)
	# slot tabs (scrollable)
	var tabscroll := ScrollContainer.new()
	tabscroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	tabscroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	tabscroll.custom_minimum_size = Vector2(0, 62)
	_tabs = Pal.hbox(8); tabscroll.add_child(_tabs)
	hv.add_child(tabscroll)
	_rrow = Pal.hbox(8)
	hv.add_child(_rrow)
	hm.add_child(hv); head.add_child(hm)
	root.add_child(head)

	# body
	var scroll := Pal.scroll(); scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_grid_host = Pal.vbox(16)
	_grid_host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_grid_host)
	root.add_child(scroll)

	_build_tabs()
	_build_rarity()
	_rebuild()

func _build_tabs() -> void:
	for c in _tabs.get_children(): c.queue_free()
	for s in Config.item_slots():
		var k := str(s.k)
		var b := _tab_btn("%s  %d" % [str(s.label), (s.get("items", []) as Array).size()], _slot == k)
		b.pressed.connect(func(): _slot = k; _rebuild(); _build_tabs())
		_tabs.add_child(b)
	var setb := _tab_btn("SETS  5", _slot == "sets")
	setb.pressed.connect(func(): _slot = "sets"; _rebuild(); _build_tabs())
	_tabs.add_child(setb)

func _tab_btn(txt: String, on: bool) -> Button:
	var b := Pal.btn(txt, "hivis" if on else "secondary", 56)
	b.custom_minimum_size = Vector2(0, 56)
	b.add_theme_font_size_override("font_size", 20)
	return b

func _build_rarity() -> void:
	for c in _rrow.get_children(): c.queue_free()
	for r in ORDER:
		var on: bool = _rfil == r
		var col: Color = ItemArt.RC.get(r, Pal.TEXT)
		var b := Pal.btn(str(Config.items.get("rarity", {}).get(r, r)), "secondary", 44)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.add_theme_font_size_override("font_size", 16)
		b.add_theme_stylebox_override("normal", Pal.sb(col if on else Color("#15181C"), 8, col, 1, 0))
		b.add_theme_color_override("font_color", Color("#121417") if on else col)
		b.pressed.connect(func(): _rfil = "" if _rfil == r else r; _rebuild(); _build_rarity())
		_rrow.add_child(b)

func _rebuild() -> void:
	for c in _grid_host.get_children(): c.queue_free()
	if _slot == "sets":
		_build_sets(); return
	var slot: Dictionary = {}
	for s in Config.item_slots():
		if s.k == _slot: slot = s
	if slot.is_empty(): return
	var shown: Array = []
	for it in slot.get("items", []):
		if _rfil == "" or it.get("r", "") == _rfil: shown.append(it)
	_grid_host.add_child(Pal.label("%s · %d SHOWN" % [str(slot.label), shown.size()], 18, Pal.SODIUM, 500))
	_grid_host.add_child(Pal.text(str(slot.blurb), 22, Pal.TEXT2, 400, true))
	var grid := GridContainer.new(); grid.columns = 3
	grid.add_theme_constant_override("h_separation", 14); grid.add_theme_constant_override("v_separation", 14)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for it in shown: grid.add_child(_card(it))
	_grid_host.add_child(grid)

func _card(it: Dictionary) -> Control:
	var col: Color = ItemArt.RC.get(it.get("r", "Ba"), Pal.TEXT)
	var b := Button.new()
	b.custom_minimum_size = Vector2(0, 260); b.focus_mode = Control.FOCUS_NONE
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.add_theme_stylebox_override("normal", Pal.sb(Color("#15181C"), 8, Color(col, 0.55), 2, 0))
	b.add_theme_stylebox_override("hover", Pal.sb(Color("#1B1F24"), 8, col, 2, 0))
	b.add_theme_stylebox_override("pressed", Pal.sb(Color("#15181C"), 8, col, 2, 0))
	var v := Pal.vbox(0); v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# well with the icon
	var well := PanelContainer.new(); well.custom_minimum_size = Vector2(0, 172); well.clip_contents = true
	well.add_theme_stylebox_override("panel", Pal.sb(Color("#101317"), 0))
	var iv := ItemView.new(); iv.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); iv.set_item(it)
	var im := MarginContainer.new(); im.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	im.add_theme_constant_override("margin_left", 14); im.add_theme_constant_override("margin_right", 14)
	im.add_theme_constant_override("margin_top", 14); im.add_theme_constant_override("margin_bottom", 14)
	im.add_child(iv); well.add_child(im)
	v.add_child(well)
	var band := ColorRect.new(); band.color = col; band.custom_minimum_size = Vector2(0, 5); v.add_child(band)
	var meta := Pal.vbox(4)
	var mm := MarginContainer.new()
	mm.add_theme_constant_override("margin_left", 12); mm.add_theme_constant_override("margin_right", 12)
	mm.add_theme_constant_override("margin_top", 8); mm.add_theme_constant_override("margin_bottom", 10)
	var rlab := str(Config.items.get("rarity", {}).get(it.get("r", "Ba"), "BASIC"))
	if int(it.get("il", 0)) > 0: rlab += " · %d" % int(it.il)
	meta.add_child(Pal.label(rlab, 15, col, 500))
	meta.add_child(Pal.heading(str(it.n), 21, Pal.TEXT))
	var owned := Game.owns_item(str(it.get("id", "")))
	meta.add_child(Pal.label("EQUIPPED" if Game.fitted(str(it.get("slot", ""))) == it.get("id", "") else ("OWNED" if owned else str(it.get("price", it.get("st", "")))), 15, Pal.CLEAN if owned else Pal.MUTED, 400))
	mm.add_child(meta); v.add_child(mm)
	b.add_child(v)
	b.pressed.connect(func(): _open(it))
	return b

func _build_sets() -> void:
	_grid_host.add_child(Pal.label("FIVE SETS · 3-PIECE AND 5-PIECE TIERS", 18, Pal.SODIUM, 500))
	_grid_host.add_child(Pal.text("A set bonus counts equipped pieces carrying the same tag. The Stab Vest and The Plate block all of them.", 22, Pal.TEXT2, 400, true))
	for st in Config.items.get("sets", []):
		var setcol := Color(str(st.c))
		var pieces: Array = []
		for s in Config.item_slots():
			for it in s.get("items", []):
				if it.get("set", "") == st.n: pieces.append(it)
		var card := PanelContainer.new()
		card.add_theme_stylebox_override("panel", Pal.sb(Color("#15181C"), 10, Color(setcol, 0.6), 1, 0))
		var m := MarginContainer.new()
		m.add_theme_constant_override("margin_left", 20); m.add_theme_constant_override("margin_right", 20)
		m.add_theme_constant_override("margin_top", 18); m.add_theme_constant_override("margin_bottom", 18)
		var v := Pal.vbox(12)
		var top := Pal.hbox(12)
		top.add_child(Pal.heading(str(st.n), 32, setcol))
		var spc := Control.new(); spc.size_flags_horizontal = Control.SIZE_EXPAND_FILL; top.add_child(spc)
		top.add_child(Pal.label("%d PIECES" % pieces.size(), 18, Pal.MUTED, 500))
		v.add_child(top)
		v.add_child(Pal.label(str(st.tag), 18, Pal.TEXT2, 500))
		var prow := Pal.hbox(8)
		for p in pieces:
			var pv := ItemView.new(); pv.custom_minimum_size = Vector2(74, 74); pv.set_item(p)
			var pc := PanelContainer.new(); pc.add_theme_stylebox_override("panel", Pal.sb(Color("#101317"), 4, Color(setcol, 0.4), 1, 0))
			var pcm := MarginContainer.new(); pcm.add_theme_constant_override("margin_left", 4); pcm.add_theme_constant_override("margin_right", 4)
			pcm.add_theme_constant_override("margin_top", 4); pcm.add_theme_constant_override("margin_bottom", 4)
			pcm.add_child(pv); pc.add_child(pcm); prow.add_child(pc)
		v.add_child(prow)
		v.add_child(_bonus_line("3PC", str(st.b3), setcol))
		v.add_child(_bonus_line("5PC", str(st.b5), setcol))
		m.add_child(v); card.add_child(m)
		_grid_host.add_child(card)

func _bonus_line(tier: String, txt: String, col: Color) -> Control:
	var row := Pal.hbox(12)
	var t := Pal.label(tier, 18, col, 500); t.custom_minimum_size = Vector2(52, 0)
	row.add_child(t)
	row.add_child(Pal.text(txt, 20, Pal.TEXT, 400, true))
	return row

# ---------- detail sheet ----------
func _open(it: Dictionary) -> void:
	Audio.ui()
	var col: Color = ItemArt.RC.get(it.get("r", "Ba"), Pal.TEXT)
	var dim := ColorRect.new(); dim.color = Color(0.02, 0.03, 0.04, 0.78)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); dim.mouse_filter = Control.MOUSE_FILTER_STOP
	App.I.overlay.add_child(dim)
	var close := func(): dim.queue_free()
	var wrap := CenterContainer.new(); wrap.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dim.add_child(wrap)
	var p := PanelContainer.new(); p.custom_minimum_size = Vector2(980, 0)
	p.add_theme_stylebox_override("panel", Pal.sb(Color(Pal.RAISED, 0.98), 16, col, 2, 0))
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 34); m.add_theme_constant_override("margin_right", 34)
	m.add_theme_constant_override("margin_top", 30); m.add_theme_constant_override("margin_bottom", 30)
	var v := Pal.vbox(18)
	var top := Pal.hbox(20)
	var well := PanelContainer.new(); well.custom_minimum_size = Vector2(200, 200)
	well.add_theme_stylebox_override("panel", Pal.sb(Color("#101317"), 8, col, 2, 0)); well.clip_contents = true
	var iv := ItemView.new(); iv.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var im := MarginContainer.new(); im.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for s2 in ["left", "right", "top", "bottom"]: im.add_theme_constant_override("margin_" + s2, 12)
	im.add_child(iv); well.add_child(im); iv.set_item(it)
	top.add_child(well)
	var info := Pal.vbox(8); info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_child(Pal.label(str(Config.items.get("rarity", {}).get(it.get("r", "Ba"), "BASIC")), 18, col, 500))
	info.add_child(Pal.heading(str(it.n), 40, Pal.TEXT))
	info.add_child(Pal.text(str(it.get("d", "")), 22, Pal.TEXT2, 400, true))
	top.add_child(info)
	v.add_child(top)
	# stat rows
	v.add_child(_kv("ITEM LEVEL", str(it.il) if int(it.get("il", 0)) > 0 else "—", Pal.TEXT))
	v.add_child(_kv("EFFECT" if it.has("price") else "STATS", str(it.get("st", "—")), Pal.TEXT))
	if it.has("price"): v.add_child(_kv("PRICE", str(it.price), Pal.CLEAN))
	if it.has("slots"): v.add_child(_kv("CARRY SLOTS", str(it.slots), Pal.TEXT))
	v.add_child(_kv("SOURCE", str(Config.items.get("source", {}).get(it.get("src", ""), it.get("src", ""))), Pal.TEXT))
	if it.has("set"): v.add_child(_kv("SET", str(it.set), Pal.SODIUM))
	if it.has("tr"):
		var warn := PanelContainer.new()
		warn.add_theme_stylebox_override("panel", Pal.sb(Color(Pal.DANGER_RED, 0.1), 8, Pal.DANGER_RED, 1, 0))
		var wm := MarginContainer.new()
		for s3 in ["left", "right", "top", "bottom"]: wm.add_theme_constant_override("margin_" + s3, 14)
		var wr := Pal.hbox(12)
		wr.add_child(Pal.label("TRADE-OFF", 18, Pal.DANGER_RED, 500))
		wr.add_child(Pal.text(str(it.tr), 20, Color("#E0C4BE"), 400, true))
		wm.add_child(wr); warn.add_child(wm); v.add_child(warn)
	# actions
	var acts := Pal.hbox(14)
	var cl := Pal.btn("CLOSE", "secondary", 84); cl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cl.pressed.connect(func(): Audio.ui(); close.call())
	acts.add_child(cl)
	var equippable: bool = it.get("slot", "") != "trophy" and it.get("slot", "") != "cons" and str(it.get("sh", "")) != "none"
	if equippable:
		var eq := Pal.btn("EQUIP", "hivis", 84); eq.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		eq.size_flags_stretch_ratio = 2.0
		eq.pressed.connect(func():
			Game.equip_item(str(it.id))
			Game.toast.emit("Fitted: %s" % str(it.n), Pal.CLEAN)
			close.call(); _rebuild())
		acts.add_child(eq)
	v.add_child(acts)
	m.add_child(v); p.add_child(m); wrap.add_child(p)

func _kv(k: String, val: String, col: Color) -> Control:
	var row := Pal.hbox(16)
	var kl := Pal.label(k, 18, Pal.MUTED, 500); kl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(kl)
	row.add_child(Pal.label(val, 20, col, 500))
	var line := PanelContainer.new(); line.add_theme_stylebox_override("panel", Pal.sb(Color(0, 0, 0, 0), 0, Pal.RAISED, 0, 0))
	var box := Pal.vbox(0); box.add_child(row)
	var sep := ColorRect.new(); sep.color = Color(Pal.RAISED, 0.6); sep.custom_minimum_size = Vector2(0, 1); box.add_child(sep)
	return box

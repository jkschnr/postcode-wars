class_name CharacterScreen
extends Control
## Your character (upgrade_05/character.html): identity header with POWER + cash +
## XP, a paperdoll on a brick backdrop flanked by ten equip slots that the doll
## reflects, the five attributes as bars (base marker + gear bonus), the derived
## fight numbers, set progress, and the bag of owned-not-worn gear. Tap a slot or
## a bag item to swap, with a live power comparison.

const LEFT := ["head", "face", "jacket", "top", "bottoms"]
const RIGHT := ["feet", "hands", "weapon", "body", "bag"]
const WEAR := ["head", "face", "jacket", "top", "bottoms", "feet", "hands", "weapon", "body", "bag"]
const STAT_ORDER := ["strength", "speed", "toughness", "slickness", "luck"]
const STAT_SHORT := {"strength": "STRENGTH", "speed": "SPEED", "toughness": "TOUGHNESS", "slickness": "SLICKNESS", "luck": "LUCK"}
const SC := {"strength": Color("#C2503F"), "speed": Color("#4DA3FF"), "toughness": Color("#D9E021"),
	"slickness": Color("#B06CF0"), "luck": Color("#6FCF6F")}
const SLOT_LABEL := {"head": "HEAD", "face": "FACE", "jacket": "JACKET", "top": "TOP", "bottoms": "LEGS",
	"feet": "FEET", "hands": "HANDS", "weapon": "WEAPON", "body": "BODY", "bag": "BAG"}

var _root: VBoxContainer
var _scroll: ScrollContainer
var _stats_node: Control
var focus_arg := ""            # "spend" → jump to + pulse the stat allocation (WO2-T12.3)

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var scroll := Pal.scroll()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(scroll)
	_scroll = scroll
	_root = Pal.vbox(16)
	_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_root)
	_build()
	if focus_arg == "spend" and int(Game.s.stat_points) > 0:
		_focus_stats.call_deferred()

## Scroll the attribute allocation into view and pulse it — the player arrived here
## from a level-up to spend points, so put the points under their thumb.
func _focus_stats() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	if not is_instance_valid(_stats_node) or not is_instance_valid(_scroll):
		return
	_scroll.ensure_control_visible(_stats_node)
	var pulse := create_tween().set_loops(4)
	pulse.tween_property(_stats_node, "modulate", Color(1.25, 1.25, 1.05), 0.4)
	pulse.tween_property(_stats_node, "modulate", Color(1, 1, 1), 0.4)

func _build() -> void:
	for c in _root.get_children(): c.queue_free()
	_root.add_child(_identity())
	_root.add_child(_doll_and_slots())
	_stats_node = _stats_block()
	_root.add_child(_stats_node)
	_root.add_child(_sets_block())
	_root.add_child(_bag_block())
	if not Game.owned_consumables().is_empty():
		_root.add_child(_stash_block())

# ---------- totals ----------
func _totals() -> Dictionary:
	var t := {}
	for k in STAT_ORDER: t[k] = int(Game.s.stats.get(k, 0))   # luck has no base
	var fb := Game.fit_bonus()
	for k in STAT_ORDER: t[k] = int(t[k]) + int(fb.get(k, 0))
	return t

func _power() -> int:
	var n := 0
	for k in _totals().values(): n += int(k)
	return n

func _set_count(name: String) -> int:
	var n := 0
	for k in WEAR:
		var it := Game.fitted_item(k)
		if not it.is_empty() and str(it.get("set", "")) == name: n += 1
	return n

# ---------- identity ----------
func _identity() -> Control:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", Pal.sb(Color("#15181C"), 12, Pal.RAISED, 1, 0))
	var m := MarginContainer.new()
	for s in ["left", "right", "top", "bottom"]: m.add_theme_constant_override("margin_" + s, 22)
	var v := Pal.vbox(14)
	var top := Pal.hbox(16)
	var who := Pal.vbox(2); who.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	who.add_child(Pal.label("%s · %s" % [str(Game.s.get("tag", Game.full_name())).to_upper(), str(Game.s.city).to_upper()], 18, Pal.SODIUM, 500))
	who.add_child(Pal.heading(Game.full_name().to_upper(), 44, Pal.TEXT))
	var sp := Specialisation.meta()
	if not sp.is_empty():
		who.add_child(Pal.label("%s · %s" % [Game.rank_name().to_upper(), str(sp.label)], 17, Color(str(sp.accent)), 500))
	else:
		who.add_child(Pal.label(Game.rank_name().to_upper(), 17, Pal.TEXT2, 500))
	top.add_child(who)
	var pw := Pal.vbox(2); pw.alignment = BoxContainer.ALIGNMENT_END
	pw.add_child(Pal.label("POWER", 16, Pal.MUTED, 500))
	pw.add_child(Pal.heading(str(_power()), 34, Pal.SODIUM))
	top.add_child(pw)
	var money := Pal.vbox(2); money.alignment = BoxContainer.ALIGNMENT_END
	money.add_child(Pal.label("ON YOU", 16, Pal.MUTED, 500))
	money.add_child(Pal.heading(Pal.money(Game.dirty()), 34, Pal.DIRTY))
	top.add_child(money)
	v.add_child(top)
	# level + xp bar
	var xp := Pal.hbox(12)
	xp.add_child(Pal.label("LVL %d" % Game.level(), 22, Pal.TEXT, 500))
	var cur := int(Game.s.get("xp_into", 0))
	var need: int = max(1, int(Game.xp_to_next())) if Game.has_method("xp_to_next") else 10000
	xp.add_child(_bar(clampf(float(cur) / float(need), 0.0, 1.0), Pal.SODIUM, 14))
	xp.add_child(Pal.label("%d / %d XP" % [cur, need], 18, Pal.MUTED, 500))
	v.add_child(xp)
	m.add_child(v); p.add_child(m)
	return p

# ---------- paperdoll + slots ----------
const SLOT_SZ := 116.0

func _doll_and_slots() -> Control:
	var band := Control.new()               # plain Control so children aren't force-stretched
	band.custom_minimum_size = Vector2(0, 640); band.clip_contents = true
	# background: dark wash + tiled brick + floor + warm rim light + vignette
	var bg := ColorRect.new(); bg.color = Color("#0E1114")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	band.add_child(bg)
	var brick := TextureRect.new()
	brick.texture = Pal.tex("res://art/tex/tex-brick.png")
	brick.stretch_mode = TextureRect.STRETCH_TILE
	brick.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	brick.modulate = Color(1, 1, 1, 0.35); brick.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	brick.mouse_filter = Control.MOUSE_FILTER_IGNORE
	band.add_child(brick)
	var floor := ColorRect.new(); floor.color = Color("#131511")
	floor.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE); floor.offset_top = -110
	floor.mouse_filter = Control.MOUSE_FILTER_IGNORE; band.add_child(floor)
	var rim := TextureRect.new(); rim.texture = Pal.radial_glow()
	rim.modulate = Color(1.0, 0.82, 0.45, 0.20)
	rim.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	rim.custom_minimum_size = Vector2(760, 760); rim.size = Vector2(760, 760)
	rim.position = Vector2(-380, -180); rim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	band.add_child(rim)
	# the doll — big, centred, standing on the floor line. Normal mode keeps the
	# idle blink alive; a slow bob makes it breathe (design: .doll-holder breathe).
	var dv := DollView.new()
	dv.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dv.offset_left = 300; dv.offset_right = -300; dv.offset_top = 24; dv.offset_bottom = -70
	dv.view = "full"; dv.set_cfg(_display_cfg())
	dv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	band.add_child(dv)
	var bob := create_tween().set_loops()
	bob.tween_property(dv, "position:y", 6.0, 2.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	bob.tween_property(dv, "position:y", 0.0, 1.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	# scanline overlay over the doll (design: .scan)
	var scan := _Scan.new()
	scan.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); scan.mouse_filter = Control.MOUSE_FILTER_IGNORE
	band.add_child(scan)
	# weapon in the hand
	var wid := Game.fitted("weapon")
	if wid != "" and not Config.item(wid).is_empty():
		var wep := ItemView.new(); wep.custom_minimum_size = Vector2(118, 118); wep.size = Vector2(118, 118)
		wep.pivot_offset = Vector2(59, 59); wep.rotation = deg_to_rad(62)
		wep.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		wep.position = Vector2(120, 40); wep.mouse_filter = Control.MOUSE_FILTER_IGNORE
		wep.set_item(Config.item(wid)); band.add_child(wep)
	# equip columns, pinned to each edge
	var lcol := Pal.vbox(9); lcol.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	lcol.offset_left = 16; lcol.offset_top = 16
	for slot in LEFT: lcol.add_child(_slot(slot))
	band.add_child(lcol)
	var rcol := Pal.vbox(9)
	rcol.anchor_left = 1.0; rcol.anchor_right = 1.0; rcol.anchor_top = 0.0; rcol.anchor_bottom = 0.0
	rcol.offset_left = -(SLOT_SZ + 16); rcol.offset_right = -16; rcol.offset_top = 16; rcol.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	for slot in RIGHT: rcol.add_child(_slot(slot))
	band.add_child(rcol)
	return band

func _slot(slot: String) -> Control:
	var it := Game.fitted_item(slot)
	var col: Color = ItemArt.RC.get(it.get("r", ""), Pal.RAISED) if not it.is_empty() else Pal.RAISED
	var b := Button.new()
	b.custom_minimum_size = Vector2(SLOT_SZ, SLOT_SZ); b.focus_mode = Control.FOCUS_NONE
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.add_theme_stylebox_override("normal", Pal.sb(Color("#101317", 0.9), 4, col, 2 if not it.is_empty() else 1, 0))
	b.add_theme_stylebox_override("hover", Pal.sb(Color("#161A1F", 0.95), 4, Pal.SODIUM, 2, 0))
	b.add_theme_stylebox_override("pressed", Pal.sb(Color("#101317", 0.9), 4, Pal.SODIUM, 2, 0))
	if not it.is_empty() and str(it.get("sh", "")) != "none":
		var iv := ItemView.new(); iv.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		var im := MarginContainer.new(); im.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); im.mouse_filter = Control.MOUSE_FILTER_IGNORE
		for s in ["left", "right", "top", "bottom"]: im.add_theme_constant_override("margin_" + s, 8)
		im.add_child(iv); b.add_child(im); iv.set_item(it)
	else:
		var lb := Pal.label(SLOT_LABEL.get(slot, slot), 14, Pal.MUTED, 500)
		lb.set_anchors_and_offsets_preset(Control.PRESET_CENTER); lb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(lb)
	# corner tag
	var tag := Pal.label(SLOT_LABEL.get(slot, slot), 12, Pal.TEXT2 if not it.is_empty() else Pal.MUTED, 500)
	tag.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE); tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tag.mouse_filter = Control.MOUSE_FILTER_IGNORE; tag.add_theme_constant_override("outline_size", 4)
	b.add_child(tag)
	b.pressed.connect(func(): _tap_slot(slot))
	return b

func _tap_slot(slot: String) -> void:
	Audio.ui()
	if Game.fitted(slot) != "": _open_equipped(slot)
	else: _open_picker(slot)

## The player's created look, with equipped gear reflected onto the doll.
func _display_cfg() -> Dictionary:
	var cfg: Dictionary = (Game.s.get("doll", Doll.DEF) as Dictionary).duplicate(true)
	var head := Game.fitted_item("head")
	if not head.is_empty():
		cfg["head"] = {"cap": 1, "beanie": 4, "trapper": 4, "bucket": 5, "rainhat": 5, "trilby": 5,
			"hood": 2, "hardhat": 1, "helmet": 1, "motolid": 1, "nursecap": 4, "balaclava": 2}.get(str(head.get("sh", "")), 0)
	var face := Game.fitted_item("face")
	if not face.is_empty():
		var fsh := str(face.get("sh", ""))
		cfg["facewear"] = {"gaiter": 1, "mask": 2, "balaclava": 3, "respirator": 4}.get(fsh, 0)
		if fsh == "gaiter" and face.get("v", {}).get("scarf", false): cfg["facewear"] = 5
	var jk := Game.fitted_item("jacket")
	if not jk.is_empty():
		var jv: Dictionary = jk.get("v", {})
		var col := str(jk.get("c", ""))
		cfg["top"] = 1 if jv.get("baffles", false) else (2 if jv.get("collar", "") == "hood" else (5 if jv.get("sleeveless", false) else (4 if jv.get("collar", "") == "lapel" else (0 if jv.get("stripes", false) else 3))))
		if col == "hivis" or col == "orange": cfg["clothc"] = 7
		elif col == "denim": cfg["clothc"] = 0
		elif col == "grey" or col == "lgrey": cfg["clothc"] = 5
	return cfg

# ---------- stats ----------
func _stats_block() -> Control:
	var box := Pal.panel()
	var m := MarginContainer.new()
	for s in ["left", "right", "top", "bottom"]: m.add_theme_constant_override("margin_" + s, 20)
	var v := Pal.vbox(12)
	var head := Pal.hbox(10)
	head.add_child(Pal.label("WHAT YOU'RE MADE OF", 20, Pal.SODIUM, 500))
	var sp := Control.new(); sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL; head.add_child(sp)
	var filled := 0
	for k in WEAR: if Game.fitted(k) != "": filled += 1
	head.add_child(Pal.label("%d OF %d SLOTS FILLED" % [filled, WEAR.size()], 18, Pal.MUTED, 500))
	v.add_child(head)
	var t := _totals()
	var mx := 1
	for k in STAT_ORDER: mx = max(mx, int(t[k]))
	for k in STAT_ORDER:
		v.add_child(_stat_line(k, int(Game.s.stats.get(k, 0)), int(t[k]), mx))
	# derived fight numbers (design formulas)
	var grid := GridContainer.new(); grid.columns = 4
	grid.add_theme_constant_override("h_separation", 10); grid.add_theme_constant_override("v_separation", 10)
	grid.add_child(_deriv("HEALTH", str(120 + int(t.toughness) * 9)))
	grid.add_child(_deriv("HIT", str(int(round(int(t.strength) * 1.4 + 6)))))
	grid.add_child(_deriv("GETAWAY", "%d%%" % min(96, 34 + int(t.speed))))
	grid.add_child(_deriv("HEAT SHED", "%d%%" % min(70, int(round(int(t.slickness) * 0.9)))))
	v.add_child(grid)
	m.add_child(v); box.add_child(m)
	return box

func _stat_line(key: String, base: int, total: int, mx: int) -> Control:
	var row := Pal.hbox(12)
	var dot := ColorRect.new(); dot.color = SC[key]; dot.custom_minimum_size = Vector2(12, 12)
	dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER; row.add_child(dot)
	var nm := Pal.label(STAT_SHORT[key], 18, Pal.TEXT2, 500); nm.custom_minimum_size = Vector2(140, 0)
	row.add_child(nm)
	var bar := _bar(clampf(float(total) / float(mx), 0.0, 1.0), SC[key], 12)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# base marker
	var marker := ColorRect.new(); marker.color = Color(1, 1, 1, 0.4); marker.custom_minimum_size = Vector2(2, 12)
	marker.set_anchors_and_offsets_preset(Control.PRESET_LEFT_WIDE)
	marker.anchor_left = clampf(float(base) / float(mx), 0.0, 1.0); marker.anchor_right = marker.anchor_left
	marker.offset_left = 0; marker.offset_right = 2
	bar.add_child(marker)
	row.add_child(bar)
	row.add_child(Pal.heading(str(total), 22, Pal.TEXT))
	var gear := total - base
	row.add_child(Pal.label("+%d" % gear if gear > 0 else "—", 18, Pal.CLEAN if gear > 0 else Pal.MUTED, 500))
	return row

func _deriv(cap: String, val: String) -> Control:
	var p := Pal.inset_panel()
	var m := MarginContainer.new()
	for s in ["left", "right", "top", "bottom"]: m.add_theme_constant_override("margin_" + s, 12)
	var v := Pal.vbox(4)
	v.add_child(Pal.label(cap, 15, Pal.MUTED, 500))
	v.add_child(Pal.heading(val, 28, Pal.TEXT))
	m.add_child(v); p.add_child(m)
	return p

# ---------- sets ----------
func _sets_block() -> Control:
	var box := Pal.vbox(8)
	box.add_child(Pal.label("SETS", 20, Pal.SODIUM, 500))
	for st in Config.items.get("sets", []):
		var setcol := Color(str(st.c))
		var n := _set_count(str(st.n))
		var on3 := n >= 3; var on5 := n >= 5
		var p := PanelContainer.new()
		p.add_theme_stylebox_override("panel", Pal.sb(Color("#15181C"), 8, Color(setcol, 0.55) if on3 else Pal.RAISED, 1, 0))
		var m := MarginContainer.new()
		m.add_theme_constant_override("margin_left", 14); m.add_theme_constant_override("margin_right", 14)
		m.add_theme_constant_override("margin_top", 10); m.add_theme_constant_override("margin_bottom", 10)
		var row := Pal.hbox(12)
		var pips := Pal.hbox(4)
		for i in range(5):
			var pip := ColorRect.new(); pip.color = setcol if i < n else Color("#22262A"); pip.custom_minimum_size = Vector2(12, 12)
			pip.size_flags_vertical = Control.SIZE_SHRINK_CENTER; pips.add_child(pip)
		row.add_child(pips)
		var nm := Pal.label(str(st.n), 18, setcol if on3 else Pal.TEXT2, 500); nm.custom_minimum_size = Vector2(220, 0)
		row.add_child(nm)
		var desc := Pal.text(str(st.b5) if on5 else str(st.b3), 17, Pal.TEXT if on5 else (Pal.TEXT2 if on3 else Pal.MUTED), 400, true)
		desc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(desc)
		row.add_child(Pal.label("5PC" if on5 else ("3PC" if on3 else "%d/5" % n), 16, setcol if on3 else Pal.MUTED, 500))
		m.add_child(row); p.add_child(m)
		box.add_child(p)
	return box

# ---------- bag ----------
func _bag_items() -> Array:
	var out: Array = []
	for id in Game.s.get("wardrobe", []):
		var it := Config.item(str(id))
		if it.is_empty(): continue
		if Game.fitted(str(it.get("slot", ""))) == str(id): continue   # worn, not in bag
		out.append(it)
	return out

func _bag_block() -> Control:
	var box := Pal.vbox(12)
	var head := Pal.hbox(10)
	head.add_child(Pal.heading("IN THE BAG", 30, Pal.TEXT))
	var sp := Control.new(); sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL; head.add_child(sp)
	var items := _bag_items()
	head.add_child(Pal.label("%d ITEMS" % items.size(), 18, Pal.MUTED, 500))
	box.add_child(head)
	if items.is_empty():
		box.add_child(Pal.text("Nothing spare. Win gear on The Street or buy it in the shop, then swap it in here.", 20, Pal.TEXT2, 400, true))
		return box
	var grid := GridContainer.new(); grid.columns = 6
	grid.add_theme_constant_override("h_separation", 10); grid.add_theme_constant_override("v_separation", 10)
	var i := 0
	for it in items:
		var cell := _bag_cell(it)
		grid.add_child(cell)
		cell.modulate.a = 0.0; cell.scale = Vector2(0.92, 0.92); cell.pivot_offset = Vector2(60, 65)
		var t := create_tween().set_parallel(true)
		t.tween_interval(min(i, 14) * 0.02)
		t.chain().tween_property(cell, "modulate:a", 1.0, 0.22)
		t.parallel().tween_property(cell, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_CUBIC)
		i += 1
	box.add_child(grid)
	return box

# ---------- stash (consumables) ----------
func _stash_block() -> Control:
	var box := Pal.vbox(12)
	box.add_child(Pal.heading("STASH", 30, Pal.TEXT))
	var grid := GridContainer.new(); grid.columns = 6
	grid.add_theme_constant_override("h_separation", 10); grid.add_theme_constant_override("v_separation", 10)
	for id in Game.owned_consumables():
		var it := Config.item(id)
		if it.is_empty(): continue
		var col: Color = ItemArt.RC.get(it.get("r", "Ba"), Pal.TEXT)
		var b := Button.new(); b.custom_minimum_size = Vector2(0, 130); b.focus_mode = Control.FOCUS_NONE
		b.add_theme_stylebox_override("normal", Pal.sb(Color("#101317"), 6, Color(col, 0.5), 2, 0))
		b.add_theme_stylebox_override("hover", Pal.sb(Color("#161A1F"), 6, Pal.SODIUM, 2, 0))
		var iv := ItemView.new(); iv.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		var im := MarginContainer.new(); im.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); im.mouse_filter = Control.MOUSE_FILTER_IGNORE
		for s in ["left", "right", "top", "bottom"]: im.add_theme_constant_override("margin_" + s, 10)
		im.add_child(iv); b.add_child(im); iv.set_item(it)
		var qty := Pal.label("×%d" % Game.consumable_qty(str(id)), 16, Pal.TEXT, 500)
		qty.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT); qty.position = Vector2(-30, -22)
		qty.mouse_filter = Control.MOUSE_FILTER_IGNORE; b.add_child(qty)
		var this_id := str(id)
		b.pressed.connect(func(): _open_consumable(this_id))
		grid.add_child(b)
	box.add_child(grid)
	return box

func _open_consumable(id: String) -> void:
	Audio.ui()
	var it := Config.item(id)
	var col: Color = ItemArt.RC.get(it.get("r", "Ba"), Pal.TEXT)
	var dim := ColorRect.new(); dim.color = Color(0.02, 0.03, 0.04, 0.82)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); dim.mouse_filter = Control.MOUSE_FILTER_STOP
	App.I.overlay.add_child(dim)
	var close := func(): dim.queue_free()
	var wrap := CenterContainer.new(); wrap.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dim.add_child(wrap)
	var p := PanelContainer.new(); p.custom_minimum_size = Vector2(860, 0)
	p.add_theme_stylebox_override("panel", Pal.sb(Color(Pal.RAISED, 0.98), 16, col, 2, 0))
	var m := MarginContainer.new()
	for s in ["left", "right", "top", "bottom"]: m.add_theme_constant_override("margin_" + s, 30)
	var v := Pal.vbox(16)
	var top := Pal.hbox(20)
	var well := PanelContainer.new(); well.custom_minimum_size = Vector2(150, 150)
	well.add_theme_stylebox_override("panel", Pal.sb(Color("#101317"), 8, col, 2, 0)); well.clip_contents = true
	var iv := ItemView.new(); iv.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var im := MarginContainer.new(); im.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for s in ["left", "right", "top", "bottom"]: im.add_theme_constant_override("margin_" + s, 12)
	im.add_child(iv); well.add_child(im); iv.set_item(it); top.add_child(well)
	var info := Pal.vbox(6); info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_child(Pal.label("CONSUMABLE · ×%d HELD" % Game.consumable_qty(id), 16, col, 500))
	info.add_child(Pal.heading(str(it.n), 34, Pal.TEXT))
	info.add_child(Pal.label(str(it.get("st", "")), 20, Pal.SODIUM, 500))
	info.add_child(Pal.text(str(it.get("d", "")), 18, Pal.TEXT2, 400, true))
	top.add_child(info)
	v.add_child(top)
	var acts := Pal.hbox(14)
	var cl := Pal.btn("KEEP IT", "secondary", 84); cl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cl.pressed.connect(func(): Audio.ui(); close.call())
	acts.add_child(cl)
	var use := Pal.btn("USE IT", "hivis", 84); use.size_flags_horizontal = Control.SIZE_EXPAND_FILL; use.size_flags_stretch_ratio = 2.0
	use.pressed.connect(func():
		var res := Game.use_consumable(id)
		if res.get("ok", false): Audio.cash(); Game.toast.emit("%s · %s" % [str(it.n), str(res.msg)], Pal.CLEAN)
		else: Audio.error(); Game.toast.emit(str(res.get("msg", "Can't use that now")), Pal.TEXT2)
		close.call(); _build())
	acts.add_child(use)
	v.add_child(acts)
	m.add_child(v); p.add_child(m); wrap.add_child(p)

func _bag_cell(it: Dictionary) -> Control:
	var col: Color = ItemArt.RC.get(it.get("r", "Ba"), Pal.TEXT)
	var b := Button.new(); b.custom_minimum_size = Vector2(0, 130); b.focus_mode = Control.FOCUS_NONE
	b.add_theme_stylebox_override("normal", Pal.sb(Color("#101317"), 6, Color(col, 0.5), 2, 0))
	b.add_theme_stylebox_override("hover", Pal.sb(Color("#161A1F"), 6, Pal.SODIUM, 2, 0))
	var iv := ItemView.new(); iv.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var im := MarginContainer.new(); im.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); im.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for s in ["left", "right", "top", "bottom"]: im.add_theme_constant_override("margin_" + s, 10)
	im.add_child(iv); b.add_child(im); iv.set_item(it)
	b.pressed.connect(func(): _open_bag(it))
	return b

# ---------- sheets ----------
func _open_equipped(slot: String) -> void:
	var it := Game.fitted_item(slot)
	var e := Econ.of(it)
	var body := _item_head(it, SLOT_LABEL.get(slot, slot)) + _stat_rows(it, {})
	_sheet(body, [
		{"t": "TOTAL POWER", "v": "+%d" % int(e.power), "c": Pal.TEXT},
		{"t": "SELLS BACK FOR", "v": Pal.money(int(e.sell)), "c": Pal.TEXT2}],
		it, "TAKE IT OFF", func(): Game.unequip_slot(slot); Game.toast.emit("%s — off" % it.n, Pal.TEXT2); _build())

func _open_bag(it: Dictionary) -> void:
	var slot := str(it.get("slot", ""))
	var e := Econ.of(it)
	var cur := Game.fitted_item(slot)
	var body := _item_head(it, SLOT_LABEL.get(slot, slot)) + _stat_rows(it, cur)
	var kvs := [{"t": "TOTAL POWER", "v": "+%d" % int(e.power), "c": Pal.TEXT},
		{"t": "SELLS BACK FOR", "v": Pal.money(int(e.sell)), "c": Pal.TEXT2}]
	if not cur.is_empty():
		var diff := int(e.power) - int(Econ.of(cur).power)
		kvs.append({"t": "REPLACES %s" % str(cur.n).to_upper(), "v": ("+%d POWER" % diff) if diff >= 0 else ("%d POWER" % diff), "c": Pal.CLEAN if diff >= 0 else Pal.DANGER_RED})
	var lvl_ok: bool = Game.level() >= int(e.lvl)
	var lbl := "SWAP IT IN" if not cur.is_empty() else "PUT IT ON"
	if not lvl_ok: lbl = "NEED LEVEL %d" % int(e.lvl)
	_sheet(body, kvs, it, lbl, func():
		if not lvl_ok: return
		Game.equip_item(str(it.id)); Game.toast.emit("%s — on" % it.n, Pal.CLEAN); _build())

func _stat_rows(it: Dictionary, cmp: Dictionary) -> String:
	# returns "" — stat rows are built as nodes; handled in _sheet via _stat_node
	return ""

func _sheet(_body_ignored: String, kvs: Array, it: Dictionary, action: String, on_action: Callable) -> void:
	var col: Color = ItemArt.RC.get(it.get("r", "Ba"), Pal.TEXT)
	var dim := ColorRect.new(); dim.color = Color(0.02, 0.03, 0.04, 0.82)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); dim.mouse_filter = Control.MOUSE_FILTER_STOP
	App.I.overlay.add_child(dim)
	var close := func(): dim.queue_free()
	var wrap := CenterContainer.new(); wrap.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dim.add_child(wrap)
	var p := PanelContainer.new(); p.custom_minimum_size = Vector2(940, 0)
	p.add_theme_stylebox_override("panel", Pal.sb(Color(Pal.RAISED, 0.98), 16, col, 2, 0))
	var m := MarginContainer.new()
	for s in ["left", "right", "top", "bottom"]: m.add_theme_constant_override("margin_" + s, 30)
	var v := Pal.vbox(16)
	# header
	var top := Pal.hbox(20)
	var well := PanelContainer.new(); well.custom_minimum_size = Vector2(176, 176)
	well.add_theme_stylebox_override("panel", Pal.sb(Color("#101317"), 8, col, 2, 0)); well.clip_contents = true
	var iv := ItemView.new(); iv.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var im := MarginContainer.new(); im.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for s in ["left", "right", "top", "bottom"]: im.add_theme_constant_override("margin_" + s, 12)
	im.add_child(iv); well.add_child(im); iv.set_item(it); top.add_child(well)
	var info := Pal.vbox(8); info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_child(Pal.label("%s · LVL %d" % [str(Config.items.get("rarity", {}).get(it.get("r", "Ba"), "BASIC")), int(Econ.lvl(it))], 18, col, 500))
	info.add_child(Pal.heading(str(it.n), 36, Pal.TEXT))
	info.add_child(Pal.text(str(it.get("d", "")), 20, Pal.TEXT2, 400, true))
	top.add_child(info)
	v.add_child(top)
	# stat rows
	for srow in Econ.of(it).stats:
		var r := Pal.hbox(10)
		var dot := ColorRect.new(); dot.color = SC.get(Econ.STAT_KEY[srow.k], Pal.TEXT); dot.custom_minimum_size = Vector2(10, 10)
		dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER; r.add_child(dot)
		r.add_child(Pal.label(str(srow.label), 18, Pal.TEXT2, 500))
		var sp := Control.new(); sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL; r.add_child(sp)
		r.add_child(Pal.heading("+%d" % int(srow.v), 22, Pal.TEXT))
		v.add_child(r)
	# kv rows
	for kv in kvs:
		var r := Pal.hbox(12)
		var l := Pal.label(str(kv.t), 18, Pal.MUTED, 500); l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		r.add_child(l)
		r.add_child(Pal.label(str(kv.v), 20, kv.get("c", Pal.TEXT), 500))
		v.add_child(r)
	if it.has("tr"):
		var warn := PanelContainer.new()
		warn.add_theme_stylebox_override("panel", Pal.sb(Color(Pal.DANGER_RED, 0.1), 8, Pal.DANGER_RED, 1, 0))
		var wm := MarginContainer.new()
		for s in ["left", "right", "top", "bottom"]: wm.add_theme_constant_override("margin_" + s, 14)
		var wr := Pal.hbox(12); wr.add_child(Pal.label("TRADE-OFF", 18, Pal.DANGER_RED, 500))
		wr.add_child(Pal.text(str(it.tr), 18, Color("#E0C4BE"), 400, true))
		wm.add_child(wr); warn.add_child(wm); v.add_child(warn)
	# actions
	var acts := Pal.hbox(14)
	var cl := Pal.btn("LEAVE IT", "secondary", 84); cl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cl.pressed.connect(func(): Audio.ui(); close.call())
	acts.add_child(cl)
	var act := Pal.btn(action, "hivis", 84); act.size_flags_horizontal = Control.SIZE_EXPAND_FILL; act.size_flags_stretch_ratio = 2.0
	act.pressed.connect(func(): Audio.ui(); on_action.call(); close.call())
	acts.add_child(act)
	v.add_child(acts)
	# sell it back — anything you own that isn't an unsellable story piece
	var sellable: bool = Game.owns_item(str(it.get("id", ""))) and str(it.get("sh", "")) != "none" and not (str(it.get("tr", "")) == "unsellable")
	if sellable:
		var sb := Pal.btn("SELL FOR %s" % Pal.money(int(Econ.of(it).sell)), "danger", 76)
		sb.pressed.connect(func():
			var got := Game.sell_gear(str(it.id))
			Audio.cash(); Game.toast.emit("Sold %s · +%s" % [str(it.n), Pal.money(got)], Pal.DIRTY)
			close.call(); _build())
		v.add_child(sb)
	m.add_child(v); p.add_child(m); wrap.add_child(p)

func _item_head(_it: Dictionary, _label: String) -> String:
	return ""

# ---------- picker for empty slots ----------
func _open_picker(slot: String) -> void:
	var owned: Array = []
	for id in Game.s.get("wardrobe", []):
		var it := Config.item(str(id))
		if not it.is_empty() and str(it.get("slot", "")) == slot and Game.fitted(slot) != str(id):
			owned.append(it)
	if owned.is_empty():
		Game.toast.emit("Nothing for that slot yet — try the shop", Pal.TEXT2); return
	# reuse the bag sheet on the first, or just show a quick list
	_open_bag(owned[0]) if owned.size() == 1 else _slot_list(slot, owned)

func _slot_list(slot: String, owned: Array) -> void:
	var dim := ColorRect.new(); dim.color = Color(0.02, 0.03, 0.04, 0.82)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); dim.mouse_filter = Control.MOUSE_FILTER_STOP
	App.I.overlay.add_child(dim)
	var close := func(): dim.queue_free()
	var wrap := CenterContainer.new(); wrap.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dim.add_child(wrap)
	var p := PanelContainer.new(); p.custom_minimum_size = Vector2(900, 0)
	p.add_theme_stylebox_override("panel", Pal.sb(Color(Pal.RAISED, 0.98), 16, Pal.SODIUM, 1, 0))
	var m := MarginContainer.new()
	for s in ["left", "right", "top", "bottom"]: m.add_theme_constant_override("margin_" + s, 28)
	var v := Pal.vbox(12)
	v.add_child(Pal.heading("PUT ON — %s" % SLOT_LABEL.get(slot, slot), 32, Pal.TEXT))
	var grid := GridContainer.new(); grid.columns = 4
	grid.add_theme_constant_override("h_separation", 10); grid.add_theme_constant_override("v_separation", 10)
	for it in owned:
		var this_id := str(it.id)
		var cell := Button.new(); cell.custom_minimum_size = Vector2(0, 150); cell.focus_mode = Control.FOCUS_NONE
		cell.add_theme_stylebox_override("normal", Pal.sb(Color("#15181C"), 8, Color(ItemArt.RC.get(it.get("r", "Ba"), Pal.TEXT), 0.5), 2, 0))
		var cv := VBoxContainer.new(); cv.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); cv.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var iv := ItemView.new(); iv.custom_minimum_size = Vector2(0, 104); iv.set_item(it); cv.add_child(iv)
		cv.add_child(Pal.label(str(it.n), 13, Pal.TEXT2, 500))
		cell.add_child(cv)
		cell.pressed.connect(func(): Game.equip_item(this_id); close.call(); _build())
		grid.add_child(cell)
	v.add_child(grid)
	var cl := Pal.btn("CLOSE", "secondary", 72); cl.pressed.connect(func(): close.call())
	v.add_child(cl)
	m.add_child(v); p.add_child(m); wrap.add_child(p)

# ---------- shared ----------
## Faint scanline overlay over the doll plate (design: .scan).
class _Scan extends Control:
	func _draw() -> void:
		var y := 0.0
		while y < size.y:
			draw_rect(Rect2(0, y, size.x, 2), Color(0, 0, 0, 0.26))
			y += 8.0
	func _notification(what: int) -> void:
		if what == NOTIFICATION_RESIZED: queue_redraw()

func _bar(frac: float, col: Color, h: int) -> Control:
	var track := PanelContainer.new(); track.custom_minimum_size = Vector2(0, h)
	track.add_theme_stylebox_override("panel", Pal.sb(Color("#22262A"), int(h / 2.0), Color(0, 0, 0, 0), 0, 0))
	track.clip_contents = true
	var fill := ColorRect.new(); fill.color = col
	fill.set_anchors_and_offsets_preset(Control.PRESET_LEFT_WIDE)
	fill.anchor_right = clampf(frac, 0.0, 1.0); fill.offset_right = 0
	track.add_child(fill)
	return track

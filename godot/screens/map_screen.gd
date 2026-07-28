class_name MapScreen
extends Control
## Main map (upgrade_02): the country as a colour map of who holds what. Faction
## influence blooms, supply/money/heat flow lines, nodes carrying a jobs arc +
## heat pulse, split-bar labels, a selected-city sheet with the NPCs on that
## manor, and a factions-held legend. Real geography via the baked UK basemap.

const BASE := "res://art/ui/ukmap_real.png"
var _area: Control
var _world: Control          # pans + zooms; holds basemap, blooms, lines, markers
var _bloom: _Bloom
var _lines: _Lines
var _markers := {}
var _sheet_host: Control
var _zoom := 1.0
var _pan := Vector2.ZERO
var _dragging := false
var _drag_moved := false
var _last := Vector2.ZERO
var _sel := "London"
var _expanded := false

func _cities() -> Array: return Config.map_cities.get("cities", [])
func _by_name(n: String) -> Dictionary:
	for c in _cities():
		if c.get("name", "") == n: return c
	return {}
func _top(c: Dictionary) -> Array:
	var e: Array = c.get("hold", {}).keys()
	e.sort_custom(func(a, b): return int(c.hold[a]) > int(c.hold[b]))
	return [e[0], int(c.hold[e[0]])] if e.size() > 0 else ["trade", 0]

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_sel = "London"
	var sea := ColorRect.new(); sea.color = Color("#07080A")
	sea.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); add_child(sea)
	_area = Control.new(); _area.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); _area.clip_contents = true
	_area.mouse_filter = Control.MOUSE_FILTER_STOP
	_area.gui_input.connect(_on_map_input)
	add_child(_area)
	# the world layer pans + zooms; everything geographic lives inside it
	_world = Control.new(); _world.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_world.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_area.add_child(_world)
	var img := TextureRect.new()
	img.texture = Pal.tex(BASE)
	img.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	img.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	img.modulate = Color(0.60, 0.50, 0.34)  # warm sodium grade — matches the city/creation screens
	_world.add_child(img)
	var wash := ColorRect.new(); wash.color = Color(0.05, 0.045, 0.05, 0.34)
	wash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); wash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_world.add_child(wash)
	# a soft sodium pool over the map centre, like the graded street screens
	var pool := TextureRect.new()
	pool.texture = Pal.radial_glow()
	pool.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pool.offset_left = 120; pool.offset_top = 120; pool.offset_right = -120; pool.offset_bottom = -300
	pool.stretch_mode = TextureRect.STRETCH_SCALE; pool.modulate = Color(Pal.SODIUM, 0.10)
	pool.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var pm := CanvasItemMaterial.new(); pm.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD; pool.material = pm
	_world.add_child(pool)

	# influence blooms (additive) + flow lines
	_bloom = _Bloom.new(); _bloom.screen = self
	_bloom.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); _bloom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := CanvasItemMaterial.new(); mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_bloom.material = mat
	_world.add_child(_bloom)
	_lines = _Lines.new(); _lines.screen = self
	_lines.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); _lines.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_world.add_child(_lines)

	# top fade so labels read
	var fade := ColorRect.new()
	fade.color = Color(0, 0, 0, 0)
	fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade.material = _fade_mat()
	# (skip shader fade; use two gradients via ColorRects)
	var topfade := ColorRect.new(); topfade.color = Color("#07080A")
	topfade.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE); topfade.offset_bottom = 300
	topfade.modulate.a = 0.0; _area.add_child(topfade)

	# title
	var title := Pal.vbox(8); title.position = Vector2(32, 24)
	title.add_child(Pal.label("THE MANOR · CONTESTED", 20, Pal.SODIUM, 500))
	title.add_child(Pal.heading("THIRTEEN CITIES", 68, Pal.TEXT))
	var trow := Pal.hbox(10)
	trow.add_child(Pal.label("TERRITORY", 18, Pal.TEXT2, 500))
	trow.add_child(_territory_bar())
	title.add_child(trow)
	_area.add_child(title)

	# legend (top-right)
	var legend := Pal.vbox(8); legend.alignment = BoxContainer.ALIGNMENT_END
	legend.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT); legend.position = Vector2(-300, 28)
	legend.custom_minimum_size = Vector2(268, 0)
	legend.add_child(_legend_row())
	legend.add_child(_lines_legend())
	_area.add_child(legend)

	# markers
	for c in _cities():
		_add_marker(c)
	_area.resized.connect(_place)
	call_deferred("_place")
	call_deferred("_center_current")
	_replace_after_layout()

func _replace_after_layout() -> void:
	# labels need a layout pass before their measured size is valid — re-run the
	# collision solver once frames have settled, same as the design's timed re-runs
	await get_tree().process_frame
	await get_tree().process_frame
	_place()

	# bottom fade so the map dissolves into the sheet instead of being chopped by it
	var botfade := TextureRect.new()
	var bg := Gradient.new()
	bg.offsets = PackedFloat32Array([0.0, 1.0])
	bg.colors = PackedColorArray([Color("#07080A", 0.0), Color("#07080A", 0.96)])
	var bt := GradientTexture2D.new(); bt.gradient = bg; bt.fill_from = Vector2(0, 0); bt.fill_to = Vector2(0, 1); bt.width = 8; bt.height = 256
	botfade.texture = bt
	botfade.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	botfade.offset_top = -340; botfade.stretch_mode = TextureRect.STRETCH_SCALE
	botfade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(botfade)

	# selected-city sheet
	_sheet_host = Control.new()
	_sheet_host.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_sheet_host.offset_left = 24; _sheet_host.offset_right = -24; _sheet_host.offset_top = -430; _sheet_host.offset_bottom = -24
	add_child(_sheet_host)
	_build_sheet()

func _fade_mat() -> Material: return null

# ---------- territory + legend ----------
func _faction_totals() -> Dictionary:
	var t := {}
	for c in _cities():
		for f in c.get("hold", {}).keys():
			t[f] = int(t.get(f, 0)) + int(c.hold[f])
	return t

func _territory_bar() -> Control:
	var totals := _faction_totals()
	var sum := 0
	for k in totals.keys(): sum += int(totals[k])
	var track := PanelContainer.new()
	track.add_theme_stylebox_override("panel", Pal.sb(Pal.INSET, 6, Pal.RAISED, 1, 0))
	track.custom_minimum_size = Vector2(220, 14); track.clip_contents = true
	var row := HBoxContainer.new(); row.add_theme_constant_override("separation", 0)
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var order: Array = totals.keys()
	order.sort_custom(func(a, b): return int(totals[a]) > int(totals[b]))
	for f in order:
		var seg := ColorRect.new(); seg.color = Pal.faction_col(f)
		seg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		seg.size_flags_stretch_ratio = float(totals[f])
		row.add_child(seg)
	track.add_child(row)
	return track

func _legend_row() -> Control:
	var totals := _faction_totals()
	var order: Array = totals.keys()
	order.sort_custom(func(a, b): return int(totals[a]) > int(totals[b]))
	var v := Pal.vbox(8); v.alignment = BoxContainer.ALIGNMENT_END
	v.add_child(Pal.label("HELD BY", 18, Pal.MUTED, 500))
	for f in order:
		var h := Pal.hbox(10); h.alignment = BoxContainer.ALIGNMENT_END
		h.add_child(Pal.label(Pal.faction_label(f), 18, Pal.TEXT2, 500))
		var dot := ColorRect.new(); dot.color = Pal.faction_col(f); dot.custom_minimum_size = Vector2(28, 8); dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(dot)
		v.add_child(h)
	return v

func _lines_legend() -> Control:
	var v := Pal.vbox(8); v.alignment = BoxContainer.ALIGNMENT_END
	v.add_child(Pal.label("LINES", 18, Pal.MUTED, 500))
	for pair in [["SUPPLY", Pal.faction_col("vale")], ["MONEY", Pal.faction_col("rhodes")], ["HEAT", Pal.DANGER_RED]]:
		var h := Pal.hbox(10); h.alignment = BoxContainer.ALIGNMENT_END
		h.add_child(Pal.label(pair[0], 18, Pal.TEXT2, 500))
		var dash := ColorRect.new(); dash.color = pair[1]; dash.custom_minimum_size = Vector2(28, 3); dash.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(dash)
		v.add_child(h)
	return v

# ---------- markers ----------
func _radius(c: Dictionary) -> int:
	if c.get("state", "") == "current": return 54
	return 22 if c.get("tier", "city") == "town" else 38

func _add_marker(c: Dictionary) -> void:
	var m := Control.new(); m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sz := _radius(c) * 2
	var node := _Node.new(); node.c = c
	node.custom_minimum_size = Vector2(sz, sz); node.size = Vector2(sz, sz); node.position = Vector2(-sz / 2.0, -sz / 2.0)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	m.add_child(node)
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(sz + 20, sz + 20); btn.position = Vector2(-(sz + 20) / 2.0, -(sz + 20) / 2.0)
	btn.flat = true; btn.focus_mode = Control.FOCUS_NONE; btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.add_theme_stylebox_override("normal", Pal.sb(Color(0, 0, 0, 0), 0))
	btn.add_theme_stylebox_override("hover", Pal.sb(Color(0, 0, 0, 0), 0))
	btn.add_theme_stylebox_override("pressed", Pal.sb(Color(0, 0, 0, 0), 0))
	btn.pressed.connect(func(): _select(c.name))
	m.add_child(btn)
	# label
	var lab := _label(c)
	m.add_child(lab)
	_world.add_child(m)
	_markers[c.name] = {"node": m, "c": c, "label": lab, "sz": sz}

func _label(c: Dictionary) -> Control:
	var locked: bool = c.get("state", "") == "locked"
	var tf := _top(c)
	var accent: Color = Pal.MUTED if locked else Pal.faction_col(tf[0])
	# a dark rounded chip behind the text so labels stay readable over the map glow
	var chip := PanelContainer.new(); chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := Pal.sb(Color("#0B0D10", 0.82), 10, Color(accent, 0.55), 1, 0)
	sb.border_width_left = 4; sb.border_color = accent
	sb.content_margin_left = 14; sb.content_margin_right = 14
	sb.content_margin_top = 8; sb.content_margin_bottom = 8
	chip.add_theme_stylebox_override("panel", sb)
	var v := Pal.vbox(4); v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var big: int = 40 if c.get("state", "") == "current" else (22 if c.get("tier", "city") == "town" else 30)
	v.add_child(Pal.heading(String(c.name).to_upper(), big, Pal.MUTED if locked else Pal.TEXT))
	# split bar
	var bar := HBoxContainer.new(); bar.add_theme_constant_override("separation", 2); bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var hold: Dictionary = c.get("hold", {})
	var order: Array = hold.keys(); order.sort_custom(func(a, b): return int(hold[a]) > int(hold[b]))
	for f in order:
		var seg := ColorRect.new(); seg.color = Pal.faction_col(f)
		seg.custom_minimum_size = Vector2(int(hold[f]) * (0.6 if c.get("tier","city")=="town" else 0.9), 5)
		bar.add_child(seg)
	v.add_child(bar)
	v.add_child(Pal.label("%s %d%%" % [Pal.faction_label(tf[0]), int(tf[1])], 15, accent, 500))
	if c.get("state", "") in ["current", "ready"]:
		v.add_child(Pal.label("%s/DAY · HEAT %d" % [c.get("take", "£0"), int(c.get("heat", 0))], 15, Pal.TEXT2, 400))
	chip.add_child(v)
	return chip

func _img_rect() -> Rect2:
	var tex := Pal.tex(BASE)
	if tex == null: return Rect2(Vector2.ZERO, _area.size)
	var ts := Vector2(tex.get_width(), tex.get_height())
	var a := _area.size
	var scale: float = max(a.x / ts.x, a.y / ts.y)
	var draw := ts * scale
	return Rect2((a - draw) / 2.0, draw)

func city_pt(c: Dictionary) -> Vector2:
	var r := _img_rect()
	return r.position + Vector2(float(c.x) * r.size.x, float(c.y) * r.size.y)

func _hits(a: Rect2, b: Rect2, pad: float) -> bool:
	return a.position.x < b.position.x + b.size.x + pad and a.position.x + a.size.x + pad > b.position.x \
		and a.position.y < b.position.y + b.size.y + pad and a.position.y + a.size.y + pad > b.position.y

## Measured, collision-free label placement — mirrors upgrade_02/main-map.html:
## eight candidate slots per node, scored against already-placed labels and every
## node circle, biggest/most-important cities placed first so they win the best slot.
func _place() -> void:
	var pts := {}
	var circles: Array = []
	for name in _markers.keys():
		var mk = _markers[name]
		var p := city_pt(mk.c)
		mk.node.position = p
		pts[name] = p
		circles.append({"x": p.x, "y": p.y, "r": float(mk.sz) / 2.0})
	var rank := {"current": 0, "ready": 1, "open": 2, "locked": 3, "town": 4}
	var order: Array = _markers.keys()
	order.sort_custom(func(a, b):
		return rank.get(_markers[a].c.get("state", ""), 5) < rank.get(_markers[b].c.get("state", ""), 5))
	var placed: Array = []
	var PAD := 14.0
	# keep labels off the title/HUD band and the bottom sheet, and on-frame
	var bx0 := 24.0; var by0 := 300.0; var bx1 := 1056.0; var by1 := 1560.0
	for name in order:
		var mk = _markers[name]
		mk.label.reset_size()
		var w: float = mk.label.size.x
		var h: float = mk.label.size.y
		var p: Vector2 = pts[name]
		var r: float = float(mk.sz) / 2.0 + 12.0
		var cands := [
			Vector2(p.x + r, p.y - h / 2.0), Vector2(p.x - r - w, p.y - h / 2.0),
			Vector2(p.x - w / 2.0, p.y + r), Vector2(p.x - w / 2.0, p.y - r - h),
			Vector2(p.x + r * 0.7, p.y + r * 0.7), Vector2(p.x - r * 0.7 - w, p.y + r * 0.7),
			Vector2(p.x + r * 0.7, p.y - r * 0.7 - h), Vector2(p.x - r * 0.7 - w, p.y - r * 0.7 - h)
		]
		var best: Vector2 = cands[0]
		var best_score := -1.0e9
		for cd in cands:
			var box := Rect2(cd, Vector2(w, h))
			var score := 0.0
			if box.position.x < bx0 or box.position.y < by0 or box.position.x + w > bx1 or box.position.y + h > by1:
				score -= 6000.0
			for q in placed:
				if _hits(box, q, PAD): score -= 2200.0
			for ci in circles:
				var cxp: float = clampf(ci.x, box.position.x, box.position.x + w)
				var cyp: float = clampf(ci.y, box.position.y, box.position.y + h)
				var d := Vector2(ci.x - cxp, ci.y - cyp).length()
				if d < ci.r + 6.0: score -= 1400.0
			score -= Vector2(cd.x + w / 2.0 - p.x, cd.y + h / 2.0 - p.y).length() * 0.05
			if score > best_score:
				best_score = score
				best = cd
		# every slot can be off-frame for an edge node — clamp the winner back in
		best.x = clampf(best.x, bx0, bx1 - w)
		best.y = clampf(best.y, by0, by1 - h)
		mk.label.position = best - p
		placed.append(Rect2(best, Vector2(w, h)))
	_bloom.queue_redraw()
	_lines.queue_redraw()

# ---------- selected sheet ----------
func _select(name: String) -> void:
	Audio.ui()
	if name != _sel: _expanded = false  # a freshly-picked city opens as a peek, like the design
	_sel = name
	_build_sheet()

func _heat_dots(heat: int, sz: int) -> Control:
	var h := Pal.hbox(5)
	for i in range(5):
		var d := ColorRect.new(); d.custom_minimum_size = Vector2(sz, sz)
		d.color = Pal.DANGER_RED if i < heat else Pal.HAIRLINE
		h.add_child(d)
	return h

func _act_label(c: Dictionary) -> String:
	if c.get("state", "") == "current": return "ENTER CITY"
	return c.get("req", "LOCKED") if c.get("state", "") == "locked" else "TRAVEL"

func _sheet_panel(height: float, accent: Color) -> PanelContainer:
	var p := PanelContainer.new()
	p.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	p.offset_top = -height
	var sb := Pal.sb(Color(Pal.RAISED, 0.97), 16, Pal.HAIRLINE, 1, 0)
	sb.border_width_left = 6; sb.border_color = accent
	p.add_theme_stylebox_override("panel", sb)
	# slide-in
	p.position.y = 40; p.modulate.a = 0.0
	var tw := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(p, "position:y", 0.0, 0.22)
	tw.parallel().tween_property(p, "modulate:a", 1.0, 0.18)
	return p

func _build_sheet() -> void:
	for ch in _sheet_host.get_children(): ch.queue_free()
	var c := _by_name(_sel)
	if c.is_empty(): return
	if _expanded: _build_expanded(c)
	else: _build_peek(c)

## Compact peek — one glance row; tap the body to expand. Mirrors the design default.
func _build_peek(c: Dictionary) -> void:
	var tf := _top(c)
	var accent: Color = Pal.faction_col(tf[0])
	var p := _sheet_panel(132.0, accent)
	p.mouse_filter = Control.MOUSE_FILTER_STOP
	p.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			_expanded = true; Audio.ui(); _build_sheet())
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 22); m.add_theme_constant_override("margin_right", 22)
	m.add_theme_constant_override("margin_top", 16); m.add_theme_constant_override("margin_bottom", 16)
	var row := Pal.hbox(16)
	var col := Pal.vbox(4); col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var req: String = "YOU ARE HERE" if c.get("state","") == "current" else c.get("req","")
	col.add_child(Pal.label("%s · %s %d%%" % [req, Pal.faction_label(tf[0]), int(tf[1])], 16, accent, 500))
	col.add_child(Pal.heading(String(c.name).to_upper(), 40, Pal.TEXT))
	row.add_child(col)
	var right := Pal.vbox(6); right.alignment = BoxContainer.ALIGNMENT_CENTER
	right.add_child(Pal.heading(c.get("take","£0"), 32, Pal.DIRTY))
	var hd := _heat_dots(int(c.get("heat",0)), 13); hd.alignment = BoxContainer.ALIGNMENT_END
	right.add_child(hd)
	row.add_child(right)
	if c.get("state","") == "locked":
		row.add_child(Pal.label("LOCKED", 18, Pal.MUTED, 500))
	else:
		var act := Pal.btn(_act_label(c), "hivis", 200)
		act.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		act.pressed.connect(func(): _act(c))
		row.add_child(act)
	row.add_child(Pal.label("▲", 22, Pal.MUTED, 500))
	m.add_child(row); p.add_child(m)
	_sheet_host.add_child(p)

## Full sheet — faction bars, NPCs, actions; tap ▼ to collapse back to the peek.
func _build_expanded(c: Dictionary) -> void:
	var tf := _top(c)
	var accent: Color = Pal.faction_col(tf[0])
	var p := _sheet_panel(430.0, accent)
	var m := MarginContainer.new()
	m.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	m.add_theme_constant_override("margin_left", 24); m.add_theme_constant_override("margin_right", 24)
	m.add_theme_constant_override("margin_top", 18); m.add_theme_constant_override("margin_bottom", 18)
	var v := Pal.vbox(12)
	var top := Pal.hbox(12)
	var tcol := Pal.vbox(4); tcol.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var chev := Pal.btn("▼ %s" % ("YOU ARE HERE" if c.get("state","") == "current" else c.get("req","")), "off", 0)
	chev.add_theme_font_size_override("font_size", 18)
	chev.add_theme_font_override("font", Pal.mono_font())
	chev.pressed.connect(func(): _expanded = false; Audio.ui(); _build_sheet())
	tcol.add_child(chev)
	tcol.add_child(Pal.heading(String(c.name).to_upper(), 40, Pal.TEXT))
	top.add_child(tcol)
	top.add_child(Pal.spacer())
	var tk := Pal.vbox(6); tk.alignment = BoxContainer.ALIGNMENT_CENTER
	tk.add_child(Pal.heading(c.get("take","£0"), 34, Pal.DIRTY))
	var hd := _heat_dots(int(c.get("heat",0)), 15); hd.alignment = BoxContainer.ALIGNMENT_END
	tk.add_child(hd)
	top.add_child(tk)
	v.add_child(top)
	# faction control bars
	var hold: Dictionary = c.get("hold", {})
	var order: Array = hold.keys(); order.sort_custom(func(a, b): return int(hold[a]) > int(hold[b]))
	for f in order:
		var row := Pal.hbox(10)
		row.add_child(Pal.label(Pal.faction_label(f), 16, Pal.faction_col(f), 500))
		var bar := Pal.bar(int(hold[f]) / 100.0, Pal.faction_col(f), 10)
		bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(bar)
		row.add_child(Pal.label("%d%%" % int(hold[f]), 16, Pal.TEXT2, 500))
		v.add_child(row)
	# NPCs on this manor
	var here: Array = Config.npcs_in(c.name)
	if here.size() > 0:
		var nr := Pal.hbox(10)
		nr.add_child(Pal.label("ON THIS MANOR", 16, Pal.MUTED, 500))
		for n in here.slice(0, 5):
			nr.add_child(Pal.portrait_slot(Pal.npc_portrait(n.id), 56, n.faction))
		v.add_child(nr)
	# actions
	var arow := Pal.hbox(12)
	var act := Pal.btn(_act_label(c), "hivis" if c.get("state","") != "locked" else "off", 0)
	act.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	act.disabled = c.get("state", "") == "locked"
	act.pressed.connect(func(): _act(c))
	arow.add_child(act)
	var intel := Pal.btn("INTEL", "secondary", 220)
	intel.pressed.connect(func(): Game.toast.emit("Intel coming soon", Pal.SODIUM))
	arow.add_child(intel)
	v.add_child(arow)
	m.add_child(v); p.add_child(m)
	_sheet_host.add_child(p)

func _act(c: Dictionary) -> void:
	Audio.ui()
	if c.get("state", "") == "current":
		App.I.show_screen("city")
	elif c.get("state", "") != "locked" and c.has("city"):
		var res: Dictionary = await ServerGateway.travel(c.city)
		if res.get("ok", false):
			if not res.get("instant", false): await ServerGateway.arrive()
			Game.s.city = c.city; Game.persist(); Game.changed.emit()
			App.I.show_screen("city")
		else:
			Game.toast.emit(String(res.get("reason", "Can't travel there")), Pal.DANGER_RED)
	else:
		Game.toast.emit(c.get("req", "Locked"), Pal.DANGER_RED)

func refresh() -> void:
	pass

# ---------- pan / zoom camera ----------
func _center_current() -> void:
	# frame the whole country like the design's fitBounds — the baked basemap already
	# spans the UK, so zoom 1.0 with no pan shows all thirteen cities; pan/zoom stays live
	_zoom = 1.0
	_pan = Vector2.ZERO
	_apply_cam()

const BASE_OFFSET := Vector2(0, -132)   # lift the country so the south clears the sheet

func _apply_cam() -> void:
	_world.scale = Vector2(_zoom, _zoom)
	_clamp_pan()
	_world.position = _pan + BASE_OFFSET

func _clamp_pan() -> void:
	var ws := _area.size * _zoom
	_pan.x = clampf(_pan.x, min(0.0, _area.size.x - ws.x), 0.0)
	_pan.y = clampf(_pan.y, min(0.0, _area.size.y - ws.y), 0.0)

func _on_map_input(e: InputEvent) -> void:
	if e is InputEventMouseButton:
		if e.button_index == MOUSE_BUTTON_WHEEL_UP and e.pressed:
			_zoom_at(e.position, 1.12)
		elif e.button_index == MOUSE_BUTTON_WHEEL_DOWN and e.pressed:
			_zoom_at(e.position, 1.0 / 1.12)
		elif e.button_index == MOUSE_BUTTON_LEFT:
			_dragging = e.pressed
			if e.pressed: _last = e.position
	elif e is InputEventMouseMotion and _dragging:
		_pan += e.relative; _apply_cam()
	elif e is InputEventScreenDrag:
		_pan += e.relative; _apply_cam()
	elif e is InputEventMagnifyGesture:
		_zoom_at(e.position, e.factor)

func _zoom_at(pos: Vector2, f: float) -> void:
	var old := _zoom
	_zoom = clampf(_zoom * f, 1.0, 4.0)
	var k := _zoom / old
	_pan = pos - (pos - _pan) * k
	_apply_cam()

# ================= inner draw nodes =================
class _Bloom extends Control:
	var screen: MapScreen
	func _draw() -> void:
		if screen == null: return
		var glow := Pal.radial_glow()
		for c in screen._cities():
			var p := screen.city_pt(c)
			var hold: Dictionary = c.get("hold", {})
			var order: Array = hold.keys(); order.sort_custom(func(a, b): return int(hold[a]) > int(hold[b]))
			# only the dominant holder blooms, softly — enough to colour the region
			# without smearing the whole map into neon soup
			if order.size() > 0:
				var f: String = order[0]
				var pct := int(hold[f])
				var r: float = (95.0 if c.get("tier","city")=="town" else 165.0) * (0.55 + pct / 150.0)
				var col := Pal.faction_col(f); col.a = 0.22 * (pct / 100.0 + 0.5)
				draw_texture_rect(glow, Rect2(p - Vector2(r, r), Vector2(r * 2, r * 2)), false, col)
			if int(c.get("heat", 0)) >= 4:
				var hr: float = 110.0 + int(c.heat) * 14.0
				var hc := Color(Pal.DANGER_RED, 0.05 + int(c.heat) * 0.02)
				draw_texture_rect(glow, Rect2(p - Vector2(hr, hr), Vector2(hr * 2, hr * 2)), false, hc)

class _Lines extends Control:
	var screen: MapScreen
	var _t := 0.0
	func _process(delta: float) -> void:
		_t += delta; queue_redraw()
	func _draw() -> void:
		if screen == null: return
		var col := {"supply": Pal.faction_col("vale"), "money": Pal.faction_col("rhodes"), "heat": Pal.DANGER_RED}
		for ln in Config.map_cities.get("lines", []):
			var a := screen._by_name(ln[0]); var b := screen._by_name(ln[1])
			if a.is_empty() or b.is_empty(): continue
			var p := screen.city_pt(a); var q := screen.city_pt(b)
			var d := q - p
			var mid := p + d * 0.5 + Vector2(-d.y, d.x) * 0.13
			var kind: String = ln[2]
			var lc: Color = col.get(kind, Color.WHITE)
			var hot: bool = ln[0] == "London" or ln[1] == "London"
			var pts := PackedVector2Array()
			var n := 24
			for k in range(n + 1):
				var tt := k / float(n)
				pts.append(p.lerp(mid, tt).lerp(mid.lerp(q, tt), tt))
			draw_polyline(pts, Color(lc, 0.30 if not hot else 0.5), 3.0 if hot else 2.0, true)
			# flow dot riding the line
			var speed := 0.24 if hot else 0.15
			var ft: float = fmod(_t * speed + (0.0 if hot else 0.4), 1.0)
			var fp := p.lerp(mid, ft).lerp(mid.lerp(q, ft), ft)
			draw_circle(fp, 5.0 if hot else 3.5, Color(lc, 0.9))

class _Node extends Control:
	var c: Dictionary
	var _t := 0.0
	func _process(delta: float) -> void:
		if int(c.get("heat", 0)) >= 3 or c.get("state", "") in ["ready", "current"]:
			_t += delta; queue_redraw()
	func _draw() -> void:
		var ctr := size / 2.0
		var R: float = min(size.x, size.y) / 2.0
		var locked: bool = c.get("state", "") == "locked"
		var tf: Array = c.get("hold", {}).keys()
		tf.sort_custom(func(a, b): return int(c.hold[a]) > int(c.hold[b]))
		var col: Color = Color(Pal.MUTED) if locked else Pal.faction_col(tf[0] if tf.size() > 0 else "trade")
		# heat breathing bloom
		if int(c.get("heat", 0)) >= 3:
			var b := 0.55 + 0.45 * sin(_t * 2.6)
			draw_circle(ctr, R * 1.4, Color(Pal.DANGER_RED, 0.12 * b))
		# ready ping
		if c.get("state", "") in ["ready", "current"]:
			var ph: float = fmod(_t * 0.45, 1.0)
			draw_arc(ctr, R * (0.9 + ph * 1.3), 0, TAU, 40, Color(col, (1.0 - ph) * 0.6), 2.0, true)
		# disc
		draw_circle(ctr, R - 4, Color("#080A0C", 0.9))
		draw_arc(ctr, R - 4, 0, TAU, 48, col, 2.0, true)
		# jobs-ready arc
		var pct: float = clampf(int(c.get("jobs", 0)) / 6.0, 0.0, 1.0)
		if pct > 0.0:
			draw_arc(ctr, R - 9, -PI / 2, -PI / 2 + TAU * pct, 40, col, 5.0, true)
		# centre
		if c.get("state", "") == "current":
			draw_circle(ctr, 11, Color(Pal.GLOW))
		else:
			var f := Pal.mono_font(500)
			var txt := str(c.get("jobs", 0)) if int(c.get("jobs", 0)) > 0 else "–"
			var fs := 18 if c.get("tier", "city") == "town" else 24
			var ts := f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
			draw_string(f, ctr - ts / 2.0 + Vector2(0, ts.y * 0.35), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)

class_name CityScreen
extends Control
## City hub (design 02-city — the single, canonical city hub after the WO2-T12.4
## merge; the old travel-tab CityScreen is folded in here as the TRAVEL switcher).
## The current city over a graded wet-night street, a
## city switcher to travel to other manors, your postcode BLOCKS (squares you tap
## to graft), and the WHERE TO venue grid. Everything sits on the sodium grade the
## map screens use.

const CITY_META := {
	"London": ["GREATER LONDON", "HACKNEY · E8 · MARE STREET"],
	"Manchester": ["GREATER MANCHESTER", "MOSS SIDE · M14 · PRINCESS RD"],
	"Birmingham": ["WEST MIDLANDS", "DIGBETH · B5 · HIGH ST"],
	"Liverpool": ["MERSEYSIDE", "TOXTETH · L8 · PARK RD"],
	"Leeds": ["WEST YORKSHIRE", "HAREHILLS · LS8 · ROUNDHAY RD"],
	"Bristol": ["AVON", "ST PAULS · BS2 · GROSVENOR RD"],
	"Newcastle": ["TYNE AND WEAR", "BYKER · NE6 · SHIELDS RD"],
	"Nottingham": ["EAST MIDLANDS", "ST ANNS · NG3 · WELLS RD"],
	"Glasgow": ["STRATHCLYDE", "POSSIL · G22 · SARACEN ST"],
	"Luton": ["BEDFORDSHIRE · TOWN", "MARSH FARM · LU3 · LEAGRAVE"],
	"Margate": ["KENT · TOWN", "CLIFTONVILLE · CT9 · THE SEAFRONT"],
	"Swindon": ["WILTSHIRE · TOWN", "PENHILL · SN2 · THE ORBITAL"],
	"Grimsby": ["LINCOLNSHIRE · TOWN", "EAST MARSH · DN32 · THE DOCKS"],
}

var _view := ""          # the city currently shown in the hub (name)
var _col: VBoxContainer

func _cur_name() -> String:
	return String(Config.city(Game.s.city).get("name", "London"))
func _zones() -> Array: return Config.city_map.get("zones", [])
func _cities() -> Array: return Config.map_cities.get("cities", [])
func _hold_col(h: String) -> Color: return Color(Pal.MUTED) if h == "none" else Pal.faction_col(h)

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_view = _cur_name()
	_build_backdrop()
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var m := MarginContainer.new()
	m.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	m.add_theme_constant_override("margin_left", 32); m.add_theme_constant_override("margin_right", 32)
	m.add_theme_constant_override("margin_top", 24); m.add_theme_constant_override("margin_bottom", 40)
	_col = Pal.vbox(22)
	m.add_child(_col); scroll.add_child(m); add_child(scroll)
	_build()

func _build_backdrop() -> void:
	var base := ColorRect.new(); base.color = Color("#0E1013")
	base.set_anchors_preset(Control.PRESET_FULL_RECT); base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(base)
	var street := TextureRect.new()
	street.texture = Pal.tex("res://art/ui/citymap_hackney.png")
	street.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	street.offset_bottom = 900
	street.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	street.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	street.modulate = Color(0.5, 0.4, 0.24)   # sodium/sepia grade
	street.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(street)
	var glow := TextureRect.new()
	glow.texture = Pal.radial_glow()
	glow.position = Vector2(300, -120); glow.size = Vector2(900, 760)
	glow.stretch_mode = TextureRect.STRETCH_SCALE; glow.modulate = Color(Pal.SODIUM, 0.28)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var gm := CanvasItemMaterial.new(); gm.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD; glow.material = gm
	add_child(glow)
	# fade the street into the panel colour so the lower content reads
	var fade := TextureRect.new()
	fade.texture = _vfade()
	fade.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE); fade.offset_bottom = 900
	fade.stretch_mode = TextureRect.STRETCH_SCALE; fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fade)

func _vfade() -> GradientTexture2D:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.4, 1.0])
	g.colors = PackedColorArray([Color("#121417", 0.35), Color("#121417", 0.1), Color("#121417", 0.98)])
	var t := GradientTexture2D.new(); t.gradient = g; t.fill_from = Vector2(0, 0); t.fill_to = Vector2(0, 1)
	t.width = 8; t.height = 256
	return t

# ------------------------------------------------------------------ build
func _build() -> void:
	for c in _col.get_children(): c.queue_free()
	var meta: Array = CITY_META.get(_view, ["THE MANOR", _view.to_upper()])
	var cd := _city_by_name(_view)
	var is_current: bool = _view == _cur_name()

	# back to map + day-clock utilities
	var top := Pal.hbox(12)
	var back := Pal.btn("← THE MANOR", "secondary", 60)
	back.add_theme_font_override("font", Pal.mono_font(500)); back.add_theme_font_size_override("font_size", 19)
	back.custom_minimum_size = Vector2(0, 60); back.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	back.pressed.connect(func(): App.I.show_screen("map"))
	top.add_child(back)
	var ready := Game.daily_ready_count()
	var db := Pal.btn("DAILY GRAFT" + ("  ●%d" % ready if ready > 0 else ""), "hivis" if ready > 0 else "secondary", 60)
	db.add_theme_font_size_override("font_size", 22); db.custom_minimum_size = Vector2(0, 60)
	db.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	db.pressed.connect(func(): Audio.ui(); App.I.show_daily())
	top.add_child(db)
	# LAY LOW — go home and cool off (Step 25). Louder the hotter you are.
	if Heat.pips() >= 3:
		var ll := Pal.btn("LAY LOW", "danger" if Heat.hot() else "secondary", 60)
		ll.add_theme_font_size_override("font_size", 22); ll.custom_minimum_size = Vector2(160, 60)
		ll.pressed.connect(_lay_low)
		top.add_child(ll)
	if Game.debt_active():
		var kb := Pal.btn("KIP", "secondary", 60); kb.add_theme_font_size_override("font_size", 22)
		kb.custom_minimum_size = Vector2(130, 60); kb.pressed.connect(_kip)
		top.add_child(kb)
	_col.add_child(top)

	# city header: region / NAME / district, with danger + heat pips
	var hdr := Pal.hbox(20)
	var htext := Pal.vbox(6); htext.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	htext.add_child(Pal.label(meta[0], 22, Pal.SODIUM, 500))
	htext.add_child(Pal.heading(_view, 92, Pal.TEXT))
	htext.add_child(Pal.label(meta[1], 22, Pal.TEXT2, 500))
	hdr.add_child(htext)
	var pipcol := Pal.vbox(12); pipcol.alignment = BoxContainer.ALIGNMENT_END
	pipcol.add_child(_pip_group("DANGER", int(cd.get("danger", 3)), Pal.DANGER_RED))
	pipcol.add_child(_pip_group("YOUR HEAT" if is_current else "HEAT", int(round(Game.heat() / 2.0)) if is_current else int(cd.get("heat", 0)), Pal.SODIUM))
	hdr.add_child(pipcol)
	_col.add_child(hdr)

	# city switcher
	_col.add_child(_sechead("TRAVEL · TAP A CITY", ""))
	var sw := GridContainer.new(); sw.columns = 3
	sw.add_theme_constant_override("h_separation", 12); sw.add_theme_constant_override("v_separation", 12)
	for c in _cities():
		if c.get("tier", "city") == "town": continue
		sw.add_child(_city_chip(c))
	_col.add_child(sw)

	# your blocks (only where the manor is established — London/Hackney for now)
	if is_current and Game.s.city == "london" and _zones().size() > 0:
		var held := 0
		for z in _zones(): if z.get("hold", "") == "manor": held += 1
		_col.add_child(_sechead("YOUR BLOCKS · TAP TO GRAFT", "%d / %d HELD" % [held, _zones().size()]))
		var bg := GridContainer.new(); bg.columns = 2
		bg.add_theme_constant_override("h_separation", 12); bg.add_theme_constant_override("v_separation", 12)
		for z in _zones():
			bg.add_child(_block_card(z))
		_col.add_child(bg)

	# districts — the borough ladder for the current city (tap to graft there)
	if is_current:
		var bs2: Array = Config.city(Game.s.city).get("boroughs", [])
		if bs2.size() > 0:
			var unlocked2 := 0
			for b in bs2: if Game.level() >= int(b.get("level_req", 1)): unlocked2 += 1
			_col.add_child(_sechead("DISTRICTS · TAP TO GRAFT", "%d / %d OPEN" % [unlocked2, bs2.size()]))
			var dg := GridContainer.new(); dg.columns = 2
			dg.add_theme_constant_override("h_separation", 12); dg.add_theme_constant_override("v_separation", 12)
			for b in bs2:
				dg.add_child(_district_card(b))
			_col.add_child(dg)

	# where to — venue grid
	var jobs_n := int(cd.get("jobs", 0))
	_col.add_child(_sechead("WHERE TO", ("%d JOBS READY" % jobs_n) if jobs_n > 0 else "NOTHING WAITING"))
	var vg := GridContainer.new(); vg.columns = 2
	vg.add_theme_constant_override("h_separation", 12); vg.add_theme_constant_override("v_separation", 12)
	for v in _venue_defs(jobs_n):
		vg.add_child(_venue_card(v))
	_col.add_child(vg)

# ------------------------------------------------------------------ pieces
func _pip_group(cap: String, n: int, col: Color) -> Control:
	var v := Pal.vbox(6); v.alignment = BoxContainer.ALIGNMENT_END
	var lbl := Pal.label(cap, 17, col if cap.begins_with("YOUR") else Pal.TEXT2, 500)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	v.add_child(lbl)
	var row := Pal.hbox(6); row.alignment = BoxContainer.ALIGNMENT_END
	for i in range(5):
		var p := ColorRect.new(); p.custom_minimum_size = Vector2(18, 18)
		p.color = col if i < n else Color(Pal.MUTED, 0.35)
		row.add_child(p)
	v.add_child(row)
	return v

func _sechead(left: String, right: String) -> Control:
	var h := Pal.hbox(16)
	h.add_child(Pal.label(left, 20, Pal.MUTED, 500))
	var rule := ColorRect.new(); rule.color = Pal.HAIRLINE; rule.custom_minimum_size = Vector2(0, 1)
	rule.size_flags_horizontal = Control.SIZE_EXPAND_FILL; rule.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(rule)
	if right != "":
		h.add_child(Pal.label(right, 20, Pal.HIVIS, 500))
	return h

func _city_chip(c: Dictionary) -> Control:
	var name := String(c.get("name", "?"))
	var on: bool = name == _view
	var locked: bool = c.get("state", "") == "locked"
	var b := Button.new()
	b.custom_minimum_size = Vector2(0, 104); b.focus_mode = Control.FOCUS_NONE
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var col := Pal.SODIUM if on else Pal.HAIRLINE
	var bg := Color(Pal.SODIUM, 0.10) if on else Color(Pal.RAISED, 0.82)
	b.add_theme_stylebox_override("normal", Pal.sb(bg, 14, col, 1, 0))
	b.add_theme_stylebox_override("hover", Pal.sb(bg, 14, Pal.SODIUM, 1, 0))
	b.add_theme_stylebox_override("pressed", Pal.sb(bg, 14, Pal.SODIUM, 1, 0))
	var mm := MarginContainer.new(); mm.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mm.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var v := Pal.vbox(3); v.alignment = BoxContainer.ALIGNMENT_CENTER; v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var nm := Pal.heading(name, 26, Pal.MUTED if locked else Pal.TEXT); nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(nm)
	var sub := String(c.get("req", "")) if locked else String(CITY_META.get(name, ["", name.to_upper()])[1]).split(" · ")[0]
	var sl := Pal.label(sub, 14, Pal.MUTED, 500); sl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(sl)
	mm.add_child(v); b.add_child(mm)
	b.pressed.connect(func(): _tap_city(c))
	return b

func _tap_city(c: Dictionary) -> void:
	Audio.ui()
	var name := String(c.get("name", ""))
	if c.get("state", "") == "locked":
		Game.toast.emit("%s · %s" % [name.to_upper(), c.get("req", "LOCKED")], Pal.DANGER_RED)
		return
	if name == _view: return
	_view = name
	if name != _cur_name():
		Game.toast.emit("Scoping %s. Travel from the manor map to move in." % name, Pal.SODIUM)
	_build()

func _block_card(z: Dictionary) -> Control:
	var col := _hold_col(z.get("hold", "none"))
	var b := Button.new()
	b.custom_minimum_size = Vector2(0, 116); b.focus_mode = Control.FOCUS_NONE
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.add_theme_stylebox_override("normal", Pal.sb(Color("#1E2126", 0.9), 14, Color(col, 0.6), 1, 0))
	b.add_theme_stylebox_override("hover", Pal.sb(Color("#242832", 0.95), 14, col, 1, 0))
	b.add_theme_stylebox_override("pressed", Pal.sb(Color("#1E2126", 0.9), 14, col, 1, 0))
	var mm := MarginContainer.new(); mm.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mm.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mm.add_theme_constant_override("margin_left", 16); mm.add_theme_constant_override("margin_right", 16)
	var row := Pal.hbox(12); row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var strip := ColorRect.new(); strip.color = col; strip.custom_minimum_size = Vector2(5, 60)
	strip.size_flags_vertical = Control.SIZE_SHRINK_CENTER; row.add_child(strip)
	var v := Pal.vbox(4); v.size_flags_horizontal = Control.SIZE_EXPAND_FILL; v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(Pal.heading(String(z.get("name", "Block")), 28, Pal.TEXT))
	var unclaimed: bool = z.get("hold", "none") == "none"
	v.add_child(Pal.label("UNCLAIMED" if unclaimed else "%s · HEAT %d" % [z.get("take", "£0"), int(z.get("heat", 0))], 17, col if not unclaimed else Pal.MUTED, 500))
	row.add_child(v)
	row.add_child(Pal.heading("›", 30, col))
	mm.add_child(row); b.add_child(mm)
	b.pressed.connect(func(): _enter_block(z))
	return b

func _enter_block(z: Dictionary) -> void:
	Audio.ui()
	if not Game.venue_is_unlocked("jobs"):
		Game.toast.emit("Jobs unlock as you get going", Pal.TEXT2); return
	Game.toast.emit("On the graft in %s" % z.get("name", "the block"), Pal.SODIUM)
	var bs: Array = Config.city(Game.s.city).get("boroughs", [])
	App.I.show_screen("jobs", bs[0].get("id", "the_strip") if bs.size() > 0 else "the_strip")

func _venue_defs(jobs_n: int) -> Array:
	return [
		{"t": "Jobs", "s": "%d on the board" % jobs_n, "id": "jobs", "screen": "jobs", "hot": true},
		{"t": "The Street", "s": "Fight whoever's out", "id": "street", "screen": "arena", "hot": true},
		{"t": "The Fit", "s": "Everything you can wear", "id": "wardrobe", "screen": "catalogue"},
		{"t": "Flexta", "s": "The road, online", "id": "feed", "screen": "feed"},
		{"t": "Gym", "s": "Bethnal Green Iron", "id": "gym", "screen": "gym"},
		{"t": "Crew", "s": "%d on payroll" % Game.s.get("crew", []).size(), "id": "crew", "screen": "crew"},
		{"t": "Bank", "s": "Bung · Mare St", "id": "bank", "screen": "bank"},
		{"t": "Fence", "s": "Delroy's chop shop", "id": "fence", "screen": "fence", "portrait": "delroy"},
		{"t": "Shop", "s": "PoundZone", "id": "shop", "screen": "shop"},
		{"t": "Contacts", "s": "Uncle T's barbers", "id": "contacts", "screen": "messages", "portrait": "uncle_t"},
		{"t": "Territory", "s": "The trapline", "id": "trapline", "screen": "trapline"},
	]

func _venue_card(v: Dictionary) -> Control:
	var unlocked: bool = Game.venue_is_unlocked(v.id)
	var hot: bool = v.get("hot", false) and unlocked
	var b := Button.new()
	b.custom_minimum_size = Vector2(0, 126); b.focus_mode = Control.FOCUS_NONE
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.disabled = not unlocked
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var edge := Pal.SODIUM if hot else Pal.HAIRLINE
	b.add_theme_stylebox_override("normal", Pal.sb(Color(Pal.RAISED, 0.88 if unlocked else 0.5), 16, edge, 1, 0))
	b.add_theme_stylebox_override("hover", Pal.sb(Color("#242832", 0.95), 16, Pal.SODIUM, 1, 0))
	b.add_theme_stylebox_override("pressed", Pal.sb(Color(Pal.RAISED, 0.88), 16, Pal.SODIUM, 1, 0))
	b.add_theme_stylebox_override("disabled", Pal.sb(Color(Pal.RAISED, 0.4), 16, Pal.HAIRLINE, 1, 0))
	var mm := MarginContainer.new(); mm.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mm.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mm.add_theme_constant_override("margin_left", 20); mm.add_theme_constant_override("margin_right", 18)
	var row := Pal.hbox(14); row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if v.has("portrait"):
		row.add_child(Pal.portrait_slot(Pal.cast_portrait(v.portrait), 74, "manor"))
	var col := Pal.vbox(6); col.size_flags_horizontal = Control.SIZE_EXPAND_FILL; col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(Pal.heading(String(v.t), 36, Pal.TEXT if unlocked else Pal.MUTED))
	col.add_child(Pal.label(String(v.s) if unlocked else "LOCKED", 18, Pal.SODIUM if hot else Pal.TEXT2, 500))
	row.add_child(col)
	row.add_child(Pal.heading("›", 30, Pal.SODIUM if hot else Pal.MUTED))
	mm.add_child(row); b.add_child(mm)
	if unlocked:
		b.pressed.connect(func(): Audio.ui(); App.I.show_screen(String(v.screen)))
	else:
		b.pressed.connect(func(): Game.toast.emit("%s unlocks later" % String(v.t), Pal.TEXT2))
	return b

func _district_card(b: Dictionary) -> Control:
	var lr: int = int(b.get("level_req", 1))
	var locked: bool = Game.level() < lr
	var jobs_n: int = (b.get("jobs", []) as Array).size()
	var danger: int = int(b.get("danger", 3))
	var but := Button.new()
	but.custom_minimum_size = Vector2(0, 124); but.focus_mode = Control.FOCUS_NONE
	but.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	but.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	but.disabled = locked
	var edge := Pal.SODIUM if not locked else Pal.HAIRLINE
	but.add_theme_stylebox_override("normal", Pal.sb(Color(Pal.RAISED, 0.88 if not locked else 0.5), 14, edge, 1, 0))
	but.add_theme_stylebox_override("hover", Pal.sb(Color("#242832", 0.95), 14, Pal.SODIUM, 1, 0))
	but.add_theme_stylebox_override("pressed", Pal.sb(Color(Pal.RAISED, 0.88), 14, Pal.SODIUM, 1, 0))
	but.add_theme_stylebox_override("disabled", Pal.sb(Color(Pal.RAISED, 0.4), 14, Pal.HAIRLINE, 1, 0))
	var mm := MarginContainer.new(); mm.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mm.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mm.add_theme_constant_override("margin_left", 16); mm.add_theme_constant_override("margin_right", 14)
	var v := Pal.vbox(4); v.alignment = BoxContainer.ALIGNMENT_CENTER; v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var top := Pal.hbox(8); top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(Pal.label(String(b.get("postcode", "")), 18, Pal.SODIUM if not locked else Pal.MUTED, 600))
	var sp := Control.new(); sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL; sp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(sp)
	for i in range(danger):
		var pip := ColorRect.new(); pip.custom_minimum_size = Vector2(9, 9)
		pip.color = Color(Pal.DANGER_RED, 0.85 if not locked else 0.4); pip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		top.add_child(pip)
	v.add_child(top)
	v.add_child(Pal.heading(String(b.get("name", "District")), 30, Pal.TEXT if not locked else Pal.MUTED))
	v.add_child(Pal.label(("🔒 LEVEL %d" % lr) if locked else ("%d ON THE BOARD ›" % jobs_n), 17, Pal.DANGER_RED if locked else Pal.TEXT2, 500))
	mm.add_child(v); but.add_child(mm)
	if not locked:
		var bid: String = String(b.get("id", ""))
		but.pressed.connect(func(): _enter_district(bid, String(b.get("name", ""))))
	return but

func _enter_district(bid: String, nm: String) -> void:
	Audio.ui()
	if not Game.venue_is_unlocked("jobs"):
		Game.toast.emit("Jobs unlock as you get going", Pal.TEXT2); return
	Game.s.borough = bid
	Game.toast.emit("On the graft in %s" % nm, Pal.SODIUM)
	App.I.show_screen("jobs", bid)

func _lay_low() -> void:
	Audio.ui()
	var was := Heat.pips()
	Heat.lay_low()
	Game.toast.emit("Laid low. You went home cold — heat was %d, now it's off." % was, Pal.CLEAN)
	App.I._refresh_hud()
	_build()

func _kip() -> void:
	Audio.ui()
	Game.rest()
	Game.toast.emit("Morning. Day %d — %d days left." % [Game.day(), Game.days_left()], Pal.SODIUM)
	_build()

func _city_by_name(n: String) -> Dictionary:
	for c in _cities():
		if c.get("name", "") == n: return c
	return {}

func refresh() -> void:
	pass

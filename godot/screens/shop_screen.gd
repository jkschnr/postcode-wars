class_name ShopScreen
extends Control
## The Fence (design screen 13): one card scene, two tabs. BUY = gear that stacks
## odds; SELL = your loot. Delroy buys, Delroy sells.

var start_tab := "buy"
var _tab := "buy"
var _body: VBoxContainer

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_tab = start_tab
	# Gear buying now lives in the proper Shop (GearShop/items.json); the legacy
	# gear.json is gone (§WO1-T6), so the Fence is sell-only. §regression-fix.
	if Config.gear.is_empty(): _tab = "sell"
	var scroll := Pal.scroll()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(scroll)
	_body = Pal.vbox(18)
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_body)
	_rebuild()

func _rebuild() -> void:
	for c in _body.get_children(): c.queue_free()
	_body.add_child(_band())
	_body.add_child(_tabs())
	if _tab == "buy":
		var grid := _grid()
		for gid in Config.gear.keys():
			grid.add_child(_gear_card(gid))
		_body.add_child(grid)
	else:
		if Game.loot_count() == 0:
			var e := Pal.panel()
			var em := MarginContainer.new()
			em.add_theme_constant_override("margin_left", 24); em.add_theme_constant_override("margin_right", 24)
			em.add_theme_constant_override("margin_top", 28); em.add_theme_constant_override("margin_bottom", 28)
			em.add_child(Pal.text("Nothing to move. Go and get something worth fencing.", 24, Pal.TEXT2, 400, true))
			e.add_child(em); _body.add_child(e)
		else:
			var grid := _grid()
			for it in Game.s.inventory:
				if it.get("kind", "loot") == "loot":
					grid.add_child(_loot_card(it))
			_body.add_child(grid)
			var total := 0
			for it in Game.s.inventory:
				if it.get("kind", "loot") == "loot": total += int(it.get("value", 0))
			var sell := Pal.btn("SELL EVERYTHING — %s DIRTY" % Pal.money(total), "hivis", 108)
			sell.pressed.connect(_sell_all)
			_body.add_child(sell)

func _band() -> Control:
	var band := PanelContainer.new()
	band.custom_minimum_size = Vector2(0, 300); band.clip_contents = true
	band.add_theme_stylebox_override("panel", Pal.sb(Pal.INSET, 12, Pal.RAISED, 1, 0))
	var bg := TextureRect.new()
	bg.texture = Pal.city_tex(Game.s.city)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	bg.modulate = Color(0.8, 0.75, 0.6); band.add_child(bg)
	var shade := ColorRect.new(); shade.color = Color(0.07, 0.08, 0.09, 0.5)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); band.add_child(shade)
	var wm := Pal.heading("FENCE", 180, Color(Pal.TEXT, 0.06))
	wm.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT); wm.position = Vector2(-360, -120); band.add_child(wm)
	var back := Pal.btn("← CITY", "secondary", 60)
	back.add_theme_font_override("font", Pal.mono_font(500)); back.add_theme_font_size_override("font_size", 20)
	back.custom_minimum_size = Vector2(180, 60); back.position = Vector2(24, 20)
	back.pressed.connect(func(): App.I.show_screen("city")); band.add_child(back)
	var m := MarginContainer.new()
	m.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	m.add_theme_constant_override("margin_left", 32); m.add_theme_constant_override("margin_bottom", 24)
	var col := Pal.vbox(2); col.alignment = BoxContainer.ALIGNMENT_END
	col.add_child(Pal.label("DELROY BUYS, DELROY SELLS", 22, Pal.SODIUM, 500))
	col.add_child(Pal.heading("THE FENCE", 64, Pal.TEXT))
	col.add_child(Pal.label("HACKNEY ARCHES · CASH ONLY · NO RECEIPTS", 20, Pal.TEXT2, 400))
	m.add_child(col); band.add_child(m)
	return band

func _tabs() -> Control:
	var row := Pal.hbox(16)
	if not Config.gear.is_empty():   # no BUY tab when there's no legacy gear to buy
		row.add_child(_tab_btn("BUY", "buy"))
	row.add_child(_tab_btn("SELL", "sell"))
	return row

func _tab_btn(label: String, id: String) -> Button:
	var on := _tab == id
	var b := Pal.btn(label, "hivis" if on else "secondary", 96)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if not on:
		b.add_theme_color_override("font_color", Pal.SODIUM)
	b.pressed.connect(func(): _tab = id; Audio.ui(); _rebuild())
	return b

func _grid() -> GridContainer:
	var g := GridContainer.new()
	g.columns = 2
	g.add_theme_constant_override("h_separation", 16); g.add_theme_constant_override("v_separation", 16)
	return g

func _card_shell(rarity: String, art_name: String) -> Array:
	# returns [panel, content_vbox]
	var rc: Color = Pal.RARITY.get(rarity, Pal.RARITY.basic)
	var p := Pal.panel()
	p.add_theme_stylebox_override("panel", Pal.sb(Pal.PANEL, 16, rc, 1, 0))
	p.clip_contents = true
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	var art := TextureRect.new()
	art.texture = Pal.item_tex(art_name)
	art.custom_minimum_size = Vector2(0, 180)
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	v.add_child(art)
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 18); m.add_theme_constant_override("margin_right", 18)
	m.add_theme_constant_override("margin_top", 14); m.add_theme_constant_override("margin_bottom", 16)
	var col := Pal.vbox(6)
	m.add_child(col); v.add_child(m); p.add_child(v)
	return [p, col, rc]

func _gear_card(gid: String) -> Control:
	var g: Dictionary = Config.gear[gid]
	var owned := Game.is_equipped(gid)
	var rarity: String = g.get("rarity", "decent")
	var shell := _card_shell(rarity, str(g.get("name", "")))
	var col: VBoxContainer = shell[1]
	var rc: Color = shell[2]
	col.add_child(Pal.label(rarity.to_upper(), 18, rc, 500))
	col.add_child(Pal.heading(String(g.get("name", "Gear")).to_upper(), 26, Pal.TEXT))
	col.add_child(Pal.label(str(g.get("desc", "")).to_upper(), 16, Pal.MUTED, 400))
	var row := Pal.hbox(10)
	row.add_child(Pal.heading("OWNED" if owned else Pal.money(int(g.price)), 32, Pal.CLEAN if owned else Pal.DIRTY))
	row.add_child(Pal.spacer())
	if not owned:
		var buy := Pal.btn("BUY", "secondary", 72)
		buy.custom_minimum_size = Vector2(130, 72)
		buy.add_theme_color_override("font_color", Pal.SODIUM)
		buy.add_theme_stylebox_override("normal", Pal.sb(Pal.INSET, 12, Pal.SODIUM, 1, 0))
		buy.pressed.connect(func(): _buy(gid))
		row.add_child(buy)
	col.add_child(row)
	return shell[0]

func _loot_card(it: Dictionary) -> Control:
	var rarity: String = it.get("rarity", "basic")
	var shell := _card_shell(rarity, str(it.get("name", "")))
	var col: VBoxContainer = shell[1]
	var rc: Color = shell[2]
	col.add_child(Pal.label(rarity.to_upper(), 18, rc, 500))
	col.add_child(Pal.heading(String(it.get("name", "Item")).to_upper(), 26, Pal.TEXT))
	col.add_child(Pal.label("STRAIGHT SALE", 16, Pal.MUTED, 400))
	col.add_child(Pal.heading(Pal.money(int(it.get("value", 0))), 32, Pal.DIRTY))
	return shell[0]

func _buy(gid: String) -> void:
	var res: Dictionary = await ServerGateway.buy_gear(gid)
	if res.ok:
		Audio.level_up(); Game.toast.emit("Copped " + Config.gear[gid].name, Pal.CLEAN)
	else:
		Audio.error(); Game.toast.emit(res.get("reason", "Can't"), Pal.DANGER_RED)
	_rebuild()

func _sell_all() -> void:
	var res: Dictionary = await ServerGateway.sell_loot()
	Audio.cash(); Game.toast.emit("Fenced the lot: +%s dirty" % Pal.money(int(res.total)), Pal.DIRTY)
	_rebuild()

func refresh() -> void:
	pass

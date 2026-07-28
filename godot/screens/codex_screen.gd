class_name CodexScreen
extends Control
## The Book (design screen 18): people / places / the Ledger of Consequences.

var _tab := "PEOPLE"
var _root: VBoxContainer

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root = Pal.vbox(16)
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_root)
	_build()

func _build() -> void:
	for c in _root.get_children(): c.queue_free()
	var head := Pal.vbox(2)
	head.add_child(Pal.label("EVERYTHING YOU KNOW", 22, Pal.SODIUM, 500))
	head.add_child(Pal.heading("THE BOOK", 56, Pal.TEXT))
	_root.add_child(head)
	var tabs := Pal.hbox(12)
	for t in ["PEOPLE", "PLACES", "LEDGER"]:
		tabs.add_child(_tab_btn(t))
	_root.add_child(tabs)
	var scroll := Pal.scroll()
	_root.add_child(scroll)
	var list := Pal.vbox(12)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	match _tab:
		"PEOPLE": _people(list)
		"PLACES": _places(list)
		"LEDGER": _ledger(list)

func _tab_btn(t: String) -> Button:
	var on := _tab == t
	var b := Pal.btn(t, "hivis" if on else "secondary", 88)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if not on: b.add_theme_color_override("font_color", Pal.TEXT)
	b.pressed.connect(func(): _tab = t; Audio.ui(); _build())
	return b

func _people(list: VBoxContainer) -> void:
	for id in Config.cast.keys():
		var d: Dictionary = Config.character(id)
		var met: bool = Cast.met(id)
		var p := Pal.panel()
		var m := MarginContainer.new()
		m.add_theme_constant_override("margin_left", 20); m.add_theme_constant_override("margin_right", 20)
		m.add_theme_constant_override("margin_top", 14); m.add_theme_constant_override("margin_bottom", 14)
		var row := Pal.hbox(16)
		row.add_child(Pal.portrait_slot(Pal.cast_portrait(id) if met else null, 84, "neutral"))
		var tv := Pal.vbox(2); tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tv.add_child(Pal.heading((d.get("display_name", id)).to_upper() if met else "??????", 28, Pal.TEXT if met else Pal.MUTED))
		tv.add_child(Pal.label((d.get("role", "")).to_upper() if met else "NOT MET YET", 18, Pal.TEXT2, 400))
		row.add_child(tv)
		if met:
			var st := Cast.life_state(id)
			var col := Pal.CLEAN if st == "active" else (Pal.SODIUM if st == "strained" else Pal.DANGER_RED)
			row.add_child(Pal.chip(st.to_upper(), col, col))
		m.add_child(row); p.add_child(m)
		list.add_child(p)

func _places(list: VBoxContainer) -> void:
	for id in Config.cities.keys():
		var c: Dictionary = Config.city(id)
		var unlocked: bool = Game.level() >= int(c.get("level_req", 1))
		var p := Pal.panel()
		var m := MarginContainer.new()
		m.add_theme_constant_override("margin_left", 20); m.add_theme_constant_override("margin_right", 20)
		m.add_theme_constant_override("margin_top", 16); m.add_theme_constant_override("margin_bottom", 16)
		var row := Pal.hbox(12)
		var tv := Pal.vbox(2); tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tv.add_child(Pal.heading((c.get("name", id)).to_upper(), 30, Pal.TEXT if unlocked else Pal.MUTED))
		tv.add_child(Pal.label((c.get("speciality", "")).to_upper() if unlocked else "LOCKED · LVL %d" % int(c.get("level_req", 1)), 18, Pal.TEXT2, 400))
		row.add_child(tv)
		row.add_child(Pal.pips(int(c.get("danger", 3)), 5, Pal.DANGER_RED, 14))
		m.add_child(row); p.add_child(m)
		list.add_child(p)

func _ledger(list: VBoxContainer) -> void:
	var head := Pal.text("The Ledger of Consequences. Append-only. Nothing here is removable, and nothing here is payable — it only accumulates.", 22, Pal.TEXT2, 400, true)
	list.add_child(head)
	var entries: Array = Game.s.get("ledger", [])
	if entries.is_empty():
		var p := Pal.panel()
		var m := MarginContainer.new()
		m.add_theme_constant_override("margin_left", 24); m.add_theme_constant_override("margin_right", 24)
		m.add_theme_constant_override("margin_top", 24); m.add_theme_constant_override("margin_bottom", 24)
		m.add_child(Pal.text("Clean so far. Give it time.", 24, Pal.MUTED, 400, true))
		p.add_child(m); list.add_child(p)
	else:
		for e in entries:
			var p := Pal.panel()
			var m := MarginContainer.new()
			m.add_theme_constant_override("margin_left", 20); m.add_theme_constant_override("margin_right", 20)
			m.add_theme_constant_override("margin_top", 14); m.add_theme_constant_override("margin_bottom", 14)
			var v := Pal.vbox(4)
			v.add_child(Pal.heading(str(e.get("title", "")), 26, Pal.TEXT))
			v.add_child(Pal.text(str(e.get("text", "")), 20, Pal.TEXT2, 400, true))
			m.add_child(v); p.add_child(m); list.add_child(p)

func refresh() -> void:
	pass

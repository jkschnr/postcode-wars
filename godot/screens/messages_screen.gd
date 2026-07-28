class_name MessagesScreen
extends Control
## Messages (design screen 15) — a real messaging-app feel, not a quest log.
## Threads with the cast; Kayo's thread opens the prison call.

const THREADS := [
	{"id": "kayo", "preview": "Go on then. What do you actually want to know?", "time": "NOW", "unread": true, "call": true, "faction": "family"},
	{"id": "nads", "preview": "Yard's empty. You coming or what?", "time": "12m", "unread": true, "faction": "road"},
	{"id": "silas", "preview": "The kettle's on when you're ready.", "time": "1h", "unread": false, "faction": "ledger"},
	{"id": "uncle_t", "preview": "Come by the shop. Let me see you're still you.", "time": "3h", "unread": false, "faction": "road"},
	{"id": "delroy", "preview": "German, after 2019. Anything else is scrap.", "time": "Yesterday", "unread": false, "faction": "road"},
]

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var v := Pal.vbox(16)
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(v)
	var head := Pal.hbox(16)
	var back := Pal.btn("← CITY", "secondary", 60)
	back.add_theme_font_override("font", Pal.mono_font(500))
	back.add_theme_font_size_override("font_size", 20)
	back.custom_minimum_size = Vector2(180, 60)
	back.pressed.connect(func(): App.I.show_screen("city"))
	head.add_child(back)
	head.add_child(Pal.heading("MESSAGES", 48, Pal.TEXT))
	v.add_child(head)
	var scroll := Pal.scroll()
	v.add_child(scroll)
	var list := Pal.vbox(12)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	for t in THREADS:
		list.add_child(_thread(t))

func _thread(t: Dictionary) -> Control:
	var name := Cast.name_of(t.id) if Cast.name_of(t.id) != "" else str(t.id).capitalize()
	var b := Button.new()
	b.custom_minimum_size = Vector2(0, 150)
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.add_theme_stylebox_override("normal", Pal.sb(Pal.PANEL, 16, Pal.RAISED, 1, 0))
	b.add_theme_stylebox_override("hover", Pal.sb(Pal.PANEL.lightened(0.05), 16, Pal.SODIUM, 1, 0))
	b.add_theme_stylebox_override("pressed", Pal.sb(Pal.PANEL, 16, Pal.RAISED, 1, 0))
	var m := MarginContainer.new()
	m.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	m.add_theme_constant_override("margin_left", 20); m.add_theme_constant_override("margin_right", 20)
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var row := Pal.hbox(16)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var port := Pal.portrait_slot(Pal.cast_portrait(t.id), 88, t.get("faction", "neutral"))
	port.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(port)
	var tv := Pal.vbox(4)
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tv.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	tv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var top := Pal.hbox(10)
	top.add_child(Pal.heading(name.to_upper() + ("  ☎" if t.get("call", false) else ""), 28, Pal.TEXT))
	top.add_child(Pal.spacer())
	top.add_child(Pal.label(str(t.get("time", "")), 18, Pal.MUTED, 400))
	tv.add_child(top)
	tv.add_child(Pal.text(str(t.get("preview", "")), 22, Pal.TEXT2, 400, true))
	row.add_child(tv)
	if t.get("unread", false):
		var dot := ColorRect.new()
		dot.color = Pal.HIVIS
		dot.custom_minimum_size = Vector2(16, 16)
		dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(dot)
	m.add_child(row); b.add_child(m)
	b.pressed.connect(func():
		Audio.ui()
		if t.get("call", false):
			App.I.show_screen("prison_call")
		else:
			Game.toast.emit("Thread with %s — full chat in a later drop" % name, Pal.TEXT2))
	return b

func refresh() -> void:
	pass

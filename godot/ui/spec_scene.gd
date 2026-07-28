class_name SpecScene
extends Control
## The naming scene (guide Step 24). Around level 20, Uncle T has noticed how you
## work and names it. The path you've leaned toward is highlighted, but you can
## take any of the three — and it's switchable later, so nothing is locked.

var _on_done: Callable

func setup(on_done := Callable()) -> void:
	_on_done = on_done

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new(); dim.color = Color(0.02, 0.02, 0.03, 0.92)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)
	var wrap := CenterContainer.new(); wrap.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(wrap)
	var p := PanelContainer.new(); p.custom_minimum_size = Vector2(1000, 0)
	p.add_theme_stylebox_override("panel", Pal.sb(Color(Pal.RAISED, 0.98), 18, Pal.SODIUM, 2, 0))
	var m := MarginContainer.new()
	for s in ["left", "right", "top", "bottom"]: m.add_theme_constant_override("margin_" + s, 36)
	var v := Pal.vbox(16)
	# Uncle T
	var top := Pal.hbox(16)
	top.add_child(Pal.portrait_slot(Pal.cast_portrait("uncle_t"), 96, "manor"))
	var who := Pal.vbox(4); who.size_flags_horizontal = Control.SIZE_EXPAND_FILL; who.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	who.add_child(Pal.label("UNCLE T'S BARBERS", 18, Pal.SODIUM, 500))
	who.add_child(Pal.heading("HE'S BEEN WATCHING", 34, Pal.TEXT))
	top.add_child(who)
	v.add_child(top)
	v.add_child(Pal.text("\"I've been watching how you work. There's a word for what you are — it's not a compliment, but it's not not one either. Pick your lane.\"", 24, Pal.TEXT2, 400, true))
	var leader := Specialisation.leader()
	for id in ["bully", "creeper", "face"]:
		v.add_child(_option(id, id == leader))
	m.add_child(v); p.add_child(m); wrap.add_child(p)
	p.modulate.a = 0.0
	create_tween().tween_property(p, "modulate:a", 1.0, 0.25)
	Audio.ui()

func _option(id: String, recommended: bool) -> Control:
	var meta: Dictionary = Specialisation.SPECS[id]
	var col := Color(str(meta.accent))
	var b := Button.new(); b.custom_minimum_size = Vector2(0, 112); b.focus_mode = Control.FOCUS_NONE
	b.add_theme_stylebox_override("normal", Pal.sb(Color(col, 0.12) if recommended else Color("#15181C"), 12, col if recommended else Pal.HAIRLINE, 2 if recommended else 1, 0))
	b.add_theme_stylebox_override("hover", Pal.sb(Color(col, 0.18), 12, col, 2, 0))
	b.add_theme_stylebox_override("pressed", Pal.sb(Color(col, 0.12), 12, col, 2, 0))
	var mm := MarginContainer.new(); mm.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); mm.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mm.add_theme_constant_override("margin_left", 20); mm.add_theme_constant_override("margin_right", 20)
	var row := Pal.hbox(14); row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var txt := Pal.vbox(3); txt.size_flags_horizontal = Control.SIZE_EXPAND_FILL; txt.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var titlerow := Pal.hbox(10)
	titlerow.add_child(Pal.heading(str(meta.label), 30, col))
	if recommended: titlerow.add_child(Pal.chip("HOW YOU WORK", col, col))
	txt.add_child(titlerow)
	txt.add_child(Pal.label(str(meta.passive), 17, Pal.TEXT2, 500))
	row.add_child(txt)
	row.add_child(Pal.heading("›", 28, col))
	mm.add_child(row); b.add_child(mm)
	b.pressed.connect(func(): _pick(id))
	return b

func _pick(id: String) -> void:
	Audio.cash()
	Specialisation.set_spec(id)
	var meta: Dictionary = Specialisation.SPECS[id]
	Game.toast.emit("You're a %s now · %s" % [str(meta.label), str(meta.passive)], Color(str(meta.accent)))
	queue_free()
	if _on_done.is_valid(): _on_done.call()

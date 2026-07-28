class_name LevelUpCeremony
extends Control
## Rank ceremony (design screen 08). Night street · figure · rank stamp that pops
## in rotated · "LEVEL N REACHED" · a 2×2 "what it bought you" grid · XP bar ·
## SPEND YOUR POINTS. Tap anywhere (after a beat) or the CTA to continue.

var level: int
var unlock: String
var on_done: Callable
var _armed := false

func setup(lvl: int, unlk: String, cb: Callable) -> void:
	level = lvl
	unlock = unlk
	on_done = cb

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.03, 0.04, 0.94)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	# warm glow pool low-centre
	var glow := ColorRect.new()
	glow.color = Color(Pal.SODIUM, 0.05)
	glow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(glow)

	var wrap := MarginContainer.new()
	wrap.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	wrap.add_theme_constant_override("margin_left", 40); wrap.add_theme_constant_override("margin_right", 40)
	wrap.add_theme_constant_override("margin_top", 90); wrap.add_theme_constant_override("margin_bottom", 60)
	add_child(wrap)
	var v := Pal.vbox(20)
	wrap.add_child(v)

	# figure (player portrait or dark plate) with the rank stamp over its foot
	var stack := Control.new()
	stack.custom_minimum_size = Vector2(0, 620)
	v.add_child(stack)
	var fig := PanelContainer.new()
	fig.add_theme_stylebox_override("panel", Pal.sb(Color("#16191D"), 16, Pal.RAISED, 1, 0))
	fig.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	fig.custom_minimum_size = Vector2(420, 520)
	fig.position = Vector2(-210, 0)
	var figtex := Pal.cast_portrait("nads")  # stand-in "you" figure until a player sprite exists
	if figtex != null:
		var tr := TextureRect.new()
		tr.texture = figtex
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		tr.modulate = Color(0.6, 0.6, 0.66)
		fig.add_child(tr)
	stack.add_child(fig)

	var cap := Pal.label("LEVEL %d REACHED" % level, 28, Pal.SODIUM, 500)
	cap.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	cap.position = Vector2(-200, 430); cap.custom_minimum_size = Vector2(400, 0)
	cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stack.add_child(cap)

	# rank stamp
	var stamp := PanelContainer.new()
	stamp.add_theme_stylebox_override("panel", Pal.sb(Color("#16191D"), 12, Pal.SODIUM, 3, 0))
	var sm := MarginContainer.new()
	sm.add_theme_constant_override("margin_left", 40); sm.add_theme_constant_override("margin_right", 40)
	sm.add_theme_constant_override("margin_top", 8); sm.add_theme_constant_override("margin_bottom", 8)
	var rank := Pal.heading(Game.rank_name().to_upper(), 96, Pal.GLOW)
	sm.add_child(rank); stamp.add_child(sm)
	stamp.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	stamp.position = Vector2(-260, 460)
	stamp.custom_minimum_size = Vector2(520, 0)
	stamp.pivot_offset = Vector2(260, 70)
	stamp.rotation_degrees = -2
	stamp.scale = Vector2(1.5, 1.5)
	stamp.modulate.a = 0.0
	stack.add_child(stamp)
	var tw := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(0.15)
	tw.parallel().tween_property(stamp, "scale", Vector2.ONE, 0.48)
	tw.parallel().tween_property(stamp, "modulate:a", 1.0, 0.3)
	Audio.level_up()
	var cf := Confetti.new(); add_child(cf)
	cf.burst(Vector2(540, 540), 80)

	var sub := Pal.label("RANK CONFIRMED · %s" % String(Config.city(Game.s.city).get("name", "London")).to_upper(), 22, Pal.MUTED, 400)
	sub.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	sub.position = Vector2(-260, 592); sub.custom_minimum_size = Vector2(520, 0)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stack.add_child(sub)

	# what it bought you
	v.add_child(Pal.sechead("WHAT IT BOUGHT YOU"))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 16)
	var per_stat: int = int(Config.levels.get("per_level", {}).get("stat_points", 1))
	var per_en: int = int(Config.levels.get("per_level", {}).get("energy_cap", 2))
	grid.add_child(_gain("+%d STAT POINTS" % per_stat, "Spend them before the next job.", Pal.HIVIS))
	grid.add_child(_gain("ENERGY CAP %d → %d" % [100 + per_en * (level - 2), 100 + per_en * (level - 1)], "Longer nights, same body.", Pal.SODIUM))
	if unlock != "":
		grid.add_child(_gain("UNLOCKED", unlock, Pal.RARITY.peng))
		grid.add_child(_gain("WORD TRAVELS", "People are starting to know the name.", Pal.DIRTY))
	v.add_child(grid)

	v.add_child(Pal.vspacer())
	# xp bar
	var xpb := Pal.vbox(8)
	var xprow := Pal.hbox(10)
	xprow.add_child(Pal.label("LEVEL %d" % level, 22, Pal.TEXT2, 500))
	xprow.add_child(Pal.spacer())
	xprow.add_child(Pal.label("%s / %s XP" % [Pal._commas(int(Game.s.xp_into)), Pal._commas(Game.xp_to_next())], 20, Pal.MUTED, 400))
	xpb.add_child(xprow)
	xpb.add_child(Pal.bar(Game.xp_progress(), Pal.SODIUM, 16, 24))
	v.add_child(xpb)

	var cta := Pal.btn("SPEND YOUR POINTS" if int(Game.s.stat_points) > 0 else "CARRY ON", "hivis", 108)
	cta.pressed.connect(_go)
	v.add_child(cta)

	await get_tree().create_timer(0.6).timeout
	_armed = true

func _gain(title: String, body: String, col: Color) -> PanelContainer:
	var p := Pal.panel()
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 20); m.add_theme_constant_override("margin_right", 20)
	m.add_theme_constant_override("margin_top", 16); m.add_theme_constant_override("margin_bottom", 16)
	var v := Pal.vbox(6)
	v.add_child(Pal.label(title, 20, col, 500))
	v.add_child(Pal.text(body, 24, Pal.TEXT2, 400, true))
	m.add_child(v); p.add_child(m)
	return p

func _go() -> void:
	Audio.ui()
	var spend := int(Game.s.stat_points) > 0
	queue_free()
	if on_done.is_valid():
		on_done.call()
	# WO2-T12.3: SPEND YOUR POINTS lands on the character sheet, stats scrolled in
	# and pulsing — not back on the board.
	if spend:
		App.I.show_screen("character", "spend")

func _gui_input(e: InputEvent) -> void:
	if _armed and ((e is InputEventMouseButton and e.pressed) or (e is InputEventScreenTouch and e.pressed)):
		_go()

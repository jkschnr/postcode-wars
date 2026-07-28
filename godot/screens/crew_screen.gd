class_name CrewScreen
extends Control
## Crew (design screen 11) — roster + recruitment. Lightweight for now: idle crew
## show a gold border (they cost wages for nothing); recruits can be signed on.

const RECRUITS := [
	{"id": "tobes", "name": "Tobes", "class": "LOOKOUT", "loyalty": 40, "wage": 120, "faction": "road"},
	{"id": "maz", "name": "Maz", "class": "WHEELS", "loyalty": 55, "wage": 220, "faction": "road"},
	{"id": "pearl", "name": "Pearl", "class": "FIXER", "loyalty": 30, "wage": 180, "faction": "neutral"},
]

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var scroll := Pal.scroll()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(scroll)
	var v := Pal.vbox(18)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(v)

	var head := Pal.vbox(2)
	head.add_child(Pal.heading("THE CREW", 56, Pal.TEXT))
	var roster: Array = Game.s.get("crew", [])
	head.add_child(Pal.label("%d ON PAYROLL · £%d / WEEK" % [roster.size(), _weekly(roster)], 22, Pal.SODIUM, 500))
	v.add_child(head)

	v.add_child(Pal.sechead("YOUR CREW"))
	if roster.is_empty():
		var empty := Pal.panel()
		var em := MarginContainer.new()
		em.add_theme_constant_override("margin_left", 24); em.add_theme_constant_override("margin_right", 24)
		em.add_theme_constant_override("margin_top", 28); em.add_theme_constant_override("margin_bottom", 28)
		em.add_child(Pal.text("Nobody on the books yet. You're doing all this alone — for now.", 24, Pal.TEXT2, 400, true))
		empty.add_child(em)
		v.add_child(empty)
	else:
		for member in roster:
			v.add_child(_member(member))

	v.add_child(Pal.sechead("AVAILABLE"))
	for r in RECRUITS:
		var signed := false
		for member in roster:
			if member.get("id", "") == r.id: signed = true
		if not signed:
			v.add_child(_recruit(r))

func _member(m: Dictionary) -> Control:
	var idle: bool = m.get("idle", true)
	var p := Pal.panel(Pal.DIRTY if idle else Color(0, 0, 0, 0))
	var mm := MarginContainer.new()
	mm.add_theme_constant_override("margin_left", 20); mm.add_theme_constant_override("margin_right", 20)
	mm.add_theme_constant_override("margin_top", 16); mm.add_theme_constant_override("margin_bottom", 16)
	var row := Pal.hbox(16)
	row.add_child(Pal.portrait_slot(Pal.cast_portrait(m.id), 88, m.get("faction", "road")))
	var tv := Pal.vbox(4)
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tv.add_child(Pal.heading(String(m.get("name", "")).to_upper(), 30, Pal.TEXT))
	tv.add_child(Pal.label("%s · LOYALTY %d · £%d/WK" % [m.get("class", ""), int(m.get("loyalty", 0)), int(m.get("wage", 0))], 18, Pal.TEXT2, 400))
	row.add_child(tv)
	if idle:
		row.add_child(Pal.chip("IDLE", Pal.DIRTY, Pal.DIRTY))
	mm.add_child(row); p.add_child(mm)
	return p

func _recruit(r: Dictionary) -> Control:
	var p := Pal.panel()
	var mm := MarginContainer.new()
	mm.add_theme_constant_override("margin_left", 20); mm.add_theme_constant_override("margin_right", 20)
	mm.add_theme_constant_override("margin_top", 16); mm.add_theme_constant_override("margin_bottom", 16)
	var row := Pal.hbox(16)
	row.add_child(Pal.portrait_slot(Pal.cast_portrait(r.id), 88, r.get("faction", "road")))
	var tv := Pal.vbox(4)
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tv.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	tv.add_child(Pal.heading(String(r.name).to_upper(), 30, Pal.TEXT))
	tv.add_child(Pal.label("%s · WANTS £%d/WK" % [r.get("class", ""), int(r.wage)], 18, Pal.TEXT2, 400))
	row.add_child(tv)
	var sign := Pal.btn("SIGN", "hivis", 88)
	sign.custom_minimum_size = Vector2(160, 88)
	sign.pressed.connect(func(): _sign(r))
	row.add_child(sign)
	mm.add_child(row); p.add_child(mm)
	return p

func _sign(r: Dictionary) -> void:
	if Game.clean() < int(r.wage):
		Game.toast.emit("Need £%d clean for the first week" % int(r.wage), Pal.DANGER_RED); Audio.error()
		return
	Audio.level_up()
	Game.add_clean(-int(r.wage))
	var roster: Array = Game.s.get("crew", [])
	var m := r.duplicate(true); m["idle"] = true
	roster.append(m)
	Game.s.crew = roster
	Game.persist(); Game.changed.emit()
	Game.toast.emit("%s's on the payroll." % r.name, Pal.SODIUM)
	App.I.show_screen("crew")

func _weekly(roster: Array) -> int:
	var t := 0
	for m in roster: t += int(m.get("wage", 0))
	return t

func refresh() -> void:
	pass

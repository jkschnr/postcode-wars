class_name ArenaScreen
extends Control
## THE STREET — every town and every block has its own strip where you can fight
## whoever's out tonight (guide: street arena). The card is a daily roster of real
## shadow-player characters on an easy→hard ladder, scaled to the block. Beat them
## for their P's, XP and respect; clear the whole block to run it. Lose and you
## wake up in hospital. Combat is the full animated CombatView, decided by stats.

var _list: VBoxContainer
var _roster: Array = []

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var scroll := Pal.scroll()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(scroll)
	_list = Pal.vbox(18)
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_list)
	_rebuild()

func _borough() -> Dictionary:
	for b in Config.city(Game.s.city).get("boroughs", []):
		if b.get("id", "") == Game.s.get("borough", ""):
			return b
	var bs: Array = Config.city(Game.s.city).get("boroughs", [])
	return bs[0] if bs.size() > 0 else {"name": "The Block", "postcode": ""}

func _key() -> String:
	return "%s|%s|%d" % [Game.s.city, Game.s.get("borough", "the_strip"), int(Game.s.get("day", 0))]

func _state() -> Dictionary:
	if not Game.s.has("street") or typeof(Game.s.street) != TYPE_DICTIONARY:
		Game.s["street"] = {}
	var k := _key()
	if not Game.s.street.has(k):
		Game.s.street[k] = {"beaten": [], "cleared": false}
	return Game.s.street[k]

func _my_power() -> int:
	return Shadow.power(Shadow.own_snapshot())

func _boss() -> Dictionary:
	return Shadow.boss_for(_key(), Game.level())

func _rebuild() -> void:
	for c in _list.get_children(): c.queue_free()
	var b := _borough()
	_roster = Shadow.street_roster(_key(), Game.level(), 5)
	_list.add_child(_strip(b))

	var st := _state()
	var beaten: Array = st.get("beaten", [])

	if Game.in_hospital():
		_list.add_child(_notice("YOU'RE IN HOSPITAL", "Come back when you're patched up. %d min left." % int(ceil(Game.hospital_left() / 60.0))))
	elif Game.in_jail():
		_list.add_child(_notice("YOU'RE BANGED UP", "No fights from a cell."))

	_list.add_child(_section("ON THE STREET TONIGHT", "%d/%d DONE" % [beaten.size(), _roster.size()]))
	for opp in _roster:
		_list.add_child(_opp_card(opp, beaten.has(opp.player_id)))

	# clear the roster and the block boss steps out
	if beaten.size() >= _roster.size():
		if st.get("boss_beaten", false):
			_list.add_child(_cleared_banner())
		else:
			_list.add_child(_section("THE ONE WHO RUNS IT", "BOSS"))
			_list.add_child(_opp_card(_boss(), false))

# ---------- header ----------
func _strip(b: Dictionary) -> Control:
	var band := PanelContainer.new()
	band.custom_minimum_size = Vector2(0, 320); band.clip_contents = true
	band.add_theme_stylebox_override("panel", Pal.sb(Pal.INSET, 12, Pal.DANGER_RED, 1, 0))
	var bg := TextureRect.new()
	bg.texture = Pal.city_tex(Game.s.city)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	bg.modulate = Color(0.62, 0.5, 0.42)
	band.add_child(bg)
	var shade := ColorRect.new(); shade.color = Color(0.05, 0.05, 0.07, 0.62)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	band.add_child(shade)
	var back := Pal.btn("← CITY", "secondary", 60)
	back.add_theme_font_override("font", Pal.mono_font(500)); back.add_theme_font_size_override("font_size", 20)
	back.custom_minimum_size = Vector2(180, 60); back.position = Vector2(24, 20)
	back.pressed.connect(func(): App.I.show_screen("city"))
	band.add_child(back)
	var respect := int(Game.s.get("respect", 0))
	var m := MarginContainer.new()
	m.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	m.add_theme_constant_override("margin_left", 32); m.add_theme_constant_override("margin_right", 28)
	m.add_theme_constant_override("margin_bottom", 24)
	var col := Pal.vbox(6); col.alignment = BoxContainer.ALIGNMENT_END
	col.add_child(Pal.label("THE STREET · %s" % str(b.get("postcode", "")).to_upper(), 20, Pal.DANGER_RED, 500))
	col.add_child(Pal.heading(str(b.get("name", "The Block")).to_upper(), 58, Pal.TEXT))
	var chips := Pal.hbox(10)
	chips.add_child(Pal.chip("RESPECT %d" % respect, Pal.SODIUM, Pal.SODIUM))
	chips.add_child(Pal.chip(_rank_title(respect), Pal.HIVIS, Pal.HIVIS))
	col.add_child(chips)
	col.add_child(Pal.label("Whoever's out tonight. Beat them, take their P's, run the block.", 19, Pal.TEXT2, 400))
	m.add_child(col); band.add_child(m)
	return band

func _rank_title(respect: int) -> String:
	if respect >= 400: return "NAME ON ROAD"
	if respect >= 200: return "KNOWN"
	if respect >= 80: return "GETTING SEEN"
	if respect >= 20: return "NEW FACE"
	return "NOBODY"

func _section(cap: String, right: String) -> Control:
	var h := Pal.sechead(cap)
	h.add_child(Pal.label(right, 20, Pal.MUTED, 400))
	return h

func _notice(title: String, body: String) -> Control:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", Pal.sb(Color(Pal.RAISED, 0.9), 14, Pal.POLICE, 1, 0))
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 20); m.add_theme_constant_override("margin_right", 20)
	m.add_theme_constant_override("margin_top", 16); m.add_theme_constant_override("margin_bottom", 16)
	var v := Pal.vbox(4)
	v.add_child(Pal.heading(title, 30, Pal.TEXT))
	v.add_child(Pal.label(body, 20, Pal.TEXT2, 400))
	m.add_child(v); p.add_child(m)
	return p

# ---------- opponent card ----------
func _opp_card(opp: Dictionary, beaten: bool) -> Control:
	var my := _my_power()
	var ratio := float(opp.power) / float(max(1, my))
	var diff := _diff_label(ratio)
	var can_fight: bool = not beaten and not Game.in_hospital() and not Game.in_jail()

	var p := PanelContainer.new()
	var edge: Color = Pal.MUTED if beaten else diff.col
	p.add_theme_stylebox_override("panel", Pal.sb(Color(Pal.PANEL, 0.5 if beaten else 0.95), 16, edge, 1, 0))
	var mm := MarginContainer.new()
	mm.add_theme_constant_override("margin_left", 18); mm.add_theme_constant_override("margin_right", 18)
	mm.add_theme_constant_override("margin_top", 16); mm.add_theme_constant_override("margin_bottom", 16)
	var row := Pal.hbox(16)
	row.add_child(_portrait(opp.doll, 108, edge))

	var col := Pal.vbox(6); col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var top := Pal.hbox(10)
	top.add_child(Pal.heading(str(opp.display_name), 34, Pal.TEXT if not beaten else Pal.MUTED))
	top.add_child(Pal.chip("LVL %d" % int(opp.level), Pal.TEXT2, Pal.HAIRLINE))
	col.add_child(top)
	col.add_child(Pal.label("%s · POWER %d" % [str(opp.specialisation).to_upper(), int(opp.power)], 18, Pal.TEXT2, 500))
	var rewards := Pal.hbox(10)
	rewards.add_child(Pal.chip("+%s" % Pal.money(int(opp.reward_dirty)), Pal.DIRTY, Color(Pal.DIRTY, 0.5)))
	rewards.add_child(Pal.chip("+%d XP" % int(opp.reward_xp), Pal.SODIUM, Color(Pal.SODIUM, 0.5)))
	rewards.add_child(Pal.chip("+%d RESPECT" % int(opp.respect), Pal.HIVIS, Color(Pal.HIVIS, 0.5)))
	if opp.get("boss", false):
		rewards.add_child(Pal.chip("DROPS GEAR", Pal.DIRTY, Pal.DIRTY))
	col.add_child(rewards)
	row.add_child(col)

	var right := Pal.vbox(8); right.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if beaten:
		right.add_child(Pal.chip("DONE", Pal.CLEAN, Pal.CLEAN))
	else:
		right.add_child(Pal.chip(diff.t, diff.col, diff.col))
		var f := Pal.btn("FIGHT", "danger" if ratio >= 1.1 else "hivis", 76)
		f.custom_minimum_size = Vector2(170, 76)
		f.disabled = not can_fight
		f.pressed.connect(func(): _fight(opp))
		right.add_child(f)
	row.add_child(right)
	mm.add_child(row); p.add_child(mm)
	return p

func _diff_label(ratio: float) -> Dictionary:
	if ratio < 0.85: return {"t": "EASY", "col": Pal.CLEAN}
	if ratio < 1.12: return {"t": "EVEN", "col": Pal.SODIUM}
	if ratio < 1.45: return {"t": "TOUGH", "col": Pal.DANGER_RED}
	return {"t": "DEADLY", "col": Color("#FF5555")}

func _portrait(cfg: Dictionary, px: int, accent: Color) -> Control:
	var frame := PanelContainer.new()
	frame.custom_minimum_size = Vector2(px, px)
	frame.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	frame.add_theme_stylebox_override("panel", Pal.sb(Color("#0C0E10"), 12, accent, 2, 0))
	frame.clip_contents = true
	var dv := DollView.new()
	dv.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dv.view = "bust"; dv.set_cfg(cfg)
	frame.add_child(dv)
	return frame

# ---------- fight ----------
func _fight(opp: Dictionary) -> void:
	Audio.ui()
	var me := {
		"name": str(Game.s.get("tag", Game.s.get("name", "YOU"))).to_upper(),
		"doll": Game.s.get("doll", Doll.DEF), "weapon": Game.fitted("weapon"),
		"str": Game.eff_stat("strength"), "tgh": Game.eff_stat("toughness"),
		"spd": Game.eff_stat("speed"), "slk": Game.eff_stat("slickness"),
		"atk_bonus": Game.gear_edge() * 4.0, "def_bonus": Game.gear_edge() * 3.0,
		"bonus_hp": int(Game.s.get("next_fight_hp", 0)),
	}
	for k in Specialisation.combat_bonus(): me[k] = float(me.get(k, 0)) + float(Specialisation.combat_bonus()[k])
	if int(Game.s.get("next_fight_hp", 0)) > 0:
		Game.s["next_fight_hp"] = 0; Game.persist()
	var them := Shadow.to_attacker(opp, "")
	var cv := CombatView.new()
	cv.setup(me, them, Game.rng.randi(), func(won): _result(opp, won))
	App.I.overlay.add_child(cv)

func _result(opp: Dictionary, won: bool) -> void:
	if won:
		Audio.coin() if opp.get("boss", false) else Audio.reveal()
		Game.add_dirty(int(opp.reward_dirty * Specialisation.street_payout_mult()))
		Game.gain_xp(int(opp.reward_xp))
		Game.s["respect"] = int(Game.s.get("respect", 0)) + int(opp.respect)
		Game.s["_arena_wins"] = int(Game.s.get("_arena_wins", 0)) + 1   # objective: arena_wins
		Game.bump_streak()
		Specialisation.bump("violent")           # street fights lean you Bully
		var st := _state()
		var drop := ""
		if opp.get("boss", false):
			st["boss_beaten"] = true
			st["cleared"] = true
			var bonus := 40 + Game.level() * 5
			Game.s["respect"] = int(Game.s.respect) + bonus
			drop = Game.roll_gear_drop(max(Game.level(), int(opp.level)))
			if drop != "": Game.own_item(drop)
			var dt: String = " · won %s" % Config.item(drop).get("n", "gear") if drop != "" else ""
			Game.toast.emit("YOU RUN THE BLOCK · +%d respect%s" % [bonus + int(opp.respect), dt], Pal.HIVIS)
			Feed.post("ran %s and took %s's chain. That's the block." % [str(_borough().get("name", "the block")), str(opp.display_name)])
		else:
			if not st.beaten.has(opp.player_id):
				st.beaten.append(opp.player_id)
			if Game.rng.randf() < 0.25:                        # a quarter of wins drop something
				drop = Game.roll_gear_drop(max(Game.level(), int(opp.level)))
				if drop != "": Game.own_item(drop)
			var dt2: String = " · won %s" % Config.item(drop).get("n", "gear") if drop != "" else ""
			Game.toast.emit("Took %s off %s · +%d respect%s" % [Pal.money(int(opp.reward_dirty)), opp.display_name, int(opp.respect), dt2], Pal.CLEAN)
		Game.persist(); Game.changed.emit()
		_rebuild()
	else:
		Game.reset_streak()
		Game.add_heat(1.0)
		var mins := Game.rng.randi_range(int(Config.get_value("timers_minutes.hospital_min", 10)), int(Config.get_value("timers_minutes.hospital_max", 30)))
		Game.hospitalise(mins * 60.0)
		Game.s["_last_loss"] = Game.now()
		Game.persist(); Game.changed.emit()
		Events.hospitalised.emit(mins)
		Game.toast.emit("%s did you over · hospital %dm" % [opp.display_name, mins], Pal.DANGER_RED)
		App.I.show_screen("city")

func _cleared_banner() -> Control:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", Pal.sb(Color(Pal.HIVIS, 0.12), 16, Pal.HIVIS, 2, 0))
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 22); m.add_theme_constant_override("margin_right", 22)
	m.add_theme_constant_override("margin_top", 20); m.add_theme_constant_override("margin_bottom", 20)
	var v := Pal.vbox(6)
	v.add_child(Pal.heading("YOU RUN THIS BLOCK", 40, Pal.HIVIS))
	v.add_child(Pal.label("Nobody left standing on %s tonight. New faces tomorrow." % str(_borough().get("name", "the block")), 20, Pal.TEXT2, 400))
	m.add_child(v); p.add_child(m)
	return p

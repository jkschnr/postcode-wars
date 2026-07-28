class_name App
extends Control
## App shell — persistent frame: background, top HUD, screen host, bottom nav,
## and an overlay layer for choice cards, the reveal, ceremonies and toasts.
## Everything is click-only.

static var I: App

var content: MarginContainer
var overlay: Control
var toast_box: VBoxContainer
var current := ""
var _hud_dirty: Label
var _hud_clean: Label
var _hud_level: Label
var _hud_rank: Label
var _hud_xp: ProgressBar
var _hud_xpnext: Label
var _hud_en: ProgressBar
var _hud_nv: ProgressBar
var _hud_en_lbl: Label
var _hud_nv_lbl: Label
var _hud_heat: HBoxContainer
var _nav: HBoxContainer
var _hud_bar: Control
var _heat_strip: Control
var _heat_lbl: Label
var _nav_bar: Control
var _streak_lbl: Label
var _streak_chip: PanelContainer
var _next_lbl: Label
var _debt_chip: PanelContainer
var _debt_days: Label
var _debt_amt: Label
var _obj_bar: Control
var _obj_text: Label
var _obj_sub: Label
var _obj_bar_fill: ProgressBar
var _obj_goto: Dictionary = {}
var _dd := -1.0        # displayed (counting) dirty
var _dc := -1.0        # displayed clean
var _last_xp := -1.0   # for XP bar pulse

func _ready() -> void:
	I = self
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Pal.BASE
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	# concrete "tooth" grit behind all UI
	var tooth := Pal.tooth_layer()
	tooth.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(tooth)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 0)
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	_hud_bar = _build_hud()
	root.add_child(_hud_bar)
	_obj_bar = _build_objective_bar()
	root.add_child(_obj_bar)
	_heat_strip = _build_heat_strip()
	root.add_child(_heat_strip)
	content = MarginContainer.new()
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("margin_left", 24)
	content.add_theme_constant_override("margin_right", 24)
	content.add_theme_constant_override("margin_top", 16)
	content.add_theme_constant_override("margin_bottom", 16)
	root.add_child(content)
	_nav_bar = _build_nav()
	root.add_child(_nav_bar)

	# Overlays live in a CanvasLayer so their Control children anchor straight to
	# the viewport and always cover the full screen, above everything.
	var cl := CanvasLayer.new()
	cl.layer = 10
	add_child(cl)
	overlay = Control.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cl.add_child(overlay)

	# fine film grain over everything (design: opacity ~0.045, no vignette)
	var glass := CanvasLayer.new()
	glass.layer = 20
	add_child(glass)
	var grain := TextureRect.new()
	grain.texture = Pal.tex("res://art/ui/grain.png")
	grain.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	grain.stretch_mode = TextureRect.STRETCH_TILE
	grain.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	grain.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	grain.mouse_filter = Control.MOUSE_FILTER_IGNORE
	grain.modulate.a = 0.05
	glass.add_child(grain)
	toast_box = Pal.vbox(10)
	toast_box.set_anchors_preset(Control.PRESET_CENTER_TOP)
	toast_box.position = Vector2(0, 180)
	toast_box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	toast_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(toast_box)

	Game.changed.connect(_refresh_hud)
	Game.toast.connect(_toast)
	Game.milestone.connect(_milestone)
	Events.venue_unlocked.connect(func(_id): Audio.unlock())
	Cast.reacted.connect(_on_cast_reacted)
	Director.changed.connect(refresh_objective)
	Events.objective_completed.connect(_on_objective_completed)

	if OS.get_environment("ENDS_TEST") == "1":
		_self_test()
		return

	if OS.get_environment("ENDS_MGTEST") == "1":
		_minigame_test()
		return

	if OS.get_environment("ENDS_MGWIN") == "1":
		_minigame_window_table()
		return

	if OS.get_environment("ENDS_BALANCE") == "1":
		_balance_sim()
		return

	if OS.get_environment("ENDS_DEBUG") == "1":
		Game.new_character("Ash", 0, "road")
		Game.s.prologue_done = true
		Game.start_debt(); Game.s.day = 6; Game.pay_debt(3200)
		Cast.meet("uncle_t"); Cast.meet("nads"); Cast.meet("silas"); Cast.meet("kayo")
		Game.add_dirty(1240); Game.add_clean(3600); Game.gain_xp(3200)
		Game.s.level = 14; Game.s.stat_points = 3
		Game.s.inventory = [
			{"name": "Flagship Phone", "rarity": "peng", "value": 420, "kind": "loot"},
			{"name": "Gold Watch", "rarity": "peng", "value": 260, "kind": "loot"},
			{"name": "Boxed AirPods", "rarity": "decent", "value": 90, "kind": "loot"}]
		for gid in ["head_4", "jacket_7", "top_4", "bottoms_2", "feet_6", "hands_4", "weapon_5", "body_2"]:
			Game.equip_item(gid)
		for spare in ["head_5", "face_5", "top_1", "feet_4", "jacket_5"]:
			Game.own_item(spare)
		Game.s.consumables = {"cons_0": 3, "cons_3": 2, "cons_4": 1}
		if OS.get_environment("ENDS_CITY") != "": Game.s.city = OS.get_environment("ENDS_CITY")  # debug: preview a city hub
		# pre-clear the strip's roster so the boss shows for screenshots
		Game.s.street = {"london|the_strip|6": {"beaten": ["st_0", "st_1", "st_2", "st_3", "st_4"], "cleared": false, "boss_beaten": false}}
		Game.gym_add("strength", 120.0, 1)
		Game.s.wash.append({"front": "chickenlix", "dirty_in": 600, "clean_out": 420, "fee": 180, "ends_at": Game.now() + 140, "claimed": false})
		Game.s.streak = 4
		Game.ensure_daily()
		Game.daily_progress("jobs", 9); Game.daily_progress("dirty", 2000)
		Game.daily_progress("crit", 1); Game.daily_progress("wash", 2000); Game.daily_progress("travel", 1)
		if OS.get_environment("ENDS_JAIL") == "1":
			Game.send_to_jail(180.0)

	var start := OS.get_environment("ENDS_SCREEN")
	# Screenshot/inspect a specific prologue beat: ENDS_SCREEN=prologue [ENDS_BEAT=p_tea]
	if start == "prologue":
		show_screen("city")
		var beat := OS.get_environment("ENDS_BEAT")
		play_beat(beat if beat != "" else "p_visit", Callable())
		if OS.get_environment("ENDS_SHOT") == "1":
			_capture()
		return
	if start == "":
		# Already signed in on this device (token persisted last time)? Skip the
		# login screen entirely, pull the cloud save and resume — stay signed in.
		if Cloud.logged_in():
			_boot_signed_in()
			return
		# the loader + login intro (upgrade_03) is the front door; it routes onward
		# to creation / resumed prologue / map when the player signs in
		start = "login"
	if Game.s.get("prologue_done", false):
		Director.ensure_active()
	show_screen(start)
	_refresh_hud()
	refresh_objective(Director.current())
	var show := OS.get_environment("ENDS_SHOW")
	if show == "encounter":
		show_encounter(ServerGateway.roll_encounter())
	elif show == "reveal":
		show_reveal({"success": true, "tier": "crit", "dirty": 480, "xp": 60, "crit": true,
			"streak": 4, "streak_mult": 1.24, "new_best": true,
			"flavor": "Two phones — hers and the spare. The live keeps streaming from your pocket for a while.",
			"job_name": "Phone Snatch", "items": [{"name": "Flagship Phone", "rarity": "peng", "value": 420}], "leveled": []})
	elif show == "levelup":
		show_levelup(6, Game.milestone_unlock(5), Callable())
	elif show == "greeter":
		Greeter.maybe_greet(Callable())
	elif show == "collect":
		show_collect(Callable())
	elif show == "exit":
		overlay.add_child(BeforeYouGo.new())
	elif show == "stages":
		var js := JobStages.new()
		js.setup("burglary", 340, {}, func(_r): pass)
		overlay.add_child(js)
	elif show == "ambush":
		var _snap := Shadow.pick_opponent()
		var ac := AmbushCard.new()
		ac.setup(Shadow.to_attacker(_snap, Config.ambushes.get("setups", ["Someone steps out."])[0]))
		overlay.add_child(ac)
	elif show == "items":
		var samp := [
			{"n":"Faded Cap","r":"Ba","c":"navy","sh":"cap","v":{}},
			{"n":"Bobble","r":"Pe","c":"red","sh":"beanie","v":{"bobble":true}},
			{"n":"Bucket","r":"De","c":"sand","sh":"bucket","v":{}},
			{"n":"Fur Hood","r":"Pe","c":"olive","sh":"hood","v":{"fur":true,"strings":true}},
			{"n":"Balaclava","r":"Pe","c":"black","sh":"balaclava","v":{}},
			{"n":"The Crown","r":"Ic","c":"gold","sh":"crown","v":{}},
			{"n":"Skull Bandana","r":"De","c":"black","sh":"gaiter","v":{"skull":true}},
			{"n":"Respirator","r":"Ce","c":"lgrey","sh":"respirator","v":{}},
			{"n":"Northside Puffer","r":"Pe","c":"black","sh":"jacket","v":{"zip":true,"baffles":true,"w":9}},
			{"n":"Tracksuit Top","r":"De","c":"navy","sh":"jacket","v":{"zip":true,"stripes":true}},
			{"n":"Hi-Vis Coat","r":"Pe","c":"hivis","sh":"jacket","v":{"zip":true,"hivis":true,"pockets":true}},
			{"n":"Denim Jacket","r":"De","c":"denim","sh":"jacket","v":{"buttons":true,"pockets":true,"w":6}},
			{"n":"Oversized Hoodie","r":"De","c":"charc","sh":"top","v":{"hood":true}},
			{"n":"Vest","r":"Ba","c":"white","sh":"top","v":{"vest":true}},
			{"n":"The Trackies","r":"Ic","c":"black","sh":"bottoms","v":{"elastic":true,"cuff":true,"crease":true}},
			{"n":"Old Jeans","r":"Ba","c":"denim","sh":"bottoms","v":{"belt":true,"pockets":true}},
			{"n":"Fresh Whites","r":"Ce","c":"white","sh":"shoe","v":{"laces":true,"swoosh":true,"soleY":21,"soleH":5}},
			{"n":"Work Boots","r":"Pe","c":"tan","sh":"shoe","v":{"boot":true,"laces":true,"steel":true}},
			{"n":"Leather Gloves","r":"De","c":"brown","sh":"glove","v":{"thin":true}},
			{"n":"The Duster","r":"Ic","c":"gold","sh":"duster","v":{}},
			{"n":"Shank","r":"Pe","c":"charc","sh":"blade","v":{"len":13,"w":2}},
			{"n":"Rambo","r":"Ce","c":"black","sh":"blade","v":{"len":18,"w":4,"guard":true,"serr":true}},
			{"n":"Bat","r":"De","c":"wood","sh":"bat","v":{}},
			{"n":"Machete","r":"Ce","c":"black","sh":"machete","v":{}},
			{"n":"Stab Vest","r":"Pe","c":"black","sh":"vestArmour","v":{"plate":true,"straps":true}},
			{"n":"Backpack","r":"Pe","c":"olive","sh":"bag","v":{"straps":true,"zip":true,"pockets":true}},
			{"n":"Cracked Android","r":"Ba","c":"charc","sh":"phone","v":{"cracked":true}},
			{"n":"Energy Drink","r":"Ba","c":"hivis","sh":"can","v":{"tab":true}},
		]
		var grid := GridContainer.new(); grid.columns = 4
		grid.add_theme_constant_override("h_separation", 8); grid.add_theme_constant_override("v_separation", 8)
		grid.position = Vector2(20, 40); grid.size = Vector2(1040, 0)
		for it in samp:
			var cell := PanelContainer.new(); cell.custom_minimum_size = Vector2(250, 230)
			cell.add_theme_stylebox_override("panel", Pal.sb(Color("#101317"), 8, Color(ItemArt.RC.get(it.r, Pal.HAIRLINE), 0.5), 2, 0))
			var cv := VBoxContainer.new()
			var iv := ItemView.new(); iv.custom_minimum_size = Vector2(0, 170); iv.set_item(it)
			cv.add_child(iv)
			cv.add_child(Pal.label(it.n, 16, ItemArt.RC.get(it.r, Pal.TEXT), 500))
			cell.add_child(cv); grid.add_child(cell)
		overlay.add_child(grid)
	elif show == "pose":
		var cfg := Shadow.doll_cfg("posetest", "bully")
		var poses := [{"t":"IDLE","ext":0.0,"g":false}, {"t":"WIND UP","ext":0.4,"g":false},
			{"t":"PUNCH","ext":1.0,"g":false}, {"t":"GUARD","ext":0.0,"g":true}]
		for i in range(poses.size()):
			var p: Dictionary = poses[i]
			var fr := PanelContainer.new()
			fr.position = Vector2(20 + (i % 2) * 530, 120 + int(i / 2) * 820)
			fr.custom_minimum_size = Vector2(500, 760); fr.size = Vector2(500, 760)
			fr.add_theme_stylebox_override("panel", Pal.sb(Color("#0C0E10"), 16, Pal.SODIUM, 2, 0))
			fr.clip_contents = true
			var dv := DollView.new()
			dv.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			dv.view = "full"; dv.set_cfg(cfg); dv.set_combat(true); dv.set_pose(p.ext, p.g)
			fr.add_child(dv)
			var lb := Pal.label(p.t, 26, Pal.SODIUM, 500); lb.position = Vector2(16, 12)
			fr.add_child(lb)
			overlay.add_child(fr)
	elif show == "combat":
		var snap := Shadow.pick_opponent()
		var me := {"name": str(Game.s.get("tag", "YOU")).to_upper(), "doll": Game.s.get("doll", Doll.DEF),
			"str": int(Game.s.stats.strength), "tgh": int(Game.s.stats.toughness),
			"spd": int(Game.s.stats.speed), "slk": int(Game.s.stats.get("slickness", 5)), "weapon": "weapon_5"}
		var cv := CombatView.new()
		cv.setup(me, Shadow.to_attacker(snap, "fight"), 4242, Callable())
		overlay.add_child(cv)
	elif show == "jailcell":
		Game.send_to_jail(900.0)
		show_screen("jail")
	elif show == "spec":
		Game.s.spec_counters = {"violent": 12, "stealth": 3, "management": 1}
		var ss := SpecScene.new(); ss.setup(Callable()); overlay.add_child(ss)
	elif show == "rank":
		var rc := RankCeremony.new(); rc.setup("Grafter", "The firm", Callable()); overlay.add_child(rc)
	elif show == "comeback":
		Game.s.session["last_end"] = Game.now() - 12 * 86400.0
		Game.s["comeback_seen"] = 0.0
		var cbi := Comeback.evaluate()
		var cbr := Comeback.apply(cbi)
		var cbc := ComebackCard.new(); cbc.setup(cbr, Callable())
		overlay.add_child(cbc)
	elif show == "defence":
		Game.s.session["last_end"] = Game.now() - 2 * 86400.0
		Game.s.shadow = {"last_attacked": {}, "pending_reports": []}
		Shadow.simulate_defences()
		show_collect(Callable())
	elif show == "confirm":
		# own a couple of tools so the loadout's TOOLS row appears
		show_screen("jobs")
		await get_tree().process_frame
		for c in content.get_children():
			if c is JobsScreen:
				var b: Dictionary = c._borough()
				var jobs: Array = b.get("jobs", [])
				if jobs.size() > 0: c._tap_job(str(jobs[0]))
	elif show == "daily":
		show_daily()
	elif show == "result":
		var cc := ChoiceCard.new()
		cc.setup(ServerGateway.roll_encounter(), Callable())
		overlay.add_child(cc)
		cc.call_deferred("_build_result", {"ok": true, "checked": true, "text": "Talked him right down. Respect on the block.", "deltas": {"dirty": 250, "clean": 0, "xp": 45, "heat": 0, "leveled": []}})
	# normal session open: greet → collect → dailies, then the player's in the world
	if show == "" and OS.get_environment("ENDS_SHOT") != "1" and Game.s.get("prologue_done", false) and current == "map":
		run_session_open()
	if OS.get_environment("ENDS_SHOT") == "1":
		_capture()

## Record when the player left so the greeter's away-timing works next open.
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED:
		if Game.s.has("session"):
			Game.s.session["last_end"] = Game.now()
			Game.persist()
		Telemetry.session_end()
		if Cloud.logged_in():
			Cloud.push_save(Game.s)   # best-effort final sync so other devices catch up
		# "Before you go" — only in the world, only if 2+ things aren't running,
		# and not stacked on top of another overlay
		if what == NOTIFICATION_APPLICATION_PAUSED and Game.s.get("prologue_done", false) \
				and current == "map" and overlay.get_child_count() <= 1 \
				and Threads.missing().size() >= 2 and Threads.rows().size() > 0:
			overlay.add_child(BeforeYouGo.new())

# ------------------------------------------------------------------ HUD
func chrome_visible(v: bool) -> void:
	_hud_bar.visible = v
	_nav_bar.visible = v
	if _obj_bar: _obj_bar.visible = v and not Director.current().is_empty()

## A completed objective flashes the banner and celebrates the momentum.
func _on_objective_completed(_id: String) -> void:
	Audio.level_up()
	if _obj_bar == null: return
	var t := create_tween()
	t.tween_property(_obj_bar, "modulate", Color(1.4, 1.4, 1.1), 0.12)
	t.tween_property(_obj_bar, "modulate", Color.WHITE, 0.3)

func _build_hud() -> Control:
	var bar := PanelContainer.new()
	var st := Pal.sb(Pal.RAISED, 0, Color(0, 0, 0, 0), 0, 0)
	st.border_color = Pal.HAIRLINE
	st.set_border_width(SIDE_BOTTOM, 1)
	bar.add_theme_stylebox_override("panel", st)
	bar.custom_minimum_size = Vector2(0, 140)
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 32)
	m.add_theme_constant_override("margin_right", 32)
	m.add_theme_constant_override("margin_top", 10)
	m.add_theme_constant_override("margin_bottom", 14)
	bar.add_child(m)
	var row := Pal.hbox(16)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	m.add_child(row)

	row.add_child(_money_chip("dirty", Pal.DIRTY))
	row.add_child(_money_chip("clean", Pal.CLEAN))

	# EN / NV bars (flex)
	var bars := Pal.vbox(8)
	bars.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bars.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bars.add_child(_hud_stat_bar("EN", Pal.SODIUM, true))
	bars.add_child(_hud_stat_bar("NV", Pal.NERVE, false))
	row.add_child(bars)

	# HEAT pips
	var heatcol := Pal.vbox(8)
	heatcol.alignment = BoxContainer.ALIGNMENT_CENTER
	heatcol.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_hud_heat = Pal.hbox(6)
	_hud_heat.alignment = BoxContainer.ALIGNMENT_CENTER
	for i in range(5):
		_hud_heat.add_child(Pal.pip(false, Pal.DANGER_RED, 14))
	heatcol.add_child(_hud_heat)
	heatcol.add_child(Pal.label("HEAT", 20, Pal.TEXT2))
	row.add_child(heatcol)

	# level + XP, divider on the left
	var lvlwrap := Pal.hbox(16)
	lvlwrap.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var divider := ColorRect.new()
	divider.color = Pal.HAIRLINE
	divider.custom_minimum_size = Vector2(1, 72)
	divider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	lvlwrap.add_child(divider)
	var lvlcol := Pal.vbox(6)
	lvlcol.alignment = BoxContainer.ALIGNMENT_CENTER
	_hud_level = Pal.heading("1", 44, Pal.TEXT)
	_hud_level.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lvlcol.add_child(_hud_level)
	_hud_xp = _bar(Pal.GLOW, 6)
	_hud_xp.custom_minimum_size = Vector2(110, 6)
	lvlcol.add_child(_hud_xp)
	lvlwrap.add_child(lvlcol)
	row.add_child(lvlwrap)
	return bar

## The objective banner (guide Step 9) — one goal, always visible, tappable to
## jump straight to where it's completed.
## A persistent warning strip that appears once you're hot (Step 25).
func _build_heat_strip() -> Control:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", Pal.sb(Color(Pal.DANGER_RED, 0.16), 0, Pal.DANGER_RED, 0, 0))
	p.custom_minimum_size = Vector2(0, 44); p.visible = false
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 24); m.add_theme_constant_override("margin_right", 24)
	m.add_theme_constant_override("margin_top", 6); m.add_theme_constant_override("margin_bottom", 6)
	var row := Pal.hbox(10)
	var dot := ColorRect.new(); dot.color = Pal.DANGER_RED; dot.custom_minimum_size = Vector2(10, 10)
	dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER; row.add_child(dot)
	_heat_lbl = Pal.label("", 18, Color("#E0B0B0"), 500); row.add_child(_heat_lbl)
	m.add_child(row); p.add_child(m)
	return p

func _refresh_heat_strip() -> void:
	if _heat_strip == null: return
	var show_it: bool = Heat.hot() and _hud_bar != null and _hud_bar.visible
	_heat_strip.visible = show_it
	if show_it: _heat_lbl.text = Heat.strip_line().to_upper()

func _build_objective_bar() -> Control:
	var bar := PanelContainer.new()
	var st := Pal.sb(Pal.PANEL, 0, Color(0, 0, 0, 0), 0, 0)
	st.border_color = Pal.HAIRLINE
	st.set_border_width(SIDE_BOTTOM, 1)
	bar.add_theme_stylebox_override("panel", st)
	bar.custom_minimum_size = Vector2(0, 96)
	var btn := Button.new()
	btn.flat = true; btn.focus_mode = Control.FOCUS_NONE
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	btn.add_theme_stylebox_override("normal", Pal.sb(Color(0, 0, 0, 0), 0))
	btn.add_theme_stylebox_override("hover", Pal.sb(Color(Pal.SODIUM, 0.06), 0))
	btn.add_theme_stylebox_override("pressed", Pal.sb(Color(Pal.SODIUM, 0.10), 0))
	btn.pressed.connect(_on_objective_pressed)
	bar.add_child(btn)
	var m := MarginContainer.new()
	m.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	m.add_theme_constant_override("margin_left", 32); m.add_theme_constant_override("margin_right", 28)
	m.add_theme_constant_override("margin_top", 12); m.add_theme_constant_override("margin_bottom", 12)
	var row := Pal.hbox(14); row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var chip := Pal.label("NOW", 15, Pal.SODIUM, 500)
	chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(chip)
	var col := Pal.vbox(2); col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.size_flags_vertical = Control.SIZE_SHRINK_CENTER; col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_obj_text = Pal.heading("—", 28, Pal.TEXT)
	col.add_child(_obj_text)
	_obj_sub = Pal.label("", 18, Pal.TEXT2, 400)
	col.add_child(_obj_sub)
	_obj_bar_fill = _bar(Pal.SODIUM, 4)
	_obj_bar_fill.custom_minimum_size = Vector2(0, 4); _obj_bar_fill.visible = false
	col.add_child(_obj_bar_fill)
	row.add_child(col)
	var chev := Pal.heading("›", 34, Pal.MUTED)
	chev.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(chev)
	m.add_child(row); bar.add_child(m)
	return bar

func _on_objective_pressed() -> void:
	Audio.ui()
	var scr := String(_obj_goto.get("screen", ""))
	if scr == "": return
	show_screen(scr, String(_obj_goto.get("borough", "")))

func refresh_objective(obj: Dictionary) -> void:
	if _obj_text == null: return
	# the objective banner only ever shows alongside the HUD (never on boot/login/
	# creation/jail, where the chrome is hidden)
	if obj.is_empty() or not _hud_bar.visible:
		_obj_bar.visible = false
		return
	_obj_bar.visible = true
	_obj_text.text = String(obj.get("text", "—")).to_upper()
	_obj_sub.text = String(obj.get("subtext", ""))
	_obj_goto = obj.get("goto", {})
	var p := Director.progress()
	if p >= 0.0:
		_obj_bar_fill.visible = true
		_obj_bar_fill.value = p
	else:
		_obj_bar_fill.visible = false

func _money_chip(kind: String, col: Color) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", Pal.sb(Color(col, 0.10), 12, col, 1, 0))
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 14); m.add_theme_constant_override("margin_right", 14)
	m.add_theme_constant_override("margin_top", 8); m.add_theme_constant_override("margin_bottom", 8)
	var h := Pal.hbox(10)
	var icon := PanelContainer.new()
	icon.add_theme_stylebox_override("panel", Pal.sb(Color(0, 0, 0, 0), 4, col, 2, 0))
	icon.custom_minimum_size = Vector2(20, 20)
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(icon)
	var lbl := Pal.heading("£0", 32, col)
	h.add_child(lbl)
	m.add_child(h)
	p.add_child(m)
	if kind == "dirty": _hud_dirty = lbl
	else: _hud_clean = lbl
	return p

func _hud_stat_bar(cap: String, col: Color, is_energy: bool) -> HBoxContainer:
	var h := Pal.hbox(10)
	var c := Pal.label(cap, 20, col)
	c.custom_minimum_size = Vector2(34, 0)
	h.add_child(c)
	var b := _bar(col, 12)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(b)
	var val := Pal.label("", 20, Pal.TEXT2)
	h.add_child(val)
	if is_energy:
		_hud_en = b; _hud_en_lbl = val
	else:
		_hud_nv = b; _hud_nv_lbl = val
	return h

func _bar(col: Color, h: int) -> ProgressBar:
	var b := ProgressBar.new()
	b.show_percentage = false
	b.custom_minimum_size = Vector2(0, h)
	b.max_value = 1.0
	var bg := Pal.sb(Pal.INSET, h / 2, Color(0,0,0,0), 0, 0)
	var fg := Pal.sb(col, h / 2, Color(0,0,0,0), 0, 0)
	b.add_theme_stylebox_override("background", bg)
	b.add_theme_stylebox_override("fill", fg)
	return b

func _refresh_hud() -> void:
	if _hud_dirty == null: return
	# money text is animated in _process (count-up); don't set it here
	_hud_level.text = str(Game.level())
	# XP bar + pulse on gain
	var xp := Game.xp_progress()
	if _last_xp >= 0 and xp > _last_xp + 0.0001:
		var t := create_tween()
		t.tween_property(_hud_xp, "modulate", Color(1.5, 1.5, 1.2), 0.08)
		t.tween_property(_hud_xp, "modulate", Color.WHITE, 0.25)
	_last_xp = xp
	_hud_xp.value = xp
	_hud_en.value = float(Game.energy()) / float(Game.energy_cap())
	_hud_nv.value = float(Game.nerve()) / float(Game.NV_CAP)
	_hud_en_lbl.text = "%d/100" % Game.energy()
	_hud_nv_lbl.text = "%d/20" % Game.nerve()
	# heat — 5 pips mapped from the 0–10 heat scale
	var pips_on := int(ceil(Game.heat() / 2.0))
	for i in range(_hud_heat.get_child_count()):
		_hud_heat.get_child(i).color = Pal.DANGER_RED if i < pips_on else Pal.HAIRLINE
	if content.get_child_count() > 0 and content.get_child(0).has_method("refresh"):
		content.get_child(0).refresh()
	if _obj_bar and _obj_bar.visible:
		refresh_objective(Director.current())
	_refresh_heat_strip()

func _next_hook() -> String:
	var milestones: Dictionary = Config.levels.get("milestones", {})
	var best := 9999
	for k in milestones.keys():
		var lv := int(k)
		if lv > Game.level() and lv < best:
			best = lv
	if best == 9999:
		return "next: Lv %d" % (Game.level() + 1)
	return "NEXT: Lv %d · %s" % [best, milestones[str(best)]]

func _process(dt: float) -> void:
	if _hud_en == null: return
	_hud_en.value = float(Game.energy()) / float(Game.energy_cap())
	_hud_nv.value = float(Game.nerve()) / float(Game.NV_CAP)
	# money count-up / count-down
	var td := float(Game.dirty()); var tc := float(Game.clean())
	if _dd < 0: _dd = td
	if _dc < 0: _dc = tc
	_dd = move_toward(_dd, td, max(abs(td - _dd) * dt * 7.0, dt * 500.0))
	_dc = move_toward(_dc, tc, max(abs(tc - _dc) * dt * 7.0, dt * 500.0))
	_hud_dirty.text = Pal.money(int(round(_dd)))
	_hud_clean.text = Pal.money(int(round(_dc)))

# ------------------------------------------------------------------ NAV
func _build_nav() -> Control:
	var bar := PanelContainer.new()
	var st := Pal.sb(Pal.RAISED, 0, Color(0, 0, 0, 0), 0, 0)
	st.border_color = Pal.HAIRLINE
	st.set_border_width(SIDE_TOP, 1)
	bar.add_theme_stylebox_override("panel", st)
	bar.custom_minimum_size = Vector2(0, 160)
	var outer := Pal.vbox(0)
	bar.add_child(outer)
	_nav = Pal.hbox(0)
	_nav.custom_minimum_size = Vector2(0, 120)
	outer.add_child(_nav)
	var items := [["map", "MAP", "diamond", false], ["city", "CITY", "square", false], ["character", "CHAR", "circle", false], ["crew", "CREW", "shield", false], ["firm", "FIRM", "diamond2", false]]
	for it in items:
		var btn := Button.new()
		btn.flat = true
		btn.focus_mode = Control.FOCUS_NONE
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.custom_minimum_size = Vector2(0, 120)
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		var v := Pal.vbox(10)
		v.alignment = BoxContainer.ALIGNMENT_CENTER
		v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		v.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var icon := _NavIcon.new()
		icon.shape = it[2]
		icon.custom_minimum_size = Vector2(36, 36)
		icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		var t := Pal.label(it[1], 20, Pal.TEXT2)
		t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(icon); v.add_child(t)
		btn.add_child(v)
		var locked: bool = it[3]
		btn.set_meta("id", it[0]); btn.set_meta("icon", icon); btn.set_meta("txt", t); btn.set_meta("locked", locked)
		btn.pressed.connect(func():
			if locked:
				Game.toast.emit(String(it[1]).capitalize() + " unlocks later", Pal.TEXT2)
			else:
				show_screen(String(it[0])))
		_nav.add_child(btn)
	var home := CenterContainer.new()
	home.custom_minimum_size = Vector2(0, 40)
	var hb := ColorRect.new()
	hb.color = Pal.MUTED
	hb.custom_minimum_size = Vector2(200, 6)
	home.add_child(hb)
	outer.add_child(home)
	return bar

func _highlight_nav() -> void:
	for btn in _nav.get_children():
		var on: bool = btn.get_meta("id") == current
		var locked: bool = btn.get_meta("locked")
		var c: Color = Pal.SODIUM if on else (Pal.MUTED if locked else Pal.TEXT2)
		var icon: _NavIcon = btn.get_meta("icon")
		icon.col = c; icon.queue_redraw()
		btn.get_meta("txt").add_theme_color_override("font_color", c)
		var sbn: StyleBoxFlat
		if on:
			sbn = Pal.sb(Color(Pal.SODIUM, 0.10), 0)
			sbn.border_color = Pal.SODIUM
			sbn.set_border_width(SIDE_TOP, 4)
		else:
			sbn = Pal.sb(Color(0, 0, 0, 0), 0)
		btn.add_theme_stylebox_override("normal", sbn)
		btn.add_theme_stylebox_override("hover", sbn)
		btn.add_theme_stylebox_override("pressed", sbn)

class _NavIcon extends Control:
	var shape := "square"
	var col := Color.WHITE
	func _draw() -> void:
		var w := 2.0
		var c := size / 2.0
		var e: float = min(size.x, size.y) / 2.0 - 2.0
		match shape:
			"circle":
				draw_arc(c, e, 0, TAU, 40, col, w, true)
			"diamond", "diamond2":
				var p := PackedVector2Array([c + Vector2(0, -e), c + Vector2(e, 0), c + Vector2(0, e), c + Vector2(-e, 0), c + Vector2(0, -e)])
				draw_polyline(p, col, w, true)
			"shield":
				var pts := PackedVector2Array([c + Vector2(-e, -e), c + Vector2(e, -e), c + Vector2(e, e * 0.2), c + Vector2(0, e), c + Vector2(-e, e * 0.2), c + Vector2(-e, -e)])
				draw_polyline(pts, col, w, true)
			_:
				draw_rect(Rect2(c - Vector2(e, e), Vector2(e * 2, e * 2)), col, false, w)

# ------------------------------------------------------------------ screens
func show_screen(id: String, arg := "") -> void:
	# One city hub (WO2-T12.4). The canonical route is "city" → CityScreen. The old
	# "citymap" route id is kept as a back-compat alias so any lingering caller still
	# lands on the single hub.
	if id == "citymap": id = "city"
	current = id
	for c in content.get_children():
		c.queue_free()
	var sc: Control
	match id:
		"boot": sc = BootScreen.new()
		"login": sc = LoginScreen.new()
		"creation": sc = CreationScreen.new()
		"map": sc = MapScreen.new()
		"city": sc = CityScreen.new()
		"jobs": sc = JobsScreen.new(); sc.borough_id = arg
		"arena": sc = ArenaScreen.new()
		"catalogue": sc = CatalogueScreen.new()
		"feed": sc = FeedScreen.new()
		"character": sc = CharacterScreen.new(); sc.focus_arg = arg
		"gym": sc = GymScreen.new()
		"bank": sc = BankScreen.new()
		"shop": sc = GearShop.new()
		"fence": sc = ShopScreen.new(); sc.start_tab = "sell"
		"jail": sc = JailScreen.new()
		"crew": sc = CrewScreen.new()
		"messages": sc = MessagesScreen.new()
		"prison_call": sc = PrisonCallScreen.new()
		"firm": sc = FirmScreen.new()
		"board": sc = BoardScreen.new()
		"codex": sc = CodexScreen.new()
		"trapline": sc = TraplineScreen.new()
		"leaderboards": sc = LeaderboardsScreen.new()
		"paperwork": sc = PaperworkScreen.new()
		_: sc = MapScreen.new()
	# map/city/login are full-bleed; every other screen uses 32px side gutters
	var full := id == "map" or id == "city" or id == "login"
	var mx := 0 if full else 32
	var my := 0 if full else 16
	content.add_theme_constant_override("margin_left", mx)
	content.add_theme_constant_override("margin_right", mx)
	content.add_theme_constant_override("margin_top", my)
	content.add_theme_constant_override("margin_bottom", my)
	content.add_child(sc)
	# boot/login/creation/jail hide the chrome
	chrome_visible(id != "boot" and id != "login" and id != "creation" and id != "jail")
	_highlight_nav()
	# the new screen slides up + fades in instead of popping (login runs its own intro)
	if id != "login" and id != "boot":
		_animate_screen_in(sc)

## A quick reveal for a screen change — fade + a short upward slide. Waits one
## frame so the layout has placed the screen, then animates from an offset.
func _animate_screen_in(sc: Control) -> void:
	if not is_instance_valid(sc): return
	sc.modulate.a = 0.0
	Audio.whoosh()
	await get_tree().process_frame
	if not is_instance_valid(sc): return
	var home := sc.position
	sc.position = home + Vector2(0, 46)
	var t := create_tween().set_parallel(true)
	t.tween_property(sc, "position", home, 0.24).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t.tween_property(sc, "modulate:a", 1.0, 0.18)

# ------------------------------------------------------------------ session open
## The guide's session spine: greeter → collect → dailies, each stage handing to
## the next. Any stage with nothing to show is skipped.
func run_session_open() -> void:
	Telemetry.session_start()
	# an 8-week season may have rolled over while you were gone (Step 37)
	var roll := Season.check_rollover()
	if not roll.is_empty():
		Game.toast.emit("NEW SEASON · %s · +%s" % [str(roll.theme.get("name", "SEASON")), Pal.money(int(roll.reward))], Pal.HIVIS)
	# while you were away, other players' games came for your shadow (Step 31)
	Shadow.simulate_defences()
	# lapsed-player comeback (Step 35): hand back what accrued + remind them
	var cb := Comeback.evaluate()
	if int(cb.tier) > 0:
		var res := Comeback.apply(cb)
		var card := ComebackCard.new()
		card.setup(res, func(): _after_comeback())
		overlay.add_child(card)
	else:
		_after_comeback()

func _after_comeback() -> void:
	# level 20+ and unnamed → Uncle T names your path (Step 24), then carry on
	if Specialisation.ready_to_name():
		var sc := SpecScene.new()
		sc.setup(func(): Greeter.maybe_greet(func(): _session_collect()))
		overlay.add_child(sc)
	else:
		Greeter.maybe_greet(func(): _session_collect())

# ------------------------------------------------------------------ cloud resume
## Already signed in on this device — pull the cloud save, keep whichever is
## further along (never downgrade), and drop straight into the game.
func _boot_signed_in() -> void:
	show_screen("boot")
	var pull: Dictionary = await Cloud.pull_save()
	if pull.get("ok", false) and typeof(pull.get("state")) == TYPE_DICTIONARY and not (pull.state as Dictionary).is_empty():
		if progress_score(pull.state) > progress_score(Game.s):
			Game.s = pull.state
			Game._migrate()
			Game.persist()
		else:
			Cloud.queue_push()          # local is ahead — push it up so other devices catch up
	route_existing()

## A monotonic "how far along" score, so a merge always keeps the bigger save.
func progress_score(st: Dictionary) -> float:
	return float(int(st.get("level", 1))) * 1.0e9 \
		+ float(int(st.get("xp_into", 0))) * 1.0e3 \
		+ float(int(st.get("day", 1))) * 100.0 \
		+ float(int(st.get("respect", 0)))

## Route a returning, signed-in player to the right screen (shared with login).
func route_existing() -> void:
	if Game.s.get("prologue_done", false):
		Director.ensure_active()
	if Game.s.get("seen_intro", false) and String(Game.s.get("name", "")) != "":
		if Game.in_jail():
			show_screen("jail")
		elif not Game.s.get("prologue_done", false):
			show_screen("map"); _refresh_hud(); start_prologue()
		else:
			show_screen("map"); _refresh_hud(); run_session_open()
	else:
		show_screen("creation")

func _session_collect() -> void:
	if CollectOverlay.has_any():
		show_collect(func(): _session_dailies())
	else:
		_session_dailies()

func _session_dailies() -> void:
	# only the first session of the day gets the dailies conversation
	var today := Time.get_datetime_dict_from_system(false)
	var ds := "%04d-%02d-%02d" % [int(today.year), int(today.month), int(today.day)]
	if String(Game.s.get("_dailies_shown", "")) != ds:
		Game.s["_dailies_shown"] = ds
		Game.persist()
		show_daily()

func show_collect(on_done := Callable()) -> void:
	var c := CollectOverlay.new()
	c.setup(on_done)
	overlay.add_child(c)

# ------------------------------------------------------------------ overlays
func show_daily() -> void:
	overlay.add_child(DailyPanel.new())

# ------------------------------------------------------------------ story
func play_beat(bid: String, done := Callable()) -> void:
	var sc := StoryScene.new()
	sc.setup(bid, done)
	overlay.add_child(sc)

## Run the Hook (prologue) beat-by-beat, skipping any already completed, then
## drop the player into the world with the clock running.
func start_prologue() -> void:
	chrome_visible(false)
	_play_prologue_from(0)

func _play_prologue_from(i: int) -> void:
	if i >= Story.PROLOGUE.size():
		_end_prologue()
		return
	var bid: String = Story.PROLOGUE[i]
	if Story.completed(bid):
		_play_prologue_from(i + 1)
		return
	play_beat(bid, func(): _play_prologue_from(i + 1))

func _end_prologue() -> void:
	Game.s.prologue_done = true
	Game.persist()
	Director.ensure_active()
	show_screen("map")
	_refresh_hud()
	refresh_objective(Director.current())
	Game.toast.emit("Ninety days. The clock's running.", Pal.STROBE)

func _on_cast_reacted(_id: String, line: String, delta: int) -> void:
	if line == "":
		return
	_toast(line, Pal.INK if delta >= 0 else Pal.CONCRETE)

func show_encounter(enc: Dictionary, on_done := Callable()) -> void:
	var card := ChoiceCard.new()
	card.setup(enc, on_done)
	overlay.add_child(card)

func show_reveal(outcome: Dictionary, on_done := Callable()) -> void:
	var rev := RevealOverlay.new()
	rev.setup(outcome, on_done)
	overlay.add_child(rev)

## Run the minigame beat for a job over the card, await it, return {score, detail}.
## The active-input moment (WO2) sits between [GO] and resolve. Awaitable at the
## call site; the host force-resolves after 14s and always emits exactly once.
func run_minigame(ctx: Dictionary) -> Dictionary:
	var host := MinigameHost.new()
	overlay.add_child(host)
	host.begin(ctx)
	var out: Array = await host.resolved
	return {"score": float(out[0]), "detail": out[1]}

func show_levelup(level: int, unlock: String, on_done := Callable()) -> void:
	var c := LevelUpCeremony.new()
	c.setup(level, unlock, on_done)
	overlay.add_child(c)

## Play a chain of level-up ceremonies (from a multi-level XP gain), then done.
func play_levelups(levels: Array, done := Callable()) -> void:
	if levels.is_empty():
		if done.is_valid(): done.call()
		return
	var rest := levels.duplicate()
	var lvl: int = rest.pop_front()
	# crossing into a new rank gets the full-screen ceremony (Step 23)
	var new_rank := str(Config.rank_for_level(lvl).get("name", ""))
	var old_rank := str(Config.rank_for_level(lvl - 1).get("name", ""))
	show_levelup(lvl, Game.milestone_unlock(lvl), func():
		if new_rank != old_rank and new_rank != "" and lvl > 1:
			Feed.post("came up to %s. Say it with respect." % new_rank)
			var rc := RankCeremony.new()
			rc.setup(new_rank, Game.milestone_unlock(lvl), func(): play_levelups(rest, done))
			overlay.add_child(rc)
		else:
			play_levelups(rest, done))

func _toast(text: String, color: Color) -> void:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", Pal.sb(Color("#0E1114F2"), 12, color, 0, 14))
	var box := Pal.hbox(10)
	var strip := ColorRect.new(); strip.color = color; strip.custom_minimum_size = Vector2(4, 0)
	box.add_child(strip)
	box.add_child(Pal.text(text, 24, color, 800))
	p.add_child(box)
	p.modulate.a = 0.0
	toast_box.add_child(p)
	var tw := create_tween()
	tw.tween_property(p, "modulate:a", 1.0, 0.15)
	tw.tween_interval(2.4)
	tw.tween_property(p, "modulate:a", 0.0, 0.4)
	tw.tween_callback(p.queue_free)

func _milestone(text: String) -> void:
	Audio.level_up()
	var st := InkStamp.new()
	st.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	overlay.add_child(st)
	st.setup(text, Pal.HIVIS, -0.09)
	var tw := create_tween()
	tw.tween_interval(1.5)
	tw.tween_property(st, "modulate:a", 0.0, 0.5)
	tw.tween_callback(st.queue_free)

# ------------------------------------------------------------------ self test
## Headless playthrough smoke test — proves the core loop logic works.
func _self_test() -> void:
	Game.reset()
	Game.new_character("Tester", 0, "road")
	var jobs := ["phone_snatch", "pickpocket", "shoplift"]
	var levelups := 0
	Game.leveled_up.connect(func(_l, _u): levelups += 1)
	var successes := 0
	var total := 60
	var arrests := 0
	for i in range(total):
		Game.s.energy.v = 100000; Game.s.energy.t = Game.now()
		Game.s.nerve.v = 100000; Game.s.nerve.t = Game.now()
		Game.release()                    # test resolution, not the 60s jail block
		Game.s.heat.v = 0.0; Game.s.heat.t = Game.now()
		var jid: String = jobs[i % jobs.size()]
		var res: Dictionary = await ServerGateway.resolve_job(jid, -1)
		if res.get("arrested"): arrests += 1
		if res.get("ok") and res.get("success"):
			successes += 1
	print("SELFTEST arrests_when_hot=", arrests)
	print("SELFTEST jobs=%d success=%d level=%d dirty=%d xp_into=%d clean=%d" % [total, successes, Game.level(), Game.dirty(), int(Game.s.xp_into), Game.clean()])
	print("SELFTEST rank=%s energy_cap=%d stat_points=%d" % [Game.rank_name(), Game.energy_cap(), int(Game.s.stat_points)])
	# greeter dismissal smoke test — proves the card opens AND can be tapped away
	Game.s.prologue_done = true
	Game.s.session = {"last_end": 0}
	Game.s["_greet_date"] = ""
	Greeter.maybe_greet(Callable())
	await get_tree().process_frame
	var card: Node = null
	for c in overlay.get_children():
		if c.has_method("_advance"): card = c
	if card == null:
		print("SELFTEST greeter=MISSING")
	else:
		for _n in range(5):
			if is_instance_valid(card): card._advance()
		await get_tree().process_frame
		var still := false
		for c in overlay.get_children():
			if c.has_method("_advance"): still = true
		print("SELFTEST greeter_opened=true greeter_dismissed=", not still)
	# director objective present after prologue
	Director.ensure_active()
	print("SELFTEST objective=", Director.current().get("text", "NONE"))
	# shadow players (Step 30): pool populated, opponent matched within power window
	var mypow := Shadow.power(Shadow.own_snapshot())
	var foe := Shadow.pick_opponent()
	var fpow := Shadow.power(foe)
	print("SELFTEST shadow pool=%d mypow=%d foe=%s foepow=%d" % [Shadow.pool().size(), mypow, foe.get("display_name", "?"), fpow])
	# defence reports (Step 31): simulate a long gap, expect truthful reports queued
	Game.s.session["last_end"] = Game.now() - 2 * 86400.0
	Game.s.shadow = {"last_attacked": {}, "pending_reports": []}
	Shadow.simulate_defences()
	print("SELFTEST defence_reports=", Shadow.pending_reports().size())
	# combat timeline (Step 27): a full fight produces a playable beat list
	var foe2 := Shadow.pick_opponent()
	var me2 := {"name": "YOU", "str": int(Game.s.stats.strength), "tgh": int(Game.s.stats.toughness), "spd": int(Game.s.stats.speed)}
	var fight := Combat.fight(me2, Shadow.to_attacker(foe2, "test"), 12345)
	var kinds := {}
	for beat in fight.timeline:
		kinds[beat.result] = int(kinds.get(beat.result, 0)) + 1
	print("SELFTEST combat rounds=%d beats=%d won=%s ko=%s kinds=%s" % [int(fight.rounds), fight.timeline.size(), str(fight.won), str(fight.ko), str(kinds)])
	# stat mechanic sweep (Step: stats really matter): a clearly stronger fighter
	# should win the large majority, and each stat should shift the result upward
	var strong := {"str": 18, "tgh": 16, "spd": 14, "slk": 12}
	var weak := {"str": 7, "tgh": 7, "spd": 7, "slk": 7}
	var sw := 0
	for i in range(80):
		if Combat.fight(strong, weak, 1000 + i).won: sw += 1
	var base := {"str": 10, "tgh": 10, "spd": 10, "slk": 10}
	var win_with := func(buff: Dictionary) -> int:
		var f2: Dictionary = base.duplicate(); for k in buff: f2[k] = int(base[k]) + int(buff[k])
		var w := 0
		for i in range(80):
			if Combat.fight(f2, base, 2000 + i).won: w += 1
		return w
	print("SELFTEST stats strong_wins=%d/80 +6STR=%d +6TGH=%d +6SPD=%d +6SLK=%d (vs even ~40)" % [
		sw, win_with.call({"str": 6}), win_with.call({"tgh": 6}), win_with.call({"spd": 6}), win_with.call({"slk": 6})])
	# The Street roster: stable, scaled, each carries a reward
	var roster := Shadow.street_roster("london|the_strip|3", Game.level(), 5)
	var roster2 := Shadow.street_roster("london|the_strip|3", Game.level(), 5)
	var stable: bool = roster.size() == 5 and str(roster[0].display_name) == str(roster2[0].display_name)
	print("SELFTEST street n=%d stable=%s first=%s pow=%d reward=%d/%dxp" % [
		roster.size(), str(stable), str(roster[0].display_name), int(roster[0].power),
		int(roster[0].reward_dirty), int(roster[0].reward_xp)])
	# arena glue: real screen instantiates, a win pays out, a fight launches CombatView
	var arena := ArenaScreen.new()
	add_child(arena)
	await get_tree().process_frame
	var opp: Dictionary = arena._roster[0]
	var d0 := Game.dirty(); var r0 := int(Game.s.get("respect", 0))
	arena._result(opp, true)
	arena._fight(opp)
	await get_tree().process_frame
	var has_cv := false
	for c in overlay.get_children():
		if c is CombatView: has_cv = true
	print("SELFTEST arena win_paid=%s respect_up=%s fight_launches=%s" % [
		str(Game.dirty() > d0), str(int(Game.s.respect) > r0), str(has_cv)])
	for c in overlay.get_children():
		if c is CombatView: c.queue_free()
	arena.queue_free()
	# audio: the procedural synth baked real, non-silent WAVs into the voice pool
	var abaked := 0; var aloud := false
	for k in ["tap", "ui", "cash", "coin", "reveal", "crit", "level_up", "error", "whoosh", "hit", "unlock"]:
		if Audio._cache.has(k):
			abaked += 1
			var d: PackedByteArray = Audio._cache[k].data
			for bi in range(0, min(d.size(), 8000), 2):
				if abs(int(d[bi + 1]) << 8) > 512: aloud = true; break
	print("SELFTEST audio baked=%d/11 audible=%s voices=%d" % [abaked, str(aloud), Audio._pool.size()])
	print("SELFTEST OK")
	get_tree().quit()

# ------------------------------------------------------------------ minigame smoke
## ENDS_MGTEST=1 — headless: instantiate every registered minigame, run setup()+
## run(), tick a few frames (catches _process crashes), then skip() and assert it
## emits finished(). Also proves the host builds. Not a feel test — a crash net.
func _minigame_test() -> void:
	Game.reset()
	Game.new_character("MG", 0, "road")
	var ok := 0
	var fail := 0
	var built: Array = []
	for jid in MinigameRegistry.MAP.keys():
		if jid in built: continue      # each scene once
		var path := MinigameRegistry.path_for(jid)
		if path in built: continue
		built.append(path)
		if not ResourceLoader.exists(path):
			print("MGTEST %-16s SCENE NOT BUILT YET" % jid); continue
		var mg := MinigameRegistry.make(jid)
		if mg == null:
			print("MGTEST %-16s make()=null" % jid); fail += 1; continue
		var got := [false, 0.0]
		mg.finished.connect(func(s, _d): got[0] = true; got[1] = s)
		mg.custom_minimum_size = Vector2(1080, 900)
		add_child(mg)
		mg.size = Vector2(1080, 900)
		await get_tree().process_frame
		mg.setup({
			"job_id": jid, "job_name": jid, "tier": 1, "approach": "", "tools": [],
			"crew": ["alone"], "stat_value": 10.0, "difficulty": 0.4, "stage_index": 0,
			"vignette": "smoke test", "scene": MinigameRegistry.scene_for(jid),
		})
		mg.run()
		for _i in range(8):
			await get_tree().process_frame
		if not got[0]:
			mg.skip()
			await get_tree().process_frame
		if got[0]: ok += 1
		else: fail += 1
		print("MGTEST %-16s run+skip emitted=%s score=%.2f" % [jid, str(got[0]), got[1]])
		if is_instance_valid(mg): mg.queue_free()
	# also prove the host assembles without a crash
	var host := MinigameHost.new()
	add_child(host)
	host.begin({"job_id": "phone_snatch", "vignette": "host smoke", "stat_value": 10.0, "difficulty": 0.3})
	await get_tree().process_frame
	print("MGTEST host_built=%s" % str(is_instance_valid(host)))
	if is_instance_valid(host): host.queue_free()
	print("MGTEST TOTAL ok=%d fail=%d" % [ok, fail])
	print("MGTEST OK")
	get_tree().quit()

# ------------------------------------------------------------------ reaction windows
## ENDS_MGWIN=1 — the WO3 reaction-window table. For each minigame that declares
## req_windows(), print the actual required reaction window (ms) at base stats
## (5, diff 0.4, stage 0), the spec's "hardest" (60, 0.9, stage 4), and the TRUE
## narrowest case (5, 0.9, stage 4). Any window < 250ms is a FAIL.
func _minigame_window_table() -> void:
	Game.reset()
	Game.new_character("Win", 0, "road")
	print("MGWIN %-16s %-14s %9s %11s %10s  %s" % ["MINIGAME", "INPUT", "BASE(ms)", "HARDEST(ms)", "WORST(ms)", "FLOOR_OK"])
	var seen: Array = []
	for jid in MinigameRegistry.MAP.keys():
		var path := MinigameRegistry.path_for(jid)
		if path in seen or not ResourceLoader.exists(path):
			continue
		seen.append(path)
		var mg := MinigameRegistry.make(jid)
		if mg == null or not mg.has_method("req_windows"):
			continue
		add_child(mg)
		var name := mg.mg_id()
		for row in mg.call("req_windows"):
			var label: String = row[0]
			var base_ms: float = row[1]
			var min_ms: float = row[2]
			var b := _win_at(mg, 5.0, 0.4, 0, base_ms, min_ms)
			var h := _win_at(mg, 60.0, 0.9, 4, base_ms, min_ms)
			var w := _win_at(mg, 5.0, 0.9, 4, base_ms, min_ms)
			# FLOOR_OK: does the WORST case meet this input's own specified floor?
			# (green's floor is 300; gold is the nested skill-ceiling bonus, floor 120)
			var ok: bool = w >= min_ms - 0.5
			print("MGWIN %-16s %-14s %9d %11d %10d  %s (floor %d)" % [name, label, int(round(b)), int(round(h)), int(round(w)), ("OK" if ok else "FAIL"), int(min_ms)])
		mg.queue_free()
	print("MGWIN DONE")
	get_tree().quit()

func _win_at(mg: Minigame, stat_v: float, diff: float, stage: int, base_ms: float, min_ms: float) -> float:
	mg.setup({"stat_value": stat_v, "difficulty": diff, "stage_index": stage})
	return mg.window_ms(base_ms, min_ms)

# ------------------------------------------------------------------ balance sim
## ENDS_BALANCE=1 — a playtest harness. Part A reads every job's tuning in
## isolation (real Resolver, neutral ctx, level-appropriate stats). Part B runs a
## full greedy progression through the real gateway to measure the pace to the
## milestone levels. No screenshots — pure numbers for tuning.
func _balance_sim() -> void:
	Game.reset()
	Game.new_character("Bal", 0, "road")
	var jobs: Dictionary = Config.jobs
	var order := ["phone_snatch", "pickpocket", "shoplift", "burglary", "corner_shotting",
		"grow_harvest", "counterfeit", "extortion", "protection", "card_fraud", "chop_run",
		"ram_raid", "warehouse", "smuggle", "gun_deal"]
	print("BAL === PER-JOB (isolated: matched stats, danger 3, skill 3, gear +0.05, streak off) ===")
	print("BAL job                tier req  base  win%%   avg£   £/EN  xp/EN  heat")
	for jid in order:
		if not jobs.has(jid): continue
		var job: Dictionary = (jobs[jid] as Dictionary).duplicate(true)
		job["id"] = jid
		var req: int = int(job.get("level_req", 1))
		var sval: int = 8 + int(round(req * 0.9))
		var ctx := {"stats": {"strength": sval, "toughness": sval, "speed": sval, "slickness": sval},
			"skill": 3, "level": req + 2, "danger": 3, "payout_mult": 1.0, "crew_bonus": 0.0}
		var wins := 0; var sum_d := 0.0; var sum_x := 0.0; var sum_h := 0.0; var sum_item := 0.0
		var N := 500
		for i in range(N):
			var o := Resolver.resolve(job, ctx, 7000 + i * 13)
			if o.success: wins += 1
			sum_d += float(o.dirty); sum_x += float(o.xp); sum_h += float(o.heat)
			for it in o.get("items", []): sum_item += float(it.get("value", 0))
		var en: float = max(1.0, float(job.get("energy", 6)))
		var avg_take := (sum_d + sum_item) / N
		print("BAL %-18s t%d  %2d  %.2f  %4.0f%%  %5.0f  %5.1f  %5.2f  %.2f" % [
			jid, int(job.get("tier", 1)), req, float(job.get("base_chance", 0.6)),
			100.0 * wins / N, avg_take, avg_take / en, (sum_x / N) / en, sum_h / N])

	# Part B: greedy progression through the real gateway (streak, city mult, heat)
	print("BAL === PROGRESSION (greedy best-qualified job, real gateway, rest when spent) ===")
	Game.reset(); Game.new_character("Bal", 0, "road")
	Game.s.prologue_done = true
	var city_at := {5: "manchester", 10: "birmingham", 15: "liverpool", 20: "glasgow", 25: "leeds", 40: "nottingham"}
	var milestones := [5, 10, 15, 20, 25, 40, 47]
	var mi := 0
	var njobs := 0; var days := 1; var arrests := 0
	var start_stats := 9
	for k in Game.s.stats: Game.s.stats[k] = start_stats
	while Game.level() < 47 and njobs < 4000:
		# train stats roughly in step with level so checks stay winnable
		var want: int = 9 + Game.level()
		for k in Game.s.stats:
			if int(Game.s.stats[k]) < want: Game.s.stats[k] = want
		# move city as levels unlock (payout/danger shift)
		for lv in city_at:
			if Game.level() >= lv and Game.s.city != city_at[lv] and Game.level() < lv + 5:
				Game.s.city = city_at[lv]
		# pick the highest-req job we qualify for that exists in the current city
		var pool: Array = []
		for b in Config.city(Game.s.city).get("boroughs", []):
			for j in b.get("jobs", []): pool.append(j)
		var best := ""; var best_req := -1
		for jid in pool:
			var r: int = int(Config.job(jid).get("level_req", 1))
			if Game.level() >= r and r > best_req: best_req = r; best = jid
		if best == "": best = "phone_snatch"
		var jd := Config.job(best)
		# rest a day when we can't afford the pick
		if Game.energy() < int(jd.get("energy", 6)) or Game.nerve() < int(jd.get("nerve", 2)):
			Game.rest(); days += 1
			if Game.heat() >= 6.0: Heat.lay_low()   # a real player would go home
			continue
		Game.release()
		var res: Dictionary = await ServerGateway.resolve_job(best, -1)
		njobs += 1
		if res.get("arrested"): arrests += 1
		while mi < milestones.size() and Game.level() >= milestones[mi]:
			print("BAL  L%-2d @ job %4d / day %3d  clean+dirty=£%d  heat=%.1f  city=%s" % [
				milestones[mi], njobs, days, Game.dirty() + Game.clean(), Game.heat(), Game.s.city])
			mi += 1
	print("BAL DONE jobs=%d days=%d arrests=%d final_L=%d bank=£%d" % [njobs, days, arrests, Game.level(), Game.dirty() + Game.clean()])
	print("BAL OK")
	get_tree().quit()

# ------------------------------------------------------------------ screenshot
func _capture() -> void:
	for i in range(4):
		await get_tree().process_frame
	# let animations (confetti, count-up, stamps) play before the shot
	var delay := float(OS.get_environment("ENDS_SHOT_DELAY"))
	if delay > 0:
		await get_tree().create_timer(delay).timeout
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var name := OS.get_environment("ENDS_SHOT_NAME")
	if name == "": name = "_shot"
	img.save_png("/Users/jakubschnierer/hra/godot/" + name + ".png")
	print("SHOT_SAVED ", name)
	get_tree().quit()

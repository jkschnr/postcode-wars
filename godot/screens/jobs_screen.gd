class_name JobsScreen
extends Control
## The Board (design screen 03): street strip · STORY / CONTRACTS / GRAFT.
## Story & contract cards are data (data/jobs_board.json) for now; graft cards are
## the real borough jobs and run the confirm→resolve→reveal flow.

var borough_id := ""
var _list: VBoxContainer

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if borough_id == "":
		borough_id = Game.s.get("borough", "the_strip")
	Game.s.borough = borough_id
	var scroll := Pal.scroll()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(scroll)
	_list = Pal.vbox(18)
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_list)
	_rebuild()

func _borough() -> Dictionary:
	for b in Config.city(Game.s.city).get("boroughs", []):
		if b.get("id", "") == borough_id:
			return b
	var bs: Array = Config.city(Game.s.city).get("boroughs", [])
	return bs[0] if bs.size() > 0 else {}

func _rebuild() -> void:
	for c in _list.get_children(): c.queue_free()
	var b := _borough()
	_list.add_child(_strip(b))
	var board: Dictionary = Config._json("res://data/jobs_board.json")

	# Story jobs are a linear questline surfaced one at a time: hide any beat
	# already played, gate on the prior beat + a level, show the first eligible.
	var story: Array = board.get("story", [])
	var live_story: Array = []
	for s in story:
		var beat: String = str(s.get("beat", ""))
		if beat != "" and Story.completed(beat): continue
		var after: String = str(s.get("after", ""))
		if after != "" and not Story.completed(after): continue
		if Game.level() < int(s.get("min_level", 0)): continue
		live_story.append(s)
		break   # one story beat on the board at a time
	if live_story.size() > 0:
		_list.add_child(_section("STORY", "CH.%d" % max(1, Story.act() + 1)))
		for s in live_story:
			_list.add_child(_story_card(s))

	var contracts: Array = board.get("contracts", [])
	if contracts.size() > 0:
		_list.add_child(_section("CONTRACTS", "%d OPEN" % contracts.size()))
		for c in contracts:
			_list.add_child(_contract_card(c))

	_list.add_child(_section("GRAFT", "REPEATABLE"))
	for jid in b.get("jobs", []):
		_list.add_child(_graft_card(jid, b))

# ---------- header strip ----------
func _strip(b: Dictionary) -> Control:
	var band := PanelContainer.new()
	band.custom_minimum_size = Vector2(0, 300)
	band.clip_contents = true
	band.add_theme_stylebox_override("panel", Pal.sb(Pal.INSET, 12, Pal.RAISED, 1, 0))
	var bg := TextureRect.new()
	bg.texture = Pal.city_tex(Game.s.city)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	bg.modulate = Color(0.8, 0.75, 0.62)
	band.add_child(bg)
	var shade := ColorRect.new()
	shade.color = Color(0.07, 0.08, 0.09, 0.5)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	band.add_child(shade)
	var back := Pal.btn("← CITY", "secondary", 60)
	back.add_theme_font_override("font", Pal.mono_font(500)); back.add_theme_font_size_override("font_size", 20)
	back.custom_minimum_size = Vector2(180, 60); back.position = Vector2(24, 20)
	back.pressed.connect(func(): App.I.show_screen("city"))
	band.add_child(back)
	var chips := Pal.hbox(10)
	chips.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	chips.position = Vector2(-320, 24)
	chips.add_child(Pal.chip("HEAT %d/5" % int(ceil(Game.heat() / 2.0)), Pal.DANGER_RED, Pal.DANGER_RED))
	chips.add_child(Pal.chip("%d JOBS" % (b.get("jobs", []) as Array).size(), Pal.SODIUM, Pal.SODIUM))
	band.add_child(chips)
	var m := MarginContainer.new()
	m.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	m.add_theme_constant_override("margin_left", 32); m.add_theme_constant_override("margin_bottom", 24)
	var col := Pal.vbox(2)
	col.alignment = BoxContainer.ALIGNMENT_END
	col.add_child(Pal.heading("THE BOARD", 64, Pal.TEXT))
	col.add_child(Pal.label("%s · %s · WHAT'S GOING TONIGHT" % [String(b.get("name", "Area")).to_upper(), String(b.get("postcode", "")).to_upper()], 20, Pal.SODIUM, 500))
	m.add_child(col)
	band.add_child(m)
	return band

func _section(cap: String, right: String) -> Control:
	var h := Pal.sechead(cap)
	h.add_child(Pal.label(right, 20, Pal.MUTED, 400))
	return h

# ---------- cards ----------
func _chip_row(items: Array) -> HBoxContainer:
	var row := Pal.hbox(10)
	for it in items:
		row.add_child(Pal.chip(str(it[0]), it[1], Color(it[1], 0.5)))
	return row

func _story_card(s: Dictionary) -> Control:
	var p := PanelContainer.new()
	var st := Pal.sb(Pal.PANEL, 16, Pal.RAISED, 1, 0)
	st.border_color = Pal.SODIUM
	st.set_border_width(SIDE_LEFT, 8)
	p.add_theme_stylebox_override("panel", st)
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 20); m.add_theme_constant_override("margin_right", 20)
	m.add_theme_constant_override("margin_top", 18); m.add_theme_constant_override("margin_bottom", 18)
	var v := Pal.vbox(12)
	var top := Pal.hbox(16)
	var sp := Pal.portrait_frame(Pal.cast_portrait(str(s.get("speaker", ""))), 96, Pal.SODIUM)
	sp.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top.add_child(sp)
	var tv := Pal.vbox(4)
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tv.add_child(Pal.label("STORY  " + str(s.get("tag", "")), 20, Pal.SODIUM, 500))
	tv.add_child(Pal.heading(str(s.get("title", "")), 40, Pal.TEXT))
	tv.add_child(Pal.text(str(s.get("scene", "")), 24, Pal.TEXT2, 400, true))
	top.add_child(tv)
	v.add_child(top)
	var chips := Pal.hbox(10)
	chips.add_child(Pal.chip("EN %d" % int(s.get("en", 0)), Pal.SODIUM, Color(Pal.SODIUM, 0.5)))
	chips.add_child(Pal.chip("NV %d" % int(s.get("nv", 0)), Pal.NERVE, Color(Pal.NERVE, 0.5)))
	chips.add_child(Pal.chip(str(s.get("note", "STORY")), Pal.SODIUM, Pal.SODIUM))
	v.add_child(chips)
	m.add_child(v); p.add_child(m)
	return _tap_wrap(p, func():
		var beat: String = str(s.get("beat", ""))
		if beat != "":
			App.I.play_beat(beat, func():
				App.I._refresh_hud()
				if is_inside_tree(): _rebuild())
		else:
			Game.toast.emit("Story job — wiring to the arc next", Pal.SODIUM))

func _contract_card(c: Dictionary) -> Control:
	var p := Pal.panel()
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 20); m.add_theme_constant_override("margin_right", 20)
	m.add_theme_constant_override("margin_top", 18); m.add_theme_constant_override("margin_bottom", 18)
	var v := Pal.vbox(12)
	var top := Pal.hbox(16)
	var cp := Pal.portrait_slot(Pal.cast_portrait(str(c.get("speaker", ""))), 96, "ledger")
	cp.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top.add_child(cp)
	var tv := Pal.vbox(4)
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var tagrow := Pal.hbox(10)
	tagrow.add_child(Pal.label(str(c.get("tag", "")), 20, Pal.SODIUM, 500))
	tagrow.add_child(Pal.spacer())
	tagrow.add_child(Pal.label("EXPIRES %s" % str(c.get("expires", "")), 20, Pal.DANGER_RED, 500))
	tv.add_child(tagrow)
	tv.add_child(Pal.heading(str(c.get("title", "")), 40, Pal.TEXT))
	tv.add_child(Pal.text(str(c.get("scene", "")), 24, Pal.TEXT2, 400, true))
	top.add_child(tv)
	v.add_child(top)
	var chips := Pal.hbox(10)
	chips.add_child(Pal.chip("EN %d" % int(c.get("en", 0)), Pal.SODIUM, Color(Pal.SODIUM, 0.5)))
	chips.add_child(Pal.chip("NV %d" % int(c.get("nv", 0)), Pal.NERVE, Color(Pal.NERVE, 0.5)))
	chips.add_child(Pal.chip(str(c.get("pay", "")), Pal.DIRTY, Color(Pal.DIRTY, 0.5)))
	chips.add_child(Pal.chip("XP +%d" % int(c.get("xp", 0)), Pal.TEXT, Pal.RAISED))
	chips.add_child(_pct_chip(int(c.get("chance", 50))))
	v.add_child(chips)
	m.add_child(v); p.add_child(m)
	return _tap_wrap(p, func(): _do_contract(c))

func _do_contract(c: Dictionary) -> void:
	Audio.ui()
	var res: Dictionary = await ServerGateway.resolve_contract(c)
	if not res.get("ok", false):
		Game.toast.emit(res.get("reason", "Can't"), Pal.DANGER_RED); Audio.error(); return
	if res.get("success", false):
		Game.ledger_add(str(c.get("title", "A contract")), "You ran it for %s. It's on the books now." % str(c.get("tag", "them")))
	App.I.show_reveal(res, func(): _post_job())

func _graft_card(jid: String, b: Dictionary) -> Control:
	var job := Config.job(jid)
	var pv := ServerGateway.preview_job(jid, -1)
	var locked: bool = Game.level() < int(pv.level_req)
	var cased: bool = Casing.is_cased(jid)
	var p := Pal.panel()
	if cased:
		p.add_theme_stylebox_override("panel", Pal.sb(Color(Pal.SODIUM, 0.08), 16, Pal.SODIUM, 2, 0))
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 20); m.add_theme_constant_override("margin_right", 20)
	m.add_theme_constant_override("margin_top", 18); m.add_theme_constant_override("margin_bottom", 18)
	var v := Pal.vbox(12)
	var top := Pal.hbox(10)
	var tier := int(job.get("tier", 1))
	var badge := Pal.chip("TIER %s" % _roman(tier), Pal.SODIUM, Pal.SODIUM)
	top.add_child(badge)
	top.add_child(Pal.label(String(b.get("name", "")).to_upper(), 20, Pal.MUTED, 500))
	if cased:
		top.add_child(Pal.chip("CASED · %dH" % Casing.hours_left(jid), Pal.SODIUM, Pal.SODIUM))
	top.add_child(Pal.spacer())
	top.add_child(Pal.label("DANGER", 18, Pal.MUTED, 400))
	top.add_child(Pal.pips(int(b.get("danger", 3)), 5, Pal.DANGER_RED, 14))
	v.add_child(top)
	v.add_child(Pal.heading(String(job.get("name", "Job")).to_upper(), 40, Pal.TEXT if not locked else Pal.MUTED))
	if locked:
		v.add_child(Pal.label("🔒 UNLOCKS AT LEVEL %d" % int(pv.level_req), 22, Pal.DANGER_RED, 500))
	else:
		var lo := int(pv.payout[0] * pv.payout_mult)
		var hi := int(pv.payout[1] * pv.payout_mult)
		var chips := Pal.hbox(10)
		chips.add_child(Pal.chip("EN %d" % int(pv.energy), Pal.SODIUM, Color(Pal.SODIUM, 0.5)))
		chips.add_child(Pal.chip("NV %d" % int(pv.nerve), Pal.NERVE, Color(Pal.NERVE, 0.5)))
		chips.add_child(Pal.chip("%s–%s" % [Pal.money(lo), Pal.money(hi)], Pal.DIRTY, Color(Pal.DIRTY, 0.5)))
		chips.add_child(Pal.chip("XP +%d" % int(pv.xp), Pal.TEXT, Pal.RAISED))
		chips.add_child(_pct_chip(int(round(pv.chance * 100))))
		v.add_child(chips)
		v.add_child(Pal.bar(pv.chance, Pal.SODIUM, 8))
	m.add_child(v); p.add_child(m)
	if locked:
		return p
	return _tap_wrap(p, func(): _tap_job(jid))

func _pct_chip(pct: int) -> Control:
	var col := Pal.CLEAN if pct >= 60 else (Pal.SODIUM if pct >= 45 else Pal.DANGER_RED)
	return Pal.chip("%d%%" % pct, col, col)

func _roman(n: int) -> String:
	return ["I", "II", "III", "IV"][clampi(n - 1, 0, 3)]

## Wrap a display panel so the whole card is tappable.
func _tap_wrap(panel: PanelContainer, cb: Callable) -> Control:
	var b := Button.new()
	b.flat = true
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.add_theme_stylebox_override("normal", Pal.sb(Color(0, 0, 0, 0), 0))
	b.add_theme_stylebox_override("hover", Pal.sb(Color(0, 0, 0, 0), 0))
	b.add_theme_stylebox_override("pressed", Pal.sb(Color(0, 0, 0, 0), 0))
	b.pressed.connect(func(): cb.call())
	# MarginContainer sizes to the panel's min height; the button overlays full-rect
	var wrap := MarginContainer.new()
	wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	wrap.add_child(panel)
	b.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	wrap.add_child(b)
	return wrap

# ---------- confirm / resolve (kept for wiring) ----------
func _tap_job(jid: String) -> void:
	Audio.ui()
	var vig := Vignettes.pick(jid)
	var job := Config.job(jid)
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.03, 0.04, 0.8)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	App.I.overlay.add_child(dim)
	var wrap := CenterContainer.new()
	wrap.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.add_child(wrap)
	var p := Pal.panel()
	p.custom_minimum_size = Vector2(1000, 0)
	var mm := MarginContainer.new()
	mm.add_theme_constant_override("margin_left", 40); mm.add_theme_constant_override("margin_right", 40)
	mm.add_theme_constant_override("margin_top", 36); mm.add_theme_constant_override("margin_bottom", 36)
	var v := Pal.vbox(18)
	mm.add_child(v); p.add_child(mm)
	wrap.add_child(p)

	v.add_child(Pal.label("JOB BRIEF", 22, Pal.SODIUM, 500))
	v.add_child(Pal.heading(String(job.get("name", "Job")).to_upper(), 56, Pal.TEXT))
	var tline := Vignettes.target_line(vig)
	if tline != "":
		v.add_child(Pal.label("MARK:  " + tline.to_upper(), 20, Pal.SODIUM, 500))

	# casing (Step 29): a scoped target is waiting for you — +30% and the intel
	var casebox := Pal.vbox(8)
	v.add_child(casebox)
	_fill_casing(casebox, jid, func(): dim.queue_free())

	# the loadout: three real decisions (guide Step 16). A plain dict, mutated by
	# the segmented controls; the card rebuilds its live section on every change.
	var ld := Loadout.default()
	var section := Pal.vbox(16)
	v.add_child(section)
	var close := func(): dim.queue_free()
	var rebuild := func(): pass          # forward-declared so closures can call it
	rebuild = func(): _build_loadout(section, jid, job, vig, ld, rebuild, close)
	rebuild.call()

func _cell(cap: String, val: String, col: Color) -> Control:
	var p := Pal.inset_panel()
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 18); m.add_theme_constant_override("margin_right", 18)
	m.add_theme_constant_override("margin_top", 14); m.add_theme_constant_override("margin_bottom", 14)
	var v := Pal.vbox(6)
	v.add_child(Pal.label(cap, 18, Pal.MUTED, 500))
	v.add_child(Pal.heading(val, 34, col))
	m.add_child(v); p.add_child(m)
	return p

## Rebuildable loadout section of the confirm card (Step 16). Rebuilds itself on
## every choice so the numbers and selected states stay honest and live.
func _build_loadout(section: VBoxContainer, jid: String, job: Dictionary, vig: Dictionary, ld: Dictionary, rebuild: Callable, close: Callable) -> void:
	for c in section.get_children(): c.queue_free()
	var pv := ServerGateway.preview_job(jid, -1, ld)

	# flavour line follows the approach
	var appr := Loadout.approach_meta(str(ld.approach))
	section.add_child(Pal.text(str(appr.get("flavor", job.get("blurb", ""))), 24, Pal.TEXT2, 400, true))

	# live numbers
	var grid := GridContainer.new(); grid.columns = 2
	grid.add_theme_constant_override("h_separation", 12); grid.add_theme_constant_override("v_separation", 12)
	var lo := int(pv.payout[0] * pv.payout_mult)
	var hi := int(pv.payout[1] * pv.payout_mult)
	grid.add_child(_cell("EST. TAKE", "%s–%s" % [Pal.money(lo), Pal.money(hi)], Pal.DIRTY))
	grid.add_child(_cell("SUCCESS", "%d%%" % int(round(pv.chance * 100)), Pal.CLEAN if pv.chance >= 0.6 else Pal.SODIUM))
	grid.add_child(_cell("HEAT", "+%.1f" % float(pv.heat), Pal.POLICE if float(pv.heat) >= 2.0 else Pal.TEXT))
	grid.add_child(_cell("XP", "+%d" % int(pv.xp), Pal.SODIUM))
	section.add_child(grid)

	# 1 — APPROACH
	section.add_child(Pal.label("HOW YOU PLAYING IT?", 18, Pal.SODIUM, 500))
	var arow := Pal.hbox(10)
	for aid in Loadout.APPROACHES:
		var this_id: String = aid
		var meta := Loadout.approach_meta(aid)
		var b := _seg_btn(str(meta.get("label", aid)), ld.approach == aid)
		b.pressed.connect(func(): Audio.ui(); ld.approach = this_id; rebuild.call())
		arow.add_child(b)
	section.add_child(arow)

	# 2 — TOOLS (only what you own)
	var tools := Loadout.owned_tools()
	if tools.size() > 0:
		section.add_child(Pal.label("WHAT YOU'RE CARRYING", 18, Pal.SODIUM, 500))
		var trow := Pal.hbox(10)
		trow.custom_minimum_size = Vector2(0, 0)
		for tid in tools:
			var this_tid: String = tid
			var tm := Loadout.tool_meta(tid)
			var on: bool = ld.tools.has(tid)
			var b := _seg_btn(str(tm.get("label", tid)), on)
			b.pressed.connect(func():
				Audio.ui()
				if ld.tools.has(this_tid): ld.tools.erase(this_tid)
				else: ld.tools.append(this_tid)
				rebuild.call())
			trow.add_child(b)
		section.add_child(trow)

	# 3 — WHO YOU BRING
	section.add_child(Pal.label("WHO YOU BRING", 18, Pal.SODIUM, 500))
	var crow := Pal.hbox(10)
	for cid in Loadout.CREWS:
		var this_cid: String = cid
		var cm := Loadout.crew_meta(cid)
		var b := _seg_btn(str(cm.get("label", cid)), ld.crew == cid)
		b.pressed.connect(func(): Audio.ui(); ld.crew = this_cid; rebuild.call())
		crow.add_child(b)
	section.add_child(crow)
	var cmeta := Loadout.crew_meta(str(ld.crew))
	if str(ld.crew) != "alone":
		var note := str(cmeta.get("note", ""))
		if float(cmeta.get("cut", 0)) > 0: note += "  (−%d%% cut)" % int(round(float(cmeta.cut) * 100))
		section.add_child(Pal.label(note, 16, Pal.MUTED, 400))

	# GO / NOT NOW
	var go := Pal.btn("GO", "hivis", 108)
	go.pressed.connect(func(): close.call(); _do_job(jid, ld, vig))
	section.add_child(go)
	var cancel := Pal.btn("NOT NOW", "secondary", 88)
	cancel.pressed.connect(func(): Audio.ui(); close.call())
	section.add_child(cancel)

## A segmented-control button: hi-vis when selected, quiet when not.
func _seg_btn(label: String, selected: bool) -> Button:
	var b := Pal.btn(label, "hivis" if selected else "secondary", 80)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.custom_minimum_size = Vector2(0, 80)
	return b

func _do_job(jid: String, ld: Dictionary, vig := {}) -> void:
	# push-your-luck jobs (guide Step 17): spend the entry cost, then run the
	# room-by-room stage flow which produces its own reveal. The loadout's crew can
	# unlock extra stages (Step 16 × Step 17).
	if Config.stages_for(jid).size() > 0:
		var job := Config.job(jid)
		if Game.in_jail():
			Game.toast.emit("You're banged up", Pal.DANGER_RED); return
		if Game.level() < int(job.get("level_req", 1)):
			Game.toast.emit("Level %d needed" % int(job.get("level_req", 1)), Pal.DANGER_RED); return
		if not Game.spend_energy(int(job.get("energy", 6))):
			Game.toast.emit("Not enough Energy", Pal.DANGER_RED); Audio.error(); return
		Game.spend_nerve(int(job.get("nerve", 2)))
		var pv := ServerGateway.preview_job(jid, -1, ld)
		var base := int(_rng_between(int(pv.payout[0] * pv.payout_mult), int(pv.payout[1] * pv.payout_mult)))
		var stages := JobStages.new()
		stages.setup(jid, base, vig, func(res): _after_stage_run(res))
		App.I.overlay.add_child(stages)
		return
	# WO2: the active-input beat. If this job has a minigame scene built, play it
	# over the card and let the score nudge the outcome ±15%; otherwise resolve at
	# the neutral 0.4 baseline (identical to the pre-minigame behaviour).
	var mscore := 0.4
	var mdetail: Dictionary = {}
	if MinigameRegistry.has(jid) and ResourceLoader.exists(MinigameRegistry.path_for(jid)):
		var mg: Dictionary = await App.I.run_minigame(_mg_ctx(jid, ld, vig))
		mscore = float(mg.get("score", 0.4))
		mdetail = mg.get("detail", {})
	var res: Dictionary = await ServerGateway.resolve_job(jid, -1, false, ld, mscore)
	if not res.get("ok", false):
		if not res.get("cancelled", false):
			Game.toast.emit(res.get("reason", "Can't do that"), Pal.DANGER_RED)
			Audio.error()
		return
	if not mdetail.is_empty():
		res["mg_detail"] = str(mdetail.get("detail", ""))
	if res.get("panicked", false):
		res["flavor"] = "It went wrong before it started. Your younger bottled it and you both walked — fast, empty-handed."
	else:
		res["flavor"] = Vignettes.flavor(vig, res)
	Vignettes.mark_seen(str(vig.get("id", "")))
	# named victims that land leave a mark in the Ledger of Consequences
	if res.get("success", false):
		var tname: String = str(vig.get("target", {}).get("name", ""))
		if tname != "" and tname != "null":
			Game.ledger_add("%s · %s" % [tname, Config.job(jid).get("name", "Job")], str(res.get("flavor", "")))
	if res.get("arrested", false):
		Audio.error()
		Game.toast.emit("NICKED — lost " + Pal.money(int(res.get("dirty_lost", 0))) + " dirty", Pal.DANGER_RED)
		App.I.show_screen("jail")
		return
	App.I.show_reveal(res, func(): _post_job())

## After a job's reveal is dismissed: refresh the list, then give the world a
## chance to step to you (guide Step 26). Never fires on arrest paths — those
## return to jail before ever calling this.
func _post_job() -> void:
	_rebuild()
	Ambush.maybe_trigger("post_job")

## The casing block on the confirm card — either the intel you scoped, or a CASE
## IT button that scopes it (free, waits 48h) and shows the result.
func _fill_casing(box: VBoxContainer, jid: String, close: Callable) -> void:
	for c in box.get_children(): c.queue_free()
	if Casing.is_cased(jid):
		box.add_child(Pal.label("CASED · +30%% · %dH LEFT" % Casing.hours_left(jid), 18, Pal.SODIUM, 500))
		box.add_child(Pal.text(Casing.flavor(jid), 20, Pal.TEXT2, 400, true))
	else:
		var b := Pal.btn("CASE IT FIRST  ·  free, ready tonight", "secondary", 76)
		b.pressed.connect(func(): close.call(); _case_job(jid))
		box.add_child(b)

func _case_job(jid: String) -> void:
	Audio.ui()
	Game.s["_cased_total"] = int(Game.s.get("_cased_total", 0)) + 1   # objective: target_cased
	var f := Casing.case_target(jid)
	# result card
	var dim := ColorRect.new(); dim.color = Color(0.02, 0.03, 0.04, 0.82)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); dim.mouse_filter = Control.MOUSE_FILTER_STOP
	App.I.overlay.add_child(dim)
	var wrap := CenterContainer.new(); wrap.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dim.add_child(wrap)
	var p := Pal.panel(); p.custom_minimum_size = Vector2(940, 0)
	var m := MarginContainer.new()
	for s in ["left", "right", "top", "bottom"]: m.add_theme_constant_override("margin_" + s, 36)
	var v := Pal.vbox(16)
	v.add_child(Pal.label("YOU HAD A LOOK", 20, Pal.SODIUM, 500))
	v.add_child(Pal.heading(Config.job(jid).get("name", "The job").to_upper(), 44, Pal.TEXT))
	v.add_child(Pal.text("\"%s\"" % f, 26, Pal.TEXT2, 400, true))
	v.add_child(Pal.label("+30% SUCCESS · WINDOW OPEN 48H", 18, Pal.CLEAN, 500))
	var ok := Pal.btn("GOOD. COME BACK TONIGHT.", "hivis", 96)
	ok.pressed.connect(func(): Audio.ui(); dim.queue_free(); _rebuild())
	v.add_child(ok)
	m.add_child(v); p.add_child(m); wrap.add_child(p)
	Game.toast.emit("Cased %s — it's waiting for you" % Config.job(jid).get("name", "the job"), Pal.SODIUM)

func _rng_between(lo: int, hi: int) -> int:
	if hi <= lo: return lo
	return lo + (randi() % (hi - lo + 1))

## Build the ctx a minigame reads (WO2). stat_value is the job's PRIMARY stat (so a
## well-built player gets an easier beat), difficulty folds tier + city/borough
## danger + approach, and the vignette's setup line rides along under the play area.
func _mg_ctx(jid: String, ld: Dictionary, vig: Dictionary) -> Dictionary:
	var job := Config.job(jid)
	var stat_name := String(job.get("stat", "slickness"))
	var city := Config.city(Game.s.city)
	var danger := int(city.get("danger", 3))
	for b in city.get("boroughs", []):
		if b.get("id", "") == Game.s.get("borough", ""):
			danger = int(b.get("danger", danger))
	var tier := int(job.get("tier", 1))
	var diff: float = clampf(0.20 + (tier - 1) * 0.22 + (danger - 3) * 0.05, 0.05, 0.95)
	return {
		"job_id": jid,
		"job_name": String(job.get("name", "Job")),
		"tier": tier,
		"approach": String(ld.get("approach", "")),
		"tools": ld.get("tools", []),
		"crew": [String(ld.get("crew", "alone"))],
		"stat_value": float(Game.eff_stat(stat_name)),
		"stat_name": stat_name,
		"skill": Game.skill_level(jid),
		"difficulty": diff,
		"stage_index": 0,
		"vignette": String(vig.get("setup", "")),
		"scene": MinigameRegistry.scene_for(jid),
	}

## Push-your-luck run finished — it already applied money/xp; show the reveal or
## route to jail on a caught-and-nicked outcome.
func _after_stage_run(res: Dictionary) -> void:
	if res.get("arrested", false):
		Audio.error()
		Game.toast.emit("NICKED — lost " + Pal.money(int(res.get("dirty_lost", 0))) + " dirty", Pal.DANGER_RED)
		App.I.show_screen("jail")
		return
	App.I.show_reveal(res, func(): _post_job())

func refresh() -> void:
	if _list: _rebuild()

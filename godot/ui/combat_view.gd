class_name CombatView
extends Control
## The fight, staged (guide Step 27) — a Shakes-&-Fidget-style arena. Both fighters
## stand on a night-street backdrop, each flanked by a live STATS card (attributes
## + derived combat numbers). A VS intro sizes them up, then the Combat timeline is
## animated beat by beat: lunges, hit-flash, screen shake, floating damage, DODGED /
## BLOCKED / CRIT callouts, HP and stamina draining live, and a KO finish. Tap SKIP
## to jump to the result. Deterministic underneath — it only shows what Combat.fight
## already decided from the seed.

signal finished(won: bool)

const VW := 1080.0
const VH := 1920.0
const FRAME_W := 452.0
const FRAME_H := 520.0
const YOU_X := 46.0
const THEM_X := VW - FRAME_W - 46.0
const NAME_Y := 146.0
const HP_Y := 230.0
const STAM_Y := 266.0
const FRAME_Y := 300.0
const GROUND_Y := 820.0
const CARD_Y := 872.0
const CALLOUT_Y := 520.0

var _you_stats: Dictionary
var _them_stats: Dictionary
var _seed: int
var _on_done: Callable
var _fight: Dictionary
var _you_f: Dictionary
var _them_f: Dictionary
var _stage: Control
var _round_lbl: Label
var _commentary: Label
var _skip_btn: Button
var _skipping := false
var _done := false
var _ui := {"you": {}, "them": {}}

# WO2-T12.2 read layer: each round you may read the opponent (STRIKE/GUARD/RUSH) and
# swing the fight up to ±20%. No input = the fight resolves exactly as Combat decided.
var _them_move_by_round := {}
var _read_rounds := {}
var _read_choice := ""
var _off_pts := 0.0
var _def_pts := 0.0
var _your_reads := 0

func setup(you_stats: Dictionary, them_stats: Dictionary, seed: int, on_done: Callable) -> void:
	_you_stats = you_stats
	_them_stats = them_stats
	_seed = seed
	_on_done = on_done

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_fight = Combat.fight(_you_stats, _them_stats, _seed)
	_you_f = Combat.make_fighter(_you_stats, "you")
	_them_f = Combat.make_fighter(_them_stats, "them")
	# what the opponent throws each round — drives the tell you read against
	for b in _fight.timeline:
		if b.actor == "them" and not _them_move_by_round.has(int(b.round)):
			_them_move_by_round[int(b.round)] = String(b.move)

	_build_backdrop()

	_stage = Control.new()
	_stage.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_stage)

	# round banner in a chip
	var chip := PanelContainer.new()
	chip.add_theme_stylebox_override("panel", Pal.sb(Color("#0C0E10", 0.85), 20, Color(Pal.SODIUM, 0.5), 1, 0))
	chip.position = Vector2(VW / 2.0 - 150, 64); chip.custom_minimum_size = Vector2(300, 0)
	var chm := MarginContainer.new()
	chm.add_theme_constant_override("margin_left", 24); chm.add_theme_constant_override("margin_right", 24)
	chm.add_theme_constant_override("margin_top", 8); chm.add_theme_constant_override("margin_bottom", 8)
	_round_lbl = Pal.label("SQUARING UP", 24, Pal.SODIUM, 500)
	_round_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chm.add_child(_round_lbl); chip.add_child(chm)
	_stage.add_child(chip)

	# fighters
	_build_fighter("you", YOU_X, str(_you_stats.get("name", "YOU")), _you_stats.get("doll", Doll.DEF), false, Pal.CLEAN, int(_you_stats.get("level", Game.level())))
	_build_fighter("them", THEM_X, str(_them_stats.get("name", "RIVAL")), _them_stats.get("doll", Doll.DEF), true, Pal.DANGER_RED, int(_them_stats.get("level", 1)))

	# stats cards under each fighter (the Shakes-&-Fidget touch — always visible)
	_stage.add_child(_stat_card(YOU_X, _you_stats, _you_f, Pal.CLEAN))
	_stage.add_child(_stat_card(THEM_X, _them_stats, _them_f, Pal.DANGER_RED))

	# centre VS medallion
	var vs := Pal.heading("VS", 46, Pal.TEXT)
	vs.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vs.position = Vector2(VW / 2.0 - 70, 500); vs.size.x = 140
	vs.custom_minimum_size = Vector2(140, 0)
	_stage.add_child(vs)
	_ui["vs"] = vs

	# commentary
	_commentary = Pal.label("", 26, Pal.TEXT, 500)
	_commentary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_commentary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_commentary.custom_minimum_size = Vector2(VW - 140, 0)
	_commentary.position = Vector2(70, 1250); _commentary.size.x = VW - 140
	_stage.add_child(_commentary)

	# skip
	_skip_btn = Pal.btn("SKIP", "secondary", 84)
	_skip_btn.custom_minimum_size = Vector2(300, 84)
	_skip_btn.position = Vector2(VW / 2.0 - 150, 1720)
	_skip_btn.pressed.connect(_on_skip)
	_stage.add_child(_skip_btn)

	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.3)
	Audio.error()
	_intro()

# ---------------------------------------------------------------- backdrop
func _build_backdrop() -> void:
	var bg := ColorRect.new(); bg.color = Color("#05060A")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bg)
	# night sky gradient
	var sky := TextureRect.new()
	sky.texture = _vgrad([Color("#141A2A"), Color("#20242E"), Color("#31251C")], [0.0, 0.6, 1.0])
	sky.position = Vector2(0, 0); sky.size = Vector2(VW, GROUND_Y + 20)
	sky.stretch_mode = TextureRect.STRETCH_SCALE
	sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(sky)
	# lamp glow high up
	var glow := TextureRect.new(); glow.texture = Pal.radial_glow()
	glow.modulate = Color(Pal.SODIUM, 0.5)
	glow.position = Vector2(VW / 2.0 - 520, -260); glow.size = Vector2(1040, 1040)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(glow)
	# skyline + rain
	var sk := _Skyline.new()
	sk.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sk.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(sk)
	var rain := _Rain.new()
	rain.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rain.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(rain)
	# wet tarmac ground with a sodium reflection streak
	var ground := TextureRect.new()
	ground.texture = _vgrad([Color("#12100E"), Color("#08090C")], [0.0, 1.0])
	ground.position = Vector2(0, GROUND_Y); ground.size = Vector2(VW, VH - GROUND_Y)
	ground.stretch_mode = TextureRect.STRETCH_SCALE
	ground.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ground)
	var refl := ColorRect.new(); refl.color = Color(Pal.SODIUM, 0.05)
	refl.position = Vector2(0, GROUND_Y); refl.size = Vector2(VW, 120)
	refl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(refl)

func _vgrad(cols: Array, offs: Array) -> GradientTexture2D:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array(offs)
	g.colors = PackedColorArray(cols)
	var t := GradientTexture2D.new()
	t.gradient = g; t.width = 8; t.height = 256
	t.fill_from = Vector2(0, 0); t.fill_to = Vector2(0, 1)
	return t

# ---------------------------------------------------------------- fighters
func _build_fighter(side: String, x: float, name: String, cfg: Dictionary, flip: bool, accent: Color, lvl: int) -> void:
	var col := side
	var nm := Pal.heading(name, 34, Pal.TEXT)
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nm.position = Vector2(x, NAME_Y); nm.size.x = FRAME_W
	nm.custom_minimum_size = Vector2(FRAME_W, 0)
	_stage.add_child(nm)
	var lv := Pal.label("LVL %d" % lvl, 18, accent, 500)
	lv.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lv.position = Vector2(x, NAME_Y + 44); lv.size.x = FRAME_W
	_stage.add_child(lv)

	var hp := _bar(x, HP_Y, FRAME_W, 26, Pal.DANGER_RED)
	var hp_lbl := Pal.label("", 18, Pal.TEXT, 500)
	hp_lbl.position = Vector2(x, HP_Y - 2); hp_lbl.size.x = FRAME_W
	hp_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stage.add_child(hp_lbl)
	var st := _bar(x + 44, STAM_Y, FRAME_W - 88, 10, Pal.SODIUM)

	# doll plate — a lit box the fighter stands in
	var frame := PanelContainer.new()
	frame.position = Vector2(x, FRAME_Y); frame.custom_minimum_size = Vector2(FRAME_W, FRAME_H)
	frame.size = Vector2(FRAME_W, FRAME_H)
	var sb := Pal.sb(Color("#0A0C0F", 0.72), 18, accent, 2, 0)
	frame.add_theme_stylebox_override("panel", sb)
	frame.clip_contents = true
	# soft floor shadow inside the plate
	var floor := ColorRect.new(); floor.color = Color(0, 0, 0, 0.35)
	floor.position = Vector2(0, FRAME_H - 42); floor.size = Vector2(FRAME_W, 42)
	frame.add_child(floor)
	var dv := DollView.new()
	dv.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dv.view = "full"
	if flip:
		dv.scale = Vector2(-1, 1)
		dv.pivot_offset = Vector2(FRAME_W / 2.0, FRAME_H / 2.0)
	dv.set_cfg(cfg)
	dv.set_combat(true)
	frame.add_child(dv)
	# weapon in the hand — the equipped weapon item, drawn over the doll on the
	# inner (opponent-facing) side, thrusts forward on each strike
	var wid := str((_you_stats if side == "you" else _them_stats).get("weapon", ""))
	if wid != "" and not Config.item(wid).is_empty():
		var wep := ItemView.new()
		var wsz := 132.0
		wep.custom_minimum_size = Vector2(wsz, wsz); wep.size = Vector2(wsz, wsz)
		wep.set_item(Config.item(wid))
		wep.pivot_offset = Vector2(wsz / 2.0, wsz / 2.0)
		# held on the inner (opponent-facing) side at hand height, angled forward
		wep.position = Vector2(FRAME_W - wsz - 22, FRAME_H * 0.42)
		wep.rotation = deg_to_rad(62)
		if flip:
			wep.scale = Vector2(-1, 1)
			wep.position = Vector2(22, FRAME_H * 0.42)
		frame.add_child(wep)
	_stage.add_child(frame)

	_ui[col] = {
		"frame": frame, "doll": dv, "accent": accent,
		"hp_fill": hp.fill, "hp_w": hp.w, "hp_lbl": hp_lbl,
		"st_fill": st.fill, "st_w": st.w,
		"home_x": x,
	}
	var hpm := int(_you_f.hp_max) if side == "you" else int(_them_f.hp_max)
	_set_hp(col, hpm, hpm)
	_set_stam(col, 1.0)

## A Shakes-&-Fidget-style stats card: attributes on the left, the combat numbers
## they drive on the right, plus a crit line. Stays on screen through the fight.
func _stat_card(x: float, raw: Dictionary, f: Dictionary, accent: Color) -> Control:
	var card := PanelContainer.new()
	card.position = Vector2(x, CARD_Y); card.custom_minimum_size = Vector2(FRAME_W, 300)
	card.add_theme_stylebox_override("panel", Pal.sb(Color("#0C0E10", 0.92), 14, Color(accent, 0.55), 1, 0))
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 22); m.add_theme_constant_override("margin_right", 22)
	m.add_theme_constant_override("margin_top", 16); m.add_theme_constant_override("margin_bottom", 16)
	var v := Pal.vbox(10)
	v.add_child(Pal.label("STATS", 16, accent, 500))
	var grid := GridContainer.new(); grid.columns = 2
	grid.add_theme_constant_override("h_separation", 26); grid.add_theme_constant_override("v_separation", 7)
	grid.add_child(_stat_line("STRENGTH", int(raw.get("str", 5)), Pal.TEXT))
	grid.add_child(_stat_line("HEALTH", int(f.hp_max), Pal.DANGER_RED))
	grid.add_child(_stat_line("TOUGHNESS", int(raw.get("tgh", 5)), Pal.TEXT))
	grid.add_child(_stat_line("DAMAGE", int(round(f.atk)), Pal.SODIUM))
	grid.add_child(_stat_line("SPEED", int(raw.get("spd", 5)), Pal.TEXT))
	grid.add_child(_stat_line("ARMOUR", int(round(f.def)), Pal.POLICE))
	grid.add_child(_stat_line("SLICKNESS", int(raw.get("slk", raw.get("slickness", 5))), Pal.TEXT))
	grid.add_child(_stat_line("EVASION", int(round(float(f.get("evasion", 0.0)) * 100.0)), Pal.NERVE, "%"))
	v.add_child(grid)
	var crit := Pal.label("CRIT  %d%%" % int(round(float(f.crit) * 100.0)), 15, Pal.MUTED, 500)
	v.add_child(crit)
	m.add_child(v); card.add_child(m)
	return card

func _stat_line(label: String, value: int, col: Color, suffix := "") -> Control:
	var row := Pal.hbox(8)
	row.custom_minimum_size = Vector2(180, 0)
	var l := Pal.label(label, 16, Pal.TEXT2, 400)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(l)
	var val := Pal.heading(str(value) + suffix, 23, col)
	row.add_child(val)
	return row

func _bar(x: float, y: float, w: float, h: float, col: Color) -> Dictionary:
	var track := PanelContainer.new()
	track.position = Vector2(x, y); track.custom_minimum_size = Vector2(w, h); track.size = Vector2(w, h)
	track.add_theme_stylebox_override("panel", Pal.sb(Color("#000000", 0.6), int(h / 2.0), Color(Pal.HAIRLINE, 0.6), 1, 0))
	track.clip_contents = true
	var fill := ColorRect.new()
	fill.color = col; fill.position = Vector2(0, 0); fill.size = Vector2(w, h)
	track.add_child(fill)
	_stage.add_child(track)
	return {"track": track, "fill": fill, "w": w}

func _set_hp(side: String, hp: int, hp_max: int) -> void:
	var u: Dictionary = _ui[side]
	if u.is_empty(): return
	var frac := clampf(float(hp) / float(max(1, hp_max)), 0.0, 1.0)
	u.hp_fill.size.x = u.hp_w * frac
	u.hp_fill.color = Pal.DANGER_RED if frac > 0.33 else Color("#7A1F1F")
	u.hp_lbl.text = "%d / %d" % [max(0, hp), hp_max]

func _set_stam(side: String, frac: float) -> void:
	var u: Dictionary = _ui[side]
	if u.is_empty(): return
	u.st_fill.size.x = u.st_w * clampf(frac, 0.0, 1.0)

# ---------------------------------------------------------------- playback
func _intro() -> void:
	await _wait(0.2)
	if _done: return
	# medallion pop
	var vs: Label = _ui.get("vs", null)
	if vs != null:
		vs.scale = Vector2(2.2, 2.2); vs.pivot_offset = Vector2(70, 30); vs.modulate.a = 0.0
		var t := create_tween().set_parallel(true)
		t.tween_property(vs, "modulate:a", 1.0, 0.25)
		t.tween_property(vs, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK)
	_commentary.text = "%s wants it. Sort it out." % _nm()
	await _wait(1.1)
	if _done or _skipping: return
	if vs != null: create_tween().tween_property(vs, "modulate:a", 0.25, 0.3)
	_play()

func _play() -> void:
	for beat in _fight.timeline:
		if _done: return
		if _skipping: break
		await _play_beat(beat)
	if _done: return
	_show_outcome()

func _play_beat(beat: Dictionary) -> void:
	var actor: String = beat.actor
	var target: String = "them" if actor == "you" else "you"
	_round_lbl.text = "ROUND %d" % int(beat.round)
	# WO2-T12.2: once per round, before your first swing, offer a read
	if actor == "you" and not _skipping and not _read_rounds.has(int(beat.round)):
		_read_rounds[int(beat.round)] = true
		await _do_read(int(beat.round))
		if _done: return
	var au: Dictionary = _ui[actor]
	var tu: Dictionary = _ui[target]

	if beat.move == "guard":
		au.doll.set_pose(0.0, true)              # arms up
		_commentary.text = ("You cover up, get your wind back." if actor == "you"
			else "%s covers up, gets a breather." % _nm())
		_pulse(au.frame, Pal.SODIUM)
		Audio.ui()
		_apply_bars(beat)
		await _wait(0.42)
		au.doll.set_pose(0.0, false)
		return

	var dir := 1.0 if actor == "you" else -1.0
	var heavy: bool = beat.move == "haymaker"
	var lunge := (64.0 if heavy else 50.0) * dir
	au.doll.set_pose(0.35, false)                # wind up
	var tw := create_tween().set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(au.frame, "position:x", au.home_x + lunge, 0.13).set_ease(Tween.EASE_OUT)
	tw.tween_property(au.frame, "position:x", au.home_x, 0.20).set_ease(Tween.EASE_IN)

	match String(beat.result):
		"dodge":
			await _wait(0.13)
			au.doll.set_pose(1.0, false)          # full reach — but they slip it
			var back: float = tu.home_x + (24.0 if target == "you" else -24.0)
			var d := create_tween().set_trans(Tween.TRANS_SINE)
			d.tween_property(tu.frame, "position:x", back, 0.10)
			d.tween_property(tu.frame, "position:x", tu.home_x, 0.14)
			_callout(target, "SLIPPED IT", Pal.TEXT2)
			_commentary.text = ("You throw — %s slips it." % _nm() if actor == "you"
				else "%s throws — you slip it clean." % _nm())
			Audio.ui()
		"whiff":
			await _wait(0.13)
			au.doll.set_pose(1.0, false)
			_callout(actor, "MISS", Pal.MUTED)
			_commentary.text = ("You swing and find nothing but air." if actor == "you"
				else "%s swings and finds nothing but air." % _nm())
		_:
			await _wait(0.15)
			au.doll.set_pose(1.0, false)          # connect at full extension
			var crit: bool = beat.result == "crit"
			var block: bool = beat.result == "block"
			_hit_flash(target)
			_recoil(target, dir)
			_shake(10.0 if crit else (6.0 if heavy else 4.0))
			if crit:
				_callout(target, "-%d  CRIT" % int(beat.dmg), Pal.SODIUM, 1.5)
				_commentary.text = ("You catch %s clean. That'll leave a mark." % _nm() if actor == "you"
					else "%s catches you clean. That hurt." % _nm())
				Audio.hit(1.3); Audio.crit()
			elif block:
				_callout(target, "-%d  BLOCK" % int(beat.dmg), Pal.TEXT2)
				_commentary.text = ("You get a hand up — take it on the guard." if target == "you"
					else "%s gets a hand up — takes it on the arm." % _nm())
				Audio.ui()
			else:
				_callout(target, "-%d" % int(beat.dmg), Pal.DANGER_RED)
				var verb: String = _verb(beat.move, actor)
				_commentary.text = ("You %s — it lands." % verb if actor == "you"
					else "%s %s — it lands." % [_nm(), verb])
				Audio.hit(1.0 if heavy else 0.7)
	_apply_bars(beat)
	await _wait(0.22)
	au.doll.set_pose(0.0, false)                  # recover to guard-down idle
	await _wait(0.08)

## The 3-second read window. Shows the opponent's tell + STRIKE/GUARD/RUSH; the
## player picks (or lets it lapse → neutral, the auto path). Accumulates points that
## _show_outcome turns into a clamped ±20% swing.
func _do_read(rnd: int) -> void:
	if _skipping or _done:
		return
	var opp: String = _them_move_by_round.get(rnd, "jab")
	_read_choice = ""

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", Pal.sb(Color("#0C0E10", 0.94), 18, Color(Pal.SODIUM, 0.6), 2, 0))
	panel.position = Vector2(VW / 2.0 - 460, 1180); panel.custom_minimum_size = Vector2(920, 0)
	var m := MarginContainer.new()
	for s in ["left", "right", "top", "bottom"]: m.add_theme_constant_override("margin_" + s, 22)
	var v := Pal.vbox(14)
	var tell := Pal.label("READ HIM — %s" % Combat.tell_for(opp).to_upper(), 26, Pal.SODIUM, 500)
	tell.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(tell)
	var row := Pal.hbox(14)
	for choice in Combat.READS:
		var b := Pal.btn(choice, "secondary", 92)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var this_choice: String = choice
		b.pressed.connect(func(): _read_choice = this_choice)
		row.add_child(b)
	v.add_child(row)
	m.add_child(v); panel.add_child(m)
	_stage.add_child(panel)

	var deadline := 3.0
	while _read_choice == "" and deadline > 0.0 and not _skipping and not _done:
		await get_tree().process_frame
		deadline -= get_process_delta_time()
	panel.queue_free()
	if _read_choice == "":
		return                                   # lapsed → neutral, no swing
	_your_reads += 1
	var o := Combat.read_outcome(_read_choice, opp)
	if o.correct:
		if _read_choice == "GUARD":
			_def_pts += 1.0
			_callout("you", "READ — GUARD", Pal.CLEAN)
		else:
			_off_pts += 1.0
			_callout("them", "READ — %s" % _read_choice, Pal.SODIUM)
		Audio.coin()
	else:
		_off_pts -= 0.5
		_callout("you", "OUT-READ", Pal.MUTED)
		Audio.error()

## Turn the accumulated read points into a clamped HP swing (≤20% each way).
func _read_adjust() -> Array:
	var off := 0.0
	var deff := 0.0
	if _your_reads > 0:
		off = clampf(_off_pts / float(_your_reads), -1.0, 1.0) * float(_them_f.hp_max) * 0.20
		deff = clampf(_def_pts / float(_your_reads), 0.0, 1.0) * float(_you_f.hp_max) * 0.20
	var adj_you: int = int(clampf(float(_fight.you_hp) + deff, 0.0, float(_you_f.hp_max)))
	var adj_them: int = int(clampf(float(_fight.them_hp) - off, 0.0, float(_them_f.hp_max)))
	return [adj_you, adj_them]

func _apply_bars(beat: Dictionary) -> void:
	_tween_hp("you", int(beat.you_hp), int(beat.you_hp_max))
	_tween_hp("them", int(beat.them_hp), int(beat.them_hp_max))
	_set_stam("you", float(beat.you_stam) / 100.0)
	_set_stam("them", float(beat.them_stam) / 100.0)

func _tween_hp(side: String, hp: int, hp_max: int) -> void:
	var u: Dictionary = _ui[side]
	if u.is_empty(): return
	var frac := clampf(float(hp) / float(max(1, hp_max)), 0.0, 1.0)
	u.hp_lbl.text = "%d / %d" % [max(0, hp), hp_max]
	u.hp_fill.color = Pal.DANGER_RED if frac > 0.33 else Color("#7A1F1F")
	create_tween().set_trans(Tween.TRANS_QUAD).tween_property(u.hp_fill, "size:x", u.hp_w * frac, 0.28)

# ---------------------------------------------------------------- fx
func _hit_flash(side: String) -> void:
	var u: Dictionary = _ui[side]
	if u.is_empty(): return
	var flash := ColorRect.new(); flash.color = Color(1, 1, 1, 0.0)
	flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	u.frame.add_child(flash)
	var t := create_tween()
	t.tween_property(flash, "color", Color(Pal.DANGER_RED, 0.55), 0.05)
	t.tween_property(flash, "color", Color(1, 1, 1, 0.0), 0.22)
	t.tween_callback(flash.queue_free)

## The target gets knocked back in the direction of the blow, then steadies.
func _recoil(side: String, dir: float) -> void:
	var u: Dictionary = _ui[side]
	if u.is_empty(): return
	var f: Control = u.frame
	var t := create_tween().set_trans(Tween.TRANS_BACK)
	t.tween_property(f, "position:x", u.home_x + dir * 22.0, 0.08).set_ease(Tween.EASE_OUT)
	t.tween_property(f, "position:x", u.home_x, 0.22).set_ease(Tween.EASE_OUT)

func _pulse(frame: Control, col: Color) -> void:
	var glow := ColorRect.new(); glow.color = Color(col, 0.0)
	glow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(glow)
	var t := create_tween()
	t.tween_property(glow, "color", Color(col, 0.22), 0.12)
	t.tween_property(glow, "color", Color(col, 0.0), 0.30)
	t.tween_callback(glow.queue_free)

func _callout(side: String, text: String, col: Color, scale := 1.0) -> void:
	var u: Dictionary = _ui[side]
	if u.is_empty(): return
	for pass_i in range(2):
		var is_shadow := pass_i == 0
		var lbl := Pal.heading(text, int(52 * scale), Color(0, 0, 0, 0.7) if is_shadow else col)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.size.x = FRAME_W; lbl.custom_minimum_size = Vector2(FRAME_W, 0)
		lbl.position = Vector2(u.home_x + (3 if is_shadow else 0), CALLOUT_Y + (3 if is_shadow else 0))
		lbl.z_index = 9 if is_shadow else 10
		_stage.add_child(lbl)
		var t := create_tween().set_parallel(true)
		t.tween_property(lbl, "position:y", CALLOUT_Y - 90.0, 0.7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		t.tween_property(lbl, "modulate:a", 0.0, 0.7).set_ease(Tween.EASE_IN)
		t.chain().tween_callback(lbl.queue_free)

func _shake(mag: float) -> void:
	var t := create_tween()
	for i in range(5):
		var off := Vector2(randf_range(-mag, mag), randf_range(-mag, mag))
		t.tween_property(_stage, "position", off, 0.03)
	t.tween_property(_stage, "position", Vector2.ZERO, 0.04)

func _nm() -> String:
	return str(_them_stats.get("name", "them"))

func _verb(move: String, actor: String) -> String:
	match move:
		"haymaker": return "swing" if actor == "you" else "swings"
		_: return "jab" if actor == "you" else "jabs"

# ---------------------------------------------------------------- skip / end
func _on_skip() -> void:
	if _done: return
	_skipping = true
	_set_hp_final()
	_show_outcome()

func _set_hp_final() -> void:
	_ui.you.hp_fill.size.x = _ui.you.hp_w * clampf(float(_fight.you_hp) / float(max(1, _fight.you_hp_max)), 0.0, 1.0)
	_ui.you.hp_lbl.text = "%d / %d" % [max(0, int(_fight.you_hp)), int(_fight.you_hp_max)]
	_ui.them.hp_fill.size.x = _ui.them.hp_w * clampf(float(_fight.them_hp) / float(max(1, _fight.them_hp_max)), 0.0, 1.0)
	_ui.them.hp_lbl.text = "%d / %d" % [max(0, int(_fight.them_hp)), int(_fight.them_hp_max)]

func _show_outcome() -> void:
	if _done: return
	_done = true
	# apply the read swing (±20% cap), recompute the winner, reflect it in the bars
	var adj := _read_adjust()
	var ay: int = adj[0]
	var at: int = adj[1]
	var won: bool = ay > 0 and (at <= 0 or ay >= at)
	if not _ui.you.is_empty():
		_ui.you.hp_fill.size.x = _ui.you.hp_w * clampf(float(ay) / float(max(1, _you_f.hp_max)), 0.0, 1.0)
		_ui.you.hp_lbl.text = "%d / %d" % [ay, int(_you_f.hp_max)]
	if not _ui.them.is_empty():
		_ui.them.hp_fill.size.x = _ui.them.hp_w * clampf(float(at) / float(max(1, _them_f.hp_max)), 0.0, 1.0)
		_ui.them.hp_lbl.text = "%d / %d" % [at, int(_them_f.hp_max)]
	if is_instance_valid(_skip_btn): _skip_btn.hide()
	if is_instance_valid(_commentary): _commentary.hide()
	var loser := "them" if won else "you"
	var lu: Dictionary = _ui[loser]
	if not lu.is_empty():
		create_tween().tween_property(lu.doll, "modulate", Color(0.4, 0.4, 0.45, 0.7), 0.4)
		create_tween().tween_property(lu.frame, "rotation", (0.05 if loser == "them" else -0.05), 0.4)
	_round_lbl.text = "KO" if _fight.ko else "FINAL"

	var scrim := ColorRect.new(); scrim.color = Color(0, 0, 0, 0.0)
	scrim.position = Vector2(0, 1150); scrim.size = Vector2(VW, 360)
	scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage.add_child(scrim)
	create_tween().tween_property(scrim, "color", Color(0, 0, 0, 0.55), 0.3)

	var banner := Pal.heading("YOU WON" if won else "DONE OVER", 88, Pal.HIVIS if won else Pal.DANGER_RED)
	banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.position = Vector2(0, 1200); banner.size.x = VW
	banner.custom_minimum_size = Vector2(VW, 0)
	banner.modulate.a = 0.0; banner.scale = Vector2(0.8, 0.8); banner.pivot_offset = Vector2(VW / 2.0, 44)
	_stage.add_child(banner)
	create_tween().tween_property(banner, "modulate:a", 1.0, 0.3)
	create_tween().set_trans(Tween.TRANS_BACK).tween_property(banner, "scale", Vector2.ONE, 0.35)
	_shake(11.0)
	Audio.cash() if won else Audio.error()

	var cont := Pal.btn("ON THE ROAD" if won else "SLEEP IT OFF", "hivis" if won else "secondary", 96)
	cont.custom_minimum_size = Vector2(560, 96)
	cont.position = Vector2(VW / 2.0 - 280, 1360)
	cont.pressed.connect(_finish_out.bind(won))
	_stage.add_child(cont)

func _finish_out(won: bool) -> void:
	Audio.ui()
	finished.emit(won)
	if _on_done.is_valid(): _on_done.call(won)
	queue_free()

func _wait(s: float) -> void:
	await get_tree().create_timer(s).timeout

# ---------------------------------------------------------------- backdrop art
class _Skyline extends Control:
	func _draw() -> void:
		_band(7, 60, 150, 120, 300, 10, Color("#0E1420"), 0.7)
		_band(31, 90, 200, 160, 360, 13, Color("#0A0F18"), 0.5)
	func _band(seed: int, wmin: float, wmax: float, hmin: float, hmax: float, gap: float, col: Color, lit: float) -> void:
		var rng := RandomNumberGenerator.new(); rng.seed = seed
		var base := 820.0
		var x := -40.0
		while x < 1080.0 + 60.0:
			var w := wmin + rng.randf() * (wmax - wmin)
			var h := hmin + rng.randf() * (hmax - hmin)
			draw_rect(Rect2(x, base - h, w, h), col)
			draw_rect(Rect2(x, base - h, w, 2), Color(Pal.SODIUM, 0.18))
			var win := wmin * 0.24
			var cols: int = max(1, int(w / (win + 8)))
			var rows: int = max(1, int(h / (win * 2.4)))
			for cy in range(rows):
				for cx in range(cols):
					if rng.randf() > lit: continue
					var warm := rng.randf() > 0.35
					var wc: Color = Color(Pal.SODIUM, 0.28 + rng.randf() * 0.3) if warm else Color(0.6, 0.74, 0.9, 0.18 + rng.randf() * 0.22)
					draw_rect(Rect2(x + 8 + cx * (win + 8), base - h + 12 + cy * win * 2.2, win * 0.5, win), wc)
			x += w + gap

class _Rain extends Control:
	var t := 0.0
	func _process(d: float) -> void: t += d; queue_redraw()
	func _draw() -> void:
		var rng := RandomNumberGenerator.new(); rng.seed = 5
		for i in range(120):
			var speed := 900.0 + rng.randf() * 700.0
			var x0 := rng.randf() * 1200.0 - 60.0
			var ln := 24.0 + rng.randf() * 24.0
			var y := fmod(rng.randf() * 1920.0 + t * speed, 2020.0) - 60.0
			var a := 0.08 + rng.randf() * 0.16
			draw_line(Vector2(x0, y), Vector2(x0 - 7, y + ln), Color(1, 1, 1, a), 1.5)

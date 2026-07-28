class_name AmbushCard
extends Control
## The ambush moment (guide Step 26): a rival steps to you. FIGHT resolves from
## stats + gear, RUN is a speed roll, PAY is a fixed toll. Losing costs carried
## dirty + a hospital timer — never gear, never bank, never story.

var _atk: Dictionary
var _rng := RandomNumberGenerator.new()
var _body: VBoxContainer
var _busy := false

func setup(atk: Dictionary) -> void:
	_atk = atk

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_rng.randomize()
	var dim := ColorRect.new(); dim.color = Color(0.02, 0.02, 0.03, 0.9)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)
	var wrap := CenterContainer.new(); wrap.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(wrap)
	var p := PanelContainer.new(); p.custom_minimum_size = Vector2(1000, 0)
	var sb := Pal.sb(Color(Pal.RAISED, 0.98), 18, Pal.DANGER_RED, 1, 0); sb.border_width_left = 6
	p.add_theme_stylebox_override("panel", sb)
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 40); m.add_theme_constant_override("margin_right", 40)
	m.add_theme_constant_override("margin_top", 36); m.add_theme_constant_override("margin_bottom", 36)
	_body = Pal.vbox(16); m.add_child(_body); p.add_child(m); wrap.add_child(p)
	_choices()
	p.modulate.a = 0.0
	create_tween().tween_property(p, "modulate:a", 1.0, 0.2)
	Audio.error()

func _choices() -> void:
	for ch in _body.get_children(): ch.queue_free()
	_body.add_child(Pal.label("AMBUSH", 20, Pal.DANGER_RED, 500))
	var top := Pal.hbox(18)
	top.add_child(_rival_portrait(128))
	var who := Pal.vbox(4); who.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	who.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	who.add_child(Pal.heading(String(_atk.name), 42, Pal.TEXT))
	who.add_child(Pal.label("LVL %d · %s" % [int(_atk.level), str(_atk.get("specialisation", "grafter")).to_upper()], 18, Pal.SODIUM, 500))
	who.add_child(Pal.label("YOU'RE CARRYING %s" % Pal.money(Game.dirty()), 18, Pal.DIRTY, 500))
	top.add_child(who)
	_body.add_child(top)
	_body.add_child(Pal.text(String(_atk.setup), 26, Pal.TEXT2, 400, true))

	var fight := Pal.btn("FIGHT", "danger", 96); fight.pressed.connect(_fight)
	_body.add_child(fight)
	var run := Pal.btn("RUN  ·  %d%%" % int(round(_flee() * 100)), "secondary", 88); run.pressed.connect(_run)
	_body.add_child(run)
	var toll := _pay_toll()
	var pay := Pal.btn("PAY THEM  ·  %s" % Pal.money(toll), "secondary", 88); pay.pressed.connect(func(): _pay(toll))
	_body.add_child(pay)

## A framed procedural portrait of the rival — their real character, not a stock
## face. Same seed everywhere, so you recognise them.
func _rival_portrait(px: int) -> Control:
	var frame := PanelContainer.new()
	frame.custom_minimum_size = Vector2(px, px)
	frame.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	frame.add_theme_stylebox_override("panel", Pal.sb(Color("#0C0E10"), 12, Pal.DANGER_RED, 2, 0))
	frame.clip_contents = true
	var dv := DollView.new()
	dv.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dv.view = "bust"
	dv.set_cfg(_atk.get("doll", Doll.DEF))
	frame.add_child(dv)
	return frame

func _flee() -> float:
	return Combat.flee_chance(int(Game.s.stats.speed), int(_atk.spd))

func _pay_toll() -> int:
	return max(60, int(Game.dirty() * 0.15))

func _me() -> Dictionary:
	return {"str": Game.eff_stat("strength"), "tgh": Game.eff_stat("toughness"),
		"spd": Game.eff_stat("speed"), "slk": Game.eff_stat("slickness"),
		"atk_bonus": Game.gear_edge() * 4.0, "def_bonus": Game.gear_edge() * 3.0,
		"name": str(Game.s.get("tag", Game.s.get("name", "YOU"))).to_upper(),
		"doll": Game.s.get("doll", Doll.DEF), "weapon": Game.fitted("weapon"),
		"bonus_hp": int(Game.s.get("next_fight_hp", 0))}

## FIGHT → hand off to the animated combat view; consequences apply when it ends.
func _fight() -> void:
	if _busy: return
	_busy = true
	var me := _me()
	for k in Specialisation.combat_bonus(): me[k] = float(me.get(k, 0)) + float(Specialisation.combat_bonus()[k])
	if int(Game.s.get("next_fight_hp", 0)) > 0:
		Game.s["next_fight_hp"] = 0; Game.persist()   # consume the drink buff
	var cv := CombatView.new()
	cv.setup(me, _atk, _rng.randi(), func(won): _fight_result(won))
	App.I.overlay.add_child(cv)
	hide()                                   # sit behind the fight

func _fight_result(won: bool) -> void:
	Game.add_heat(1.0)
	if won:
		var xp: int = 40 + int(_atk.level) * 4
		Game.gain_xp(xp)
		Specialisation.bump("violent")
		Game.persist(); Game.changed.emit()
		Game.toast.emit("Saw %s off · +%d XP · nothing lost" % [_atk.name, xp], Pal.CLEAN)
	else:
		var info := _apply_loss()
		Game.toast.emit("Done over · lost %s · hospital %dm" % [Pal.money(info.lost), info.mins], Pal.DANGER_RED)
	_close()

func _run() -> void:
	if _busy: return
	_busy = true
	if _rng.randf() < _flee():
		var drop := int(Game.dirty() * 0.05)
		Game.add_dirty(-drop); Specialisation.bump("stealth")
		Game.persist(); Game.changed.emit()
		_outcome(true, "Gone before they got a proper hand on you.", "Dropped %s on the way" % Pal.money(drop))
	else:
		var info := _apply_loss()
		_outcome(false, "You didn't get ten yards. They dragged you back.", "Lost %s · hospital %dm" % [Pal.money(info.lost), info.mins])

func _pay(toll: int) -> void:
	if _busy: return
	_busy = true
	Game.add_dirty(-min(Game.dirty(), toll)); Game.reset_streak()
	Game.persist(); Game.changed.emit()
	_outcome(true, "You paid it. Cheaper than the hospital.", "Paid %s · they walk" % Pal.money(toll))

## The cost of losing an ambush — carried dirty + a hospital stay, never gear/bank/
## story. Returns {lost, mins} for messaging.
func _apply_loss() -> Dictionary:
	var lost := int(Game.dirty() * float(Config.get_value("ambush.loss_pct_carried_dirty", 0.25)))
	Game.add_dirty(-lost)
	Game.reset_streak()
	Game.add_heat(1.0)
	var mins := _rng.randi_range(int(Config.get_value("timers_minutes.hospital_min", 10)), int(Config.get_value("timers_minutes.hospital_max", 30)))
	Game.hospitalise(mins * 60.0)
	Game.s["_last_loss"] = Game.now()
	Game.persist(); Game.changed.emit()
	Events.hospitalised.emit(mins)
	return {"lost": lost, "mins": mins}

## Simple result card for RUN / PAY (FIGHT gets its own ceremony in CombatView).
func _outcome(won: bool, line: String, sub: String) -> void:
	show()
	for ch in _body.get_children(): ch.queue_free()
	_body.add_child(Pal.label("GOT AWAY" if won else "DONE OVER", 20, Pal.CLEAN if won else Pal.DANGER_RED, 500))
	_body.add_child(Pal.heading(line, 40, Pal.TEXT))
	_body.add_child(Pal.label(sub, 22, Pal.SODIUM, 500))
	Audio.cash() if won else Audio.error()
	var done := Pal.btn("ON THE ROAD" if won else "SLEEP IT OFF", "hivis" if won else "secondary", 96)
	done.pressed.connect(_close)
	_body.add_child(done)

func _close() -> void:
	Audio.ui()
	queue_free()
	if not Game.in_hospital(): return
	App.I.show_screen("map")

class_name JobStages
extends Control
## The push-your-luck run (guide Step 17). Room by room: bank what you've got, or
## push deeper for more at higher risk. GET OUT always keeps your haul; PUSH rolls
## the stage risk — fail and you drop the bag (and maybe get nicked). The player
## makes their own tension and blames only themselves.

var _jid := ""
var _job: Dictionary = {}
var _stages: Array = []
var _base := 0
var _vig: Dictionary = {}
var _on_done: Callable
var _haul := 0
var _room := 1          # deciding whether to push INTO this room; room 0 already banked
var _body: VBoxContainer
var _rng := RandomNumberGenerator.new()

func setup(jid: String, base_take: int, vig: Dictionary, on_done: Callable) -> void:
	_jid = jid
	_job = Config.job(jid)
	_stages = Config.stages_for(jid)
	_base = max(1, base_take)
	_vig = vig
	_on_done = on_done
	_haul = int(_base * PushLuck.loot_mult(0))    # you're in — the first room's yours

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_rng.randomize()
	var dim := ColorRect.new(); dim.color = Color(0.02, 0.03, 0.04, 0.86)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)
	var wrap := CenterContainer.new()
	wrap.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(wrap)
	var p := Pal.panel(); p.custom_minimum_size = Vector2(1000, 0)
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 40); m.add_theme_constant_override("margin_right", 40)
	m.add_theme_constant_override("margin_top", 36); m.add_theme_constant_override("margin_bottom", 36)
	_body = Pal.vbox(18); m.add_child(_body); p.add_child(m); wrap.add_child(p)
	_render()

func _render() -> void:
	for c in _body.get_children(): c.queue_free()
	if _room >= _stages.size():
		_finish(true, ""); return
	var st: Dictionary = _stages[_room]
	var risk := PushLuck.risk(_room, int(Game.s.stats.get("slickness", 5)))
	var in_lo := int(_base * PushLuck.loot_mult(_room) * 0.7)
	var in_hi := int(_base * PushLuck.loot_mult(_room) * 1.15)

	_body.add_child(Pal.label("ROOM %d OF %d" % [_room + 1, _stages.size()], 20, Pal.SODIUM, 500))
	_body.add_child(Pal.heading(String(st.get("name", "The room")).to_upper(), 50, Pal.TEXT))
	_body.add_child(Pal.text(_variant(st.get("text", "")), 26, Pal.TEXT2, 400, true))

	var grid := GridContainer.new(); grid.columns = 3
	grid.add_theme_constant_override("h_separation", 12); grid.add_theme_constant_override("v_separation", 12)
	grid.add_child(_cell("BANKED SO FAR", Pal.money(_haul), Pal.CLEAN))
	grid.add_child(_cell("IN HERE", "%s–%s" % [Pal.money(in_lo), Pal.money(in_hi)], Pal.DIRTY))
	grid.add_child(_cell("RISK", "%d%%" % int(round(risk * 100)), Pal.DANGER_RED if risk >= 0.4 else Pal.SODIUM))
	_body.add_child(grid)

	var row := Pal.hbox(14)
	var out := Pal.btn("GET OUT · " + Pal.money(_haul), "secondary", 108)
	out.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	out.pressed.connect(func(): _get_out())
	var push := Pal.btn("PUSH", "hivis", 108)
	push.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	push.pressed.connect(func(): _push(risk))
	row.add_child(out); row.add_child(push)
	_body.add_child(row)

## A stage's text/fail_text may be a single string or an array of variants (§WO1-T2.5);
## pick one so a player who runs a job twenty times doesn't read the same paragraph.
func _variant(v) -> String:
	if v is Array:
		return String(v[_rng.randi() % v.size()]) if v.size() > 0 else ""
	return String(v)

func _cell(cap: String, val: String, col: Color) -> Control:
	var p := Pal.inset_panel()
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 16); m.add_theme_constant_override("margin_right", 16)
	m.add_theme_constant_override("margin_top", 12); m.add_theme_constant_override("margin_bottom", 12)
	var v := Pal.vbox(4)
	v.add_child(Pal.label(cap, 16, Pal.MUTED, 500))
	v.add_child(Pal.heading(val, 30, col))
	m.add_child(v); p.add_child(m); p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return p

func _get_out() -> void:
	Audio.cash()
	_finish(true, "")

func _push(risk: float) -> void:
	Audio.ui()
	if _rng.randf() < risk:
		# caught — drop the bag
		var st: Dictionary = _stages[_room]
		var ft = st.get("fail_text", "It goes wrong and you don't wait to find out how bad.")
		_finish(false, _variant(ft))
	else:
		var got := int(_base * PushLuck.loot_mult(_room) * _rng.randf_range(0.7, 1.15))
		_haul += got
		_room += 1
		Game.s["_max_stage"] = max(int(Game.s.get("_max_stage", 0)), _room + 1)   # objective: stage_reached
		Audio.cash()
		_render()

func _finish(success: bool, fail_text: String) -> void:
	var rooms_cleared := _room  # rooms banked before this decision
	var res := {"ok": true, "success": success, "job_name": _job.get("name", "Job"),
		"stages": rooms_cleared, "leveled": [], "items": []}
	# spend nerve for the deeper you went (energy was spent to start the job)
	Game.add_heat(float(_job.get("heat", 1)) + rooms_cleared * 0.4)

	if success:
		var take := _haul
		Game.add_dirty(take)
		var xp: int = int(_job.get("xp", 10)) * max(1, rooms_cleared)
		res["leveled"] = Game.gain_xp(xp)
		Game.bump_streak()
		var crit := rooms_cleared >= _stages.size()
		res["dirty"] = take; res["xp"] = xp
		res["tier"] = "crit" if crit else ("good" if rooms_cleared >= 3 else "base")
		res["crit"] = crit
		res["streak"] = Game.streak(); res["streak_mult"] = Game.streak_mult()
		res["new_best"] = Game.note_haul(take, crit)
		res["flavor"] = Vignettes.flavor(_vig, res)
		Game.daily_progress("jobs", 1); Game.daily_progress("dirty", take)
		if crit: Game.daily_progress("crit", 1)
		var tname: String = str(_vig.get("target", {}).get("name", ""))
		if tname != "" and tname != "null":
			Game.ledger_add("%s · %s" % [tname, _job.get("name", "Job")], String(res.flavor))
		Vignettes.mark_seen(str(_vig.get("id", "")))
	else:
		Game.reset_streak()
		res["dirty"] = 0; res["xp"] = 0; res["tier"] = "fail"; res["success"] = false
		res["flavor"] = fail_text
		# the deeper you pushed, the better the chance of getting nicked
		var arrest_chance := 0.15 + rooms_cleared * 0.12
		if _rng.randf() < arrest_chance:
			var lost := int(Game.dirty() * 0.25)
			Game.add_dirty(-lost)
			res["arrested"] = true; res["dirty_lost"] = lost

	Game.persist(); Game.changed.emit()
	var cb := _on_done
	queue_free()
	if cb.is_valid(): cb.call(res)

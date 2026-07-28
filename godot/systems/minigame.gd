class_name Minigame
extends Control
## Base class for every active-input beat (WO2). A minigame MODIFIES the outcome,
## it never decides it: the score it emits (0..1) feeds the resolver as a ±15%
## nudge on top of stats+gear, plus a crit-window multiplier. See resolver.gd and
## MinigameHost. Subclasses implement setup()/run()/skip() and emit finished()
## exactly once. Everything is one-thumb, portrait, Control-space — no physics,
## no bodies, no follow-cameras (Brief #1 architecture is untouched).

signal finished(score: float, detail: Dictionary)
## Live gameplay pings (WO2-T11) the host forwards to the scene's actor layer so the
## backdrop shows the event happening: "grab", "hit", "miss", "serve", "bust", "gold".
signal event(name: String)

## Context the host hands in. Keys (all optional, sensible fallbacks):
##   job_id, job_name, tier, approach ("loud"/"quiet"/""), tools[], crew[],
##   stat_value (primary stat for this job), skill, difficulty (0..1),
##   stage_index (push-your-luck), vignette (one line of copy shown during play).
var ctx: Dictionary = {}
var _done := false

## Called once when the overlay opens, before run().
func setup(_ctx: Dictionary) -> void:
	ctx = _ctx

## Must emit finished() exactly once, score clamped 0..1.
##   0.0 fumbled · 0.4 what SKIP awards · 0.7 solid · 1.0 perfect
## detail is free-form and surfaces in the reveal ("CLEAN LIFT", "COUPLE OF SCUFFS").
func run() -> void:
	pass

## Every minigame ships a working skip → the stat-only result at score 0.4.
func skip() -> void:
	_finish(0.4, {"skipped": true, "detail": "PLAYED IT SAFE"})

# ---- helpers for subclasses -------------------------------------------------

## Single-shot guard so a double-tap or the 14s host cap can't double-emit.
func _finish(score: float, detail: Dictionary) -> void:
	if _done:
		return
	_done = true
	Telemetry.log_event("minigame_end", {"job": ctx.get("job_id", ""), "score": snappedf(score, 0.01), "skipped": detail.get("skipped", false)})
	finished.emit(clampf(score, 0.0, 1.0), detail)

func is_done() -> bool:
	return _done

## Ping the actor layer (the scene reacts). Cheap; safe to call every beat.
func _event(name: String) -> void:
	event.emit(name)

## Primary stat value for this job (0 fallback), used to widen tolerances so a
## well-built player has an easier minigame — stats still dominate.
func stat() -> float:
	return float(ctx.get("stat_value", 5))

func difficulty() -> float:
	return clampf(float(ctx.get("difficulty", 0.4)), 0.0, 1.0)

func stage_index() -> int:
	return int(ctx.get("stage_index", 0))

func approach() -> String:
	return String(ctx.get("approach", ""))

func has_tool(name: String) -> bool:
	for t in ctx.get("tools", []):
		if String(t).to_lower().find(name.to_lower()) >= 0:
			return true
	return false

func has_crew(role: String) -> bool:
	for c in ctx.get("crew", []):
		var r := ""
		if c is Dictionary: r = String(c.get("role", c.get("name", "")))
		else: r = String(c)
		if r.to_lower().find(role.to_lower()) >= 0:
			return true
	return false

## The play area rect the host reserves for us (below the scene, above the copy).
## Defaults to our own rect if the host hasn't sized us yet.
func play_rect() -> Rect2:
	return Rect2(Vector2.ZERO, size)

# ============================================================================
# WO3 — universal fairness layer. Every minigame gets these identically; no
# subclass rolls its own timing floor or skips the ready beat.
# ============================================================================

var _plays := 0          # this minigame's lifetime plays BEFORE the current one

## Stable id per minigame, derived from the script filename (e.g. "timing_bar").
func mg_id() -> String:
	var s: Script = get_script()
	if s != null:
		return String(s.resource_path).get_file().get_basename()
	return "minigame"

func _load_plays() -> int:
	return int((Game.s.get("mg_plays", {}) as Dictionary).get(mg_id(), 0))

func _bump_plays() -> void:
	var d: Dictionary = Game.s.get("mg_plays", {})
	d[mg_id()] = int(d.get(mg_id(), 0)) + 1
	Game.s["mg_plays"] = d
	Game.persist()

## TASK 1 — the 3-phase opening. Nothing the subclass animates should move until
## this returns (keep your own _running flag false / set_process(true) after). SHOW
## the static board + instruction, then SET (READY→GO + haptic), then hand back.
## After the 5th play the SHOW shrinks and the instruction drops to a corner label.
func _ready_beat(instruction: String) -> void:
	_plays = _load_plays()
	_bump_plays()
	var veteran := _plays >= 5

	var lbl := Label.new()
	lbl.add_theme_font_override("font", Pal.display_font())
	lbl.add_theme_color_override("font_color", Pal.GLOW)
	lbl.add_theme_font_size_override("font_size", 30 if veteran else 46)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if veteran:
		# small corner label — veterans aren't lectured
		lbl.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
		lbl.add_theme_color_override("font_color", Pal.MUTED)
		lbl.add_theme_font_override("font", Pal.mono_font(500))
		lbl.add_theme_font_size_override("font_size", 20)
		lbl.offset_top = 8
	else:
		lbl.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		lbl.offset_left = -420; lbl.offset_right = 420; lbl.offset_top = -40
	add_child(lbl)

	# PHASE 1 — SHOW
	lbl.text = instruction
	await get_tree().create_timer(0.5 if veteran else 1.2).timeout
	if _done: lbl.queue_free(); return
	# PHASE 2 — SET
	if not veteran:
		lbl.text = "READY"
		Audio.ui()
		await get_tree().create_timer(0.45).timeout
		if _done: lbl.queue_free(); return
		lbl.text = "GO"
		lbl.add_theme_color_override("font_color", Pal.HIVIS)
		Audio.whoosh()
		if OS.has_feature("mobile"): Input.vibrate_handheld(30)
		await get_tree().create_timer(0.35).timeout
	lbl.queue_free()
	# PHASE 3 — the subclass now starts moving.

## TASK 5 — the one timing formula. Returns a reaction window in ms: stats widen,
## difficulty + stage narrow (bounded), and a HARD FLOOR nothing goes below.
func window_ms(base_ms: float, min_ms := 250.0) -> float:
	var w := base_ms
	w *= 1.0 + stat() * 0.012        # stats widen
	w *= 1.0 - difficulty() * 0.25   # difficulty narrows, bounded
	w *= 1.0 - stage_index() * 0.06  # stages narrow, bounded
	return maxf(min_ms, w)

## First 3 plays are 1.4× easier — an explicit training ramp on top of window_ms().
func training_mult() -> float:
	return 1.4 if _load_plays() < 3 else 1.0

## TASK 3 — end a run showing the diagnosable reason (fiction voice) for 1.5s, then
## finish. `detail.reason` also rides through to the caller. Success skips the hold.
func _end_with(score: float, detail: Dictionary) -> void:
	if _done:
		return
	var reason := String(detail.get("reason", ""))
	if reason != "" and score < 0.7:
		var r := Label.new()
		r.text = reason
		r.add_theme_font_override("font", Pal.body_font(500))
		r.add_theme_font_size_override("font_size", 30)
		r.add_theme_color_override("font_color", Pal.DANGER_RED)
		r.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		r.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		r.mouse_filter = Control.MOUSE_FILTER_IGNORE
		r.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		r.offset_left = -440; r.offset_right = 440; r.offset_top = -30
		add_child(r)
		await get_tree().create_timer(1.5).timeout
	_finish(score, detail)

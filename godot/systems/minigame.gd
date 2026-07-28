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

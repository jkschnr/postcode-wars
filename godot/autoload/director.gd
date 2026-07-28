extends Node
## Director (guide Step 9) — exactly one active objective at all times. Listens to
## the Events bus, evaluates the active objective's target, and on completion
## applies its rewards (venue unlocks, story beats, xp) and advances the chain.
## It is NEVER empty: when the chain is exhausted it generates a fallback goal so
## "I don't know what to do" is technically impossible.

signal changed(objective: Dictionary)

var active: String = ""
var completed: Array = []
var _fallback_obj: Dictionary = {}
var _busy := false        # re-entrancy guard: _apply emits Events that call back in

func _ready() -> void:
	# state lives in the save so it persists
	var d: Dictionary = Game.s.get("director", {})
	active = String(d.get("active", ""))
	completed = d.get("completed", [])
	for sig in ["job_completed", "money_changed", "level_up", "venue_unlocked",
			"beat_triggered", "timer_completed", "stat_trained", "item_acquired",
			"travelled", "target_cased"]:
		Events.connect(sig, _on_state_changed)

## Called once the prologue is done, or on any boot, to make sure something is active.
func ensure_active() -> void:
	if active == "" and not _all_done():
		active = _next_uncompleted()
	if active == "" and _all_done():
		active = "__fallback__"
		_fallback_obj = _make_fallback()
	_save()
	evaluate()
	changed.emit(current())

func current() -> Dictionary:
	if active == "__fallback__":
		return _fallback_obj
	return Config.objective(active)

func _on_state_changed(_a = null, _b = null, _c = null, _d = null) -> void:
	evaluate()

func evaluate() -> void:
	# _apply() grants xp/money which emit Events that call back into evaluate();
	# the guard makes those re-entrant calls no-ops so we never recurse on a
	# still-active objective (which would re-grant forever).
	if _busy: return
	_busy = true
	_run_eval()
	_busy = false

func _run_eval() -> void:
	if active == "" or active == "__fallback__":
		if active == "__fallback__" and _is_complete(_fallback_obj.get("target", {})):
			_apply(_fallback_obj.get("on_complete", {}))
			_fallback_obj = _make_fallback()
			changed.emit(current())
		return
	var obj := Config.objective(active)
	if obj.is_empty(): return
	if not _is_complete(obj.get("target", {})): return
	if not (active in completed): completed.append(active)
	var nxt := String(obj.get("on_complete", {}).get("next", ""))
	var finished_id := String(obj.get("id", ""))
	# advance FIRST, then apply — so any Event fired during _apply sees the new
	# active objective, not the one we just completed
	active = nxt if nxt != "" else "__fallback__"
	if active == "__fallback__":
		_fallback_obj = _make_fallback()
	_apply(obj.get("on_complete", {}))
	_save()
	Events.objective_completed.emit(finished_id)
	changed.emit(current())
	_run_eval()  # a chain can complete instantly (already-met next target)

func _apply(on_complete: Dictionary) -> void:
	for v in on_complete.get("unlock_venues", []):
		Game.unlock_venue(String(v))
	var beat := String(on_complete.get("trigger_beat", ""))
	if beat != "":
		if not Game.s.has("pending_beats"): Game.s["pending_beats"] = []
		if not (beat in Game.s.pending_beats): Game.s.pending_beats.append(beat)
		Events.beat_triggered.emit(beat)
	var grant: Dictionary = on_complete.get("grant", {})
	if int(grant.get("xp", 0)) > 0:
		Game.gain_xp(int(grant.xp))
	if int(grant.get("dirty", 0)) != 0: Game.add_dirty(int(grant.dirty))
	if int(grant.get("clean", 0)) != 0: Game.add_clean(int(grant.clean))
	Game.persist()

func _is_complete(target: Dictionary) -> bool:
	match String(target.get("type", "")):
		"dirty_earned_total":
			return int(Game.s.get("records", {}).get("total_dirty", 0)) >= int(target.get("amount", 0))
		"clean_balance":
			return Game.clean() >= int(target.get("amount", 0))
		"jobs_completed":
			return int(Game.s.get("records", {}).get("total_jobs", 0)) >= int(target.get("count", 0))
		"level_reached":
			return Game.level() >= int(target.get("level", 0))
		"stat_trained":
			return int(Game.s.get("_stats_trained", 0)) >= int(target.get("count", 1))
		"crew_size":
			return Game.s.get("crew", []).size() >= int(target.get("count", 0))
		"travel_any":
			return int(Game.s.get("_travels", 0)) >= int(target.get("count", 1))
		"beat_completed":
			return Story.completed(String(target.get("beat", "")))
		"venue_visited":
			return String(target.get("venue", "")) in Game.s.get("_visited", [])
		"items_sold":
			return int(Game.s.get("_items_sold", 0)) >= int(target.get("count", 1))
		"arena_wins":
			return int(Game.s.get("_arena_wins", 0)) >= int(target.get("count", 1))
		"stage_reached":
			return int(Game.s.get("_max_stage", 0)) >= int(target.get("stage", 1))
		"target_cased":
			return int(Game.s.get("_cased_total", 0)) >= int(target.get("count", 1))
		"items_equipped":
			return Game.s.get("fit", {}).size() >= int(target.get("count", 1))
		"calls_made":
			return int(Game.s.get("_calls_made", 0)) >= int(target.get("count", 1))
	return false

## Progress as a fraction for the banner bar (0..1), or -1 if not measurable.
func progress() -> float:
	var t: Dictionary = current().get("target", {})
	match String(t.get("type", "")):
		"dirty_earned_total":
			return clampf(float(Game.s.get("records", {}).get("total_dirty", 0)) / max(1.0, float(t.get("amount", 1))), 0, 1)
		"clean_balance":
			return clampf(float(Game.clean()) / max(1.0, float(t.get("amount", 1))), 0, 1)
		"jobs_completed":
			return clampf(float(Game.s.get("records", {}).get("total_jobs", 0)) / max(1.0, float(t.get("count", 1))), 0, 1)
		"level_reached":
			return clampf(float(Game.level()) / max(1.0, float(t.get("level", 1))), 0, 1)
	return -1.0

func _next_uncompleted() -> String:
	var id := Config.objectives_start
	while id != "" and (id in completed):
		id = String(Config.objective(id).get("on_complete", {}).get("next", ""))
	return id

func _all_done() -> bool:
	if Config.objectives_start == "": return true
	return _next_uncompleted() == ""

## Never-empty banner past the end of the chain (§WO1-T3.2). Rotates daily across
## five goal shapes so the endgame always has a fresh, real thing to do.
func _make_fallback() -> Dictionary:
	var lvl := Game.level()
	var bank := ((int(Game.clean() / 5000) + 1) * 5000)
	var candidates := [
		{"id": "fb_level", "text": "Reach level %d" % (lvl + 2),
			"subtext": "More levels, more doors. Put the work in.",
			"target": {"type": "level_reached", "level": lvl + 2}, "goto": {"screen": "jobs"},
			"on_complete": {"grant": {"xp": 200}}},
		{"id": "fb_bank", "text": "Bank £%s" % _kfmt(bank),
			"subtext": "Keep the pile growing. Clean money's the only kind that lasts.",
			"target": {"type": "clean_balance", "amount": bank}, "goto": {"screen": "bank"},
			"on_complete": {"grant": {"xp": 200}}},
		{"id": "fb_push", "text": "Push a job to the fourth room",
			"subtext": "The money's always in the room you nearly didn't go into.",
			"target": {"type": "stage_reached", "stage": 4}, "goto": {"screen": "jobs"},
			"on_complete": {"grant": {"xp": 220}}},
		{"id": "fb_arena", "text": "Win three on the street",
			"subtext": "Respect's a currency too. Go and earn some.",
			"target": {"type": "arena_wins", "count": int(Game.s.get("_arena_wins", 0)) + 3}, "goto": {"screen": "arena"},
			"on_complete": {"grant": {"xp": 240}}},
		{"id": "fb_case", "text": "Case two targets",
			"subtext": "Ten minutes watching saves you ten years inside. Case it first.",
			"target": {"type": "target_cased", "count": int(Game.s.get("_cased_total", 0)) + 2}, "goto": {"screen": "jobs"},
			"on_complete": {"grant": {"xp": 180}}},
	]
	return candidates[Seeds.daily_seed() % candidates.size()]

func _kfmt(n: int) -> String:
	return "%d,000" % (n / 1000) if n >= 1000 else str(n)

func _save() -> void:
	Game.s["director"] = {"active": active, "completed": completed}
	Game.persist()

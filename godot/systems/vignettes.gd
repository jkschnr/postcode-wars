class_name Vignettes
extends RefCounted
## Vignette selector (brief §11 / §14.3). Filters a job's vignettes by conditions,
## then strongly prefers ones the player hasn't seen (so the hundredth pickpocket
## isn't the first). All flavour is data; this just chooses and remembers.

static func pick(job_id: String) -> Dictionary:
	var pool: Array = Config.vignettes.get(job_id, [])
	if pool.is_empty():
		return {}
	var valid: Array = []
	for v in pool:
		if _ok(v):
			valid.append(v)
	if valid.is_empty():
		valid = pool
	var seen: Dictionary = Game.s.get("seen_vignettes", {})
	var unseen: Array = []
	for v in valid:
		if not seen.has(v.get("id", "")):
			unseen.append(v)
	if not unseen.is_empty():
		return unseen[Game.rng.randi() % unseen.size()]
	# everything's been seen — resurface the least-recently-shown
	valid.sort_custom(func(a, b): return float(seen.get(a.get("id",""), 0)) < float(seen.get(b.get("id",""), 0)))
	return valid[0]

static func mark_seen(id: String) -> void:
	if id == "":
		return
	if not Game.s.has("seen_vignettes") or typeof(Game.s.seen_vignettes) != TYPE_DICTIONARY:
		Game.s.seen_vignettes = {}
	Game.s.seen_vignettes[id] = Game.now()

## The outcome line matching how the job actually went.
static func flavor(v: Dictionary, outcome: Dictionary) -> String:
	if v.is_empty():
		return ""
	if not outcome.get("success", false):
		return str(v.get("on_fail", ""))
	if outcome.get("crit", false) and v.has("on_crit"):
		return str(v.get("on_crit", ""))
	return str(v.get("on_success", ""))

static func target_line(v: Dictionary) -> String:
	var t: Dictionary = v.get("target", {})
	if t.is_empty():
		return ""
	var nm = t.get("name", null)
	var detail: String = str(t.get("detail", ""))
	if nm != null and str(nm) != "":
		return "%s — %s" % [str(nm), detail] if detail != "" else str(nm)
	return detail

static func _ok(v: Dictionary) -> bool:
	var c: Dictionary = v.get("conditions", {})
	if c.has("max_heat") and Game.heat() > float(c.max_heat): return false
	if c.has("min_heat") and Game.heat() < float(c.min_heat): return false
	if c.has("cities") and not (Game.s.city in c.cities): return false
	if c.has("time"):
		var h: int = Time.get_datetime_dict_from_system().hour
		var night: bool = h < 6 or h >= 20
		if str(c.time) == "night" and not night: return false
		if str(c.time) == "day" and night: return false
	return true

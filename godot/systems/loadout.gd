class_name Loadout
extends RefCounted
## The pre-job loadout (guide Step 16). The confirm screen becomes three real
## decisions — APPROACH, TOOLS, WHO YOU BRING — instead of one always-correct tap.
## A loadout is a plain dict {approach, tools:[ids], crew} carried by the confirm
## card; mods() folds it into the numbers the resolver already understands. No
## combination is universally best.

const APPROACHES := ["quiet", "loud", "night"]
const CREWS := ["alone", "rico", "enforcer", "driver"]

static func default() -> Dictionary:
	return {"approach": "quiet", "tools": [], "crew": "alone"}

static func approach_meta(id: String) -> Dictionary:
	return Config.get_value("approach." + id, {})

static func crew_meta(id: String) -> Dictionary:
	return Config.get_value("crew." + id, {})

static func tool_meta(id: String) -> Dictionary:
	var t: Dictionary = Config.tuning.get("tools", {})
	return t.get(id, {})

## Tools you actually own (equipped gear whose id is a defined tool). Only these
## are offered — you can't carry what you haven't got.
static func owned_tools() -> Array:
	var t: Dictionary = Config.tuning.get("tools", {})
	var out: Array = []
	for g in Game.s.get("equipped", []):
		var id := str(g.get("id", ""))
		if t.has(id) and not out.has(id): out.append(id)
	for it in Game.s.get("inventory", []):
		var id := str(it.get("id", ""))
		if t.has(id) and not out.has(id): out.append(id)
	return out

## Combine a loadout into resolver-ready modifiers.
##   payout_mult  — multiply the take
##   success_add  — added to success chance (folds into ctx.crew_bonus)
##   heat_mult    — multiply outcome heat
##   cut          — fraction of the take the crew keeps
##   escape       — reduces arrest chance on a failed job
##   panic        — chance the job just ends (crew bottles it)
##   time_cost_h  — game-hours the approach costs
##   extra_stages — push-your-luck stages the crew unlocks
##   flags        — informational tags (search_risk etc.)
static func mods(ld: Dictionary) -> Dictionary:
	var m := {"payout_mult": 1.0, "success_add": 0.0, "heat_mult": 1.0,
		"cut": 0.0, "escape": 0.0, "panic": 0.0, "time_cost_h": 0.0,
		"extra_stages": 0, "search_risk": 0.0}
	var a := approach_meta(str(ld.get("approach", "quiet")))
	m.payout_mult *= float(a.get("payout", 1.0))
	m.success_add += float(a.get("success", 0.0))
	m.heat_mult *= float(a.get("heat", 1.0))
	m.time_cost_h += float(a.get("time_cost_h", 0.0))
	for tid in ld.get("tools", []):
		var t := tool_meta(str(tid))
		m.success_add += float(t.get("success", 0.0))
		m.heat_mult *= float(t.get("heat_mult", 1.0))
		m.escape += float(t.get("escape", 0.0))
		m.search_risk += float(t.get("search_risk", 0.0))
	var c := crew_meta(str(ld.get("crew", "alone")))
	m.success_add += float(c.get("success", 0.0))
	m.escape += float(c.get("escape", 0.0))
	m.panic += float(c.get("panic", 0.0))
	m.cut += float(c.get("cut", 0.0))
	m.extra_stages += int(c.get("stages", 0))
	return m

## Human-readable one-line summary of the current loadout, for the confirm card.
static func summary(ld: Dictionary) -> String:
	var parts: Array = []
	parts.append(str(approach_meta(str(ld.get("approach", "quiet"))).get("label", "QUIET")))
	for tid in ld.get("tools", []):
		parts.append(str(tool_meta(str(tid)).get("label", tid)))
	var crew := str(ld.get("crew", "alone"))
	if crew != "alone":
		parts.append(str(crew_meta(crew).get("label", crew)))
	return "  ·  ".join(parts)

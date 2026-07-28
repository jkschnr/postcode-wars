class_name Specialisation
extends RefCounted
## Specialisation (guide Step 24) — no class picker. The game watches what you do
## (violent / stealth / management) and, at level 20, Uncle T names it. Three
## titles, each with a passive and a job-weighting lean. Switchable: play against
## type for a while and it re-titles you, so nothing is ever locked away.

const SPECS := {
	"bully": {
		"label": "BULLY", "kind": "violent", "accent": "#C2503F",
		"passive": "+15% street & snatch payouts · heavier hands in a scrap",
		"line": "You solve things the loud way. It works more than it should, and it costs more than you think.",
	},
	"creeper": {
		"label": "CREEPER", "kind": "stealth", "accent": "#B06CF0",
		"passive": "−25% heat gain · harder to catch, harder to describe",
		"line": "You don't hit people. That's not soft — that's you working out that hitting people is expensive.",
	},
	"face": {
		"label": "FACE", "kind": "management", "accent": "#C9A227",
		"passive": "+20% firm & trapline yield · doors open, prices soften",
		"line": "You've stopped doing it all yourself. Other people do it now, and they do it for you.",
	},
}

static func current() -> String:
	return str(Game.s.get("specialisation", "")) if Game.s.get("specialisation", null) != null else ""

static func meta(id := "") -> Dictionary:
	var k := id if id != "" else current()
	return SPECS.get(k, {})

static func _counters() -> Dictionary:
	if not Game.s.has("spec_counters") or typeof(Game.s.spec_counters) != TYPE_DICTIONARY:
		Game.s["spec_counters"] = {"violent": 0, "stealth": 0, "management": 0}
	return Game.s.spec_counters

## Record a tracked action. kind: "violent" | "stealth" | "management".
static func bump(kind: String, n := 1) -> void:
	var c := _counters()
	c[kind] = int(c.get(kind, 0)) + n

## The path you're leaning toward, by counters.
static func leader() -> String:
	var c := _counters()
	var best := "bully"; var bestv := -1
	for k in [["violent", "bully"], ["stealth", "creeper"], ["management", "face"]]:
		if int(c.get(k[0], 0)) > bestv: bestv = int(c.get(k[0], 0)); best = k[1]
	return best

static func set_spec(id: String) -> void:
	if not SPECS.has(id): return
	Game.s["specialisation"] = id
	Game.persist(); Game.changed.emit()
	if Telemetry: Telemetry.log_event("specialisation_set", {"id": id})

## Ready to be named? Level 20+, nothing chosen yet.
static func ready_to_name() -> bool:
	return Game.level() >= 20 and current() == ""

# ---------- passives ----------
static func heat_mult() -> float:
	return 0.75 if current() == "creeper" else 1.0

static func street_payout_mult() -> float:
	return 1.15 if current() == "bully" else 1.0

static func mgmt_mult() -> float:
	return 1.20 if current() == "face" else 1.0

## Combat edge from the path — folded into the player's fighter dict.
static func combat_bonus() -> Dictionary:
	match current():
		"bully": return {"atk_bonus": 6.0}          # heavier hands
		"creeper": return {"slk": 3}                 # slippery
		_: return {}

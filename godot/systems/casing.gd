class_name Casing
extends RefCounted
## Casing (guide Step 29) — scope a target for free, then it sits waiting for you
## for 48 hours: +30% success, the loot revealed, an orange marker in the job list.
## Anticipation is the cheapest fun there is, and a prepared target waiting for you
## is a genuinely good feeling. State lives in Game.s.casing {jid: {until, flavor}}.

const RESULTS := [
	"Nobody in on Tuesdays after seven. There's a dog but it's a spaniel and it's already met you.",
	"Camera over the door isn't wired to anything. The one over the garage is. That's the wrong way round and it's their problem.",
	"Woman upstairs is in every day except Thursday when she does a shift somewhere. That's your window and it's four hours wide.",
	"Back gate's been on the same padlock since Christmas. You could open it with a look.",
	"They cash up at half nine and the young one takes the bag to the night safe alone. Every night. Same route.",
]
const WINDOW := 48.0 * 3600.0
const SUCCESS := 0.30

static func _map() -> Dictionary:
	if not Game.s.has("casing") or typeof(Game.s.casing) != TYPE_DICTIONARY:
		Game.s["casing"] = {}
	return Game.s.casing

static func is_cased(jid: String) -> bool:
	var c := _map()
	return c.has(jid) and Game.now() < float(c[jid].get("until", 0))

static func flavor(jid: String) -> String:
	return str(_map().get(jid, {}).get("flavor", ""))

static func hours_left(jid: String) -> int:
	if not is_cased(jid): return 0
	return int(ceil((float(_map()[jid].until) - Game.now()) / 3600.0))

## Case a target. Deterministic flavour per job+day so it reads consistent.
static func case_target(jid: String) -> String:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("pw_case_%s_%d" % [jid, Game.day()])
	var f: String = RESULTS[rng.randi() % RESULTS.size()]
	_map()[jid] = {"until": Game.now() + WINDOW, "flavor": f}
	Game.persist(); Game.changed.emit()
	if Telemetry: Telemetry.log_event("cased", {"job": jid})
	return f

## Extra success from a live case (folded into the resolver).
static func bonus(jid: String) -> float:
	return SUCCESS if is_cased(jid) else 0.0

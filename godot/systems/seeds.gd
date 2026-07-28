class_name Seeds
extends RefCounted
## Deterministic seeding (guide Step 2). Story spine is fixed for everyone; the
## flesh (job lists, prices, loot, ambushers) is randomised per player but STABLE
## within a session — backing out of a screen must never re-roll. Never call
## randf() at render time; anything visible derives from one of these seeds.

## Generated once at character creation, never changes. Kept in Game.s.seed.
static func player_seed() -> int:
	var sd: int = int(Game.s.get("seed", 0))
	if sd == 0:
		sd = abs(hash("%s-%d" % [Game.s.get("name", "ash"), int(Game.s.get("created_at", 1))]))
		Game.s["seed"] = sd
	return sd

## Same for the whole UK day — rerolls at local midnight.
static func daily_seed() -> int:
	var day := Time.get_datetime_dict_from_system(false)
	return abs(hash("%d-%04d%02d%02d" % [player_seed(), int(day.year), int(day.month), int(day.day)]))

## A stable seed for the Nth encounter this player has ever hit.
static func encounter_seed(counter: int) -> int:
	return abs(hash("%d-enc-%d" % [player_seed(), counter]))

## A namespaced stable seed, e.g. tag "jobs" so the job list is stable per day.
static func tagged_seed(tag: String) -> int:
	return abs(hash("%d-%s" % [daily_seed(), tag]))

static func rng_for(seed_value: int) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = seed_value
	return r

class_name Season
extends RefCounted
## Seasons (guide Step 37) — an 8-week cycle ending in a soft reset. The fresh-start
## effect is the strongest reactivation tool there is, and it keeps the board
## claimable forever. Local clock now; the same shape runs off a server rollover
## later. Kept in Game.s.season {id, joined_at, legacy_respect}.

static func length_days() -> int:
	return int(Config.season_data.get("length_days", 56))

static func themes() -> Array:
	return Config.season_data.get("themes", [])

static func _ensure() -> void:
	if not Game.s.has("season") or typeof(Game.s.season) != TYPE_DICTIONARY:
		Game.s["season"] = {"id": 1, "joined_at": 0.0, "legacy_respect": 0}
	if float(Game.s.season.get("joined_at", 0)) <= 0:
		Game.s.season["joined_at"] = Game.now()

static func info() -> Dictionary:
	_ensure()
	var id := int(Game.s.season.get("id", 1))
	var th: Array = themes()
	var theme: Dictionary = th[(id - 1) % th.size()] if th.size() > 0 else {"name": "SEASON", "twist": "", "accent": "#FFA94D"}
	var elapsed := Game.now() - float(Game.s.season.joined_at)
	var left: int = max(0, length_days() - int(elapsed / 86400.0))
	return {"id": id, "theme": theme, "days_left": left, "elapsed_days": int(elapsed / 86400.0)}

## Roll to the next season if the clock has run out. Returns the rollover result
## (or {} for no change). Soft reset: half your respect banks to a legacy total,
## the streets reset, a fresh theme + a season-end reward.
static func check_rollover() -> Dictionary:
	_ensure()
	var elapsed := Game.now() - float(Game.s.season.joined_at)
	if elapsed < length_days() * 86400.0: return {}
	var old_id := int(Game.s.season.id)
	var respect := int(Game.s.get("respect", 0))
	var legacy := int(Game.s.season.get("legacy_respect", 0)) + respect
	# season-end reward scales with the respect you built
	var reward := 500 + respect * 3
	Game.add_clean(reward)
	# soft reset: half your respect carries, the streets are fresh, the board reopens
	Game.s["respect"] = int(respect * 0.5)
	Game.s["street"] = {}
	Game.s.season = {"id": old_id + 1, "joined_at": Game.now(), "legacy_respect": legacy}
	Game.persist(); Game.changed.emit()
	if Telemetry: Telemetry.log_event("season_rollover", {"from": old_id, "reward": reward})
	var nxt := info()
	return {"new_id": old_id + 1, "reward": reward, "theme": nxt.theme, "legacy": legacy}

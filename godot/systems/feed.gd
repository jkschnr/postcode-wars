class_name Feed
extends RefCounted
## The Flexta feed (guide Step 36) — visible aspiration. Auto-posts other players'
## wins (rank-ups, big pushes, arena wins, running a block) and your own. Purely
## the shadow pool + your history, so it's free content that reads as a living
## scene. Reactions grant a trickle of respect, capped so they can't be farmed.

const POSTS := [
	"ran the block on %P tonight. Nobody left standing.",
	"pushed to stage 5 and walked out with %M.",
	"came up to %R. Say it with respect.",
	"did %N over outside the chicken shop. He'll feel that.",
	"is top of %P this week. For now.",
	"caught a %I on a crit. Some people have all the luck.",
	"cleared the strip and took the boss's chain.",
]

static func own() -> Array:
	return Game.s.get("feed", [])

## Post one of the player's own events into the feed (kept, capped).
static func post(line: String) -> void:
	if not Game.s.has("feed") or typeof(Game.s.feed) != TYPE_ARRAY: Game.s["feed"] = []
	Game.s.feed.push_front({"who": str(Game.s.get("tag", "YOU")).to_upper(), "line": line,
		"doll": Game.s.get("doll", Doll.DEF), "mine": true, "day": Game.day(),
		"react": {"fire": 0, "hundred": 0, "rat": 0}})
	if Game.s.feed.size() > 20: Game.s.feed.resize(20)
	Game.persist()

## The rendered feed: your posts on top, then a stable daily churn of shadow wins.
static func items() -> Array:
	var out: Array = []
	for p in own(): out.append(p)
	var pool := Shadow.pool()
	if pool.is_empty(): return out
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("pw_feed_%d" % Game.day())
	var pcodes := ["E5", "N17", "SE15", "B21", "OT", "SW9", "E3", "N4"]
	var names := Shadow.NAMES
	for i in range(9):
		var s: Dictionary = pool[rng.randi() % pool.size()]
		var t: String = POSTS[rng.randi() % POSTS.size()]
		t = t.replace("%P", pcodes[rng.randi() % pcodes.size()])
		t = t.replace("%M", Pal.money(rng.randi_range(1200, 6400)))
		t = t.replace("%R", Config.rank_for_level(int(s.level)).get("name", "Grafter"))
		t = t.replace("%N", names[rng.randi() % names.size()])
		t = t.replace("%I", ["flagship phone", "gold watch", "certi jacket"][rng.randi() % 3])
		out.append({"who": str(s.display_name), "line": t, "doll": s.doll, "mine": false,
			"react": {"fire": rng.randi_range(2, 40), "hundred": rng.randi_range(0, 22), "rat": rng.randi_range(0, 9)}})
	return out

## Everyone ranked by power — the player folded into the shadow pool.
static func leaderboard() -> Array:
	var rows: Array = []
	var me := Shadow.own_snapshot()
	me["mine"] = true; me["power"] = Shadow.power(me)
	rows.append(me)
	for s in Shadow.pool():
		var r: Dictionary = s.duplicate()
		r["mine"] = false
		rows.append(r)
	rows.sort_custom(func(a, b): return int(a.get("power", 0)) > int(b.get("power", 0)))
	return rows

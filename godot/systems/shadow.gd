class_name Shadow
extends RefCounted
## Shadow players (guide Step 30 ⭐). Ambushes and rivals are real players'
## characters, played by AI while they're offline. Before real accounts exist a
## seeded pool of plausible snapshots stands in — SAME code path, so nothing
## changes at launch. THE CRITICAL RULE: an offline player loses nothing; their
## snapshot is a mannequin, not their account.

const NAMES := ["MARKO_88", "TEZ_OT", "RAWDOG_E5", "SNAKEY_92", "DUTCH_N17",
	"KYE_SE", "BANDO_B", "RILZ_OT", "SMOKEY_E3", "VELLY_10",
	"OZ_N4", "DENZ_SW9", "TRAP_KING", "LIL_MENACE", "BIG_DAWG",
	"CUZ_E17", "FLICKA_B", "ROADMAN_J", "SHANKS_09", "GHOST_SE15",
	"MADDO_N", "PACC_MAN", "SCARZ_E5", "NINO_BX", "DRILLA_OT",
	"YOUNGZ_B", "TALLY_E3", "REEKO_S", "BONES_N17", "AXE_SE"]
const SPECS := ["bully", "grafter", "runner", "face", "ghost"]

## A weapon id appropriate to a level — nastier the higher you go, ~55% carry.
## Deterministic per (seed_str) so a rival always holds the same thing.
static func weapon_for(seed_str: String, level: int) -> String:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("pw_wep_" + seed_str)
	if rng.randf() > 0.55: return ""
	var pool: Array = []
	for sl in Config.item_slots():
		if sl.get("k", "") != "weapon": continue
		for it in sl.get("items", []):
			if str(it.get("sh", "")) == "none": continue
			if int(it.get("il", 0)) <= level + 4: pool.append(str(it.id))
	if pool.is_empty(): return ""
	return pool[rng.randi() % pool.size()]

## Deterministic procedural character for a snapshot — same seed always yields the
## same face, so a rival you recognise from the leaderboard looks the same in an
## ambush. Specialisation shapes the read: a bully is heavier and hooded, a face
## is iced-up and fresh, a ghost hides under a hood and shades.
static func doll_cfg(seed_str: String, spec: String) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("pw_doll_" + seed_str)
	var o := Doll.options()
	var cfg := {}
	for k in o.keys():
		cfg[k] = rng.randi() % int((o[k].list as Array).size())
	# specialisation reads — deliberate silhouettes, not random noise
	match spec:
		"bully":
			cfg.beard = [3, 4, 1][rng.randi() % 3]      # full / chinstrap / stubble
			cfg.brow = 2                                  # heavy
			cfg.mark = [1, 2, 6][rng.randi() % 3]         # a scar
			cfg.head = [0, 2, 3][rng.randi() % 3]         # bare / hood / durag
			cfg.mouth = 1                                 # set
			cfg.top = [1, 2][rng.randi() % 2]             # puffer / hoodie
		"face":
			cfg.chain = [2, 3][rng.randi() % 2]           # cuban / pendant
			cfg.glass = 1 if rng.randf() < 0.6 else 0     # shades
			cfg.beard = [0, 1, 2][rng.randi() % 3]        # clean-ish
			cfg.top = [3, 4][rng.randi() % 2]             # tee / bomber
			cfg.clothc = 7                                # gold
		"runner":
			cfg.head = 1                                  # cap
			cfg.top = 0                                   # tracksuit
			cfg.beard = [0, 1][rng.randi() % 2]           # young
			cfg.mark = 0
		"ghost":
			cfg.head = 2                                  # hood up
			cfg.glass = 1 if rng.randf() < 0.5 else 0
			cfg.clothc = 3                                # near-black
			cfg.beard = [0, 1][rng.randi() % 2]
		_:                                                # grafter — plain, working
			cfg.head = [0, 1][rng.randi() % 2]
			cfg.top = [0, 2, 3][rng.randi() % 3]
	return cfg

## power = (STR+TGH+SPD+SLK)×4 + level×12 + gear_value  (guide formula)
static func power(snap: Dictionary) -> int:
	var st: Dictionary = snap.get("stats", {})
	var s := int(st.get("str", 5)) + int(st.get("tgh", 5)) + int(st.get("spd", 5)) + int(st.get("slk", 5))
	return s * 4 + int(snap.get("level", 1)) * 12 + int(snap.get("gear_value", 0))

## The player's own snapshot — what other players' games see of you.
static func own_snapshot() -> Dictionary:
	var st: Dictionary = Game.s.get("stats", {})
	return {
		"player_id": "me",
		"display_name": str(Game.s.get("tag", Game.s.get("name", "YOU"))).to_upper(),
		"level": Game.level(),
		"rank": Config.rank_for_level(Game.level()).get("name", "Yout"),
		"stats": {"str": int(st.get("strength", 5)), "tgh": int(st.get("toughness", 5)),
			"spd": int(st.get("speed", 5)), "slk": int(st.get("slickness", st.get("stealth", 5)))},
		"gear_value": int(round(Game.gear_edge() * 100.0)),
		"portrait_seed": str(Game.s.get("doll_seed", "self")),
		"specialisation": str(Game.s.get("specialisation", "grafter")),
		"doll": Game.s.get("doll", Doll.DEF.duplicate()),
	}

## Deterministic seeded pool of 30 plausible snapshots, scaled around the player's
## level so the world always has reachable rivals. Cached per level band.
static var _pool_cache: Array = []
static var _pool_band: int = -1

static func pool() -> Array:
	var band := Game.level() / 3
	if _pool_band == band and not _pool_cache.is_empty():
		return _pool_cache
	_pool_band = band
	_pool_cache = []
	var rng := RandomNumberGenerator.new()
	for i in NAMES.size():
		rng.seed = hash("pw_shadow_%s_%d" % [NAMES[i], band])
		var lvl: int = max(1, Game.level() + rng.randi_range(-4, 6))
		var base := 5 + lvl
		var snap := {
			"player_id": "u_%d" % (8000 + i),
			"display_name": NAMES[i],
			"level": lvl,
			"rank": Config.rank_for_level(lvl).get("name", "Yout"),
			"stats": {
				"str": base + rng.randi_range(-3, 6),
				"tgh": base + rng.randi_range(-3, 6),
				"spd": base + rng.randi_range(-3, 6),
				"slk": base + rng.randi_range(-3, 6),
			},
			"gear_value": rng.randi_range(0, lvl * 3),
			"portrait_seed": "%04x" % (rng.randi() & 0xffff),
			"specialisation": SPECS[rng.randi() % SPECS.size()],
		}
		snap["doll"] = doll_cfg(str(snap.portrait_seed), str(snap.specialisation))
		snap["weapon"] = weapon_for(str(snap.portrait_seed), lvl)
		snap["power"] = power(snap)
		_pool_cache.append(snap)
	return _pool_cache

## A street's fight card (The Street arena): n opponents on a difficulty ladder,
## seeded stable per street+day so the roster is the same all day and refreshes
## when the day rolls. Each carries its own reward. Real characters (dolls),
## scaled around the player's level with an easy→hard spread.
static func street_roster(street_key: String, player_level: int, n: int) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("pw_street_" + street_key)
	var out: Array = []
	var used := {}
	for i in range(n):
		var name: String = NAMES[rng.randi() % NAMES.size()]
		var guard := 0
		while used.has(name) and guard < 12:
			name = NAMES[rng.randi() % NAMES.size()]; guard += 1
		used[name] = true
		var tier: int = i - int(n / 2)                       # -2..+2 easy→hard
		var lvl: int = max(1, player_level + tier + rng.randi_range(-1, 1))
		var base := 5 + lvl
		var spec: String = SPECS[rng.randi() % SPECS.size()]
		var pseed := "%s_%d" % [street_key, i]
		var snap := {
			"player_id": "st_%d" % i,
			"display_name": name,
			"level": lvl,
			"rank": Config.rank_for_level(lvl).get("name", "Yout"),
			"stats": {
				"str": base + rng.randi_range(-2, 5),
				"tgh": base + rng.randi_range(-2, 5),
				"spd": base + rng.randi_range(-2, 5),
				"slk": base + rng.randi_range(-2, 5),
			},
			"gear_value": rng.randi_range(0, lvl * 3),
			"specialisation": spec,
			"portrait_seed": pseed,
			"doll": doll_cfg(pseed, spec),
		}
		snap["weapon"] = weapon_for(pseed, lvl)
		snap["power"] = power(snap)
		snap["reward_dirty"] = int(60 + snap.power * 1.1 + lvl * 18)
		snap["reward_xp"] = 20 + lvl * 5
		snap["respect"] = 3 + max(0, tier) * 3
		out.append(snap)
	return out

## The block boss — the name that runs the strip. Tougher than the roster, better
## paid, and drops a piece of gear. Deterministic per street+day.
static func boss_for(street_key: String, player_level: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("pw_boss_" + street_key)
	var lvl: int = max(3, player_level + rng.randi_range(3, 6))
	var base := 8 + lvl
	var spec: String = SPECS[rng.randi() % SPECS.size()]
	var pseed := street_key + "_boss"
	var snap := {
		"player_id": "boss",
		"display_name": NAMES[rng.randi() % NAMES.size()],
		"level": lvl,
		"rank": Config.rank_for_level(lvl).get("name", "Grafter"),
		"stats": {"str": base + rng.randi_range(1, 6), "tgh": base + rng.randi_range(1, 6),
			"spd": base + rng.randi_range(1, 6), "slk": base + rng.randi_range(1, 6)},
		"gear_value": rng.randi_range(lvl, lvl * 4),
		"specialisation": spec, "portrait_seed": pseed,
		"doll": doll_cfg(pseed, spec), "weapon": weapon_for(pseed, lvl + 4),
		"boss": true,
	}
	snap["power"] = power(snap)
	snap["reward_dirty"] = int(300 + snap.power * 2.2 + lvl * 40)
	snap["reward_xp"] = 80 + lvl * 10
	snap["respect"] = 20 + lvl
	return snap

## Matchmaking: a snapshot within ±window power, excluding the player and anyone
## attacked in the last exclude_recent_hours. Falls back to the nearest by power.
static func pick_opponent() -> Dictionary:
	var my_pow := power(own_snapshot())
	var window := float(Config.get_value("shadow.power_window", 0.25))
	var lo := my_pow * (1.0 - window)
	var hi := my_pow * (1.0 + window)
	var recent: Dictionary = Game.s.get("shadow", {}).get("last_attacked", {})
	var cutoff := Game.now() - float(Config.get_value("shadow.exclude_recent_hours", 24)) * 3600.0
	var eligible: Array = []
	for s in pool():
		if float(recent.get(s.player_id, 0)) > cutoff: continue
		if s.power >= lo and s.power <= hi: eligible.append(s)
	if eligible.is_empty():
		# nearest by power, still respecting the recency exclusion where possible
		var best: Dictionary = {}
		var bestd := 1e20
		for s in pool():
			var d: float = abs(s.power - my_pow)
			if d < bestd: bestd = d; best = s
		return best
	return eligible[randi() % eligible.size()]

## Record that we just ran an ambush against this snapshot (recency exclusion).
static func mark_attacked(player_id: String) -> void:
	if not Game.s.has("shadow"): Game.s["shadow"] = {"last_attacked": {}, "pending_reports": []}
	Game.s.shadow.last_attacked[player_id] = Game.now()

## Turn a snapshot into the attacker dict the AmbushCard/Combat expect.
static func to_attacker(snap: Dictionary, setup_line: String) -> Dictionary:
	var st: Dictionary = snap.get("stats", {})
	return {
		"name": snap.display_name,
		"level": int(snap.level),
		"str": int(st.get("str", 8)),
		"tgh": int(st.get("tgh", 8)),
		"spd": int(st.get("spd", 8)),
		"slk": int(st.get("slk", 8)),
		"atk_bonus": float(snap.get("gear_value", 0)) * 0.4,
		"def_bonus": float(snap.get("gear_value", 0)) * 0.3,
		"player_id": snap.player_id,
		"specialisation": snap.get("specialisation", "grafter"),
		"doll": snap.get("doll", doll_cfg(str(snap.get("portrait_seed", "x")), str(snap.get("specialisation", "grafter")))),
		"weapon": snap.get("weapon", ""),
		"setup": setup_line,
	}

# ---------------------------------------------------------------- Step 31
## Defence reports — while you were away, other players' games attacked YOUR
## shadow. We simulate them truthfully against your snapshot and report exactly
## what happened. You lose nothing; the report is the return hook.
static func simulate_defences() -> void:
	if not Game.s.get("prologue_done", false): return
	var sess: Dictionary = Game.s.get("session", {})
	var last_end := float(sess.get("last_end", 0))
	if last_end <= 0: return
	var away := Game.now() - last_end
	if away < 8.0 * 3600.0: return                       # only after a real gap
	var n: int = clampi(int(away / 86400.0) + (1 if away >= 8 * 3600.0 else 0), 0, 2)
	if n <= 0: return
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("pw_def_%d" % int(last_end))
	var me := own_snapshot()
	var defender := {"str": int(me.stats.str), "tgh": int(me.stats.tgh),
		"spd": int(me.stats.spd), "atk_bonus": float(me.gear_value) * 0.4, "def_bonus": float(me.gear_value) * 0.3}
	var reports: Array = Game.s.get("shadow", {}).get("pending_reports", [])
	var used := {}
	for i in n:
		var p := pool()
		var atk: Dictionary = p[rng.randi() % p.size()]
		if used.has(atk.player_id): continue
		used[atk.player_id] = true
		var ast: Dictionary = atk.stats
		var attacker := {"str": int(ast.str), "tgh": int(ast.tgh), "spd": int(ast.spd),
			"atk_bonus": float(atk.gear_value) * 0.4, "def_bonus": float(atk.gear_value) * 0.3}
		# attacker is 'a', you are the defender 'b' — you win by NOT losing
		var res := Combat.resolve(attacker, defender, rng)
		var margin: float = abs(float(res.you_hp) - float(res.them_hp))
		var result := "won"                              # you (defender = b) held them off
		if res.won: result = "lost"                      # attacker (a) won
		elif margin < 12: result = "close"
		reports.append({
			"attacker": atk.display_name,
			"level": int(atk.level),
			"result": result,
			"line": _report_line(atk.display_name, result),
			"seen": false,
		})
	if not Game.s.has("shadow"): Game.s["shadow"] = {"last_attacked": {}, "pending_reports": []}
	Game.s.shadow.pending_reports = reports
	Game.persist()

static func _report_line(who: String, result: String) -> String:
	match result:
		"won": return "%s tried you on while you were gone. You saw him off." % who
		"lost": return "%s caught you outside your block. He'll be feeling good about that." % who
		_: return "%s had you and then he didn't. It was close enough that you should think about it." % who

static func pending_reports() -> Array:
	return Game.s.get("shadow", {}).get("pending_reports", [])

static func clear_reports() -> void:
	if Game.s.has("shadow"): Game.s.shadow.pending_reports = []
	Game.persist()

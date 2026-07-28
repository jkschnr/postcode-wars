class_name Combat
extends RefCounted
## Turn-based street combat (guide Step 27), built to be *watched*. resolve() runs
## a full fight from a seed and returns a replayable TIMELINE of beats — who moved,
## what they threw, whether it landed, dodged, was blocked or crit, and both
## fighters' HP/stamina after. The animated CombatView plays that timeline back;
## headless callers (defence sims) just read `.won`. Deterministic: same fighters +
## seed → same fight, every time. Every constant lives in tuning.combat.

static func _t(path: String, fb: Variant) -> Variant:
	return Config.get_value("combat." + path, fb)

## Build a fighter's live stat-block from a stat dict {str,tgh,spd, atk_bonus, def_bonus}.
static func make_fighter(s: Dictionary, who: String) -> Dictionary:
	var hp := float(_t("hp_base", 100)) + float(s.get("tgh", 5)) * float(_t("hp_per_toughness", 5)) + float(s.get("bonus_hp", 0))
	return {
		"who": who,
		"name": str(s.get("name", who)),
		"doll": s.get("doll", {}),
		"hp": hp, "hp_max": hp,
		"atk": float(s.get("str", 5)) * float(_t("atk_per_strength", 2)) + float(s.get("atk_bonus", 0)),
		"def": float(s.get("tgh", 5)) * float(_t("def_per_toughness", 2)) + float(s.get("def_bonus", 0)),
		"spd": float(s.get("spd", 5)),
		"slk": float(s.get("slk", 5)),
		"stam": float(_t("stamina_max", 100)), "stam_max": float(_t("stamina_max", 100)),
		"crit": float(_t("crit_base", 0.05)) + float(s.get("spd", 5)) * float(_t("crit_per_speed", 0.002)) + float(s.get("slk", 5)) * float(_t("crit_per_slk", 0.004)),
		"evasion": clampf(float(_t("dodge_base", 0.04)) + float(s.get("slk", 5)) * float(_t("dodge_per_slk", 0.02)), 0.0, float(_t("dodge_cap", 0.48))),
		"guarding": false,
	}

## Deterministic AI move pick. Presses for the finish when the target is low, guards
## to get wind back when gassed, otherwise mixes jabs and the occasional haymaker.
static func _choose(f: Dictionary, foe: Dictionary, rng: RandomNumberGenerator) -> String:
	var moves: Dictionary = _t("moves", {})
	var heavy_cost := float(moves.get("haymaker", {}).get("stamina", 30))
	var jab_cost := float(moves.get("jab", {}).get("stamina", 10))
	var low := float(_t("low_hp_frac", 0.34))
	# gassed — can't even jab: cover up and breathe
	if f.stam < jab_cost:
		return "guard"
	# target is on the ropes: go for it if there's gas for the big one
	if foe.hp <= foe.hp_max * low and f.stam >= heavy_cost:
		return "haymaker" if rng.randf() < 0.8 else "jab"
	# running low on wind and not in danger: bank some stamina
	if f.stam < heavy_cost and f.hp > f.hp_max * 0.5 and rng.randf() < 0.45:
		return "guard"
	# default mix — haymaker when there's gas, weighted toward jabs
	if f.stam >= heavy_cost and rng.randf() < 0.34:
		return "haymaker"
	return "jab"

## One actor's turn against the other. Mutates both fighters, returns the beat.
## `forced` overrides the AI move pick (used for speed-flurry bonus jabs).
static func _turn(actor: Dictionary, target: Dictionary, rnd: int, rng: RandomNumberGenerator, forced := "") -> Dictionary:
	var moves: Dictionary = _t("moves", {})
	var move := forced if forced != "" else _choose(actor, target, rng)
	var mv: Dictionary = moves.get(move, moves.get("jab", {}))
	actor.guarding = false

	if move == "guard":
		actor.guarding = true
		actor.stam = min(actor.stam_max, actor.stam + float(_t("stamina_regen_guard", 26)))
		return _beat(rnd, actor, "guard", "guard", 0, actor, target)

	actor.stam = max(0.0, actor.stam - float(mv.get("stamina", 10)))
	actor.stam = min(actor.stam_max, actor.stam + float(_t("stamina_regen_idle", 6)))

	# whiff — heavy swings miss more often on their own
	if rng.randf() > float(mv.get("accuracy", 0.94)):
		return _beat(rnd, actor, move, "whiff", 0, actor, target)

	# the target tries to slip it — SLICKNESS is the evasion stat, out-speeding a
	# slower attacker helps a little, and heavy swings are easier to read
	var dodge: float = float(_t("dodge_base", 0.04)) + target.slk * float(_t("dodge_per_slk", 0.02))
	dodge += max(0.0, target.spd - actor.spd) * float(_t("dodge_per_speed_diff", 0.006))
	if move == "haymaker": dodge += float(_t("dodge_vs_heavy", 0.10))
	dodge = clampf(dodge, 0.0, float(_t("dodge_cap", 0.48)))
	if rng.randf() < dodge:
		return _beat(rnd, actor, move, "dodge", 0, actor, target)

	# damage
	var soft := float(_t("def_softening", 150))
	var vlo := float(_t("variance", [0.85, 1.15])[0])
	var vhi := float(_t("variance", [0.85, 1.15])[1])
	var raw: float = actor.atk * float(mv.get("dmg", 1.0)) * (1.0 - target.def / (target.def + soft)) * rng.randf_range(vlo, vhi)
	var crit: bool = rng.randf() < actor.crit * float(mv.get("crit_mult", 1.0))
	if crit: raw *= float(_t("crit_mult", 1.7))
	var result := "crit" if crit else "hit"
	if target.guarding:
		raw *= (1.0 - float(_t("block_reduction", 0.55)))
		result = "block"
	var dmg: int = max(1, int(round(raw)))
	target.hp = max(0.0, target.hp - dmg)
	return _beat(rnd, actor, move, result, dmg, actor, target)

static func _beat(rnd: int, actor: Dictionary, move: String, result: String, dmg: int, a: Dictionary, b: Dictionary) -> Dictionary:
	# snapshot both fighters by their fixed side so the view can address bars by who
	var you: Dictionary = a if a.who == "you" else b
	var them: Dictionary = a if a.who == "them" else b
	return {
		"round": rnd, "actor": actor.who, "move": move, "result": result, "dmg": dmg,
		"you_hp": int(round(you.hp)), "them_hp": int(round(them.hp)),
		"you_stam": int(round(you.stam)), "them_stam": int(round(them.stam)),
		"you_hp_max": int(you.hp_max), "them_hp_max": int(them.hp_max),
	}

## Full fight. a = you, b = them (stat dicts). Returns the timeline + summary.
static func fight(a: Dictionary, b: Dictionary, seed: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var you := make_fighter(a, "you")
	var them := make_fighter(b, "them")
	var timeline: Array = []
	var max_rounds := int(_t("max_rounds", 10))
	var ko := false
	var rounds := 0
	var flurry_ratio := float(_t("flurry_spd_ratio", 1.35))
	var flurry_chance := float(_t("flurry_chance", 0.5))
	var jab_cost := float(_t("moves", {}).get("jab", {}).get("stamina", 10))
	for r in range(1, max_rounds + 1):
		rounds = r
		# initiative: faster acts first; tie → you
		var order := [you, them] if you.spd >= them.spd else [them, you]
		for actor in order:
			var target: Dictionary = them if actor.who == "you" else you
			timeline.append(_turn(actor, target, r, rng))
			if target.hp <= 0.0:
				ko = true
				break
			# tempo: a much faster fighter snaps out a bonus jab
			if actor.spd >= target.spd * flurry_ratio and actor.stam >= jab_cost and rng.randf() < flurry_chance:
				timeline.append(_turn(actor, target, r, rng, "jab"))
				if target.hp <= 0.0:
					ko = true
					break
		if ko: break
	var won: bool = you.hp > 0.0 and (them.hp <= 0.0 or you.hp >= them.hp)
	return {
		"won": won, "ko": ko, "rounds": rounds, "timeline": timeline,
		"you_hp": int(round(you.hp)), "them_hp": int(round(them.hp)),
		"you_hp_max": int(you.hp_max), "them_hp_max": int(them.hp_max),
	}

## Back-compat shim for callers that only need the outcome (defence sims). Maps the
## new fight() onto the old {won, log, you_hp, them_hp} shape.
static func resolve(a: Dictionary, b: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	var res := fight(a, b, rng.randi())
	return {"won": res.won, "log": res.timeline, "you_hp": res.you_hp, "them_hp": res.them_hp}

# ---- WO2-T12.2: the optional per-round READ -----------------------------------
## Combat stays stat-decided (the maths above is untouched). On top, each round the
## player may read the opponent and pick STRIKE / GUARD / RUSH against a tell. It's
## rock-paper-scissors: STRIKE beats RUSH, GUARD beats STRIKE, RUSH beats GUARD.
## A correct read boosts your damage or cuts what you take; a wrong read is a small
## penalty. The View clamps the total to ±20% of a fight, so a stronger opponent
## still usually wins — the reads reward attention, they don't replace the build.
const READS := ["STRIKE", "GUARD", "RUSH"]
const _BEATS := {"STRIKE": "RUSH", "GUARD": "STRIKE", "RUSH": "GUARD"}

## Map an AI move to the read it reads as: haymaker=STRIKE, jab=RUSH, guard=GUARD.
static func move_as_read(move: String) -> String:
	match move:
		"haymaker": return "STRIKE"
		"guard": return "GUARD"
		_: return "RUSH"

## A one-line tell for the opponent's coming move, readable in under a second.
static func tell_for(move: String) -> String:
	match move:
		"haymaker": return "he winds up"
		"guard": return "he sets his feet"
		_: return "he steps in"

## Your read vs their move → {dmg_mult, taken_mult, correct}. correct read: STRIKE/
## RUSH multiply your damage ×1.3; GUARD cuts damage taken 40%. Wrong read: ×0.85.
static func read_outcome(choice: String, opp_move: String) -> Dictionary:
	var opp := move_as_read(opp_move)
	if _BEATS.get(choice, "") == opp:
		if choice == "GUARD":
			return {"dmg_mult": 1.0, "taken_mult": 0.6, "correct": true}
		return {"dmg_mult": 1.3, "taken_mult": 1.0, "correct": true}
	if choice == opp:
		return {"dmg_mult": 1.0, "taken_mult": 1.0, "correct": false}   # neutral
	return {"dmg_mult": 0.85, "taken_mult": 1.0, "correct": false}       # out-read

## Flee chance vs a rival, guide formula, clamped.
static func flee_chance(my_spd: int, their_spd: int, shoved := false) -> float:
	var base := float(_t("flee_base", 40)) + (my_spd - their_spd) * float(_t("flee_per_speed_diff", 2))
	if shoved: base += float(_t("flee_shove_bonus", 40))
	return clampf(base / 100.0, float(_t("flee_floor", 0.10)), float(_t("flee_cap", 0.85)))

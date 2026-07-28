class_name Resolver
extends RefCounted
## Job outcome resolution — no minigames. Success is computed from stats + skill
## + gear + crew − city danger, shown to the player, then rolled with a seed and
## turned into an outcome tier. The UI only ANIMATES the result (brief §7).

const TIERS := ["fail", "near_fail", "base", "good", "crit", "jackpot"]

## Probability of success, 0.05–0.95. Always shown before committing.
static func success_chance(job: Dictionary, ctx: Dictionary) -> float:
	var base: float = job.get("base_chance", 0.6)
	var stat_name: String = job.get("stat", "slickness")
	# EFFECTIVE stat — trained base + everything the fit adds (gear contributes
	# ONLY through stats now; the flat-bonus system is gone). §WO1-T6.
	var stat: int = ctx.get("stats", {}).get(stat_name, 5)
	var skill: int = ctx.get("skill", 0)          # this crime's skill level
	var crew: float = ctx.get("crew_bonus", 0.0)  # crew + approach + tools + casing − heat
	var danger: int = ctx.get("danger", 3)
	var lvl: int = ctx.get("level", 1)
	var req: int = job.get("level_req", 1)
	# minigame_score (WO2-T1): the ONE thing active play changes. 0.4 == skip/neutral
	# (preview uses this), so stats+gear still dominate. Perfect (1.0) = +10%, a
	# fumble (0.0) = −5% — that whole ±15% range and nothing more. §WO2-0.3.
	var minigame_score: float = ctx.get("minigame_score", 0.4)
	var chance: float = base \
		+ stat * 0.008 \
		+ skill * 0.015 \
		+ crew \
		+ max(0, lvl - req) * 0.004 \
		- (danger - 1) * 0.06 \
		+ (minigame_score * 0.15) - 0.05
	# The 0.95 clamp is what protects the risk economy — applied AFTER every
	# contribution (gear + minigame included), never before. §WO1-T6.5 / §WO2-0.3.
	return clampf(chance, 0.05, 0.95)

## Resolve to a full outcome. `seed` makes it replayable (Backend §8.3).
static func resolve(job: Dictionary, ctx: Dictionary, seed: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var chance := success_chance(job, ctx)
	var roll := rng.randf()
	var success := roll < chance
	var payout_mult: float = ctx.get("payout_mult", 1.0)
	var lo: float = job.get("payout", [40, 120])[0]
	var hi: float = job.get("payout", [40, 120])[1]

	var tier := "base"
	var dirty := 0
	var xp := 0
	var heat := 0.0
	var items: Array = []
	var crit := false
	var near_miss := false

	if not success:
		# how close was it? within 0.12 of the line = near-miss (real, not faked)
		near_miss = roll < chance + 0.12
		tier = "near_fail" if near_miss else "fail"
		dirty = 0
		xp = int(job.get("xp", 10) * 0.25)         # consolation graft XP
		heat = float(job.get("heat", 1)) * (0.5 if near_miss else 1.0)
		return _pack(tier, false, dirty, xp, heat, items, crit, near_miss, job)

	# success band from a second roll. The minigame opens a CRIT WINDOW: a perfect
	# result (1.0) multiplies crit/jackpot odds ×2.5 — that's where the felt reward
	# lives. Skip/neutral (0.4) → ×1.6, a fumble (0.0) → ×1.0 (base). §WO2-0.3.
	var mg: float = ctx.get("minigame_score", 0.4)
	var crit_mult: float = 1.0 + mg * 1.5
	var jackpot_thr: float = 1.0 - 0.02 * crit_mult
	var crit_thr: float = 1.0 - 0.10 * crit_mult
	var band := rng.randf()
	var t := rng.randf()
	if band > jackpot_thr:
		tier = "jackpot"; crit = true; t = 0.9 + t * 0.1
		items.append(_roll_item(job, "certi", rng))
	elif band > crit_thr:
		tier = "crit"; crit = true; t = 0.8 + t * 0.2
		if job.has("crit_item"):
			items.append(_roll_item(job, job.get("crit_rarity", "peng"), rng))
	elif band > 0.70:
		tier = "good"; t = 0.6 + t * 0.4
	else:
		tier = "base"

	dirty = int(round(lerp(lo, hi, t) * payout_mult))
	xp = int(job.get("xp", 10) * (1.0 + (0.5 if crit else 0.0)))
	heat = float(job.get("heat", 1))
	return _pack(tier, true, dirty, xp, heat, items, crit, near_miss, job)

static func _roll_item(job: Dictionary, rarity: String, rng: RandomNumberGenerator) -> Dictionary:
	var name: String = job.get("crit_item", "Flagship Phone")
	var band: Array = job.get("crit_value", [200, 500])
	return {"name": name, "rarity": rarity, "value": int(round(lerp(float(band[0]), float(band[1]), rng.randf())))}

static func _pack(tier, success, dirty, xp, heat, items, crit, near_miss, job) -> Dictionary:
	return {
		"tier": tier, "success": success, "dirty": dirty, "xp": xp,
		"heat": heat, "items": items, "crit": crit, "near_miss": near_miss,
		"skill": job.get("skill", ""), "job_name": job.get("name", "Job"),
	}

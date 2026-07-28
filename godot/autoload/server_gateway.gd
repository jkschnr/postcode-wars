extends Node
## ServerGateway — the ONE seam between game and logic. Every consequential action
## goes through an async method here. M1 = LocalGateway (runs client-side). M3 =
## NakamaGateway (same signatures, server-authoritative). UI never bypasses this.

# All methods `await` a frame so call sites already use `await` — swapping in the
# networked gateway later changes nothing at the call site.

func _yield() -> void:
	await get_tree().process_frame

# ------------------------------------------------------------------ jobs
## Non-mutating preview for the confirm panel (chance is always shown, brief §7).
func preview_job(job_id: String, approach := -1, loadout := {}) -> Dictionary:
	var job := Config.job(job_id)
	if job.is_empty():
		return {}
	var jm := _apply_approach(job, approach)
	var ctx := _ctx(jm)
	var appr := _approach(job, approach)
	ctx.payout_mult *= float(appr.get("payout_mult", 1.0))
	# universal loadout (Step 16): approach/tools/crew fold into the same numbers
	var lm := Loadout.mods(loadout)
	ctx.crew_bonus += lm.success_add + Casing.bonus(job_id) - Heat.risk_add()   # cased +30%, heat −risk
	ctx.payout_mult *= lm.payout_mult * (1.0 - lm.cut) * Heat.payout_mult()      # heat fattens the take
	return {
		"name": job.get("name", "Job"),
		"chance": Resolver.success_chance(jm, ctx),
		"energy": int(job.get("energy", 6)),
		"nerve": int(job.get("nerve", 2)),
		"payout": job.get("payout", [40, 120]),
		"payout_mult": ctx.payout_mult,
		"xp": int(job.get("xp", 10)),
		"heat": max(0.0, (float(job.get("heat", 1)) + float(appr.get("heat", 0))) * lm.heat_mult),
		"level_req": int(job.get("level_req", 1)),
		"search_risk": lm.search_risk,
	}

## Resolve + apply. Returns the outcome the UI animates, plus levels crossed.
## minigame_score (WO2): 0.4 == neutral/skip; the caller passes the played score so
## the resolver can nudge chance ±15% and open the crit window. Default keeps every
## non-minigame caller (contracts, scripted beats) at the stat-only baseline.
func resolve_job(job_id: String, approach := -1, force_success := false, loadout := {}, minigame_score := 0.4) -> Dictionary:
	await _yield()
	var job := Config.job(job_id)
	if job.is_empty():
		return {"ok": false, "reason": "Unknown job"}
	if Game.in_jail():
		return {"ok": false, "reason": "You're banged up"}
	var appr0 := _approach(job, approach)
	if appr0.get("cancel", false):
		return {"ok": false, "cancelled": true}
	if Game.level() < int(job.get("level_req", 1)):
		return {"ok": false, "reason": "Level %d needed" % int(job.get("level_req", 1))}
	if Game.energy() < int(job.get("energy", 6)):
		return {"ok": false, "reason": "Not enough Energy"}
	if Game.nerve() < int(job.get("nerve", 2)):
		return {"ok": false, "reason": "Not enough Nerve"}

	Game.spend_energy(int(job.get("energy", 6)))
	Game.spend_nerve(int(job.get("nerve", 2)))

	var appr := _approach(job, approach)
	var jm := _apply_approach(job, approach)
	var ctx := _ctx(jm)
	ctx.payout_mult *= float(appr.get("payout_mult", 1.0))
	# universal loadout (Step 16)
	var lm := Loadout.mods(loadout)
	ctx.crew_bonus += lm.success_add + Casing.bonus(job_id) - Heat.risk_add()   # cased +30%, heat −risk
	ctx.payout_mult *= lm.payout_mult * (1.0 - lm.cut) * Heat.payout_mult()      # heat fattens the take
	ctx["minigame_score"] = clampf(minigame_score, 0.0, 1.0)                     # WO2 active-play nudge
	var seed := Game.rng.randi()
	var outcome := Resolver.resolve(jm, ctx, seed)
	# Scripted beats (e.g. the prologue's first job) must land — reroll to a win.
	if force_success and not outcome.success:
		for _i in range(40):
			seed = Game.rng.randi()
			outcome = Resolver.resolve(jm, ctx, seed)
			if outcome.success: break

	# crew panic (Step 16): a green younger can bottle it and end the job — you get
	# out clean but empty-handed. Never on a forced-success scripted beat.
	outcome["panicked"] = false
	if not force_success and lm.panic > 0.0 and Game.rng.randf() < lm.panic:
		outcome.success = false
		outcome.panicked = true
		outcome.dirty = 0
		outcome.items = []

	# approach heat modifier + city heat multiplier + loadout heat multiplier
	outcome.heat = max(0.0, outcome.heat + float(appr.get("heat", 0))) * float(ctx.get("heat_mult", 1.0)) * float(lm.heat_mult)
	if outcome.panicked:
		outcome.heat = min(outcome.heat, 0.5)            # legging it early leaves little trace

	# --- graft streak (combo) : consecutive wins multiply payout + XP ---
	if outcome.success:
		Game.bump_streak()
	else:
		Game.reset_streak()
	var smult := Game.streak_mult()
	outcome["streak"] = Game.streak()
	outcome["streak_mult"] = smult
	outcome.dirty = int(round(int(outcome.dirty) * smult))
	outcome.xp = int(round(int(outcome.xp) * smult))

	# apply consequences
	Game.add_dirty(int(outcome.dirty))
	Game.add_heat(float(outcome.heat))
	for it in outcome.items:
		Game.add_item(it)
	if outcome.success:
		Game.add_skill_xp(job_id, 1)

	# records + dailies + milestones
	var haul := int(outcome.dirty)
	for it2 in outcome.items:
		haul += int(it2.value)
	outcome["new_best"] = false
	if outcome.success:
		outcome["new_best"] = Game.note_haul(haul, outcome.get("crit", false))
		Game.daily_progress("jobs", 1)
		Game.daily_progress("dirty", int(outcome.dirty))
		if outcome.get("crit", false):
			Game.daily_progress("crit", 1)
			Game.check_milestone("first_crit", "FIRST CRIT")
		if outcome.new_best and haul >= 800:
			Game.check_milestone("haul_800", "BIG HAUL")

	# Arrest risk on a failed job, scaling with heat (§8). Confiscates carried
	# dirty and sends you to jail — the price of getting greedy while hot.
	outcome["arrested"] = false
	if not outcome.success and not outcome.panicked:
		var h := Game.heat()
		var arrest_chance: float = clampf(0.03 + h * 0.05, 0.03, 0.6) * (1.0 - clampf(lm.escape, 0.0, 0.9))
		if Game.rng.randf() < arrest_chance:
			outcome["arrested"] = true
			var lost := Game.dirty()
			Game.add_dirty(-lost)
			outcome["dirty_lost"] = lost
			Game.add_heat(-Game.heat())  # nicked — heat resets
			Game.send_to_jail(60.0 + h * 15.0)

	var leveled := Game.gain_xp(int(outcome.xp))
	Game.persist()
	Game.changed.emit()

	outcome["ok"] = true
	outcome["leveled"] = leveled
	outcome["chance"] = ctx.get("_chance", 0.0)
	outcome["minigame_score"] = ctx.get("minigame_score", 0.4)   # WO2: reveal shows the stars
	return outcome

# ------------------------------------------------------------------ contracts (Part 2)
## Resolve a character contract from the board — its own chance/pay/xp, applied
## like a job and animated through the same reveal.
func resolve_contract(c: Dictionary) -> Dictionary:
	await _yield()
	var en := int(c.get("en", 10))
	var nv := int(c.get("nv", 4))
	if Game.in_jail(): return {"ok": false, "reason": "You're banged up"}
	if Game.energy() < en: return {"ok": false, "reason": "Not enough Energy"}
	if Game.nerve() < nv: return {"ok": false, "reason": "Not enough Nerve"}
	Game.spend_energy(en); Game.spend_nerve(nv)
	var chance := float(c.get("chance", 50)) / 100.0
	var success := Game.rng.randf() < chance
	var lo := 0; var hi := 0
	var pay := str(c.get("pay", "£0–£0")).replace("£", "").replace(",", "")
	var parts := pay.split("–")
	if parts.size() == 2:
		lo = int(parts[0]); hi = int(parts[1])
	var outcome := {"success": success, "tier": "good" if success else "fail", "crit": false,
		"job_name": c.get("title", "Contract"), "items": [], "near_miss": false,
		"streak": Game.streak(), "streak_mult": 1.0, "new_best": false, "flavor": ""}
	if success:
		Game.bump_streak()
		var dirty := Game.rng.randi_range(max(1, lo), max(1, hi))
		Game.add_dirty(dirty); outcome["dirty"] = dirty
		outcome["xp"] = int(c.get("xp", 100))
		outcome["flavor"] = "Contract cleared. %s will remember it went smooth." % str(c.get("tag", "They")).split(" ")[0].capitalize()
		Game.note_haul(dirty, false); Game.daily_progress("jobs", 1); Game.daily_progress("dirty", dirty)
	else:
		Game.reset_streak()
		outcome["dirty"] = 0
		outcome["xp"] = int(int(c.get("xp", 100)) * 0.25)
		outcome["flavor"] = "It went sideways. Word travels."
	Game.add_heat(2.0)
	outcome["leveled"] = Game.gain_xp(int(outcome.xp))
	outcome["ok"] = true
	Game.persist(); Game.changed.emit()
	return outcome

# ------------------------------------------------------------------ travel (timed)
func travel(city_id: String) -> Dictionary:
	await _yield()
	var c := Config.city(city_id)
	if c.is_empty():
		return {"ok": false, "reason": "Nowhere"}
	if Game.level() < int(c.get("level_req", 1)):
		return {"ok": false, "reason": "Level %d needed" % int(c.get("level_req", 1))}
	if Game.s.city == city_id and not Game.travel_active():
		return {"ok": true, "instant": true, "name": c.get("name", city_id)}
	var from := Config.city(Game.s.city)
	var d := Vector2(float(from.get("x", 0.5)), float(from.get("y", 0.5))).distance_to(Vector2(float(c.get("x", 0.5)), float(c.get("y", 0.5))))
	var secs: float = clampf(30.0 + d * 520.0, 30.0, 240.0)  # 0.5–4 min (prototype-compressed)
	Game.s.travel = {"to": city_id, "from": Game.s.city, "ends_at": Game.now() + secs}
	Game.persist()
	Game.changed.emit()
	return {"ok": true, "instant": false, "secs": secs, "name": c.get("name", city_id)}

func arrive() -> Dictionary:
	await _yield()
	Game.travel_arrive()
	Game.daily_progress("travel", 1)
	Game.check_milestone("first_travel", "NEW CITY")
	return {"ok": true, "name": Config.city(Game.s.city).get("name", "")}

# ------------------------------------------------------------------ gym
func gym_queue(stat: String) -> Dictionary:
	await _yield()
	if Game.s.gym_queue.size() >= 3:
		return {"ok": false, "reason": "Queue full (3 max)"}
	if not Game.spend_energy(10):
		return {"ok": false, "reason": "Not enough Energy (10)"}
	Game.gym_add(stat, 120.0, 1)
	Game.persist(); Game.changed.emit()
	return {"ok": true}

func gym_collect() -> Dictionary:
	await _yield()
	return {"ok": true, "gains": Game.gym_collect()}

# ------------------------------------------------------------------ laundering
func wash_start(front_id: String, amount: int) -> Dictionary:
	await _yield()
	if amount <= 0 or Game.dirty() < amount:
		return {"ok": false, "reason": "Not enough dirty"}
	var w := Economy.wash_out(front_id, amount)
	Game.add_dirty(-int(w.dirty_in))
	var secs: float = min(float(w.cycle_s), 300.0)  # compress cycle for prototype
	Game.s.wash.append({"front": front_id, "dirty_in": w.dirty_in, "clean_out": w.clean_out, "fee": w.fee, "ends_at": Game.now() + secs, "claimed": false})
	Game.daily_progress("wash", int(w.clean_out))
	Game.persist(); Game.changed.emit()
	return {"ok": true, "clean_out": w.clean_out, "secs": secs}

func wash_collect() -> Dictionary:
	await _yield()
	return {"ok": true, "clean": Game.wash_collect()}

# ------------------------------------------------------------------ shop / fence
func buy_gear(gear_id: String) -> Dictionary:
	await _yield()
	var g: Dictionary = Config.gear.get(gear_id, {})
	if g.is_empty():
		return {"ok": false}
	if Game.is_equipped(gear_id):
		return {"ok": false, "reason": "Already got it"}
	if Game.clean() < int(g.price):
		return {"ok": false, "reason": "Not enough clean"}
	Game.add_clean(-int(g.price))
	var item := g.duplicate(true); item["id"] = gear_id
	Game.equip(item)
	Game.persist(); Game.changed.emit()
	return {"ok": true}

func sell_loot() -> Dictionary:
	await _yield()
	return {"ok": true, "total": Game.sell_loot()}

# ------------------------------------------------------------------ jail
func jail_action(kind: String) -> Dictionary:
	await _yield()
	match kind:
		"bail":
			var cost := 200 + Game.level() * 30
			if Game.clean() < cost:
				return {"ok": false, "reason": "Bail is £%d clean" % cost}
			Game.add_clean(-cost); Game.release()
			return {"ok": true, "released": true}
		"brief":
			if Game.clean() < 400:
				return {"ok": false, "reason": "The Brief wants £400 clean"}
			Game.add_clean(-400)
			Game.s.jail_until = Game.now() + Game.jail_left() * 0.4
			Game.persist(); Game.changed.emit()
			return {"ok": true, "reduced": true}
	return {"ok": false}

# ------------------------------------------------------------------ encounters
## Pick a random valid encounter for the moment (sync — no mutation).
func roll_encounter() -> Dictionary:
	var pool: Array = []
	for e in Config.encounters:
		if _enc_ok(e):
			pool.append(e)
	if pool.is_empty():
		return {}
	return pool[Game.rng.randi() % pool.size()]

func _enc_ok(e: Dictionary) -> bool:
	var c: Dictionary = e.get("conditions", {})
	if Game.level() < int(c.get("min_level", 1)): return false
	if c.has("max_heat") and Game.heat() > float(c.max_heat): return false
	if c.has("min_heat") and Game.heat() < float(c.min_heat): return false
	if c.has("cities") and not (Game.s.city in c.cities): return false
	return true

func enc_option_enabled(opt: Dictionary) -> bool:
	if opt.has("req_dirty") and Game.dirty() < int(opt.req_dirty): return false
	if opt.has("req_clean") and Game.clean() < int(opt.req_clean): return false
	return true

## Resolve a chosen encounter option (flat effect, or a stat check → pass/fail).
func resolve_encounter(opt: Dictionary) -> Dictionary:
	await _yield()
	var won := true
	var eff: Dictionary
	if opt.has("check"):
		var st: int = int(Game.s.stats.get(opt.check.stat, 5))
		var roll: int = Game.rng.randi_range(1, 20) + int(st / 3.0)
		won = roll >= int(opt.check.dc)
		eff = (opt.on_pass if won else opt.on_fail).duplicate(true)
	else:
		eff = opt.get("effects", {}).duplicate(true)
	var d := _apply_enc(eff)
	Game.persist()
	Game.changed.emit()
	return {"ok": won, "checked": opt.has("check"), "text": eff.get("text", ""), "deltas": d}

func _apply_enc(eff: Dictionary) -> Dictionary:
	var d := {"dirty": 0, "clean": 0, "xp": 0, "heat": 0, "leveled": []}
	if eff.has("dirty_frac"):
		var lost := int(Game.dirty() * float(eff.dirty_frac))
		Game.add_dirty(-lost); d.dirty -= lost
	if eff.has("dirty"): Game.add_dirty(int(eff.dirty)); d.dirty += int(eff.dirty)
	if eff.has("clean"): Game.add_clean(int(eff.clean)); d.clean += int(eff.clean)
	if eff.has("heat"): Game.add_heat(float(eff.heat)); d.heat += int(eff.heat)
	if eff.has("energy"):
		Game.s.energy.v = clampf(Game.energy() + int(eff.energy), 0, Game.energy_cap()); Game.s.energy.t = Game.now()
	if eff.has("xp"):
		d.leveled = Game.gain_xp(int(eff.xp)); d.xp += int(eff.xp)
	return d

# ------------------------------------------------------------------ character
func allocate_stat(stat: String) -> bool:
	await _yield()
	return Game.allocate_stat(stat)

# ------------------------------------------------------------------ helpers
func _approach(job: Dictionary, idx: int) -> Dictionary:
	if idx >= 0 and job.has("approach") and idx < job.approach.size():
		return job.approach[idx]
	return {}

func _apply_approach(job: Dictionary, idx: int) -> Dictionary:
	var jm := job.duplicate(true)
	var a := _approach(job, idx)
	if a.has("chance"):
		jm.base_chance = float(job.get("base_chance", 0.6)) + float(a.chance)
	return jm

func _ctx(job: Dictionary) -> Dictionary:
	var city := Config.city(Game.s.city)
	var danger := int(city.get("danger", 3))
	# borough danger overrides city danger when the job lives in one
	for b in city.get("boroughs", []):
		if b.get("id", "") == Game.s.get("borough", ""):
			danger = int(b.get("danger", danger))
	# Effective stats fold the fit's gear bonuses in — gear helps ONLY through
	# stats now (§WO1-T6), so the resolver sees trained + equipped.
	var eff := {
		"strength": Game.eff_stat("strength"), "toughness": Game.eff_stat("toughness"),
		"speed": Game.eff_stat("speed"), "slickness": Game.eff_stat("slickness"),
		"luck": Game.eff_stat("luck"),
	}
	var ctx := {
		"stats": eff,
		"skill": Game.skill_level(job.get("id", "")),
		"level": Game.level(),
		"danger": danger,
		"payout_mult": float(city.get("payout_mult", 1.0)),
		"heat_mult": float(city.get("heat_mult", 1.0)),
		"crew_bonus": 0.0,
	}
	ctx["_chance"] = Resolver.success_chance(job, ctx)
	return ctx

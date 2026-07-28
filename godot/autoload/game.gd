extends Node
## Game — session state + pure getters/mutators. It holds the numbers; the
## ServerGateway owns the *decisions* (resolution). UI never mutates state
## directly — it goes through the gateway, which calls these helpers.

signal changed
signal toast(text: String, color: Color)
signal leveled_up(level: int, unlock: String)
signal milestone(text: String)

var s: Dictionary = {}
var rng := RandomNumberGenerator.new()

const SAVE_VERSION := 4

const EN_RATE := 1.0 / 180.0
const NV_RATE := 1.0 / 540.0
const HEAT_RATE := 1.0 / 600.0
const NV_CAP := 20
const HEAT_CAP := 10

func _ready() -> void:
	rng.randomize()
	var loaded := Save.read()
	if loaded.is_empty():
		s = _default_state()
	else:
		s = loaded
		_migrate()

## Fill any keys added after a save was written (forward-compat) + versioned
## migrations for structural changes.
func _migrate() -> void:
	var d := _default_state()
	for k in d.keys():
		if not s.has(k):
			s[k] = d[k]
	var v := int(s.get("save_version", 0))
	if v < 4:
		# progressive unlock arrived in v4: a save from before it has been playing
		# with every venue open, so don't strand a veteran behind the new gates.
		var vet: bool = bool(s.get("prologue_done", false)) or int(s.get("level", 1)) > 1
		if vet:
			s["venues_unlocked"] = ["jobs", "uncle_t", "bank", "fence", "gym", "crew",
				"shop", "map_full", "contacts", "trapline", "territory", "firm", "street", "wardrobe", "feed"]
		s["save_version"] = 4
	_ensure_seed()  # a stable per-player seed for all deterministic rolls

## One stable seed per player, generated once (mirrors Seeds.player_seed but kept
## here so the autoload never depends on a class_name at parse time).
func _ensure_seed() -> void:
	if int(s.get("seed", 0)) == 0:
		s["seed"] = abs(hash("%s-%d" % [s.get("name", "ash"), int(s.get("created_at", 1))]))

func now() -> float:
	return Time.get_unix_time_from_system()

func _default_state() -> Dictionary:
	var t := now()
	return {
		"name": "", "look": 0, "origin": "road", "created_at": t,
		"level": 1, "xp_into": 0, "stat_points": 0,
		"stats": {"strength": 5, "toughness": 5, "speed": 5, "slickness": 5},
		"dirty": 0, "clean": 50,
		"energy": {"v": 100.0, "t": t}, "nerve": {"v": float(NV_CAP), "t": t},
		"heat": {"v": 0.0, "t": t},
		"city": "london", "borough": "the_strip", "unlocked_cities": ["london"],
		"skills": {}, "inventory": [], "equipped": [], "consumables": {},
		"gym_queue": [], "wash": [], "travel": {},
		"jail_until": 0.0, "arrests": 0,
		"streak": 0, "streak_best": 0,
		"records": {"best_haul": 0, "total_jobs": 0, "total_dirty": 0, "crits": 0},
		"flags": {},
		"daily": {},
		"seen_intro": false,
		# --- story (S1): surname is fixed, the debt is the spine ---
		"surname": "Blake",
		"prologue_done": false,
		"debt_active": false, "debt_total": 40000, "debt_paid": 0,
		"debt_days_total": 90, "day": 1,
		"story": {"act": 0, "beat": "", "completed": [], "flags": {}, "counters": {}, "available": []},
		"cast": {},
		"seen_vignettes": {},
		"call_credit": 900,
		"call_topics_used": {},
		"save_version": SAVE_VERSION,
		"seed": 0,
		"venues_unlocked": ["jobs", "uncle_t", "street", "wardrobe", "feed"],
		"director": {"active": "", "completed": []},
		"timers": [],
		"cased": [],
		"echo_queue": [],
		"threads": [],
		"dailies": {"date": "", "tasks": [], "completed": [], "streak": 0,
			"freeze_used_week": 0, "last_complete_date": ""},
		"session": {"last_end": 0, "count_today": 0, "seconds_today": 0,
			"ambushes_this_session": 0},
		"notifications": {"sent_today": 0, "last_sent": 0, "optouts": [], "optin": false},
		"shadow": {"last_attacked": {}, "pending_reports": []},
		"season": {"id": 1, "joined_at": 0, "pass_owned": false},
		"specialisation": null,
		"_stats_trained": 0, "_travels": 0, "_visited": [], "pending_beats": [],
		"hospital_until": 0.0, "_last_ambush": 0.0, "_last_loss": 0.0,
		"street": {}, "respect": 0,
		"wardrobe": [], "fit": {},
		"catchup_until": 0.0, "comeback_seen": 0.0,
		"next_fight_hp": 0,
		"spec_counters": {"violent": 0, "stealth": 0, "management": 0},
		"feed": [], "feed_reacts_today": 0,
		"casing": {}, "cellmate_seen": 0.0,
		# objective-chain progress counters (§WO1-T3)
		"_items_sold": 0, "_arena_wins": 0, "_max_stage": 0, "_cased_total": 0, "_calls_made": 0,
	}

# ------------------------------------------------------------------ story: debt + days
func full_name() -> String:
	var first: String = str(s.get("name", ""))
	var sur: String = str(s.get("surname", "Blake"))
	return (first + " " + sur).strip_edges()

func start_debt() -> void:
	s.debt_active = true
	s.debt_paid = 0
	s.day = 1
	persist(); changed.emit()

func debt_active() -> bool: return bool(s.get("debt_active", false))
func debt_total() -> int: return int(s.get("debt_total", 40000))
func debt_paid() -> int: return int(s.get("debt_paid", 0))
func debt_left() -> int: return max(0, debt_total() - debt_paid())
func day() -> int: return int(s.get("day", 1))
func days_left() -> int:
	return max(0, int(s.get("debt_days_total", 90)) - day() + 1)

func pay_debt(amount: int) -> void:
	s.debt_paid = min(debt_total(), debt_paid() + max(0, amount))
	persist(); changed.emit()

## Action-day rhythm: a "kip" ends the day — refills energy/nerve, ticks the debt
## clock, pays crew wages, and refills the prison-call credit once a week.
func rest() -> void:
	s.day = day() + 1
	s.energy.v = float(energy_cap()); s.energy.t = now()
	s.nerve.v = float(NV_CAP); s.nerve.t = now()
	# crew wages come out of clean money each morning
	var wages := 0
	for m in s.get("crew", []):
		wages += int(m.get("wage", 0))
	if wages > 0:
		add_clean(-min(clean(), wages))
		toast.emit("Wages out: %s clean" % Pal.money(wages), Color("#D63B3B"))
	# prison-call credit refills at the start of each week
	if day() % 7 == 1:
		s.call_credit = 900
	persist(); changed.emit()

# ------------------------------------------------------------------ meta economy (Part 2)
## The append-only Ledger of Consequences (brief §14.9). Never removable.
func ledger_add(title: String, text: String) -> void:
	if not s.has("ledger") or typeof(s.ledger) != TYPE_ARRAY:
		s.ledger = []
	s.ledger.append({"title": title, "text": text, "day": day()})
	persist()

## Firm weekly cut — collectable once per in-game week into clean money.
func firm_cut_ready() -> bool:
	var last := int(s.get("firm", {}).get("cut_day", -99))
	return day() - last >= 7 or last < 0
func collect_firm_cut() -> int:
	if not firm_cut_ready(): return 0
	var cut := int(2140 * Specialisation.mgmt_mult())
	if not s.has("firm") or typeof(s.firm) != TYPE_DICTIONARY: s.firm = {}
	s.firm.cut_day = day()
	Specialisation.bump("management")
	add_clean(cut); persist(); changed.emit()
	return cut

## Trapline daily take — accrues per day since last collect, paid dirty.
func trapline_take() -> int:
	var last := int(s.get("trapline", {}).get("day", day() - 1))
	var days := clampi(day() - last, 0, 7)
	return days * 4180
func trapline_collect() -> int:
	var got := int(trapline_take() * Specialisation.mgmt_mult())
	if got <= 0: return 0
	if not s.has("trapline") or typeof(s.trapline) != TYPE_DICTIONARY: s.trapline = {}
	s.trapline.day = day()
	Specialisation.bump("management")
	add_dirty(got); persist(); changed.emit()
	return got

func new_character(cname: String, look: int, origin: String) -> void:
	s = _default_state()
	s.name = cname
	s.look = look
	s.origin = origin
	# origin bonuses (old GDD §6.1, survives)
	match origin:
		"road": s.stats.slickness += 2
		"athlete": s.stats.strength += 2; s.energy.v = 110
		"college": s.clean += 40
	s.seen_intro = true
	_ensure_seed()
	persist()

func persist() -> void:
	Save.write(s)
	# mirror to the cloud when signed in (debounced; no-op when local-only)
	if Cloud.logged_in():
		Cloud.queue_push()

func reset() -> void:
	Save.wipe()
	s = _default_state()
	changed.emit()

# ------------------------------------------------------------------ getters
func level() -> int: return int(s.level)
func dirty() -> int: return int(s.dirty)
func clean() -> int: return int(s.clean)

func energy_cap() -> int:
	var per: int = int(Config.levels.get("per_level", {}).get("energy_cap", 2))
	return 100 + per * (level() - 1)

func energy() -> int:
	return int(min(energy_cap(), s.energy.v + EN_RATE * (now() - s.energy.t)))

func nerve() -> int:
	return int(min(NV_CAP, s.nerve.v + NV_RATE * (now() - s.nerve.t)))

func heat() -> float:
	return max(0.0, s.heat.v - HEAT_RATE * (now() - s.heat.t))

func xp_progress() -> float:
	return XP.progress(level(), int(s.xp_into), Config.levels.get("curve", {}))

func xp_to_next() -> int:
	return XP.to_next(level(), Config.levels.get("curve", {}))

func rank_name() -> String:
	return Config.rank_for_level(level()).get("name", "Wasteman")

func skill_level(job_id: String) -> int:
	return int(s.skills.get(job_id, 0))

# ------------------------------------------------------------------ mutators
func spend_energy(n: int) -> bool:
	var cur := energy()
	if cur < n: return false
	s.energy.v = cur - n; s.energy.t = now(); return true

func spend_nerve(n: int) -> bool:
	var cur := nerve()
	if cur < n: return false
	s.nerve.v = cur - n; s.nerve.t = now(); return true

func add_dirty(n: int) -> void:
	s.dirty = max(0, int(s.dirty) + n)
	Events.money_changed.emit(int(s.dirty), int(s.clean))
func add_clean(n: int) -> void:
	s.clean = max(0, int(s.clean) + n)
	Events.money_changed.emit(int(s.dirty), int(s.clean))

func add_heat(pips: float) -> void:
	# a Creeper picks up less heat than everyone else (Step 24 passive)
	if pips > 0.0: pips *= Specialisation.heat_mult()
	s.heat.v = clampf(heat() + pips, 0.0, float(HEAT_CAP))
	s.heat.t = now()
	Events.heat_changed.emit(int(round(s.heat.v)))

# ------------------------------------------------------------------ progressive unlock (Step 21)
func venue_is_unlocked(id: String) -> bool:
	return id in s.get("venues_unlocked", [])

func unlock_venue(id: String) -> void:
	if not s.has("venues_unlocked") or typeof(s.venues_unlocked) != TYPE_ARRAY:
		s.venues_unlocked = []
	if not (id in s.venues_unlocked):
		s.venues_unlocked.append(id)
		persist()
		Events.venue_unlocked.emit(id)

func add_skill_xp(job_id: String, _amount: int) -> void:
	# simple: each successful job nudges the track a level occasionally
	s.skills[job_id] = skill_level(job_id) + 1

## Is the comeback catch-up boost (2× XP) currently running?
func catchup_active() -> bool:
	return now() < float(s.get("catchup_until", 0.0))

## Apply XP, return the list of levels crossed (for ceremonies). Doubles during the
## lapsed-player catch-up window (guide Step 35).
func gain_xp(amount: int) -> Array:
	if catchup_active(): amount *= 2
	var res := XP.apply(level(), int(s.xp_into), amount, Config.levels.get("curve", {}))
	s.level = res.level
	s.xp_into = res.xp_into
	var per: int = int(Config.levels.get("per_level", {}).get("stat_points", 1))
	for _l in res.leveled:
		s.stat_points += per
	Events.xp_gained.emit(amount)
	for lvl in res.leveled:
		Events.level_up.emit(int(lvl))
	return res.leveled

func milestone_unlock(lvl: int) -> String:
	return str(Config.levels.get("milestones", {}).get(str(lvl), ""))

func allocate_stat(stat: String) -> bool:
	if int(s.stat_points) <= 0: return false
	if not s.stats.has(stat): return false
	s.stats[stat] += 1
	s.stat_points -= 1
	s["_stats_trained"] = int(s.get("_stats_trained", 0)) + 1
	persist(); changed.emit()
	Events.stat_trained.emit(stat, int(s.stats[stat]))
	return true

func add_item(item: Dictionary) -> void:
	s.inventory.append(item)

# ------------------------------------------------------------------ time
static func fmt_time(secs: float) -> String:
	if secs <= 0: return "ready"
	var s := int(ceil(secs))
	if s >= 3600: return "%dh %dm" % [s / 3600, (s % 3600) / 60]
	if s >= 60: return "%dm %ds" % [s / 60, s % 60]
	return "%ds" % s

# ------------------------------------------------------------------ gym
func gym_add(stat: String, dur: float, gain: int) -> void:
	var start: float = now()
	if s.gym_queue.size() > 0:
		start = max(start, float(s.gym_queue[-1].ends_at))
	s.gym_queue.append({"stat": stat, "ends_at": start + dur, "gain": gain})

func gym_collect() -> Dictionary:
	var gains := {}
	var remaining := []
	for q in s.gym_queue:
		if float(q.ends_at) <= now():
			s.stats[q.stat] = int(s.stats.get(q.stat, 5)) + int(q.gain)
			gains[q.stat] = int(gains.get(q.stat, 0)) + int(q.gain)
			s["_stats_trained"] = int(s.get("_stats_trained", 0)) + 1
			Events.stat_trained.emit(String(q.stat), int(s.stats[q.stat]))
		else:
			remaining.append(q)
	s.gym_queue = remaining
	if not gains.is_empty(): persist()
	return gains

func gym_ready() -> int:
	var n := 0
	for q in s.gym_queue:
		if float(q.ends_at) <= now(): n += 1
	return n

# ------------------------------------------------------------------ laundering
func wash_collect() -> int:
	var got := 0
	var remaining := []
	for b in s.wash:
		if not b.get("claimed", false) and float(b.ends_at) <= now():
			add_clean(int(b.clean_out)); got += int(b.clean_out)
		elif not b.get("claimed", false):
			remaining.append(b)
	s.wash = remaining
	if got > 0: persist()
	return got

func wash_ready() -> int:
	var n := 0
	for b in s.wash:
		if float(b.ends_at) <= now(): n += 1
	return n

# ------------------------------------------------------------------ travel
func travel_active() -> bool:
	return s.travel.has("to") and float(s.travel.get("ends_at", 0)) > now()

func travel_left() -> float:
	return max(0.0, float(s.travel.get("ends_at", 0)) - now())

func travel_dest() -> String:
	return str(s.travel.get("to", ""))

func travel_arrive() -> void:
	if s.travel.has("to"):
		s.city = s.travel.to
		if not (s.city in s.unlocked_cities):
			s.unlocked_cities.append(s.city)
	s.travel = {}
	s["_travels"] = int(s.get("_travels", 0)) + 1
	persist(); changed.emit()
	Events.travelled.emit(String(s.city))

# ------------------------------------------------------------------ wardrobe (upgrade_05 catalogue)
## Owned catalogue items live in s.wardrobe (ids); s.fit maps slot -> equipped id.
## Separate from the legacy s.equipped/gear.json system so nothing breaks.
func owns_item(id: String) -> bool:
	return id in s.get("wardrobe", [])

func own_item(id: String) -> void:
	if not s.has("wardrobe") or typeof(s.wardrobe) != TYPE_ARRAY: s["wardrobe"] = []
	if not (id in s.wardrobe): s.wardrobe.append(id)

func fitted(slot: String) -> String:
	return str(s.get("fit", {}).get(slot, ""))

func fitted_item(slot: String) -> Dictionary:
	var id := fitted(slot)
	return Config.item(id) if id != "" else {}

func equip_item(id: String) -> bool:
	var it := Config.item(id)
	if it.is_empty(): return false
	own_item(id)
	if level() < int(Econ.lvl(it)):
		toast.emit("Level %d needed for that" % int(Econ.lvl(it)), Color("#D63B3B"))
		return false
	if not s.has("fit") or typeof(s.fit) != TYPE_DICTIONARY: s["fit"] = {}
	s.fit[str(it.get("slot", "misc"))] = id
	persist(); changed.emit()
	return true

func unequip_slot(slot: String) -> void:
	if s.has("fit") and s.fit.has(slot):
		s.fit.erase(slot)
		persist(); changed.emit()

## Parse an item's stat string ("TGH ×2, LCK", "all", "SPD") into stat deltas.
static func parse_item_stats(st: String) -> Dictionary:
	var out := {"strength": 0, "toughness": 0, "speed": 0, "slickness": 0, "luck": 0}
	var keys := {"STR": "strength", "TGH": "toughness", "SPD": "speed", "SLK": "slickness", "LCK": "luck"}
	if st == "" or st == "—" or st.to_lower() == "varies": return out
	for tok in st.split(","):
		var t: String = tok.strip_edges()
		var mult := 1
		if "×" in t:
			var mstr: String = t.substr(t.find("×") + 1).strip_edges()
			if mstr.is_valid_int(): mult = int(mstr)
		if t.begins_with("all"):
			for k in ["strength", "toughness", "speed", "slickness"]: out[k] += mult
			continue
		for kk in keys:
			if t.begins_with(kk): out[keys[kk]] += mult
	return out

## Total stat bonus from everything equipped in the fit (via the shared Econ model).
func fit_bonus() -> Dictionary:
	var out := {"strength": 0, "toughness": 0, "speed": 0, "slickness": 0, "luck": 0}
	for slot in s.get("fit", {}).keys():
		var it := Config.item(str(s.fit[slot]))
		if it.is_empty(): continue
		var d := Econ.stat_bonus(it)
		for k in out: out[k] += int(d.get(k, 0))
	return out

## Effective stat = trained base + everything the fit adds.
func eff_stat(name: String) -> int:
	return int(s.stats.get(name, 5)) + int(fit_bonus().get(name, 0))

## Sell an owned gear item back for its resale value (unequips first). Returns £.
func sell_gear(id: String) -> int:
	var it := Config.item(id)
	if it.is_empty(): return 0
	var slot := str(it.get("slot", ""))
	if fitted(slot) == id: unequip_slot(slot)
	if s.has("wardrobe"): s.wardrobe.erase(id)
	var v := int(Econ.sell(it))
	s["_items_sold"] = int(s.get("_items_sold", 0)) + 1   # objective: items_sold
	add_dirty(v); persist(); changed.emit()
	return v

## How many of a consumable you're holding.
func consumable_qty(id: String) -> int:
	return int(s.get("consumables", {}).get(id, 0))

func owned_consumables() -> Array:
	var out: Array = []
	for id in s.get("consumables", {}).keys():
		if int(s.consumables[id]) > 0: out.append(str(id))
	return out

func _gain_energy(n: int) -> void:
	s.energy.v = min(float(energy_cap()), energy() + n); s.energy.t = now()

## Use one consumable — applies its effect to game state where it maps, or tells
## the player to save it for a job. Returns {ok, msg}.
func use_consumable(id: String) -> Dictionary:
	if consumable_qty(id) <= 0: return {"ok": false, "msg": "none held"}
	var it := Config.item(id)
	var n := str(it.get("n", ""))
	var msg := ""
	match n:
		"Energy Drink":
			s["next_fight_hp"] = int(s.get("next_fight_hp", 0)) + 15; msg = "+15 HP going into your next fight"
		"Meal Deal": _gain_energy(10); msg = "+10 Energy"
		"Chicken & Chips": _gain_energy(15); msg = "+15 Energy"
		"Coffee, Petrol Station": _gain_energy(5); msg = "+5 Energy"
		"Painkillers":
			if not in_hospital(): return {"ok": false, "msg": "You're not in hospital"}
			s["hospital_until"] = now() + hospital_left() * 0.7; msg = "Out of hospital sooner"
		"Solicitor's Card":
			if not in_jail(): return {"ok": false, "msg": "You're not banged up"}
			s["jail_until"] = now() + max(0.0, float(s.get("jail_until", 0)) - now()) * 0.5; msg = "Half off your sentence"
		"Burner SIM":
			set_heat(0.0); msg = "New number — police intel reset"
		"Camera Jammer":
			add_heat(-2.0); msg = "Heat down"
		"Spray Can":
			s["respect"] = int(s.get("respect", 0)) + 3; msg = "+3 respect on the wall"
		_:
			return {"ok": false, "msg": "Save that for a job"}
	s.consumables[id] = consumable_qty(id) - 1
	persist(); changed.emit()
	return {"ok": true, "msg": msg}

func set_heat(v: float) -> void:
	s.heat.v = clampf(v, 0.0, float(HEAT_CAP)); s.heat.t = now()

## A random wearable item scaled to a level — the drop from a fight/boss. Prefers
## something you don't already own. Returns the item id or "" if nothing fits.
func roll_gear_drop(level: int) -> String:
	var pool: Array = []
	var owned_pool: Array = []
	for sl in Config.item_slots():
		var k := str(sl.get("k", ""))
		if k == "trophy" or k == "cons": continue
		for it in sl.get("items", []):
			if str(it.get("sh", "")) == "none": continue
			if str(it.get("src", "")) in ["STORY", "EVENT"]: continue
			if int(it.get("il", 0)) > level + 6: continue
			var id := str(it.id)
			if owns_item(id): owned_pool.append(id)
			else: pool.append(id)
	var pick_from: Array = pool if pool.size() > 0 else owned_pool
	if pick_from.is_empty(): return ""
	return pick_from[rng.randi() % pick_from.size()]

# ------------------------------------------------------------------ gear & inventory
## A small combat/shadow edge derived from the FIT's total stat points (the flat
## flat-bonus system is gone — §WO1-T6). ~0 to ~0.35 across a full peng loadout.
func gear_edge() -> float:
	var t := 0
	for v in fit_bonus().values():
		t += int(v)
	return float(t) * 0.005

func is_equipped(id: String) -> bool:
	for g in s.equipped:
		if g.get("id", "") == id: return true
	return false

func equip(item: Dictionary) -> void:
	# one item per slot
	var slot: String = item.get("slot", "misc")
	var kept := []
	for g in s.equipped:
		if g.get("slot", "misc") != slot:
			kept.append(g)
	kept.append(item)
	s.equipped = kept
	persist(); changed.emit()

func sell_loot() -> int:
	var total := 0
	var kept := []
	for it in s.inventory:
		if it.get("kind", "loot") == "loot":
			total += int(it.get("value", 0))
		else:
			kept.append(it)
	s.inventory = kept
	if total > 0:
		add_dirty(total); persist(); changed.emit()
	return total

func loot_count() -> int:
	var n := 0
	for it in s.inventory:
		if it.get("kind", "loot") == "loot": n += 1
	return n

# ------------------------------------------------------------------ jail
func in_jail() -> bool:
	return float(s.get("jail_until", 0)) > now()

func jail_left() -> float:
	return max(0.0, float(s.get("jail_until", 0)) - now())

func send_to_jail(secs: float) -> void:
	s.jail_until = now() + secs
	s.arrests = int(s.get("arrests", 0)) + 1
	persist(); changed.emit()
	Events.arrested.emit("job", int(secs / 60.0))

func release() -> void:
	s.jail_until = 0.0
	persist(); changed.emit()

# ------------------------------------------------------------------ hospital (ambush loss)
func in_hospital() -> bool: return float(s.get("hospital_until", 0)) > now()
func hospital_left() -> float: return max(0.0, float(s.get("hospital_until", 0)) - now())
func hospitalise(secs: float) -> void:
	s.hospital_until = now() + secs
	persist(); changed.emit()

# ------------------------------------------------------------------ streak (combo)
func streak() -> int:
	return int(s.get("streak", 0))

func streak_mult() -> float:
	return 1.0 + min(streak(), 10) * 0.06   # up to +60%

func bump_streak() -> void:
	s.streak = streak() + 1
	s.streak_best = max(int(s.get("streak_best", 0)), streak())

func reset_streak() -> void:
	s.streak = 0

# ------------------------------------------------------------------ records
## Returns true if this is a new best single haul.
func note_haul(total: int, crit: bool) -> bool:
	var rec: Dictionary = s.records
	rec.total_jobs = int(rec.get("total_jobs", 0)) + 1
	rec.total_dirty = int(rec.get("total_dirty", 0)) + max(0, total)
	if crit: rec.crits = int(rec.get("crits", 0)) + 1
	var best: bool = total > int(rec.get("best_haul", 0))
	if best: rec.best_haul = total
	return best

# ------------------------------------------------------------------ milestones
func check_milestone(id: String, text: String) -> void:
	if not s.flags.get(id, false):
		s.flags[id] = true
		milestone.emit(text)

# ------------------------------------------------------------------ daily graft
func today() -> int:
	return int(now() / 86400.0)

func ensure_daily() -> void:
	var d: Dictionary = s.get("daily", {})
	if int(d.get("day", -1)) == today() and d.has("tasks"):
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = today() * 2654435761
	var pool := [
		{"type": "jobs", "desc": "Pull %d jobs", "tmin": 4, "tmax": 8, "rc": 300, "rx": 80, "step": 1},
		{"type": "dirty", "desc": "Earn £%d dirty", "tmin": 600, "tmax": 1500, "rc": 250, "rx": 70, "step": 100},
		{"type": "crit", "desc": "Land a CRIT", "tmin": 1, "tmax": 1, "rc": 400, "rx": 120, "step": 1},
		{"type": "wash", "desc": "Wash £%d clean", "tmin": 400, "tmax": 1000, "rc": 200, "rx": 60, "step": 100},
		{"type": "travel", "desc": "Touch down in a new city", "tmin": 1, "tmax": 1, "rc": 150, "rx": 50, "step": 1},
	]
	var idxs := [0, 1, 2, 3, 4]
	for i in range(idxs.size() - 1, 0, -1):
		var j := rng.randi() % (i + 1)
		var tmp = idxs[i]; idxs[i] = idxs[j]; idxs[j] = tmp
	var tasks := []
	for k in range(3):
		var tpl: Dictionary = pool[idxs[k]]
		var target: int = rng.randi_range(int(tpl.tmin), int(tpl.tmax))
		var step: int = int(tpl.step)
		if step > 1: target = max(step, int(round(target / float(step))) * step)
		var desc: String = tpl.desc
		if desc.find("%d") >= 0: desc = desc % target
		tasks.append({"type": tpl.type, "desc": desc, "target": target, "progress": 0, "claimed": false, "rc": int(tpl.rc), "rx": int(tpl.rx)})
	s.daily = {"day": today(), "tasks": tasks, "streak": int(d.get("streak", 0)), "streak_done": false}
	persist()

func daily_progress(type: String, amount: int) -> void:
	ensure_daily()
	var any := false
	for t in s.daily.tasks:
		if t.type == type and int(t.progress) < int(t.target):
			t.progress = min(int(t.target), int(t.progress) + amount)
			any = true
	if any: persist()

func daily_ready(t: Dictionary) -> bool:
	return int(t.progress) >= int(t.target) and not t.get("claimed", false)

func daily_ready_count() -> int:
	ensure_daily()
	var n := 0
	for t in s.daily.tasks:
		if daily_ready(t): n += 1
	return n

func daily_claim(idx: int) -> Dictionary:
	ensure_daily()
	if idx < 0 or idx >= s.daily.tasks.size(): return {}
	var t: Dictionary = s.daily.tasks[idx]
	if not daily_ready(t): return {}
	t.claimed = true
	add_clean(int(t.rc))
	var leveled := gain_xp(int(t.rx))
	var all := true
	for tt in s.daily.tasks:
		if not tt.get("claimed", false): all = false
	if all and not s.daily.get("streak_done", false):
		s.daily.streak = int(s.daily.get("streak", 0)) + 1
		s.daily.streak_done = true
		check_milestone("daily_first", "DAILY DONE")
	persist(); changed.emit()
	return {"clean": int(t.rc), "xp": int(t.rx), "leveled": leveled}

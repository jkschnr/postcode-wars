class_name Econ
extends RefCounted
## Item economy (faithful port of upgrade_05/econ.js). Prices, level gates and
## numeric stats are DERIVED from an item's ilvl + rarity + stat string, so the
## whole 207-item set stays balanced without hand-typing numbers. One source of
## truth shared by the shop, the character sheet and combat.
##   Econ.of(item) -> {lvl, cash, sell, stats:[{k,label,v}], power}

const STAT := {"STR": "STRENGTH", "SPD": "SPEED", "TGH": "TOUGHNESS", "SLK": "SLICKNESS", "LCK": "LUCK"}
const STAT_KEY := {"STR": "strength", "SPD": "speed", "TGH": "toughness", "SLK": "slickness", "LCK": "luck"}
const RMUL := {"Ba": 1.0, "De": 1.6, "Pe": 2.6, "Ce": 4.2, "Ic": 7.0}       # price multiplier
const RSTAT := {"Ba": 1.0, "De": 1.15, "Pe": 1.35, "Ce": 1.6, "Ic": 2.0}    # stat multiplier

## Level gate: wearable a couple of levels before its ilvl.
static func lvl(it: Dictionary) -> int:
	var il := int(it.get("il", 0))
	return 1 if il == 0 else max(1, int(round(il * 0.85)))

## Parse "TGH ×2, LCK" / "SPD" / "all" / "all ×1" into weighted stat keys.
static func weights(it: Dictionary) -> Array:
	var s := str(it.get("st", ""))
	var out: Array = []
	if s.to_lower().begins_with("all"):
		var w := 1
		if "×" in s:
			var m := s.substr(s.find("×") + 1).strip_edges()
			if m.length() > 0 and m[0].is_valid_int(): w = int(m[0])
		for k in STAT: out.append({"k": k, "w": w})
		return out
	for part in s.split(","):
		var t: String = part.strip_edges()
		if t.length() < 3: continue
		var key := t.substr(0, 3)
		if not STAT.has(key): continue
		var w := 1
		if "×" in t:
			var mstr := t.substr(t.find("×") + 1).strip_edges()
			if mstr.length() > 0 and mstr[0].is_valid_int(): w = int(mstr[0])
		out.append({"k": key, "w": w})
	return out

## Stat values scale with ilvl, weight and rarity — ~1 point per 2.4 ilvl.
static func stats(it: Dictionary) -> Array:
	var w := weights(it)
	if w.is_empty(): return []
	# Stat divisor is a balance band (§WO1-T6.3): a full-Peng L20 loadout must
	# land at +55..75 total stat points. 10.0 puts it at ~70. Tune the BAND here,
	# never individual items.
	var div_stat: float = float(Config.get_value("econ.stat_divisor", 10.0))
	var base: int = max(1, int(round(int(it.get("il", 0)) / div_stat)))
	var div := 2 if w.size() > 3 else 1
	var rs := float(RSTAT.get(it.get("r", "Ba"), 1.0))
	var out: Array = []
	for x in w:
		var v: int = max(1, int(round(base * int(x.w) * rs / div)))
		out.append({"k": x.k, "label": STAT[x.k], "v": v})
	return out

static func power(it: Dictionary) -> int:
	var n := 0
	for s in stats(it): n += int(s.v)
	return n

## Cash price (int). Consumables carry their own "£N"; wearables use the curve.
static func cash(it: Dictionary) -> int:
	if it.has("price"): return _num(str(it.price))
	var il := int(it.get("il", 0))
	if il == 0: return 0
	var raw := (14.0 + pow(float(il), 1.72) * 1.9) * float(RMUL.get(it.get("r", "Ba"), 1.0))
	var step := 5 if raw < 100 else (25 if raw < 1000 else (100 if raw < 5000 else 500))
	return int(round(raw / step)) * step

static func sell(it: Dictionary) -> int:
	return int(round(cash(it) * 0.4))

static func of(it: Dictionary) -> Dictionary:
	return {"lvl": lvl(it), "cash": cash(it), "sell": sell(it), "stats": stats(it), "power": power(it)}

## Summed stat bonus mapped to game stat names — what equipping an item adds.
static func stat_bonus(it: Dictionary) -> Dictionary:
	var out := {"strength": 0, "toughness": 0, "speed": 0, "slickness": 0, "luck": 0}
	for s in stats(it):
		out[STAT_KEY[s.k]] += int(s.v)
	return out

static func _num(p: String) -> int:
	var digits := ""
	for ch in p:
		if ch >= "0" and ch <= "9": digits += ch
	return int(digits) if digits != "" else 0

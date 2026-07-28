class_name Comeback
extends RefCounted
## Graduated treatment for lapsed players (guide Step 35). The #1 reason lapsed
## players bounce is "I can't remember what I was doing" — so on return we hand
## back what accrued, remind them what they were on, and (for longer gaps) hand a
## catch-up boost. evaluate() reads the gap; apply() grants it, once per lapse.

## Tier by days away: 0 = normal, 1 = 4–7d, 2 = 8–29d, 3 = 30d+.
static func evaluate() -> Dictionary:
	var last := float(Game.s.get("session", {}).get("last_end", 0))
	if last <= 0: return {"tier": 0, "days": 0}
	var days := int((Game.now() - last) / 86400.0)
	# don't re-fire for the same lapse
	if float(Game.s.get("comeback_seen", 0.0)) >= last: return {"tier": 0, "days": days}
	var tier := 0
	if days >= 30: tier = 3
	elif days >= 8: tier = 2
	elif days >= 4: tier = 1
	return {"tier": tier, "days": days}

## Grant the treatment for a tier and return what was handed over (for the card).
static func apply(info: Dictionary) -> Dictionary:
	var days: int = int(info.get("days", 0))
	var tier: int = int(info.get("tier", 0))
	# welcome-back bundle — accrued street income, handed back uncapped once
	var bundle := clampi(days, 4, 30) * 260
	Game.add_clean(bundle)
	var catchup := false
	if tier >= 2:
		Game.s["catchup_until"] = Game.now() + 48.0 * 3600.0   # 2× XP for 48h
		catchup = true
	Game.s["comeback_seen"] = float(Game.s.get("session", {}).get("last_end", Game.now()))
	Game.persist(); Game.changed.emit()
	if Telemetry: Telemetry.log_event("comeback_shown", {"days": days, "tier": tier})
	return {"bundle": bundle, "catchup": catchup, "days": days, "tier": tier}

## The current objective text, so the card can remind them what they were on.
static func recap_line() -> String:
	var cur := Director.current()
	if not cur.is_empty(): return str(cur.get("text", ""))
	if Game.debt_active(): return "Still %s owed to Rhodes, %d days on the clock." % [Pal.money(Game.debt_left()), Game.days_left()]
	return "Back on the road. Pick a block and get to work."

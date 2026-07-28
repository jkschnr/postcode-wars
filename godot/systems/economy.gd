class_name Economy
extends RefCounted
## Two currencies, one tension (old GDD §15.1 — survives). Dirty cash is earned
## by crime and at risk; clean money is safe and buys the legit ladder. Washing
## converts dirty→clean with a fee over time. Pure helpers; Game holds balances.

## Laundering fronts (fee shrinks as you go up tiers).
const FRONTS := {
	"chickenlix": {"name": "ChickenLix", "fee": 0.30, "rate": 600, "cycle_s": 7200},
	"carwash": {"name": "Car Wash", "fee": 0.26, "rate": 1400, "cycle_s": 10800},
	"barbers": {"name": "Barbershop", "fee": 0.22, "rate": 2200, "cycle_s": 14400},
}

static func wash_out(front_id: String, dirty_in: int) -> Dictionary:
	var f: Dictionary = FRONTS.get(front_id, FRONTS.chickenlix)
	var capped: int = min(dirty_in, int(f.rate))
	var fee := int(round(capped * f.fee))
	return {"dirty_in": capped, "clean_out": capped - fee, "fee": fee, "cycle_s": f.cycle_s}

## Loss caps (old GDD A.4) — legible, survivable.
static func arrest_loss(carried_dirty: int) -> int:
	return carried_dirty   # 100% carried dirty confiscated

static func duppy_loss(carried_dirty: int) -> int:
	return int(round(carried_dirty * 0.25))

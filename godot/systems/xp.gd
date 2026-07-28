class_name XP
extends RefCounted
## Level 1–100 spine (the backbone). Pure & testable. Curve params come from
## data/levels.json so they can be tuned without touching code.

## XP required to go from `level` to `level+1`.
static func to_next(level: int, curve: Dictionary) -> int:
	var base: float = curve.get("base", 100.0)
	var exp: float = curve.get("exp", 1.55)
	return int(round(base * pow(float(level), exp)))

## Apply gained XP to (level, xp_into). Returns the new values plus any levels
## crossed, so the caller can fire a ceremony per level.
static func apply(level: int, xp_into: int, gained: int, curve: Dictionary) -> Dictionary:
	var max_level: int = curve.get("max_level", 100)
	var leveled: Array = []
	xp_into += gained
	while level < max_level:
		var need := to_next(level, curve)
		if xp_into < need:
			break
		xp_into -= need
		level += 1
		leveled.append(level)
	if level >= max_level:
		xp_into = 0
	return {"level": level, "xp_into": xp_into, "leveled": leveled}

## 0..1 progress through the current level (for the big XP bar).
static func progress(level: int, xp_into: int, curve: Dictionary) -> float:
	if level >= int(curve.get("max_level", 100)):
		return 1.0
	var need := to_next(level, curve)
	return clampf(float(xp_into) / float(need), 0.0, 1.0)

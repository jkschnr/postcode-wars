class_name PushLuck
extends RefCounted
## Push-your-luck maths (guide Step 17). Risk and loot climb per stage; slickness
## shaves risk. All numbers come from tuning.json so balance is a data edit.

static func _risk_arr() -> Array:
	return Config.get_value("pushluck.stage_risk", [0.08, 0.18, 0.32, 0.50, 0.68])

static func _loot_arr() -> Array:
	return Config.get_value("pushluck.stage_loot_mult", [1.0, 1.6, 2.5, 4.0, 7.0])

static func stage_count() -> int:
	return _risk_arr().size()

## Risk of getting caught pushing into stage i, reduced by slickness.
static func risk(i: int, slk: int) -> float:
	var arr := _risk_arr()
	var base: float = float(arr[i]) if i >= 0 and i < arr.size() else float(Config.get_value("pushluck.max_risk", 0.85))
	var red := float(Config.get_value("pushluck.slickness_risk_reduction_per_point", 0.004))
	return clampf(base - slk * red, 0.02, float(Config.get_value("pushluck.max_risk", 0.85)))

## Loot multiplier for the loot found in stage i (× the job's base take).
static func loot_mult(i: int) -> float:
	var arr := _loot_arr()
	return float(arr[i]) if i >= 0 and i < arr.size() else float(arr[arr.size() - 1])

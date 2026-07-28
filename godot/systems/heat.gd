class_name Heat
extends RefCounted
## The session heat arc (guide Step 25). Heat rises through a run and cuts both
## ways: it fattens payouts AND raises failure + ambush risk. Past 6 pips a warning
## strip appears, and the banking decision — LAY LOW, go home — is the real climax:
## "I had £3,200 and I went out one more time."

static func _t(path: String, fb: Variant) -> Variant:
	return Config.get_value("heat_arc." + path, fb)

static func pips() -> int:
	return int(round(Game.heat()))

## Payouts scale up with heat — the reason to push one more.
static func payout_mult() -> float:
	return 1.0 + float(pips()) * float(_t("payout_per_pip", 0.08))

## Failure (and ambush) chance rises with heat — the reason not to.
static func risk_add() -> float:
	return float(pips()) * float(_t("risk_per_pip", 0.02))

static func hot() -> bool:
	return pips() >= int(_t("warn_at", 6))

## The warning strip line, by how hot you are.
static func strip_line() -> String:
	var p := pips()
	if p >= 10: return "Go home. Go home now."
	if p >= 8: return "There's a car that's been past twice. Same car."
	if p >= 6: return "You're hot. Everyone knows you were out last night."
	if p >= 3: return "People have noticed you're about."
	return ""

## Go home, cool right off. Ends the run — the climax choice. Refills a little
## nerve (a night in) and drops heat to the floor.
static func lay_low() -> void:
	Game.set_heat(float(_t("lay_low_to", 0.0)))
	Game.s.nerve.v = float(Game.NV_CAP); Game.s.nerve.t = Game.now()
	Game.persist(); Game.changed.emit()
	if Telemetry: Telemetry.log_event("lay_low", {})

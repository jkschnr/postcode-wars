extends Node
## Ambushes (guide Step 26) — the game interrupts you with a situation you didn't
## choose, which is what gives the bank, gear and stats a reason to exist. Strict
## guardrails so it never feels cheap: safe cooldown, max per session, never mid-
## overlay, never right after a loss.

func _t(path: String, fb: Variant) -> Variant:
	return Config.get_value("ambush." + path, fb)

## Roll an ambush for a context ("post_job", "travel_home", "city_entry"). Returns
## true if one fired (and the card is now up).
func maybe_trigger(ctx: String) -> bool:
	if not Game.s.get("prologue_done", false): return false
	if Game.in_jail() or Game.in_hospital(): return false
	if App.I.overlay.get_child_count() > 1: return false     # never stack on another card
	var sess: Dictionary = Game.s.get("session", {})
	if int(sess.get("ambushes_this_session", 0)) >= int(_t("max_per_session", 2)): return false
	if Game.now() - float(Game.s.get("_last_ambush", 0)) < float(_t("cooldown_s", 60)): return false
	if Game.now() - float(Game.s.get("_last_loss", 0)) < 7200.0: return false   # 2h after a loss

	var base: Dictionary = _t("base", {})
	var chance := 0.0
	match ctx:
		"post_job": chance = float(base.get("post_job_hot", 0.15)) * clampf(Game.heat() / 5.0, 0.2, 1.6)
		"travel_home": chance = float(base.get("travel_home", 0.10))
		"city_entry": chance = float(base.get("city_entry_rich", 0.12)) if Game.dirty() >= int(_t("rich_threshold_dirty", 1000)) else 0.03
		_: chance = 0.10
	if Game.dirty() >= int(_t("rich_threshold_dirty", 1000)): chance += 0.05
	if randf() > chance: return false

	_fire()
	return true

func _fire() -> void:
	var setups: Array = Config.ambushes.get("setups", ["Someone steps out of a doorway."])
	# the rival is a real player's shadow snapshot, matched within ±25% power
	# (guide Step 30) — the seeded pool stands in until real accounts exist
	var snap := Shadow.pick_opponent()
	var atk := Shadow.to_attacker(snap, setups[randi() % setups.size()])
	Shadow.mark_attacked(str(snap.get("player_id", "")))
	Game.s.session["ambushes_this_session"] = int(Game.s.get("session", {}).get("ambushes_this_session", 0)) + 1
	Game.s["_last_ambush"] = Game.now()
	Game.persist()
	Events.ambushed.emit(atk)
	var card := AmbushCard.new()
	card.setup(atk)
	App.I.overlay.add_child(card)

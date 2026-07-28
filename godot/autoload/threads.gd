extends Node
## Threads / exit-state (guide Step 10) — the player should never leave with a
## clean slate. On backgrounding, if too little is "running", we offer a quick
## "Before you go" card of one-tap ways to leave something cooking. "I'M GOOD"
## is always present and never punished.

func active_timers() -> int:
	var n: int = Game.s.get("gym_queue", []).size() + Game.s.get("wash", []).size()
	if Game.travel_active(): n += 1
	return n

func energy_near_full() -> bool:
	return float(Game.energy()) / float(Game.energy_cap()) >= 0.85

func has_open_thread() -> bool:
	return Game.s.get("echo_queue", []).size() > 0

func has_expiring() -> bool:
	return Game.s.get("cased", []).size() > 0

## Which "leave something running" conditions are MISSING right now.
func missing() -> Array:
	var m: Array = []
	if active_timers() < 2: m.append("timers")
	if energy_near_full(): m.append("energy")   # sitting on energy = wasting the night
	if not has_open_thread(): m.append("thread")
	if not has_expiring(): m.append("expiring")
	return m

## Rows the card should offer, addressing the missing conditions. Each row is
## {icon, label, action_label, screen}.
func rows() -> Array:
	var out: Array = []
	var miss := missing()
	if "timers" in miss and Game.venue_is_unlocked("gym"):
		out.append({"label": "Gym slot's free", "action": "START", "screen": "gym"})
	if ("timers" in miss or "energy" in miss):
		out.append({"label": "Roads are quiet — go earn", "action": "GRAFT", "screen": "jobs"})
	if Game.dirty() >= 300 and Game.venue_is_unlocked("bank"):
		out.append({"label": "You're carrying dirty money", "action": "BANK", "screen": "bank"})
	if "expiring" in miss:
		out.append({"label": "Nothing cased for later", "action": "CASE", "screen": "jobs"})
	if Game.daily_ready_count() > 0:
		out.append({"label": "Daily graft's not done", "action": "COLLECT", "screen": ""})
	return out.slice(0, 4)

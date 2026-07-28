extends Node
## Story — the arc/chapter state machine (brief §14.1). Holds act, completed
## beats, flags and counters (persisted in Game.s.story). Beats are data
## (Config.story_beats); completing one applies its on_complete effects. Story
## PULLS, it never blocks — if the player ignores it, graft still works.

signal beat_available(id: String)

# The Hook (S1) is a fixed linear chain; later acts use evaluate() + unlocks.
const PROLOGUE := ["p_visit", "p_tea", "p_barbershop", "p_firstjob", "p_nads"]

func _s() -> Dictionary:
	if not Game.s.has("story") or typeof(Game.s.story) != TYPE_DICTIONARY:
		Game.s.story = {"act": 0, "beat": "", "completed": [], "flags": {}, "counters": {}, "available": []}
	if not Game.s.story.has("available"):
		Game.s.story.available = []
	return Game.s.story

func act() -> int: return int(_s().act)
func has_flag(f: String) -> bool: return bool(_s().flags.get(f, false))
func set_flag(f: String, v := true) -> void: _s().flags[f] = v
func counter(c: String) -> int: return int(_s().counters.get(c, 0))
func bump(c: String, n := 1) -> void: _s().counters[c] = counter(c) + n
func completed(id: String) -> bool: return id in _s().completed
func prologue_done() -> bool: return bool(Game.s.get("prologue_done", false))

## Apply a beat's on_complete effects and record it. Called by the scene player
## when the last card of a beat is dismissed.
func complete_beat(id: String) -> void:
	var b := Config.beat(id)
	if id != "" and not (id in _s().completed):
		_s().completed.append(id)
	_s().available.erase(id)
	var oc: Dictionary = b.get("on_complete", {})
	for f in oc.get("flags", []):
		set_flag(str(f))
	var rels: Dictionary = oc.get("relationships", {})
	for k in rels.keys():
		Cast.adjust(str(k), int(rels[k]))
	var sets: Dictionary = oc.get("set", {})
	for k in sets.keys():
		_apply_set(str(k), sets[k])
	_s().act = max(int(_s().act), int(b.get("act", 0)))
	for nb in oc.get("unlock_beats", []):
		_s().available.append(str(nb))
	Game.persist()

func _apply_set(key: String, value) -> void:
	match key:
		"debt_active":
			if bool(value): Game.start_debt()
		"prologue_done":
			Game.s.prologue_done = bool(value)

## For post-prologue content: queue any non-completed beat whose conditions are
## met. Emits beat_available; the shell decides how to surface it (S2+).
func evaluate() -> void:
	for id in Config.story_beats.keys():
		if completed(id) or id in _s().available:
			continue
		if _unlocked(Config.beat(id)):
			_s().available.append(id)
			beat_available.emit(id)

func _unlocked(b: Dictionary) -> bool:
	var u: Dictionary = b.get("unlock", {})
	if u.is_empty(): return false
	if Game.level() < int(u.get("min_level", 1)): return false
	for rb in u.get("requires_beats", []):
		if not completed(str(rb)): return false
	for rf in u.get("requires_flags", []):
		if not has_flag(str(rf)): return false
	if u.has("city") and Game.s.city != str(u.city): return false
	return true

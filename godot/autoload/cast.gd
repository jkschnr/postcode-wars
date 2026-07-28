extends Node
## Cast — the named characters and how they feel about you. Static definition
## lives in data/cast/*.json (Config.cast); mutable state (relationship, trust,
## met, lifecycle) lives in Game.s.cast so it saves. Relationship shifts are
## NEVER shown as numbers — every change emits one line in the character's voice
## (brief §4.16 / §14.2).

signal reacted(id: String, line: String, delta: int)

func _def(id: String) -> Dictionary:
	return Config.character(id)

func _state(id: String) -> Dictionary:
	if not Game.s.has("cast") or typeof(Game.s.cast) != TYPE_DICTIONARY:
		Game.s.cast = {}
	if not Game.s.cast.has(id):
		var st: Dictionary = _def(id).get("start", {})
		Game.s.cast[id] = {
			"relationship": int(st.get("relationship", 0)),
			"trust": int(st.get("trust", 0)),
			"state": "active", "met": false, "flags": [],
		}
	return Game.s.cast[id]

func name_of(id: String) -> String:
	return _def(id).get("display_name", id.capitalize())

func portrait_of(id: String) -> String:
	return _def(id).get("portrait", "")

func rel(id: String) -> int: return int(_state(id).relationship)
func trust(id: String) -> int: return int(_state(id).trust)
func met(id: String) -> bool: return bool(_state(id).met)
func life_state(id: String) -> String: return str(_state(id).state)

func meet(id: String) -> void:
	var s := _state(id)
	if not s.met:
		s.met = true
		Game.persist()

## Shift relationship and surface one reaction line (never a number).
func adjust(id: String, delta: int) -> void:
	if delta == 0: return
	var s := _state(id)
	s.relationship = clampi(int(s.relationship) + delta, -100, 100)
	_reclass(id)
	reacted.emit(id, _reaction_line(id, delta), delta)
	Game.persist()

func adjust_trust(id: String, delta: int) -> void:
	if delta == 0: return
	var s := _state(id)
	s.trust = clampi(int(s.trust) + delta, -100, 100)
	Game.persist()

func _reclass(id: String) -> void:
	var s := _state(id)
	if int(s.relationship) <= -100:
		s.state = "lost"
	elif int(s.relationship) <= -40:
		s.state = "strained"
	elif s.state != "lost":
		s.state = "active"

func _reaction_line(id: String, delta: int) -> String:
	var r: Dictionary = _def(id).get("reactions", {})
	if life_state(id) == "lost":
		return str(r.get("lost", ""))
	return str(r.get("up", "")) if delta >= 0 else str(r.get("down", ""))

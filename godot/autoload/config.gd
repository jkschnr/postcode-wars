extends Node
## Config — loads all tuning data from res://data/*.json. Single source; no magic
## numbers in gameplay scripts (brief §9).

var cities: Dictionary = {}
var jobs: Dictionary = {}
var levels: Dictionary = {}
var ranks: Array = []
var encounters: Array = []
var gear: Dictionary = {}
var story_beats: Dictionary = {}      # id -> beat
var story_cards: Dictionary = {}      # id -> card
var story_calls: Dictionary = {}      # id -> prison-call def
var cast: Dictionary = {}             # id -> character def
var vignettes: Dictionary = {}        # job_id -> Array[vignette]
var factions: Dictionary = {}         # id -> {label, ring, note}
var npcs: Array = []                   # upgrade-01 roster
var map_cities: Dictionary = {}        # {cities:[], lines:[]} for the main map
var city_map: Dictionary = {}          # {zones, venues, kind_col, patrol, supply}
var tuning: Dictionary = {}            # every number in the game (guide Step 1)
var objectives: Dictionary = {}        # id -> objective (Director chain, Step 9)
var objectives_start: String = ""
var greeter: Dictionary = {}           # character -> greeter sets (Step 6)
var backend: Dictionary = {}           # Supabase creds (accounts + cloud save)
var stages: Dictionary = {}            # job_id -> Array[stage] (push-your-luck, Step 17)
var ambushes: Dictionary = {}          # {setups:[], attackers:[]} (Step 26)
var items: Dictionary = {}             # {slots, sets, rarity, source} (upgrade_05 catalogue)
var items_by_id: Dictionary = {}       # id -> item row
var season_data: Dictionary = {}       # {length_days, themes} (Step 37)

func npcs_in(city: String) -> Array:
	var out := []
	for n in npcs:
		if n.get("city", "") == city: out.append(n)
	return out
func npcs_of(faction: String) -> Array:
	var out := []
	for n in npcs:
		if n.get("faction", "") == faction: out.append(n)
	return out

func _ready() -> void:
	cities = _json("res://data/cities.json")
	jobs = _json("res://data/jobs.json")
	levels = _json("res://data/levels.json")
	ranks = _json("res://data/ranks.json")
	story_beats = _json("res://data/story/beats.json")
	story_cards = _json("res://data/story/cards.json")
	story_calls = _json("res://data/story/calls.json")
	factions = _json("res://data/factions.json")
	npcs = _json("res://data/npcs.json")
	map_cities = _json("res://data/map_cities.json")
	city_map = _json("res://data/city_map.json")
	tuning = _json("res://data/tuning.json")
	backend = _json("res://data/backend.json")
	season_data = _json("res://data/season.json")
	_load_items()
	_load_stages()
	_load_objectives()
	_load_greeter()
	_load_cast()
	_load_vignettes()
	_load_encounters()
	# inject ids so a job/city dict knows its own key
	for id in jobs.keys():
		jobs[id]["id"] = id
	for id in cities.keys():
		cities[id]["id"] = id

## Read any tuning number by dot-path, e.g. get_value("pushluck.stage_risk").
## Asserts in dev when a key is missing so balance bugs fail loud; returns the
## supplied fallback in release.
func get_value(path: String, fallback: Variant = null) -> Variant:
	var node: Variant = tuning
	for part in path.split("."):
		if typeof(node) == TYPE_DICTIONARY and node.has(part):
			node = node[part]
		else:
			assert(false, "Config.get_value: missing tuning key '%s'" % path)
			return fallback
	return node

## Live-reload tuning during development (no restart).
func reload() -> void:
	tuning = _json("res://data/tuning.json")

func _json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		push_error("Config: missing " + path)
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	var data = JSON.parse_string(f.get_as_text())
	f.close()
	if data == null:
		push_error("Config: bad JSON in " + path)
		return {}
	return data

func _load_stages() -> void:
	ambushes = _json("res://data/ambushes/setups.json")
	stages = {}
	var dir := DirAccess.open("res://data/stages")
	if dir == null: return
	for file in dir.get_files():
		if file.ends_with(".json"):
			var d = _json("res://data/stages/" + file)
			if typeof(d) == TYPE_DICTIONARY and d.has("job"):
				stages[d.job] = d.get("stages", [])

func stages_for(job_id: String) -> Array:
	return stages.get(job_id, [])

func _load_items() -> void:
	items = _json("res://data/items.json")
	items_by_id = {}
	for slot in items.get("slots", []):
		for it in slot.get("items", []):
			if it.has("id"): items_by_id[it.id] = it

func item(id: String) -> Dictionary:
	return items_by_id.get(id, {})

func item_slots() -> Array:
	return items.get("slots", [])

func _load_objectives() -> void:
	objectives = {}
	var d = _json("res://data/objectives/chain.json")
	if typeof(d) == TYPE_DICTIONARY:
		objectives_start = String(d.get("start", ""))
		for o in d.get("chain", []):
			objectives[o.get("id", "")] = o

func objective(id: String) -> Dictionary:
	return objectives.get(id, {})

func _load_greeter() -> void:
	greeter = {}
	var dir := DirAccess.open("res://data/greeter")
	if dir == null: return
	for file in dir.get_files():
		if file.ends_with(".json"):
			var g = _json("res://data/greeter/" + file)
			if typeof(g) == TYPE_DICTIONARY and g.has("character"):
				greeter[g.character] = g

func _load_encounters() -> void:
	encounters = []
	var dir := DirAccess.open("res://data/encounters")
	if dir == null:
		return
	for file in dir.get_files():
		if file.ends_with(".json"):
			var e = _json("res://data/encounters/" + file)
			if typeof(e) == TYPE_ARRAY:
				encounters.append_array(e)          # a pack of many
			elif typeof(e) == TYPE_DICTIONARY and not e.is_empty():
				encounters.append(e)                # a single encounter

func _load_cast() -> void:
	cast = {}
	var dir := DirAccess.open("res://data/cast")
	if dir == null: return
	for file in dir.get_files():
		if file.ends_with(".json"):
			var c = _json("res://data/cast/" + file)
			if typeof(c) == TYPE_DICTIONARY and c.has("id"):
				cast[c.id] = c

func _load_vignettes() -> void:
	vignettes = {}
	var dir := DirAccess.open("res://data/vignettes")
	if dir == null: return
	for file in dir.get_files():
		if file.ends_with(".json"):
			var arr = _json("res://data/vignettes/" + file)
			if typeof(arr) == TYPE_ARRAY:
				for v in arr:
					var jid: String = v.get("job", file.get_basename())
					if not vignettes.has(jid): vignettes[jid] = []
					vignettes[jid].append(v)

func card(id: String) -> Dictionary:
	return story_cards.get(id, {})

func beat(id: String) -> Dictionary:
	return story_beats.get(id, {})

func character(id: String) -> Dictionary:
	return cast.get(id, {})

func job(id: String) -> Dictionary:
	return jobs.get(id, {})

func city(id: String) -> Dictionary:
	return cities.get(id, {})

func rank_for_level(level: int) -> Dictionary:
	var r: Dictionary = ranks[0] if ranks.size() > 0 else {"name": "Wasteman"}
	for rk in ranks:
		if level >= int(rk.get("level", 1)):
			r = rk
	return r

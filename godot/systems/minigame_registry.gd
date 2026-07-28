class_name MinigameRegistry
extends RefCounted
## job_id → minigame scene. 8 minigames cover 15 jobs; reuse is deliberate but each
## reused instance gets different ctx + copy (see each minigame's per-job reskin), so
## warehouse and shoplift never feel like the same game. WO2-T1.

const MAP := {
	"phone_snatch":    "res://minigames/timing_bar.tscn",
	"pickpocket":      "res://minigames/steady_hold.tscn",
	"shoplift":        "res://minigames/attention_sweep.tscn",
	"burglary":        "res://minigames/lockpick.tscn",
	"corner_shotting": "res://minigames/serve_queue.tscn",
	"chop_run":        "res://minigames/hotwire_drive.tscn",
	"extortion":       "res://minigames/pressure_dial.tscn",
	"protection":      "res://minigames/pressure_dial.tscn",
	"grow_harvest":    "res://minigames/attention_sweep.tscn",
	"counterfeit":     "res://minigames/serve_queue.tscn",
	"card_fraud":      "res://minigames/steady_hold.tscn",
	"ram_raid":        "res://minigames/smash_load.tscn",
	"warehouse":       "res://minigames/attention_sweep.tscn",
	"smuggle":         "res://minigames/steady_hold.tscn",
	"gun_deal":        "res://minigames/pressure_dial.tscn",
}

## Scene backdrop bound to each job (WO2-T10). Falls back to street_night.
const SCENE := {
	"phone_snatch": "street_night", "pickpocket": "street_night",
	"shoplift": "shop_interior", "burglary": "terrace_night",
	"corner_shotting": "corner_block", "chop_run": "lockup_yard",
	"extortion": "market", "protection": "corner_block",
	"grow_harvest": "grow_room", "counterfeit": "market",
	"card_fraud": "shop_interior", "ram_raid": "precinct_night",
	"warehouse": "docks_night", "smuggle": "docks_night", "gun_deal": "towpath",
}

static func has(job_id: String) -> bool:
	return MAP.has(job_id)

static func path_for(job_id: String) -> String:
	return String(MAP.get(job_id, ""))

static func scene_for(job_id: String) -> String:
	return String(SCENE.get(job_id, "street_night"))

## Instantiate the minigame for a job, or null if none / scene missing.
static func make(job_id: String) -> Minigame:
	var p := path_for(job_id)
	if p == "" or not ResourceLoader.exists(p):
		return null
	var ps: PackedScene = load(p)
	if ps == null:
		return null
	var inst := ps.instantiate()
	return inst as Minigame

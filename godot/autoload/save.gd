extends Node
## Save — local persistence (user://). This is the M1 store; the NakamaGateway
## takes over authority in M3 without callers changing.

const PATH := "user://postcode_wars_save.json"

func write(state: Dictionary) -> void:
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(state))
		f.close()

func read() -> Dictionary:
	if not FileAccess.file_exists(PATH):
		return {}
	var f := FileAccess.open(PATH, FileAccess.READ)
	var data = JSON.parse_string(f.get_as_text())
	f.close()
	return data if typeof(data) == TYPE_DICTIONARY else {}

func wipe() -> void:
	if FileAccess.file_exists(PATH):
		DirAccess.remove_absolute(PATH)

extends Node
## Telemetry (guide Step 39) — log everything from day one; you can't tune what you
## can't see. Local-only ring buffer persisted to user://; when a backend exists it
## can batch-upload. Never blocks gameplay, never logs personal data.

const MAX := 400
const PATH := "user://pw_telemetry.jsonl"
var _buf: Array = []
var _session_start := 0.0

func _ready() -> void:
	_session_start = Time.get_unix_time_from_system()
	# hook the event bus so most events log themselves
	if Events.has_signal("job_completed"): Events.job_completed.connect(func(_a = null): log_event("job_attempt", {}))
	if Events.has_signal("ambushed"): Events.ambushed.connect(func(a): log_event("ambush_triggered", {"lvl": int(a.get("level", 0))}))
	if Events.has_signal("hospitalised"): Events.hospitalised.connect(func(m): log_event("hospitalised", {"mins": m}))
	if Events.has_signal("level_up"): Events.level_up.connect(func(l = 0): log_event("level_up", {"level": l}))

## Record one event. props is a small flat dict of primitives.
func log_event(event: String, props: Dictionary = {}) -> void:
	var row := {"t": int(Time.get_unix_time_from_system()), "e": event}
	for k in props: row[k] = props[k]
	_buf.append(row)
	if _buf.size() > MAX: _buf = _buf.slice(_buf.size() - MAX)

## Session shape (Step 40 dashboard #1): what state the player opened/left in.
func session_start() -> void:
	var empty := not CollectOverlay.has_any() and Director.current().is_empty()
	log_event("session_start", {
		"collect": CollectOverlay.has_any(),
		"energy": int(Game.energy()),
		"empty": empty,   # session_start_empty > 5% is a bug
	})

func session_end() -> void:
	log_event("session_end", {
		"dur": int(Time.get_unix_time_from_system() - _session_start),
		"bars_hi": _bars_above(0.85),
	})
	flush()

func _bars_above(frac: float) -> int:
	var n := 0
	if Game.energy() >= Game.energy_cap() * frac: n += 1
	if Game.nerve() >= Game.NV_CAP * frac: n += 1
	return n

## Persist the buffer (append-only JSONL). Best-effort; failure is silent.
func flush() -> void:
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f == null: return
	for row in _buf:
		f.store_line(JSON.stringify(row))
	f.close()

func recent(n := 20) -> Array:
	return _buf.slice(max(0, _buf.size() - n))

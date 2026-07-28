class_name MinigameHost
extends Control
## The overlay that runs a minigame over the job card (WO2-T1). Layout, top→bottom:
##   · animated scene backdrop (top third) — the player must see WHERE they are
##   · the minigame's own play area (middle)
##   · one line of vignette copy + a small SKIP button (bottom-right)
## Hard 14s cap: nothing in this game holds the player longer than 14s without a tap;
## if a minigame hasn't finished by then it force-resolves at its current score.
## Emits resolved(score, detail) exactly once; App.run_minigame() awaits it.

signal resolved(score: float, detail: Dictionary)

const CAP_SECONDS := 14.0
const TOP_FRAC := 0.34   # scene backdrop height as a fraction of screen

var _mg: Minigame
var _emitted := false
var _cap: SceneTreeTimer
var _backdrop: Node                        # the scene band; its actor layer reacts
var _score_probe: Callable = Callable()   # optional live-score reader for the cap

func begin(ctx: Dictionary) -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.03, 0.04, 0.65)   # dim the card behind to ~35% visible
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	var vb := VBoxContainer.new()
	vb.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vb.add_theme_constant_override("separation", 0)
	add_child(vb)

	# ---- top third: the animated scene (+ actor layer) ----
	var scene_id: String = String(ctx.get("scene", MinigameRegistry.scene_for(String(ctx.get("job_id", "")))))
	var top := _scene_band(scene_id, String(ctx.get("actor", "")))
	if top.has_method("react"):
		_backdrop = top
	top.custom_minimum_size = Vector2(0, 0)
	top.size_flags_vertical = Control.SIZE_FILL
	top.size_flags_stretch_ratio = TOP_FRAC
	vb.add_child(top)

	# ---- middle: the minigame play area ----
	var mid := PanelContainer.new()
	mid.add_theme_stylebox_override("panel", Pal.sb(Color("#0C0E10", 0.0), 0, Color(0, 0, 0, 0), 0, 0))
	mid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	mid.size_flags_stretch_ratio = 1.0 - TOP_FRAC - 0.14
	mid.clip_contents = true
	vb.add_child(mid)

	_mg = MinigameRegistry.make(String(ctx.get("job_id", "")))
	if _mg == null:
		# no minigame mapped — award the safe result and bail cleanly
		call_deferred("_emit", 0.4, {"skipped": true, "detail": "NO PLAY"})
		return
	_mg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_mg.finished.connect(_on_finished)
	# forward live gameplay events to the scene's actor layer (WO2-T11)
	if _backdrop != null:
		_mg.event.connect(func(n: String):
			if is_instance_valid(_backdrop) and _backdrop.has_method("react"):
				_backdrop.react(n))
	mid.add_child(_mg)

	# ---- bottom: vignette line + SKIP ----
	vb.add_child(_bottom_bar(String(ctx.get("vignette", ""))))

	# hand off after one frame so the minigame is sized before setup()/run()
	_start.call_deferred(ctx)

func _start(ctx: Dictionary) -> void:
	await get_tree().process_frame
	if _mg == null or _emitted:
		return
	_mg.setup(ctx)
	_mg.run()
	_cap = get_tree().create_timer(CAP_SECONDS)
	_cap.timeout.connect(_on_cap)

func _scene_band(scene_id: String, actor_id: String) -> Control:
	# Load the animated backdrop by PATH (no compile-time dep on Task 10's class),
	# and drive it through has_method so build order doesn't matter.
	var path := "res://ui/scene_backdrop.tscn"
	if ResourceLoader.exists(path):
		var ps: PackedScene = load(path)
		if ps != null:
			var inst := ps.instantiate()
			if inst.has_method("bind"):
				inst.call("bind", scene_id, actor_id)
			return inst
	# fallback while scenes aren't built yet: a flat graded band
	var band := PanelContainer.new()
	band.add_theme_stylebox_override("panel", Pal.sb(Color("#12161C"), 0, Pal.RAISED, 0, 0))
	var lbl := Pal.label(scene_id.to_upper().replace("_", " "), 22, Pal.MUTED, 500)
	lbl.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	band.add_child(lbl)
	return band

func _bottom_bar(vignette: String) -> Control:
	var pc := PanelContainer.new()
	pc.custom_minimum_size = Vector2(0, 150)
	pc.size_flags_vertical = Control.SIZE_SHRINK_END
	pc.add_theme_stylebox_override("panel", Pal.sb(Color("#0C0E10", 0.92), 0, Pal.RAISED, 0, 0))
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 34); m.add_theme_constant_override("margin_right", 24)
	m.add_theme_constant_override("margin_top", 20); m.add_theme_constant_override("margin_bottom", 24)
	var row := Pal.hbox(16)
	var line := Pal.text(vignette if vignette != "" else "Eyes open. Do it clean.", 26, Pal.TEXT2, 400, true)
	line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.custom_minimum_size = Vector2(600, 0)
	line.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(line)
	var sk := Pal.btn("SKIP", "off", 72)
	sk.add_theme_font_size_override("font_size", 24)
	sk.custom_minimum_size = Vector2(150, 72)
	sk.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	sk.tooltip_text = "Take the safe result"
	sk.pressed.connect(_on_skip)
	row.add_child(sk)
	m.add_child(row); pc.add_child(m)
	return pc

func _on_skip() -> void:
	Audio.ui()
	Telemetry.log_event("minigame_skip", {"job": _mg.ctx.get("job_id", "") if _mg else ""})
	if _mg != null:
		_mg.skip()   # subclasses route skip → finished(0.4)
	else:
		_emit(0.4, {"skipped": true})

func _on_cap() -> void:
	if _emitted or _mg == null:
		return
	# force-resolve at the current score if the minigame exposes one, else safe 0.4
	var s := 0.4
	if _mg.has_method("current_score"):
		s = float(_mg.call("current_score"))
	_emit(s, {"detail": "TIME", "timed_out": true})

func _on_finished(score: float, detail: Dictionary) -> void:
	if _backdrop != null and is_instance_valid(_backdrop) and _backdrop.has_method("react"):
		_backdrop.react(String(detail.get("result", "gold" if score >= 0.7 else "miss")))
	_emit(score, detail)

func _emit(score: float, detail: Dictionary) -> void:
	if _emitted:
		return
	_emitted = true
	resolved.emit(clampf(score, 0.0, 1.0), detail)
	queue_free()

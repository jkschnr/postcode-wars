class_name ComebackCard
extends Control
## Welcome-back card for a lapsed player (guide Step 35): what accrued while you
## were gone, what you were in the middle of, and — for longer gaps — a catch-up
## boost. Three sentences that stop a returning player bouncing.

var _res: Dictionary
var _on_done: Callable

func setup(res: Dictionary, on_done: Callable) -> void:
	_res = res
	_on_done = on_done

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new(); dim.color = Color(0.02, 0.02, 0.03, 0.9)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)
	var wrap := CenterContainer.new(); wrap.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(wrap)
	var p := PanelContainer.new(); p.custom_minimum_size = Vector2(1000, 0)
	p.add_theme_stylebox_override("panel", Pal.sb(Color(Pal.RAISED, 0.98), 18, Pal.SODIUM, 2, 0))
	var m := MarginContainer.new()
	for s in ["left", "right", "top", "bottom"]: m.add_theme_constant_override("margin_" + s, 40)
	var v := Pal.vbox(16)
	v.add_child(Pal.label("WHILE YOU WERE GONE", 20, Pal.SODIUM, 500))
	var days := int(_res.get("days", 0))
	v.add_child(Pal.heading("%d DAYS OFF THE ROAD" % days, 46, Pal.TEXT))
	v.add_child(Pal.text(Comeback.recap_line(), 26, Pal.TEXT2, 400, true))
	# what was handed back
	var box := Pal.vbox(10)
	box.add_child(_line("BANKED WHILE AWAY", "+%s clean" % Pal.money(int(_res.get("bundle", 0))), Pal.CLEAN))
	if _res.get("catchup", false):
		box.add_child(_line("CATCH-UP", "2× XP for 48 hours", Pal.SODIUM))
	if int(_res.get("tier", 0)) >= 3:
		box.add_child(_line("NEW SEASON", "A fresh board to claim", Pal.HIVIS))
	v.add_child(box)
	var go := Pal.btn("BACK TO IT", "hivis", 100)
	go.pressed.connect(_close)
	v.add_child(go)
	m.add_child(v); p.add_child(m); wrap.add_child(p)
	p.modulate.a = 0.0
	create_tween().tween_property(p, "modulate:a", 1.0, 0.25)
	Audio.cash()

func _line(cap: String, val: String, col: Color) -> Control:
	var p := Pal.inset_panel()
	var m := MarginContainer.new()
	for s in ["left", "right", "top", "bottom"]: m.add_theme_constant_override("margin_" + s, 16)
	var row := Pal.hbox(12)
	var l := Pal.label(cap, 20, Pal.TEXT2, 500); l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(l)
	row.add_child(Pal.heading(val, 28, col))
	m.add_child(row); p.add_child(m)
	return p

func _close() -> void:
	Audio.ui()
	queue_free()
	if _on_done.is_valid(): _on_done.call()

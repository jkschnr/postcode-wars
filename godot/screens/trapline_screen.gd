class_name TraplineScreen
extends Control
## Trapline (design screen 19): supply-chain schematic — 90° elbows, fixed
## spacing, not geography. Stops coloured by health; tap a stop for its panel.

const STOPS := {
	"london": {"name": "LONDON", "pos": Vector2(210, 470), "day": 2400, "health": "clean", "line": "NORTH LINE", "hub": true},
	"luton": {"name": "LUTON", "pos": Vector2(460, 470), "day": 640, "health": "clean", "line": "NORTH LINE"},
	"northampton": {"name": "NORTHAMPTON", "pos": Vector2(710, 470), "day": 210, "health": "slow", "line": "NORTH LINE"},
	"grimsby": {"name": "GRIMSBY", "pos": Vector2(930, 610), "day": 380, "health": "clean", "line": "NORTH LINE"},
	"swindon": {"name": "SWINDON", "pos": Vector2(460, 760), "day": 300, "health": "clean", "line": "WEST LINE"},
	"bristol": {"name": "BRISTOL", "pos": Vector2(710, 760), "day": 0, "health": "heat", "line": "WEST LINE"},
	"margate": {"name": "MARGATE", "pos": Vector2(460, 1020), "day": 250, "health": "clean", "line": "SOUTH LINE"},
	"dover": {"name": "DOVER", "pos": Vector2(710, 1020), "day": 120, "health": "slow", "line": "SOUTH LINE"},
}
const SEGS := [
	["london", "luton", "nerve"], ["luton", "northampton", "dirty"], ["northampton", "grimsby", "dirty"],
	["luton", "swindon", "nerve"], ["swindon", "bristol", "police"],
	["swindon", "margate", "nerve"], ["margate", "dover", "nerve"], ["dover", "bristol", "nerve"],
]
var _sel := "bristol"
var _panel_host: Control

func _health_col(h: String) -> Color:
	match h:
		"slow": return Pal.SODIUM
		"heat": return Pal.DANGER_RED
		_: return Pal.CLEAN

func _line_col(id: String) -> Color:
	match id:
		"nerve": return Pal.NERVE
		"dirty": return Pal.DIRTY
		"police": return Pal.POLICE.lightened(0.2)
	return Pal.MUTED

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var head := Pal.vbox(2)
	head.position = Vector2(24, 16)
	head.add_child(Pal.label("SUPPLY NETWORK · LONDON HUB", 22, Pal.SODIUM, 500))
	head.add_child(Pal.heading("TRAPLINE", 56, Pal.TEXT))
	add_child(head)
	var chips := Pal.hbox(10)
	chips.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	chips.position = Vector2(-380, 40)
	chips.add_child(Pal.chip("£4,180/DAY", Pal.CLEAN, Color(Pal.CLEAN, 0.5)))
	chips.add_child(Pal.chip("1 LINE SICK", Pal.DANGER_RED, Pal.DANGER_RED))
	add_child(chips)

	# lines behind nodes
	var lines := _Lines.new()
	lines.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	lines.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lines.screen = self
	add_child(lines)

	# line labels
	_line_label("NORTH LINE", Vector2(50, 380), Pal.DIRTY)
	_line_label("WEST LINE", Vector2(50, 690), Pal.POLICE.lightened(0.2))
	_line_label("SOUTH LINE", Vector2(50, 950), Pal.NERVE)

	for id in STOPS.keys():
		_make_stop(id)

	# bottom: legend + selected panel + tiles
	var bottom := Pal.vbox(14)
	bottom.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.offset_left = 24; bottom.offset_right = -24; bottom.offset_top = -560; bottom.offset_bottom = -24
	add_child(bottom)
	var lh := Pal.sechead("LINE HEALTH")
	lh.add_child(Pal.label("TAP A STOP", 20, Pal.MUTED, 400))
	bottom.add_child(lh)
	var leg := Pal.hbox(12)
	leg.add_child(_legend("RUNNING CLEAN", Pal.CLEAN))
	leg.add_child(_legend("SLOW · NEEDS A VISIT", Pal.SODIUM))
	leg.add_child(_legend("HEAT · SHUT IT DOWN", Pal.DANGER_RED))
	bottom.add_child(leg)
	_panel_host = Control.new()
	_panel_host.custom_minimum_size = Vector2(0, 180)
	bottom.add_child(_panel_host)
	_build_panel()
	var tiles := Pal.hbox(16)
	tiles.add_child(_tile("STOPS HELD", "8", Pal.TEXT))
	tiles.add_child(_tile("WEEKLY TAKE", "£29.3K", Pal.DIRTY))
	tiles.add_child(_tile("NEED A VISIT", "3", Pal.DANGER_RED))
	bottom.add_child(tiles)
	var take := Game.trapline_take()
	if take > 0:
		var cb := Pal.btn("COLLECT TAKE — %s DIRTY" % Pal.money(take), "hivis", 100)
		cb.pressed.connect(func():
			var got := Game.trapline_collect()
			Audio.cash(); Game.toast.emit("Trapline take: +%s dirty" % Pal.money(got), Pal.DIRTY)
			App.I.show_screen("trapline"))
		bottom.add_child(cb)

func _line_label(t: String, pos: Vector2, col: Color) -> void:
	var l := Pal.label(t, 22, col, 500)
	l.position = pos
	add_child(l)

func _make_stop(id: String) -> void:
	var s: Dictionary = STOPS[id]
	var col := _health_col(s.health)
	var node := Control.new()
	node.position = s.pos
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(56, 56); btn.size = Vector2(56, 56)
	btn.position = Vector2(-28, -28)
	btn.focus_mode = Control.FOCUS_NONE
	btn.add_theme_stylebox_override("normal", Pal.sb(Pal.BASE, 28, col, 4, 0))
	btn.add_theme_stylebox_override("hover", Pal.sb(Pal.BASE, 28, Pal.TEXT, 4, 0))
	btn.add_theme_stylebox_override("pressed", Pal.sb(Pal.BASE, 28, col, 4, 0))
	if s.get("hub", false):
		var dot := ColorRect.new(); dot.color = Pal.SODIUM
		dot.custom_minimum_size = Vector2(18, 18); dot.position = Vector2(19, 19)
		btn.add_child(dot)
	btn.pressed.connect(func(): _sel = id; Audio.ui(); _build_panel())
	node.add_child(btn)
	var lbl := Pal.vbox(0)
	lbl.position = Vector2(-90, 34)
	var nm := Pal.heading(s.name, 24, Pal.TEXT); nm.custom_minimum_size = Vector2(180, 0); nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var day := Pal.label("£%s/day" % Pal._commas(int(s.day)), 18, col, 400); day.custom_minimum_size = Vector2(180, 0); day.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_child(nm); lbl.add_child(day)
	node.add_child(lbl)
	add_child(node)

func _legend(t: String, col: Color) -> Control:
	var p := Pal.panel()
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 16); m.add_theme_constant_override("margin_right", 12)
	m.add_theme_constant_override("margin_top", 14); m.add_theme_constant_override("margin_bottom", 14)
	var h := Pal.hbox(10)
	var dot := ColorRect.new(); dot.color = col; dot.custom_minimum_size = Vector2(16, 16); dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(dot)
	h.add_child(Pal.label(t, 18, Pal.TEXT2, 400))
	m.add_child(h); p.add_child(m)
	return p

func _build_panel() -> void:
	for c in _panel_host.get_children(): c.queue_free()
	var s: Dictionary = STOPS[_sel]
	var col := _health_col(s.health)
	var p := PanelContainer.new()
	p.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	p.add_theme_stylebox_override("panel", Pal.sb(Pal.PANEL, 16, col, 1, 0))
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 20); m.add_theme_constant_override("margin_right", 20)
	m.add_theme_constant_override("margin_top", 16); m.add_theme_constant_override("margin_bottom", 16)
	var row := Pal.hbox(16)
	var tv := Pal.vbox(4); tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tv.add_child(Pal.label("%s · £%s/DAY" % [s.line, Pal._commas(int(s.day))], 20, col, 500))
	tv.add_child(Pal.heading(s.name, 36, Pal.TEXT))
	var msg := "Running clean. Leave it be."
	if s.health == "heat": msg = "Two lifted last week. Shut it or lose the lot."
	elif s.health == "slow": msg = "Takings slipping. Wants a visit."
	tv.add_child(Pal.text(msg, 22, Pal.TEXT2, 400, true))
	row.add_child(tv)
	if s.health == "heat":
		var sd := Pal.btn("SHUT IT DOWN", "danger", 96)
		sd.custom_minimum_size = Vector2(300, 96)
		sd.pressed.connect(func():
			Game.add_heat(-4.0); Audio.ui()
			Game.toast.emit("Shut it down. Heat off that block.", Pal.CLEAN))
		row.add_child(sd)
	m.add_child(row); p.add_child(m)
	_panel_host.add_child(p)

func _tile(cap: String, val: String, col: Color) -> Control:
	var p := Pal.panel()
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 18); m.add_theme_constant_override("margin_right", 18)
	m.add_theme_constant_override("margin_top", 14); m.add_theme_constant_override("margin_bottom", 14)
	var v := Pal.vbox(4)
	v.add_child(Pal.label(cap, 18, Pal.MUTED, 500))
	v.add_child(Pal.heading(val, 40, col))
	m.add_child(v); p.add_child(m)
	return p

func refresh() -> void:
	pass

class _Lines extends Control:
	var screen: TraplineScreen
	func _draw() -> void:
		if screen == null: return
		for seg in TraplineScreen.SEGS:
			var a: Vector2 = TraplineScreen.STOPS[seg[0]].pos
			var b: Vector2 = TraplineScreen.STOPS[seg[1]].pos
			var col: Color = screen._line_col(seg[2])
			if abs(a.x - b.x) < 2 or abs(a.y - b.y) < 2:
				draw_line(a, b, col, 8.0)
			else:
				var corner := Vector2(b.x, a.y)
				draw_line(a, corner, col, 8.0)
				draw_line(corner, b, col, 8.0)

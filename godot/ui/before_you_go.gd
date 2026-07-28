class_name BeforeYouGo
extends Control
## "Before you go" card (guide Step 10). Offers up to four one-tap ways to leave
## something running. "I'M GOOD" is always present and never punished.

const LINES := [
	"Don't leave it all sitting.",
	"You're going out with nothing running. That's just wasting the night.",
	"One thing before you go.",
]

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new(); dim.color = Color(0, 0, 0, 0.82)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	panel.custom_minimum_size = Vector2(860, 0)
	panel.add_theme_stylebox_override("panel", Pal.sb(Color(Pal.RAISED, 0.98), 20, Pal.SODIUM, 1, 0))
	add_child(panel)
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 34); m.add_theme_constant_override("margin_right", 34)
	m.add_theme_constant_override("margin_top", 30); m.add_theme_constant_override("margin_bottom", 30)
	panel.add_child(m)
	var v := Pal.vbox(16)
	v.add_child(Pal.heading("BEFORE YOU GO", 44, Pal.TEXT))
	var idx: int = abs(int(Game.now())) % LINES.size()
	v.add_child(Pal.label(LINES[idx], 20, Pal.TEXT2, 400))
	for row in Threads.rows():
		var b := Pal.btn("", "secondary", 84)
		var bm := MarginContainer.new()
		bm.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		bm.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bm.add_theme_constant_override("margin_left", 18); bm.add_theme_constant_override("margin_right", 18)
		var hr := Pal.hbox(10); hr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var lbl := Pal.label(String(row.label), 22, Pal.TEXT, 500)
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hr.add_child(lbl)
		hr.add_child(Pal.label(String(row.action), 20, Pal.SODIUM, 600))
		bm.add_child(hr); b.add_child(bm)
		var scr := String(row.get("screen", ""))
		b.pressed.connect(func(): _go(scr))
		v.add_child(b)
	var good := Pal.btn("I'M GOOD", "hivis", 96)
	good.pressed.connect(_close)
	v.add_child(good)
	m.add_child(v)
	panel.modulate.a = 0.0
	create_tween().tween_property(panel, "modulate:a", 1.0, 0.18)
	Audio.ui()

func _go(screen: String) -> void:
	Audio.ui()
	queue_free()
	if screen == "": App.I.show_daily()
	else: App.I.show_screen(screen)

func _close() -> void:
	Audio.ui()
	queue_free()

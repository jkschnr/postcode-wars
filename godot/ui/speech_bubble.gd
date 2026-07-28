class_name SpeechBubble
extends HBoxContainer
## A speech bubble that pops in when someone speaks — tail + icon + line.
## Extends HBoxContainer so it sizes to its content inside a VBox layout.

func setup(text: String, accent: Color, icon_glyph := "❝", max_w := 620) -> void:
	add_theme_constant_override("separation", 0)
	# tail (points left, toward the portrait above-left)
	var tail := _Tail.new()
	tail.col = Pal.PANEL
	tail.edge = accent
	tail.custom_minimum_size = Vector2(18, 48)
	tail.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	add_child(tail)
	# bubble
	var bubble := PanelContainer.new()
	bubble.add_theme_stylebox_override("panel", Pal.sb(Pal.PANEL, 16, accent, 2, 16))
	var h := Pal.hbox(12)
	var chip := PanelContainer.new()
	chip.add_theme_stylebox_override("panel", Pal.sb(accent, 8, Color(0, 0, 0, 0), 0, 6))
	chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var ig := Pal.heading(icon_glyph, 26, Pal.TARMAC2)
	ig.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ig.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ig.custom_minimum_size = Vector2(30, 34)
	chip.add_child(ig)
	h.add_child(chip)
	var lbl := Pal.text(text, 24, Pal.INK, 500, true)
	lbl.custom_minimum_size = Vector2(max_w, 0)
	lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(lbl)
	bubble.add_child(h)
	add_child(bubble)

func _ready() -> void:
	pivot_offset = Vector2(40, 40)
	scale = Vector2(0.7, 0.7)
	modulate.a = 0.0
	var tw := create_tween().set_parallel()
	tw.tween_property(self, "modulate:a", 1.0, 0.14)
	tw.tween_property(self, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

class _Tail extends Control:
	var col: Color = Pal.PANEL
	var edge: Color = Pal.SODIUM
	func _draw() -> void:
		var m := size.y * 0.5
		var pts := PackedVector2Array([Vector2(size.x, m - 12), Vector2(0, m), Vector2(size.x, m + 12)])
		draw_colored_polygon(pts, col)
		draw_line(Vector2(size.x, m - 12), Vector2(0, m), edge, 2)
		draw_line(Vector2(0, m), Vector2(size.x, m + 12), edge, 2)

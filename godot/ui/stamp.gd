class_name InkStamp
extends Control
## An ink stamp — rotated, double-bordered, worn. The Papers, Please signature.
## Drawn in code so it never fights layout.

var text := "APPROVED"
var col := Pal.STROBE
var angle := -0.14
var _t := 0.0

func setup(t: String, c: Color, a := -0.14) -> void:
	text = t; col = c; angle = a
	custom_minimum_size = Vector2(320, 118)
	queue_redraw()

func _ready() -> void:
	# a tiny "slam" as it lands
	scale = Vector2(1.35, 1.35)
	modulate.a = 0.0
	pivot_offset = custom_minimum_size * 0.5
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 1.0, 0.12)
	tw.parallel().tween_property(self, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _draw() -> void:
	var c := size * 0.5
	draw_set_transform(c, angle, Vector2.ONE)
	var f := Pal.display_font()
	var fs := 46
	var tw: float = f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var bw: float = tw + 52
	var bh := 66.0
	var cc := Color(col, 0.92)
	var rect := Rect2(-bw / 2, -bh / 2, bw, bh)
	# worn double border (draw sides as segments with tiny gaps)
	_worn_border(rect, cc, 5.0)
	_worn_border(rect.grow(-8.0), cc, 3.0)
	# faint ink fill
	draw_rect(rect.grow(-4.0), Color(col, 0.06), true)
	# text (baseline positioned)
	draw_string(f, Vector2(-tw / 2, fs * 0.36), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, cc)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _worn_border(r: Rect2, cc: Color, w: float) -> void:
	# four sides drawn as short dashes so the ink looks pressed/uneven
	var step := 7.0
	var x := r.position.x
	while x < r.end.x:
		if int(x) % 3 != 0:
			draw_line(Vector2(x, r.position.y), Vector2(min(x + step - 1, r.end.x), r.position.y), cc, w)
			draw_line(Vector2(x, r.end.y), Vector2(min(x + step - 1, r.end.x), r.end.y), cc, w)
		x += step
	var y := r.position.y
	while y < r.end.y:
		if int(y) % 3 != 0:
			draw_line(Vector2(r.position.x, y), Vector2(r.position.x, min(y + step - 1, r.end.y)), cc, w)
			draw_line(Vector2(r.end.x, y), Vector2(r.end.x, min(y + step - 1, r.end.y)), cc, w)
		y += step

class_name ItemView
extends Control
## Draws one ItemArt buffer scaled to fit, crisp pixels — the gear-icon counterpart
## to DollView. Iconic items get a warm glow pool behind them.

var item: Dictionary = {}
var _buf: ItemArt.Buf

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rebuild()

func set_item(it: Dictionary) -> void:
	item = it
	_rebuild()

func _rebuild() -> void:
	_buf = ItemArt.build(item) if not item.is_empty() else null
	queue_redraw()

func _draw() -> void:
	if _buf == null: return
	var n := ItemArt.N
	var cell: float = min(size.x, size.y) / float(n)
	var ox := (size.x - n * cell) / 2.0
	var oy := (size.y - n * cell) / 2.0
	# iconic glow pool
	if str(item.get("r", "")) == "Ic":
		var g := Pal.radial_glow()
		if g != null:
			var gs := n * cell * 1.1
			draw_texture_rect(g, Rect2(ox + (n * cell - gs) / 2.0, oy + (n * cell - gs) / 2.0 - 2, gs, gs), false, Color(0.95, 0.76, 0.31, 0.22))
	for y in range(n):
		var x := 0
		while x < n:
			var col: Color = _buf.at(x, y)
			if col.a <= 0.0:
				x += 1; continue
			var run := 1
			while x + run < n and _buf.at(x + run, y) == col: run += 1
			draw_rect(Rect2(ox + x * cell, oy + y * cell, run * cell + 0.5, cell + 0.5), col)
			x += run

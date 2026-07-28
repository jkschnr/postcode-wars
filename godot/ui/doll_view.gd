class_name DollView
extends Control
## Draws a Doll buffer scaled to fit, cropped to a view (full/bust/head), with an
## idle blink. Chunky pixels, crisp edges — the live paperdoll preview.

var cfg: Dictionary = Doll.DEF.duplicate()
var view := "bust"
var combat := false          # combat mode: posable arms, no idle blink
var _pose := {}
var _buf: Doll.Buf
var _buf_closed: Doll.Buf
var _blink := false
var _t := 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rebuild()
	set_process(not combat)

func set_cfg(c: Dictionary) -> void:
	cfg = c.duplicate()
	_rebuild()

func set_view(v: String) -> void:
	view = v
	queue_redraw()

## Combat mode — draw idle arms and enable set_pose; blink is disabled.
func set_combat(on: bool) -> void:
	combat = on
	if on: _pose = {"arms": true}
	set_process(not on)
	_rebuild()

## Animate a strike/guard: ext 0..1 extends the punching arm; guard raises both.
func set_pose(ext: float, guard: bool) -> void:
	_pose = {"arms": true, "ext": ext, "guard": guard}
	_buf = Doll.build(cfg, false, _pose)
	queue_redraw()

func _rebuild() -> void:
	_buf = Doll.build(cfg, false, _pose)
	if not combat:
		_buf_closed = Doll.build(cfg, true, _pose)
	queue_redraw()

func _process(dt: float) -> void:
	_t += dt
	# blink ~ every 4.6s for ~0.13s
	var phase := fmod(_t, 4.6)
	var b := phase > 4.46
	if b != _blink:
		_blink = b
		queue_redraw()

func _draw() -> void:
	var buf: Doll.Buf = _buf_closed if _blink else _buf
	if buf == null: return
	var v: Array = Doll.VIEWS.get(view, Doll.VIEWS["full"])
	var vx: int = v[0]; var vy: int = v[1]; var vw: int = v[2]; var vh: int = v[3]
	var cell: float = min(size.x / float(vw), size.y / float(vh))
	var ox := (size.x - vw * cell) / 2.0
	var oy := (size.y - vh * cell) / 2.0
	for y in range(vy, vy + vh):
		var x := vx
		while x < vx + vw:
			var col: Color = buf.at(x, y)
			if col.a <= 0.0:
				x += 1; continue
			var n := 1
			while x + n < vx + vw and buf.at(x + n, y) == col: n += 1
			draw_rect(Rect2(ox + (x - vx) * cell, oy + (y - vy) * cell, n * cell + 0.5, cell + 0.5), col)
			x += n

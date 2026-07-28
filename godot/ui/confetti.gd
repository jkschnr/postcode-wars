class_name Confetti
extends Control
## Cheap celebratory confetti — colored bits that burst, tumble and fade.
## Used on crits and level-ups.

var _bits: Array = []
var _t := 0.0
const COLS := [Color("#c79a41"), Color("#7f8a4f"), Color("#9c3a2e"), Color("#b1a63c"), Color("#d2c69c"), Color("#5a7784")]

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func burst(center: Vector2, n := 60) -> void:
	var rng := RandomNumberGenerator.new(); rng.randomize()
	for i in range(n):
		var ang := rng.randf_range(-PI, 0.0)  # upward-ish
		var spd := rng.randf_range(280, 720)
		_bits.append({
			"pos": center + Vector2(rng.randf_range(-20, 20), rng.randf_range(-10, 10)),
			"vel": Vector2(cos(ang), sin(ang)) * spd,
			"col": COLS[rng.randi() % COLS.size()],
			"rot": rng.randf_range(0, TAU), "spin": rng.randf_range(-12, 12),
			"life": rng.randf_range(1.0, 1.8), "sz": rng.randf_range(4, 9),
		})
	queue_redraw()

func _process(dt: float) -> void:
	_t += dt
	for b in _bits:
		b.vel.y += 1400 * dt
		b.vel.x *= 0.99
		b.pos += b.vel * dt
		b.rot += b.spin * dt
		b.life -= dt
	queue_redraw()
	if _t > 2.2:
		queue_free()

func _draw() -> void:
	for b in _bits:
		if b.life <= 0: continue
		draw_set_transform(b.pos, b.rot, Vector2.ONE)
		var a: float = clamp(b.life, 0.0, 1.0)
		draw_rect(Rect2(-b.sz / 2, -b.sz / 3, b.sz, b.sz * 0.66), Color(b.col, a), true)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

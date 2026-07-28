class_name BootScreen
extends Control
## Title screen. Skyline, logo, tap to play.

var _armed := false

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var sky := Skyline.new()
	sky.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(sky)

	var v := Pal.vbox(14)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	var wrap := CenterContainer.new()
	wrap.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(wrap)
	wrap.add_child(v)

	var logo := Pal.heading("ENDS", 180, Pal.INK)
	logo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(logo)
	var strike := ColorRect.new()
	strike.color = Pal.SODIUM
	strike.custom_minimum_size = Vector2(320, 6)
	strike.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(strike)
	var stamp := InkStamp.new()
	v.add_child(stamp)
	stamp.setup("CONFIDENTIAL", Pal.STROBE, -0.1)
	var tag := Pal.text("from wasteman to Top Boy,\none postcode at a time", 26, Pal.CONCRETE, 500)
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(tag)
	v.add_child(Control.new())
	var prompt := Pal.text("TAP TO PLAY", 30, Pal.HIVIS, 800)
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(prompt)
	var tw := create_tween().set_loops()
	tw.tween_property(prompt, "modulate:a", 0.4, 0.6)
	tw.tween_property(prompt, "modulate:a", 1.0, 0.6)

	await get_tree().create_timer(0.3).timeout
	_armed = true

func _gui_input(e: InputEvent) -> void:
	if _armed and ((e is InputEventMouseButton and e.pressed) or (e is InputEventScreenTouch and e.pressed)):
		Audio.ui()
		if Game.s.get("seen_intro", false):
			App.I.show_screen("map")
		else:
			App.I.show_screen("creation")

class Skyline extends Control:
	func _ready() -> void: queue_redraw()
	func _draw() -> void:
		var g := Gradient.new()
		var bg := Rect2(Vector2.ZERO, size)
		draw_rect(bg, Color("#0C0E11"), true)
		# distant sodium haze
		draw_circle(Vector2(size.x * 0.5, size.y * 0.42), size.x * 0.6, Color(Pal.SODIUM, 0.04))
		# building silhouettes along the bottom
		var rng := RandomNumberGenerator.new()
		rng.seed = 7
		var x := -20.0
		var base := size.y * 0.72
		while x < size.x + 20:
			var w := rng.randf_range(60, 130)
			var h := rng.randf_range(size.y * 0.12, size.y * 0.34)
			draw_rect(Rect2(x, base - h, w - 6, h + size.y), Color("#0E1114"), true)
			# lit windows
			var cols := int(w / 24)
			var rows := int(h / 30)
			for cx in range(cols):
				for cy in range(rows):
					if rng.randf() < 0.32:
						var wx := x + 10 + cx * 24
						var wy := base - h + 12 + cy * 30
						draw_rect(Rect2(wx, wy, 6, 9), Color(Pal.SODIUM, rng.randf_range(0.3, 0.8)), true)
			x += w
		# lamp glows near the ground
		for i in range(6):
			var lx := size.x * (0.1 + i * 0.16)
			draw_circle(Vector2(lx, base + 30), 70, Color(Pal.SODIUM, 0.08))

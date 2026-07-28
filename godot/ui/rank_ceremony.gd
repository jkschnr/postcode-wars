class_name RankCeremony
extends Control
## Full-screen rank-up (guide Step 23): rain, a figure under a streetlight, the new
## rank stamped on like a court document, the unlocks beneath. The spine of the game
## is level 1→100 — a rank crossing has to land.

const LINES := {
	"Yout": "People have started using your name instead of pointing.",
	"Roadman": "You're not new any more. That's not entirely a good thing.",
	"Grafter": "Somebody described you to somebody else as reliable.",
	"Older": "Youngers have started standing up when you come in.",
	"Certi": "Nobody asks who you are now. They ask what you want.",
	"Elder": "Men who don't know you have opinions about you.",
	"General": "You've stopped counting in hundreds.",
	"Roadfather": "Your name is a thing that gets said in rooms you're not in.",
	"Top Boy": "There is nobody above you. That's not a reward. That's a position.",
}

var _rank := ""
var _unlock := ""
var _on_done: Callable

func setup(rank: String, unlock := "", on_done := Callable()) -> void:
	_rank = rank; _unlock = unlock; _on_done = on_done

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var bg := ColorRect.new(); bg.color = Color("#06070A")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bg)
	# streetlight cone glow
	var glow := TextureRect.new(); glow.texture = Pal.radial_glow()
	glow.modulate = Color(1.0, 0.78, 0.40, 0.22)
	glow.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	glow.custom_minimum_size = Vector2(900, 900); glow.size = Vector2(900, 900)
	glow.position = Vector2(-450, 40); glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(glow)
	var rain := _Rain.new(); rain.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rain.mouse_filter = Control.MOUSE_FILTER_IGNORE; add_child(rain)
	# a figure under the light — the player's doll, dim
	var frame := Control.new(); frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var dv := DollView.new()
	dv.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dv.offset_left = 340; dv.offset_right = -340; dv.offset_top = 150; dv.offset_bottom = -1170
	dv.view = "full"; dv.modulate = Color(0.7, 0.72, 0.78, 0.85)
	dv.set_cfg(Game.s.get("doll", Doll.DEF)); dv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(dv); add_child(frame)

	var wrap := CenterContainer.new(); wrap.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(wrap)
	var v := Pal.vbox(14); v.alignment = BoxContainer.ALIGNMENT_CENTER
	var lab := Pal.label("YOU'VE COME UP", 22, Pal.SODIUM, 500); lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lab.custom_minimum_size = Vector2(900, 0); v.add_child(lab)
	var title := Pal.heading(_rank.to_upper(), 96, Pal.HIVIS)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; title.custom_minimum_size = Vector2(900, 0)
	title.rotation = deg_to_rad(-3.0); v.add_child(title)
	var line := Pal.text("\"%s\"" % str(LINES.get(_rank, "You're somebody now.")), 26, Pal.TEXT2, 400, true)
	line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; line.custom_minimum_size = Vector2(820, 0); v.add_child(line)
	if _unlock != "":
		v.add_child(Pal.label("UNLOCKED · %s" % _unlock.to_upper(), 20, Pal.SODIUM, 500))
	var cont := Pal.btn("ON THE ROAD", "hivis", 100)
	cont.custom_minimum_size = Vector2(520, 100)
	cont.pressed.connect(_close)
	v.add_child(cont)
	wrap.add_child(v)
	# entrance: stamp the title in
	title.scale = Vector2(1.8, 1.8); title.pivot_offset = Vector2(450, 48); title.modulate.a = 0.0
	var t := create_tween().set_parallel(true)
	t.tween_property(title, "modulate:a", 1.0, 0.25)
	t.tween_property(title, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK)
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.3)
	Audio.cash()

func _close() -> void:
	Audio.ui()
	queue_free()
	if _on_done.is_valid(): _on_done.call()

class _Rain extends Control:
	var t := 0.0
	func _process(d: float) -> void: t += d; queue_redraw()
	func _draw() -> void:
		var rng := RandomNumberGenerator.new(); rng.seed = 5
		for i in range(140):
			var speed := 900.0 + rng.randf() * 700.0
			var x0 := rng.randf() * (size.x + 120.0) - 60.0
			var ln := 24.0 + rng.randf() * 24.0
			var y := fmod(rng.randf() * size.y + t * speed, size.y + 60.0) - 60.0
			draw_line(Vector2(x0, y), Vector2(x0 - 7, y + ln), Color(1, 1, 1, 0.10 + rng.randf() * 0.16), 1.5)

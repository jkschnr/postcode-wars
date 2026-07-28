class_name SceneBackdrop
extends Control
## WO2-T10: a living backdrop behind cards and minigames. A baked plate (art/scenes)
## sits under code-drawn layers so a static camera still breathes: parallax drift,
## a light beat (sodium flicker + a headlight sweep every 8–20s), weather (rain on
## night scenes, drifting mist otherwise), 2–4 silhouettes crossing at different
## speeds, and a wet-ground reflection of the lights above. ≤40 draws, ≤48 particles.

const RAIN := {"street_night": true, "terrace_night": true, "corner_block": true,
	"docks_night": true, "precinct_night": true, "towpath": true}

const LIGHT := {
	"street_night": Color(1.0, 0.66, 0.30), "high_street_day": Color(0.85, 0.86, 0.82),
	"shop_interior": Color(1.0, 0.97, 0.9), "terrace_night": Color(1.0, 0.78, 0.43),
	"corner_block": Color(1.0, 0.82, 0.47), "market": Color(1.0, 0.85, 0.55),
	"lockup_yard": Color(0.9, 0.94, 1.0), "docks_night": Color(1.0, 0.78, 0.47),
	"precinct_night": Color(1.0, 0.4, 0.35), "grow_room": Color(1.0, 0.7, 0.35),
	"towpath": Color(0.8, 0.86, 0.9), "barbershop": Color(1.0, 0.9, 0.7),
}

var _scene := "street_night"
var _actor := ""
var _tex: Texture2D
var _rain := false
var _light := Color(1, 0.66, 0.3)
var _t := 0.0
var _drops: Array = []          # [{x, y, len, spd, a}]
var _figs: Array = []           # [{x, y, spd, w, h, depth}]
var _sweep_next := 6.0
var _sweep_t := -1.0
var _flick := 1.0
var _react_t := 0.0
var _react := Color(0, 0, 0, 0)
# actor layer (WO2-T11): a small figure that plays the beat out — leans in on a good
# hit, spins away / drops on a miss or a bust.
var _actor_state := "idle"
var _actor_t := 0.0
var _actor_face := 1.0            # facing / lean, animated by state
var _rng := RandomNumberGenerator.new()

func bind(scene_id: String, actor := "") -> void:
	_scene = scene_id
	_actor = actor
	_tex = Pal.tex("res://art/scenes/%s.png" % scene_id)
	_rain = RAIN.get(scene_id, false)
	_light = LIGHT.get(scene_id, Color(1, 0.7, 0.4))
	_rng.seed = hash(scene_id)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	resized.connect(_seed_layers)
	_seed_layers()
	set_process(true)

func _ready() -> void:
	if _tex == null:
		bind(_scene, _actor)

func _seed_layers() -> void:
	_drops.clear(); _figs.clear()
	var w: float = max(1.0, size.x)
	var h: float = max(1.0, size.y)
	if _rain:
		for i in range(44):
			_drops.append({"x": _rng.randf() * w, "y": _rng.randf() * h,
				"len": 12.0 + _rng.randf() * 18.0, "spd": 500.0 + _rng.randf() * 500.0,
				"a": 0.06 + _rng.randf() * 0.14})
	else:
		for i in range(6):     # drifting mist puffs
			_drops.append({"x": _rng.randf() * w, "y": h * (0.4 + _rng.randf() * 0.5),
				"len": 60.0 + _rng.randf() * 120.0, "spd": 12.0 + _rng.randf() * 20.0,
				"a": 0.03 + _rng.randf() * 0.05})
	var n := 2 + (_rng.randi() % 3)
	for i in range(n):
		var depth := _rng.randf()
		_figs.append({"x": _rng.randf() * w, "y": h * (0.72 + depth * 0.16),
			"spd": (14.0 + _rng.randf() * 30.0) * (1.0 if _rng.randf() < 0.5 else -1.0),
			"w": 14.0 + depth * 16.0, "h": 44.0 + depth * 36.0, "depth": depth})

## The actor layer (WO2-T11) pings this on a minigame event so the scene reacts:
## the flash + the centre figure plays the beat out.
func react(event: String) -> void:
	match event:
		"gold": _react = Color(_light, 0.24); _actor_state = "score"
		"hit", "grab", "serve": _react = Color(_light, 0.16); _actor_state = "score"
		"miss", "caught", "bust": _react = Color(Pal.DANGER_RED, 0.26); _actor_state = "spot"
		_: _react = Color(_light, 0.12); _actor_state = "score"
	_react_t = 0.4
	_actor_t = 0.6

func _process(delta: float) -> void:
	_t += delta
	# sodium flicker
	_flick = 0.82 + 0.18 * sin(_t * 9.0) * (0.4 + 0.6 * _rng.randf())
	# headlight sweep every 8–20s
	if _sweep_t < 0.0:
		_sweep_next -= delta
		if _sweep_next <= 0.0:
			_sweep_t = 0.0
	else:
		_sweep_t += delta
		if _sweep_t > 1.6:
			_sweep_t = -1.0
			_sweep_next = 8.0 + _rng.randf() * 12.0
	# weather
	var h: float = max(1.0, size.y)
	var w: float = max(1.0, size.x)
	for dp in _drops:
		if _rain:
			dp.y += dp.spd * delta
			if dp.y > h: dp.y = -10.0; dp.x = _rng.randf() * w
		else:
			dp.x += dp.spd * delta
			if dp.x - dp.len > w: dp.x = -dp.len
	# life
	for fg in _figs:
		fg.x += fg.spd * delta
		if fg.x > w + 40.0: fg.x = -40.0
		elif fg.x < -40.0: fg.x = w + 40.0
	if _react_t > 0.0:
		_react_t -= delta; _react.a = clampf(_react_t / 0.4, 0.0, 1.0) * _react.a
	# actor beat: lean in on a score, spin away on a spot; settle back to idle
	if _actor_t > -0.6:
		_actor_t -= delta
		var target := 1.0
		if _actor_t > 0.0:
			target = -1.0 if _actor_state == "spot" else 1.35
		_actor_face = lerp(_actor_face, target, clampf(delta * 7.0, 0.0, 1.0))
	queue_redraw()

func _draw() -> void:
	var w := size.x
	var h := size.y
	# far parallax tint
	draw_rect(Rect2(0, 0, w, h), Color(0.06, 0.07, 0.10))
	# base plate (mid layer) with a small parallax drift
	if _tex != null:
		var drift := Vector2(sin(_t * 0.3) * 4.0, cos(_t * 0.22) * 3.0)
		draw_texture_rect(_tex, Rect2(-6 + drift.x, -6 + drift.y, w + 12, h + 12), false)
	# reflection: mirror the lit upper band into the wet ground, low alpha
	if _tex != null:
		var gy := h * 0.74
		draw_texture_rect_region(_tex, Rect2(0, h, w, -(h - gy)),
			Rect2(0, 0, _tex.get_width(), _tex.get_height() * 0.4), Color(_light, 0.10))
		draw_rect(Rect2(0, gy, w, h - gy), Color(0.02, 0.03, 0.04, 0.35))
	# lamp flicker glow (near light source)
	var glow := Pal.radial_glow()
	draw_texture_rect(glow, Rect2(w * 0.10 - 160, -120, 340, 340), false, Color(_light, 0.22 * _flick))
	# headlight sweep
	if _sweep_t >= 0.0:
		var sx: float = lerp(-0.3, 1.3, _sweep_t / 1.6) * w
		for i in range(6):
			var off: float = (float(i) - 3.0) * 26.0
			var a: float = (1.0 - absf(float(i) - 3.0) / 3.0) * 0.16
			draw_rect(Rect2(sx + off, 0, 20, h), Color(_light, a))
	# weather
	for dp in _drops:
		if _rain:
			draw_line(Vector2(dp.x, dp.y), Vector2(dp.x - 6, dp.y + dp.len), Color(0.8, 0.85, 0.95, dp.a), 1.5)
		else:
			draw_rect(Rect2(dp.x, dp.y, dp.len, 14), Color(0.7, 0.72, 0.75, dp.a))
	# life — silhouettes crossing
	for fg in _figs:
		var col := Color(0.02, 0.02, 0.03, 0.55 + fg.depth * 0.3)
		var bx: float = fg.x
		var by: float = fg.y
		draw_rect(Rect2(bx - fg.w / 2, by - fg.h, fg.w, fg.h), col)          # body
		draw_circle(Vector2(bx, by - fg.h - fg.w * 0.4), fg.w * 0.42, col)   # head
	# actor layer — the figure the beat happens to, centre-stage at ground level
	var ax := w * 0.5
	var ay := h * 0.86
	var lean := (_actor_face - 1.0) * 22.0
	var acol := Color(0.03, 0.03, 0.04, 0.72)
	var aw := 26.0
	var ah := 70.0
	draw_rect(Rect2(ax - aw / 2 + lean, ay - ah, aw, ah), acol)             # body, leaning
	draw_circle(Vector2(ax + lean * 1.3, ay - ah - aw * 0.4), aw * 0.44, acol)  # head, turns away on a spot
	# a little sodium rim on the actor so it reads against the plate
	draw_rect(Rect2(ax - aw / 2 + lean, ay - ah, aw, 3), Color(_light, 0.4 * _flick))
	# bottom vignette so foreground content reads
	draw_rect(Rect2(0, h - 90, w, 90), Color(0.07, 0.08, 0.09, 0.0))
	if _react_t > 0.0 and _react.a > 0.0:
		draw_rect(Rect2(0, 0, w, h), _react)

class_name LoginScreen
extends Control
## Intro (upgrade_03/login.html): a ring-loader boots the manor, then hands over
## to a cinematic wet-night login — procedural skyline, rain, neon POSTCODE WARS
## with a wet reflection, a scrolling ticker, live tiles, and the sign-in form.
## The form is atmospheric (the game is local): GET TO WORK continues, NEW FACE /
## GUEST RUN start fresh.

const SODIUM := Color("#FFA94D")
const WARM := Color("#FFC97A")
const BG := Color("#050608")
const VALE := Color("#B06CF0")

var _loader: Control
var _form: VBoxContainer
var _tagline: Label
var _bar_segs: Array = []
var _pips: Array = []
var _step: Label
var _pct: Label
var _sub: Label
var _t := 0.0
var _loading := true
var _busy := false
var _email_in: LineEdit
var _pass_in: LineEdit
var _err_lbl: Label

const BOOT := [
	["Waking the streets…", "BAKING 13 STREET PLATES"],
	["Counting what's owed…", "RHODES · £12,480 · 6 DAYS"],
	["Rounding up the faces…", "50 ON THE MANOR, 4 INSIDE"],
	["Checking who holds what…", "E8 · 5 OF 8 BLOCKS HELD"],
	["Putting the rain on…", "DOWNPOUR · NIGHT · HEAT 3"],
]
const TAGLINES := [
	"The rain hasn't let up since four.",
	"Thirteen cities. One of them owes you.",
	"Everyone on this road is somebody's problem.",
	"Rhodes is still counting. So are you.",
]

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new(); bg.color = BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	_build_scene()
	_build_form()
	_build_loader()
	set_process(true)
	call_deferred("_run_loader")

# ============================================================ street scene
func _build_scene() -> void:
	# sky: vertical gradient + two colour blooms
	var sky := TextureRect.new()
	sky.texture = _vgrad([Color("#1b1408"), Color("#12131a"), Color("#0a0c11"), Color("#05060a")], [0.0, 0.26, 0.56, 1.0])
	sky.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sky.stretch_mode = TextureRect.STRETCH_SCALE; sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(sky)
	_bloom(Vector2(260, 230), 620, Color(Pal.SODIUM, 0.20))
	_bloom(Vector2(930, 560), 520, Color(VALE, 0.13))

	# skyline (three depth bands) sitting above the ground line (~y 800)
	var sl := _Skyline.new()
	sl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); sl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(sl)

	# streetlamp: post + head + glowing bulb + light cone
	var post := ColorRect.new(); post.color = Color("#20252c")
	post.position = Vector2(946, 360); post.size = Vector2(12, 460)
	post.mouse_filter = Control.MOUSE_FILTER_IGNORE; add_child(post)
	var lamp := _Lamp.new()
	lamp.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); lamp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(lamp)

	# wet ground + reflected glow
	var ground := TextureRect.new()
	ground.texture = _vgrad([Color("#0b0d12"), Color("#080a0e"), Color("#05060a")], [0.0, 0.3, 1.0])
	ground.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	ground.offset_top = -1120; ground.stretch_mode = TextureRect.STRETCH_SCALE
	ground.mouse_filter = Control.MOUSE_FILTER_IGNORE; add_child(ground)
	_bloom(Vector2(820, 820), 560, Color(Pal.SODIUM, 0.26), true)
	_bloom(Vector2(260, 820), 460, Color(VALE, 0.16), true)
	# kerb line
	var kerb := ColorRect.new(); kerb.color = Color(Pal.SODIUM, 0.5)
	kerb.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE); kerb.offset_top = -1120; kerb.offset_bottom = -1118
	kerb.mouse_filter = Control.MOUSE_FILTER_IGNORE; add_child(kerb)

	# rain
	var rain := _Rain.new()
	rain.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); rain.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(rain)

	# scrolling ticker across the road
	_build_ticker()
	# live status tiles
	_build_tiles()
	# title block
	_build_title()

func _bloom(pos: Vector2, r: float, col: Color, additive := true) -> void:
	var t := TextureRect.new()
	t.texture = Pal.radial_glow()
	t.position = pos - Vector2(r, r); t.size = Vector2(r * 2, r * 2)
	t.stretch_mode = TextureRect.STRETCH_SCALE; t.modulate = col
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if additive:
		var m := CanvasItemMaterial.new(); m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		t.material = m
	add_child(t)

func _vgrad(cols: Array, offs: Array) -> GradientTexture2D:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array(offs)
	g.colors = PackedColorArray(cols)
	var tex := GradientTexture2D.new()
	tex.gradient = g; tex.fill_from = Vector2(0, 0); tex.fill_to = Vector2(0, 1)
	tex.width = 8; tex.height = 256
	return tex

func _build_title() -> void:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 0)
	box.position = Vector2(56, 150); box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(box)
	# kicker
	var kick := Pal.hbox(14)
	var dash := ColorRect.new(); dash.color = SODIUM; dash.custom_minimum_size = Vector2(34, 2)
	dash.size_flags_vertical = Control.SIZE_SHRINK_CENTER; kick.add_child(dash)
	kick.add_child(Pal.label("EST. 2026 · THIRTEEN CITIES", 20, SODIUM, 500))
	box.add_child(kick)
	box.add_child(_bigword("Postcode", Pal.TEXT))
	# WARS with a glow behind
	var warswrap := Control.new(); warswrap.custom_minimum_size = Vector2(0, 160); warswrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var glow := TextureRect.new(); glow.texture = Pal.radial_glow()
	glow.position = Vector2(-40, -20); glow.size = Vector2(560, 300); glow.modulate = Color(Pal.SODIUM, 0.35)
	glow.stretch_mode = TextureRect.STRETCH_SCALE; glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var gm := CanvasItemMaterial.new(); gm.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD; glow.material = gm
	warswrap.add_child(glow)
	var wars := _bigword("Wars", WARM); wars.position = Vector2(0, 0)
	warswrap.add_child(wars)
	box.add_child(warswrap)
	# rule
	var rule := ColorRect.new(); rule.color = SODIUM
	rule.custom_minimum_size = Vector2(560, 3); rule.position = Vector2(0, 0)
	var rulewrap := MarginContainer.new(); rulewrap.add_theme_constant_override("margin_top", 40)
	rulewrap.add_child(rule); box.add_child(rulewrap)
	# tagline (typed)
	_tagline = Pal.label("", 26, Pal.TEXT2, 400)
	var tm := MarginContainer.new(); tm.add_theme_constant_override("margin_top", 20); tm.add_child(_tagline)
	box.add_child(tm)

func _bigword(txt: String, col: Color) -> Label:
	var l := Label.new()
	l.text = txt
	l.add_theme_font_override("font", Pal.display_font())
	l.add_theme_font_size_override("font_size", 190)
	l.add_theme_color_override("font_color", col)
	l.add_theme_constant_override("line_spacing", -40)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

func _build_ticker() -> void:
	var strip := Control.new()
	strip.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	strip.offset_top = -1014; strip.offset_bottom = -958; strip.clip_contents = true
	strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bgs := ColorRect.new(); bgs.color = Color("#0a0c11", 0.82)
	bgs.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); bgs.mouse_filter = Control.MOUSE_FILTER_IGNORE
	strip.add_child(bgs)
	var news := [
		[SODIUM, "THE MANOR HOLDS 5 OF 8 BLOCKS IN E8"],
		[VALE, "THE VALE TOOK DALSTON LANE AT 03:12"],
		[Pal.DIRTY, "RHODES: £12,480 OUTSTANDING · 6 DAYS"],
		[Color("#2E5EAA"), "PATROL DENSITY UP 18% ON KINGSLAND ROAD"],
		[Pal.CLEAN, "BUNG SAVINGS CLEARED £3,050 OVERNIGHT"],
		[Pal.DANGER_RED, "TWO ARRESTS ON THE MARSHES · NOT YOURS"],
	]
	var run := Pal.hbox(0); run.mouse_filter = Control.MOUSE_FILTER_IGNORE
	run.set_anchors_and_offsets_preset(Control.PRESET_CENTER_LEFT)
	for pass_i in range(2):
		for item in news:
			var seg := Pal.hbox(14)
			var m := MarginContainer.new(); m.add_theme_constant_override("margin_left", 30); m.add_theme_constant_override("margin_right", 30)
			var dot := ColorRect.new(); dot.color = item[0]; dot.custom_minimum_size = Vector2(8, 8)
			dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			seg.add_child(dot)
			seg.add_child(Pal.label(item[1], 20, item[0], 500))
			m.add_child(seg); run.add_child(m)
	strip.add_child(run)
	add_child(strip)
	_ticker_run = run

var _ticker_run: Control

func _build_tiles() -> void:
	var grid := HBoxContainer.new()
	grid.add_theme_constant_override("separation", 14)
	grid.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	grid.offset_left = 56; grid.offset_right = -56; grid.offset_top = -900; grid.offset_bottom = -800
	grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tiles := [
		["JOBS WAITING", "6", Pal.HIVIS, "THREE PAY IN CASH"],
		["HEAT", "3 / 5", Pal.DANGER_RED, "ONE MORE AND THEY COME"],
		["ON THE ROAD", "8,412", Pal.CLEAN, "NADS IS ONLINE"],
	]
	for tl in tiles:
		var p := PanelContainer.new()
		p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var sb := Pal.sb(Color("#12151a", 0.92), 12, Color("#23272e"), 1, 0)
		sb.border_width_top = 2; sb.border_color = tl[2]
		p.add_theme_stylebox_override("panel", sb)
		var m := MarginContainer.new()
		m.add_theme_constant_override("margin_left", 18); m.add_theme_constant_override("margin_right", 18)
		m.add_theme_constant_override("margin_top", 14); m.add_theme_constant_override("margin_bottom", 14)
		var v := Pal.vbox(4)
		v.add_child(Pal.label(tl[0], 17, Pal.MUTED, 500))
		v.add_child(Pal.heading(tl[1], 40, tl[2]))
		v.add_child(Pal.label(tl[3], 16, Pal.TEXT2, 400))
		m.add_child(v); p.add_child(m); grid.add_child(p)
	add_child(grid)

# ============================================================ form
func _build_form() -> void:
	_form = VBoxContainer.new()
	_form.add_theme_constant_override("separation", 16)
	_form.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_form.offset_left = 56; _form.offset_right = -56; _form.offset_top = -760; _form.offset_bottom = -72
	_form.alignment = BoxContainer.ALIGNMENT_END
	_form.modulate.a = 0.0
	add_child(_form)

	_form.add_child(_field("EMAIL", String(Cloud.email), false, "email"))
	_form.add_child(_field("PASSWORD", "", true, "pass"))
	_err_lbl = Pal.label("", 18, Pal.DANGER_RED, 500)
	_err_lbl.visible = false
	_form.add_child(_err_lbl)

	var rowr := Pal.hbox(0)
	var remember := Pal.hbox(14); remember.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var rbox := PanelContainer.new()
	rbox.add_theme_stylebox_override("panel", Pal.sb(Color(Pal.SODIUM, 0.16), 9, SODIUM, 2, 0))
	rbox.custom_minimum_size = Vector2(34, 34); rbox.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var rin := ColorRect.new(); rin.color = SODIUM; rin.custom_minimum_size = Vector2(14, 14)
	var rc := CenterContainer.new(); rc.add_child(rin); rbox.add_child(rc)
	remember.add_child(rbox)
	remember.add_child(Pal.label("KEEP ME ON THE MANOR", 20, Pal.TEXT2, 500))
	rowr.add_child(remember)
	rowr.add_child(Pal.label("FORGOT?", 20, Pal.MUTED, 500))
	_form.add_child(rowr)

	var cta := Pal.btn("GET TO WORK", "hivis", 124)
	cta.add_theme_font_size_override("font_size", 44)
	cta.pressed.connect(func(): _proceed("continue"))
	_form.add_child(cta)

	var alt := Pal.hbox(14)
	var nf := Pal.btn("NEW FACE", "secondary", 104); nf.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nf.pressed.connect(func(): _proceed("new"))
	var gr := Pal.btn("GUEST RUN", "secondary", 104); gr.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	gr.pressed.connect(func(): _proceed("guest"))
	alt.add_child(nf); alt.add_child(gr)
	_form.add_child(alt)

	var strip := Pal.hbox(12)
	var dotwrap := Control.new(); dotwrap.custom_minimum_size = Vector2(14, 14); dotwrap.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var sdot := ColorRect.new(); sdot.color = Pal.CLEAN; sdot.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dotwrap.add_child(sdot); strip.add_child(dotwrap)
	strip.add_child(Pal.label("LONDON · 34 MS · 8,412 ON THE ROAD", 19, Pal.TEXT2, 500))
	strip.add_child(Pal.spacer())
	strip.add_child(Pal.label("v0.9.4", 19, Pal.MUTED, 500))
	_form.add_child(strip)

func _field(cap: String, val: String, secret: bool, key := "") -> Control:
	var wrap := Control.new(); wrap.custom_minimum_size = Vector2(0, 112)
	var cover := PanelContainer.new()
	cover.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cover.add_theme_stylebox_override("panel", Pal.sb(Color("#0c0e12", 0.82), 14, Pal.RAISED, 1, 0))
	wrap.add_child(cover)
	var lbl := Pal.label(cap, 17, Pal.MUTED, 500)
	lbl.position = Vector2(24, 16); wrap.add_child(lbl)
	var le := LineEdit.new()
	le.text = val; le.secret = secret
	le.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	le.offset_left = 20; le.offset_right = -20; le.offset_top = 40
	le.add_theme_font_override("font", Pal.body_font(500))
	le.add_theme_font_size_override("font_size", 30)
	le.add_theme_color_override("font_color", Pal.TEXT)
	le.add_theme_color_override("caret_color", SODIUM)
	le.add_theme_stylebox_override("normal", Pal.sb(Color(0, 0, 0, 0), 0))
	le.add_theme_stylebox_override("focus", Pal.sb(Color(0, 0, 0, 0), 0))
	wrap.add_child(le)
	var ul := ColorRect.new(); ul.color = SODIUM
	ul.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	ul.offset_left = 14; ul.offset_right = -14; ul.offset_top = -3; ul.scale.x = 0.0
	ul.pivot_offset = Vector2.ZERO
	le.focus_entered.connect(func(): ul.scale.x = 1.0)
	le.focus_exited.connect(func(): ul.scale.x = 0.0)
	wrap.add_child(ul)
	if key == "email": _email_in = le
	elif key == "pass": _pass_in = le
	return wrap

# ============================================================ loader
func _build_loader() -> void:
	_loader = Control.new()
	_loader.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_loader.mouse_filter = Control.MOUSE_FILTER_STOP
	var lbg := TextureRect.new()
	lbg.texture = _vgrad([Color("#16110a"), Color("#0a0b10"), Color("#05060a")], [0.0, 0.52, 1.0])
	lbg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); lbg.stretch_mode = TextureRect.STRETCH_SCALE
	lbg.mouse_filter = Control.MOUSE_FILTER_IGNORE; _loader.add_child(lbg)

	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 0)
	col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	col.offset_left = 90; col.offset_right = -90
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_loader.add_child(col)

	# ring mark + pips + PW core
	var markwrap := CenterContainer.new()
	var mark := Control.new(); mark.custom_minimum_size = Vector2(360, 360)
	var rings := _Rings.new(); rings.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mark.add_child(rings)
	var pipwrap := Control.new(); pipwrap.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); pipwrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for i in range(13):
		var a := (float(i) / 13.0) * TAU - PI / 2.0
		var pip := ColorRect.new(); pip.color = Color("#23272e"); pip.custom_minimum_size = Vector2(12, 12); pip.size = Vector2(12, 12)
		pip.position = Vector2(180 + cos(a) * 169 - 6, 180 + sin(a) * 169 - 6)
		pipwrap.add_child(pip); _pips.append(pip)
	mark.add_child(pipwrap)
	var core := PanelContainer.new()
	core.add_theme_stylebox_override("panel", Pal.sb(Color("#12151a"), 26, SODIUM, 1, 0))
	core.custom_minimum_size = Vector2(150, 150)
	core.set_anchors_and_offsets_preset(Control.PRESET_CENTER); core.offset_left = -75; core.offset_top = -75; core.offset_right = 75; core.offset_bottom = 75
	var cc := CenterContainer.new(); cc.add_child(Pal.heading("PW", 76, WARM)); core.add_child(cc)
	mark.add_child(core)
	markwrap.add_child(mark); col.add_child(markwrap)

	col.add_child(_center(Pal.heading("Postcode Wars", 56, Pal.TEXT)))
	var lm := MarginContainer.new(); lm.add_theme_constant_override("margin_top", 12)
	lm.add_child(_center(Pal.label("LOADING THE MANOR", 19, Pal.MUTED, 500))); col.add_child(lm)

	# progress
	var pm := MarginContainer.new(); pm.add_theme_constant_override("margin_top", 52)
	var pcol := Pal.vbox(14)
	var toprow := Pal.hbox(16)
	_step = Pal.label("Waking the streets…", 21, Pal.TEXT2, 500); _step.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	toprow.add_child(_step)
	_pct = Pal.heading("0%", 38, SODIUM)
	toprow.add_child(_pct)
	pcol.add_child(toprow)
	var bar := Pal.hbox(3)
	for i in range(24):
		var seg := ColorRect.new(); seg.color = Color("#161a20"); seg.custom_minimum_size = Vector2(0, 18)
		seg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bar.add_child(seg); _bar_segs.append(seg)
	pcol.add_child(bar)
	var subrow := Pal.hbox(0)
	_sub = Pal.label("13 CITIES · 50 FACES · 1 DEBT", 17, Pal.MUTED, 500); _sub.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	subrow.add_child(_sub); subrow.add_child(Pal.label("v0.9.4", 17, Color("#3A4046"), 500))
	pcol.add_child(subrow)
	pm.add_child(pcol); col.add_child(pm)
	add_child(_loader)

func _center(c: Control) -> Control:
	var cc := CenterContainer.new(); cc.add_child(c); return cc

func _run_loader() -> void:
	var dur := 3.2
	var el := 0.0
	while el < dur:
		await get_tree().process_frame
		el += get_process_delta_time()
		var p: float = clampf(el / dur, 0.0, 1.0)
		var n := int(round(p * 24))
		for i in range(min(n, _bar_segs.size())):
			_bar_segs[i].color = WARM
		var lit := int(p * 13)
		for i in range(min(lit, _pips.size())):
			_pips[i].color = SODIUM
		_pct.text = "%d%%" % int(p * 100)
		var si: int = clampi(int(p * BOOT.size()), 0, BOOT.size() - 1)
		_step.text = BOOT[si][0]; _sub.text = BOOT[si][1]
	_step.text = "On the road."; _pct.text = "100%"
	await get_tree().create_timer(0.46).timeout
	_loading = false
	# hand over: fade + scale the loader out, reveal the form, start the tagline
	var tw := create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(_loader, "modulate:a", 0.0, 0.6)
	tw.tween_property(_loader, "scale", Vector2(1.06, 1.06), 0.6)
	tw.tween_property(_form, "modulate:a", 1.0, 0.7)
	await tw.finished
	_loader.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_loader.visible = false
	_cycle_tagline()

# ============================================================ tagline typing
var _tag_i := 0
func _cycle_tagline() -> void:
	if not is_inside_tree(): return
	var line: String = TAGLINES[_tag_i]
	for i in range(line.length() + 1):
		if not is_inside_tree(): return
		_tagline.text = line.substr(0, i)
		await get_tree().create_timer(0.034).timeout
	await get_tree().create_timer(2.4).timeout
	while _tagline.text.length() > 0:
		if not is_inside_tree(): return
		_tagline.text = _tagline.text.substr(0, _tagline.text.length() - 1)
		await get_tree().create_timer(0.016).timeout
	_tag_i = (_tag_i + 1) % TAGLINES.size()
	_cycle_tagline()

func _process(dt: float) -> void:
	_t += dt
	# ticker scroll (loops on half-width since content is doubled)
	if _ticker_run:
		var half := _ticker_run.size.x / 2.0
		if half > 0:
			_ticker_run.position.x = -fmod(_t * 26.0, half)

# ============================================================ routing
func _proceed(mode: String) -> void:
	if _busy or _loading: return
	_busy = true
	Audio.ui()

	# GUEST RUN, or no backend configured → local-only, no auth
	if mode == "guest" or not Cloud.configured():
		if mode == "new" or mode == "guest":
			Game.reset()
			App.I.show_screen("creation")
		else:
			_route_existing()
		return

	# cloud path: email/password required
	var mail := _email_in.text.strip_edges()
	var pw := _pass_in.text
	if mail == "" or pw == "":
		return _fail("Enter your email and password.")
	if mode == "new":
		_set_busy("Making your account…")
		var sr: Dictionary = await Cloud.sign_up(mail, pw)
		if not sr.ok:
			return _fail(String(sr.error))
		if sr.get("needs_confirm", false):
			return _fail("Check your email to confirm, then sign in.")
		Game.reset()
		App.I.show_screen("creation")
		return
	# GET TO WORK → sign in, then pull the cloud save
	_set_busy("Checking the road…")
	var r: Dictionary = await Cloud.sign_in(mail, pw)
	if not r.ok:
		return _fail(String(r.error))
	var pull: Dictionary = await Cloud.pull_save()
	if pull.ok and typeof(pull.state) == TYPE_DICTIONARY and not pull.state.is_empty():
		# keep the further-along save — never let a stale cloud row drag you back
		if App.I.progress_score(pull.state) >= App.I.progress_score(Game.s):
			Game.s = pull.state
			Game._migrate()
			Game.persist()
		else:
			Cloud.queue_push()
	App.I.route_existing()

func _route_existing() -> void:
	if Game.s.get("seen_intro", false) and String(Game.s.get("name", "")) != "":
		if Game.in_jail():
			App.I.show_screen("jail")
		elif not Game.s.get("prologue_done", false):
			App.I.show_screen("map"); App.I._refresh_hud(); App.I.start_prologue()
		else:
			App.I.show_screen("map"); App.I._refresh_hud()
			App.I.run_session_open()
	else:
		App.I.show_screen("creation")

func _set_busy(msg: String) -> void:
	if _err_lbl:
		_err_lbl.visible = true
		_err_lbl.add_theme_color_override("font_color", Pal.TEXT2)
		_err_lbl.text = msg

func _fail(msg: String) -> void:
	_busy = false
	if _err_lbl:
		_err_lbl.visible = true
		_err_lbl.add_theme_color_override("font_color", Pal.DANGER_RED)
		_err_lbl.text = msg
	Audio.error()

# ================= inner draw nodes =================
class _Skyline extends Control:
	func _draw() -> void:
		_band(7, 52, 130, 110, 330, 9, Color("#141821"), Color("#0b0e14"), 0.80, 1160.0)
		_band(31, 78, 180, 150, 400, 11, Color("#111520"), Color("#080a10"), 0.66, 1120.0)
		_band(57, 120, 250, 90, 290, 14, Color("#0b0e14"), Color("#05070b"), 0.52, 1080.0)
	func _band(seed: int, wmin: float, wmax: float, hmin: float, hmax: float, gap: float, top: Color, bot: Color, lit: float, base_up: float) -> void:
		var rng := RandomNumberGenerator.new(); rng.seed = seed
		var base := 1920.0 - base_up
		var x := -40.0
		while x < 1080.0 + 60.0:
			var w := wmin + rng.randf() * (wmax - wmin)
			var h := hmin + rng.randf() * (hmax - hmin)
			draw_rect(Rect2(x, base - h, w, h), bot.lerp(top, 0.5))
			draw_rect(Rect2(x, base - h, w, 2), Color(Pal.SODIUM, 0.24))
			var win := wmin * 0.28
			var cols: int = max(1, int(w / (win + 6)))
			var rows: int = max(1, int(h / (win * 2.2)))
			for cy in range(rows):
				for cx in range(cols):
					if rng.randf() > lit: continue
					var warm := rng.randf() > 0.28
					var wc: Color = Color(Pal.SODIUM, 0.3 + rng.randf() * 0.4) if warm else Color(0.66, 0.8, 0.92, 0.24 + rng.randf() * 0.3)
					draw_rect(Rect2(x + 6 + cx * (win + 6), base - h + 10 + cy * win * 2.0, win * 0.5, win), wc)
			x += w + gap

class _Lamp extends Control:
	func _draw() -> void:
		# light cone
		var pts := PackedVector2Array([Vector2(978, 356), Vector2(1006, 356), Vector2(1160, 1040), Vector2(820, 1040)])
		draw_colored_polygon(pts, Color(Pal.SODIUM, 0.10))
		# head
		draw_rect(Rect2(902, 336, 96, 20), Color("#2a3037"))
		# bulb + glow
		draw_rect(Rect2(886, 348, 132, 12), Color("#FFE8BE"))

class _Rain extends Control:
	var t := 0.0
	func _process(d: float) -> void: t += d; queue_redraw()
	func _draw() -> void:
		var rng := RandomNumberGenerator.new(); rng.seed = 5
		for i in range(150):
			var speed := 900.0 + rng.randf() * 700.0
			var x0 := rng.randf() * 1200.0 - 60.0
			var ln := 26.0 + rng.randf() * 26.0
			var y := fmod(rng.randf() * 1920.0 + t * speed, 2020.0) - 60.0
			var a := 0.10 + rng.randf() * 0.22
			draw_line(Vector2(x0, y), Vector2(x0 - 8, y + ln), Color(1, 1, 1, a), 1.5)

class _Rings extends Control:
	var t := 0.0
	func _process(d: float) -> void: t += d; queue_redraw()
	func _draw() -> void:
		var c := size / 2.0
		var r: float = min(size.x, size.y) / 2.0 - 2.0
		draw_arc(c, r, 0, TAU, 64, Color(Pal.SODIUM, 0.28), 2.0, true)
		var a1 := t * 3.9
		draw_arc(c, r - 34, a1, a1 + PI * 0.6, 24, Color(Pal.SODIUM), 3.0, true)
		draw_arc(c, r - 34, a1 + PI, a1 + PI + PI * 0.25, 16, Color("#FFC97A"), 3.0, true)
		var a2 := -t * 1.4
		draw_arc(c, r - 66, a2, a2 + PI * 0.5, 20, Color(Pal.NERVE), 2.0, true)

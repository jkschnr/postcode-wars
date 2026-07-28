class_name RevealOverlay
extends Control
## The payoff ceremony (design screen 05). Scrim · Anton stinger · outcome line ·
## duffel with rarity rim · loot row (cash + item cards, flip-in stagger) · XP bar
## · tap to continue. Cash counts up; glow takes the best rarity in the drop.

var outcome: Dictionary
var on_done: Callable
var _ready_to_close := false

# --- WO2-T12.1: tap-to-skip / fast-forward / long-press-to-skip-forever ---
var _skippable := false            # taps ignored until 1.15s (protects the reveal)
var _revealed := false             # true once anims are finalised
var _tweens: Array = []            # every tween we spawn, so a skip can kill them
var _duffel_ref: Control
var _cards_ref: Array = []
var _cash_label: Label
var _cash_amount := 0
var _pressing := false
var _press_t := 0.0

const RARITY_ORDER := ["basic", "decent", "peng", "certi", "iconic"]

func _tw() -> Tween:
	var t := create_tween()
	_tweens.append(t)
	return t

func setup(o: Dictionary, cb: Callable) -> void:
	outcome = o
	on_done = cb

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.03, 0.04, 0.92)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	# soft rarity glow pool behind the duffel
	var glow := _Glow.new()
	glow.col = _glow_col()
	glow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(glow)
	if outcome.get("success", false):
		_success()
	else:
		_fail()

func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseButton or e is InputEventScreenTouch:
		if e.pressed:
			_pressing = true; _press_t = 0.0
			set_process(true)
		elif _pressing:
			_pressing = false
			if _press_t < 0.5:
				_on_tap()

func _process(delta: float) -> void:
	# long-press (≥0.5s) = skip the ceremony from now on, stored in settings
	if _pressing:
		_press_t += delta
		if _press_t >= 0.5:
			_pressing = false
			Game.s["fast_reveal"] = true
			Game.persist()
			Game.toast.emit("Reveals fast-forwarded. Long-press again anytime to bring them back.", Pal.TEXT2)
			if not _revealed: _fast_forward()
			_close()

func _on_tap() -> void:
	if not _skippable:
		return
	# first tap fast-forwards the anims to their settled state; the next tap closes
	if not _revealed:
		_fast_forward()
		_ready_to_close = true
	elif _ready_to_close:
		_close()

## Kill every running tween and snap the ceremony to its finished frame.
func _fast_forward() -> void:
	for t in _tweens:
		if t is Tween and t.is_valid():
			t.kill()
	if is_instance_valid(_duffel_ref):
		_duffel_ref.scale = Vector2.ONE
		_duffel_ref.modulate.a = 1.0
	for c in _cards_ref:
		if is_instance_valid(c):
			c.scale = Vector2.ONE
			c.modulate.a = 1.0
	if is_instance_valid(_cash_label):
		_cash_label.text = Pal.money(_cash_amount)
	_revealed = true

func _close() -> void:
	queue_free()
	App.I.play_levelups(outcome.get("leveled", []), on_done)

func _best_rarity() -> String:
	var best := "basic"
	match outcome.get("tier", "base"):
		"good": best = "decent"
		"crit": best = "peng"
		"jackpot": best = "certi"
	for it in outcome.get("items", []):
		if RARITY_ORDER.find(it.rarity) > RARITY_ORDER.find(best):
			best = it.rarity
	return best

func _glow_col() -> Color:
	if not outcome.get("success", false): return Color(Pal.DANGER_RED, 0.0)
	return Pal.RARITY.get(_best_rarity(), Pal.SODIUM)

## The minigame result: how you played, as a detail line + a 3-star score. Proof
## to the player that their hands mattered (WO2-T12.1).
func _mg_block() -> Control:
	var score := float(outcome.get("minigame_score", 0.4))
	var det := str(outcome.get("mg_detail", ""))
	var stars := 1
	if score >= 0.75: stars = 3
	elif score >= 0.45: stars = 2
	var row := Pal.hbox(10)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	for i in range(3):
		var lit := i < stars
		var s := Pal.heading("★" if lit else "☆", 34, Pal.DIRTY if lit else Pal.MUTED)
		row.add_child(s)
	if det != "":
		var l := Pal.label("  " + det, 24, Pal.SODIUM, 500)
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.add_child(l)
	return row

func _col() -> VBoxContainer:
	var wrap := MarginContainer.new()
	wrap.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	wrap.add_theme_constant_override("margin_left", 40)
	wrap.add_theme_constant_override("margin_right", 40)
	wrap.add_theme_constant_override("margin_top", 120)
	wrap.add_theme_constant_override("margin_bottom", 80)
	add_child(wrap)
	var v := Pal.vbox(28)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	wrap.add_child(v)
	return v

func _success() -> void:
	var v := _col()
	var rar := _best_rarity()
	var glow: Color = Pal.RARITY.get(rar, Pal.SODIUM)

	# stinger
	var sting := Pal.heading("DONE", 104, Pal.SODIUM)
	sting.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(sting)
	# outcome line (vignette flavour)
	var fl := str(outcome.get("flavor", ""))
	if fl != "":
		var f := Pal.text(fl, 28, Pal.TEXT, 400, true)
		f.custom_minimum_size = Vector2(1000, 0)
		f.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(f)

	# minigame result: 3-star rating + the detail line, above the loot (WO2-T12.1)
	if outcome.has("mg_detail"):
		v.add_child(_mg_block())

	# duffel
	var duffel := _Duffel.new()
	_duffel_ref = duffel
	duffel.rim = glow
	duffel.clip_contents = true
	duffel.custom_minimum_size = Vector2(420, 200)
	duffel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	duffel.pivot_offset = duffel.custom_minimum_size / 2.0
	duffel.scale = Vector2(0.9, 0.9)
	duffel.modulate.a = 0.0
	v.add_child(duffel)
	var tw := _tw().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(duffel, "scale", Vector2(1.01, 1.01), 0.32)
	tw.parallel().tween_property(duffel, "modulate:a", 1.0, 0.22)
	tw.tween_property(duffel, "scale", Vector2.ONE, 0.12)
	Audio.reveal()
	if outcome.get("crit", false) or outcome.get("tier") == "jackpot":
		var cf := Confetti.new(); add_child(cf)
		cf.burst(size * Vector2(0.5, 0.42), 70)
		Audio.crit()

	# loot row
	var row := Pal.hbox(16)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(row)
	var cash_card := _cash_card(int(outcome.get("dirty", 0)))
	row.add_child(cash_card)
	for it in outcome.get("items", []):
		row.add_child(_loot_card(it))
	# flip-in stagger
	var idx := 0
	for card in row.get_children():
		_cards_ref.append(card)
		card.pivot_offset = card.custom_minimum_size / 2.0
		card.scale = Vector2(0.94, 0.0)
		card.modulate.a = 0.0
		var d := 0.45 + idx * 0.09
		var t2 := _tw().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		t2.tween_interval(d)
		t2.parallel().tween_property(card, "scale", Vector2.ONE, 0.26)
		t2.parallel().tween_property(card, "modulate:a", 1.0, 0.20)
		idx += 1

	v.add_child(Pal.vspacer())
	# XP bar block
	v.add_child(_xp_block())
	# tap to continue
	var cont := Pal.label("TAP ANYWHERE TO CONTINUE", 22, Pal.MUTED, 500)
	cont.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(cont)
	var pulse := create_tween().set_loops()
	pulse.tween_property(cont, "modulate:a", 0.4, 0.7)
	pulse.tween_property(cont, "modulate:a", 1.0, 0.7)
	# fast-reveal setting (from a prior long-press) snaps straight to the end
	if bool(Game.s.get("fast_reveal", false)):
		_fast_forward(); _skippable = true; _ready_to_close = true
		return
	# keep the 0.8s anticipation; allow tap-to-skip at 1.15s; full-ready after settle
	get_tree().create_timer(1.15).timeout.connect(func(): _skippable = true)
	await get_tree().create_timer(1.3).timeout
	_revealed = true
	_ready_to_close = true

func _fail() -> void:
	var v := _col()
	var near: bool = outcome.get("near_miss", false)
	var sting := Pal.heading("NEARLY" if near else "BLANK", 128, Pal.DANGER_RED)
	sting.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(sting)
	var fl := str(outcome.get("flavor", ""))
	if fl == "" and near:
		fl = "Feds were seconds out. Walked away with nothing but the graft."
	if fl != "":
		var f := Pal.text(fl, 30, Pal.TEXT, 400, true)
		f.custom_minimum_size = Vector2(1000, 0)
		f.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(f)
	# even a blank job shows how the beat was played (WO2-T12.1)
	if outcome.has("mg_detail"):
		v.add_child(_mg_block())
	Audio.error()
	v.add_child(Pal.vspacer())
	v.add_child(_xp_block())
	var cont := Pal.label("TAP ANYWHERE TO CONTINUE", 22, Pal.MUTED, 500)
	cont.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(cont)
	# fail settles fast, but still protect the anticipation gap before skip is live
	_revealed = true
	if bool(Game.s.get("fast_reveal", false)):
		_skippable = true; _ready_to_close = true
		return
	await get_tree().create_timer(0.8).timeout
	_skippable = true
	_ready_to_close = true

func _cash_card(amount: int) -> Control:
	var p := PanelContainer.new()
	p.custom_minimum_size = Vector2(300, 300)
	p.add_theme_stylebox_override("panel", Pal.sb(Color(Pal.DIRTY, 0.10), 16, Pal.DIRTY, 2, 0))
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 20); m.add_theme_constant_override("margin_right", 20)
	m.add_theme_constant_override("margin_top", 24); m.add_theme_constant_override("margin_bottom", 24)
	var v := Pal.vbox(10)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	var cap := Pal.label("DIRTY CASH", 22, Pal.DIRTY, 500)
	cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(cap)
	var val := Pal.heading("£0", 64, Pal.DIRTY)
	val.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(val)
	_cash_label = val
	_cash_amount = amount
	var sub := Pal.label("STRAIGHT IN THE BAG", 18, Pal.MUTED, 400)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(sub)
	m.add_child(v); p.add_child(m)
	# count up
	var last := [0]
	var ct := _tw()
	ct.tween_interval(0.6)
	ct.tween_method(func(x):
		val.text = Pal.money(int(x))
		var s: int = int(x) / 40
		if s != last[0]: last[0] = s; Audio.cash()
	, 0.0, float(amount), 0.9)
	return p

func _loot_card(it: Dictionary) -> Control:
	var rc: Color = Pal.RARITY.get(it.get("rarity", "basic"), Pal.RARITY.basic)
	var p := PanelContainer.new()
	p.custom_minimum_size = Vector2(300, 300)
	p.add_theme_stylebox_override("panel", Pal.sb(Pal.PANEL, 16, rc, 2, 0))
	p.clip_contents = true
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	# art
	var art := TextureRect.new()
	art.texture = Pal.item_tex(str(it.get("name", "")))
	art.custom_minimum_size = Vector2(0, 200)
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	art.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(art)
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 16); m.add_theme_constant_override("margin_right", 16)
	m.add_theme_constant_override("margin_top", 12); m.add_theme_constant_override("margin_bottom", 14)
	var tv := Pal.vbox(4)
	tv.add_child(Pal.label(str(it.get("rarity", "basic")).to_upper(), 20, rc, 500))
	tv.add_child(Pal.heading(str(it.get("name", "Item")).to_upper(), 26, Pal.TEXT))
	m.add_child(tv)
	v.add_child(m)
	p.add_child(v)
	return p

func _xp_block() -> Control:
	var v := Pal.vbox(10)
	var top := Pal.hbox(10)
	top.add_child(Pal.label("LEVEL %d · %s" % [Game.level(), Game.rank_name().to_upper()], 22, Pal.TEXT2, 500))
	top.add_child(Pal.spacer())
	top.add_child(Pal.heading("+%d XP" % int(outcome.get("xp", 0)), 36, Pal.SODIUM))
	v.add_child(top)
	var b := Pal.bar(Game.xp_progress(), Pal.SODIUM, 16, 24)
	v.add_child(b)
	var bot := Pal.hbox(10)
	bot.add_child(Pal.label("%s / %s XP" % [Pal._commas(int(Game.s.xp_into)), Pal._commas(Game.xp_to_next())], 20, Pal.MUTED, 400))
	bot.add_child(Pal.spacer())
	bot.add_child(Pal.label("NEXT: %s" % _next_rank().to_upper(), 20, Pal.MUTED, 400))
	v.add_child(bot)
	return v

func _next_rank() -> String:
	var lvl := Game.level()
	for r in Config.ranks:
		if int(r.get("level", 1)) > lvl:
			return str(r.get("name", "—"))
	return Game.rank_name()

func _spacer(h: int) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c

# ---- graphics ----
class _Glow extends Control:
	var col := Color.WHITE
	func _draw() -> void:
		if col.a <= 0.0: return
		var c := Vector2(size.x * 0.5, size.y * 0.42)
		for i in range(10):
			var r := 360.0 - i * 30.0
			draw_circle(c, r, Color(col, 0.03))

class _Duffel extends Control:
	var rim := Color("#FFA94D")
	func _ready() -> void: resized.connect(queue_redraw)
	func _draw() -> void:
		var w := size.x; var h := size.y
		var body := Color("#1A1D22")
		var top := h * 0.16
		var r := 30.0
		# rounded-rect bag body
		draw_rect(Rect2(r, top, w - 2 * r, h - top), body)
		draw_rect(Rect2(0, top + r, w, h - top - r), body)
		draw_circle(Vector2(r, top + r), r, body)
		draw_circle(Vector2(w - r, top + r), r, body)
		# two handle nubs peeking over the top
		draw_arc(Vector2(w * 0.40, top + 4), 24, PI, TAU, 20, Color("#0C0E10"), 8.0)
		draw_arc(Vector2(w * 0.60, top + 4), 24, PI, TAU, 20, Color("#0C0E10"), 8.0)
		# rim light along the lit top edge
		draw_line(Vector2(r, top), Vector2(w - r, top), Color(rim, 0.9), 3.0)
		draw_arc(Vector2(r, top + r), r, PI, PI * 1.5, 12, Color(rim, 0.85), 3.0)
		draw_arc(Vector2(w - r, top + r), r, PI * 1.5, TAU, 12, Color(rim, 0.85), 3.0)
		# label
		var f := Pal.mono_font(500)
		var txt := "EVERYTHING YOU TOOK"
		var ts := f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 22)
		draw_string(f, Vector2((w - ts.x) / 2.0, h * 0.82), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Pal.TEXT2)

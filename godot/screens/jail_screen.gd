class_name JailScreen
extends Control
## Jail / hospital (design screen 14). A held-timer screen with agency — wait,
## pay bail, or call the Brief. GREY ONLY — no sodium, no hi-vis. The one screen
## the streetlight doesn't reach.

var _timer_lbl: Label
var _acc := 0.0

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new(); bg.color = Pal.INSET; bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	_build()

func _build() -> void:
	for c in get_children():
		if c is ColorRect: continue
		c.queue_free()
	var wrap := MarginContainer.new()
	wrap.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	wrap.add_theme_constant_override("margin_left", 48); wrap.add_theme_constant_override("margin_right", 48)
	wrap.add_theme_constant_override("margin_top", 140); wrap.add_theme_constant_override("margin_bottom", 80)
	add_child(wrap)
	var v := Pal.vbox(20)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	wrap.add_child(v)

	if not Game.in_jail():
		v.add_child(_c(Pal.heading("BACK ON ROAD", 72, Pal.TEXT)))
		v.add_child(_c(Pal.label("KEEP IT LOWER THIS TIME.", 22, Pal.MUTED, 400)))
		v.add_child(Pal.vspacer())
		var go := Pal.btn("GET OUT THERE", "secondary", 108)
		go.pressed.connect(func(): App.I.show_screen("city"))
		v.add_child(go)
		return

	v.add_child(_c(Pal.label("HELD IN CUSTODY", 24, Pal.POLICE.lightened(0.2), 500)))
	v.add_child(_c(Pal.heading("BANGED UP", 88, Pal.TEXT)))
	v.add_child(_c(Pal.label("TIME REMAINING", 22, Pal.MUTED, 500)))
	_timer_lbl = Pal.heading(Game.fmt_time(Game.jail_left()), 96, Pal.CONCRETE)
	_timer_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_timer_lbl)
	v.add_child(Pal.bar(1.0 - clampf(Game.jail_left() / 180.0, 0.0, 1.0), Pal.CONCRETE, 12))
	v.add_child(_c(Pal.text("Dirty cash was confiscated on arrest. Banked clean money is safe.", 22, Pal.MUTED, 400, true)))
	v.add_child(_cellmate())
	v.add_child(Pal.vspacer())

	var bail := 200 + Game.level() * 30
	var b1 := Pal.btn("PAY BAIL — %s CLEAN" % Pal.money(bail), "secondary", 100)
	b1.pressed.connect(func(): _act("bail"))
	v.add_child(b1)
	var b2 := Pal.btn("CALL THE BRIEF — £400 · CUTS 60%", "secondary", 100)
	b2.pressed.connect(func(): _act("brief"))
	v.add_child(b2)
	var b3 := Pal.btn("DO YOUR BIRD", "off", 100)
	b3.pressed.connect(func(): _act("wait"))
	v.add_child(b3)

const CELLMATES := [
	{"name": "DENZ", "sub": "30s, calm, in for something he won't discuss",
		"line": "You'll be out by tea. I can tell — you've got the face of a man with a solicitor."},
	{"name": "WHISPERS", "sub": "50s, talks constantly, occasionally gold",
		"line": "...never trust a man who irons his tracksuit. Anyway — there's a lock-up in Silvertown nobody's touched since March."},
	{"name": "THE KID", "sub": "19, first time, terrified",
		"line": "Is it always like this? Is it? Sorry. Sorry, I'll shut up."},
]

## The cellmate (guide Step 28) — getting nicked should occasionally be lucky.
## First look at a given sentence rotates a character and rolls a payoff: a lead
## for the feed, or a bit of Prison Issue kit you keep.
func _cellmate() -> Control:
	var idx := int(abs(hash(int(Game.s.get("jail_until", 0))))) % CELLMATES.size()
	var cm: Dictionary = CELLMATES[idx]
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", Pal.sb(Color(Pal.PANEL, 0.9), 14, Pal.NERVE, 1, 0))
	var m := MarginContainer.new()
	for s in ["left", "right", "top", "bottom"]: m.add_theme_constant_override("margin_" + s, 18)
	var v := Pal.vbox(6)
	v.add_child(Pal.label("NEXT BED · %s" % str(cm.sub).to_upper(), 16, Pal.NERVE, 500))
	v.add_child(Pal.heading(str(cm.name), 30, Pal.TEXT))
	v.add_child(Pal.text("\"%s\"" % str(cm.line), 20, Pal.TEXT2, 400, true))
	# one payoff per sentence
	if float(Game.s.get("cellmate_seen", 0)) != float(Game.s.get("jail_until", 0)):
		Game.s["cellmate_seen"] = float(Game.s.get("jail_until", 0))
		var drop := _prison_kit()
		if drop != "":
			Game.own_item(drop)
			v.add_child(Pal.label("HE SLID YOU · %s" % Config.item(drop).get("n", "kit").to_upper(), 16, Pal.CLEAN, 500))
			Game.toast.emit("Cellmate slid you %s" % Config.item(drop).get("n", "kit"), Pal.CLEAN)
		elif idx == 1:
			Feed.post("heard about a lock-up in Silvertown. Might be nothing.")
			v.add_child(Pal.label("A LEAD · IT'S ON YOUR FEED", 16, Pal.SODIUM, 500))
		Game.persist()
	m.add_child(v); p.add_child(m)
	return p

## A random Prison Issue piece (src JAIL), ~45% of the time.
func _prison_kit() -> String:
	if Game.rng.randf() > 0.45: return ""
	var pool: Array = []
	for sl in Config.item_slots():
		for it in sl.get("items", []):
			if str(it.get("src", "")) == "JAIL" and not Game.owns_item(str(it.id)): pool.append(str(it.id))
	return pool[Game.rng.randi() % pool.size()] if pool.size() > 0 else ""

func _c(l: Label) -> Label:
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l

func _act(kind: String) -> void:
	if kind == "wait":
		Game.toast.emit("Doing your bird…", Pal.MUTED); return
	var res: Dictionary = await ServerGateway.jail_action(kind)
	if res.ok:
		Audio.ui()
		if res.get("released", false):
			Game.toast.emit("Bailed out.", Pal.TEXT2); App.I.show_screen("city")
		else:
			Game.toast.emit("The Brief's on it.", Pal.POLICE.lightened(0.2)); _build()
	else:
		Audio.error(); Game.toast.emit(res.get("reason", "Can't"), Pal.DANGER_RED)

func _process(dt: float) -> void:
	_acc += dt
	if _acc > 0.5:
		_acc = 0.0
		if Game.in_jail() and _timer_lbl:
			_timer_lbl.text = Game.fmt_time(Game.jail_left())
		elif not Game.in_jail() and _timer_lbl:
			_build()

func refresh() -> void:
	pass

class_name StoryScene
extends Control
## Plays one story beat as a sequence of cream-paper cards (brief §5): location
## line, speaker portrait, a speech bubble for dialogue, narration, and choice
## buttons. Choices apply data-driven effects (flags/relationships/etc). One card
## can embed a real job (the prologue's first pickpocket) that runs the actual
## resolver + reveal. On the last card it completes the beat and calls back.

var beat_id: String
var _cards: Array = []
var _idx := 0
var on_done: Callable
var _wrap: CenterContainer
var _backdrop: SceneBackdrop
var _cur_scene := ""

func setup(bid: String, cb: Callable) -> void:
	beat_id = bid
	on_done = cb
	_cards = Config.beat(bid).get("cards", [])

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	# WO2: an animated scene sits behind the story cards, driven by each card's scene
	_backdrop = SceneBackdrop.new()
	_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_backdrop.visible = false
	add_child(_backdrop)
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.03, 0.04, 0.66)   # lowered so the scene reads behind the paper
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	_wrap = CenterContainer.new()
	_wrap.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_wrap)
	_show_card()

func _panel() -> VBoxContainer:
	for c in _wrap.get_children(): c.queue_free()
	var p := Pal.paper_panel()
	p.custom_minimum_size = Vector2(840, 0)
	var v := Pal.vbox(16)
	p.add_child(v)
	_wrap.add_child(p)
	p.pivot_offset = Vector2(420, 260)
	p.scale = Vector2(0.96, 0.96)
	create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).tween_property(p, "scale", Vector2.ONE, 0.18)
	return v

func _show_card() -> void:
	if _idx >= _cards.size():
		_finish()
		return
	var card := Config.card(_cards[_idx])
	if card.has("job"):
		_run_job(card)
		return
	_render(card)

## Substitute story tokens ({name} → the name the player chose in creation) so
## the prologue addresses them directly instead of a hard-coded placeholder.
func _sub(s: String) -> String:
	if s.find("{name}") == -1:
		return s
	var nm: String = str(Game.s.get("name", "")).strip_edges()
	if nm == "": nm = "Ash"
	return s.replace("{name}", nm)

func _render(card: Dictionary) -> void:
	# WO2: swap the backdrop to this card's scene (cards without one keep the last)
	var sc := str(card.get("scene", ""))
	if sc != "" and sc != _cur_scene:
		_cur_scene = sc
		_backdrop.bind(sc)
	_backdrop.visible = _cur_scene != ""
	var v := _panel()
	var speaker: String = card.get("speaker", "")
	if str(card.get("location", "")) != "":
		var loc := Pal.ptext(str(card.location).to_upper(), 15, 700, true)
		loc.custom_minimum_size = Vector2(776, 0)
		v.add_child(loc)
		v.add_child(Pal.hsep(Color(Pal.PAPER_INK, 0.35)))
	if speaker != "" and speaker != "narrator":   # "narrator" = scene voice, no portrait
		var head := Pal.hbox(16)
		head.add_child(Pal.portrait_frame(Pal.cast_portrait(Cast.portrait_of(speaker)), 88, Pal.SODIUM))
		var nb := Pal.vbox(2)
		nb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		nb.add_child(Pal.ptext(Cast.name_of(speaker), 30, 700))
		var role: String = Config.character(speaker).get("role", "")
		if role != "":
			nb.add_child(Pal.ptext(role, 15, 400))
		head.add_child(nb)
		v.add_child(head)
	if str(card.get("text", "")) != "":
		var bub := SpeechBubble.new()
		v.add_child(bub)
		bub.setup(_sub(str(card.text)), Pal.SODIUM, "❝", 720)
	if str(card.get("narration", "")) != "":
		var n := Pal.ptext(_sub(str(card.narration)), 22, 400, true)
		n.custom_minimum_size = Vector2(776, 0)
		v.add_child(n)
	v.add_child(Pal.hsep(Color(Pal.PAPER_INK, 0.35)))
	var opts: Array = card.get("options", [])
	if opts.is_empty():
		opts = [{"label": "CONTINUE"}]
	for opt in opts:
		var o: Dictionary = opt
		var b := Pal.paper_button(_sub(str(o.get("label", "CONTINUE"))))
		b.pressed.connect(func(): _choose(o))
		v.add_child(b)

func _choose(opt: Dictionary) -> void:
	Audio.ui()
	_apply(opt.get("effects", {}))
	if str(opt.get("outcome", "")) != "":
		_show_outcome(str(opt.outcome))
	else:
		_advance()

func _show_outcome(line: String) -> void:
	var v := _panel()
	var t := Pal.ptext(_sub(line), 27, 400, true)
	t.custom_minimum_size = Vector2(776, 0)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	var b := Pal.paper_button("CONTINUE")
	b.pressed.connect(func(): Audio.ui(); _advance())
	v.add_child(b)

func _advance() -> void:
	_idx += 1
	_show_card()

func _apply(eff: Dictionary) -> void:
	if eff.is_empty():
		return
	for f in eff.get("flags", []):
		Story.set_flag(str(f))
	var rel: Dictionary = eff.get("rel", {})
	for k in rel.keys():
		Cast.adjust(str(k), int(rel[k]))
	var tr: Dictionary = eff.get("trust", {})
	for k in tr.keys():
		Cast.adjust_trust(str(k), int(tr[k]))
	for id in eff.get("meet", []):
		Cast.meet(str(id))
	var cnt: Dictionary = eff.get("counter", {})
	for k in cnt.keys():
		Story.bump(str(k), int(cnt[k]))
	if eff.has("heat"): Game.add_heat(float(eff.heat))
	if eff.has("dirty"): Game.add_dirty(int(eff.dirty))
	if eff.has("clean"): Game.add_clean(int(eff.clean))
	Game.persist()
	Game.changed.emit()

func _run_job(card: Dictionary) -> void:
	var jd: Dictionary = card.job
	var jid: String = str(jd.get("id", "pickpocket"))
	var vig_id: String = str(jd.get("vignette", ""))
	var vig: Dictionary = {}
	for v in Config.vignettes.get(jid, []):
		if str(v.get("id", "")) == vig_id:
			vig = v
			break
	# make sure the tutorial job can be afforded, then guarantee it lands
	Game.s.energy.v = float(Game.energy_cap()); Game.s.energy.t = Game.now()
	Game.s.nerve.v = float(Game.NV_CAP); Game.s.nerve.t = Game.now()
	var res: Dictionary = await ServerGateway.resolve_job(jid, -1, true)
	res["flavor"] = Vignettes.flavor(vig, res)
	Vignettes.mark_seen(vig_id)
	visible = false
	App.I.show_reveal(res, func(): visible = true; _advance())

func _finish() -> void:
	Story.complete_beat(beat_id)
	var cb := on_done
	queue_free()
	if cb.is_valid():
		cb.call()

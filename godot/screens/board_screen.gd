class_name BoardScreen
extends Control
## The Board (design screen 17) — the one free-placement screen. Pinned lead
## cards on a brick wall; tap two leads to run a red string between them.

const LEADS := [
	{"type": "PERSON", "title": "SILAS RHODES", "text": "Pays in favours. Never in front of a witness.", "pos": Vector2(40, 300)},
	{"type": "PERSON", "title": "DELROY", "text": "Takes German plates only. Somebody supplies him.", "pos": Vector2(390, 280)},
	{"type": "NOTE", "title": "BETFRENZ, DALSTON", "text": "Same three transfers every Friday, 18:40. Always £4,000.", "pos": Vector2(740, 350)},
	{"type": "NOTE", "title": "THE BOW YARD", "text": "Gate code changes monthly. Somebody inside sells it on.", "pos": Vector2(110, 720)},
	{"type": "PERSON", "title": "DC HALLOW", "text": "Knew about the moped before it was reported.", "pos": Vector2(440, 700)},
	{"type": "NOTE", "title": "CUSTODY 4471", "text": "Your record was pulled twice the week before the arrest.", "pos": Vector2(750, 770)},
	{"type": "PERSON", "title": "NADS", "text": "Only person who knew both the yard and the time.", "pos": Vector2(250, 1090)},
	{"type": "NOTE", "title": "BROTHER'S FILE", "text": "Sealed, then unsealed, then sealed again. Same fortnight.", "pos": Vector2(610, 1130)},
]
const CARD := Vector2(300, 250)

var _strings: _Strings
var _sel := -1
var _conns: Array = [[0, 1], [1, 3], [1, 4], [4, 7]]
var _cards: Array = []
var _status: Label

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if Game.s.has("board_conns") and typeof(Game.s.board_conns) == TYPE_ARRAY:
		_conns = (Game.s.board_conns as Array).duplicate(true)
	# brick wall
	var wall := TextureRect.new()
	wall.texture = Pal.tex("res://art/tex/tex-brick.png")
	wall.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	wall.stretch_mode = TextureRect.STRETCH_TILE
	wall.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	wall.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	wall.modulate = Color(0.5, 0.42, 0.34)
	add_child(wall)
	var dark := ColorRect.new(); dark.color = Color(0.05, 0.05, 0.06, 0.5)
	dark.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); add_child(dark)

	var title := Pal.vbox(2)
	title.position = Vector2(24, 16)
	title.add_child(Pal.label("WHAT YOU'VE WORKED OUT SO FAR", 22, Pal.SODIUM, 500))
	title.add_child(Pal.heading("THE BOARD", 56, Pal.TEXT))
	add_child(title)

	# string layer (behind cards, above wall)
	_strings = _Strings.new()
	_strings.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_strings.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_strings.board = self
	add_child(_strings)

	for i in range(LEADS.size()):
		_cards.append(_make_card(i))
	_refresh_strings()

	# bottom bar
	var bar := PanelContainer.new()
	bar.add_theme_stylebox_override("panel", Pal.sb(Color(Pal.RAISED, 0.96), 16, Pal.HAIRLINE, 1, 0))
	bar.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bar.offset_left = 24; bar.offset_right = -24; bar.offset_top = -180; bar.offset_bottom = -24
	add_child(bar)
	var bm := MarginContainer.new()
	bm.add_theme_constant_override("margin_left", 24); bm.add_theme_constant_override("margin_right", 24)
	bm.add_theme_constant_override("margin_top", 20); bm.add_theme_constant_override("margin_bottom", 20)
	bar.add_child(bm)
	var brow := Pal.hbox(16)
	var tc := Pal.vbox(4); tc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tc.add_child(Pal.label("TAP TWO LEADS TO RUN A STRING BETWEEN THEM", 20, Pal.SODIUM, 500))
	_status = Pal.text("Nothing selected. %d strings run so far." % _conns.size(), 24, Pal.TEXT2, 400)
	tc.add_child(_status)
	brow.add_child(tc)
	var clear := Pal.btn("CLEAR", "secondary", 88)
	clear.custom_minimum_size = Vector2(180, 88)
	clear.pressed.connect(_clear)
	brow.add_child(clear)
	bm.add_child(brow)

func card_center(i: int) -> Vector2:
	return LEADS[i].pos + CARD / 2.0

func _make_card(i: int) -> Control:
	var lead: Dictionary = LEADS[i]
	var b := Button.new()
	b.position = lead.pos
	b.custom_minimum_size = CARD
	b.size = CARD
	b.focus_mode = Control.FOCUS_NONE
	b.pivot_offset = CARD / 2.0
	b.rotation_degrees = [-2.0, 1.5, -1.0, 2.0, -1.5, 1.0, -2.0, 1.5][i % 8]
	b.add_theme_stylebox_override("normal", Pal.sb(Color("#1A1D22", 0.96), 6, Pal.RAISED, 1, 0))
	b.add_theme_stylebox_override("hover", Pal.sb(Color("#22262C", 0.98), 6, Pal.SODIUM, 1, 0))
	b.add_theme_stylebox_override("pressed", Pal.sb(Color("#1A1D22", 0.96), 6, Pal.SODIUM, 2, 0))
	var m := MarginContainer.new()
	m.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	m.add_theme_constant_override("margin_left", 18); m.add_theme_constant_override("margin_right", 18)
	m.add_theme_constant_override("margin_top", 20); m.add_theme_constant_override("margin_bottom", 16)
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var v := Pal.vbox(6); v.alignment = BoxContainer.ALIGNMENT_END; v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(Pal.label(lead.type, 18, Pal.SODIUM if lead.type == "PERSON" else Pal.TEXT2, 500))
	v.add_child(Pal.heading(lead.title, 26, Pal.TEXT))
	v.add_child(Pal.text(lead.text, 20, Pal.TEXT2, 400, true))
	m.add_child(v); b.add_child(m)
	# red pin
	var pin := ColorRect.new()
	pin.color = Pal.DANGER_RED
	pin.custom_minimum_size = Vector2(22, 22)
	pin.position = Vector2(CARD.x / 2.0 - 11, -8)
	b.add_child(pin)
	b.pressed.connect(func(): _tap(i))
	add_child(b)
	return b

func _tap(i: int) -> void:
	Audio.ui()
	if _sel == -1:
		_sel = i
		_status.text = "Selected: %s. Tap another lead." % LEADS[i].title
		_highlight()
	elif _sel == i:
		_sel = -1
		_status.text = "Nothing selected. %d strings run so far." % _conns.size()
		_highlight()
	else:
		var pair := [min(_sel, i), max(_sel, i)]
		if not _has_conn(pair):
			_conns.append(pair)
			Game.s.board_conns = _conns; Game.persist()
			Audio.reveal()
		_sel = -1
		_status.text = "Nothing selected. %d strings run so far." % _conns.size()
		_refresh_strings()
		_highlight()

func _has_conn(pair: Array) -> bool:
	for c in _conns:
		if c[0] == pair[0] and c[1] == pair[1]: return true
	return false

func _highlight() -> void:
	for i in range(_cards.size()):
		var sel := i == _sel
		var b: Button = _cards[i]
		b.add_theme_stylebox_override("normal", Pal.sb(Color("#1A1D22", 0.96), 6, Pal.SODIUM if sel else Pal.RAISED, 2 if sel else 1, 0))

func _refresh_strings() -> void:
	_strings.conns = _conns
	_strings.queue_redraw()

func _clear() -> void:
	Audio.ui()
	_conns = []
	_sel = -1
	Game.s.board_conns = _conns; Game.persist()
	_status.text = "Nothing selected. 0 strings run so far."
	_refresh_strings(); _highlight()

func refresh() -> void:
	pass

class _Strings extends Control:
	var board: BoardScreen
	var conns: Array = []
	func _draw() -> void:
		if board == null: return
		for c in conns:
			var a := board.card_center(c[0])
			var b := board.card_center(c[1])
			draw_line(a, b, Color(Pal.DANGER_RED, 0.85), 3.0, true)

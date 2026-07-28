class_name LeaderboardsScreen
extends Control
## Standings (design screen 21): weekly/seasonal, level/money/territory, a ranked
## list, and the player's own row ALWAYS pinned at the foot — even at rank 4,000.

const BOARD := [
	{"name": "NUNN", "firm": "HOLLOW NINE", "lvl": 41},
	{"name": "RIDA", "firm": "THE LATIMER", "lvl": 39},
	{"name": "BEX", "firm": "REDCROSS", "lvl": 38},
	{"name": "TRELL", "firm": "NINEFOLD", "lvl": 37},
	{"name": "COOP", "firm": "ASHEN ROW", "lvl": 36},
	{"name": "MENSA", "firm": "HOLLOW NINE", "lvl": 35},
	{"name": "SKEPZ", "firm": "THE LATIMER", "lvl": 34},
	{"name": "DOLA", "firm": "REDCROSS", "lvl": 33},
	{"name": "VESH", "firm": "NINEFOLD", "lvl": 32},
	{"name": "AKS", "firm": "ASHEN ROW", "lvl": 31},
]
var _period := "WEEKLY"
var _metric := "LEVEL"
var _root: VBoxContainer

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root = Pal.vbox(16)
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_root)
	_build()

func _build() -> void:
	for c in _root.get_children(): c.queue_free()
	var hrow := Pal.hbox(10)
	var hc := Pal.vbox(2)
	hc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hc.add_child(Pal.label("WHO'S EATING, WHO ISN'T", 22, Pal.SODIUM, 500))
	hc.add_child(Pal.heading("STANDINGS", 56, Pal.TEXT))
	hrow.add_child(hc)
	var rc := Pal.vbox(2); rc.alignment = BoxContainer.ALIGNMENT_END
	rc.add_child(Pal.label("THIS WEEK", 18, Pal.MUTED, 400))
	rc.add_child(Pal.label("RESETS SUNDAY 00:00", 18, Pal.MUTED, 400))
	hrow.add_child(rc)
	_root.add_child(hrow)
	# period tabs
	var pt := Pal.hbox(16)
	pt.add_child(_tab("WEEKLY", _period == "WEEKLY", func(): _period = "WEEKLY"; _build()))
	pt.add_child(_tab("SEASONAL", _period == "SEASONAL", func(): _period = "SEASONAL"; _build()))
	_root.add_child(pt)
	# metric sub-tabs
	var mt := Pal.hbox(12)
	for m in ["LEVEL", "MONEY", "TERRITORY"]:
		mt.add_child(_subtab(m))
	_root.add_child(mt)
	# list
	var scroll := Pal.scroll()
	_root.add_child(scroll)
	var list := Pal.vbox(10)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	var i := 1
	for e in BOARD:
		list.add_child(_row(i, e.name, e.firm, e.lvl, false))
		i += 1
	# pinned player row
	_root.add_child(_row(37, String(Game.s.get("name", "You")).to_upper(), "HOLLOW NINE", Game.level(), true))

func _tab(label: String, on: bool, cb: Callable) -> Button:
	var b := Pal.btn(label, "hivis" if on else "secondary", 96)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if not on: b.add_theme_color_override("font_color", Pal.TEXT)
	b.pressed.connect(func(): Audio.ui(); cb.call())
	return b

func _subtab(m: String) -> Button:
	var on := _metric == m
	var b := Button.new()
	b.custom_minimum_size = Vector2(0, 84)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_override("font", Pal.mono_font(500))
	b.add_theme_font_size_override("font_size", 22)
	b.add_theme_color_override("font_color", Pal.SODIUM if on else Pal.TEXT2)
	b.add_theme_color_override("font_hover_color", Pal.SODIUM if on else Pal.TEXT2)
	b.add_theme_color_override("font_pressed_color", Pal.SODIUM if on else Pal.TEXT2)
	var bc := Pal.SODIUM if on else Pal.RAISED
	b.add_theme_stylebox_override("normal", Pal.sb(Color(Pal.SODIUM, 0.06) if on else Pal.INSET, 12, bc, 1, 0))
	b.add_theme_stylebox_override("hover", Pal.sb(Pal.INSET, 12, Pal.SODIUM, 1, 0))
	b.add_theme_stylebox_override("pressed", Pal.sb(Pal.INSET, 12, bc, 1, 0))
	b.text = m
	b.pressed.connect(func(): _metric = m; Audio.ui(); _build())
	return b

func _row(rank: int, name: String, firm: String, lvl: int, you: bool) -> Control:
	var p := PanelContainer.new()
	var bc := Pal.SODIUM if you else Pal.RAISED
	var bg := Color(Pal.SODIUM, 0.08) if you else Pal.PANEL
	p.add_theme_stylebox_override("panel", Pal.sb(bg, 16, bc, 2 if you else 1, 0))
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 20); m.add_theme_constant_override("margin_right", 20)
	m.add_theme_constant_override("margin_top", 14); m.add_theme_constant_override("margin_bottom", 14)
	var row := Pal.hbox(16)
	row.add_child(Pal.heading("%02d" % rank, 30, Pal.SODIUM if you else Pal.MUTED))
	row.add_child(Pal.portrait_slot(Pal.cast_portrait("nads") if you else null, 76, "family" if you else "neutral"))
	var tv := Pal.vbox(2)
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tv.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var nrow := Pal.hbox(8)
	nrow.add_child(Pal.heading(name, 30, Pal.TEXT))
	if you: nrow.add_child(Pal.label("YOU", 18, Pal.SODIUM, 500))
	tv.add_child(nrow)
	tv.add_child(Pal.label(firm, 18, Pal.TEXT2, 400))
	row.add_child(tv)
	var metric_txt := "LVL %d" % lvl
	if _metric == "MONEY": metric_txt = Pal.money(lvl * 4200)
	elif _metric == "TERRITORY": metric_txt = "%d BLK" % (lvl / 3)
	row.add_child(Pal.heading(metric_txt, 30, Pal.DIRTY))
	m.add_child(row); p.add_child(m)
	return p

func refresh() -> void:
	pass

class_name FeedScreen
extends Control
## Flexta (guide Step 36): a feed of other players' wins + your own, and the
## leaderboard folded from the same shadow pool. Aspiration you can see.

var _tab := "feed"
var _tabrow: HBoxContainer
var _host: VBoxContainer

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var root := Pal.vbox(0); root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	var head := PanelContainer.new()
	head.add_theme_stylebox_override("panel", Pal.sb(Color("#15181C"), 0, Pal.RAISED, 1, 0))
	var hm := MarginContainer.new()
	hm.add_theme_constant_override("margin_left", 28); hm.add_theme_constant_override("margin_right", 28)
	hm.add_theme_constant_override("margin_top", 18); hm.add_theme_constant_override("margin_bottom", 14)
	var hv := Pal.vbox(12)
	var titlerow := Pal.hbox(12)
	var back := Pal.btn("←", "secondary", 52); back.custom_minimum_size = Vector2(64, 52)
	back.pressed.connect(func(): App.I.show_screen("city"))
	titlerow.add_child(back)
	titlerow.add_child(Pal.heading("FLEXTA", 36, Pal.SODIUM))
	var sp := Control.new(); sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL; titlerow.add_child(sp)
	titlerow.add_child(Pal.label("THE ROAD, ONLINE", 16, Pal.MUTED, 500))
	hv.add_child(titlerow)
	_tabrow = Pal.hbox(8); hv.add_child(_tabrow)
	hm.add_child(hv); head.add_child(hm); root.add_child(head)
	var scroll := Pal.scroll(); scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_host = Pal.vbox(12); _host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_host); root.add_child(scroll)
	_build_tabs(); _rebuild()

func _build_tabs() -> void:
	for c in _tabrow.get_children(): c.queue_free()
	for pair in [["feed", "THE FEED"], ["board", "LEADERBOARD"]]:
		var k: String = pair[0]
		var b := Pal.btn(str(pair[1]), "hivis" if _tab == k else "secondary", 56)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL; b.add_theme_font_size_override("font_size", 20)
		b.pressed.connect(func(): _tab = k; _build_tabs(); _rebuild())
		_tabrow.add_child(b)

func _rebuild() -> void:
	for c in _host.get_children(): c.queue_free()
	if _tab == "feed":
		for post in Feed.items(): _host.add_child(_post_card(post))
	else:
		_host.add_child(Pal.label("RANKED BY POWER · THE MANOR", 18, Pal.SODIUM, 500))
		var rows := Feed.leaderboard()
		for i in range(min(rows.size(), 30)):
			_host.add_child(_board_row(i + 1, rows[i]))

# ---------- feed ----------
func _post_card(post: Dictionary) -> Control:
	var mine: bool = post.get("mine", false)
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", Pal.sb(Color(Pal.SODIUM, 0.08) if mine else Color(Pal.PANEL, 0.9), 12, Pal.SODIUM if mine else Pal.RAISED, 1, 0))
	var m := MarginContainer.new()
	for s in ["left", "right", "top", "bottom"]: m.add_theme_constant_override("margin_" + s, 16)
	var v := Pal.vbox(10)
	var top := Pal.hbox(12)
	top.add_child(_portrait(post.get("doll", Doll.DEF), 64))
	var who := Pal.vbox(2); who.size_flags_horizontal = Control.SIZE_EXPAND_FILL; who.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	who.add_child(Pal.heading(str(post.who), 24, Pal.SODIUM if mine else Pal.TEXT))
	who.add_child(Pal.text(str(post.line), 20, Pal.TEXT2, 400, true))
	top.add_child(who)
	v.add_child(top)
	var reacts := Pal.hbox(10)
	var rc: Dictionary = post.get("react", {"fire": 0, "hundred": 0, "rat": 0})
	for r in [["fire", "🔥"], ["hundred", "💯"], ["rat", "🐀"]]:
		var key: String = r[0]
		var chip := Pal.btn("%s %d" % [r[1], int(rc.get(key, 0))], "secondary", 52)
		chip.custom_minimum_size = Vector2(120, 52); chip.add_theme_font_size_override("font_size", 20)
		if not mine:
			chip.pressed.connect(func(): _react(post, key, chip))
		reacts.add_child(chip)
	v.add_child(reacts)
	m.add_child(v); p.add_child(m)
	return p

func _react(post: Dictionary, key: String, chip: Button) -> void:
	var rc: Dictionary = post.get("react", {})
	rc[key] = int(rc.get(key, 0)) + 1
	post["react"] = rc
	chip.text = "%s %d" % [chip.text.substr(0, chip.text.find(" ")), int(rc[key])]
	# a trickle of respect, capped per day so it can't be farmed
	if int(Game.s.get("feed_reacts_today", 0)) < 20:
		Game.s["feed_reacts_today"] = int(Game.s.get("feed_reacts_today", 0)) + 1
		Game.s["respect"] = int(Game.s.get("respect", 0)) + 1
		Game.persist()
	Audio.ui()

# ---------- leaderboard ----------
func _board_row(rank: int, row: Dictionary) -> Control:
	var mine: bool = row.get("mine", false)
	var p := PanelContainer.new()
	var edge: Color = Pal.SODIUM if mine else (Pal.DIRTY if rank <= 3 else Pal.RAISED)
	p.add_theme_stylebox_override("panel", Pal.sb(Color(Pal.SODIUM, 0.1) if mine else Color(Pal.PANEL, 0.85), 10, edge, 1, 0))
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 16); m.add_theme_constant_override("margin_right", 18)
	m.add_theme_constant_override("margin_top", 10); m.add_theme_constant_override("margin_bottom", 10)
	var row2 := Pal.hbox(14)
	var rnk := Pal.heading("#%d" % rank, 30, Pal.DIRTY if rank <= 3 else Pal.MUTED); rnk.custom_minimum_size = Vector2(76, 0)
	row2.add_child(rnk)
	row2.add_child(_portrait(row.get("doll", Doll.DEF), 60))
	var who := Pal.vbox(2); who.size_flags_horizontal = Control.SIZE_EXPAND_FILL; who.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	who.add_child(Pal.heading(str(row.get("display_name", "YOU")) + ("  (you)" if mine else ""), 26, Pal.SODIUM if mine else Pal.TEXT))
	who.add_child(Pal.label("LVL %d · %s" % [int(row.get("level", 1)), str(row.get("specialisation", "")).to_upper()], 16, Pal.TEXT2, 500))
	row2.add_child(who)
	var pw := Pal.vbox(0); pw.alignment = BoxContainer.ALIGNMENT_CENTER
	pw.add_child(Pal.heading(str(int(row.get("power", 0))), 30, Pal.HIVIS if mine else Pal.TEXT))
	pw.add_child(Pal.label("POWER", 13, Pal.MUTED, 500))
	row2.add_child(pw)
	m.add_child(row2); p.add_child(m)
	return p

func _portrait(cfg: Dictionary, px: int) -> Control:
	var frame := PanelContainer.new(); frame.custom_minimum_size = Vector2(px, px)
	frame.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	frame.add_theme_stylebox_override("panel", Pal.sb(Color("#0C0E10"), 8, Pal.HAIRLINE, 1, 0)); frame.clip_contents = true
	var dv := DollView.new(); dv.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dv.view = "bust"; dv.set_cfg(cfg)
	frame.add_child(dv)
	return frame

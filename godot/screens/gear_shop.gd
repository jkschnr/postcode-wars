class_name GearShop
extends Control
## The shop (upgrade_05/shop.html): two vendors — Bossman's (SHOP-B) and Delroy's
## back room (SHOP-D) — each stocking the catalogue items sourced from them.
## Category tabs, item rows with derived stats/price/level gate, and a BUY that
## spends your street cash, gates on level, and drops the item in your bag.

const SC := {"strength": Color("#C2503F"), "speed": Color("#4DA3FF"), "toughness": Color("#D9E021"),
	"slickness": Color("#B06CF0"), "luck": Color("#6FCF6F")}
const VENDORS := [
	{"k": "SHOP-B", "n": "Bossman's", "line": "Open till late. Cash only, obviously."},
	{"k": "SHOP-D", "n": "Delroy's back room", "line": "\"Bring it back. I mean it.\""},
]

var _vend := "SHOP-B"
var _cat := "all"
var _vend_row: HBoxContainer
var _cat_row: HBoxContainer
var _list_host: VBoxContainer
var _cash_lbl: Label

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var root := Pal.vbox(0); root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	# header
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
	var tcol := Pal.vbox(2); tcol.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tcol.add_child(Pal.label("SHOPPING", 16, Pal.MUTED, 500))
	tcol.add_child(Pal.heading("BOSSMAN'S", 34, Pal.TEXT)); _title = tcol.get_child(1)
	titlerow.add_child(tcol)
	var money := Pal.vbox(2); money.alignment = BoxContainer.ALIGNMENT_END
	money.add_child(Pal.label("ON YOU", 15, Pal.MUTED, 500))
	_cash_lbl = Pal.heading(Pal.money(Game.dirty()), 32, Pal.DIRTY); money.add_child(_cash_lbl)
	money.add_child(Pal.label("LEVEL %d" % Game.level(), 16, Pal.SODIUM, 500))
	titlerow.add_child(money)
	hv.add_child(titlerow)
	_vend_row = Pal.hbox(10); hv.add_child(_vend_row)
	var catscroll := ScrollContainer.new()
	catscroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	catscroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	catscroll.custom_minimum_size = Vector2(0, 58)
	_cat_row = Pal.hbox(8); catscroll.add_child(_cat_row); hv.add_child(catscroll)
	hm.add_child(hv); head.add_child(hm); root.add_child(head)
	# body
	var scroll := Pal.scroll(); scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_list_host = Pal.vbox(12); _list_host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_list_host); root.add_child(scroll)
	_build_vendors(); _rebuild()

var _title: Label

func _stock(v: String) -> Array:
	var out: Array = []
	for slot in Config.item_slots():
		for it in slot.get("items", []):
			if str(it.get("src", "")) == v: out.append(it)
	return out

func _build_vendors() -> void:
	for c in _vend_row.get_children(): c.queue_free()
	for vd in VENDORS:
		var k := str(vd.k)
		var on := _vend == k
		var b := Button.new(); b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(0, 80); b.focus_mode = Control.FOCUS_NONE
		b.add_theme_stylebox_override("normal", Pal.sb(Color(Pal.SODIUM, 0.1) if on else Color("#15181C"), 10, Pal.SODIUM if on else Pal.RAISED, 1, 0))
		var mm := MarginContainer.new(); mm.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); mm.mouse_filter = Control.MOUSE_FILTER_IGNORE
		mm.add_theme_constant_override("margin_left", 16); mm.add_theme_constant_override("margin_top", 10)
		var cv := Pal.vbox(2); cv.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cv.add_child(Pal.heading(str(vd.n), 24, Pal.SODIUM if on else Pal.TEXT))
		cv.add_child(Pal.label("%d LINES IN STOCK" % _stock(k).size(), 15, Pal.MUTED, 500))
		mm.add_child(cv); b.add_child(mm)
		b.pressed.connect(func(): _vend = k; _cat = "all"; _build_vendors(); _rebuild())
		_vend_row.add_child(b)

func _build_cats() -> void:
	for c in _cat_row.get_children(): c.queue_free()
	var st := _stock(_vend)
	var counts := {}
	for x in st: counts[x.slot] = int(counts.get(x.slot, 0)) + 1
	_cat_row.add_child(_cat_btn("EVERYTHING", "all", st.size()))
	for slot in Config.item_slots():
		var k := str(slot.k)
		if counts.has(k): _cat_row.add_child(_cat_btn(str(slot.label), k, int(counts[k])))

func _cat_btn(label: String, key: String, n: int) -> Button:
	var on := _cat == key
	var b := Pal.btn("%s  %d" % [label, n], "hivis" if on else "secondary", 52)
	b.custom_minimum_size = Vector2(0, 52); b.add_theme_font_size_override("font_size", 18)
	b.pressed.connect(func(): _cat = key; _rebuild())
	return b

func _rebuild() -> void:
	if is_instance_valid(_title): _title.text = str(VENDORS[0].n if _vend == "SHOP-B" else VENDORS[1].n).to_upper()
	_cash_lbl.text = Pal.money(Game.dirty())
	_build_cats()
	for c in _list_host.get_children(): c.queue_free()
	var list: Array = []
	for it in _stock(_vend):
		if _cat == "all" or str(it.get("slot", "")) == _cat: list.append(it)
	var vline := str(VENDORS[0].line if _vend == "SHOP-B" else VENDORS[1].line)
	_list_host.add_child(Pal.label("%d FOR SALE · %s" % [list.size(), vline], 18, Pal.SODIUM, 500))
	for it in list:
		_list_host.add_child(_row(it))

func _row(it: Dictionary) -> Control:
	var e := Econ.of(it)
	var col: Color = ItemArt.RC.get(it.get("r", "Ba"), Pal.TEXT)
	var owned: bool = Game.owns_item(str(it.id)) and str(it.get("slot", "")) != "cons"
	var locked: bool = Game.level() < int(e.lvl)
	var broke: bool = Game.dirty() < int(e.cash)
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", Pal.sb(Color("#15181C", 0.6 if locked else 1.0), 10, Color("#3E5A3C") if owned else Pal.RAISED, 1, 0))
	var m := MarginContainer.new()
	for s in ["left", "right", "top", "bottom"]: m.add_theme_constant_override("margin_" + s, 14)
	var row := Pal.hbox(16)
	# well
	var well := PanelContainer.new(); well.custom_minimum_size = Vector2(120, 120); well.clip_contents = true
	well.add_theme_stylebox_override("panel", Pal.sb(Color("#101317"), 6, Color(col, 0.5), 1, 0))
	var iv := ItemView.new(); iv.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var im := MarginContainer.new(); im.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); im.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for s in ["left", "right", "top", "bottom"]: im.add_theme_constant_override("margin_" + s, 9)
	im.add_child(iv); well.add_child(im); iv.set_item(it)
	row.add_child(well)
	# middle: name + stats
	var mid := Pal.vbox(6); mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var tagrow := Pal.hbox(10)
	tagrow.add_child(Pal.label(str(Config.items.get("rarity", {}).get(it.get("r", "Ba"), "BASIC")), 15, col, 500))
	tagrow.add_child(Pal.label(_slot_label(str(it.get("slot", ""))), 15, Pal.MUTED, 500))
	if it.has("set"): tagrow.add_child(Pal.label(str(it.set), 15, Color(_set_col(str(it.set))), 500))
	mid.add_child(tagrow)
	mid.add_child(Pal.heading(str(it.n), 26, Pal.TEXT))
	if e.stats.size() > 0:
		for srow in e.stats:
			mid.add_child(_stat_pip(srow))
	else:
		mid.add_child(Pal.label(str(it.get("st", "")), 17, Pal.TEXT2, 500))
	if it.has("tr"):
		mid.add_child(Pal.label("TRADE-OFF · %s" % str(it.tr).to_upper(), 15, Pal.DANGER_RED, 500))
	row.add_child(mid)
	# right: level, price, buy
	var right := Pal.vbox(8); right.alignment = BoxContainer.ALIGNMENT_CENTER
	right.add_child(Pal.label("LVL %d" % int(e.lvl), 16, Pal.DANGER_RED if locked else Pal.MUTED, 500))
	right.add_child(Pal.heading(Pal.money(int(e.cash)) if int(e.cash) > 0 else "—", 30, Pal.DANGER_RED if (broke and not owned) else Pal.TEXT))
	var stackable := str(it.get("slot", "")) == "cons"
	var can_buy: bool = not (owned and not stackable) and not locked and not broke
	var label := "OWNED" if (owned and not stackable) else ("LOCKED" if locked else ("SHORT" if broke else "BUY"))
	var buy := Pal.btn(label, "hivis" if can_buy else "secondary", 62)
	buy.custom_minimum_size = Vector2(160, 62); buy.disabled = not can_buy
	buy.pressed.connect(func(): _buy(it))
	right.add_child(buy)
	row.add_child(right)
	m.add_child(row); p.add_child(m)
	return p

func _stat_pip(srow: Dictionary) -> Control:
	var row := Pal.hbox(8)
	var key: String = Econ.STAT_KEY[srow.k]
	var dot := ColorRect.new(); dot.color = SC.get(key, Pal.TEXT); dot.custom_minimum_size = Vector2(8, 8)
	dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER; row.add_child(dot)
	var l := Pal.label(str(srow.label), 15, Pal.TEXT2, 500); l.custom_minimum_size = Vector2(96, 0)
	row.add_child(l)
	var bar := _mini_bar(clampf(float(srow.v) / 20.0, 0.05, 1.0), SC.get(key, Pal.TEXT))
	row.add_child(bar)
	row.add_child(Pal.label("+%d" % int(srow.v), 16, Pal.TEXT, 500))
	return row

func _mini_bar(frac: float, col: Color) -> Control:
	var track := PanelContainer.new(); track.custom_minimum_size = Vector2(90, 6)
	track.add_theme_stylebox_override("panel", Pal.sb(Color("#22262A"), 3, Color(0, 0, 0, 0), 0, 0)); track.clip_contents = true
	var fill := ColorRect.new(); fill.color = col
	fill.set_anchors_and_offsets_preset(Control.PRESET_LEFT_WIDE); fill.anchor_right = clampf(frac, 0.0, 1.0); fill.offset_right = 0
	track.add_child(fill)
	return track

func _buy(it: Dictionary) -> void:
	var e := Econ.of(it)
	var stackable := str(it.get("slot", "")) == "cons"
	if Game.level() < int(e.lvl) or Game.dirty() < int(e.cash): Audio.error(); return
	if Game.owns_item(str(it.id)) and not stackable: return
	Game.add_dirty(-int(e.cash))
	if stackable:
		if not Game.s.has("consumables") or typeof(Game.s.consumables) != TYPE_DICTIONARY: Game.s.consumables = {}
		Game.s.consumables[str(it.id)] = int(Game.s.consumables.get(str(it.id), 0)) + 1
	else:
		Game.own_item(str(it.id))
	Game.persist(); Game.changed.emit()
	Audio.cash()
	Game.toast.emit("%s — bought · %s left" % [str(it.n), Pal.money(Game.dirty())], Pal.CLEAN)
	_rebuild()

func _slot_label(k: String) -> String:
	for s in Config.item_slots():
		if s.k == k: return str(s.label)
	return k.to_upper()

func _set_col(name: String) -> String:
	for st in Config.items.get("sets", []):
		if st.n == name: return str(st.c)
	return "#FFA94D"

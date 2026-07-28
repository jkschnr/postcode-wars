class_name Pal
extends RefCounted
## Visual language — the "Postcode Wars" design system (handoff stage one).
## Wet British night: near-black surfaces, sodium-orange brand, one hi-vis CTA,
## dirty-gold vs clean-green money. Anton (display) / Inter (body) / IBM Plex Mono
## (labels). 1080×1920 portrait. Static so any screen can call Pal.xxx.
## Old constant names are kept as aliases so legacy screens keep compiling while
## they're reskinned.

# ---- surfaces ----
const BASE := Color("#121417")        # app background
const PANEL := Color("#1E2126")       # cards, panels
const RAISED := Color("#2A2E33")      # headers, borders, dividers
const INSET := Color("#0C0E10")       # wells, inputs, list backgrounds
const HAIRLINE := Color("#3A3F45")    # lit border on raised chrome

# ---- text ----
const TEXT := Color("#EDEFF2")        # headlines, values
const TEXT2 := Color("#9AA0A6")       # body, descriptions
const MUTED := Color("#5A6068")       # labels, captions, meta
const INVERSE := Color("#121417")     # on hi-vis buttons only

# ---- accent & signal ----
const SODIUM := Color("#FFA94D")      # the brand — streetlight orange
const GLOW := Color("#FFC97A")        # highlights, lit edges, glow cores
const HIVIS := Color("#D9E021")       # ONE CTA per screen
const DANGER_RED := Color("#D63B3B")  # heat, danger, loss, war room
const POLICE := Color("#2E5EAA")      # arrest, police presence
const DIRTY := Color("#C9A227")       # gold — seizable cash
const CLEAN := Color("#57C785")       # green — safe cash
const NERVE := Color("#B06CF0")       # NV bar / nerve checks

# ---- back-compat aliases (legacy screens) ----
const TARMAC := BASE
const TARMAC2 := INSET
const PANEL2 := RAISED
const PAPER := Color("#1E2126")
const PAPER2 := Color("#2A2E33")
const PAPER_INK := Color("#EDEFF2")
const CONCRETE := Color("#9AA0A6")
const CONCRETE_HI := Color("#EDEFF2")
const SODIUM_GLOW := GLOW
const STROBE := DANGER_RED
const MONEY := CLEAN
const INK := TEXT
const INK_DIM := TEXT2
const LINE := Color("#2A2E3388")

const RARITY := {
	"basic": Color("#B9C0C7"), "decent": Color("#6FCF6F"), "peng": Color("#4DA3FF"),
	"certi": Color("#B06CF0"), "iconic": Color("#F2C14E"),
}
# Danger pips are red in this system (1→5 intensifying)
const DANGER := [Color("#8a5a3a"), Color("#b0563a"), Color("#c94d3a"), Color("#d63b3b"), Color("#ff4d4d")]

# faction ring colours for portrait slots
const FACTION := {
	"ledger": Color("#C9A227"), "law": Color("#2E5EAA"), "road": Color("#FFA94D"),
	"rival": Color("#D63B3B"), "family": Color("#57C785"), "neutral": Color("#9AA0A6"),
}

# ------------------------------------------------------------------ fonts
static var _fcache := {}
static func _font(path: String) -> FontFile:
	if not _fcache.has(path):
		_fcache[path] = load(path) if ResourceLoader.exists(path) else null
	return _fcache[path]

## Anton — display / headlines / values / buttons (uppercase).
static func display_font() -> Font:
	return _font("res://fonts/Anton-Regular.ttf")

## Inter — body / descriptions / dialogue. Variable weight via FontVariation.
static func body_font(weight := 400) -> Font:
	var base := _font("res://fonts/Inter-Regular.ttf")
	if base == null: return ThemeDB.fallback_font
	if weight <= 400: return base
	var key := "inter_%d" % weight
	if not _fcache.has(key):
		var fv := FontVariation.new()
		fv.base_font = base
		fv.variation_opentype = {"wght": weight}
		_fcache[key] = fv
	return _fcache[key]

## IBM Plex Mono — labels, codes, timestamps (uppercase, tracked).
static func mono_font(weight := 400) -> Font:
	var f := _font("res://fonts/IBMPlexMono-Medium.ttf") if weight >= 500 else _font("res://fonts/IBMPlexMono-Regular.ttf")
	return f if f != null else ThemeDB.fallback_font

# ------------------------------------------------------------------ money
static func _commas(a: int) -> String:
	var s := str(a); var out := ""; var c := 0
	for i in range(s.length() - 1, -1, -1):
		out = s[i] + out; c += 1
		if c % 3 == 0 and i > 0: out = "," + out
	return out

## Exact to £9,999; £10,000+ abbreviates (£24.5k, £1.2m).
static func money(n: int) -> String:
	var neg := n < 0
	var a: int = abs(n)
	var s: String
	if a < 10000:
		s = _commas(a)
	elif a < 1000000:
		s = ("%.1f" % (a / 1000.0)).trim_suffix(".0") + "k"
	else:
		s = ("%.1f" % (a / 1000000.0)).trim_suffix(".0") + "m"
	return ("-£" if neg else "£") + s

# ------------------------------------------------------------------ styleboxes
static func sb(bg: Color, radius := 16, border := Color(0, 0, 0, 0), bw := 0, pad := 16) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_corner_radius_all(radius)
	if bw > 0:
		s.border_color = border
		s.set_border_width_all(bw)
	s.set_content_margin_all(pad)
	return s

# ------------------------------------------------------------------ text
## Display headline (Anton). Legacy name `heading`.
static func heading(t: String, size := 48, col := TEXT) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_font_override("font", display_font())
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.autowrap_mode = TextServer.AUTOWRAP_OFF
	return l

## Body text (Inter). Legacy name `text`.
static func text(t: String, size := 30, col := TEXT, weight := 400, wrap := false) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_font_override("font", body_font(weight))
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if wrap else TextServer.AUTOWRAP_OFF
	return l

## Mono label / caption (IBM Plex Mono, uppercase feel). Use for tags, codes,
## timestamps, section captions.
static func label(t: String, size := 22, col := TEXT2, weight := 400) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_font_override("font", mono_font(weight))
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.autowrap_mode = TextServer.AUTOWRAP_OFF
	return l

# legacy: paper document text → now on-brand body text
static func ptext(t: String, size := 26, weight := 400, wrap := false) -> Label:
	return text(t, size, TEXT2 if weight < 600 else TEXT, weight, wrap)

# ------------------------------------------------------------------ containers
static func vbox(sep := 16) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", sep)
	return v

static func hbox(sep := 12) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", sep)
	return h

static func spacer() -> Control:
	var c := Control.new()
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c

static func vspacer() -> Control:
	var c := Control.new()
	c.size_flags_vertical = Control.SIZE_EXPAND_FILL
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c

static func hsep(col := LINE) -> Control:
	var r := ColorRect.new()
	r.color = col
	r.custom_minimum_size = Vector2(0, 1)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r

static func scroll() -> ScrollContainer:
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return sc

## A section header: mono caption + hairline rule (design .sechead).
static func sechead(caption: String) -> HBoxContainer:
	var h := hbox(16)
	h.add_child(label(caption, 22, MUTED, 500))
	var rule := ColorRect.new()
	rule.color = RAISED
	rule.custom_minimum_size = Vector2(0, 1)
	rule.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rule.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(rule)
	return h

# ------------------------------------------------------------------ components
## Panel — 16px corners, 1px #2A2E33 border, tinted per use.
static func panel(accent := Color(0, 0, 0, 0), bg := PANEL) -> PanelContainer:
	var p := PanelContainer.new()
	var border := RAISED if accent.a == 0.0 else accent
	p.add_theme_stylebox_override("panel", sb(bg, 16, border, 1, 0))
	return p

static func inset_panel() -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", sb(INSET, 16, RAISED, 1, 0))
	return p

# legacy paper panel → dark panel
static func paper_panel() -> PanelContainer:
	return panel()

## Button — Anton uppercase, ≥96px. tint: "hivis" (primary), "secondary",
## "danger", "off". Legacy signature `button(label,color,filled,height)` maps:
## filled→primary hivis, else secondary tinted with `color`.
static func btn(txt: String, tint := "secondary", height := 96) -> Button:
	var b := Button.new()
	b.text = txt
	b.custom_minimum_size = Vector2(0, height)
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.add_theme_font_override("font", display_font())
	b.add_theme_font_size_override("font_size", 36)
	var fg := TEXT
	var bg := RAISED
	var bcol := HAIRLINE
	var bw := 1
	match tint:
		"hivis": bg = HIVIS; fg = INVERSE; bw = 0
		"danger": bg = Color(DANGER_RED, 0.14); fg = DANGER_RED; bcol = DANGER_RED
		"off": bg = Color("#191B1F"); fg = MUTED; bcol = RAISED
		_: bg = RAISED; fg = TEXT; bcol = HAIRLINE
	b.add_theme_color_override("font_color", fg)
	b.add_theme_color_override("font_hover_color", fg)
	b.add_theme_color_override("font_pressed_color", fg)
	b.add_theme_color_override("font_disabled_color", Color(MUTED, 0.6))
	var normal := sb(bg, 16, bcol, bw, 12)
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", sb(bg.lightened(0.06), 16, bcol, bw, 12))
	b.add_theme_stylebox_override("pressed", sb(bg.darkened(0.06), 16, bcol, bw, 12))
	b.add_theme_stylebox_override("disabled", sb(Color("#191B1F"), 16, RAISED, 1, 12))
	return b

# legacy: button(label, color, filled, height)
static func button(txt: String, color := SODIUM, filled := false, height := 120) -> Button:
	var b := btn(txt, "hivis" if filled else "secondary", max(96, height))
	if not filled:
		b.add_theme_color_override("font_color", color)
		b.add_theme_color_override("font_hover_color", color)
		b.add_theme_color_override("font_pressed_color", color)
	return b

static func paper_button(txt: String, height := 96) -> Button:
	return btn(txt, "secondary", height)

## Chip — cost / tag / consequence. 8px radius, mono label.
static func chip(txt: String, col := TEXT2, accent := RAISED) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", sb(INSET, 10, accent, 1, 10))
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	p.add_child(label(txt, 22, col, 400))
	return p

## Bar — track + fill. `chunks`>0 draws chunked (XP never sweeps smooth).
static func bar(value: float, col := SODIUM, height := 12, chunks := 0) -> Control:
	var track := PanelContainer.new()
	track.custom_minimum_size = Vector2(0, height)
	track.add_theme_stylebox_override("panel", sb(INSET, height / 2, Color(0, 0, 0, 0), 0, 0))
	track.clip_contents = true
	var fillbar := _BarFill.new()
	fillbar.value = clampf(value, 0.0, 1.0)
	fillbar.col = col
	fillbar.chunks = chunks
	fillbar.radius = height / 2.0
	track.add_child(fillbar)
	return track

class _BarFill extends Control:
	var value := 0.0
	var col := Color.WHITE
	var chunks := 0
	var radius := 6.0
	func _ready() -> void: resized.connect(queue_redraw)
	func _draw() -> void:
		var w := size.x * value
		if chunks <= 0:
			draw_rect(Rect2(0, 0, w, size.y), col)
		else:
			var gap := 3.0
			var cw := (size.x - gap * (chunks - 1)) / float(chunks)
			var filled := int(round(value * chunks))
			for i in range(filled):
				draw_rect(Rect2(i * (cw + gap), 0, cw, size.y), col)

## Pip — single tinted square, for heat / danger / rarity.
static func pip(on: bool, col := DANGER_RED, sz := 14) -> ColorRect:
	var r := ColorRect.new()
	r.custom_minimum_size = Vector2(sz, sz)
	r.color = col if on else HAIRLINE
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r

static func pips(count: int, total: int, col := DANGER_RED, sz := 14, gap := 6) -> HBoxContainer:
	var h := hbox(gap)
	for i in range(total):
		h.add_child(pip(i < count, col, sz))
	return h

## Stat row — label, value, bar, delta.
static func stat_row(name: String, value: int, cap: int, delta := 0) -> PanelContainer:
	var p := panel()
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 20); m.add_theme_constant_override("margin_right", 20)
	m.add_theme_constant_override("margin_top", 14); m.add_theme_constant_override("margin_bottom", 14)
	var v := vbox(8)
	var top := hbox(10)
	top.add_child(label(name.to_upper(), 22, TEXT2, 500))
	top.add_child(spacer())
	top.add_child(heading(str(value), 32, TEXT if value < cap else RARITY.iconic))
	if delta != 0:
		top.add_child(label(("+%d" % delta) if delta > 0 else str(delta), 22, CLEAN if delta > 0 else DANGER_RED, 500))
	v.add_child(top)
	v.add_child(bar(float(value) / float(max(1, cap)), SODIUM if value < cap else RARITY.iconic, 10))
	m.add_child(v)
	p.add_child(m)
	return p

# ------------------------------------------------------------------ assets
static var _texcache := {}
static func tex(path: String) -> Texture2D:
	if not _texcache.has(path):
		_texcache[path] = load(path) if ResourceLoader.exists(path) else null
	return _texcache[path]

const PORTRAIT_COUNT := 16
static func portrait_tex(idx: int) -> Texture2D:
	# legacy generic slots retired; fall back to a cast portrait by index
	var ids := ["nads", "tobes", "maz", "pearl", "ranj", "nev", "bev", "kadeem", "marlon", "wesley", "jerome", "delroy", "shauna", "hallow", "silas", "uncle_t"]
	return cast_portrait(ids[((idx % 16) + 16) % 16])

static func portrait_for(name: String) -> Texture2D:
	return cast_portrait(name.to_lower())

## Cast portrait: prefer the design's real pixel art (art/cast/px-<id>.png), then
## fall back to a procedurally-generated one (art/portraits/cast/<id>.png) for
## story-only characters the handoff didn't ship (e.g. kayo).
static func cast_portrait(id: String) -> Texture2D:
	var t := tex("res://art/cast/px-%s.png" % id)
	if t != null:
		return t
	return tex("res://art/portraits/cast/%s.png" % id)

## Character environment plate behind a portrait.
const CAST_PLATE := {
	"uncle_t": "barber", "silas": "office", "nads": "flats", "delroy": "yard",
	"shauna": "office", "tobes": "flats", "hallow": "carpark", "maz": "yard",
	"pearl": "kitchen", "ranj": "yard", "nev": "office", "bev": "yard",
	"kadeem": "carpark", "marlon": "flats", "wesley": "office", "jerome": "flats",
}
static func plate_for(id: String) -> Texture2D:
	return tex("res://art/plates/plate-%s.png" % CAST_PLATE.get(id, "flats"))

## Item art by loose name match → art/items/item-<code>.png
const ITEM_CODES := {
	"phone": "phone", "handset": "phone", "burner": "phone", "airpods": "phone",
	"watch": "trainers", "trainers": "trainers", "jerry": "jerry", "fuel": "jerry",
	"cutter": "cutters", "bolt": "cutters", "hi-vis": "hivis", "hivis": "hivis",
	"clipboard": "hivis", "plate": "plates", "reader": "reader", "card": "reader",
	"jammer": "jammer", "signal": "jammer", "van": "van", "transit": "van",
	"key": "keys", "safe": "keys", "codes": "codes", "till": "codes",
	"ledger": "ledger", "book": "ledger", "cassette": "codes", "wallet": "reader",
	"designer": "trainers", "batch": "plates", "gear": "van", "crate": "van",
}
static func item_code(name: String) -> String:
	var n := name.to_lower()
	for k in ITEM_CODES.keys():
		if n.find(k) >= 0:
			return ITEM_CODES[k]
	return "phone"
static func item_tex(name: String) -> Texture2D:
	return tex("res://art/items/item-%s.png" % item_code(name))

## Upgrade-01/02 loaders: faction colours + npc/sign/vehicle/badge art.
static func faction_col(f: String) -> Color:
	var hex: String = Config.factions.get(f, {}).get("ring", "#4DA3FF")
	return Color(hex)
static func faction_label(f: String) -> String:
	return Config.factions.get(f, {}).get("label", f.to_upper())
static func npc_portrait(id: String) -> Texture2D:
	return tex("res://art/npc/npc-%s.png" % id)
static func sign_tex(id: String) -> Texture2D:
	return tex("res://art/signs/sign-%s.png" % id)
static func veh_tex(id: String) -> Texture2D:
	return tex("res://art/veh/veh-%s.png" % id)
static func badge_tex(id: String) -> Texture2D:
	return tex("res://art/badges/badge-%s.png" % id)

static func city_tex(id: String) -> Texture2D:
	return tex("res://art/cities/%s.png" % id)
static func gear_tex(id: String) -> Texture2D:
	return tex("res://art/gear/%s.png" % id)

## Rectangular portrait in a tinted frame (dossier / choice card).
static func portrait_frame(t: Texture2D, size: int, border := SODIUM) -> Control:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", sb(INSET, 12, border, 2, 3))
	var tr := TextureRect.new()
	tr.texture = t
	tr.custom_minimum_size = Vector2(size, size * 1.25)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE  # size from container, not texture
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	p.custom_minimum_size = Vector2(size, size * 1.25)
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	p.add_child(tr)
	return p

## Circular portrait slot with a faction ring (roster / toast).
static func portrait_slot(t: Texture2D, size: int, faction := "neutral") -> Control:
	var ring := _Circle.new()
	ring.custom_minimum_size = Vector2(size, size)
	ring.tex = t
	ring.ring = FACTION.get(faction, MUTED)
	return ring

class _Circle extends Control:
	var tex: Texture2D
	var ring := Color("#9AA0A6")
	func _ready() -> void: resized.connect(queue_redraw)
	func _draw() -> void:
		var r: float = min(size.x, size.y) / 2.0
		var c := size / 2.0
		draw_circle(c, r, Color("#0C0E10"))
		if tex != null:
			draw_texture_rect(tex, Rect2(c - Vector2(r, r), Vector2(r * 2, r * 2)), false)
		draw_arc(c, r - 1, 0, TAU, 48, ring, 2.0, true)

## A soft radial white→transparent glow, cached. Tint + additive-blend it for
## faction influence blooms, rarity light pools, heat cores.
static var _glow: ImageTexture
static func radial_glow(n := 128) -> ImageTexture:
	if _glow != null:
		return _glow
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	var c := (n - 1) / 2.0
	for y in range(n):
		for x in range(n):
			var d: float = Vector2(x - c, y - c).length() / c
			var a: float = clampf(1.0 - d, 0.0, 1.0)
			a = a * a
			img.set_pixel(x, y, Color(1, 1, 1, a))
	_glow = ImageTexture.create_from_image(img)
	return _glow

## Concrete "tooth" texture layer (soft-light, opacity 0.22).
static func tooth_layer() -> TextureRect:
	var t := TextureRect.new()
	t.texture = tex("res://art/tex/tex-concrete.png")
	t.stretch_mode = TextureRect.STRETCH_TILE
	t.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	t.modulate = Color(1, 1, 1, 0.14)
	return t

class_name ItemArt
extends RefCounted
## Procedural gear icons — a faithful GDScript port of upgrade_05/item-art.js.
## Every item is painted into a 32×32 cell buffer and drawn by ItemView, the same
## pixel language as the doll: key light top-left, one shade band bottom-right, one
## outline, flat blocks, deterministic wear below Certi. ~60 parametric drawers, so
## a recolour or a new variant is a data edit, not new art. build(item) → Buf.

const N := 32
const NONE := Color(0, 0, 0, 0)
static func c(hex: String) -> Color: return Color(hex)

# ---------- palettes: [base, shade, highlight, outline] ----------
static var P := {
	"black":  [c("#23262A"), c("#15171A"), c("#383C41"), c("#0C0E10")],
	"charc":  [c("#33383D"), c("#212529"), c("#4A5057"), c("#141719")],
	"grey":   [c("#7E858C"), c("#5A6068"), c("#A0A7AE"), c("#33383D")],
	"lgrey":  [c("#B4BAC0"), c("#878D94"), c("#D6DBE0"), c("#4E545A")],
	"white":  [c("#E2E4E1"), c("#B2B5B2"), c("#F5F6F3"), c("#6E716E")],
	"cream":  [c("#DCCFAF"), c("#AFA285"), c("#F0E6CB"), c("#6E6753")],
	"navy":   [c("#2E3A52"), c("#1C2434"), c("#44536E"), c("#101620")],
	"blue":   [c("#3C6E8E"), c("#264A62"), c("#5A93B4"), c("#152C3B")],
	"denim":  [c("#4A6688"), c("#32465E"), c("#6787AC"), c("#1D2836")],
	"sky":    [c("#6E9EC0"), c("#4C7593"), c("#94C0DC"), c("#2E4A5E")],
	"red":    [c("#7A2E28"), c("#521A16"), c("#9C4740"), c("#2C0E0B")],
	"maroon": [c("#5A2430"), c("#3A1620"), c("#77363F"), c("#1F0C11")],
	"olive":  [c("#4A5236"), c("#313823"), c("#656E4A"), c("#1B2013")],
	"green":  [c("#3E5A3C"), c("#263A25"), c("#587A54"), c("#152314")],
	"tan":    [c("#8A6A44"), c("#63492C"), c("#A88A62"), c("#3A2A18")],
	"brown":  [c("#5A3A22"), c("#3A2312"), c("#7A5233"), c("#231407")],
	"wood":   [c("#A8763E"), c("#7A5228"), c("#C6975C"), c("#4A3116")],
	"sand":   [c("#B49A6E"), c("#8A7350"), c("#CFB88C"), c("#57492F")],
	"hivis":  [c("#D9E021"), c("#A3A814"), c("#EEF56B"), c("#5E6209")],
	"orange": [c("#D97A1E"), c("#A25512"), c("#F09A45"), c("#5E3208")],
	"gold":   [c("#C9A227"), c("#8E7016"), c("#E4C154"), c("#4E3D08")],
	"steel":  [c("#9AA3AA"), c("#6E767D"), c("#C2C9CF"), c("#454B50")],
	"dsteel": [c("#6E767D"), c("#4A5157"), c("#949BA1"), c("#2A2F33")],
	"purple": [c("#6E4A82"), c("#492F58"), c("#8E68A2"), c("#2A1834")],
	"pink":   [c("#B4707E"), c("#8A4E5B"), c("#D0959F"), c("#5A2E37")],
	"teal":   [c("#2E6E68"), c("#1C4844"), c("#489089"), c("#0F2A27")],
	"paper":  [c("#D8D2C2"), c("#ABA595"), c("#EFEBDD"), c("#6B675C")],
	"glass":  [c("#5E8A94"), c("#3E626B"), c("#86B2BB"), c("#264147")],
}
static func pal(k: String) -> Array:
	return P.get(k, P.grey)

const BLACKISH := Color("#0A0C0E")

# ---------- buffer ----------
class Buf:
	var d: PackedColorArray
	func _init() -> void:
		d = PackedColorArray(); d.resize(ItemArt.N * ItemArt.N); d.fill(ItemArt.NONE)
	func _ok(x: int, y: int) -> bool: return x >= 0 and x < ItemArt.N and y >= 0 and y < ItemArt.N
	func at(x: int, y: int) -> Color: return d[y * ItemArt.N + x] if _ok(x, y) else ItemArt.NONE
	func has(x: int, y: int) -> bool: return _ok(x, y) and d[y * ItemArt.N + x].a > 0.0
	func set_px(x: int, y: int, col: Color) -> void:
		if col.a <= 0.0: return                 # null in the JS = a no-op, never a clear
		x = int(x); y = int(y)
		if _ok(x, y): d[y * ItemArt.N + x] = col
	func r(x: int, y: int, w: int, h: int, col: Color) -> void:
		for j in range(h):
			for i in range(w): set_px(x + i, y + j, col)
	func row(x1: int, x2: int, y: int, col: Color) -> void:
		r(min(x1, x2), y, abs(x2 - x1) + 1, 1, col)
	func col_(x: int, y1: int, y2: int, col: Color) -> void:
		r(x, min(y1, y2), 1, abs(y2 - y1) + 1, col)
	func over(x: int, y: int, col: Color) -> void:
		if has(x, y): set_px(x, y, col)
	func di(x: int, y: int, x2: int, y2: int, col: Color) -> void:
		var dx := x2 - x; var dy := y2 - y
		var n: int = max(abs(dx), abs(dy))
		if n == 0: set_px(x, y, col); return
		for i in range(n + 1):
			set_px(x + int(dx * i / float(n)), y + int(dy * i / float(n)), col)
	func ell(cx: int, cy: int, rx: int, ry: int, col: Color, half := "") -> void:
		var y := int(ceil(cy - ry))
		while y <= cy + ry:
			if (half == "top" and y > cy) or (half == "bot" and y < cy):
				y += 1; continue
			var t := 1.0 - float((y - cy) * (y - cy)) / float(ry * ry)
			if t < 0.0: y += 1; continue
			var w := int(round(rx * sqrt(t)))
			row(cx - w, cx + w - 1, y, col)
			y += 1
	func shade_right(y0: int, y1: int, n: int, col: Color) -> void:
		for y in range(y0, y1 + 1):
			var last := -1
			for x in range(ItemArt.N):
				if has(x, y): last = x
			if last < 0: continue
			for i in range(n): over(last - i, y, col)
	func outline(col: Color) -> void:
		var add: Array = []
		for y in range(ItemArt.N):
			for x in range(ItemArt.N):
				if has(x, y): continue
				if has(x - 1, y) or has(x + 1, y) or has(x, y - 1) or has(x, y + 1):
					add.append(Vector2i(x, y))
		for p in add: set_px(p.x, p.y, col)
	func wear(seed: int, amount: int, col: Color) -> void:
		var s := seed * 9301 + 49297
		for i in range(amount):
			s = (s * 9301 + 49297) % 233280
			over(4 + (s % 24), 4 + ((s >> 5) % 24), col)

# ---------- public ----------
static func build(item: Dictionary) -> Buf:
	var b := Buf.new()
	var c4: Array = pal(str(item.get("c", "grey")))
	var v: Dictionary = item.get("v", {})
	var sh := str(item.get("sh", "none"))
	_draw(sh, b, c4, v)
	if sh != "none":
		b.outline(c("#4E545A") if _lum(c4[0]) < 0.20 else c4[3])
		var r := str(item.get("r", "Ba"))
		if r == "Ba" or r == "De":
			b.wear(str(item.get("n", "x")).length() * 7 + int(item.get("il", 0)), 9 if r == "Ba" else 5, c4[1])
		for x in range(6, 26):
			if not b.has(x, 29): b.set_px(x, 29, BLACKISH)
		for x in range(9, 23):
			if not b.has(x, 30): b.set_px(x, 30, c("#0E1013"))
	return b

static func _lum(col: Color) -> float:
	return col.r * 0.299 + col.g * 0.587 + col.b * 0.114

# ---------- shape dispatch ----------
static func _draw(sh: String, b: Buf, c: Array, v: Dictionary) -> void:
	match sh:
		"cap": _cap(b, c, v)
		"beanie": _beanie(b, c, v)
		"bucket": _bucket(b, c)
		"trilby": _trilby(b, c)
		"rainhat": _rainhat(b, c)
		"trapper": _trapper(b, c)
		"hood": _hood(b, c, v)
		"hardhat": _hardhat(b, c)
		"helmet": _helmet(b, c)
		"motolid": _motolid(b, c)
		"nursecap": _nursecap(b, c)
		"balaclava": _balaclava(b, c, v)
		"crown": _crown(b, c)
		"mask": _mask(b, c, v)
		"respirator": _respirator(b, c)
		"gaiter": _gaiter(b, c, v)
		"jacket": _jacket(b, c, v)
		"top": _top(b, c, v)
		"bottoms": _bottoms(b, c, v)
		"shoe": _shoe(b, c, v)
		"glove": _glove(b, c, v)
		"duster": _duster(b, c)
		"ring": _ring(b, c)
		"box": _box(b, c, v)
		"bat": _bat(b, c, v)
		"pole": _pole(b, c)
		"bottle": _bottle(b, c)
		"magazine": _magazine(b, c)
		"torch": _torch(b, c)
		"screwdriver": _screwdriver(b, c)
		"wrench": _wrench(b, c)
		"baton": _baton(b, c, v)
		"blade": _blade(b, c, v)
		"machete": _machete(b, c)
		"sawnoff": _sawnoff(b, c)
		"spray": _spray(b, c, v)
		"vestArmour": _vest_armour(b, c, v)
		"harness": _harness(b, c)
		"bag": _bag(b, c, v)
		"carrier": _carrier(b, c)
		"binbag": _binbag(b, c)
		"phone": _phone(b, c, v)
		"sim": _sim(b, c)
		"jammer": _jammer(b, c)
		"can": _can(b, c, v)
		"cup": _cup(b, c)
		"packet": _packet(b, c, v)
		"card": _card(b, c, v)
		"tool": _tool(b, c, v)
		"crowbar": _crowbar(b, c)
		"picks": _picks(b, c)
		"grinder": _grinder(b, c)
		"spirits": _spirits(b, c)
		"watch": _watch(b, c)
		"envelope": _envelope(b, c, v)
		"note": _note(b, c)
		"photo": _photo(b, c)
		"pen": _pen(b, c)
		"key": _key(b, c)
		"trophy": _trophy(b, c)
		"ledger": _ledger(b, c)
		"bandana": _bandana(b, c)
		_: _none(b)

# ===== HEAD =====
static func _cap(b: Buf, c: Array, v: Dictionary) -> void:
	var cy := 20; var rx := 9; var ry := 9
	b.ell(15, cy, rx, ry, c[0], "top")
	b.ell(15, cy, rx, ry, c[2], "top")
	b.ell(15, cy + 1, rx - 1, ry - 1, c[0], "top")
	b.r(6, cy - 1, 19, 2, c[0])
	b.col_(15, cy - 8, cy, c[1])
	if v.get("fitted", false): b.col_(11, cy - 7, cy, c[1]); b.col_(19, cy - 7, cy, c[1])
	if v.get("flat", false):
		b.r(16, cy - 1, 12, 3, c[1]); b.r(16, cy - 1, 12, 1, c[2]); b.r(16, cy + 2, 12, 1, c[3])
	else:
		b.ell(19, cy + 1, 9, 3, c[1], "bot"); b.ell(19, cy, 9, 3, c[1], "bot"); b.r(16, cy - 1, 6, 2, c[1])
	b.shade_right(cy - 7, cy, 3, c[1])
	if v.get("button", false): b.r(14, cy - 10, 2, 2, c[1])

static func _beanie(b: Buf, c: Array, v: Dictionary) -> void:
	var cy := 21; var rx := 9
	b.ell(16, cy, rx, 10, c[0], "top")
	b.ell(16, cy - 1, rx - 2, 8, c[2], "top")
	b.ell(16, cy, rx - 1, 9, c[0], "top")
	for x in range(9, 24, 3): b.col_(x, cy - 9, cy - 1, c[1])
	b.r(7, cy - 1, 19, 4, c[0]); b.r(7, cy - 1, 19, 1, c[2])
	for x in range(8, 25, 3): b.col_(x, cy, cy + 2, c[1])
	b.r(7, cy + 3, 19, 1, c[3])
	b.shade_right(cy - 9, cy + 2, 3, c[1])
	if v.get("bobble", false):
		b.ell(16, cy - 13, 4, 4, c[2]); b.ell(16, cy - 13, 3, 3, c[0]); b.ell(17, cy - 12, 2, 2, c[1])

static func _bucket(b: Buf, c: Array) -> void:
	b.ell(16, 19, 8, 9, c[0], "top"); b.ell(16, 18, 6, 7, c[2], "top"); b.ell(16, 19, 7, 8, c[0], "top")
	b.r(8, 17, 17, 3, c[0])
	b.ell(16, 20, 12, 4, c[1], "bot"); b.ell(16, 20, 12, 3, c[1], "bot")
	b.r(4, 19, 25, 1, c[2]); b.row(9, 23, 16, c[1]); b.shade_right(11, 23, 3, c[1])

static func _trilby(b: Buf, c: Array) -> void:
	b.ell(16, 17, 7, 9, c[0], "top"); b.ell(16, 16, 5, 7, c[2], "top"); b.ell(16, 17, 6, 8, c[0], "top")
	b.r(14, 9, 4, 3, c[1]); b.r(9, 15, 15, 3, c[0]); b.r(9, 15, 15, 2, c[3]); b.r(21, 14, 3, 3, c[3])
	b.ell(16, 18, 13, 4, c[1], "bot"); b.ell(16, 18, 13, 3, c[1], "bot")
	b.r(3, 17, 27, 1, c[2]); b.shade_right(9, 20, 3, c[1])

static func _rainhat(b: Buf, c: Array) -> void:
	b.ell(16, 18, 7, 8, c[0], "top"); b.ell(16, 17, 5, 6, c[2], "top"); b.ell(16, 18, 6, 7, c[0], "top")
	b.r(10, 16, 13, 3, c[0])
	b.ell(16, 20, 14, 5, c[1], "bot"); b.ell(16, 20, 14, 4, c[1], "bot")
	b.r(2, 19, 29, 1, c[2]); b.row(4, 27, 23, c[3]); b.shade_right(11, 23, 3, c[1])

static func _trapper(b: Buf, c: Array) -> void:
	b.ell(16, 17, 8, 8, c[0], "top"); b.ell(16, 16, 6, 6, c[2], "top"); b.ell(16, 17, 7, 7, c[0], "top")
	b.r(9, 15, 15, 3, c[0])
	b.r(6, 17, 20, 3, P.cream[0]); b.r(6, 17, 20, 1, P.cream[2])
	b.r(6, 20, 5, 7, c[0]); b.r(21, 20, 5, 7, c[1])
	b.r(6, 24, 5, 2, P.cream[1]); b.r(21, 24, 5, 2, P.cream[1])
	b.shade_right(10, 16, 3, c[1])

static func _hood(b: Buf, c: Array, v: Dictionary) -> void:
	b.ell(16, 17, 10, 11, c[0], "top"); b.r(6, 17, 21, 7, c[0]); b.ell(16, 24, 10, 5, c[0], "bot")
	b.ell(16, 16, 8, 9, c[2], "top"); b.ell(16, 17, 9, 10, c[0], "top")
	b.ell(16, 19, 6, 7, c[3]); b.ell(16, 19, 5, 6, BLACKISH)
	if v.get("fur", false):
		b.ell(16, 19, 7, 8, P.cream[0]); b.ell(16, 19, 6, 7, c[3]); b.ell(16, 19, 5, 6, BLACKISH); b.ell(16, 13, 5, 2, P.cream[2])
	if v.get("strings", false):
		b.col_(13, 24, 28, c[2]); b.col_(19, 24, 27, c[2]); b.r(12, 28, 2, 2, c[1]); b.r(18, 27, 2, 2, c[1])
	b.shade_right(9, 27, 3, c[1])

static func _hardhat(b: Buf, c: Array) -> void:
	b.ell(16, 19, 8, 9, c[0], "top"); b.ell(16, 18, 6, 7, c[2], "top"); b.ell(16, 19, 7, 8, c[0], "top")
	b.col_(16, 11, 18, c[1]); b.r(8, 17, 17, 3, c[0])
	b.ell(16, 20, 11, 3, c[0], "bot"); b.ell(16, 20, 11, 2, c[2], "bot")
	b.r(5, 21, 23, 1, c[1]); b.shade_right(11, 22, 3, c[1])

static func _helmet(b: Buf, c: Array) -> void:
	b.ell(15, 19, 10, 9, c[0], "top"); b.ell(15, 18, 8, 7, c[2], "top"); b.ell(15, 19, 9, 8, c[0], "top")
	b.r(6, 18, 20, 2, c[0])
	for i in range(4): b.r(9 + i * 4, 13 + i, 2, 6 - i, c[3])
	b.r(24, 17, 4, 3, c[1]); b.di(10, 20, 13, 26, c[1]); b.di(20, 20, 17, 26, c[1]); b.r(13, 25, 5, 3, c[3])
	b.shade_right(11, 20, 3, c[1])

static func _motolid(b: Buf, c: Array) -> void:
	b.ell(16, 20, 10, 12, c[0], "top"); b.ell(16, 18, 8, 9, c[2], "top"); b.ell(16, 20, 9, 11, c[0], "top")
	b.r(6, 18, 21, 6, c[0]); b.ell(16, 24, 10, 5, c[0], "bot")
	b.r(8, 15, 17, 6, P.glass[0]); b.r(8, 15, 17, 1, P.glass[2]); b.r(20, 16, 5, 5, P.glass[1])
	b.r(7, 14, 19, 1, c[3]); b.r(8, 21, 17, 1, c[3]); b.r(11, 26, 11, 2, c[1]); b.shade_right(10, 27, 3, c[1])

static func _nursecap(b: Buf, c: Array) -> void:
	b.ell(16, 20, 9, 8, c[0], "top"); b.ell(16, 19, 7, 6, c[2], "top"); b.ell(16, 20, 8, 7, c[0], "top")
	b.r(8, 18, 17, 3, c[0]); b.r(7, 20, 19, 2, c[1]); b.r(7, 20, 19, 1, c[2])
	b.r(15, 13, 2, 5, P.red[0]); b.r(13, 15, 6, 2, P.red[0]); b.shade_right(12, 21, 3, c[1])

static func _balaclava(b: Buf, c: Array, v: Dictionary) -> void:
	b.ell(16, 15, 9, 7, c[0], "top"); b.r(7, 15, 19, 10, c[0]); b.ell(16, 25, 9, 4, c[0], "bot")
	b.ell(16, 14, 7, 5, c[2], "top")
	if v.get("two", false):
		b.ell(12, 17, 3, 2, BLACKISH); b.ell(20, 17, 3, 2, BLACKISH); b.ell(12, 16, 3, 1, c[2]); b.ell(20, 16, 3, 1, c[2])
	else:
		b.r(9, 16, 14, 3, BLACKISH); b.ell(9, 17, 2, 2, BLACKISH); b.ell(23, 17, 2, 2, BLACKISH); b.r(9, 15, 14, 1, c[2])
	for x in range(8, 25, 3): b.col_(x, 20, 24, c[1])
	b.r(7, 24, 19, 1, c[1])
	if v.get("gold", false): b.r(7, 23, 19, 1, P.gold[0]); b.r(9, 15, 14, 1, P.gold[1])
	b.shade_right(9, 27, 3, c[1])

static func _crown(b: Buf, c: Array) -> void:
	b.r(8, 16, 17, 7, c[0]); b.r(8, 16, 17, 1, c[2])
	for p in [[7, 9], [14, 6], [21, 9]]:
		for i in range(8):
			var w: int = 4 - max(0, 2 - i)
			b.r(p[0] + int((4 - w) / 2.0), p[1] + i, w, 1, c[0])
		b.r(p[0], p[1], 4, 1, c[2])
	b.r(8, 18, 17, 2, c[3])
	b.r(11, 19, 3, 2, P.red[0]); b.r(19, 19, 3, 2, P.glass[0])
	b.set_px(8, 8, P.white[2]); b.set_px(15, 5, P.white[2]); b.set_px(22, 8, P.white[2])
	b.shade_right(6, 23, 3, c[1])

# ===== FACE =====
static func _mask(b: Buf, c: Array, v: Dictionary) -> void:
	b.ell(16, 16, 9, 5, c[0], "top"); b.r(7, 16, 19, 4, c[0]); b.ell(16, 20, 9, 5, c[0], "bot")
	b.r(7, 13, 19, 1, c[2])
	for y in range(16, 23, 2): b.row(8, 24, y, c[1])
	b.di(7, 14, 3, 11, c[1]); b.di(7, 22, 3, 25, c[1]); b.di(25, 14, 29, 11, c[1]); b.di(25, 22, 29, 25, c[1])
	if v.get("valve", false):
		b.ell(16, 19, 3, 3, P.charc[0]); b.ell(16, 19, 2, 2, P.charc[2]); b.ell(16, 19, 1, 1, P.charc[3])
	b.shade_right(12, 24, 3, c[1])

static func _respirator(b: Buf, c: Array) -> void:
	b.ell(16, 17, 7, 6, c[0], "top"); b.r(9, 17, 15, 4, c[0]); b.ell(16, 21, 7, 5, c[0], "bot")
	b.ell(16, 16, 5, 4, c[2], "top")
	b.ell(7, 17, 4, 4, P.charc[0]); b.ell(25, 17, 4, 4, P.charc[0]); b.ell(7, 16, 3, 2, P.charc[2]); b.ell(25, 16, 3, 2, P.charc[1])
	b.ell(16, 20, 4, 3, P.glass[0]); b.r(13, 19, 3, 1, P.glass[2])
	b.r(9, 13, 15, 1, c[1]); b.r(11, 25, 11, 1, c[1]); b.shade_right(12, 26, 3, c[1])

static func _gaiter(b: Buf, c: Array, v: Dictionary) -> void:
	b.ell(16, 11, 9, 3, c[0]); b.r(7, 11, 19, 12, c[0]); b.ell(16, 23, 9, 4, c[0], "bot")
	b.ell(16, 11, 7, 2, c[3]); b.r(9, 11, 15, 1, c[1])
	for y in range(15, 23, 3): b.row(8, 24, y, c[1])
	if v.get("skull", false):
		b.ell(16, 17, 4, 4, P.white[0]); b.r(14, 17, 2, 2, c[3]); b.r(17, 17, 2, 2, c[3]); b.r(14, 20, 5, 1, P.white[1])
	if v.get("scarf", false):
		b.r(10, 23, 6, 6, c[0]); b.r(10, 23, 6, 1, c[2]); b.r(10, 28, 6, 1, c[1])
	b.shade_right(11, 26, 3, c[1])

# ===== JACKET / TOP =====
static func _jacket(b: Buf, c: Array, v: Dictionary) -> void:
	var bot: int = int(v.get("bot", 26)); var w: int = int(v.get("w", 6))
	var bl := 16 - w; var br := 15 + w; var sh := 10
	var sleeve_end: int = (sh + 7) if v.get("short", false) else bot - 3
	b.r(bl + 2, sh - 2, w * 2 - 4, 2, c[0])
	b.r(bl, sh, w * 2, bot - sh, c[0])
	if not v.get("sleeveless", false):
		for y in range(sh, sleeve_end + 1):
			var drift := int((y - sh) / 9.0)
			b.r(bl - 5 - drift, y, 4, 1, c[0])
			b.r(br + 2 + drift, y, 4, 1, c[1])
		b.r(bl - 5, sh - 1, 4, 1, c[2]); b.r(bl - 5, sh, 4, 1, c[2])
		var dd := int((sleeve_end - sh) / 9.0)
		b.r(bl - 5 - dd, sleeve_end - 1, 4, 2, c[1]); b.r(br + 2 + dd, sleeve_end - 1, 4, 2, c[3])
		b.r(bl - 2, sh - 1, 2, 3, c[0]); b.r(br + 1, sh - 1, 2, 3, c[1])
	b.r(bl, sh - 2, w * 2, 1, c[2]); b.r(bl, bot - 1, w * 2, 1, c[3]); b.r(br - 3, sh, 4, bot - sh, c[1])
	var collar := str(v.get("collar", ""))
	if collar == "hood":
		b.ell(16, sh - 1, w, 5, c[1], "top"); b.r(bl + 1, sh - 5, w * 2 - 2, 4, c[1]); b.r(bl + 1, sh - 5, w * 2 - 2, 1, c[0]); b.r(13, sh - 2, 6, 2, c[3])
	elif collar == "fur":
		b.r(bl + 1, sh - 5, w * 2 - 2, 4, P.cream[0]); b.r(bl + 1, sh - 5, w * 2 - 2, 1, P.cream[2]); b.r(13, sh - 2, 6, 1, c[3])
	elif collar == "lapel":
		b.di(16, sh, 12, sh + 7, c[2]); b.di(16, sh, 20, sh + 7, c[2]); b.r(12, sh - 3, 3, 3, c[1]); b.r(18, sh - 3, 3, 3, c[1]); b.r(14, sh - 3, 5, 2, c[3])
	else:
		b.r(12, sh - 4, 8, 3, c[1]); b.r(12, sh - 4, 8, 1, c[2]); b.r(14, sh - 3, 5, 2, c[3])
	if v.get("zip", false): b.col_(16, sh - 1, bot - 1, c[2]); b.col_(15, sh - 1, bot - 1, c[3])
	if v.get("buttons", false):
		b.col_(16, sh, bot - 1, c[1])
		for y in range(sh + 3, bot - 2, 4): b.r(15, y, 2, 1, c[2])
	if v.get("baffles", false):
		for y in range(sh + 2, bot - 1, 3):
			b.row(bl, br, y, c[1])
			if not v.get("sleeveless", false): b.row(bl - 5, bl - 2, y, c[1]); b.row(br + 2, br + 5, y, c[3])
	if v.get("pockets", false): b.r(bl + 1, bot - 7, 4, 3, c[1]); b.r(br - 4, bot - 7, 4, 3, c[3])
	if v.get("hivis", false):
		b.r(bl, bot - 10, w * 2, 2, P.steel[2])
		if not v.get("sleeveless", false): b.r(bl - 5, bot - 10, 4, 2, P.steel[1]); b.r(br + 2, bot - 10, 4, 2, P.steel[1])
	if v.get("stripes", false) and not v.get("sleeveless", false):
		b.col_(bl - 4, sh + 1, sleeve_end - 2, c[2]); b.col_(br + 3, sh + 1, sleeve_end - 2, c[2])
	if v.get("strings", false): b.col_(14, sh - 1, sh + 5, c[2]); b.col_(18, sh - 1, sh + 4, c[2])

static func _top(b: Buf, c: Array, v: Dictionary) -> void:
	var T := 11; var Bt := 26; var w := 6; var bl := 16 - w; var br := 15 + w
	b.r(bl + 2, T - 2, w * 2 - 4, 2, c[0]); b.r(bl, T, w * 2, Bt - T, c[0]); b.r(bl, T - 2, w * 2, 1, c[2])
	if not v.get("vest", false):
		b.r(bl - 5, T, 5, 7, c[0]); b.r(br + 1, T, 5, 7, c[1]); b.r(bl - 5, T - 1, 5, 1, c[2])
		b.r(bl - 5, T + 6, 5, 1, c[1]); b.r(br + 1, T + 6, 5, 1, c[3])
	else:
		b.r(bl, T - 2, 3, 4, c[0]); b.r(br - 2, T - 2, 3, 4, c[1])
	b.r(br - 3, T, 4, Bt - T, c[1]); b.r(bl, Bt - 1, w * 2, 1, c[3])
	if v.get("crew", false): b.ell(16, T - 1, 4, 2, c[1]); b.ell(16, T - 1, 3, 1, c[3])
	if v.get("collar", false):
		b.r(12, T - 4, 8, 3, c[1]); b.r(12, T - 4, 8, 1, c[2]); b.r(14, T - 3, 5, 2, c[3]); b.col_(16, T - 1, T + 4, c[1]); b.set_px(15, T, c[2]); b.set_px(15, T + 3, c[2])
	if v.get("hood", false): b.ell(16, T - 1, w, 5, c[1], "top"); b.r(bl + 1, T - 5, w * 2 - 2, 4, c[1]); b.r(bl + 1, T - 5, w * 2 - 2, 1, c[0]); b.r(13, T - 2, 6, 2, c[3])
	if v.get("number", false): b.r(13, T + 4, 2, 6, c[2]); b.r(17, T + 4, 2, 6, c[2])
	if v.get("hivis", false):
		b.r(bl, T + 7, w * 2, 2, P.steel[2])
		if not v.get("vest", false): b.r(bl - 5, T + 4, 5, 2, P.steel[1]); b.r(br + 1, T + 4, 5, 2, P.steel[1])
	if v.get("stripe", false):
		b.r(bl, T + 5, w * 2, 2, c[2])
		if not v.get("vest", false): b.r(bl - 5, T + 5, 5, 2, c[2]); b.r(br + 1, T + 5, 5, 2, c[2])

static func _bottoms(b: Buf, c: Array, v: Dictionary) -> void:
	var T := 6; var Bm: int = 19 if v.get("short", false) else 27
	b.r(10, T, 12, 5, c[0]); b.r(10, T, 12, 1, c[2])
	if v.get("elastic", false):
		for x in range(11, 21, 2): b.col_(x, T + 1, T + 3, c[1])
	if v.get("belt", false): b.r(10, T + 2, 12, 2, c[3]); b.r(15, T + 1, 3, 4, c[1])
	b.r(10, T + 5, 5, Bm - T - 4, c[0]); b.r(17, T + 5, 5, Bm - T - 4, c[1]); b.r(15, T + 5, 2, Bm - T - 4, c[3])
	b.r(10, T + 5, 5, 1, c[2]); b.r(10, Bm, 5, 1, c[3]); b.r(17, Bm, 5, 1, c[3])
	if v.get("cuff", false): b.r(10, Bm - 2, 5, 2, c[1]); b.r(17, Bm - 2, 5, 2, c[3])
	if v.get("pockets", false): b.r(11, 15, 3, 4, c[1]); b.r(18, 15, 3, 4, c[3])
	if v.get("crease", false): b.col_(12, T + 6, Bm - 1, c[2]); b.col_(19, T + 6, Bm - 1, c[0])
	if v.get("bands", false): b.r(10, 19, 5, 2, P.steel[2]); b.r(17, 19, 5, 2, P.steel[1])

# ===== FEET =====
static func _shoe(b: Buf, c: Array, v: Dictionary) -> void:
	var soleY: int = int(v.get("soleY", 24)); var soleH: int = int(v.get("soleH", 3))
	for x in range(5, 27):
		var t: float = clampf((x - 5) / 21.0, 0.0, 1.0)
		var y: int = int(round(21 - 9 * pow(t, 1.5)))
		if x >= 12 and x <= 19: y = max(y, 16)
		b.col_(x, y, soleY - 1, c[0]); b.set_px(x, y, c[2])
	b.ell(8, 20, 4, 4, c[0]); b.ell(8, 19, 3, 3, c[2])
	b.r(21, 13, 6, soleY - 13, c[1])
	b.ell(23, 14, 5, 2, c[1]); b.ell(23, 14, 4, 1, BLACKISH)
	b.r(13, 15, 5, 5, c[2]); b.r(13, 15, 5, 1, c[0])
	if v.get("boot", false):
		var shf: int = int(v.get("shaft", 7))
		b.r(19, 14 - shf, 8, shf, c[0]); b.r(23, 14 - shf, 4, shf, c[1]); b.r(19, 14 - shf, 8, 1, c[2]); b.ell(23, 14 - shf, 4, 1, c[1])
	if v.get("laces", false):
		for i in range(4):
			var x := 11 + i * 2
			b.di(x, _shoe_top(x) + 1, x + 3, _shoe_top(x + 3) + 3, c[2])
	if v.get("swoosh", false): b.di(9, 22, 18, 17, c[2]); b.di(9, 23, 18, 18, c[2])
	if v.get("brogue", false):
		for x in range(9, 19, 2): b.set_px(x, _shoe_top(x) + 2, c[2])
	if v.get("steel", false): b.ell(8, 20, 4, 4, c[2]); b.ell(8, 20, 3, 3, c[0])
	if v.get("strap", false): b.r(19, 11, 8, 2, c[3]); b.r(24, 10, 3, 4, c[1])
	var soleC: Color = _vc(v, "soleC", P.white[0]); var soleHi: Color = _vc(v, "soleHi", P.white[2])
	b.r(4, soleY, 24, soleH, soleC); b.r(4, soleY - 1, 4, 1, soleC); b.r(4, soleY, 24, 1, soleHi); b.r(4, soleY + soleH, 24, 1, c("#1A1D20"))
	if soleH > 3:
		for x in range(5, 27, 3): b.col_(x, soleY + 2, soleY + soleH - 1, _vc(v, "soleHi", P.white[1]))

static func _shoe_top(x: int) -> int:
	var t: float = clampf((x - 5) / 21.0, 0.0, 1.0)
	var y: int = int(round(21 - 9 * pow(t, 1.5)))
	if x >= 12 and x <= 19: y = max(y, 16)
	return y

static func _vc(v: Dictionary, key: String, fb: Color) -> Color:
	if v.has(key): return Color(str(v[key]))
	return fb

# ===== HANDS =====
static func _glove(b: Buf, c: Array, v: Dictionary) -> void:
	b.r(11, 8, 11, 14, c[0]); b.r(11, 8, 11, 1, c[2]); b.r(18, 9, 4, 13, c[1])
	for x in range(13, 22, 3): b.col_(x, 8, 13, c[1])
	b.r(7, 12, 4, 5, c[0]); b.r(7, 12, 4, 1, c[2])
	b.r(11, 22, 11, 3, c[1]); b.r(11, 22, 11, 1, c[2])
	if v.get("fingerless", false): b.r(11, 11, 11, 1, c[1])
	if v.get("knuck", false):
		b.r(12, 14, 9, 3, c[2])
		for x in range(13, 21, 3): b.r(x, 14, 2, 3, c[3])
	if v.get("thin", false): b.r(11, 22, 11, 3, c[0]); b.r(11, 23, 11, 1, c[2])
	if v.get("strap", false): b.r(10, 21, 13, 2, c[3])

static func _duster(b: Buf, c: Array) -> void:
	b.r(8, 12, 16, 8, c[0]); b.r(8, 12, 16, 2, c[2]); b.r(8, 18, 16, 2, c[1])
	for i in range(4): b.r(9 + i * 4, 13, 3, 3, c[3]); b.r(9 + i * 4, 9, 3, 4, c[0]); b.r(11 + i * 4, 9, 1, 4, c[1])
	b.r(8, 20, 16, 1, c[3])

static func _ring(b: Buf, c: Array) -> void:
	b.r(12, 11, 8, 2, c[0]); b.r(12, 19, 8, 2, c[1]); b.col_(11, 12, 20, c[0]); b.col_(20, 12, 20, c[1]); b.r(12, 11, 8, 1, c[2])

static func _box(b: Buf, c: Array, v: Dictionary) -> void:
	b.r(7, 10, 18, 14, c[0]); b.r(7, 10, 18, 2, c[2]); b.r(20, 12, 5, 12, c[1]); b.r(9, 13, 14, 5, c[3])
	if v.get("label", false): b.r(10, 14, 12, 3, c[1])
	if v.get("tab", false): b.r(12, 8, 8, 2, c[1])

# ===== WEAPON =====
static func _bat(b: Buf, c: Array, v: Dictionary) -> void:
	for y in range(3, 17):
		var w: int = 4 if y < 5 else 6
		b.r(16 - (w >> 1), y, w, 1, c[0]); b.r(16 + (w >> 1) - 1, y, 1, 1, c[1])
	b.ell(16, 4, 2, 2, c[2], "top")
	for y in range(17, 27):
		var w: int = max(2, 6 - int(round((y - 16) * 0.5)))
		b.r(16 - (w >> 1), y, w, 1, c[1])
	b.r(15, 22, 3, 5, c[3]); b.r(14, 27, 5, 2, c[1]); b.r(14, 27, 5, 1, c[2]); b.col_(15, 5, 16, c[2])
	if v.get("signed", false): b.di(14, 10, 18, 8, P.white[0]); b.di(14, 13, 18, 12, P.white[1])

static func _pole(b: Buf, c: Array) -> void:
	b.r(14, 3, 5, 26, c[0]); b.r(17, 3, 2, 26, c[1]); b.r(14, 3, 5, 1, c[2])
	b.r(13, 3, 7, 2, c[1]); b.r(13, 27, 7, 2, c[1]); b.r(14, 12, 5, 2, c[3])

static func _bottle(b: Buf, c: Array) -> void:
	b.r(13, 4, 5, 6, c[0]); b.r(16, 4, 2, 6, c[1]); b.r(11, 10, 9, 3, c[0])
	b.r(10, 13, 11, 15, c[0]); b.r(17, 13, 4, 15, c[1]); b.r(10, 13, 11, 1, c[2])
	b.r(11, 17, 9, 5, P.paper[0]); b.r(11, 17, 9, 1, P.paper[2]); b.r(13, 3, 5, 2, c[3])

static func _magazine(b: Buf, c: Array) -> void:
	b.r(11, 4, 10, 24, c[0]); b.r(11, 4, 10, 2, c[2]); b.r(17, 6, 4, 22, c[1])
	b.col_(13, 5, 27, c[1]); b.col_(15, 5, 27, c[1]); b.r(11, 4, 10, 1, c[3])

static func _torch(b: Buf, c: Array) -> void:
	b.r(12, 4, 8, 5, c[2]); b.r(12, 4, 8, 1, P.cream[2]); b.r(13, 9, 6, 18, c[0]); b.r(17, 9, 2, 18, c[1])
	for y in range(13, 24, 3): b.row(13, 18, y, c[1])
	b.r(13, 27, 6, 2, c[3])

static func _screwdriver(b: Buf, c: Array) -> void:
	b.r(15, 3, 2, 14, P.steel[0]); b.set_px(16, 3, P.steel[2]); b.col_(16, 4, 16, P.steel[1]); b.r(14, 2, 4, 2, P.steel[2])
	b.r(12, 17, 8, 11, c[0]); b.r(17, 18, 3, 10, c[1]); b.r(12, 17, 8, 1, c[2])
	for y in range(19, 27, 2): b.row(12, 19, y, c[1])

static func _wrench(b: Buf, c: Array) -> void:
	for pair in [[3, true], [20, false]]:
		var y0: int = pair[0]; var left: bool = pair[1]
		b.r(9, y0, 14, 9, c[0]); b.r(18, y0 + 1, 5, 7, c[1]); b.r(9, y0, 14, 1, c[2])
		b.r(20 if left else 9, y0 + 2, 3, 5, c[0])
	b.r(13, 11, 6, 10, c[0]); b.r(17, 11, 2, 10, c[1]); b.col_(14, 11, 20, c[2])

static func _baton(b: Buf, c: Array, v: Dictionary) -> void:
	b.r(14, 4, 4, 16, P.steel[0]); b.r(16, 4, 2, 16, P.steel[1]); b.r(14, 4, 4, 1, P.steel[2])
	b.r(13, 20, 6, 8, c[0]); b.r(17, 21, 2, 7, c[1]); b.r(13, 20, 6, 1, c[2])
	if v.get("grip", false):
		for y in range(22, 27, 2): b.row(13, 18, y, c[1])

static func _blade(b: Buf, c: Array, v: Dictionary) -> void:
	var ln: int = int(v.get("len", 16)); var w: int = int(v.get("w", 3))
	for i in range(ln):
		var x := 9 + int(round(i * 0.55)); var y := 24 - i
		b.r(x, y, w, 1, P.steel[0]); b.set_px(x + w - 1, y, P.steel[1]); b.set_px(x, y, P.steel[2])
	var hx := 8; var hy := 24
	b.r(hx - 1, hy, 6, 5, c[0]); b.r(hx + 3, hy + 1, 2, 4, c[1]); b.r(hx - 1, hy, 6, 1, c[2])
	if v.get("guard", false): b.r(hx - 1, hy - 1, 8, 2, P.charc[0])
	if v.get("serr", false):
		for i in range(2, ln, 2): b.set_px(9 + int(round(i * 0.55)) + w, 24 - i, P.steel[1])
	if v.get("fold", false): b.r(hx - 1, hy - 6, 6, 7, c[0]); b.r(hx + 3, hy - 5, 2, 6, c[1])

static func _machete(b: Buf, c: Array) -> void:
	for i in range(20):
		var x := 8 + int(round(i * 0.5)); var y := 24 - i; var w: int = 5 if i > 12 else 4
		b.r(x, y, w, 1, P.steel[0]); b.set_px(x + w - 1, y, P.steel[1]); b.set_px(x, y, P.steel[2])
	b.r(6, 23, 7, 6, c[0]); b.r(10, 24, 3, 5, c[1]); b.r(6, 23, 7, 1, c[2]); b.r(6, 22, 9, 2, P.charc[0])

static func _sawnoff(b: Buf, c: Array) -> void:
	b.r(6, 12, 16, 4, P.charc[0]); b.r(6, 12, 16, 1, P.charc[2]); b.r(6, 15, 16, 1, P.charc[3]); b.col_(14, 12, 15, P.charc[1])
	b.r(6, 11, 3, 6, P.charc[3]); b.r(20, 13, 8, 7, c[0]); b.r(24, 14, 4, 6, c[1]); b.r(20, 13, 8, 1, c[2])
	b.di(20, 20, 26, 24, c[1]); b.r(16, 16, 3, 4, c[0])

static func _spray(b: Buf, c: Array, v: Dictionary) -> void:
	b.r(12, 8, 8, 20, c[0]); b.r(17, 9, 3, 19, c[1]); b.r(12, 8, 8, 1, c[2])
	b.r(13, 4, 6, 4, P.charc[0]); b.r(17, 5, 2, 3, P.charc[1]); b.r(12, 6, 8, 2, P.charc[0]); b.r(12, 14, 8, 6, c[2])
	if v.get("cap", false): b.r(13, 2, 6, 3, c[1])
	if v.get("nozzle", false): b.r(19, 5, 3, 2, P.charc[2])

# ===== BODY =====
static func _vest_armour(b: Buf, c: Array, v: Dictionary) -> void:
	if v.get("belt", false):
		b.r(4, 15, 24, 5, c[0]); b.r(4, 15, 24, 1, c[2]); b.r(4, 19, 24, 1, c[3])
		b.r(13, 13, 7, 9, c[0]); b.r(13, 13, 7, 1, c[2]); b.r(17, 14, 3, 8, c[1])
		b.r(20, 14, 4, 7, P.steel[0])
		return
	b.r(11, 7, 4, 7, c[0]); b.r(17, 7, 4, 7, c[1]); b.r(11, 7, 4, 1, c[2])
	b.r(9, 13, 14, 14, c[0]); b.r(9, 13, 14, 1, c[2]); b.r(19, 14, 4, 13, c[1]); b.r(9, 26, 14, 1, c[3]); b.col_(16, 14, 26, c[3])
	if v.get("molle", false):
		for y in range(16, 25, 3): b.row(10, 15, y, c[1]); b.row(17, 22, y, c[3])
	if v.get("pouch", false): b.r(10, 18, 5, 6, c[1]); b.r(17, 18, 5, 6, c[3]); b.r(10, 18, 5, 1, c[2])
	if v.get("straps", false): b.r(7, 16, 2, 9, c[1]); b.r(23, 16, 2, 9, c[1]); b.r(7, 19, 2, 2, P.steel[1]); b.r(23, 19, 2, 2, P.steel[1])
	if v.get("plate", false): b.r(11, 15, 10, 9, P.charc[0]); b.r(11, 15, 10, 1, P.charc[2]); b.r(18, 16, 3, 8, P.charc[1])
	if v.get("hivis", false): b.r(9, 19, 14, 2, P.steel[2])

static func _harness(b: Buf, c: Array) -> void:
	b.di(11, 8, 16, 17, c[0]); b.di(12, 8, 17, 17, c[1]); b.di(21, 8, 16, 17, c[0]); b.di(20, 8, 15, 17, c[1])
	b.r(13, 17, 6, 4, P.steel[0]); b.r(13, 17, 6, 1, P.steel[2])
	b.r(7, 21, 18, 3, c[0]); b.r(7, 21, 18, 1, c[2]); b.r(7, 23, 18, 1, c[1]); b.r(9, 24, 4, 4, c[1]); b.r(19, 24, 4, 4, c[1])

# ===== BAG =====
static func _bag(b: Buf, c: Array, v: Dictionary) -> void:
	var top: int = int(v.get("top", 11))
	b.r(7, top, 18, 27 - top, c[0]); b.r(7, top, 18, 1, c[2]); b.r(19, top + 1, 6, 26 - top, c[1])
	if v.get("flap", false): b.r(7, top, 18, 6, c[1]); b.r(7, top, 18, 1, c[2]); b.r(14, top + 5, 4, 2, P.steel[0])
	if v.get("straps", false): b.di(10, top, 12, 4, c[1]); b.di(22, top, 20, 4, c[1]); b.r(11, 3, 10, 2, c[1])
	if v.get("handle", false): b.r(11, top - 5, 2, 5, c[1]); b.r(19, top - 5, 2, 5, c[1]); b.r(11, top - 6, 10, 2, c[1])
	if v.get("zip", false):
		b.row(8, 23, top + 3, c[2])
		for x in range(8, 24, 2): b.set_px(x, top + 3, c[3])
	if v.get("pockets", false): b.r(9, top + 8, 6, 6, c[1]); b.r(17, top + 8, 6, 6, c[3])
	if v.get("long", false): b.r(7, top, 18, 4, c[1])
	if v.get("cross", false): b.di(7, top + 1, 23, 3, c[1]); b.di(8, top + 1, 24, 3, c[0])

static func _carrier(b: Buf, c: Array) -> void:
	b.r(8, 10, 16, 17, c[0]); b.r(8, 10, 16, 1, c[2]); b.r(19, 11, 5, 16, c[1])
	b.r(9, 6, 4, 5, c[0]); b.r(19, 6, 4, 5, c[1]); b.r(9, 5, 4, 2, c[2]); b.r(19, 5, 4, 2, c[1]); b.r(11, 15, 10, 5, c[2])

static func _binbag(b: Buf, c: Array) -> void:
	b.r(9, 12, 15, 15, c[0]); b.r(9, 12, 15, 1, c[2]); b.r(19, 13, 5, 14, c[1])
	b.r(11, 8, 10, 5, c[0]); b.r(17, 9, 4, 4, c[1]); b.r(10, 6, 5, 4, c[0]); b.r(17, 6, 5, 4, c[1]); b.r(8, 26, 17, 2, c[1])

# ===== PHONE / TECH =====
static func _phone(b: Buf, c: Array, v: Dictionary) -> void:
	var screen: Color = _vc(v, "screen", P.glass[0])
	b.r(11, 4, 11, 24, c[0]); b.r(11, 4, 11, 1, c[2]); b.r(18, 5, 4, 23, c[1])
	b.r(12, 7, 9, 16, screen); b.r(12, 7, 9, 1, P.glass[2])
	if v.get("cracked", false): b.di(13, 9, 19, 20, P.white[1]); b.di(16, 8, 14, 21, P.white[1]); b.di(16, 13, 20, 16, P.white[1])
	if v.get("keys", false):
		b.r(12, 20, 9, 6, c[1])
		for y in range(21, 26, 2):
			for x in range(13, 21, 3): b.set_px(x, y, c[3])
		b.r(12, 7, 9, 12, screen)
	if v.get("antenna", false): b.r(19, 1, 2, 4, c[1])
	if v.get("dual", false): b.r(13, 24, 3, 2, c[2]); b.r(17, 24, 3, 2, c[2])

static func _sim(b: Buf, c: Array) -> void:
	b.r(9, 10, 15, 12, c[0]); b.r(9, 10, 15, 1, c[2]); b.r(20, 11, 4, 11, c[1])
	b.r(12, 13, 8, 6, P.gold[0]); b.r(12, 13, 8, 1, P.gold[2]); b.col_(16, 13, 18, P.gold[1]); b.row(12, 19, 16, P.gold[1])

static func _jammer(b: Buf, c: Array) -> void:
	b.r(8, 12, 16, 12, c[0]); b.r(8, 12, 16, 1, c[2]); b.r(19, 13, 5, 11, c[1])
	b.r(10, 15, 6, 5, P.glass[0]); b.r(10, 15, 6, 1, P.glass[2]); b.r(18, 16, 3, 3, P.red[0])
	b.r(11, 6, 2, 6, P.steel[0]); b.r(19, 4, 2, 8, P.steel[0]); b.r(10, 5, 4, 2, P.steel[1]); b.r(18, 3, 4, 2, P.steel[1])

# ===== CONSUMABLES =====
static func _can(b: Buf, c: Array, v: Dictionary) -> void:
	b.r(11, 6, 10, 21, c[0]); b.r(17, 7, 4, 20, c[1]); b.r(11, 6, 10, 1, c[2])
	b.r(11, 5, 10, 2, P.steel[0]); b.r(11, 5, 10, 1, P.steel[2]); b.r(11, 26, 10, 2, P.steel[1]); b.r(11, 12, 10, 7, c[2])
	if v.get("tab", false): b.r(14, 4, 4, 2, P.steel[1])

static func _cup(b: Buf, c: Array) -> void:
	for i in range(18):
		var w: int = 14 - int(round(i * 0.3))
		b.r(16 - int(w / 2.0), 10 + i, w, 1, c[0]); b.r(16 + int(ceil(w / 2.0)) - 3, 10 + i, 3, 1, c[1])
	b.r(8, 7, 16, 3, P.white[0]); b.r(8, 7, 16, 1, P.white[2]); b.r(12, 5, 8, 2, P.charc[0]); b.r(9, 15, 14, 3, c[2])

static func _packet(b: Buf, c: Array, v: Dictionary) -> void:
	b.r(7, 9, 18, 16, c[0]); b.r(7, 9, 18, 1, c[2]); b.r(20, 10, 5, 15, c[1]); b.r(9, 12, 14, 6, c[2])
	if v.get("pills", false):
		for y in range(13, 22, 4):
			for x in range(10, 22, 4): b.r(x, y, 3, 3, P.steel[2]); b.set_px(x + 1, y + 1, P.steel[1])
	if v.get("meat", false): b.r(9, 12, 14, 9, P.pink[0]); b.r(9, 12, 14, 1, P.pink[2]); b.r(18, 13, 5, 8, P.pink[1])
	if v.get("food", false): b.r(9, 11, 14, 4, P.wood[0]); b.r(9, 18, 14, 4, P.sand[0])

static func _card(b: Buf, c: Array, v: Dictionary) -> void:
	b.r(6, 11, 20, 13, c[0]); b.r(6, 11, 20, 1, c[2]); b.r(21, 12, 5, 12, c[1])
	if v.get("photo", false): b.r(8, 13, 6, 8, P.charc[0]); b.r(9, 14, 4, 4, P.steel[1])
	for y in range(14, 22, 2): b.row(15 if v.get("photo", false) else 8, 23, y, c[1])
	if v.get("chip", false): b.r(8, 14, 5, 4, P.gold[0]); b.r(8, 14, 5, 1, P.gold[2])

static func _tool(b: Buf, c: Array, v: Dictionary) -> void:
	b.di(11, 27, 14, 12, c[0]); b.di(12, 27, 15, 12, c[1]); b.di(21, 27, 18, 12, c[0]); b.di(20, 27, 17, 12, c[1])
	var grip: Color = _vc(v, "grip", P.red[0])
	b.r(10, 24, 4, 5, grip); b.r(19, 24, 4, 5, grip)
	b.r(13, 8, 6, 6, P.steel[0]); b.r(13, 8, 6, 1, P.steel[2]); b.r(17, 9, 2, 5, P.steel[1]); b.r(14, 4, 2, 5, P.steel[0]); b.r(17, 4, 2, 5, P.steel[1])

static func _crowbar(b: Buf, c: Array) -> void:
	for i in range(20): b.r(11 + int(round(i * 0.4)), 25 - i, 3, 1, c[0])
	for i in range(20): b.set_px(13 + int(round(i * 0.4)), 25 - i, c[1])
	b.r(17, 4, 6, 3, c[0]); b.r(21, 4, 2, 3, c[1]); b.r(21, 3, 4, 2, c[2]); b.r(9, 24, 5, 4, c[1])

static func _picks(b: Buf, c: Array) -> void:
	b.r(7, 20, 18, 8, c[0]); b.r(7, 20, 18, 1, c[2]); b.r(20, 21, 5, 7, c[1])
	for i in range(5): b.col_(9 + i * 3, 6 + i, 20, P.steel[0]); b.set_px(9 + i * 3, 6 + i, P.steel[2]); b.set_px(10 + i * 3, 7 + i, P.steel[1])
	b.r(7, 22, 18, 1, c[1])

static func _grinder(b: Buf, c: Array) -> void:
	b.r(6, 13, 13, 8, c[0]); b.r(6, 13, 13, 1, c[2]); b.r(6, 19, 13, 2, c[1])
	b.r(17, 10, 4, 14, P.charc[0]); b.r(19, 11, 2, 13, P.charc[1])
	b.r(19, 6, 3, 22, P.steel[0]); b.r(21, 7, 1, 21, P.steel[1]); b.r(19, 6, 3, 1, P.steel[2]); b.r(8, 15, 7, 3, c[2]); b.r(4, 16, 3, 3, c[1])

static func _spirits(b: Buf, c: Array) -> void:
	b.r(14, 3, 5, 6, P.glass[0]); b.r(17, 3, 2, 6, P.glass[1]); b.r(13, 2, 7, 2, P.gold[0]); b.r(13, 2, 7, 1, P.gold[2])
	for y in range(9, 13):
		var w: int = 5 + (y - 8) * 2
		b.r(16 - (w >> 1), y, w, 1, P.glass[0])
	b.r(10, 13, 12, 15, P.glass[0]); b.r(18, 13, 4, 15, P.glass[1]); b.r(10, 13, 12, 1, P.glass[2]); b.col_(12, 14, 27, P.glass[2])
	b.r(10, 17, 12, 8, c[0]); b.r(10, 17, 12, 1, c[2]); b.r(19, 18, 3, 7, c[1]); b.r(12, 19, 8, 4, P.gold[0]); b.r(13, 20, 6, 2, c[0])

# ===== TROPHIES =====
static func _watch(b: Buf, c: Array) -> void:
	b.r(13, 3, 6, 8, c[1]); b.r(13, 21, 6, 8, c[1])
	for y in range(4, 29, 3): b.row(13, 18, y, c[3])
	b.r(9, 10, 14, 12, P.gold[0]); b.r(9, 10, 14, 1, P.gold[2]); b.r(19, 11, 4, 11, P.gold[1])
	b.r(11, 12, 10, 8, P.cream[0]); b.r(11, 12, 10, 1, P.cream[2]); b.r(15, 14, 1, 4, P.charc[0]); b.r(16, 16, 3, 1, P.charc[0])

static func _envelope(b: Buf, c: Array, v: Dictionary) -> void:
	b.r(6, 10, 20, 14, c[0]); b.r(6, 10, 20, 1, c[2]); b.r(21, 11, 5, 13, c[1])
	b.di(6, 10, 16, 18, c[1]); b.di(25, 10, 16, 18, c[1])
	if v.get("sealed", false): b.r(14, 17, 5, 4, P.red[0])
	if v.get("window", false): b.r(8, 18, 8, 4, P.paper[0])

static func _note(b: Buf, c: Array) -> void:
	b.r(8, 8, 16, 18, P.paper[0]); b.r(8, 8, 16, 1, P.paper[2]); b.r(20, 9, 4, 17, P.paper[1])
	for y in range(12, 24, 3): b.row(10, 20, y, c[1])
	b.r(8, 8, 16, 1, P.paper[3]); b.di(8, 26, 24, 24, P.paper[1])

static func _photo(b: Buf, c: Array) -> void:
	b.r(6, 8, 20, 17, P.cream[0]); b.r(6, 8, 20, 1, P.cream[2]); b.r(22, 9, 4, 16, P.cream[1])
	b.r(8, 10, 16, 11, c[0]); b.r(8, 10, 16, 1, c[2])
	b.r(12, 14, 8, 7, P.brown[0]); b.r(13, 12, 3, 3, P.brown[0]); b.r(17, 13, 2, 2, P.brown[1]); b.r(6, 22, 20, 3, P.cream[1])

static func _pen(b: Buf, c: Array) -> void:
	b.di(11, 27, 20, 5, c[0]); b.di(12, 27, 21, 5, c[1]); b.di(10, 28, 12, 25, P.gold[0])
	b.r(17, 7, 4, 6, P.gold[0]); b.r(19, 8, 2, 5, P.gold[1]); b.r(19, 4, 2, 5, c[2])

static func _key(b: Buf, c: Array) -> void:
	b.r(12, 5, 9, 9, P.steel[0]); b.r(12, 5, 9, 1, P.steel[2]); b.r(18, 6, 3, 8, P.steel[1])
	b.r(15, 14, 3, 13, P.steel[0]); b.r(17, 14, 1, 13, P.steel[1]); b.r(18, 20, 3, 2, P.steel[0]); b.r(18, 24, 4, 2, P.steel[0])

static func _trophy(b: Buf, c: Array) -> void:
	b.r(10, 6, 12, 9, P.gold[0]); b.r(10, 6, 12, 1, P.gold[2]); b.r(18, 7, 4, 8, P.gold[1])
	b.r(12, 15, 8, 3, P.gold[1]); b.r(7, 8, 3, 5, P.gold[0]); b.r(22, 8, 3, 5, P.gold[1]); b.r(14, 18, 4, 5, P.gold[1])
	b.r(9, 23, 14, 5, P.wood[0]); b.r(9, 23, 14, 1, P.wood[2]); b.r(19, 24, 4, 4, P.wood[1])

static func _ledger(b: Buf, c: Array) -> void:
	b.r(7, 6, 18, 21, c[0]); b.r(7, 6, 18, 1, c[2]); b.r(21, 7, 4, 20, c[1])
	b.r(9, 8, 14, 17, P.paper[0]); b.r(9, 8, 14, 1, P.paper[2])
	for y in range(11, 24, 3): b.row(11, 21, y, c[1])
	b.col_(18, 9, 24, P.red[0]); b.r(7, 6, 3, 21, c[1])

static func _bandana(b: Buf, c: Array) -> void:
	b.di(6, 14, 16, 6, c[0]); b.di(26, 14, 16, 6, c[0])
	for i in range(10): b.row(6 + i, 26 - i, 14 + i, c[0] if i < 6 else c[1])
	b.r(11, 12, 10, 5, c[2]); b.r(6, 13, 4, 3, c[1]); b.r(22, 13, 4, 3, c[1])

static func _none(b: Buf) -> void:
	for i in range(14): b.set_px(9 + i, 9 + i, P.charc[2]); b.set_px(22 - i, 9 + i, P.charc[2])
	b.r(9, 9, 2, 2, P.charc[0]); b.r(21, 9, 2, 2, P.charc[0]); b.r(9, 21, 2, 2, P.charc[0]); b.r(21, 21, 2, 2, P.charc[0])

# ---------- rarity colours ----------
static var RC := {"Ba": Color("#B9C0C7"), "De": Color("#6FCF6F"), "Pe": Color("#4DA3FF"), "Ce": Color("#B06CF0"), "Ic": Color("#F2C14E")}

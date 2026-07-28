class_name Doll
extends RefCounted
## Layered procedural pixel paperdoll — a 1:1 GDScript port of upgrade_04/doll.js.
## Paints into a 48×60 cell buffer so every feature lands on the same grid lines,
## then DollView draws the cells scaled. Same art language as the px-* plates:
## chunky pixels, flat blocks, one shade band, hard edges.

const W := 48
const H := 60
const CX := 24
const CLEAR := Color(0, 0, 0, 0)

static func c(hex: String) -> Color: return Color(hex)

# ---------- palettes ----------
static var SKIN := [
	{"k":"S1","base":c("#E8C4A0"),"sh":c("#C79E7C"),"hi":c("#F4D9BF"),"dk":c("#A87F5F")},
	{"k":"S2","base":c("#D9A97F"),"sh":c("#B0855D"),"hi":c("#E9C39B"),"dk":c("#8F6845")},
	{"k":"S3","base":c("#C08E62"),"sh":c("#96683F"),"hi":c("#D3A87C"),"dk":c("#7A5330")},
	{"k":"S4","base":c("#A6714A"),"sh":c("#7C4E2C"),"hi":c("#BC8A60"),"dk":c("#633C1F")},
	{"k":"S5","base":c("#8A5A3A"),"sh":c("#613A20"),"hi":c("#A0704B"),"dk":c("#4C2C16")},
	{"k":"S6","base":c("#6E4429"),"sh":c("#4B2A16"),"hi":c("#835636"),"dk":c("#3A1F0F")},
	{"k":"S7","base":c("#543120"),"sh":c("#381D0F"),"hi":c("#68402A"),"dk":c("#2A1509")},
	{"k":"S8","base":c("#3C2317"),"sh":c("#26140C"),"hi":c("#4E3020"),"dk":c("#1C0E07")},
]
static var HAIRC := [
	{"k":"H1","base":c("#14100E"),"sh":c("#000000"),"hi":c("#2E2A26")},
	{"k":"H2","base":c("#241A14"),"sh":c("#100A07"),"hi":c("#3E3028")},
	{"k":"H3","base":c("#3A2A1E"),"sh":c("#20150E"),"hi":c("#553F2D")},
	{"k":"H4","base":c("#5A3A22"),"sh":c("#3A2312"),"hi":c("#7A5233")},
	{"k":"H5","base":c("#7C5334"),"sh":c("#553520"),"hi":c("#9C6F48")},
	{"k":"H6","base":c("#A87C4A"),"sh":c("#7B5730"),"hi":c("#C39A64")},
	{"k":"H7","base":c("#C9A46E"),"sh":c("#9A7A49"),"hi":c("#E0C08D")},
	{"k":"H8","base":c("#E0D2B4"),"sh":c("#B0A488"),"hi":c("#F2E9D4")},
	{"k":"H9","base":c("#8E9298"),"sh":c("#65696E"),"hi":c("#B4B8BD")},
	{"k":"H10","base":c("#7A2E28"),"sh":c("#521A16"),"hi":c("#9C4740")},
]
static var EYEC := [c("#3A2A1C"), c("#6B4A24"), c("#4E7A4A"), c("#3C6E8E"), c("#6E7A82"), c("#8E6A3C")]
static var CLOTHC := [
	{"base":c("#4A5A72"),"sh":c("#334054"),"hi":c("#63748E")},
	{"base":c("#7A3A38"),"sh":c("#552422"),"hi":c("#98544F")},
	{"base":c("#3E4A3C"),"sh":c("#283227"),"hi":c("#566450")},
	{"base":c("#2C2F33"),"sh":c("#1B1D20"),"hi":c("#41454A")},
	{"base":c("#5A4632"),"sh":c("#3C2E20"),"hi":c("#775F46")},
	{"base":c("#6E6A52"),"sh":c("#4C4938"),"hi":c("#8C876C")},
	{"base":c("#B0B4B8"),"sh":c("#85898D"),"hi":c("#D2D6DA")},
	{"base":c("#C9A227"),"sh":c("#8E7016"),"hi":c("#E4C154")},
]
static var GOLD := c("#C9A227")
static var GOLDD := c("#8E7016")
static var INK := c("#2B3138")
static var LIP := c("#8E5A55")

static var FACES := [
	{"k":"Oval","hw":10,"jw":8,"top":8,"chin":37},
	{"k":"Square","hw":10,"jw":10,"top":8,"chin":36},
	{"k":"Long","hw":9,"jw":8,"top":7,"chin":40},
	{"k":"Wide","hw":11,"jw":10,"top":9,"chin":34},
	{"k":"Angular","hw":10,"jw":6,"top":8,"chin":38},
	{"k":"Heavy","hw":11,"jw":11,"top":8,"chin":37},
]
const BROW_OFF := 11

static var HAIR := ["Bald","Buzz","Skin fade","Waves","Cornrows","Afro","Locs","Braids","Top knot","Curtains","Mullet","Ponytail"]
static var BROWS := ["Flat","Arched","Heavy","Thin","Slit","Knitted"]
static var EYES := ["Level","Hooded","Wide","Narrow","Tired","Sharp"]
static var NOSES := ["Straight","Broad","Hooked","Button","Broken"]
static var MOUTHS := ["Neutral","Set","Smirk","Downturned","Full"]
static var BEARDS := ["None","Stubble","Goatee","Full beard","Chinstrap","Moustache","Muttons"]
static var MARKS := ["None","Brow scar","Cheek scar","Teardrop","Neck ink","Freckles","Split lip"]
static var HEADS := ["None","Cap","Hood up","Durag","Beanie","Bucket hat"]
static var GLASS := ["None","Shades","Clear specs","Half-rim"]
static var CHAINS := ["None","Thin rope","Cuban link","Pendant"]
static var TOPS := ["Tracksuit","Puffer","Hoodie","Tee","Bomber","Vest"]

static var VIEWS := {"full":[0,0,48,60], "bust":[6,2,36,44], "head":[11,3,26,31]}

const DEF := {"face":1,"skin":4,"hair":2,"hairc":2,"brow":2,"eye":0,"eyec":0,"nose":0,
	"mouth":1,"beard":1,"mark":0,"head":0,"glass":0,"chain":1,"top":0,"clothc":0}

# ordered slots (build/hair/face/kit) — used by the creation UI
static func options() -> Dictionary:
	return {
		"face":{"label":"FACE SHAPE","list":_keys(FACES)},
		"skin":{"label":"SKIN","list":_keys(SKIN),"swatch":_bases(SKIN)},
		"hair":{"label":"HAIR","list":HAIR},
		"hairc":{"label":"HAIR COLOUR","list":_keys(HAIRC),"swatch":_bases(HAIRC)},
		"brow":{"label":"BROWS","list":BROWS},
		"eye":{"label":"EYES","list":EYES},
		"eyec":{"label":"EYE COLOUR","list":["E1","E2","E3","E4","E5","E6"],"swatch":EYEC},
		"nose":{"label":"NOSE","list":NOSES},
		"mouth":{"label":"MOUTH","list":MOUTHS},
		"beard":{"label":"FACIAL HAIR","list":BEARDS},
		"mark":{"label":"MARKS","list":MARKS},
		"head":{"label":"HEADWEAR","list":HEADS},
		"glass":{"label":"EYEWEAR","list":GLASS},
		"chain":{"label":"JEWELLERY","list":CHAINS},
		"top":{"label":"CLOTHING","list":TOPS},
		"clothc":{"label":"CLOTH COLOUR","list":["C1","C2","C3","C4","C5","C6","C7","C8"],"swatch":_bases(CLOTHC)},
	}
static func _keys(a: Array) -> Array:
	var o := []
	for e in a: o.append(e.k)
	return o
static func _bases(a: Array) -> Array:
	var o := []
	for e in a: o.append(e.base)
	return o

static func clone(cfg: Dictionary) -> Dictionary: return cfg.duplicate()
static func random() -> Dictionary:
	var o := options(); var cfg := {}
	for k in o.keys():
		cfg[k] = randi() % o[k].list.size()
	return cfg

# ---------- buffer ----------
class Buf:
	var d: PackedColorArray
	func _init() -> void:
		d = PackedColorArray(); d.resize(Doll.W * Doll.H); d.fill(Doll.CLEAR)
	func _ok(x: int, y: int) -> bool: return x >= 0 and x < Doll.W and y >= 0 and y < Doll.H
	func at(x: int, y: int) -> Color: return d[y * Doll.W + x] if _ok(x, y) else Doll.CLEAR
	func has(x: int, y: int) -> bool: return _ok(x, y) and d[y * Doll.W + x].a > 0.0
	func set_px(x: int, y: int, col: Color) -> void:
		x = int(round(x)); y = int(round(y))
		if _ok(x, y): d[y * Doll.W + x] = col
	func rect(x: int, y: int, w: int, h: int, col: Color) -> void:
		for j in range(h):
			for i in range(w): set_px(x + i, y + j, col)
	func row(x1: int, x2: int, y: int, col: Color) -> void:
		rect(min(x1, x2), y, abs(x2 - x1) + 1, 1, col)
	func col_(x: int, y1: int, y2: int, col: Color) -> void:
		rect(x, min(y1, y2), 1, abs(y2 - y1) + 1, col)
	func over(x: int, y: int, col: Color) -> void:
		if has(x, y): set_px(x, y, col)

static func half_at(f: Dictionary, y: int) -> int:
	var cheek: int = f.top + 14
	if y < f.top: return -1
	if y == f.top: return f.hw - 3
	if y == f.top + 1: return f.hw - 1
	if y <= cheek: return f.hw
	if y >= f.chin: return -1
	var t := float(y - cheek) / float(f.chin - cheek)
	var hwv := int(round(f.hw + (f.jw - f.hw) * t))
	if y >= f.chin - 2: hwv = max(2, hwv - 2)
	if y == f.chin - 1: hwv = max(2, hwv - 1)
	return hwv

# ---------- layers ----------
static func _body(b: Buf, cfg: Dictionary, f: Dictionary) -> void:
	var cl: Dictionary = CLOTHC[cfg.clothc]; var s: Dictionary = SKIN[cfg.skin]
	var neckTop: int = f.chin - 1; var sy: int = neckTop + 4
	b.rect(CX - 3, neckTop, 6, 5, s.sh)
	b.rect(CX - 3, neckTop, 3, 5, s.dk)
	for y in range(sy, H):
		var grow: int = min(19, 8 + int(round((y - sy) * 1.4)))
		b.row(CX - grow, CX + grow - 1, y, cl.base)
		b.row(CX + grow - 4, CX + grow - 1, y, cl.sh)
	match int(cfg.top):
		1:
			var y := sy + 3
			while y < H: b.row(CX - 19, CX + 18, y, cl.sh); y += 4
		2:
			b.rect(CX - 6, sy, 13, 3, cl.sh); b.rect(CX - 4, sy + 1, 9, 2, cl.hi)
			b.col_(CX - 3, sy + 3, sy + 9, cl.hi); b.col_(CX + 3, sy + 3, sy + 9, cl.hi)
		3:
			b.rect(CX - 5, sy, 11, 2, cl.sh)
		4:
			b.col_(CX, sy, H - 1, cl.sh); b.col_(CX - 1, sy, H - 1, cl.sh)
			b.rect(CX - 19, H - 3, 38, 3, cl.hi)
		5:
			for y in range(sy, H):
				var grow: int = min(19, 8 + int(round((y - sy) * 1.4)))
				b.row(CX - grow, CX + grow - 1, y, s.sh)
				b.row(CX + grow - 3, CX + grow - 1, y, s.dk)
				var p: int = min(9, 4 + (y - sy))
				b.row(CX - p, CX + p - 1, y, cl.base); b.row(CX + p - 3, CX + p - 1, y, cl.sh)
		_:
			b.row(CX - 4, CX + 3, sy, cl.sh); b.row(CX - 2, CX + 1, sy + 1, cl.sh)
			for y in range(sy + 1, H):
				var grow: int = min(19, 8 + int(round((y - sy) * 1.4)))
				b.col_(CX - grow + 1, y, y, cl.hi); b.col_(CX + grow - 2, y, y, cl.hi)
	if int(cfg.chain) > 0:
		var y := sy + 2
		if cfg.chain == 1:
			b.row(CX - 5, CX + 4, y, GOLD); b.row(CX - 3, CX + 2, y + 1, GOLD)
		elif cfg.chain == 2:
			b.rect(CX - 7, y, 15, 2, GOLDD)
			var x := CX - 7
			while x < CX + 8: b.set_px(x, y, GOLD); x += 2
			b.row(CX - 4, CX + 3, y + 2, GOLD)
		elif cfg.chain == 3:
			b.row(CX - 6, CX + 5, y, GOLD); b.row(CX - 3, CX + 2, y + 2, GOLD)
			b.rect(CX - 2, y + 3, 4, 3, GOLD); b.rect(CX - 1, y + 4, 2, 1, GOLDD)

static func _head(b: Buf, cfg: Dictionary, f: Dictionary) -> void:
	var s: Dictionary = SKIN[cfg.skin]
	for y in range(f.top, f.chin):
		var hw := half_at(f, y)
		if hw < 0: continue
		b.row(CX - hw, CX + hw - 1, y, s.base)
		b.row(CX + hw - 3, CX + hw - 1, y, s.sh)
	var cheek: int = f.top + 14
	b.row(CX - 3, CX + 2, f.top + 2, s.hi)
	b.row(CX - f.hw + 1, CX + f.hw - 2, f.top + 5, s.sh)
	for y in range(f.chin - 4, f.chin):
		var hw := half_at(f, y)
		if hw > 0: b.row(CX - hw, CX - hw + 1, y, s.sh)
	var ehw := half_at(f, cheek - 2)
	b.rect(CX - ehw - 2, cheek - 3, 2, 5, s.sh)
	b.rect(CX + ehw, cheek - 3, 2, 5, s.sh)
	b.col_(CX - ehw - 1, cheek - 2, cheek, s.dk)
	b.col_(CX + ehw, cheek - 2, cheek, s.dk)

static func _brows(b: Buf, cfg: Dictionary, f: Dictionary) -> void:
	var h: Dictionary = HAIRC[cfg.hairc]; var y: int = f.top + BROW_OFF
	var inner := 2; var outer := 5
	for o in [-1, 1]:
		var xs := []
		for i in range(inner, outer + 1): xs.append(CX + o * i - (1 if o < 0 else 0))
		for idx in range(xs.size()):
			var x: int = xs[idx]
			var t := float(idx) / float(xs.size() - 1)
			var dy := 0; var tall := 1
			match int(cfg.brow):
				1: dy = -1 if (t > 0.25 and t < 0.85) else 0
				2: tall = 2
				3: tall = 1
				4: if idx == 3: continue
				5: dy = int(round((1.0 - t) * -1.0)) + (1 if t < 0.3 else 0)
			b.rect(x, y + dy, 1, tall, h.hi if cfg.brow == 3 else h.base)

static func _eye_geom(cfg: Dictionary, f: Dictionary) -> Dictionary:
	var y: int = f.top + BROW_OFF + 3
	var wide := 5 if cfg.eye == 2 else 4
	var tall := 1 if (cfg.eye == 1 or cfg.eye == 3) else 2
	return {"y":y, "wide":wide, "tall":tall, "ix":2}

static func _eyes(b: Buf, cfg: Dictionary, f: Dictionary) -> void:
	var s: Dictionary = SKIN[cfg.skin]; var h: Dictionary = HAIRC[cfg.hairc]; var ec: Color = EYEC[cfg.eyec]
	var g := _eye_geom(cfg, f)
	for o in [-1, 1]:
		var x: int = (CX - g.ix - g.wide) if o < 0 else (CX + g.ix)
		b.rect(x, g.y, g.wide, g.tall, c("#EFE7DA"))
		var px := x + 1
		b.rect(px, g.y, 2, g.tall, ec)
		b.set_px(px + (0 if o < 0 else 1), g.y + g.tall - 1, c("#111111"))
		b.row(x, x + g.wide - 1, g.y - 1, h.sh)
		if cfg.eye == 1: b.row(x, x + g.wide - 1, g.y - 1, s.dk)
		if cfg.eye == 4: b.row(x, x + g.wide - 1, g.y + g.tall, s.dk)
		if cfg.eye == 5: b.set_px((x if o < 0 else x + g.wide - 1), g.y - 1, h.base)

static func _eyes_closed(b: Buf, cfg: Dictionary, f: Dictionary) -> void:
	var s: Dictionary = SKIN[cfg.skin]; var h: Dictionary = HAIRC[cfg.hairc]; var g := _eye_geom(cfg, f)
	for o in [-1, 1]:
		var x: int = (CX - g.ix - g.wide) if o < 0 else (CX + g.ix)
		b.rect(x, g.y - 1, g.wide, g.tall + 1, s.base)
		b.row(x, x + g.wide - 1, g.y, h.sh)

static func _nose(b: Buf, cfg: Dictionary, f: Dictionary) -> void:
	var s: Dictionary = SKIN[cfg.skin]
	var y0: int = f.top + BROW_OFF + 3; var y1: int = y0 + 3
	var w := 3 if cfg.nose == 1 else 2
	var bx := CX - int(w / 2.0) - (0 if w == 3 else 1)
	for y in range(y0, y1 + 1):
		var x := bx
		if cfg.nose == 2 and y > y0 + 1: x = bx - 1
		if cfg.nose == 4 and y == y0 + 2: x = bx + 1
		b.rect(x, y, w, 1, s.sh); b.rect(x + w - 1, y, 1, 1, s.dk)
	var baseW := 5 if cfg.nose == 1 else (3 if cfg.nose == 3 else 4)
	var byy := y1 + 1
	b.rect(CX - int(baseW / 2.0) - 1, byy, baseW, 1, s.sh)
	b.set_px(CX - int(baseW / 2.0) - 1, byy, s.dk)
	b.set_px(CX - int(baseW / 2.0) + baseW - 2, byy, s.dk)
	b.rect(CX - 1, byy - 1, 2, 1, s.hi)

static func _mouth(b: Buf, cfg: Dictionary, f: Dictionary, dark) -> void:
	var s: Dictionary = SKIN[cfg.skin]; var y: int = f.chin - 5
	var ink: Color = dark if dark != null else s.dk
	var mid: Color = dark if dark != null else s.sh
	var w := 5 if cfg.mouth == 3 else 6; var x := CX - int(w / 2.0)
	match int(cfg.mouth):
		1: b.rect(x, y, w, 1, ink); b.rect(x + 1, y + 1, w - 2, 1, mid)
		2: b.rect(x, y, w - 1, 1, ink); b.set_px(x + w - 1, y - 1, ink); b.rect(x + 1, y + 1, w - 3, 1, mid)
		3: b.rect(x + 1, y, w - 2, 1, ink); b.set_px(x, y + 1, ink); b.set_px(x + w - 1, y + 1, ink)
		4: b.rect(x, y, w, 1, ink); b.rect(x, y + 1, w, 1, LIP); b.rect(x + 1, y - 1, w - 2, 1, LIP)
		_: b.rect(x, y, w, 1, ink); b.rect(x + 1, y + 1, w - 2, 1, mid)

static func _beard(b: Buf, cfg: Dictionary, f: Dictionary) -> void:
	if int(cfg.beard) == 0: return
	var h: Dictionary = HAIRC[cfg.hairc]; var mouthY: int = f.chin - 5
	match int(cfg.beard):
		1:
			for y in range(f.top + 13, f.chin):
				var hw := half_at(f, y)
				if hw <= 0: continue
				for x in range(CX - hw, CX + hw):
					if (x + y) % 2 == 0 and y >= f.chin - 7: b.over(x, y, SKIN[cfg.skin].sh)
		2:
			b.rect(CX - 3, mouthY + 2, 7, f.chin - mouthY - 2, h.base)
			b.rect(CX - 4, mouthY - 1, 9, 1, h.base)
		3:
			for y in range(f.top + 13, f.chin):
				var hw := half_at(f, y)
				if hw > 0 and y > f.top + 15: b.row(CX - hw, CX + hw - 1, y, h.base)
			for y in range(f.top + 13, f.top + 17):
				var hw := half_at(f, y)
				b.row(CX - hw, CX - hw + 2, y, h.base); b.row(CX + hw - 3, CX + hw - 1, y, h.base)
			b.rect(CX - 4, mouthY - 1, 9, 1, h.base)
			_mouth(b, cfg, f, h.sh)
		4:
			for y in range(f.top + 13, f.chin):
				var hw := half_at(f, y)
				if hw > 0 and y > f.top + 14:
					b.row(CX - hw, CX - hw + 1, y, h.base); b.row(CX + hw - 2, CX + hw - 1, y, h.base)
			b.rect(CX - 4, f.chin - 2, 9, 2, h.base)
		5:
			b.rect(CX - 4, mouthY - 2, 9, 2, h.base)
		_:
			for y in range(f.top + 12, f.top + 20):
				var hw := half_at(f, y)
				if hw > 0:
					b.row(CX - hw, CX - hw + 2, y, h.base); b.row(CX + hw - 3, CX + hw - 1, y, h.base)

static func _hood_back(b: Buf, cfg: Dictionary, f: Dictionary) -> void:
	var cl: Dictionary = CLOTHC[cfg.clothc]; var hw: int = f.hw; var w := (hw + 1) * 2
	b.rect(CX - hw - 1, f.top - 2, w, 3, cl.base)
	b.rect(CX + hw - 2, f.top - 2, 3, 3, cl.sh)
	b.rect(CX - hw - 1, f.top + 3, 2, f.chin - f.top - 3, cl.base)
	b.rect(CX + hw - 1, f.top + 3, 2, f.chin - f.top - 3, cl.sh)
	b.rect(CX - hw - 1, f.chin + 2, w, 3, cl.base)
	b.rect(CX + hw - 2, f.chin + 2, 3, 3, cl.sh)

static func _hair_back(b: Buf, cfg: Dictionary, f: Dictionary) -> void:
	if int(cfg.hair) == 0: return
	var h: Dictionary = HAIRC[cfg.hairc]; var hw: int = f.hw
	match int(cfg.hair):
		5: b.rect(CX - hw - 4, f.top - 4, (hw + 4) * 2, 16, h.sh)
		6:
			for i in range(-3, 4):
				if i != 0: b.rect(CX + i * 3 - 1, f.top + 4, 2, 26 - abs(i) * 3, h.sh)
		7: b.rect(CX - hw - 3, f.top + 4, 3, 22, h.sh); b.rect(CX + hw, f.top + 4, 3, 22, h.sh)
		8: b.rect(CX - 3, f.top - 4, 7, 5, h.sh); b.rect(CX - 2, f.top - 3, 5, 3, h.base)
		10: b.rect(CX - hw - 1, f.top + 10, (hw + 1) * 2, 18, h.sh)
		11: b.rect(CX + hw, f.top + 6, 3, 16, h.sh); b.rect(CX + hw + 1, f.top + 20, 2, 4, h.sh)

static func _cap(b: Buf, f: Dictionary, h: Dictionary, lift: int, sideTo: int, sideW: int) -> void:
	for y in range(f.top - lift, f.top + 4):
		var hwv: int = max(half_at(f, max(y, f.top)), f.hw - 1)
		var pad := (-1 if y == f.top - lift else 0) if y < f.top else 0
		b.row(CX - hwv - pad, CX + hwv - 1 + pad, y, h.base)
	b.row(CX - f.hw, CX + f.hw - 1, f.top + 4, h.sh)
	if sideTo > 0:
		for y in range(f.top + 5, f.top + sideTo + 1):
			var hwv := half_at(f, y)
			b.row(CX - hwv, CX - hwv + sideW - 1, y, h.base); b.row(CX + hwv - sideW, CX + hwv - 1, y, h.base)
	for y in range(f.top - lift, f.top + 5):
		b.row(CX + f.hw - 3, CX + f.hw - 1, y, h.sh)

static func _hair_front(b: Buf, cfg: Dictionary, f: Dictionary) -> void:
	if int(cfg.hair) == 0:
		b.rect(CX - 3, f.top + 1, 4, 1, SKIN[cfg.skin].hi); return
	var h: Dictionary = HAIRC[cfg.hairc]
	match int(cfg.hair):
		1: _cap(b, f, h, 0, 8, 1)
		2: _cap(b, f, h, 2, 6, 2)
		3:
			_cap(b, f, h, 2, 8, 2)
			var y: int = int(f.top) - 1
			while y <= f.top + 4:
				var x: int = CX - int(f.hw) + 1
				while x < CX + f.hw: b.over(x, y, h.hi); x += 3
				y += 2
		4:
			_cap(b, f, h, 2, 9, 2)
			var x: int = CX - int(f.hw) + 1
			while x < CX + f.hw:
				for y in range(f.top - 2, f.top + 6): b.over(x, y, h.sh)
				x += 3
		5:
			_cap(b, f, h, 4, 6, 3)
			b.rect(CX - f.hw - 4, f.top - 4, 4, 12, h.base); b.rect(CX + f.hw, f.top - 4, 4, 12, h.base)
			b.rect(CX + f.hw + 1, f.top - 4, 3, 12, h.sh)
		6:
			_cap(b, f, h, 1, 6, 2)
			var x: int = CX - int(f.hw) + 1
			while x < CX + f.hw: b.over(x, f.top, h.sh); x += 3
		7:
			_cap(b, f, h, 1, 6, 2)
			var x: int = CX - int(f.hw) + 1
			while x < CX + f.hw:
				var y: int = int(f.top) - 1
				while y <= f.top + 4: b.over(x, y, h.hi); y += 2
				x += 4
		8: _cap(b, f, h, 1, 7, 2)
		9:
			_cap(b, f, h, 3, 9, 3)
			b.col_(CX, f.top - 3, f.top + 8, h.sh); b.col_(CX - 1, f.top - 3, f.top + 8, h.sh)
			b.rect(CX - f.hw, f.top + 6, 4, 3, h.base); b.rect(CX + f.hw - 4, f.top + 6, 4, 3, h.base)
		10: _cap(b, f, h, 2, 8, 2)
		11:
			_cap(b, f, h, 2, 7, 2)
			var x: int = CX - int(f.hw) + 1
			while x < CX + f.hw: b.over(x, f.top + 1, h.sh); x += 2

static func _mark(b: Buf, cfg: Dictionary, f: Dictionary) -> void:
	if int(cfg.mark) == 0: return
	var s: Dictionary = SKIN[cfg.skin]; var browY: int = f.top + BROW_OFF; var cheek: int = f.top + 14
	match int(cfg.mark):
		1: b.col_(CX + 5, browY - 2, browY + 2, s.hi)
		2:
			for i in range(4): b.over(CX - 7 + i, cheek + 3 + i, s.hi)
		3: b.set_px(CX - 5, browY + 5, INK); b.set_px(CX - 5, browY + 6, INK)
		4:
			var y: int = f.chin
			b.rect(CX - 3, y, 2, 3, INK); b.rect(CX + 2, y, 2, 3, INK); b.row(CX - 3, CX + 3, y + 3, INK)
		5:
			for p in [[-5,3],[-3,5],[-6,6],[4,3],[6,5],[2,6]]: b.over(CX + p[0], cheek + p[1], s.sh)
		_: b.rect(CX + 2, f.chin - 6, 1, 2, s.hi)

static func _headwear(b: Buf, cfg: Dictionary, f: Dictionary) -> void:
	if int(cfg.head) == 0: return
	var cl: Dictionary = CLOTHC[cfg.clothc]; var hw: int = f.hw
	match int(cfg.head):
		1:
			b.rect(CX - hw, f.top - 3, hw * 2, 8, cl.base); b.rect(CX + hw - 3, f.top - 3, 3, 8, cl.sh)
			b.rect(CX - hw - 1, f.top + 5, hw * 2 + 2, 2, cl.sh); b.rect(CX + hw + 1, f.top + 5, 7, 2, cl.sh)
			b.rect(CX - hw + 2, f.top - 2, hw, 1, cl.hi)
		2:
			b.rect(CX - hw - 3, f.top - 3, (hw + 3) * 2, 6, cl.base); b.rect(CX + hw, f.top - 3, 3, 6, cl.sh)
			b.rect(CX - hw - 3, f.top + 3, 3, 22, cl.base); b.rect(CX + hw, f.top + 3, 3, 22, cl.sh)
			b.rect(CX - hw - 2, f.top - 2, (hw + 2) * 2, 1, cl.hi)
		3:
			b.rect(CX - hw, f.top - 1, hw * 2, 7, cl.base); b.rect(CX + hw - 3, f.top - 1, 3, 7, cl.sh)
			b.rect(CX + hw - 1, f.top + 6, 3, 9, cl.sh)
		4:
			b.rect(CX - hw, f.top - 4, hw * 2, 9, cl.base); b.rect(CX + hw - 3, f.top - 4, 3, 9, cl.sh)
			b.rect(CX - hw - 1, f.top + 3, hw * 2 + 2, 3, cl.hi)
		_:
			b.rect(CX - hw, f.top - 3, hw * 2, 8, cl.base); b.rect(CX + hw - 3, f.top - 3, 3, 8, cl.sh)
			b.rect(CX - hw - 5, f.top + 5, hw * 2 + 10, 2, cl.sh)

static func _glass(b: Buf, cfg: Dictionary, f: Dictionary) -> void:
	if int(cfg.glass) == 0: return
	var g := _eye_geom(cfg, f); var hw := half_at(f, g.y)
	var lx: int = CX - g.ix - g.wide - 1; var rx: int = CX + g.ix - 1; var wide: int = g.wide + 2
	if cfg.glass == 1:
		b.rect(lx + 1, g.y, wide - 1, g.tall + 1, c("#171A1E"))
		b.rect(rx + 1, g.y, wide - 1, g.tall + 1, c("#171A1E"))
		b.set_px(lx + 2, g.y, c("#4E5A64")); b.set_px(rx + 2, g.y, c("#4E5A64"))
		b.row(lx + wide, rx, g.y, c("#171A1E"))
		b.row(CX - hw, lx, g.y, c("#171A1E")); b.row(rx + wide, CX + hw - 1, g.y, c("#171A1E"))
	elif cfg.glass == 2:
		for x in [lx, rx + 1]:
			b.row(x, x + wide - 1, g.y - 1, INK); b.row(x, x + wide - 1, g.y + g.tall, INK)
			b.col_(x, g.y - 1, g.y + g.tall, INK); b.col_(x + wide - 1, g.y - 1, g.y + g.tall, INK)
		b.row(lx + wide, rx, g.y - 1, INK)
		b.row(CX - hw, lx - 1, g.y - 1, INK); b.row(rx + wide + 1, CX + hw - 1, g.y - 1, INK)
	else:
		b.row(lx, lx + wide - 1, g.y - 1, INK); b.row(rx + 1, rx + wide, g.y - 1, INK)
		b.row(lx + wide, rx, g.y - 1, INK)
		b.row(CX - hw, lx - 1, g.y - 1, INK); b.row(rx + wide + 1, CX + hw - 1, g.y - 1, INK)

# ---------- arms & poses (combat) ----------
## A chunky limb segment — a 3px-thick line of blocks from a→b.
static func _limb(b: Buf, x0: int, y0: int, x1: int, y1: int, col: Color) -> void:
	var steps: int = max(abs(x1 - x0), abs(y1 - y0))
	if steps == 0:
		b.rect(x0 - 1, y0 - 1, 3, 3, col); return
	for i in range(steps + 1):
		var t := float(i) / float(steps)
		var x := int(round(lerp(float(x0), float(x1), t)))
		var y := int(round(lerp(float(y0), float(y1), t)))
		b.rect(x - 1, y - 1, 3, 3, col)

## Idle / punching arms. `ext` 0..1 extends the right arm into a strike toward the
## opponent (the sprite is mirrored for the rival, so it always reaches the middle).
static func _arms_low(b: Buf, cfg: Dictionary, f: Dictionary, ext: float) -> void:
	var s: Dictionary = SKIN[cfg.skin]
	var cl: Dictionary = CLOTHC[cfg.clothc]
	var sy: int = f.chin + 3
	var shY: int = sy + 2
	# left arm always rests at the side
	_limb(b, CX - 9, shY, CX - 9, shY + 11, cl.sh)
	b.rect(CX - 10, shY + 11, 3, 3, s.base)
	if ext <= 0.02:
		# right arm rests too
		_limb(b, CX + 8, shY, CX + 8, shY + 11, cl.sh)
		b.rect(CX + 8, shY + 11, 3, 3, s.base)
		return
	# right arm throws: elbow straightens, fist travels out and up to head height
	var fx: int = int(round(CX + 8 + ext * 15.0))
	var fy: int = int(round(shY - ext * 8.0))
	var mx: int = int(round(CX + 8 + ext * 7.0))
	var my: int = int(round(shY + 1 - ext * 3.0))
	_limb(b, CX + 7, shY, mx, my, cl.base)      # upper arm
	_limb(b, mx, my, fx, fy, cl.base)           # forearm
	b.rect(fx - 1, fy - 1, 4, 4, s.base)        # fist
	b.rect(fx, fy, 2, 2, s.hi)

## Face covering worn on the doll — reflects an equipped face item (guide gear).
## fw: 1 gaiter/snood · 2 mask · 3 balaclava · 4 respirator · 5 scarf.
static func _facewear(b: Buf, cfg: Dictionary, f: Dictionary) -> void:
	var fw := int(cfg.get("facewear", 0))
	if fw == 0: return
	var cl: Dictionary = CLOTHC[cfg.clothc]
	if fw == 3:
		var black := {"base": c("#1A1C1F"), "sh": c("#101215"), "hi": c("#2A2E33")}
		for y in range(f.top, f.chin):
			var hw := half_at(f, y)
			if hw < 0: continue
			if y >= f.top + BROW_OFF + 2 and y <= f.top + BROW_OFF + 4: continue   # eye slit
			b.row(CX - hw, CX + hw - 1, y, black.base)
			b.row(CX + hw - 3, CX + hw - 1, y, black.sh)
		return
	var top: int = f.top + BROW_OFF + (2 if fw == 5 else 3)
	for y in range(top, f.chin + 2):
		var hw := half_at(f, min(y, f.chin - 1))
		if hw < 0: hw = int(f.jw)
		b.row(CX - hw, CX + hw - 1, y, cl.base)
		b.row(CX + hw - 3, CX + hw - 1, y, cl.sh)
	var thw := half_at(f, top)
	if thw > 0: b.row(CX - thw, CX + thw - 1, top, cl.hi)
	if fw == 2 or fw == 4:
		for y in range(top + 1, f.chin, 2):
			var hw := half_at(f, min(y, f.chin - 1))
			if hw > 1: b.row(CX - hw + 1, CX + hw - 2, y, cl.sh)
	if fw == 4:
		var mid := half_at(f, top + 2)
		if mid > 0:
			b.rect(CX - mid - 3, top + 1, 3, 4, INK); b.rect(CX + mid, top + 1, 3, 4, INK)
	if fw == 5:
		b.rect(CX - 6, f.chin + 1, 4, 6, cl.base); b.rect(CX - 6, f.chin + 1, 4, 1, cl.hi)

## Both fists up at the temples, forearms rising along the jaw — the guard pose.
static func _arms_guard(b: Buf, cfg: Dictionary, f: Dictionary) -> void:
	var s: Dictionary = SKIN[cfg.skin]
	var cl: Dictionary = CLOTHC[cfg.clothc]
	var top: int = f.top + 10
	var bot: int = f.chin + 4
	# forearms up the outside of the face
	b.rect(CX - f.hw - 3, top, 3, bot - top, cl.base); b.rect(CX - f.hw - 3, top, 3, 1, cl.hi)
	b.rect(CX + f.hw, top, 3, bot - top, cl.base); b.rect(CX + f.hw, top, 3, 1, cl.hi)
	# fists at temple height, knuckles toward the face
	b.rect(CX - f.hw - 4, top - 2, 5, 5, s.base); b.rect(CX - f.hw - 4, top - 2, 5, 1, s.hi)
	b.rect(CX + f.hw - 1, top - 2, 5, 5, s.base); b.rect(CX + f.hw - 1, top - 2, 5, 1, s.hi)

# ---------- assembly ----------
static func build(cfg: Dictionary, closed := false, pose := {}) -> Buf:
	var f: Dictionary = FACES[cfg.face]
	var b := Buf.new()
	var ext := float(pose.get("ext", 0.0))
	var guard := bool(pose.get("guard", false))
	var arms := bool(pose.get("arms", false)) or ext > 0.0 or guard
	_hair_back(b, cfg, f)
	if int(cfg.head) == 2: _hood_back(b, cfg, f)
	_body(b, cfg, f)
	if arms and not guard: _arms_low(b, cfg, f, ext)
	_head(b, cfg, f)
	_brows(b, cfg, f)
	if closed: _eyes_closed(b, cfg, f)
	else: _eyes(b, cfg, f)
	_nose(b, cfg, f)
	_mouth(b, cfg, f, null)
	_beard(b, cfg, f)
	_mark(b, cfg, f)
	if int(cfg.get("facewear", 0)) > 0: _facewear(b, cfg, f)
	_hair_front(b, cfg, f)
	_headwear(b, cfg, f)
	_glass(b, cfg, f)
	if guard: _arms_guard(b, cfg, f)
	return b

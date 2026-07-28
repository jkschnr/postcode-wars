#!/usr/bin/env python3
"""Procedural pixel-art asset generator for ENDS / Postcode Wars.
Papers, Please style: low-res, limited palette, desaturated, dithered, sepia.
Outputs game assets to godot/art/ and preview montages to the scratchpad.
No AI/diffusion — pure algorithmic pixel art (swap for AI later if wired up)."""

import os, random, math
from PIL import Image, ImageDraw, ImageEnhance, ImageOps, ImageFilter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ART = os.path.join(ROOT, "art")
for sub in ("portraits", "cities", "gear", "ui"):
    os.makedirs(os.path.join(ART, sub), exist_ok=True)

PAPER = (199, 187, 144)

# ---------- shared post-processing: the Papers, Please grade ----------
BAYER = [[0,8,2,10],[12,4,14,6],[3,11,1,9],[15,7,13,5]]

def grade(img, sepia=0.14, sat=0.42, posterize=3, dither=True):
    img = img.convert("RGB")
    img = ImageEnhance.Color(img).enhance(sat)
    img = ImageEnhance.Contrast(img).enhance(1.08)
    img = Image.blend(img, Image.new("RGB", img.size, PAPER), sepia)
    if dither:
        px = img.load(); w, h = img.size
        for y in range(h):
            for x in range(w):
                t = (BAYER[y % 4][x % 4] / 16.0 - 0.5) * 18
                r, g, b = px[x, y]
                px[x, y] = (max(0, min(255, int(r + t))),
                            max(0, min(255, int(g + t))),
                            max(0, min(255, int(b + t))))
    return ImageOps.posterize(img, posterize)

# ---------- palettes ----------
SKINS = [(196,150,112),(168,124,90),(150,106,74),(120,84,58),(210,170,138),(96,66,46)]
HAIRS = [(30,24,18),(58,40,26),(96,70,44),(150,120,80),(40,40,44),(120,60,40),(180,180,175)]
CLOTHS = [(58,62,54),(70,58,48),(48,54,64),(64,48,48),(52,60,58),(40,40,46),(84,74,54)]
BGS = [(96,96,86),(104,100,84),(88,94,90),(110,102,88),(92,88,80)]

def portrait(seed, W=56, H=72):
    r = random.Random(seed * 977 + 13)
    bg = r.choice(BGS)
    img = Image.new("RGB", (W, H), bg)
    d = ImageDraw.Draw(img)
    d.rectangle([0,0,W,H], outline=(bg[0]-12,bg[1]-12,bg[2]-12))
    skin = r.choice(SKINS); sh = tuple(int(c*0.8) for c in skin)
    hair = r.choice(HAIRS); cloth = r.choice(CLOTHS); cx = W//2
    d.polygon([(cx-24,H),(cx-16,H-20),(cx+16,H-20),(cx+24,H)], fill=cloth)
    d.rectangle([cx-16,H-22,cx+16,H-12], fill=cloth)
    d.polygon([(cx-8,H-22),(cx,H-14),(cx+8,H-22)], fill=tuple(int(c*0.85) for c in cloth))
    d.rectangle([cx-5,H-26,cx+5,H-16], fill=sh)
    hy0, hy1 = 12, 50
    d.ellipse([cx-15,hy0,cx+15,hy1], fill=skin)
    d.ellipse([cx-18,28,cx-12,38], fill=skin); d.ellipse([cx+12,28,cx+18,38], fill=skin)
    d.arc([cx-15,hy0,cx+15,hy1], 20, 160, fill=sh)
    style = r.randint(0, 4)
    if style != 4 or hair == HAIRS[-1]:
        top = 8 + r.randint(-2, 2)
        d.ellipse([cx-16,top,cx+16,top+22], fill=hair)
        if style == 0:
            d.rectangle([cx-16,top+8,cx+16,22], fill=hair)
        elif style == 1:
            d.rectangle([cx-17,top+8,cx-12,50], fill=hair)
            d.rectangle([cx+12,top+8,cx+17,50], fill=hair)
            d.rectangle([cx-16,top+8,cx+16,26], fill=hair)
        elif style == 2:
            d.rectangle([cx-15,top+4,cx+15,20], fill=hair)
        elif style == 3:
            hood = r.choice(CLOTHS)
            d.polygon([(cx-20,26),(cx-15,6),(cx+15,6),(cx+20,26)], fill=hood)
            d.ellipse([cx-15,hy0,cx+15,hy1], fill=skin)
            d.ellipse([cx-13,10,cx+13,26], fill=hair)
    brow = tuple(int(c*0.6) for c in hair); ey = 30
    d.line([cx-11,ey-4,cx-4,ey-4], fill=brow); d.line([cx+4,ey-4,cx+11,ey-4], fill=brow)
    d.rectangle([cx-9,ey,cx-6,ey+2], fill=(28,24,20)); d.rectangle([cx+6,ey,cx+9,ey+2], fill=(28,24,20))
    d.line([cx,ey+2,cx-1,ey+8], fill=sh); d.point([cx-1,ey+9], fill=sh)
    my = ey + 13
    if r.random() < 0.3:
        d.line([cx-5,my,cx,my+1], fill=(90,54,48)); d.line([cx,my+1,cx+5,my], fill=(90,54,48))
    else:
        d.line([cx-5,my,cx+5,my], fill=(96,58,50))
    if r.random() < 0.45:
        for _ in range(40):
            sx = r.randint(cx-12, cx+12); sy = r.randint(40, 49)
            if (sx-cx)**2/144 + (sy-31)**2/361 < 1:
                d.point([sx,sy], fill=sh)
    return grade(img)

# ---------- named cast: distinct, seeded, one signifier each (brief §4) ----------
CAST_SPECS = {
    "uncle_t": dict(seed=101, skin=3, hair=6, hairstyle="short", age=61, cloth=(70,64,52),  bg=(96,88,70),  extra="apron",    stubble=True),
    "silas":   dict(seed=102, skin=4, hair=6, hairstyle="side",  age=54, cloth=(80,76,66),  bg=(100,100,98), extra="cardigan", glasses=True),
    "nads":    dict(seed=103, skin=2, hair=1, hairstyle="bun",   age=22, cloth=(64,48,52),  bg=(112,92,80),  extra=None,       smile=True, earrings=True),
    "kayo":    dict(seed=104, skin=2, hair=0, hairstyle="fade",  age=26, cloth=(142,142,138),bg=(78,82,86),  extra="prison",   stubble=True),
}

def cast_portrait(spec, W=56, H=72):
    r = random.Random(spec["seed"])
    bg = spec.get("bg", (96,96,86))
    img = Image.new("RGB", (W, H), bg); d = ImageDraw.Draw(img)
    d.rectangle([0,0,W-1,H-1], outline=tuple(c-12 for c in bg))
    skin = SKINS[spec["skin"]]; sh = tuple(int(c*0.8) for c in skin)
    hair = HAIRS[spec["hair"]]; cloth = spec.get("cloth", (58,62,54)); cx = W//2
    extra = spec.get("extra")
    # shoulders / torso
    d.polygon([(cx-24,H),(cx-16,H-20),(cx+16,H-20),(cx+24,H)], fill=cloth)
    d.rectangle([cx-16,H-22,cx+16,H-12], fill=cloth)
    if extra == "cardigan":
        d.polygon([(cx-6,H-22),(cx,H-8),(cx+6,H-22)], fill=(210,205,188))   # shirt V
        d.polygon([(cx-16,H-22),(cx-4,H-22),(cx,H-9),(cx-16,H-10)], fill=tuple(int(c*0.9) for c in cloth))
        d.polygon([(cx+16,H-22),(cx+4,H-22),(cx,H-9),(cx+16,H-10)], fill=tuple(int(c*0.9) for c in cloth))
    elif extra == "apron":
        d.rectangle([cx-11,H-22,cx+11,H-4], fill=(150,146,130))
        d.line([cx-11,H-22,cx-6,H-27], fill=(150,146,130)); d.line([cx+11,H-22,cx+6,H-27], fill=(150,146,130))
    elif extra == "prison":
        d.polygon([(cx-9,H-22),(cx,H-13),(cx+9,H-22)], fill=(158,158,152))
    else:
        d.polygon([(cx-8,H-22),(cx,H-14),(cx+8,H-22)], fill=tuple(int(c*0.85) for c in cloth))
    # head
    hy0, hy1 = 12, 50
    d.ellipse([cx-15,hy0,cx+15,hy1], fill=skin)
    d.ellipse([cx-18,28,cx-12,38], fill=skin); d.ellipse([cx+12,28,cx+18,38], fill=skin)
    d.arc([cx-15,hy0,cx+15,hy1], 20, 160, fill=sh)
    # hair
    hs = spec.get("hairstyle","short"); top = 8
    if hs == "bun":
        d.ellipse([cx-6,1,cx+6,11], fill=hair)
        d.ellipse([cx-16,top,cx+16,top+20], fill=hair)
        d.ellipse([cx-15,hy0+1,cx+15,hy1], fill=skin)
        d.rectangle([cx-16,top+5,cx+16,19], fill=hair)
        d.ellipse([cx-15,10,cx+15,24], fill=hair)
    elif hs == "fade":
        d.ellipse([cx-14,top+3,cx+14,21], fill=hair)
        d.rectangle([cx-13,top+8,cx+13,17], fill=hair)
    elif hs == "side":
        d.ellipse([cx-16,top,cx+16,top+20], fill=hair)
        d.rectangle([cx-16,top+6,cx+16,19], fill=hair)
        d.polygon([(cx-16,13),(cx+4,11),(cx+16,17),(cx-16,20)], fill=tuple(int(c*0.88) for c in hair))
    else:
        d.ellipse([cx-15,top+2,cx+15,22], fill=hair)
        d.rectangle([cx-15,top+8,cx+15,18], fill=hair)
    # brows + eyes
    brow = tuple(int(c*0.6) for c in hair); ey = 30
    d.line([cx-11,ey-4,cx-4,ey-4], fill=brow); d.line([cx+4,ey-4,cx+11,ey-4], fill=brow)
    d.rectangle([cx-9,ey,cx-6,ey+2], fill=(28,24,20)); d.rectangle([cx+6,ey,cx+9,ey+2], fill=(28,24,20))
    d.line([cx,ey+2,cx-1,ey+8], fill=sh)
    if spec.get("glasses"):
        gcol = (36,32,28)
        d.rectangle([cx-11,ey-2,cx-3,ey+4], outline=gcol)
        d.rectangle([cx+3,ey-2,cx+11,ey+4], outline=gcol)
        d.line([cx-3,ey,cx+3,ey], fill=gcol)
    my = ey + 13
    if spec.get("age",30) > 50:
        d.line([cx-6,my-2,cx-1,my-2], fill=tuple(int(c*0.7) for c in hair))
        d.line([cx+1,my-2,cx+6,my-2], fill=tuple(int(c*0.7) for c in hair))
        d.line([cx-10,ey+6,cx-7,ey+7], fill=sh); d.line([cx+7,ey+7,cx+10,ey+6], fill=sh)
    if spec.get("smile"):
        d.arc([cx-5,my-4,cx+5,my+3], 20, 160, fill=(120,72,62))
    else:
        d.line([cx-5,my,cx+5,my], fill=(96,58,50))
    if spec.get("earrings"):
        d.ellipse([cx-18,37,cx-15,41], outline=(200,180,120)); d.ellipse([cx+15,37,cx+18,41], outline=(200,180,120))
    if spec.get("stubble"):
        for _ in range(46):
            sx = r.randint(cx-12, cx+12); sy = r.randint(40, 49)
            if (sx-cx)**2/144 + (sy-31)**2/361 < 1:
                d.point([sx,sy], fill=sh)
    return grade(img)

def city(name, W=200, H=120):
    r = random.Random(abs(hash(name)) & 0xffffff)
    img = Image.new("RGB", (W, H))
    dd = ImageDraw.Draw(img)
    # overcast sky, warmer near horizon
    for y in range(H):
        t = y / H
        dd.line([(0,y),(W,y)], fill=(int(64+t*26), int(64+t*20), int(66+t*12)))
    # hazy moon
    mx, my = r.randint(int(W*0.15), int(W*0.85)), r.randint(10, 26)
    for rr in range(16, 0, -1):
        a = (16-rr)/16 * 0.5
        dd.ellipse([mx-rr,my-rr,mx+rr,my+rr], fill=(int(120*a+64), int(118*a+62), int(104*a+62)))
    ground = int(H*0.80)
    # three depth layers of buildings, far→near darker & taller
    for layer, (lo, hi, dark, wnd) in enumerate([(18,int(H*0.40),0.62,0.0),(24,int(H*0.55),0.44,0.35),(28,int(H*0.68),0.28,0.55)]):
        x = -8
        while x < W:
            bw = r.randint(16, 40); bh = r.randint(lo, hi)
            base = int(40*dark)+20
            c = (base+r.randint(-6,6), base+r.randint(-8,4)-2, base+r.randint(-8,2)-4)
            top = ground - bh
            dd.rectangle([x, top, x+bw, ground], fill=c)
            if wnd:
                for wy in range(top+4, ground-3, 6):
                    for wx in range(x+3, x+bw-2, 5):
                        if r.random() < wnd:
                            lit = r.random() < 0.24
                            dd.rectangle([wx,wy,wx+2,wy+3], fill=(201,158,74) if lit else (22,20,18))
            if layer == 2 and r.random() < 0.18:  # smokestacks / aerials
                sx = x + bw//2
                dd.rectangle([sx-1, top-r.randint(8,18), sx+1, top], fill=(34,30,26))
            x += bw + r.randint(1,4)
    # a faint landmark silhouette centre-back (tower/crane)
    lx = int(W*0.5) + r.randint(-30,30)
    if r.random() < 0.7:
        dd.rectangle([lx-3, ground-int(H*0.62), lx+3, ground], fill=(30,27,24))
        dd.line([lx, ground-int(H*0.62), lx+r.randint(-16,16), ground-int(H*0.5)], fill=(30,27,24))  # crane arm
    # wet road + puddle reflections
    dd.rectangle([0, ground, W, H], fill=(26,24,22))
    for _ in range(24):
        gx = r.randint(0,W); dd.point([gx, r.randint(ground+2,H-1)], fill=(58,54,42))
    for lx2 in range(24, W, 40):
        dd.rectangle([lx2-1, ground-3, lx2+1, ground-1], fill=(201,158,74))
        dd.line([lx2, ground, lx2, min(H-1,ground+6)], fill=(120,96,50))  # reflection
    # rain streaks
    for _ in range(90):
        rx = r.randint(0, W); ry = r.randint(0, ground)
        ImageDraw.Draw(img).line([(rx,ry),(rx-2,ry+5)], fill=(150,156,150), width=1)
    img = Image.blend(img, Image.new("RGB",(W,H),(150,156,150)), 0.0)
    return grade(img, sat=0.5, posterize=3)

def gear_icon(name, W=48, H=48):
    img = Image.new("RGB", (W, H), (58,52,40)); d = ImageDraw.Draw(img)
    d.rectangle([0,0,W-1,H-1], outline=(110,98,70))
    c1=(168,156,120); c2=(120,106,74); steel=(172,174,170); dark=(34,30,26)
    if name=="gloves":
        for off in (-10,4):
            d.rounded_rectangle([22+off,16,22+off+9,34],3,fill=c2,outline=dark)
            d.rectangle([22+off,12,22+off+9,18],fill=c2)
    elif name=="bally":
        d.ellipse([12,8,36,42],fill=(72,68,60),outline=dark); d.rectangle([16,21,32,25],fill=(214,208,186))
    elif name=="shank":
        d.polygon([(16,34),(30,12),(33,15),(20,36)],fill=steel); d.rectangle([15,33,22,40],fill=c2)
    elif name=="rambo":
        d.polygon([(12,36),(34,8),(38,12),(18,38)],fill=steel); d.rectangle([10,34,20,42],fill=c2)
    elif name=="stab_vest":
        d.polygon([(13,13),(35,13),(35,38),(24,43),(13,38)],fill=(92,98,84),outline=dark)
        d.line([24,13,24,43],fill=dark); d.rectangle([16,18,20,30],fill=(120,126,110))
    elif name=="burner":
        d.rounded_rectangle([17,10,31,40],3,fill=(30,30,34)); d.rectangle([19,14,29,32],fill=(90,120,110))
    else:
        d.ellipse([14,14,34,34],fill=c1)
    return grade(img, sat=0.5, posterize=4, dither=False)

# ---------- territorial war-map (realistic UK + Ireland, owner-shaded) ----------
import json as _json
_TERR = _json.load(open(os.path.join(ROOT, "data", "territories.json")))
MAP_BASES_D = _TERR["bases"]
OWNER_LAND = {
	"player": (150, 118, 50), "red": (122, 60, 50), "blue": (58, 86, 112),
	"purple": (98, 72, 98), "neutral": (98, 112, 76),
}
LAND_BASE = (112, 116, 84)
# Real-world coastline projected through one linear lon/lat window so the
# silhouette AND the city pins (data/territories.json) share the same frame.
PROJ = {"lon0": -8.6, "lon1": 2.2, "lat0": 59.0, "lat1": 49.7}
def _proj(lon, lat):
	x = (lon - PROJ["lon0"]) / (PROJ["lon1"] - PROJ["lon0"])
	y = (PROJ["lat0"] - lat) / (PROJ["lat0"] - PROJ["lat1"])
	return (x, y)
# Great Britain coast, clockwise from the far north (Dunnet Head), down the
# EAST coast, round the south, and back up the WEST coast. lon, lat pairs.
_GB_LL = [
	(-3.40,58.67),(-2.00,57.70),(-2.10,57.15),(-2.90,56.45),(-2.58,56.28),
	(-3.18,56.05),(-2.10,55.90),(-1.62,55.00),(-1.13,54.60),(-0.40,54.28),
	(-0.08,54.12),(0.13,53.58),(-0.25,53.72),(0.20,53.20),(0.35,52.99),
	(0.15,52.86),(0.55,52.97),(1.30,52.93),(1.73,52.60),(1.75,52.48),
	(1.58,52.10),(1.28,51.95),(0.95,51.62),(0.55,51.52),(1.42,51.38),
	(1.35,51.13),(0.97,50.91),(0.25,50.74),(-0.50,50.78),(-1.40,50.72),
	(-2.45,50.60),(-3.10,50.42),(-3.55,50.30),(-4.15,50.35),(-5.05,50.10),
	(-5.20,49.96),(-5.72,50.07),(-4.55,51.00),(-4.20,51.18),(-2.95,51.38),
	(-3.20,51.48),(-4.30,51.62),(-5.30,51.70),(-4.75,52.13),(-4.75,52.80),
	(-4.20,53.30),(-3.10,53.35),(-3.05,53.42),(-3.05,54.10),(-3.60,54.50),
	(-3.80,54.85),(-4.86,54.63),(-4.80,55.30),(-5.80,55.30),(-5.10,55.75),
	(-5.30,56.00),(-6.20,56.73),(-5.70,57.30),(-5.16,57.90),(-5.00,58.63),
]
# Ireland — only its east/north shows; the west runs off the frame (realistic).
_IE_LL = [
	(-6.00,55.20),(-5.90,54.60),(-6.05,54.05),(-6.20,52.80),(-7.60,51.90),
	(-9.50,51.60),(-10.20,52.10),(-9.90,53.40),(-9.90,54.20),(-8.50,55.20),
	(-7.30,55.40),
]
GB_OUTLINE = [_proj(lon, lat) for lon, lat in _GB_LL]
IE_OUTLINE = [_proj(lon, lat) for lon, lat in _IE_LL]

def _grade_map(img):
	img = ImageEnhance.Color(img).enhance(0.72)
	img = ImageEnhance.Contrast(img).enhance(1.05)
	img = Image.blend(img, Image.new("RGB", img.size, PAPER), 0.05)
	return ImageOps.posterize(img, 6)

def uk_map(W=560, H=820):
	gbm = Image.new("L", (W, H), 0)
	ImageDraw.Draw(gbm).polygon([(x*W, y*H) for x, y in GB_OUTLINE], fill=255)
	iem = Image.new("L", (W, H), 0)
	ImageDraw.Draw(iem).polygon([(x*W, y*H) for x, y in IE_OUTLINE], fill=255)
	land = Image.new("L", (W, H), 0)
	land.paste(255, (0, 0), gbm); land.paste(255, (0, 0), iem)
	shelf = land.filter(ImageFilter.MaxFilter(15))
	gpx = gbm.load(); ipx = iem.load(); lpx = land.load(); shx = shelf.load()
	bases = [(b["x"]*W, b["y"]*H, OWNER_LAND[b["owner"]]) for b in MAP_BASES_D]
	img = Image.new("RGB", (W, H))
	for y in range(H):
		t = y / H
		ImageDraw.Draw(img).line([(0, y), (W, y)], fill=(int(28+t*10), int(42+t*12), int(54+t*12)))
	px = img.load()
	region = [[-1]*W for _ in range(H)]
	rng = random.Random(7)
	for y in range(H):
		for x in range(W):
			if lpx[x, y] == 0:
				if shx[x, y] > 0:
					px[x, y] = (46, 64, 76)   # coastal shelf
				continue
			relief = rng.randint(-7, 7)
			if ipx[x, y] > 0 and gpx[x, y] == 0:
				# Ireland — neutral land, not partitioned
				c = OWNER_LAND["neutral"]
				px[x, y] = (int(LAND_BASE[0]*0.6+c[0]*0.4)+relief, int(LAND_BASE[1]*0.6+c[1]*0.4)+relief, int(LAND_BASE[2]*0.6+c[2]*0.4)+relief)
				continue
			best = 0; bd = 1e18
			for i in range(len(bases)):
				dx = x-bases[i][0]; dy = y-bases[i][1]; d = dx*dx+dy*dy
				if d < bd: bd = d; best = i
			region[y][x] = best
			oc = bases[best][2]
			px[x, y] = (
				max(0, min(255, int(LAND_BASE[0]*0.52+oc[0]*0.48)+relief)),
				max(0, min(255, int(LAND_BASE[1]*0.52+oc[1]*0.48)+relief)),
				max(0, min(255, int(LAND_BASE[2]*0.52+oc[2]*0.48)+relief)))
	# subtle relief hills
	dd = ImageDraw.Draw(img)
	for _ in range(90):
		hx = rng.randint(2, W-3); hy = rng.randint(2, H-3)
		if lpx[hx, hy] > 0:
			dd.ellipse([hx-5, hy-2, hx+5, hy+2], outline=(70, 72, 54))
	# region borders (GB only)
	for y in range(1, H-1):
		for x in range(1, W-1):
			r = region[y][x]
			if r == -1: continue
			if region[y][x+1] != r or region[y+1][x] != r or region[y][x-1] != r or region[y-1][x] != r:
				px[x, y] = (54, 48, 34)
	# coastline
	for y in range(1, H-1):
		for x in range(1, W-1):
			if lpx[x, y] > 0 and (lpx[x-1, y] == 0 or lpx[x+1, y] == 0 or lpx[x, y-1] == 0 or lpx[x, y+1] == 0):
				px[x, y] = (26, 28, 22)
	return _grade_map(img)

# ---------- UI overlays (RGBA) ----------
def grain_tile(N=128):
    img = Image.new("RGBA", (N, N), (0,0,0,0)); px = img.load()
    r = random.Random(99)
    for y in range(N):
        for x in range(N):
            v = r.random()
            if v < 0.06:   px[x,y] = (0,0,0, r.randint(18,46))       # dark speck
            elif v > 0.965: px[x,y] = (230,222,190, r.randint(10,28)) # light speck
    return img

def vignette(N=256):
    img = Image.new("RGBA", (N, N), (0,0,0,0)); px = img.load()
    c = N/2.0
    for y in range(N):
        for x in range(N):
            d = math.hypot(x-c, y-c) / (c*1.42)
            a = max(0.0, (d-0.45)/0.55)
            px[x,y] = (12,9,6, int(min(1.0, a) * 165))
    return img

# ---------- generate ----------
CITIES = ["london","manchester","birmingham","liverpool","leeds","glasgow","nottingham","bristol","newcastle"]
GEAR = ["gloves","bally","shank","rambo","stab_vest","burner"]

portraits = [portrait(i) for i in range(16)]
for i, p in enumerate(portraits):
    p.save(os.path.join(ART, "portraits", f"p{i:02d}.png"))
os.makedirs(os.path.join(ART, "portraits", "cast"), exist_ok=True)
cast_imgs = {}
for cid, spec in CAST_SPECS.items():
    im = cast_portrait(spec)
    cast_imgs[cid] = im
    im.save(os.path.join(ART, "portraits", "cast", f"{cid}.png"))
for name in CITIES:
    city(name).save(os.path.join(ART, "cities", f"{name}.png"))
for g in GEAR:
    gear_icon(g).save(os.path.join(ART, "gear", f"{g}.png"))
grain_tile().save(os.path.join(ART, "ui", "grain.png"))
vignette().save(os.path.join(ART, "ui", "vignette.png"))
uk_map().save(os.path.join(ART, "ui", "ukmap.png"))

# ---------- preview montages ----------
def sheet(imgs, cols, path, scale=4, pad=6):
    if not imgs: return
    w=imgs[0].width*scale; h=imgs[0].height*scale
    rows=(len(imgs)+cols-1)//cols
    sh=Image.new("RGB",(cols*(w+pad)+pad, rows*(h+pad)+pad),(20,16,12))
    for i,im in enumerate(imgs):
        sh.paste(im.convert("RGB").resize((w,h),Image.NEAREST),(pad+(i%cols)*(w+pad),pad+(i//cols)*(h+pad)))
    sh.save(path)

SCR="/private/tmp/claude-502/-Users-jakubschnierer-hra/2af88260-eec4-4110-aa80-49e4a1a934ba/scratchpad"
os.makedirs(SCR, exist_ok=True)
sheet(portraits,8,os.path.join(SCR,"preview_portraits.png"))
sheet(list(cast_imgs.values()),4,os.path.join(SCR,"preview_cast.png"))
sheet([city(n) for n in CITIES],3,os.path.join(SCR,"preview_cities.png"),scale=3)
sheet([gear_icon(g) for g in GEAR],6,os.path.join(SCR,"preview_gear.png"))
print("generated", len(portraits),"portraits,",len(CITIES),"cities,",len(GEAR),"gear, + grain/vignette")

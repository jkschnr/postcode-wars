#!/usr/bin/env python3
"""WO2-T10 scene backdrops. Bakes a graded base PLATE per scene (sky, silhouettes,
lit windows, ground + reflection streak). The animated layers — rain, light flicker,
headlight sweep, crossing silhouettes, parallax, wet reflection — are drawn on top in
code by scene_backdrop.gd. Papers-Please grade, low-res, upscaled nearest in-engine."""

import os, random
from PIL import Image, ImageDraw, ImageEnhance, ImageFilter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "art", "scenes")
os.makedirs(OUT, exist_ok=True)

W, H = 540, 340
PAPER = (199, 187, 144)

def grade(img, sepia=0.10, sat=0.55):
    img = img.convert("RGB")
    img = ImageEnhance.Color(img).enhance(sat)
    img = ImageEnhance.Contrast(img).enhance(1.06)
    img = Image.blend(img, Image.new("RGB", img.size, PAPER), sepia)
    return img

def vgrad(d, cols, y0=0, y1=H):
    n = len(cols) - 1
    for y in range(y0, y1):
        f = (y - y0) / max(1, (y1 - y0))
        seg = min(int(f * n), n - 1)
        t = f * n - seg
        a, b = cols[seg], cols[seg + 1]
        c = tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))
        d.line([(0, y), (W, y)], fill=c)

def lamp(d, x, y, r, col, a=90):
    glow = Image.new("RGBA", (r * 2, r * 2), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    for i in range(r, 0, -2):
        aa = int(a * (1 - i / r) ** 2)
        gd.ellipse([r - i, r - i, r + i, r + i], fill=col + (aa,))
    return glow, (int(x - r), int(y - r))

def windows(d, x0, y0, w, h, rng, warm=0.6, dens=0.5, cell=14):
    for yy in range(y0 + 6, y0 + h - 6, cell * 2):
        for xx in range(x0 + 6, x0 + w - 6, cell):
            if rng.random() > dens:
                continue
            if rng.random() < warm:
                c = (255, 190, 90)
            else:
                c = (150, 190, 230)
            d.rectangle([xx, yy, xx + cell - 6, yy + cell], fill=c)

def base(sky):
    img = Image.new("RGB", (W, H), sky[0])
    return img, ImageDraw.Draw(img)

def scene_street_night(rng):
    img, d = base([(20, 26, 42)])
    vgrad(d, [(20, 26, 42), (32, 30, 40), (46, 34, 24)])
    horizon = 210
    x = -20
    while x < W:
        bw = rng.randint(50, 110); bh = rng.randint(70, 150)
        d.rectangle([x, horizon - bh, x + bw, horizon], fill=(14, 18, 28))
        windows(d, x, horizon - bh, bw, bh, rng, warm=0.7, dens=0.35)
        x += bw + rng.randint(4, 12)
    d.rectangle([0, horizon, W, H], fill=(14, 12, 11))  # wet road
    d.rectangle([0, horizon, W, horizon + 3], fill=(60, 46, 26))
    g, pos = lamp(d, 120, 120, 90, (255, 169, 77), 120)
    img.paste(g, pos, g)
    return img

def scene_high_street_day(rng):
    img, d = base([(150, 152, 150)])
    vgrad(d, [(150, 152, 150), (168, 166, 158), (120, 118, 112)])
    horizon = 220
    x = -10
    while x < W:
        bw = rng.randint(60, 100); bh = rng.randint(90, 150)
        col = rng.choice([(88, 84, 78), (96, 80, 70), (70, 78, 82)])
        d.rectangle([x, horizon - bh, x + bw, horizon], fill=col)
        d.rectangle([x, horizon - 34, x + bw, horizon], fill=(40, 42, 44))       # shopfront
        d.rectangle([x + 4, horizon - 30, x + bw - 4, horizon - 26], fill=rng.choice([(180, 70, 60), (60, 120, 140)]))  # awning
        x += bw + 6
    d.rectangle([0, horizon, W, H], fill=(96, 94, 90))
    return img

def scene_shop_interior(rng):
    img, d = base([(40, 42, 46)])
    d.rectangle([0, 0, W, H], fill=(46, 48, 52))
    for i in range(4):                                   # strip lights
        lit = (255, 250, 235) if i != 1 else (200, 205, 210)
        d.rectangle([40 + i * 130, 24, 150 + i * 130, 34], fill=lit)
    for row in range(3):                                 # shelving
        y = 90 + row * 78
        d.rectangle([30, y, W - 30, y + 54], fill=(60, 58, 54))
        for c in range(10):
            d.rectangle([44 + c * 46, y + 8, 44 + c * 46 + 30, y + 46],
                        fill=rng.choice([(150, 60, 50), (60, 110, 130), (180, 150, 60), (90, 120, 80)]))
    d.rectangle([0, H - 40, W, H], fill=(38, 36, 34))    # counter
    return img

def scene_terrace_night(rng):
    img, d = base([(18, 22, 34)])
    vgrad(d, [(18, 22, 34), (28, 26, 30)])
    d.rectangle([70, 90, W - 70, 250], fill=(40, 30, 26))   # house
    d.polygon([(60, 92), (W - 60, 92), (W // 2, 40)], fill=(30, 22, 20))  # roof
    d.rectangle([180, 150, 250, 220], fill=(255, 200, 110))  # one lit window
    for wx in (110, 300, 360):
        d.rectangle([wx, 150, wx + 50, 210], fill=(20, 24, 30))
    d.rectangle([0, 250, W, H], fill=(12, 12, 12))
    d.rectangle([90, 236, 120, 258], fill=(40, 60, 50))     # wheelie bin
    d.rectangle([130, 240, 158, 258], fill=(50, 44, 40))
    return img

def scene_corner_block(rng):
    img, d = base([(22, 24, 34)])
    vgrad(d, [(22, 24, 34), (34, 30, 30)])
    for i, (x, bw, bh) in enumerate([(20, 120, 250), (170, 110, 300), (300, 130, 220)]):
        d.rectangle([x, 300 - bh, x + bw, 300], fill=(18, 20, 28))
        windows(d, x, 300 - bh, bw, bh, rng, warm=0.5, dens=0.55, cell=16)
    d.rectangle([0, 300, W, H], fill=(14, 14, 16))
    g, pos = lamp(d, 250, 150, 60, (255, 210, 120), 90)     # stairwell light
    img.paste(g, pos, g)
    return img

def scene_market(rng):
    img, d = base([(40, 40, 48)])
    vgrad(d, [(40, 40, 50), (54, 48, 44)])
    for i in range(5):                                    # stalls + awnings
        x = 10 + i * 106
        d.rectangle([x, 180, x + 90, 300], fill=(60, 54, 48))
        d.rectangle([x - 4, 150, x + 94, 182], fill=rng.choice([(180, 70, 60), (70, 130, 90), (200, 160, 70)]))
    for bx in range(0, W, 26):                            # bunting
        d.polygon([(bx, 120), (bx + 20, 120), (bx + 10, 138)], fill=rng.choice([(200, 80, 70), (70, 120, 160), (210, 180, 80)]))
    d.rectangle([0, 300, W, H], fill=(30, 28, 26))
    return img

def scene_lockup_yard(rng):
    img, d = base([(30, 30, 34)])
    vgrad(d, [(30, 30, 34), (40, 38, 36)])
    for i in range(4):                                    # roller shutters
        x = 20 + i * 128
        d.rectangle([x, 120, x + 108, 280], fill=(70, 66, 60))
        for yy in range(126, 280, 10):
            d.line([(x, yy), (x + 108, yy)], fill=(50, 48, 44))
    d.rectangle([0, 280, W, H], fill=(46, 44, 42))        # oil-stained concrete
    d.ellipse([120, 300, 220, 330], fill=(28, 26, 26))
    d.rectangle([250, 40, 290, 46], fill=(230, 235, 240)) # strip light
    return img

def scene_docks_night(rng):
    img, d = base([(16, 22, 32)])
    vgrad(d, [(16, 22, 32), (24, 30, 40), (20, 30, 40)])
    for i in range(14):                                   # stacked containers
        x = (i % 7) * 78; y = 150 + (i // 7) * 44
        d.rectangle([x, y, x + 74, y + 40], fill=rng.choice([(120, 70, 50), (60, 90, 110), (90, 100, 70), (140, 120, 60)]))
    d.line([(400, 60), (400, 200)], fill=(30, 34, 40), width=6)   # crane
    d.line([(400, 60), (500, 90)], fill=(30, 34, 40), width=6)
    d.rectangle([0, 250, W, H], fill=(14, 20, 30))               # harbour water
    for hx in range(40, W, 60):
        d.rectangle([hx, 252, hx + 3, 300], fill=(255, 200, 120))  # light reflections
    return img

def scene_precinct_night(rng):
    img, d = base([(20, 22, 28)])
    vgrad(d, [(20, 22, 28), (30, 28, 30)])
    for i in range(4):
        x = 20 + i * 128
        d.rectangle([x, 130, x + 108, 260], fill=(44, 42, 44))   # shuttered units
        for yy in range(136, 260, 9):
            d.line([(x, yy), (x + 108, yy)], fill=(32, 30, 32))
    d.rectangle([160, 96, 300, 126], fill=(200, 60, 50))         # one flickering sign
    d.rectangle([0, 260, W, H], fill=(24, 24, 26))               # empty car park
    for ly in (300, 320):
        for lx in range(0, W, 70):
            d.rectangle([lx, ly, lx + 40, ly + 3], fill=(90, 88, 80))
    return img

def scene_grow_room(rng):
    img, d = base([(40, 36, 30)])
    d.rectangle([0, 0, W, H], fill=(120, 110, 70))              # foil walls
    for x in range(0, W, 8):
        d.line([(x, 0), (x + 4, H)], fill=(140, 130, 90))
    g, pos = lamp(d, W // 2, 120, 140, (255, 180, 90), 150)     # warm lamp glow
    img.paste(g, pos, g)
    for i in range(6):                                          # plants
        x = 40 + i * 82
        d.polygon([(x, 300), (x + 20, 220), (x + 40, 300)], fill=(40, 90, 40))
        d.polygon([(x + 6, 300), (x + 20, 250), (x + 34, 300)], fill=(60, 120, 50))
    d.ellipse([W // 2 - 30, 96, W // 2 + 30, 150], outline=(60, 60, 60), width=4)  # fan
    return img

def scene_towpath(rng):
    img, d = base([(18, 24, 30)])
    vgrad(d, [(18, 24, 30), (26, 30, 34)])
    d.arc([120, 120, 420, 320], 180, 360, fill=(30, 30, 34), width=18)  # bridge underside
    d.rectangle([0, 210, W, H], fill=(14, 22, 28))                      # canal
    for ry in range(216, 320, 10):                                     # ripples
        d.line([(0, ry), (W, ry)], fill=(30, 40, 50))
    for rx in range(60, W, 90):
        d.rectangle([rx, 214, rx + 2, 280], fill=(120, 140, 120))
    return img

def scene_barbershop(rng):
    img, d = base([(44, 42, 44)])
    d.rectangle([0, 0, W, H], fill=(50, 46, 44))
    d.rectangle([30, 70, 250, 210], fill=(20, 24, 30))       # mirror
    d.rectangle([30, 70, 250, 210], outline=(180, 150, 90), width=4)
    for i in range(2):                                       # chairs
        x = 90 + i * 200
        d.rectangle([x, 230, x + 90, 320], fill=(70, 40, 36))
        d.rectangle([x + 10, 200, x + 80, 236], fill=(90, 54, 48))
    d.rectangle([300, 150, 500, 180], fill=(60, 58, 54))     # counter/side
    for cx in range(310, 500, 26):                           # clippers/bottles
        d.rectangle([cx, 130, cx + 10, 152], fill=rng.choice([(200, 200, 210), (60, 140, 120), (200, 160, 70)]))
    return img

SCENES = {
    "street_night": scene_street_night, "high_street_day": scene_high_street_day,
    "shop_interior": scene_shop_interior, "terrace_night": scene_terrace_night,
    "corner_block": scene_corner_block, "market": scene_market,
    "lockup_yard": scene_lockup_yard, "docks_night": scene_docks_night,
    "precinct_night": scene_precinct_night, "grow_room": scene_grow_room,
    "towpath": scene_towpath, "barbershop": scene_barbershop,
}

def main():
    for name, fn in SCENES.items():
        rng = random.Random(hash(name) & 0xffffff)
        img = grade(fn(rng))
        img.save(os.path.join(OUT, name + ".png"))
        print("scene", name)
    print("done:", len(SCENES), "scenes ->", OUT)

if __name__ == "__main__":
    main()

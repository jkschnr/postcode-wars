#!/usr/bin/env python3
"""Re-bake the UK basemap framed like the design's Leaflet fitBounds so the
thirteen city nodes spread across the whole portrait frame instead of clustering
in a band with empty sea above. The bake window is aspect-matched to 1080x1920,
so the existing COVERED display in map_screen.gd needs no change — just the new
PNG and recomputed normalized city coords. One-off build asset."""
import math, os, io, time, json, urllib.request
from PIL import Image, ImageEnhance, ImageOps

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ART = os.path.join(ROOT, "art", "ui")

Z = 7
# window matches the design fitBounds visible area; aspect == 1080/1920 == 0.5625
LON0, LON1 = -6.60, 1.59        # west, east
LAT0, LAT1 = 57.40, 48.60       # north (top), south (bottom)

def xt(lon): return (lon + 180.0) / 360.0 * (2 ** Z)
def yt(lat):
    return (1.0 - math.log(math.tan(math.radians(lat)) + 1.0 / math.cos(math.radians(lat))) / math.pi) / 2.0 * (2 ** Z)

XT0, XT1 = xt(LON0), xt(LON1)   # increases eastward
YT0, YT1 = yt(LAT0), yt(LAT1)   # increases southward -> YT1 > YT0
win_w_px = (XT1 - XT0) * 256.0
win_h_px = (YT1 - YT0) * 256.0
print("window aspect %.4f (target 0.5625)" % (win_w_px / win_h_px))

tx0, tx1 = math.floor(XT0), math.floor(XT1)
ty0, ty1 = math.floor(YT0), math.floor(YT1)

def fetch(z, x, y):
    url = "https://tile.openstreetmap.org/%d/%d/%d.png" % (z, x, y)
    req = urllib.request.Request(url, headers={"User-Agent": "PostcodeWars-dev/1.0 asset-baker"})
    return Image.open(io.BytesIO(urllib.request.urlopen(req, timeout=30).read())).convert("RGB")

bw = (tx1 - tx0 + 1) * 256
bh = (ty1 - ty0 + 1) * 256
big = Image.new("RGB", (bw, bh))
for x in range(tx0, tx1 + 1):
    for y in range(ty0, ty1 + 1):
        big.paste(fetch(Z, x, y), ((x - tx0) * 256, (y - ty0) * 256))
        time.sleep(0.12)

# crop to the exact window, then scale to the portrait artboard
cx0 = (XT0 - tx0) * 256.0
cy0 = (YT0 - ty0) * 256.0
cx1 = (XT1 - tx0) * 256.0
cy1 = (YT1 - ty0) * 256.0
crop = big.crop((round(cx0), round(cy0), round(cx1), round(cy1)))
final = crop.resize((1080, 1920), Image.LANCZOS)

# wet British night grade (mirrors ui.css leaflet filter + old bake)
g = ImageOps.grayscale(final).convert("RGB")
g = ImageEnhance.Brightness(g).enhance(0.5)
g = ImageEnhance.Contrast(g).enhance(1.35)
g = Image.blend(g, Image.new("RGB", (1080, 1920), (18, 26, 38)), 0.28)   # cool tint
g = Image.blend(g, Image.new("RGB", (1080, 1920), (30, 20, 8)), 0.06)    # faint sodium
g.save(os.path.join(ART, "ukmap_real.png"))
print("saved ukmap_real.png 1080 x 1920")

# recompute normalized city coords against the same window
cj = os.path.join(ROOT, "data", "map_cities.json")
d = json.load(open(cj))
for c in d["cities"]:
    c["x"] = round((xt(c["lon"]) - XT0) / (XT1 - XT0), 4)
    c["y"] = round((yt(c["lat"]) - YT0) / (YT1 - YT0), 4)
    print("  %-11s -> (%.3f, %.3f)" % (c["name"], c["x"], c["y"]))
json.dump(d, open(cj, "w"), indent=2)
print("rewrote map_cities.json coords")

#!/usr/bin/env python3
"""Bake a real, wet-night-graded UK basemap from OSM tiles + reproject the city
node coordinates onto it. Replaces the flat procedural silhouette so the map
matches the design handoff. One-off build asset — not shipped as a tile dep."""
import math, os, io, time, json, urllib.request
from PIL import Image, ImageEnhance, ImageOps

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ART = os.path.join(ROOT, "art", "ui")
os.makedirs(ART, exist_ok=True)

Z = 6
X0, X1 = 30, 32          # lon ~ -11.25 .. 5.6
Y0, Y1 = 17, 22          # lat ~ 59.5 .. 49.6  (fits GB incl. Cornwall)
W = (X1 - X0 + 1) * 256
H = (Y1 - Y0 + 1) * 256

def fetch(z, x, y):
    url = "https://tile.openstreetmap.org/%d/%d/%d.png" % (z, x, y)
    req = urllib.request.Request(url, headers={"User-Agent": "PostcodeWars-dev/1.0 asset-baker"})
    return Image.open(io.BytesIO(urllib.request.urlopen(req, timeout=30).read())).convert("RGB")

def lonlat_px(lon, lat):
    n = 2 ** Z
    xt = (lon + 180.0) / 360.0 * n
    yt = (1.0 - math.log(math.tan(math.radians(lat)) + 1.0 / math.cos(math.radians(lat))) / math.pi) / 2.0 * n
    return (xt - X0) * 256.0, (yt - Y0) * 256.0

base = Image.new("RGB", (W, H))
for x in range(X0, X1 + 1):
    for y in range(Y0, Y1 + 1):
        base.paste(fetch(Z, x, y), ((x - X0) * 256, (y - Y0) * 256))
        time.sleep(0.15)

# wet British night grade (mirrors ui.css leaflet filter)
g = ImageOps.grayscale(base).convert("RGB")
g = ImageEnhance.Brightness(g).enhance(0.5)
g = ImageEnhance.Contrast(g).enhance(1.35)
g = Image.blend(g, Image.new("RGB", (W, H), (18, 26, 38)), 0.28)   # cool tint
g = Image.blend(g, Image.new("RGB", (W, H), (30, 20, 8)), 0.06)    # faint sodium warmth
g.save(os.path.join(ART, "ukmap_real.png"))
print("saved ukmap_real.png", W, "x", H)

# reproject city/base nodes onto the baked image and rewrite territories.json
LL = {
    "highlands": (-4.2, 57.3), "glasgow": (-4.25, 55.86), "newcastle": (-1.61, 54.97),
    "leeds": (-1.55, 53.80), "manchester": (-2.24, 53.48), "liverpool": (-2.99, 53.41),
    "wales": (-3.8, 52.4), "nottingham": (-1.15, 52.95), "birmingham": (-1.90, 52.48),
    "eastanglia": (1.30, 52.63), "bristol": (-2.59, 51.45), "london": (-0.13, 51.51),
    "kent": (0.9, 51.28), "cornwall": (-5.05, 50.26),
}
tj = os.path.join(ROOT, "data", "territories.json")
d = json.load(open(tj))
for b in d["bases"]:
    if b["id"] in LL:
        px, py = lonlat_px(*LL[b["id"]])
        b["x"] = round(px / W, 4)
        b["y"] = round(py / H, 4)
json.dump(d, open(tj, "w"), indent=2)
print("rewrote territories.json node coords for basemap")

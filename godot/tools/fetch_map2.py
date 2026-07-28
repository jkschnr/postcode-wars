#!/usr/bin/env python3
"""Upgrade-02 map data baker. Projects the main-map cities onto the existing UK
basemap, bakes a graded Hackney street basemap, projects the city-map zones/
venues/paths onto it, and ports the NPC roster + faction palette to JSON.
One-off build step (network). Godot reads the JSON + PNGs; no tile dependency."""
import re, json, math, os, io, time, urllib.request
from PIL import Image, ImageOps, ImageEnhance

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ART = os.path.join(ROOT, "art", "ui")
DATA = os.path.join(ROOT, "data")
UPG = os.path.join(ROOT, "..", "upgrades", "upgrade_02")

def fetch(z, x, y):
    url = "https://tile.openstreetmap.org/%d/%d/%d.png" % (z, x, y)
    req = urllib.request.Request(url, headers={"User-Agent": "PostcodeWars-dev/1.0 asset-baker"})
    return Image.open(io.BytesIO(urllib.request.urlopen(req, timeout=30).read())).convert("RGB")

def px_of(lon, lat, z, x0, y0):
    n = 2 ** z
    xt = (lon + 180.0) / 360.0 * n
    yt = (1.0 - math.log(math.tan(math.radians(lat)) + 1.0 / math.cos(math.radians(lat))) / math.pi) / 2.0 * n
    return (xt - x0) * 256.0, (yt - y0) * 256.0

# ---------- FACTION palette ----------
FACTION = {
    "manor":  {"label": "THE MANOR", "ring": "#FFA94D", "note": "Yours. Owes you, or is owed."},
    "rhodes": {"label": "RHODES",    "ring": "#C9A227", "note": "The debt. Suits and ledgers."},
    "vale":   {"label": "THE VALE",  "ring": "#B06CF0", "note": "Rival firm, three postcodes north."},
    "trade":  {"label": "TRADE",     "ring": "#4DA3FF", "note": "Neutral. Sells to anyone."},
    "police": {"label": "POLICE",    "ring": "#2E5EAA", "note": "Building a case."},
    "civil":  {"label": "CIVILIAN",  "ring": "#6FCF6F", "note": "Not in it. Affected by it."},
    "prison": {"label": "INSIDE",    "ring": "#B9C0C7", "note": "Reachable only on a call."},
}
json.dump(FACTION, open(os.path.join(DATA, "factions.json"), "w"), indent=2)

# ---------- NPC roster (parse from upgrade npcs.js) ----------
js = open(os.path.join(UPG, "npcs.js")).read()
m = re.search(r'window\.NPCS\s*=\s*(\[.*?\]);', js, re.S)
npcs = json.loads(m.group(1))
json.dump(npcs, open(os.path.join(DATA, "npcs.json"), "w"), indent=2)
print("npcs", len(npcs))

# ---------- main map: project 13 cities onto the existing UK basemap ----------
# UK basemap = ukmap_real.png baked at z6, tiles x30..32 y17..22 (768x1536)
UKZ, UKX0, UKY0, UKW, UKH = 6, 30, 17, 768, 1536
CITIES = [
    {"name": "Glasgow", "lat": 55.861, "lon": -4.250, "danger": 4, "tier": "city", "state": "locked", "req": "LVL 40", "hold": {"rhodes": 64, "vale": 22}, "jobs": 0, "take": "£0", "heat": 1},
    {"name": "Newcastle", "lat": 54.978, "lon": -1.618, "danger": 3, "tier": "city", "state": "open", "req": "LVL 24", "hold": {"vale": 58, "trade": 30, "manor": 12}, "jobs": 2, "take": "£1.2k", "heat": 2},
    {"name": "Liverpool", "lat": 53.408, "lon": -2.991, "danger": 3, "tier": "city", "state": "open", "req": "LVL 18", "hold": {"trade": 52, "manor": 28, "vale": 20}, "jobs": 3, "take": "£2.4k", "heat": 2},
    {"name": "Leeds", "lat": 53.800, "lon": -1.549, "danger": 3, "tier": "city", "state": "open", "req": "LVL 20", "hold": {"trade": 46, "manor": 34, "rhodes": 20}, "jobs": 2, "take": "£1.9k", "heat": 3},
    {"name": "Manchester", "lat": 53.480, "lon": -2.242, "danger": 3, "tier": "city", "state": "ready", "req": "JOB READY", "hold": {"vale": 61, "manor": 24, "trade": 15}, "jobs": 4, "take": "£3.6k", "heat": 4},
    {"name": "Grimsby", "lat": 53.567, "lon": -0.081, "danger": 2, "tier": "town", "state": "town", "req": "TOWN", "hold": {"trade": 70, "manor": 12}, "jobs": 1, "take": "£420", "heat": 1},
    {"name": "Nottingham", "lat": 52.954, "lon": -1.158, "danger": 2, "tier": "city", "state": "open", "req": "LVL 14", "hold": {"vale": 55, "trade": 28, "manor": 17}, "jobs": 2, "take": "£1.1k", "heat": 2},
    {"name": "Birmingham", "lat": 52.486, "lon": -1.890, "danger": 3, "tier": "city", "state": "open", "req": "LVL 16", "hold": {"trade": 44, "manor": 38, "vale": 18}, "jobs": 3, "take": "£2.8k", "heat": 3},
    {"name": "Swindon", "lat": 51.559, "lon": -1.781, "danger": 1, "tier": "town", "state": "town", "req": "TOWN", "hold": {"rhodes": 66, "trade": 20}, "jobs": 1, "take": "£380", "heat": 1},
    {"name": "Bristol", "lat": 51.454, "lon": -2.588, "danger": 2, "tier": "city", "state": "ready", "req": "JOB READY", "hold": {"manor": 57, "trade": 29, "vale": 14}, "jobs": 4, "take": "£2.2k", "heat": 2},
    {"name": "Luton", "lat": 51.879, "lon": -0.417, "danger": 1, "tier": "town", "state": "town", "req": "TOWN", "hold": {"rhodes": 72, "manor": 14}, "jobs": 1, "take": "£510", "heat": 2},
    {"name": "Margate", "lat": 51.385, "lon": 1.386, "danger": 1, "tier": "town", "state": "town", "req": "TOWN", "hold": {"manor": 48, "trade": 34}, "jobs": 2, "take": "£690", "heat": 1},
    {"name": "London", "lat": 51.507, "lon": -0.128, "danger": 5, "tier": "city", "state": "current", "req": "YOU ARE HERE", "hold": {"manor": 62, "vale": 22, "rhodes": 16}, "jobs": 6, "take": "£8.4k", "heat": 3, "city": "london"},
]
CITY_KEY = {"Glasgow": "glasgow", "Newcastle": "newcastle", "Liverpool": "liverpool", "Leeds": "leeds",
            "Manchester": "manchester", "Nottingham": "nottingham", "Birmingham": "birmingham",
            "Bristol": "bristol", "London": "london"}
for c in CITIES:
    px, py = px_of(c["lon"], c["lat"], UKZ, UKX0, UKY0)
    c["x"] = round(px / UKW, 4); c["y"] = round(py / UKH, 4)
    if c["name"] in CITY_KEY: c["city"] = CITY_KEY[c["name"]]
LINES = [
    ["London", "Luton", "money"], ["Luton", "Birmingham", "money"], ["Birmingham", "Manchester", "supply"],
    ["Manchester", "Liverpool", "supply"], ["Manchester", "Leeds", "supply"], ["Leeds", "Newcastle", "heat"],
    ["Newcastle", "Glasgow", "heat"], ["Birmingham", "Nottingham", "supply"], ["Nottingham", "Grimsby", "supply"],
    ["Birmingham", "Swindon", "money"], ["Swindon", "Bristol", "money"], ["London", "Bristol", "supply"],
    ["London", "Margate", "money"], ["London", "Birmingham", "heat"],
]
json.dump({"cities": CITIES, "lines": LINES}, open(os.path.join(DATA, "map_cities.json"), "w"), indent=2)
print("map cities", len(CITIES))

# ---------- city map: bake a graded Hackney basemap + project zones/venues ----------
CZ = 15
BB = (51.5290, -0.0790, 51.5575, -0.0240)  # lat0,lon0(min), lat1,lon1(max)
n = 2 ** CZ
def xtile(lon): return int((lon + 180.0) / 360.0 * n)
def ytile(lat): return int((1.0 - math.log(math.tan(math.radians(lat)) + 1.0 / math.cos(math.radians(lat))) / math.pi) / 2.0 * n)
x0 = min(xtile(BB[1]), xtile(BB[3])); x1 = max(xtile(BB[1]), xtile(BB[3]))
y0 = min(ytile(BB[0]), ytile(BB[2])); y1 = max(ytile(BB[0]), ytile(BB[2]))
CW = (x1 - x0 + 1) * 256; CH = (y1 - y0 + 1) * 256
print("hackney tiles x %d..%d y %d..%d -> %dx%d" % (x0, x1, y0, y1, CW, CH))
base = Image.new("RGB", (CW, CH))
for x in range(x0, x1 + 1):
    for y in range(y0, y1 + 1):
        base.paste(fetch(CZ, x, y), ((x - x0) * 256, (y - y0) * 256))
        time.sleep(0.12)
g = ImageOps.grayscale(base).convert("RGB")
g = ImageEnhance.Brightness(g).enhance(0.42)
g = ImageEnhance.Contrast(g).enhance(1.45)
g = Image.blend(g, Image.new("RGB", (CW, CH), (16, 22, 34)), 0.30)
g.save(os.path.join(ART, "citymap_hackney.png"))
print("citymap", CW, CH)

def cnorm(lat, lon):
    px, py = px_of(lon, lat, CZ, x0, y0)
    return [round(px / CW, 4), round(py / CH, 4)]

ZONES = [
    {"id": "london_fields", "name": "London Fields", "hold": "manor", "heat": 1, "take": "£1.2k", "poly": [[51.5430,-0.0620],[51.5455,-0.0525],[51.5405,-0.0470],[51.5380,-0.0565]]},
    {"id": "broadway", "name": "Broadway Market", "hold": "manor", "heat": 2, "take": "£980", "poly": [[51.5380,-0.0565],[51.5405,-0.0470],[51.5350,-0.0430],[51.5325,-0.0520]]},
    {"id": "dalston", "name": "Dalston Lane", "hold": "vale", "heat": 4, "take": "£2.4k", "poly": [[51.5480,-0.0760],[51.5510,-0.0640],[51.5455,-0.0600],[51.5430,-0.0720]]},
    {"id": "kingsland", "name": "Kingsland Road", "hold": "trade", "heat": 3, "take": "£1.6k", "poly": [[51.5430,-0.0770],[51.5455,-0.0700],[51.5360,-0.0660],[51.5340,-0.0740]]},
    {"id": "well_street", "name": "Well Street", "hold": "manor", "heat": 1, "take": "£640", "poly": [[51.5395,-0.0455],[51.5420,-0.0360],[51.5370,-0.0320],[51.5345,-0.0410]]},
    {"id": "homerton", "name": "Homerton", "hold": "vale", "heat": 3, "take": "£1.1k", "poly": [[51.5480,-0.0470],[51.5510,-0.0350],[51.5450,-0.0310],[51.5425,-0.0430]]},
    {"id": "arches", "name": "The Arches", "hold": "rhodes", "heat": 2, "take": "£3.1k", "poly": [[51.5350,-0.0660],[51.5375,-0.0590],[51.5320,-0.0555],[51.5300,-0.0625]]},
    {"id": "marshes", "name": "The Marshes", "hold": "none", "heat": 0, "take": "£0", "poly": [[51.5530,-0.0430],[51.5570,-0.0280],[51.5500,-0.0250],[51.5470,-0.0390]]},
]
for z in ZONES:
    z["npoly"] = [cnorm(la, lo) for la, lo in z["poly"]]
VENUES = [
    {"id": "barber", "name": "Uncle T · Barber", "sign": "barber", "lat": 51.5412, "lon": -0.0555, "zone": "broadway", "kind": "STORY", "jobs": 2, "note": "Back room. Nobody knocks.", "screen": "jobs"},
    {"id": "chicken", "name": "ChickenLix", "sign": "chicken", "lat": 51.5445, "lon": -0.0592, "zone": "london_fields", "kind": "GRAFT", "jobs": 3, "note": "Open till three. Mopeds idling out front.", "screen": "jobs"},
    {"id": "tyres", "name": "Maz Tyres", "sign": "tyres", "lat": 51.5468, "lon": -0.0668, "zone": "dalston", "kind": "WHEELS", "jobs": 2, "note": "Part worn, no questions, cash only.", "screen": "jobs"},
    {"id": "betting", "name": "Betfrenz", "sign": "betting", "lat": 51.5392, "lon": -0.0712, "zone": "kingsland", "kind": "HUSTLE", "jobs": 2, "note": "Till codes change on a Tuesday.", "screen": "bank"},
    {"id": "laundry", "name": "Bubbles", "sign": "laundry", "lat": 51.5372, "lon": -0.0402, "zone": "well_street", "kind": "WASH", "jobs": 1, "note": "Service wash. Fifteen per cent.", "screen": "bank"},
    {"id": "gym", "name": "Ironworks", "sign": "gym", "lat": 51.5462, "lon": -0.0398, "zone": "homerton", "kind": "TRAIN", "jobs": 1, "note": "Twenty-four hour. Nobody there at four.", "screen": "gym"},
    {"id": "lockups", "name": "Arch 14", "sign": "lockups", "lat": 51.5334, "lon": -0.0612, "zone": "arches", "kind": "STORAGE", "jobs": 3, "note": "Rhodes holds the lease. You hold a key.", "screen": "fence"},
    {"id": "corner", "name": "Pearl & Sons", "sign": "corner", "lat": 51.5352, "lon": -0.0498, "zone": "broadway", "kind": "CONTACT", "jobs": 1, "note": "Off licence. Aunty Pearl sees everything.", "screen": "messages"},
]
for v in VENUES:
    v["x"], v["y"] = cnorm(v["lat"], v["lon"])
PATROL = [[51.5510,-0.0700],[51.5470,-0.0560],[51.5400,-0.0490],[51.5340,-0.0600],[51.5400,-0.0740],[51.5510,-0.0700]]
SUPPLY = [[51.5334,-0.0612],[51.5392,-0.0712],[51.5468,-0.0668]]
KIND_COL = {"STORY": "#FFA94D", "GRAFT": "#D9E021", "WHEELS": "#4DA3FF", "HUSTLE": "#B06CF0",
            "WASH": "#57C785", "TRAIN": "#F2C14E", "STORAGE": "#C9A227", "CONTACT": "#6FCF6F"}
json.dump({"zones": ZONES, "venues": VENUES, "kind_col": KIND_COL,
           "patrol": [cnorm(la, lo) for la, lo in PATROL],
           "supply": [cnorm(la, lo) for la, lo in SUPPLY]},
          open(os.path.join(DATA, "city_map.json"), "w"), indent=2)
print("city_map zones/venues", len(ZONES), len(VENUES))
print("DONE")

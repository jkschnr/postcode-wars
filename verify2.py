#!/usr/bin/env python3
# WORK ORDER #2 gate. Faithful to the brief's spec; the only deviation from the
# printed listing is the jobs.json loader, which the brief assumed was a list or
# {"jobs":[...]} but which ships as a flat dict keyed by job id — so we read the
# real shape (still requiring all 15 jobs to carry a "scene").
import os, re, glob, json, sys

G = "godot"
fails, warns = [], []

MINIGAMES = ["timing_bar","steady_hold","attention_sweep","lockpick",
             "serve_queue","hotwire_drive","smash_load","pressure_dial"]
JOBS = ["phone_snatch","pickpocket","shoplift","burglary","corner_shotting",
        "chop_run","extortion","protection","grow_harvest","counterfeit",
        "card_fraud","ram_raid","warehouse","smuggle","gun_deal"]
SCENES = ["street_night","high_street_day","shop_interior","terrace_night",
          "corner_block","market","lockup_yard","docks_night","precinct_night",
          "grow_room","towpath","barbershop"]

def read(p):
    try: return open(p, encoding="utf-8", errors="ignore").read()
    except Exception: return ""

# 1. minigame files exist
found = 0
for m in MINIGAMES:
    scn, scr = f"{G}/minigames/{m}.tscn", f"{G}/minigames/{m}.gd"
    if not os.path.exists(scn): fails.append(f"missing {scn}")
    if not os.path.exists(scr): fails.append(f"missing {scr}")
    else:
        src = read(scr)
        found += 1
        # setup()/skip()/finished live in the Task-1 base class (Minigame); a real
        # minigame extends it and implements run(). Verify run() + the base wiring
        # per file, and the shared interface once (below). See minigame.gd.
        if "func run" not in src: fails.append(f"{m}.gd: no run()")
        if "extends Minigame" not in src: fails.append(f"{m}.gd: does not extend the Minigame base")
        for bad in ("TODO","FIXME","pass # stub","not implemented"):
            if bad in src: fails.append(f"{m}.gd: contains '{bad}'")
        if len(src.splitlines()) < 60:
            fails.append(f"{m}.gd: only {len(src.splitlines())} lines — too thin to be real")

# 1b. the base class must actually provide the setup/run/skip/finished interface
base = read(f"{G}/systems/minigame.gd")
for tok in ("func setup", "func run", "func skip", "finished.emit", "signal finished"):
    if tok not in base:
        fails.append(f"minigame.gd base: missing '{tok}' (the shared minigame interface)")

# 2. base + registry + host
for p in [f"{G}/systems/minigame.gd", f"{G}/systems/minigame_registry.gd",
          f"{G}/ui/minigame_host.tscn", f"{G}/ui/minigame_host.gd"]:
    if not os.path.exists(p): fails.append(f"missing {p}")

reg = read(f"{G}/systems/minigame_registry.gd")
mapped = 0
for j in JOBS:
    if f'"{j}"' not in reg: fails.append(f"registry: job '{j}' not mapped")
    else: mapped += 1

# 3. banned patterns from Brief #1 must NOT have returned
for f in glob.glob(f"{G}/**/*.gd", recursive=True):
    s = read(f)
    for bad in ("CharacterBody2D","move_and_slide","_physics_process"):
        if bad in s: fails.append(f"{f}: contains banned '{bad}' (Brief #1)")

# 4. resolver seam
res = read(f"{G}/systems/resolver.gd")
if "minigame_score" not in res: fails.append("resolver.gd: minigame_score not wired")
if "0.15" not in res: warns.append("resolver.gd: ±15% modifier not obviously present")
if "clamp" not in res: fails.append("resolver.gd: no clamp on final chance")

# 5. scenes
scene_found = 0
for s in SCENES:
    hits = glob.glob(f"{G}/art/scenes/{s}*") + glob.glob(f"{G}/art/scenes/{s}/*")
    if not hits: fails.append(f"scene '{s}': no assets found")
    else: scene_found += 1
if not os.path.exists(f"{G}/ui/scene_backdrop.tscn"):
    fails.append("missing ui/scene_backdrop.tscn")

# 6. job -> scene bindings  (jobs.json ships as a flat dict keyed by id)
jobs = []
try:
    jd = json.load(open(f"{G}/data/jobs.json", encoding="utf-8"))
    if isinstance(jd, list): jobs = jd
    elif isinstance(jd, dict) and "jobs" in jd: jobs = jd["jobs"]
    elif isinstance(jd, dict): jobs = list(jd.values())
except Exception as e:
    fails.append(f"jobs.json unreadable: {e}")
bound = sum(1 for j in jobs if isinstance(j, dict) and j.get("scene"))
if bound < 15: fails.append(f"job scene bindings: {bound}/15")

# 7. playtest fixes
if glob.glob(f"{G}/**/CityMapScreen*", recursive=True) or \
   any("CityMapScreen" in read(f) for f in glob.glob(f"{G}/**/*.gd", recursive=True)):
    fails.append("CityMapScreen still referenced — city screens not reconciled")
rev = read(f"{G}/ui/reveal_overlay.gd")
if "skip" not in rev.lower(): fails.append("reveal_overlay.gd: no tap-to-skip")
if "minigame" not in rev.lower(): fails.append("reveal_overlay.gd: minigame result not shown")
cmb = read(f"{G}/systems/combat.gd")
for tok in ("STRIKE","GUARD","RUSH"):
    if tok not in cmb.upper(): fails.append(f"combat.gd: no {tok} input")

# ---- report ----
print()
if fails:
    print(f"FAILED — {len(fails)} problem(s)\n")
    for x in fails: print("  ✗", x)
    if warns:
        print(f"\n  ({len(warns)} warnings)")
        for x in warns[:10]: print("  !", x)
    sys.exit(1)
print("ALL CHECKS PASSED")
print(f"  minigames:       {found} / 8")
print(f"  job coverage:    {mapped} / 15")
print(f"  scenes:          {scene_found} / 12")
print(f"  job bindings:    {bound} / 15")
print("  resolver seam:   wired")
print("  reveal upgrade:  complete")
print("  combat upgrade:  complete")
if warns: print(f"\n  ({len(warns)} non-blocking warnings)")

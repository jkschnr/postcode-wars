#!/usr/bin/env python3
import json, glob, os, sys, re

D = "godot/data"
fails, warns = [], []

def load(p):
    try: return json.load(open(p, encoding="utf-8"))
    except Exception as e:
        fails.append(f"{p}: cannot parse — {e}"); return None

# ---------- 1. VIGNETTES ----------
vig_total, ids = 0, set()
for f in sorted(glob.glob(f"{D}/vignettes/*.json")):
    d = load(f)
    if d is None: continue
    v = d if isinstance(d, list) else (d.get("vignettes") or [])
    name = os.path.basename(f)
    if len(v) < 10: fails.append(f"vignettes/{name}: {len(v)}/10")
    vig_total += len(v)
    named = crits = conds = 0
    for e in v:
        i = e.get("id")
        if not i: fails.append(f"{name}: entry with no id")
        elif i in ids: fails.append(f"{name}: duplicate id {i}")
        ids.add(i)
        for fld in ("setup", "on_success", "on_fail"):
            if not e.get(fld): fails.append(f"{name}/{i}: missing {fld}")
        for bad in ("TODO", "...", "TBD", "placeholder"):
            if bad in json.dumps(e): fails.append(f"{name}/{i}: contains '{bad}'")
        w = len((e.get("setup") or "").split())
        if not (18 <= w <= 50): warns.append(f"{name}/{i}: setup {w} words (want 20-45)")
        if e.get("on_crit"): crits += 1
        t = e.get("target") or {}
        if t.get("name") and t["name"] != "—": named += 1
        if e.get("conditions"): conds += 1
    if v:
        if crits < 4: fails.append(f"{name}: only {crits} on_crit (need 4)")
        if named < 3: fails.append(f"{name}: only {named} named targets (need 3)")
        if conds < 4: fails.append(f"{name}: only {conds} with conditions (need 4)")

# ---------- 2. STAGES ----------
JOBS_WITH_STAGES = ["burglary","warehouse","corner_shotting","phone_snatch","pickpocket",
    "shoplift","chop_run","extortion","protection","grow_harvest","counterfeit",
    "card_fraud","ram_raid","smuggle","gun_deal"]
TIER1 = {"phone_snatch","pickpocket","shoplift"}
stage_files = variants = 0
for job in JOBS_WITH_STAGES:
    p = f"{D}/stages/{job}.json"
    if not os.path.exists(p): fails.append(f"stages/{job}.json: MISSING"); continue
    d = load(p)
    if d is None: continue
    st = d.get("stages", [])
    want = 3 if job in TIER1 else 5
    if len(st) < want: fails.append(f"stages/{job}: {len(st)}/{want} stages")
    stage_files += 1
    for i, s in enumerate(st):
        for fld in ("name", "text", "fail_text"):
            if not s.get(fld): fails.append(f"stages/{job}[{i}]: missing {fld}")
        for fld in ("text", "fail_text"):
            val = s.get(fld)
            if isinstance(val, list):
                if len(val) < 3: fails.append(f"stages/{job}[{i}].{fld}: {len(val)}/3 variants")
                else: variants += len(val)
            else: variants += 1

# ---------- 3. OBJECTIVES ----------
ch = load(f"{D}/objectives/chain.json")
if ch:
    c = ch.get("chain", [])
    if len(c) < 25: fails.append(f"objectives: {len(c)}/25")
    lvl = sum(1 for o in c if o.get("target",{}).get("type") == "level_reached")
    if c and lvl > len(c) / 5:
        fails.append(f"objectives: {lvl} level gates, max allowed {len(c)//5}")
    seen = {o["id"] for o in c}
    for o in c:
        nxt = o.get("on_complete", {}).get("next", "")
        if not nxt and not o.get("fallback"):
            fails.append(f"objectives/{o['id']}: DEAD END (no next, no fallback flag)")
        if nxt and nxt not in seen:
            fails.append(f"objectives/{o['id']}: next '{nxt}' does not exist")
        if not o.get("subtext"): fails.append(f"objectives/{o['id']}: no subtext")
    LIARS = {"obj_sell_gear":"items_sold","obj_get_stronger":"stat_trained","obj_first_crew":"crew_size"}
    for oid, want in LIARS.items():
        o = next((x for x in c if x["id"] == oid), None)
        if o and o.get("target",{}).get("type") != want:
            fails.append(f"objectives/{oid}: target is '{o.get('target',{}).get('type')}', must be '{want}'")

# ---------- 4. STORY ----------
b = load(f"{D}/story/beats.json") or {}
cards = load(f"{D}/story/cards.json") or {}
if len(b) < 28: fails.append(f"story beats: {len(b)}/28")
if len(cards) < 110: fails.append(f"story cards: {len(cards)}/110")
for bid, bv in b.items():
    for cid in bv.get("cards", []):
        if cid not in cards: fails.append(f"beat {bid}: card '{cid}' missing")
silence = 0
for cid, c in cards.items():
    if not c.get("speaker"): fails.append(f"card {cid}: no speaker")
    w = len((c.get("text") or "").split())
    if w > 60: fails.append(f"card {cid}: text {w} words (max 60)")
    opts = c.get("options", [])
    if not (2 <= len(opts) <= 4): fails.append(f"card {cid}: {len(opts)} options (want 2-4)")
    for o in opts:
        if "outcome" not in o: warns.append(f"card {cid}: option '{o.get('label')}' has no outcome")
    if any(o.get("label") == "…" for o in opts): silence += 1
if len(b) and silence < len(b):
    warns.append(f"only {silence} cards offer silence — want at least 1 per beat ({len(b)})")

# ---------- 5. CALLS ----------
calls = load(f"{D}/story/calls.json") or {}
if len(calls) < 3: fails.append(f"prison calls: {len(calls)}/3 characters")
topics = sum(len(v.get("topics", [])) for v in calls.values())
if topics < 30: fails.append(f"call topics: {topics}/30")

# ---------- 6. GEAR MIGRATION ----------
if os.path.exists(f"{D}/gear.json"): fails.append("gear.json still exists — must be deleted")
hits = []
for f in glob.glob("godot/**/*.gd", recursive=True) + glob.glob(f"{D}/**/*.json", recursive=True):
    try:
        if "gear_bonus" in open(f, encoding="utf-8", errors="ignore").read(): hits.append(f)
    except Exception: pass
if hits: fails.append(f"gear_bonus still referenced in: {hits}")
it = load(f"{D}/items.json")
if it:
    allit = [i for g in it.get("slots", []) for i in g.get("items", [])]
    nov = [i["id"] for i in allit if not i.get("v") and i.get("il", 0) > 0]
    if nov: fails.append(f"{len(nov)} items have no stat values: {nov[:8]}…")

# ---------- REPORT ----------
print()
if fails:
    print(f"FAILED — {len(fails)} problem(s)\n")
    for x in fails: print("  ✗", x)
    if warns:
        print(f"\n  ({len(warns)} warnings)")
        for x in warns[:15]: print("  !", x)
    sys.exit(1)

print("ALL CHECKS PASSED")
print(f"  vignettes:      {vig_total} / 150")
print(f"  stages:         {stage_files} / 15 jobs")
print(f"  stage variants: {variants}")
print(f"  story beats:    {len(b)} / 28")
print(f"  story cards:    {len(cards)} / 110")
print(f"  objectives:     {len(ch.get('chain', [])) if ch else 0} / 25")
print(f"  call topics:    {topics} / 30")
print(f"  gear migration: complete")
if warns: print(f"\n  ({len(warns)} non-blocking warnings)")

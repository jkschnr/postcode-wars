#!/usr/bin/env python3
import re, glob, os, sys
G = "godot"
fails = []
MG = ["timing_bar","steady_hold","attention_sweep","lockpick",
      "serve_queue","hotwire_drive","smash_load","pressure_dial"]

base = open(f"{G}/systems/minigame.gd", encoding="utf-8").read()
for fn in ("_ready_beat", "window_ms"):
    if fn not in base: fails.append(f"minigame.gd: missing {fn}()")
if "250" not in base: fails.append("minigame.gd: no 250ms floor constant in window_ms")

for m in MG:
    p = f"{G}/minigames/{m}.gd"
    if not os.path.exists(p): fails.append(f"missing {p}"); continue
    s = open(p, encoding="utf-8").read()
    if "_ready_beat" not in s: fails.append(f"{m}: no ready beat")
    if "window_ms" not in s: fails.append(f"{m}: does not use window_ms() floor")
    if '"reason"' not in s: fails.append(f"{m}: no failure reason in detail")
    if s.count("_event(") < 3: fails.append(f"{m}: only {s.count('_event(')} actor pings (need 3+)")
    if "randf_range" in s and m == "steady_hold":
        fails.append("steady_hold: random noise on player-controlled fill must be removed")

print()
if fails:
    print(f"FAILED — {len(fails)}\n")
    for x in fails: print("  ✗", x)
    sys.exit(1)
print("ALL CHECKS PASSED")

# Postcode Wars — Upgrades

Two additive upgrade packs. Neither touches the base build: drop both folders into the project root next to the numbered screens, load the modules you want, and everything else keeps working.

Read each pack's own doc for the full API — `upgrade_01/UPGRADE.md` and `upgrade_02/README.md`.

---

## Install

```
<project root>/
  01-map.html … 23-motion.html      ← existing screens, unchanged
  ui.css  chrome.js  cast.js  art.js  anim.js  atmos.js
  art/                              ← existing art, unchanged
  upgrade_01/                       ← drop in
  upgrade_02/                       ← drop in
```

Both packs reference `../ui.css` and `../chrome.js`, so the folder names must stay as they are.

---

## Upgrade 01 — Graphics + cast

**Look at:** `upgrade_01/demo.html` (every effect live, with controls) · `upgrade_01/npcs.html` (the roster)

| | Addition |
|---|---|
| 1–4 | **Grade** — per-city colour grade (13 cities), weather (dry / drizzle / rain / downpour), time of day (dusk / night / dawn), and heat as a visual state that breathes at 4+ |
| 5 | **Venue signage** — 8 lit fascias |
| 6 | **Item art expanded** — +28, 40 total |
| 7 | **Vehicles** — 4 side-on |
| 8 | **Crew badges** — 4 class emblems |
| 9 | **Idle ambience** — headlight sweeps, lamp flicker, haze drift, litter |
| 10 | **Job-type stingers** — 4 distinct reveal entrances |
| 11 | **Map travel draw** — route draws with the glow riding the line |
| 12 | **Rarity as light** — glow pools instead of border colours |
| 13 | **Paperwork interrupt** — warrant / seizure / eviction / charge sheet, slid over the screen |
| 14 | **50 named NPCs** with pixel portraits, across 13 cities and 7 factions |

Modules: `grade.js` · `ambience.js` · `fx.js` · `art-map.js` · `npcs.js` — independent, load only what a screen needs. 102 files.

## Upgrade 02 — Main map & city map

**Look at:** `upgrade_02/main-map.html` · `upgrade_02/city-map.html` (they link to each other)

Templates for the two screens the game lives in, both on real geography with game data painted over it.

**Main map** turns the country into a colour map of who holds what: faction influence blooms bleeding into the basemap, three animated line types (supply / money / heat), nodes carrying a jobs-ready arc and a heat pulse, faction-split bars under every city name, and a peek sheet that expands into full territory breakdown plus the NPCs on that manor.

**City map** makes your postcode an actual map: eight Hackney blocks as coloured fields tinted by holder, a chip row that focuses one block and dims the rest, venue pins on real coordinates colour-coded by job type, an animated patrol loop and supply run, and a venue sheet headed by its fascia art.

98 files (includes its own copy of the NPC roster and art it needs).

---

## Colour discipline

Everything colourful in both packs comes from one faction palette, so it reads as information rather than decoration:

| Faction | Colour | Meaning |
|---|---|---|
| The Manor | `#FFA94D` | Yours |
| Rhodes | `#C9A227` | The debt |
| The Vale | `#B06CF0` | Rival firm |
| Trade | `#4DA3FF` | Neutral, sells to anyone |
| Police | `#2E5EAA` | Building a case |
| Civilian | `#6FCF6F` | Not in it, affected by it |
| Inside | `#B9C0C7` | Reachable only on a call |

Hi-vis `#D9E021` stays reserved for the single most important action on any screen.

---

## Before build

- **Street imagery is live OpenStreetMap, graded in CSS.** Bake one flat PNG per city (and per city-map view) before build — do not ship a tile dependency. All blooms, blocks, pins and lines live in overlay layers, so they survive the swap unchanged.
- **All art is procedurally generated stand-in work** — final in size, framing and lighting, but a pixel artist should redraw the vehicles, signage lettering and NPC portraits for ship. Paths and dimensions are correct; swap the PNGs in place.
- The Hackney block polygons are hand-approximated from real coordinates — replace with true postcode boundaries if you have them.
- The 50 NPCs deliberately have no line pools. Each one's note is the brief for that voice; write the lines against the story beats they appear in.

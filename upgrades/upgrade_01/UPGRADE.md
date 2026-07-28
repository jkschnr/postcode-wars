# Upgrade 01 — Graphics

Additive graphics package for **Postcode Wars**. Nothing in the base build is modified: this folder adds four JS modules, 52 art files and one live demo sheet. Drop the folder in, load the modules, call them where you want them.

Start with **`demo.html`** — every one of the thirteen additions is live on that one page, with the controls to prove each state. **`npcs.html`** is the 50-strong NPC roster, filterable by city and faction.

---

## What's in it

| # | Addition | Where it lives |
|---|---|---|
| 1 | Per-city colour grade (13 cities) | `grade.js` |
| 2 | Weather states (dry / drizzle / rain / downpour) | `grade.js` |
| 3 | Time of day (dusk / night / dawn) | `grade.js` |
| 4 | Heat as a visual state, not a number | `grade.js` |
| 5 | Venue signage — 8 lit fascias | `art/sign-*.png` |
| 6 | Item art expanded — +28, 40 total | `art/item-*.png` |
| 7 | Vehicles — 4 side-on | `art/veh-*.png` |
| 8 | Crew class badges — 4 emblems | `art/badge-*.png` |
| 9 | Idle ambience (headlights, lamp flicker, drift, litter) | `ambience.js` |
| 10 | Job-type stingers — 4 entrances | `fx.js` |
| 11 | Map travel draw with glow head | `fx.js` |
| 12 | Rarity as light, not border | `fx.js` |
| 13 | Paperwork interrupt — 4 kinds | `fx.js` |
| 14 | **50 named NPCs** with pixel portraits | `npcs.js` · `art/npc-*.png` |

---

## Install

Copy `upgrade_01/` into the project root, next to the numbered screens. Then in each screen's `<head>`, **after** the existing `art.js` / `cast.js` / `chrome.js`:

```html
<script src="upgrade_01/grade.js"></script>
<script src="upgrade_01/ambience.js"></script>
<script src="upgrade_01/fx.js"></script>
<script src="upgrade_01/art-map.js"></script>
<script src="upgrade_01/npcs.js"></script>
```

All four are independent — load only what a screen uses. Each injects its own keyframes once, so there is nothing to add to `ui.css`.

---

## API

### `applyGrade(el, { city, weather, time, heat })`
Stacks six overlay layers on any positioned container: time-of-day multiply, city tint, haze, wet sheen, rain sheets, heat wash. Call again to change state — layers are reused, not duplicated.

```js
applyGrade(document.getElementById('street'), {
  city: 'glasgow', weather: 'downpour', time: 'night', heat: 4
});
```

- `city` — any key in `CITY_GRADE` (13 cities, each with its own light temperature)
- `weather` — `dry` | `drizzle` | `rain` | `downpour`
- `time` — `dusk` | `night` | `dawn`
- `heat` — `0`–`5`. At **3** a faint police-blue wash appears; at **4+** it strengthens and breathes on a 2.6 s cycle.

Returns the state string (e.g. `"glasgow · DOWNPOUR · NIGHT · HEAT 4"`) and also writes it to `el.dataset.gradeState`.

### `ambience(el, { headlights, lamp, drift, litter, lampX })`
Adds idle motion so a screen feels inhabited while nothing is happening. Everything is decorative and `pointer-events:none`.

```js
ambience(streetBand, { litter: true, lampX: 62 });
ambienceOff(streetBand);   // before a transition, or for a still capture
```

A car passes every 9–16 s as a headlight sweep only — never a drawn car. One lamp flickers on a long irregular cycle. Haze drifts over ~30 s.

### `rarityLight(el, rarity)` · `bestRarity([...])`
Gives a card a glow pool that spills onto the surface behind it. Certi and Iconic pulse slowly.

```js
rarityLight(card, 'iconic');
const best = bestRarity(['decent', 'peng', 'iconic']);  // 'iconic' — for the bag rim
```

### `stinger(host, type, text)`
Four job types, four entrances: `wheels` streaks past, `graft` lands square, `hustle` turns over like a card, `violence` snaps in hard and rattles the container.

```js
stinger(revealStage, 'violence');        // default word per type
stinger(revealStage, 'wheels', 'AWAY');  // or your own
```

### `travelDraw(svg, from, to, ms, done)`
Draws a curved route between two map points with the glow head riding the line. Chain the callback for multi-hop journeys. Needs an `<svg>` overlay sized to the map viewport; coordinates are in SVG user units.

### `paperInterrupt(host, kind, fields, onDismiss)`
Slides a document over the screen at a story beat rather than filing it in a menu.

```js
paperInterrupt(frame, 'seizure', {
  amount: '£12,480', location: 'Bung Savings, Dalston',
  reference: 'Held 48 hrs', officer: 'DC Hallow'
});
```

Kinds: `warrant` · `seizure` · `eviction` · `charge`. The `SERVED` stamp lands 320 ms after the sheet.

### NPCs — `npcs.js`
Fifty named people across 13 cities and 7 factions. Each has an id, name, age, role, city, place and a one-line note that fixes who they are. Portraits are 96 × 120 pixel art at 4× nearest, one per NPC.

```js
npcsIn('Manchester')     // everyone in a city
npcsOf('vale')           // everyone in a faction
npcById('dez')           // one person
npcSlot(npc, 96)         // portrait slot markup, ring coloured by faction
npcArt('dez')            // upgrade_01/art/npc-dez.png
```

Factions and their ring colours: **manor** `#FFA94D` (yours) · **rhodes** `#C9A227` (the debt) · **vale** `#B06CF0` (rival firm) · **trade** `#4DA3FF` (neutral, sells to anyone) · **police** `#2E5EAA` · **civil** `#6FCF6F` (not in it, affected by it) · **prison** `#B9C0C7` (reachable only on a call).

Pages **inside** `upgrade_01/` must set `window.NPC_ART_BASE = 'art/'` before first use; from the project root the defaults are correct.

Wire them into: **11 crew** (recruitment pool), **15 messages** (senders), **18 codex** (met/unmet entries), **06 choice** (speakers), **02 city** (who is standing outside which venue).

### Art lookups — `art-map.js`
```js
signFor('ChickenLix')        // upgrade_01/art/sign-chicken.png
badgeFor('driver')           // upgrade_01/art/badge-driver.png
vehicleFor('transit')        // upgrade_01/art/veh-transit.png
artFor2('gold chain')        // upgrade_01/art/item-chain.png
itemArt2(name, height)       // drop-in replacement for the base itemArt()
```
`artFor2()` falls back to the base twelve items automatically, so it is safe to swap in everywhere.

---

## Where to wire each one

| Screen | Add |
|---|---|
| 01 map | `travelDraw()` on city-to-city travel |
| 02 city | `applyGrade()` on the street banner · `ambience()` · `signFor()` on every venue tile |
| 03 jobs | `applyGrade()` on the street strip · `ambience()` |
| 04 job confirm | `applyGrade()` with the job's heat · `vehicleFor()` on wheels jobs |
| 05 reveal | `stinger()` by job type · `rarityLight()` per loot card · `bestRarity()` for the bag rim · `itemArt2()` |
| 06 choice | `applyGrade()` on the blurred street behind the card |
| 07 character | `itemArt2()` on equipped gear |
| 11 crew | `badgeFor()` on every roster row and candidate card |
| 13 shop / fence | `itemArt2()` · `rarityLight()` on item cards |
| 14 jail | `applyGrade()` with `weather:'dry'`, no city tint — this screen stays grey |
| Any story beat | `paperInterrupt()` |

---

## Notes

- **Grade is the highest-value item here.** Four overlay layers give 13 cities × 4 weathers × 3 times of day distinct moods from the same art. Wire it before anything else.
- **Heat 4+ must be felt before it is read.** If you only take one thing, take that.
- **Art is procedurally generated stand-in work**, same as the base set — final in size, framing and lighting, but a pixel artist should redraw the vehicles and signage lettering for ship. Paths and dimensions are correct; swap the PNGs in place.
- In Godot, `grade.js` maps to stacked `ColorRect`s with blend modes, `ambience.js` to an `AnimationPlayer` on a `CanvasLayer`, `stinger()` to four `AnimationPlayer` tracks, and `paperInterrupt()` to a `CanvasLayer` popup scene.
- The 50 NPCs are deliberately **not** given line pools here — their voice should be written against the story beats they appear in, not invented up front. Each note is the brief for that voice.
- Two sprite-heavy elements render blank in exported PNGs (the engine drops CSS-background sprite strips) — open the HTML to see them correctly.

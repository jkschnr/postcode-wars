# Upgrade 02 — Main map & city map

Two templates, both at 1080 × 1920, both built on real geography with the game's data painted over it.
Drop-in: they sit beside the base screens and reuse `../ui.css` and `../chrome.js`.

- **`main-map.html`** — the UK. Replaces screen 01.
- **`city-map.html`** — one city, street level. Replaces screen 02.

They link to each other: **Enter city** on the UK map goes to the city map, **← UK** goes back.

---

## Main map — what changed

The old map was a node network on a dark basemap: correct, but monochrome and inert. This one turns the
country into **a colour map of who holds what**.

1. **Faction influence blooms.** Every city bleeds its holders' colours into the map on a screen-blended
   canvas layer, radius and opacity driven by percentage held. Contested cities show two or three colours
   overlapping. Read the country at a glance: orange is yours, purple is the Vale, gold is Rhodes, blue is trade.
2. **Three kinds of line, not one route web.** Supply (purple), money (gold) and heat (red), each curved and
   dash-animated so the flow direction is visible. London's lines are thicker and faster.
3. **Nodes carry data.** Faction-coloured ring, an arc showing jobs ready out of six, the job count in the
   middle, a red breathing bloom at heat 3+, and a ping pulse on cities with work waiting.
4. **Labels carry the split.** Under each city name, a stacked bar of faction control, the holder and their
   percentage, then daily take and heat. Placement is still measured and collision-free.
5. **Selected-city sheet.** Faction control bars, daily take, heat pips, and the NPCs standing on that manor
   pulled live from `npcs.js`. Tap any node to switch.
6. **Legend** listing only the factions that actually hold ground, ordered by how much.

## City map — what changed

The old city screen was a banner image and a grid of venue tiles. This one is **an actual map of your postcode**.

1. **Postcode blocks as coloured fields.** Eight real Hackney blocks drawn as polygons over the live street
   data, tinted by who runs them, dashed outline when unclaimed, red core when hot.
2. **Block focus.** The chip row under the map focuses one block — everything else dims to 30%.
3. **Venue pins on real coordinates,** labelled, colour-coded by job type (story / graft / wheels / hustle /
   wash / train / storage / contact), with a job count and a ping on the selected one.
4. **A patrol loop and a supply run,** animated over the streets — police blue and supply purple.
5. **Venue sheet with the fascia art** from Upgrade 01 as its header image, the block it sits in, the job
   count, and who is inside.
6. **City stats** in the header: blocks held, daily take, heat.

---

## Notes

- Street data is live OpenStreetMap, graded in CSS. **Bake to flat PNGs before build** — do not ship a tile
  dependency. Blocks, pins and blooms are all drawn in overlay layers, so they survive the swap unchanged.
- The eight Hackney blocks use real coordinates but are hand-approximated polygons — replace with true
  postcode boundaries if you have them.
- Needs `npcs.js` and `art/` from Upgrade 01; both are already copied into this folder.
- In Godot: blooms and block fields are `Polygon2D` with additive material, lines are `Line2D` with a
  scrolling texture, pins are `Control` nodes positioned from lat/lon at bake time.

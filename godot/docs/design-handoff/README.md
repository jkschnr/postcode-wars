# Handoff: Postcode Wars — full UI design set

## Overview

**Postcode Wars** is a click-only crime RPG for portrait mobile, set in 2026-era Britain. No twitch input, no joystick — every action is a tap on a card, a button or a list row. The player runs jobs, launders money, builds a crew and climbs from street shotter to firm boss across 13 UK cities.

This bundle contains the complete visual design for **24 screens**, three spec sheets, all generated art, and the shared CSS/JS that drives them. Target build environment is **Godot 4**, portrait, at a design resolution of **1080 × 1920**.

## About the design files

Everything here is a **design reference created in HTML** — a prototype showing intended look, motion and behaviour. It is **not production code to port line-for-line**.

The task is to **recreate these designs in Godot 4** using `Control` nodes, `StyleBoxFlat`/9-slice textures, and `AnimatedSprite2D` — following the per-screen node stacks documented in `Export Notes.dc.html` and summarised below. The HTML exists so you can see exact colours, sizes, spacing, copy and timing; read it as a spec, not as a source tree.

If the team decides against Godot, the same designs translate cleanly to any framework with a flex/grid layout model — the whole set is built from vertical stacks of full-width rows, with exactly one exception (screen 17, The Board, which uses free placement).

## Fidelity

**High fidelity.** Final colours, typography, spacing, copy, art and motion timings. Recreate pixel-accurately at 1080 × 1920 and scale from there. Every number in this document is the number to build to.

Two caveats:
- **Character portraits and item art are procedurally generated pixel art** — they are final in style, size and slot geometry, but a pixel artist should redraw them for ship. Sizes and file paths are correct; swap the PNGs in place.
- **Icons** are currently CSS shapes (squares, circles, bars). They stand in for a proper icon set and should be drawn before build. Never substitute emoji.
- **Street imagery** is live OpenStreetMap tile data, colour-graded for a wet night. For the build, bake one flat 1080-wide PNG per city and reference it by city key.

---

## Design tokens

### Colour — surfaces
| Token | Hex | Use |
|---|---|---|
| `bg/base` | `#121417` | App background |
| `bg/panel` | `#1E2126` | Cards, panels |
| `bg/panel-raised` | `#2A2E33` | Headers, borders, dividers |
| `bg/inset` | `#0C0E10` | Wells, inputs, list backgrounds |

### Colour — text
| Token | Hex | Use |
|---|---|---|
| `text/primary` | `#EDEFF2` | Headlines, values |
| `text/secondary` | `#9AA0A6` | Body, descriptions |
| `text/muted` | `#5A6068` | Labels, captions, meta |
| `text/inverse` | `#121417` | On hi-vis buttons only |

### Colour — accent & signal
| Token | Hex | Rule |
|---|---|---|
| `accent/sodium` | `#FFA94D` | The brand. Streetlight orange. Appears on every screen. |
| `accent/glow` | `#FFC97A` | Highlights, lit edges, glow cores |
| `accent/hivis` | `#D9E021` | **One CTA per screen. Never two.** |
| `danger/red` | `#D63B3B` | Heat, danger pips, loss, war room |
| `police/blue` | `#2E5EAA` | Arrest, police presence |
| `money/dirty` | `#C9A227` | Gold. Seizable cash. |
| `money/clean` | `#57C785` | Green. Safe cash. |

Dirty and clean money **must never share a colour, a border or a panel**.

### Colour — rarity
| Tier | Hex |
|---|---|
| Basic | `#B9C0C7` |
| Decent | `#6FCF6F` |
| Peng | `#4DA3FF` |
| Certi | `#B06CF0` |
| Iconic | `#F2C14E` |

### Typography
- **Display** — Anton, uppercase. Sizes 220 / 128 / 112 / 96 / 80 / 64 / 48 / 36 / 32 / 28.
- **Body** — Inter (400/500/600/700). Sizes 32 / 28 / 24 / 20.
- **Mono** — IBM Plex Mono (400/500), letter-spacing `0.12em`–`0.20em`, uppercase. Used for every label, code, timestamp and technical caption.
- **Numerals** — always `font-variant-numeric: tabular-nums`. Digits must not re-flow while a counter ticks.
- **Minimum text size is 20 px.** No exceptions.
- Money is exact to £9,999; £10,000 and above abbreviates (`£24.5k`).

### Spacing & geometry
- Step scale: **8 / 16 / 24 / 32 / 48**
- Side gutters **32**, top safe inset **60**, bottom safe inset **40**
- Panel radius **16**, inner element radius **12**, chip radius **8**
- Panel border: **1 px `#2A2E33`**
- Touch targets **≥ 96 px tall**, full width by default
- **No drop shadows.** Depth comes from background contrast, never blur.
- Sodium glow is always radial and soft, bled into the background — never a hard stroke.

### Texture layers (both present on every screen)
- `.tooth` — concrete texture, `art/tex-concrete.png`, 512 px tile, opacity `0.22`, `mix-blend-mode: soft-light`
- `.grain` — fine noise, opacity `0.04`, above content, `pointer-events: none`

---

## Screens

All 24 screens are in this folder, numbered. `00-index.html` links every one of them and is the best entry point.

Each screen is a **vertical stack**: persistent top HUD (140 px including safe inset) → screen content → persistent bottom nav (120 px + 40 px inset). Both chrome pieces come from `chrome.js` — build them once as a scene and instance them everywhere.

### P0 — the core loop
| # | Screen | Purpose | Node stack |
|---|---|---|---|
| 01 | UK map | Choose a city; see debt clock | HUD · map viewport (full-bleed) · location strip · nav |
| 02 | City | Choose a venue within a city | HUD · street banner 820 px · city header over banner · city switcher · venue grid (2 cols × 8) · nav |
| 03 | Job list | Pick a job | HUD · street strip 260 px · header · scroll: STORY / CONTRACTS / GRAFT · nav |
| 04 | Job confirm | Commit to a job | HUD · street 520 px + pin · title · scene panel · numbers grid (4 cells) · advice pop-up · GO / BACK · nav |
| 05 | Reveal | The payoff ceremony | Scrim · stinger · outcome line · duffel bag · loot row (1–3 cards) · character toast · XP bar |
| 06 | Choice card | Dialogue and decisions | Blurred street · scrim 74% · card (animated portrait / speaker / typed dialogue / 2–4 options) · state rail |
| 07 | Character | Stats, skills, gear | HUD · street band 340 px · level block · 4 stat rows · 4 skill tracks · 4 gear tiles · nav |
| 08 | Level up | Rank ceremony | Night street · 2 rain sheets · figure · rank stamp · gains grid (2×2) · XP bar · CTA |

### P1 — the meta
| # | Screen | Purpose |
|---|---|---|
| 09 | Character creation | Look presets, origin, name — 3 steps |
| 10 | Bank (Bung) | Dirty/clean split, deposit slider, wash queue |
| 11 | Crew | Roster + recruitment |
| 12 | Gym | Train stats on timers |
| 13 | Shop / fence | Buy and sell, one card scene for both tabs |
| 14 | Jail / hospital | Held-timer screen. **Grey only — no sodium.** |
| 15 | Messages | Real messaging-app feel, not a quest log |
| 16 | Prison call | Real-time credit clock, transcript above topics |

### P2 — depth
| # | Screen | Purpose |
|---|---|---|
| 17 | The board | Investigation wall. **The one screen with free placement.** Curved string paths between card centres, recomputed on any move. |
| 18 | Codex | People / places / Ledger of Consequences |
| 19 | Trapline | Supply-chain schematic — 90° elbows only, fixed spacing, not geography |
| 20 | Firm | Bank, territory, war room, roster |
| 21 | Leaderboards | Player row always pinned, even at rank 4,000 |

### Spec sheets
| # | Screen | Purpose |
|---|---|---|
| 22 | Paperwork | Document art: warrants, receipts, seizure notices, evidence bags — 2026-era |
| 23 | Motion | Every animation, playable with replay buttons |
| — | `Design System.dc.html` | Colour, type, surface, sample panel at true scale |
| — | `Component Sheet.dc.html` | All 10 components, every state |
| — | `Export Notes.dc.html` | **Per-screen node stack, 9-slice list, repeating elements, single assets.** Read this before building any screen. |

---

## Components

Ten components carry the whole game. Every state of each is documented at true scale in `Component Sheet.dc.html`.

1. **Panel** — one 9-slice, 16 px corners, 1 px `#2A2E33` border, tinted per use
2. **Button** — one 9-slice, four tints: hi-vis (`#D9E021`, dark text) / secondary (panel + muted text) / danger (`#D63B3B`) / disabled (0.4 alpha). 96 px min height.
3. **Job card** — tier badge, title, scene copy, 4-cell stat strip, success bar, CTA. Three tints: available / locked (0.72 modulate) / story (8 px left edge).
4. **Loot card** — 5 rarity tints + cash variant. Flips in with 90 ms stagger.
5. **Stat row** — label, value, bar, delta
6. **Portrait slot** — circle, 2 px ring tinted by faction. Sizes 200 / 132 / 96 / 88 / 84 / 76.
7. **Bar** — 9-slice track + fill, chunked in steps. Never a smooth sweep on XP.
8. **Pip** — single 14–24 px asset, tinted. Used for heat, danger, rarity.
9. **Timer ring** — 56 / 64 / 520 px asset + shader arc
10. **Chip** — cost, tag, consequence, city switcher. 8 px radius, mono label.

---

## Interactions & behaviour

### Screen transitions
- **Forward** — slide in from right, **240 ms**, `cubic-bezier(.2,.8,.3,1)`
- **Back** — slide out right, **200 ms**, `ease-in`
- Cards inside a screen enter at scale `0.96 → 1.00`, **120 ms**, staggered

### Reveal ceremony (screen 05 — the most-seen screen in the game)
1. Scrim fades, stinger hits
2. Duffel drops: `translateY(-120px) scale(0.96)` → overshoot `+8px scale(1.01)` → rest. **420 ms**, `cubic-bezier(.2,.8,.3,1)`. Lands heavy.
3. Loot cards flip in: `rotateY(90deg) scale(0.94)` → rest, **260 ms**, **90 ms stagger** between cards
4. Cash **counts up** over 900 ms with a cubic ease-out — it never cuts in
5. Glow pool and bag rim take the colour of the **best** rarity in the drop
6. Character toast slides down like a text message: **420 ms** with a `translateY(6%)` overshoot, holds 3 s

### Level up (screen 08)
- Rank stamp: `scale(1.5) rotate(-5deg)` → `scale(1) rotate(-2deg)`, **480 ms**
- Two rain sheets scroll at different speeds behind
- Rank word must fit 12 characters

### Choice card (screen 06)
- Speaker's portrait is an animated sprite; **mouth flaps only while the line types**
- Dialogue types out at **~46 characters/second**
- Portrait blinks on a random **1.8–5 s** timer when idle
- Options are min 96 px and grow to two lines rather than truncating
- Consequence hints are right-anchored and tinted by outcome
- Three states share one scene: conversation, stat check, costly

### Animation helpers (`anim.js`)
| Function | Purpose |
|---|---|
| `sprite(el, {src, frames, fw, fh, fps, loop})` | Horizontal strip player, nearest-neighbour |
| `talkingHead(el, src)` | Idle blinks + `.say(ms)` mouth flaps |
| `typeOut(el, text, cps, done)` | Character-by-character dialogue |
| `countTo(el, target, ms, fmt)` | Cubic ease-out number count-up |

### Sprite strips (in `art/`, 4× nearest-neighbour, ready for `AnimatedSprite2D`)
| Strip | Frames | FPS | Loop | Frame size |
|---|---|---|---|---|
| `anim-<character>.png` × 16 | 4 (idle / blink / mouth ½ / mouth open) | 9 | no | 96 × 120 |
| `anim-shutter.png` | 6 | 10 | no | 64 × 64 |
| `anim-stamp.png` | 5 | 14 | no | 64 × 64 |
| `anim-moped.png` | 4 | 9 | yes | 64 × 48 |
| `anim-lamp.png` | 4 | 6 | yes | 64 × 64 |

---

## State

The prototype fakes state; the build needs it real. Minimum set:

**Player** — level, XP, name, look preset, origin, 4 stats (with caps), 4 skill tracks, energy, nerve, heat, city, dirty cash, clean cash, debt, inventory, equipped gear (4 slots)

**World** — 13 cities each with venues, heat and danger; job pool per venue with expiry timers; wash queue (4 slots, each with amount / fee / remaining time); gym queue (3 slots); crew roster (each with class, loyalty, wage, idle flag); board leads (position, connections); trapline stops (health, take); firm (bank, territory %, roster, rank)

**Cast** — 16 characters, each with met/unmet flag, relationship value, faction, and a line pool. Definitions and copy are in `cast.js`.

**Consequence ledger** — append-only. Entries are never removable and never payable; they only accumulate.

**Transitions to watch** — energy spent up front on a gym session, not on collect. A maxed stat locks to rarity gold and drops out of selection. Idle crew get a gold border because it is the only prompt that they cost wages for nothing.

---

## Assets

All in `art/` (75 files). All procedurally generated in-project — no third-party licensing.

- **9 texture plates**, 512 × 512, tiling: concrete, wet tarmac, brick, shutter, scratched metal, plastic, paper, fabric, duffel canvas
- **6 character environment plates**, 448 × 560: barbershop, office, car park, kitchen, tower flats, yard
- **12 item arts**, 520 × 400: phone, card reader, jammer, ledger, till codes, keys, trainers, jerry can, plate set, bolt cutters, Transit keys, hi-vis
- **16 pixel character sprite strips**, 4 frames each at 96 × 120, upscaled 4×
- **4 prop sprite strips** (sizes above)
- **Paperwork art** — warrants, receipts, seizure notices, evidence bags; see `22-paperwork.html`

Street imagery is fetched live from OpenStreetMap tiles at runtime and graded in CSS. **Bake these to flat PNGs before build** — do not ship a tile dependency.

## Reference screenshots

`screenshots/` holds a **1080 × 1920 PNG of every screen**, captured from the live design at true resolution. Use them for pixel measurement and side-by-side comparison while building.

Two known gaps in the PNGs — the live HTML is correct in both cases, so open the HTML when in doubt:
- **Animated sprite portraits** (screen 06 choice card, screen 23 motion sheet) render as empty frames. The export engine drops CSS-background sprite strips. The strips themselves are in `art/anim-*.png` and the still portraits in `art/px-*.png`.
- **A single external map tile layer** may be blank on the map screens. Street imagery is fetched live from OpenStreetMap; bake it to flat PNGs before build (see Fidelity, above).

Every other element — layout, type, colour, item art, character art, textures, paperwork — is captured exactly as designed.

## Files

| File | Contents |
|---|---|
| `00-index.html` | Links every screen — start here |
| `01`–`23-*.html` | The 24 screens |
| `ui.css` | Shared tokens, panel/button/chip classes, grain and tooth layers, scroll behaviour |
| `chrome.js` | Persistent top HUD and bottom nav, instanced on every screen |
| `cast.js` | 16 characters: names, roles, places, line pools, portrait briefs |
| `art.js` | Content-name → art-path mapping for items and characters |
| `anim.js` | Sprite player and motion helpers. Also holds `__capPrep()`, a capture-time-only helper used to export the reference PNGs — not game code, safe to delete. |
| `atmos.js` | Rain, glow and street-grading layers |
| `Design System.dc.html` | Colour, type, surface, sample panel |
| `Component Sheet.dc.html` | All 10 components, all states |
| `Export Notes.dc.html` | **Per-screen build spec — read first** |
| `support.js` | Runtime for the three `.dc.html` spec sheets only. Not game code. |
| `art/` | All 75 art files — textures, character plates, item art, pixel portraits, sprite strips |
| `screenshots/` | 1080 × 1920 reference PNG of every screen |

## Before you build

Read `Export Notes.dc.html` first. It carries the global geometry rules, the shared-asset list, and a per-screen block naming the container stack, which panels are 9-slice, which rows repeat and at what count, and which pieces ship as single assets. Everything in this README is context for that document.

Two things a developer cannot derive from these files and will need from the design side:
1. **Character portrait photography or final pixel art** — briefs for all 16 are written into `cast.js`
2. **A drawn icon set** — the CSS shapes in the prototypes are placeholders

# Code map — where things live

Godot 4 project in `godot/`. UI-only (Control nodes), portrait 1080×1920.

## Autoloads (`godot/autoload/`)
| File | Role |
|---|---|
| `config.gd` | Loads all tuning from `data/*.json`; single source of numbers |
| `save.gd` | Local `user://` persistence (the M1 store) |
| `server_gateway.gd` | **The one seam.** Every action goes through here. LocalGateway now; NakamaGateway (same signatures) at M3 |
| `game.gd` | Session state + getters/mutators (money, energy/nerve/heat, level, save) |
| `audio.gd` | Minimal procedural SFX |

## Systems (`godot/systems/`) — pure & testable
| File | Role |
|---|---|
| `xp.gd` | Level curve `round(base·L^exp)`, apply XP, level-ups |
| `resolver.gd` | Job success chance + seeded outcome tiers (no minigames) |
| `economy.gd` | Wash fees, loss caps |

## Data (`godot/data/`) — all tuning, no magic numbers in code
`cities.json` (London+boroughs, Manchester, Birmingham) · `jobs.json` (6) ·
`levels.json` (curve, per-level grants, milestone unlocks) · `ranks.json` ·
`encounters/pack1.json` (8 choice cards).

## Screens (`godot/screens/`)
`boot` · `creation` · `map` (UK nodes) · `city` (borough sub-nodes + venue grid) ·
`jobs` (job list + confirm/approach + resolve) · `character` (level/XP/stats).

## UI components (`godot/ui/`)
`pal.gd` (palette/fonts/widgets + paper-document styles + asset loaders) ·
`choice_card.gd` (encounters, as cream-paper dossiers) · `reveal_overlay.gd`
(the §7.5 reveal) · `level_up_ceremony.gd` · `stamp.gd` (`InkStamp` — the rotated
worn ink stamp used on outcomes/titles). A global grain + vignette "glass" layer
lives in `main.gd`.

## Shell (`godot/main.gd` + `main.tscn`)
Background, persistent top HUD (dirty/clean/EN/NV/heat/level+XP), bottom nav
(Map·City·Me·Crew·Firm), screen manager, and a CanvasLayer overlay for cards,
reveal, ceremonies and toasts.

## Art (`godot/art/` + `godot/tools/`)
**Papers, Please** style — procedural pixel-art (no diffusion API available here).
`tools/generate_art.py` (Pillow) generates: `art/portraits/p00..p15.png` (grim ID
mugshots), `art/cities/<id>.png` (overcast skylines), `art/gear/<id>.png` (icons).
All graded: desaturate → sepia → Bayer dither → posterise. Regenerate with
`python3 godot/tools/generate_art.py`. Textures render nearest-neighbour
(`default_texture_filter=0`). `Pal.portrait_tex/portrait_for/city_tex/gear_tex`
load them; `Pal.portrait_frame` frames one as an ID card. Swap for real AI art
later by dropping PNGs into the same paths.

## Server (`godot/server/nakama/`)
`docker-compose.yml` + `src/main.ts` runtime stub — **inert until M3**.

## Verifying
- Logic: `ENDS_TEST=1 godot --path godot --headless` runs a 60-job playthrough and
  prints level/money progression (`SELFTEST OK`).
- Visuals: `ENDS_SHOT=1 ENDS_SCREEN=<screen> ENDS_SHOT_NAME=x godot --path godot`
  writes a PNG of any screen (screens: boot/creation/map/city/jobs/character;
  `ENDS_SHOW=encounter|reveal|levelup` for overlays; `ENDS_DEBUG=1` seeds a
  character with money/XP).

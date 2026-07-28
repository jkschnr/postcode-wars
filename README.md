# Postcode Wars — *ENDS*

> *from wasteman to Top Boy, one postcode at a time.*

A **click-only crime RPG on a map of the UK**, built in **Godot 4**. You're one
character. You start as a nobody in London and grind criminal work — tapping a
city to travel, tapping a job to pull it, tapping choices when NPCs pop up — until
you're level 100 and the biggest boss in the country.

**No walking, no joystick, no minigames.** The whole game is screens, lists, cards
and buttons. Clash-of-Clans in structure (tap · timers · collect · upgrade · async
conflict), an RPG character sheet in progression, Top Boy in voice.

This repo is the **M1 vertical slice** — "The Spine" — playable end-to-end.

---

## ▶ Play it

**Double-click `Spustit Hru.command`.** It finds Godot and runs the game in a
portrait window. (Or open the `godot/` folder in the Godot 4 editor and press F5.)

Godot 4.x is required — get it from [godotengine.org](https://godotengine.org).

## 🎮 What's in M1

- **Character creation** — street name, look, origin (with starting bonuses).
- **UK map** — tap London / Manchester / Birmingham to travel (level-gated).
- **City → boroughs** — London opens into The Strip, Rimley Market, The Docks,
  each with its own job list; danger scales the risk and reward.
- **Jobs** — phone snatch, pickpocket, shoplift, burglary, corner shotting, chop
  run. Success chance always shown. Some jobs offer an **approach choice**
  (go quiet / kick it in / come back later) that shifts the odds.
- **The reveal** — duffel drops, rarity glow, cash counts up, CRIT / near-miss
  stingers, XP chunk.
- **Choice cards** — NPCs (Uncle T, the Plug, Keisha, the feds…) pop up with text
  and 2–4 options; stat-checks pass or fail.
- **Progression** — level 1–100 spine, XP bar, 4 allocatable stats, rank titles,
  milestone unlocks with a full-screen ceremony.
- **Resources** — dirty vs clean money, Energy, Nerve, heat; local save.

## 🗂 Structure

```
hra/
├─ Spustit Hru.command        ← double-click launcher
├─ README.md
├─ docs/                      ← design + roadmap (docs/00-INDEX.md), source docs in docs/design/
└─ godot/                     ← the Godot 4 project
   ├─ project.godot           (portrait 1080×1920, Control-only, gl_compatibility)
   ├─ main.gd / main.tscn     app shell: HUD · bottom nav · screen manager · overlays
   ├─ autoload/               Config · Save · ServerGateway · Game · Audio
   ├─ systems/                pure logic: xp · resolver · economy   (testable)
   ├─ data/                   ALL tuning as JSON: cities · jobs · levels · ranks · encounters
   ├─ screens/                boot · creation · map · city · jobs · character
   ├─ ui/                     pal (theme) · choice_card · reveal_overlay · level_up_ceremony
   └─ server/nakama/          docker-compose + TS runtime — INERT until M3
```

## 🔌 The gateway seam

Every consequential action goes through `autoload/server_gateway.gd`. M1 ships a
**LocalGateway** (runs client-side, zero infra). M3 adds a **NakamaGateway** with
identical method signatures — the rest of the game doesn't change by one line,
because no game logic lives in the UI scenes.

## 🧭 Roadmap

M1 Spine (this) → M2 flavour & depth (40+ encounters, heat/jail, gym, gear, more
cities) → M3 server (Nakama) → M4 organisation (crew, county lines, territory) →
M5 firms & war. See [docs/03-milestones.md](docs/03-milestones.md).

*Real England, fictional people. 18+. Everyone is an adult; product is abstract;
violence is stylised (KO, not kill).*

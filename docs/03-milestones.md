# Milestones

Ship each playable end-to-end before starting the next.

### ✅ M1 — The Spine  *(this build)*
Character creation → UK map (3 cities) → city → borough → job list (6 jobs) →
confirm/approach → resolve → reveal → XP & levels → Energy/Nerve regen →
dirty/clean money → local save. LocalGateway only. Choice-card component live
(used for approaches + a starter encounter set). **Verified**: all screens
screenshot-clean; headless smoke test drives 60 jobs → level 6 cleanly.

*Not yet, by design:* travel timers, heat consequences/jail, gym/gear/shop as
live venues (they're teased, locked).

### ✅ M2 — Flavour & Depth  *(this build)*
**9 cities** (Glasgow, Liverpool, Leeds, Nottingham, Bristol, Newcastle added) with
level gates + specialities; **15 jobs** across tiers (ram-raid, warehouse, smuggle,
counterfeit, card fraud, extortion, gun deal…); **gym** stat-training with timers;
**bank/Bung** laundering dirty→clean with timers; **shop** (gear that raises your
odds) + **fence** (sell loot); **heat → arrest → jail** (bail / Brief / wait);
**travel timers** (transit banner + arrive); **41 choice cards**. Venues live &
level-gated in the city grid. *Notifications:* in-app "ready"/collect states are in;
OS push is a mobile concern deferred to M3. Verified: all screens screenshot-clean,
smoke test 60 jobs → ~80% success with arrests firing.

### ⬜ M3 — Server
Nakama: accounts, server-authoritative resolution, the ledger, timers,
leaderboards. Implement `NakamaGateway` against the stub in
`godot/server/nakama/` — swap the `ServerGateway` autoload, no other changes.

### ⬜ M4 — Organisation
Crew recruiting/assignment; county lines (Trapline); NPC gang factions + beef;
territory claiming.

### ⬜ M5 — Firms & War
Player gangs, async raids & wars, seasons, full leaderboards.

## Dopamine / entertainment pass (on top of M1–M2)
Old GDD §18 made real: **Graft Streak** (consecutive wins → up to +60% payout/XP,
wiped by a fail/arrest; 🔥 HUD chip + reveal tick) · **juiced reveal** (screen-shake,
confetti + fanfare on crits, cash-tick SFX count-up, **NEW BEST** flag) ·
**numbers-go-up HUD** (money counts up/down, XP bar pulses) · **next-unlock hook**
(always a bar near full) · **Daily Graft** (3 rotating tasks + rewards + daily streak,
paper checklist, "● N READY" callout) · **milestone stamps** (first crit, big haul,
new city) · **confetti level-ups**. See `ui/stamp.gd`, `ui/confetti.gd`,
`ui/daily_panel.gd`; streak/records/dailies live in `game.gd` + `server_gateway.gd`.

## Level → unlock (data/levels.json)
1 petty jobs · 5 Manchester · 10 crew + laundering · 15 tier-2 · 20 Birmingham &
Glasgow · 25 county lines · 35 territory · 50 firms · 60 heists · 75 war ·
90 endgame cities · 100 **Top Boy**.

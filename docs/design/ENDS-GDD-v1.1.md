# ENDS
### Game Design Document — v1.1
**Title:** ENDS — *confirmed*
**Genre:** Persistent-world crime RPG · 2D top-down real-time · Mobile-first
**Setting:** Present-day England. Real cities, real problems, fictional people.
**Status:** Fundamentals locked. This document covers gameplay, front-end, logic, art direction and MVP roadmap. Backend/infra intentionally out of scope for this phase.

---

## 0. One-Page Pitch

You're a nobody from the ends. No money, no name, no mandem — just a dead phone and a postcode that doesn't rate you.

**ENDS** is a persistent multiplayer world set in today's England, played from a gritty top-down view. You start off grafting petty jobs — snatching phones on the high street, shotting on a corner, creeping through back windows — and you build. Recruit your own crew of youngers and enforcers. Take over a bando and fortify it. Run county lines out to sleepy little towns. Wash your paper through a chicken shop. Beef with NPC firms that hold the map, take their postcodes block by block, and when your firm is certi enough — go to war with real players' gangs, Clash-of-Clans style: scouted, scheduled, raided.

The world is live and dangerous, but **the danger is by choice**: NPC opps patrol the roads, feds escalate when you get greedy, and street robbers clock you when your pockets are heavy — yet nobody's session ever gets ruined by a random player. Player-vs-player conflict lives inside the war system, where it's fair, dramatic, and worth showing up for.

Sessions are short and loaded. Five to fifteen minutes: collect your Ps, burn your energy on live jobs, set your timers, bounce. Come back when your trap's stacked, your crew's trained, or — the big one — when your phone buzzes: **"RAID ON YOUR TRAP HOUSE. DEFEND IT."**

Every job ends in a reveal. Every session ends with two bars at 90%. Every week ends with a war story.

**The fantasy in one line:** *from wasteman to Top Boy, one postcode at a time.*

---

## 1. Locked Design Decisions

These were decided during concept phase and everything in this document is built on them:

| # | Decision | Choice |
|---|----------|--------|
| 1 | Format | 2D top-down **real-time world** (not menu-driven) |
| 2 | Pacing | **Short bursts, several times a day** — energy + timers |
| 3 | Visual style | **Gritty realism** — Top Boy palette and mood |
| 4 | Platform | **Mobile first** — touch, virtual joystick |
| 5 | Combat | **Simple** — stats and gear decide, light tactical input |
| 6 | PvP | **No open-world PvP.** NPC threat fills the streets; player conflict happens in CoC-style scheduled/async wars, with optional live defence |
| 7 | Orientation | **Landscape** — two-thumb play, wide FOV |

**v1.1 update:** orientation is locked to **landscape** (§19.1) and the title **ENDS** is confirmed.

---

## 2. Vision & Design Pillars

### 2.1 The Fantasy
Rags-to-riches on road. The player should feel the specific, textured fantasy of modern UK street life as told by Top Boy: grey estates, wet tarmac, sodium lights, the constant hum of risk, the loyalty of a small crew, and the slow, dangerous climb from invisible to untouchable.

### 2.2 Design Pillars
Every feature must serve at least one pillar. If it serves none, it gets cut.

1. **Every job is a moment, not a menu.** Crimes are played, live, in the world — 10 to 60 seconds of hands-on tension with a reveal at the end. Never a button that says "Commit crime."
2. **Always three bars near full.** The player is never without a near-complete goal. Skill about to level, business about to cap, rank about to tick. "One more thing" never ends.
3. **Risk is a choice, never a surprise.** The world is dangerous — but the player always opted into the danger (crime on opp turf, heavy pockets, an escort run, a war). No random griefing, ever. Loss is capped and legible.
4. **The phone is the game.** All UI is diegetic through the character's smartphone. If a real roadman would do it on his phone, the player does it on the in-game phone.
5. **Real England, fictional people.** Real cities, real postcodes, real problems (county lines, knife crime, CCTV Britain) — but every gang, estate name, brand and character is fiction. Authentic, never exploitative (§21).

### 2.3 Target Audience
- Core: 18–34, UK + Europe, mobile-native, raised on GTA / Top Boy / drill culture, currently playing mid-core mobile (Clash of Clans, Last War, Hustle Castle) or nostalgic for browser mafia games (Torn, Omerta).
- Secondary: strategy/management players who never touch action games — the async war + crew + economy layer is a full game for them.
- Explicitly 18+ product (PEGI 18 / ESRB M expected — see §21).

### 2.4 Session Promise
"Give me 7 minutes, 3–5 times a day, and I'll give you: a collect, three live jobs with loot reveals, one meaningful upgrade decision, and one thing to look forward to."

---

## 3. Glossary — Slang as System Language

The slang isn't decoration; it's the game's terminology. Each term maps to a mechanic. This doubles as a mechanics index.

| Term | Meaning | Where it lives in-game |
|------|---------|------------------------|
| **Ends** | your area, home turf | Game title; your spawn district |
| **Mandem** | your people, the crew | Firm roster (players + NPC crew) |
| **Opps** | enemies, rival gang | NPC factions & enemy firms; "Opp radar" on map |
| **Roadman** | someone living the street life | Rank 3 in progression ladder |
| **Top Boy** | the one running things | Final rank; firm leader title |
| **Younger** | junior crew member | Cheapest recruitable NPC class |
| **Older / Elder** | senior gang figures | Mid/high player ranks; mentor NPC ("Uncle T") |
| **Graft** | hustle, work | The daily task system ("Daily Graft") |
| **Trap / trap house** | spot where product moves | Your base — the CoC-style buildable |
| **Bando** | abandoned house | Starter-tier trap house |
| **Shotting** | selling product | Corner-dealing activity |
| **Shotter** | street dealer | Income-generating NPC crew class |
| **Food / product** | drugs (abstracted) | The commodity in trap/line economy — never named or depicted beyond "product" |
| **Line** | a drug phone line | County Lines system; the Trapline app |
| **Going OT / country / the cunch** | working a line out of town | County-lines destination towns |
| **Plug** | supplier | NPC contact who sells you product stock |
| **Ps / paper / bread** | money | Currency naming across UI |
| **A bag** | £1,000 | Economy shorthand in UI ("2.4 bags") |
| **Whip** | car | Vehicle system |
| **Ped** | moped | First vehicle; snatch-crime enabler |
| **Dinger** | stolen car | Chop-shop delivery item |
| **Shank / Rambo** | knife / big knife | Melee weapon tiers |
| **Strap / wap** | firearm | Endgame weapons — loud, massive heat |
| **Bally** | balaclava | Identity-concealment gear (CCTV mechanic) |
| **Drip** | outfit, style | Clothing system: stats + status |
| **Peng** | high quality | Item rarity tier |
| **Certi** | certified, proven | Item rarity tier; rank 6 |
| **Bare** | a lot | Flavour copy |
| **Wasteman** | a nobody | What NPCs call you at rank 1 |
| **Feds / jakes** | police | Heat & police system |
| **The Brief** | your lawyer | Contact who reduces jail time |
| **Duppy'd** | knocked out / done in | KO state after losing a fight |
| **Patterned** | sorted, arranged | Quest-complete flavour ("say no more, it's patterned") |
| **Link** | to meet / a connection | Contact system verb |
| **Beef** | active conflict | The NPC-faction aggression meter |
| **Stripes** | earned respect marks | War scoring unit (our "stars") |
| **On road** | active in street life | Online/active status in Firm roster |

Writing rule for all game copy: slang is used naturally and confidently, never explained in-fiction, never forced. A tooltip system ("long-press any word") quietly translates for non-UK players.

---

## 4. World Structure

### 4.1 Macro Map — England
The country map is the top navigation layer: a stylised, dark, rain-slicked map of England with city nodes and county-line routes drawn between them like a transit diagram.

**Launch city:** London.
**Expansion cities (post-launch order):** Birmingham → Manchester → Liverpool → Leeds → Nottingham.
**Satellite towns (county lines only, not walkable):** Luton, Ipswich, Margate at launch; each expansion city adds 2–3 of its own (e.g. Manchester → Blackpool, Wrexham; Liverpool → Rhyl).

Each city has a **speciality** that shapes its economy and crime mix, so travel is strategic, not cosmetic:

| City | Speciality | Unique content |
|------|-----------|----------------|
| London | Everything, highest prices, highest heat | All systems; jewellery smash-and-grab |
| Birmingham | Chop shops & car culture | Best dinger prices; car-theft contract chains |
| Manchester | Product wholesale | Cheapest plug prices; grow-op content |
| Liverpool | The docks | Port smuggling; container heists; import gear |
| Leeds | Counterfeit & fraud | Fake goods economy; card-cloning jobs |
| Nottingham | Guns (endgame) | Only reliable strap plug in the game |

### 4.2 City Structure — London at Launch
A city = a set of hand-crafted walkable **districts** plus a city map screen. Districts are separate scenes (~60–90 seconds to walk across), connected by a fast-travel city map (bus/tube flavour, instant, small fee) — no boring overworld walking between them.

Following the Top Boy model: **real city, real postcode, fictional places inside it.** Summerhouse isn't a real estate; ours aren't either.

**London launch districts (5):**

**D1 — The Fields (Marlow Fields Estate), E8 — SAFE ZONE**
Your ends. Brutalist council blocks around a courtyard, walkways, a caged football pitch, Bossman's corner shop, "Iron Temple" gym under the arches, your first bando. All tutorial content lives here. No NPC aggression, no heat accumulation. The emotional home base — this is where your drip gets clocked and your rank gets respected.

**D2 — The Strip (West End high street), W1 — LOW-RISK / HIGH-CCTV**
Crowds, lights, tourists with phones out. Pickpocketing, phone snatching, shoplifting, ticket touting. Dense CCTV: identity mechanics matter here (§8.4). Feds respond fast but the crimes are petty — jail stints are short. The "learn to read crowds" district.

**D3 — Rimley Market, SE15 — CONTESTED**
A covered market and surrounding terraces. Extortion (protection money from stalls), fencing stolen goods, mid-tier burglary. Held at launch by the **Green Lane Boys** (NPC). This is the first district players will realistically take postcode control in. Territory control points: the market gate, the railway arch lockups, the pub.
   
**D4 — Neon Row (Shoreditch-style night strip), E2 — NIGHT ECONOMY**
Dead by day, alive 20:00–04:00 real time. Club-adjacent shotting, touting, jacking drunk city boys, and the best Feed-flex venue in the game (being seen here in top drip = rep bonus). NPC faction: **Cold Mile Crew**. Night-only jobs give +30% payouts.

**D5 — The Docks (Silvertown industrial), E16 — HIGH-STAKES**
Warehouses, container yards, lockups, the chop shop ("Delroy's"). ATM ram-raids, warehouse jobs, cargo theft, endgame heist staging. Held by the **Docklands Firm** — the strongest NPC faction in London. Highest payouts, hardest patrols, armed response territory.

Each district ships with: 1 unique ambient soundscape, 2–4 crime types tuned to it, 1 resident NPC faction, 3 territory control points (if contested), and 2–5 named interactable venues.

### 4.3 Zone Rules
| Zone type | NPC aggression | Player heat | Territory | Notes |
|-----------|---------------|-------------|-----------|-------|
| Safe (D1) | None | None gained | No | Social + management hub |
| Low-risk (D2) | Reactive only | Fast decay | No | Petty crime playground |
| Contested (D3, D4) | Beef-based patrols | Normal | Yes — postcode control | Core mid-game |
| High-stakes (D5) | Proactive patrols | Slow decay | Yes | Endgame; best loot |

### 4.4 Travel
- **Within a city:** instant fast-travel via city map, £5–£20 flavour fee. Walking between adjacent districts also possible through connector streets (for immersion + ambush events later).
- **Between cities:** real-time timer travel. London↔Birmingham 25 min, ↔Manchester 40 min, ↔Liverpool 45 min. By coach (free, slow), train (fee, −30% time), or your own whip (fastest, but your whip is then in that city). While travelling: world locked, phone fully usable (chat, management, marketplace). Travel is deliberately a return-trigger: start a trip, close the app, get the "You've touched down in Brum" notification.
- **To satellite towns:** you don't travel there. Your **runners** do (§9). Or you escort a shipment — a special convoy event (§9.4).

### 4.5 Time & Weather
- Server clock = **real UK time.** Night is 20:00–06:00. Night buffs: +20–30% payout on most street crime, −25% CCTV effectiveness, +NPC danger. This aligns crime prime-time with players' real evenings — the world is at its best exactly when the audience is free.
- Weather: dynamic, ~35% chance of rain blocks. Rain: −15% witness reports (lower heat gain), puddle/reflection rendering, thinner NPC crowds. Storms (rare): unique "blackout" events — CCTV offline district-wide for 20 min, announced 5 min ahead. Everyone converges. Chaos. Beautiful.


---

## 5. Session Design & Resource Systems

### 5.1 The Session Skeleton
Target session: **5–15 minutes, 3–5 times a day.** Every session follows the same satisfying three-beat shape:

1. **COLLECT (60–90s)** — walk out of your trap, collect stacked income (shotters, businesses, territory tick, finished line runs), claim Daily Graft progress, read the Feed. Small guaranteed dopamine to open.
2. **SPEND (3–10 min)** — burn Nerve and Energy on live jobs, fights, a raid, or training top-ups. This is the hands-on play.
3. **SET UP (60s)** — queue the timers: start gym training, restock a line, send a runner, start travel, kick off a trap-house upgrade, list items on the marketplace. Leave with everything cooking.

Design rule: **the app must never open onto nothing.** If the player somehow has zero collects and zero resources, the world offers a free opportunity (a street event, a contact call, a limited job) within 30 seconds.

### 5.2 The Three Resources

| Resource | Governs | Cap (base) | Regen | Full from empty | Design intent |
|----------|---------|-----------|-------|-----------------|---------------|
| **Energy** | Physical acts: fights, raids, gym | 100 | +1 / 3 min | 5 h | Paces combat & training; ~3–4 sessions/day rhythm |
| **Nerve** | Crimes | 20 | +1 / 9 min | 3 h | Separate spend-track so a session always has two things to burn |
| **Stamina** | Sprinting in-world | 100 | +10 / s (after 2 s pause) | seconds | Free, in-moment only; makes chases feel physical |

- Caps grow with progression: Energy +5 per trap-house tier (max 150), Nerve +2 per rank (max 40).
- Overflow rule: resources stop regenerating at cap — the classic "don't waste it" return trigger. Notification fires at 100% (opt-in, §18.6).
- No paid instant-refill loops in core design (monetisation phase later, but the economy is built to survive without selling energy — §22.4).

### 5.3 The Timer Layer
Everything below runs while the app is closed. Timers are the heartbeat of retention:

| Timer | Duration | Return trigger created |
|-------|----------|------------------------|
| Gym session (queued) | 45 min per session, queue up to 3 | "Training done — collect gains" |
| Shotter income tick | caps at 6 h | "Your corner's stacked" |
| Territory income tick | caps at 8 h | "Postcode Ps ready" |
| Laundering batch | 2–8 h by amount | "Money's clean" |
| Line resupply cycle | 8 h | "The line's dry — restock" |
| Runner round trip | 3–6 h by town | "Runner's back with the Ps" |
| Crew training | 1–12 h by class/level | "Enforcer ready" |
| Trap-house upgrade | 1 h – 3 days by tier | "Build done" |
| Defence repair post-raid | 2 h | "Trap's patched up" |
| Heat decay | −1 pip / 10 min | "You've cooled off" |
| Hospital / Jail | 10–45 min | "You're back on road" |
| Inter-city travel | 25–45 min | "Touched down" |
| War prep phase | 24 h | "War starts tonight" |

Rule of thumb: at any moment a player is retaining ≥3 active timers, staggered so at least one completes within the next 2–4 hours during waking time.

### 5.4 Anti-Burnout Guardrails (deliberate)
Hooks that respect the player last longer than hooks that squeeze them. Torn has run twenty years on exactly this balance.
- Daily streaks have **1 free freeze per week** (miss a day, streak survives).
- All caps are generous enough that a 3-session day loses nothing vs a 10-session day.
- No mechanic ever punishes *not* logging in beyond capped income (nothing is destroyed or stolen offline outside declared wars, and wars have shields).
- Notification volume is hard-limited (§18.6): max 4/day, only high-arousal events.

---

## 6. The Player Character

### 6.1 Creation Flow (3 steps, <90 seconds)
1. **Face & body** — quick-pick presets + skin tone, hair, facial hair. (Deep customisation lives in drip, not faces — faces are small on a top-down sprite.)
2. **Origin** — one of three backgrounds. Flavour + starting bonus, not a class lock:
   - **Grew Up On Road** — +2 starting Slickness, knows the E8 Mandem youngers by name (reduced starting beef with them).
   - **Dropout Athlete** — +2 Strength, +10 Stamina cap. Gym trains 10% faster.
   - **College Boy** — +15% laundering efficiency, starts with the OddJobz app unlocked (§15.4). NPCs rate you less at first ("look at this mans").
3. **Name & tag** — street name (unique) + your spray-tag design (pick a style + two colours; this literally marks your territory later, §14.2).

### 6.2 Stats (4, trained)
| Stat | Affects | Trained by |
|------|---------|-----------|
| **Strength** | Fight damage, ram-raids, carrying capacity | Gym (Energy + timer) |
| **Toughness** | HP, damage resistance, hospital time reduction | Gym |
| **Speed** | Flee chance, chase escapes, snatch success, travel perks | Gym |
| **Slickness** | Stealth-crime success, lockpicking, pickpocket yield, scam resistance | **Not gym-trainable** — grows only from doing crimes. You learn slick by being slick. |

- Range 1–100. Soft cap curve: training time per point doubles every 20 points.
- Gym flow: pick stat → queue 45-min sessions (each costs 10 Energy) → collect gains later. Higher-tier gyms (other cities, firm-owned) give better gains/hour — a travel motivator.

### 6.3 Crime Skills
Every crime type has its own skill track, level 1–20, XP from doing it. Levels unlock **better variants, not just bigger numbers** — this keeps old activities fresh:
- *Pickpocket 5:* can lift watches, not just wallets. *10:* read a mark's carry value before committing. *15:* crowds no longer slow you. *20:* "Fingersmith" title + gold hand icon by your name.
- Same pattern for all crime tracks (full unlock tables in Appendix A.2).

### 6.4 Drip — Clothing Is Stats AND Status
Clothing gives small stat/utility bonuses and is **visible on your sprite to everyone.** Drip is the primary flex economy and the primary cosmetic economy.

- Slots: headwear, jacket, top, bottoms, footwear, accessory ×2, bally (own slot).
- Rarity tiers (slang-native): **Basic → Decent → Peng → Certi → Iconic.**
- Set bonuses, e.g. *Full Northside* (puffer + tech bottoms + triple-S style trainers): +5% snatch payouts, "clocked" rep aura in Neon Row.
- **The bally trade-off (core tension):** bally on = −60% CCTV identification during crimes, but in safe/low-risk zones NPCs react ("why's mans wearing a bally in Tesco"), feds stop-and-search chance rises, and your drip flex is hidden (no rep aura). Wear it for work, not for show.
- Iconic pieces are seasonal/limited (war rewards, event drops) — the long-term status chase.

### 6.5 Inventory & Carrying
- Slots-based pocket inventory (12 base; jackets/bags add slots).
- **Dirty cash is carried as a physical wad** with weight-lite rules: the more you carry, the more street robbers clock you (§11.4) and the more you lose when duppy'd. Banking/washing is the safety valve — friction by design.
- Stash: home trap house has a stash room (raid target, §13).

---

## 7. Crimes & Activities

Design law (Pillar 1): every crime is a **live micro-play** in the world: *approach → execute (skill/timing beat) → outcome roll → reveal ceremony.* 10–60 seconds. Full tuning tables in Appendix A.1; below, each crime's design.

### 7.1 Tier 1 — Petty (Rank 1+, Nerve 2–3)

**PHONE SNATCH** — *The Strip, Neon Row*
Marks walk with a glowing phone out. On foot: shoulder-check timing tap as you pass. On a ped: drive-by lane, tap in the swipe window. Fumble the timing → mark yells, fed-proximity chase meter starts — sprint through alleys till it drains. **Crit:** it's the new flagship model (sells 4× on Shifted). *This is the tutorial crime — it teaches movement, timing, chases and the reveal in one 30-second package.*

**PICKPOCKET** — *The Strip*
Trail a mark, stay inside the "shadow cone" behind them (drifts as they turn), hold to lift when the tension bar sits in the green. Slickness widens the green. **Crit:** wallet AND watch. **Fail:** grabbed wrist → shove-off QTE → petty chase.

**SHOPLIFT** — *The Strip*
In-shop: palm items into your jacket while the shopkeeper's attention cone sweeps. Bally helps CCTV, hurts attention. Sell haul to Keisha the fence (D3).

**BIKE THEFT** — *any district*
Bolt-cutter timing hold on locked bikes/peds. Loud crack on fail = instant local heat. Stolen peds enable snatch drive-bys before you can afford your own.

### 7.2 Tier 2 — Graft Proper (Rank 3+, Nerve 4–6)

**CORNER SHOTTING** — *contested zones*
Stand your corner; customer NPCs approach in waves. Serve = quick swipe per customer. Among them: **undercovers** with tells (too clean, wrong walk, asks twice). Serving an undercover = instant bust attempt. **Push-your-luck core:** each wave raises bust odds (+4%/wave, resets on cash-out). Cash out any time and walk. The whole game's risk philosophy in one activity.

**BURGLARY** — *Rimley Market terraces*
Case the house (lit windows = occupied), lockpick minigame (rotating pin sweet-spots; Slickness widens them), inside: top-down loot-grab against a silent-alarm timer, out before the fed ETA hits zero. Occupied-house variant at higher skill: sleeping NPCs with hearing radii. **Crit find:** wall safe (bonus lockpick, jewellery).

**EXTORTION ("collecting")** — *Rimley Market* — *flags territory action*
Lean on stalls/shops for weekly protection. Persuasion check vs Strength/rep; refusal → smash-the-till mini-beat (heat spike) or walk away (rep hit with your own firm). Once your firm holds the postcode, collection automates into territory income — extortion is how you *build toward* ownership.

**CHOP-SHOP RUNS** — *The Docks (Delroy's)*
Delroy posts model-specific orders ("need a grey German saloon, E-plates, no scratches"). Find it street-parked (spawns rule-based), defeat its security minigame (better whips = harder), then **drive it back through live heat** — damage docks the payout. First activity that makes *driving* a skill.

**TICKET TOUTING / JACKING DRUNKS** — *Neon Row, night only*
Crowd-work economy of the night strip: buy/flip event tickets to NPC queues (market-timing mini-game), or relieve stumbling city boys of their wallets (pickpocket variant, zero resistance, double heat if witnessed — bouncer NPCs have big witness cones).

### 7.3 Tier 3 — Organised (Rank 5+, Nerve 8–10, crew helpful)

**ATM RAM-RAID** — *The Docks / The Strip at 04:00*
Requires a van (stolen or owned) + 1 Enforcer minimum. Reverse into the ATM (angle/speed judged), cash cassette load-up against a 90-second armed-response timer, getaway with a police pursuit tail you must break line-of-sight to drop. Loud, cinematic, brilliant clip-fodder.

**WAREHOUSE JOB** — *The Docks*
Stealth-or-loud choice made live: patrol guards with vision cones (stealth: Slickness routes) or bang the door and race the response timer (loud: Strength + crew). Loot pallets vary per instance — forklift key spawn opens the big cage (crit path).

**GROW-OP (ownable)** — *unlocks with a Tier-2 trap house*
Convert a trap-house room: capacity investment → grow cycles on 24 h timers → harvest supplies your own lines below wholesale. The first "vertical integration" the player builds; feds raid it if district heat peaks (insurable via the Brief).

**COUNTERFEIT RUNS** — *Leeds content, previewed in London*
Buy fake goods pallets, retail them via your shotters at big margin — with a "sketchiness" quality roll; too sketchy raises district heat and tanks the price. Leeds trips buy better fakes: a travel loop.

### 7.4 Tier 4 — Heists (Rank 7+, 2–4 players, Nerve 15, scheduled)
The jackpot layer and the strongest co-op bonding in the game. Structure: **Plan (async) → Execute (live, 3–5 min) → Split (ceremony).**
Roles: **Driver** (getaway routes, pursuit-breaking), **Muscle** (guards, doors), **Slick** (locks, alarms, safes), **Lookout** (fed ETA radar, callouts — playable from anywhere, so a firm-mate on a bus IRL can still run overwatch on their phone: genuinely novel).

Launch heists:
1. **The Jewellers (W1)** — smash-and-grab, Hatton Garden energy. 90 seconds of glass, grab-value choices (trays vs the safe gamble), West End getaway.
2. **Cash-in-Transit (route ambush)** — intel first (watch the route across two districts, two days), then the hit: box the van, angle-grinder timer, armed response inbound.
3. **The Container (Liverpool)** — port infiltration, crane puzzle, "what's in the box" = the biggest single loot-roll in the game (from washing machines to Iconic drip crates). Post-launch flagship.

Payout splits are proposed by the leader and **voted** — social friction as content. Betrayal is impossible mechanically (no mid-heist stealing): trust drama should be about the split screen, not about ruining someone's night.

### 7.5 The Reveal Ceremony (spec, used by every crime)
The most important 4 seconds in the game — the micro-dopamine engine:
1. Screen dims; a duffel bag drops with weight; haptic thud.
2. Bag glow = rarity of best item (Basic white → Decent green → Peng blue → Certi purple → Iconic gold). Glow shows *before* contents: 0.8 s of pure anticipation.
3. Contents flip out card-by-card (cash counts up with ticker SFX; items land with a snap).
4. Stingers layered on top: **CRIT** slash, **NEAR MISS** copy ("Feds were 3 seconds out"), skill-XP bar chunk, streak tick.
5. One-tap continue; long-press to skip forever (respect the veterans).
Total: ≤4 s. Skippable, but designed so nobody wants to for the first hundred hours.

---

## 8. Feds, Heat & Consequences

### 8.1 Two Heat Meters
- **Personal heat** (0–10 pips, shown as sirens on the HUD): raised by witnessed crimes, chases, fights in public. Decays −1 pip/10 min, faster in safe zones or "laying low" at home (2×).
- **District heat** (invisible number, visible effects): the sum of everyone's noise in a district over 24 h. High district heat = more patrols, faster response timers *for everyone*, and eventually a **Crackdown event** (§18.7). Creates a shared-pool dynamic: greedy days make the whole postcode hot — genuinely emergent cooperation ("allow it tonight, feds are on one").

### 8.2 Response Escalation
| Personal heat | Response |
|---|---|
| 1–3 | Beat officers walk toward reports; easy to stroll away from |
| 4–6 | Response car units; foot chases with stamina battles; stop-and-search of flagged players (bally, big wads) |
| 7–9 | Multiple units, dogs (track through alleys — you must break scent via water/crowds) |
| 10 | **Armed response** (Docks/heists tier): slow, loud, lethal-feel; escape is about pre-planned routes, not improvising |

### 8.3 Getting Nicked
Chase caught / bust failed → **arrest flow:** three options in 3 seconds — *Run* (Speed check, last gamble), *Struggle* (Strength check, assault charge added on fail), *Hands up* (co-operative: shortest stint).
**Jail = a timer with agency:** 10–45 min base by charge. Inside you can: pay **bail** (scales with charge, clean money only — dirty was confiscated on arrest, the single biggest dirty-cash sink in the game), call **the Brief** (retainer contact: −40% stint, cooldown), do **prison graft** (small minigames: −time, +Toughness XP, tiny black-market finds), or attempt **the door** (rare escape minigame: high fail cost, legendary Feed post on success).
Arrest confiscates all carried dirty cash and contraband. Banked/stashed/clean assets are never touched. **Loss is always capped and always legible** (Pillar 3).

### 8.4 CCTV Britain (identity system)
England is the most-surveilled country in Europe; we make that a mechanic.
- Districts have CCTV density ratings (The Strip: extreme; The Fields: low; Docks: patchy).
- Committing crimes on camera fills an **ID meter**. Full meter = you're "known": passive heat gain everywhere, feds recognise you on sight for 24 h.
- **Bally** cuts camera ID by 60% — with the social trade-offs from §6.4.
- Counter-play: pay a contact ("the Cleaner") to wipe footage (expensive, cooldown), or physically spray cameras in your firm's territory (a maintainable territory buff — and a raid target for opps).

### 8.5 Hospital
Duppy'd in a fight → hospitalised 10–30 min (severity-based). Toughness reduces it; a firm-mate with the Medic perk can halve it remotely (social utility). You lose 25% of *carried dirty cash* to whoever dropped you (NPC or raider). Hospital screen is not dead time: full phone access + "Watch the ward telly" idle minigame granting small Toughness XP.

---

## 9. County Lines — The Strategic Layer

The signature system. Real-world shape (city hub pushes product to small towns through dedicated phone lines and runners), abstracted into clean strategy. **All characters involved are adults; see §21.**

### 9.1 Setting Up a Line
Requirements: Rank 4, a trap house Tier 2+, product stock (bought from the Plug or grown, §7.3), one dedicated **burner** (equipment item), one assigned **Runner** (NPC crew).
Flow in the **Trapline app**: pick a satellite town → name the line → assign runner + load stock → the line goes live.

### 9.2 Line Economics
- Each town has **demand** (units/day), **price multiplier** (1.6×–2.4× city price — the whole point of going OT), **fed pressure** and **local competition** (NPC lines you can push out).
- A line sells automatically at `min(stock, demand)` per tick. Profit lands as dirty cash *in the town* — a runner has to bring it home (round-trip timer, §5.3).
- Lines are leaky by design: per-run **bust risk** (base 4%/run, scaling with fed pressure and greed — oversupplying a small town spikes pressure). Busted run = lose that stock + cash-in-transit, runner "shook" (48 h morale debuff) — never permadeath (§21).

### 9.3 Line Levels
Reliable weeks level a line up: Level 1 "Testing the water" → 5 "It's pattern" (max): demand +60%, bust base −1.5%, unlock second runner slot. Losing a line to a bust wave drops it a level, not to zero — setbacks sting but never wipe (Pillar 3).

### 9.4 Escorted Runs (the convoy spike)
Any run can be **escorted**: you (plus optional crew) physically ride with the shipment.
- Escorted run = +40% yield and immunity to random busts...
- ...but it generates **intel**: rival NPC factions (and during wars, enemy player firms) can learn a window of your route and stage an **interception** — a live ambush encounter on a road scene (fight or drive through).
- Result: the game's biggest risk-reward lever, fully opt-in, producing the "barely got the bag home" stories that fuel the Feed and gang chat. During wars, successful interceptions score Stripes (§14.6).

### 9.5 The Map View
The Trapline app renders your network like a transit map — hub node, lines snaking out to towns, colour-coded health (green flowing / amber dry / red hot). Watching your network grow from one shaky line to a web across the Midlands is a macro-progression image worth a thousand progress bars. End-of-week summary: "Your network moved 340 units this week. Top line: Margate."

---

## 10. Combat — Simple, Readable, Fast

Locked decision: **stats and gear decide.** Combat is a 5–10 second resolution with two or three meaningful taps, not an execution test.

### 10.1 The Numbers
- `HP = 100 + Toughness × 5`
- `ATK = Strength × 2 + weapon damage`
- `DEF = Toughness × 2 + gear defence`
- Up to 4 auto-exchanged rounds, ~1.5 s each. Per round: `damage = ATK × (1 − DEF_opp / (DEF_opp + 150)) × rand(0.85–1.15)`
- Crit chance `5% + Speed × 0.2%`, crit ×1.7, big flash + haptic.

### 10.2 The Three Buttons
During each round window the player may tap one:
- **ITEM** — use the equipped consumable (pepper spray: skip enemy round; energy drink: +15 HP; bottle: one-shot +12 dmg then breaks).
- **SHOVE** — sacrifice your round to create distance: next flee attempt +40%.
- **RUSH** — ×1.5 damage dealt *and taken* this round. The all-in button.
No buttons pressed = clean auto-resolve. Depth is optional; outcomes stay stat-honest.

### 10.3 Fleeing (the equaliser)
`Flee % = 30 + (your Speed − their Speed) × 2 + (40 if shoved)`, capped 85%, floor 10%.
Success: you're gone, dropping 5% of carried dirty ("dropped notes" — a lovely little loot scatter for bystander NPCs). **Every player always has an out.** With stat-decided combat this rule is what keeps the world from ever feeling like a grief simulator, even against NPC hit squads.

### 10.4 Weapons (UK-honest)
Melee-first world; firearms are rare, loud, endgame:
| Tier | Weapons | Notes |
|---|---|---|
| Fists | — | Always available |
| Blunt | bat, pole, bottle | Cheap, legal-ish to carry (low search risk) |
| Blade | shank → Rambo | Best dmg/price; carrying = stop-and-search risk, big charge if nicked |
| Strap (endgame) | pistol, sawn-off | Nottingham plug only; using one = instant heat 10, district-wide event, days-long personal heat. A statement, not a sidearm. |
Weapon condition degrades; Delroy maintains them. Gear defence comes from drip (stab vests exist, look terrible with everything — a real fashion/safety dilemma players will argue about).

### 10.5 Fight Types
Street beef (vs NPC patrols/robbers), Hit-squad ambushes (2–3 NPCs, flee-friendly), Raid fights (§14.4 — squad vs defence, same math per pairing), War skirmishes (control-point captures), Sparring (safe-zone gym, friendly, small XP, zero stakes — social toy).

---

## 11. The NPC Ecosystem — A World That Pushes Back

Locked decision: no open-world PvP; **NPCs are the street threat.** They make the world feel occupied and dangerous from day one with ten players online, and they're the training wheels for the war system.

### 11.1 London's NPC Factions at Launch
Every faction has identity, turf, a signature behaviour and a colour/tag language so you read the streets at a glance. All names and colours fictional (§21).

| Faction | Turf | Identity | Signature behaviour |
|---|---|---|---|
| **E8 Mandem** | The Fields' edges | Local youngers, all mouth | Low-tier; your first beef; quick to squash it for cheap |
| **Green Lane Boys (GLB)** | Rimley Market | Extortion specialists | Tax stalls hard; collapse fast when their collectors get hit — designed to be the first postcode players take |
| **Cold Mile Crew (CMC)** | Neon Row | Night robbers, flashy | Only dangerous 20:00–04:00; jack drunk *players'* NPC marks (kill-steal your jobs — infuriating in the best way) |
| **Docklands Firm** | The Docks | Old-school organised | Proactive patrols, armed at core sites, run their own convoys **you can intercept** (§9.4 in reverse — PvE convoy robbery!) |
| **Nine Fingers** | Nomadic | Raiders, no turf | The wildcard: periodically raid *everyone's* territory including other NPCs — keeps the map churning and gives every firm a common enemy |

Each expansion city ships 3–5 factions of its own with local flavour (Birmingham's car-crew, Liverpool's dock firm, etc.).

### 11.2 The Beef Meter
Per-faction relationship, −100 (war) to +100 (paid peace), starting 0.
- Crimes on their turf: −2 to −10 each. Hitting their people: −15. Taking their postcode: −60.
- **Thresholds:** −20 *verbals* (they mouth off, block paths); −40 *on-sight* (patrols attack in their turf); −70 *hit squads* (2–3 man teams ambush you in ANY contested district, ~1/session while it lasts); −90 *taxing* (they skim 10% off your businesses in their reach until resolved).
- **Resolving beef:** pay them off (cost scales with negativity — a real dirty-cash sink), lay low (decays +1/h toward 0 when you avoid their turf), or **send a message** (defeat a patrol: −30 more beef but they respect it — unlocks the *Truce* option at half price. Violence as negotiation, very on-theme).

### 11.3 Patrol & Ambush Design
- Patrols: 2–3 sprites, faction colours, patrol loops with vision cones shown on tap (fairness: you can always see what sees you).
- Ambushes: telegraphed 3 s ("mans are moving on you" + directional haptic) → fight or flee. Never within 60 s of spawning into a district, never in safe zones, never during a reveal ceremony. **Danger, minus cheap shots.**

### 11.4 Street Robbers (the mirror)
Independent NPCs who do to you what you do to the world. Carrying >£500 dirty in contested zones marks you subtly (your character pats their pocket — a readable tell you learn to feel nervous about). Robbers shadow you exactly like *your* pickpocket shadow-cone works — teaching by mirroring. Getting jacked for a wad you were too greedy to bank is the game's favourite lesson and generates zero unfair-feeling losses: you chose to carry.

### 11.5 Street Events (ambient content)
Rolled per district visit (~20%): a plug offering discount stock ("bulk ting, one time"), a fed stop-and-search, a fleeing NPC dropping loot with the owner in pursuit (take it = instant beef), a rival's abandoned stash tip-off, a busker who's clearly a lookout... 30+ at launch, each ≤20 s, each a tiny story.

---

## 12. Your Firm — NPC Crew (the "troops" layer)

The heart of the CoC fusion: even a solo player commands an organisation. Player gangs multiply it; they don't gate it.

### 12.1 Crew Classes
| Class | Role | Wage/day | Cap by HQ tier |
|---|---|---|---|
| **Younger** | Runs lines (county-lines runner) | £50 | 2 → 8 |
| **Shotter** | Holds a corner in owned/contested turf → passive income tick | £80 | 1 → 6 |
| **Enforcer** | Fights: raids, escorts, defence muscle | £120 | 1 → 5 |
| **Lookout** | Defence: alarm speed, camera coverage, patrol detection | £60 | 1 → 6 |
| **Driver** | Getaways, convoys; −travel times; chop-run assists | £150 | 0 → 3 |

### 12.2 Recruit → Train → Equip
- **Recruit** at the pitch-side in The Fields (rotating candidates with rolled traits — *Slippery* +flee, *Loyal* −wage, *Hothead* +dmg/−discipline...). Rare candidates appear after big wins: success attracts talent.
- **Train** on timers (1 h L1 → 12 h L5) in HQ facilities; parallel slots grow with HQ (the "builders" analogue).
- **Equip** hand-me-downs: your old shanks, ballys and vests gear your crew — a beautiful second life for outgrown loot and a reason the loot economy never dead-ends.
- **Morale**: wages auto-paid from clean money; missed payroll = strikes; a lost fight = "shook" debuff 48 h; wins, wage bumps and shared duffel bonuses restore it. Light management, real texture.
- Crew are **never permanently lost** (§21) — worst case is hospitalised (timer) + shook.

### 12.3 Assignment Board
One clean screen (in the Firm app): drag crew tokens between duty slots — Lines / Corners / Defence / Raid squad / Resting. Every slot shows its yield or coverage live. This board is the management-player's home screen and the 60-second "SET UP" beat of every session.

---

## 13. The Trap House — Base Building

### 13.1 Housing Ladder
| Tier | Name | Unlocks |
|---|---|---|
| 0 | Your mum's sofa | Nothing. Motivation. |
| 1 | **The Bando** (squatted) | Stash (small), 1 crew slot, gym mat |
| 2 | **Trap flat** | Lines unlock, grow-op room option, 3 crew, wall safe |
| 3 | **Trap house** (whole terrace) | Defence layout editor, 6 crew, garage (1 whip) |
| 4 | **The Block** (unit in your firm's held postcode) | 10 crew, war room, 2nd stash, roof lookout |
| 5 | **The Penthouse** (clean-money purchase, city centre) | Prestige skin + max caps; deliberately *legit* — the endgame flex is looking legal |

### 13.2 Defence Layout Editor (the "base editor")
Top-down editor of your trap's block: place defence elements on a grid with budget + tier caps. Elements:
- **Reinforced door** (breach HP; multiple = route choices for attackers)
- **Lookout post** (assigned Lookout: alarm raises fed-ETA pressure on raiders; detection cone)
- **Dog run** (patrolling pitbull cone — cheap, scary, bypassable with *Meat* consumable: counter-play everywhere)
- **Stair trap** (one-time stun on the route)
- **Camera** (reveals raiders' positions to defence AI / live defender)
- **Cage** (stash-room inner barrier — the last 10 seconds of every raid)
- **Decoy stash** (eats a raider's Grab action for junk loot — the mind-games slot)
Defence Rating (visible to scouts, §14.5) summarises the layout. Layout matters more than spend: a cheap clever maze out-defends an expensive corridor. Editor ships with 3 preset layouts per tier so management-averse players are never punished.

### 13.3 The Stash
Raiders can steal **only** from your stash's *raidable share*: 20% of stash dirty cash + unbanked territory income, never clean money, never gear, never crew. Capped, legible, survivable (Pillar 3) — losing a defence should make you want revenge, not want to uninstall.

---

## 14. Territory, Raids & War — The CoC Engine

One system, two opponents: NPC firms first, player firms later. Identical rules throughout, so PvE *is* the PvP tutorial.

### 14.1 The Postcode
Contested districts contain 1–3 postcode territories, each with 3 physical **control points** (market gate, arch lockups, the pub...). Holding a postcode yields: income tick (£400–£1,200/day by district), district buffs (−heat decay time, +shotter yield, spray-your-cameras rights §8.4), and your firm's **tag rendered on the walls** — art as ownership; walking through turf you hold *feels* held.

### 14.2 Claiming from NPCs (solo-friendly on-ramp)
Weaken (hit their collectors/patrols to drop the postcode's Grip meter) → **Raid** their HQ (§14.4) → Plant the tag (live spray minigame at each control point, interruptible by their counter-attack wave — a tense little "hold the point" finale) → Hold it (they attempt one scripted retake in the next 48 h; survive it and it's yours). A determined solo player with 3–4 crew can take their first postcode in week two — the single biggest macro-milestone of early game.

### 14.3 The War Loop (player firm vs player firm)
1. **Declare** (Firm app → target's held postcode; costs a war chest stake, both sides notified). Matchmaking guardrails: ±30% power rating window, defenders can't be declared on twice concurrently, new firms immune 14 days.
2. **Prep — 24 h**: scouting (§14.5), defence re-layout, crew healing, trash talk in a shared war channel (auto-created, moderated, glorious).
3. **War — 48 h**: each side gets **5 raid tickets per day** vs the other's trap houses/control points. All raids are attacker-live vs defence-AI, with live-defence join if a defender's online (§14.4).
4. **Scoring — Stripes**: 0–3 per raid (breach ≥1 barrier / reach stash / clean extract), defensive Stripe for a full repel, +2 for a war-convoy interception (§9.4).
5. **Resolution**: most Stripes takes (or keeps) the postcode + 60% of the war chest; loser gets a 3-day shield and keeps all non-staked assets. Draw = defender holds.

### 14.4 Raid Anatomy (attacker's 120 seconds)
Loadout (up to 3 crew + consumables) → insert at a chosen edge → breach (doors = timed holds; Muscle class speeds them) → navigate (dogs, traps, cameras; Slickness reads them) → the stash cage (final timed crack while defence converges — the drama beat) → **extract** (loot only banks when you cross the exit line; greed on the way out is how raids are lost). Fed-ETA bar accelerates with every alarm — even flawless defence can win by making you *slow*.
**Live defence:** if the defender (or firm-mates) are online at raid-start, a 20-second **DEFEND** prompt lets them spawn in and fight alongside their AI. Async by default, electric when it's live — and the raid alert push is the strongest notification in the game.

### 14.5 Scouting
Send a Younger to case a target (30 min timer): returns Defence Rating, element count by type, and one random exact placement. Counter-intel: Lookouts have a chance to catch scouts — a caught scout tips *you* off that war's coming. Information warfare with two taps.

### 14.6 Seasons
8-week seasons. At season end: war leaderboard rewards (Iconic drip, tag styles, trophies rendered in your trap), then a **soft map reset** — NPC factions "take back" ~50% of player-held postcodes overnight (in-fiction: a nationwide crackdown). Keeps the map claimable for new players forever, gives established firms a fresh campaign, and makes season-end week the biggest land-rush party in the game.

---

## 15. Economy

### 15.1 Two Currencies, One Tension
- **Dirty cash (Ps)** — earned by all crime. Spends on: street gear, crew wages advances, plugs/product, bribes, beef payoffs. **At risk** when carried (robbers, arrest, fights) and partially raidable in your stash. Cannot buy property, penthouse-tier goods, or sit in the bank.
- **Clean money (the Books)** — safe forever, buys the legit ladder (property, whips from a dealership, top-tier drip, bail). Made by **washing** dirty through fronts, plus small legit trickles.
The entire economic gameplay is the pump between the two: earn dirty fast and dangerous → convert with fees and time → build unassailable clean wealth. Greed (holding dirty for one more job) vs safety (banking now) is a decision the player makes twenty times a day, and it's never trivial.

### 15.2 Laundering Fronts
Buyable venues in walkable districts (visible on the street — your name over the door, another ownership flex):
| Front | Cost (clean) | Wash rate | Fee | Side perk |
|---|---|---|---|---|
| Chicken shop ("ChickenLix" franchise) | £8k | £600/2 h | 30% | Crew morale snack buff |
| Car wash | £15k | £1,400/3 h | 26% | Cheap whip repairs |
| Barbershop | £22k | £2,200/4 h | 22% | Rep aura: fresh trim buff (real) |
| Bookies ("Betfrenz") | £40k | £4,000/6 h | 18% | In-game betting venue (§17.5) |
| Nightclub (Neon Row endgame) | £120k | £12k/8 h | 12% | Firm social HQ; heist intel rumours |
Fronts are upgradeable (capacity/fee), generate small clean trickle on their own, and can be **taxed by NPC beef** (§11.2) — everything connects.

### 15.3 Faucets & Sinks (inflation control)
Faucets: crime payouts, territory ticks, line profits, heist jackpots, marketplace sales.
Sinks: laundering fees (the big one), wages, bail/Brief, beef payoffs, travel, gear condition, defence builds/repairs, war chests, betting, fast-travel fees, plug stock.
Target: sinks absorb 55–65% of faucet volume at steady state. The marketplace (§15.5) is player-to-player so it moves money without printing it.

### 15.4 Legit Trickles
**OddJobz app**: 3 real-ish gigs/day (parcel run = deliver package across districts; queue for a mate; flyer drop) paying small clean money. Purpose: laundering-free early cash, an "I'm going straight" roleplay lever, and cover stories ("I do deliveries, bruv"). Deliberately worse per minute than crime — going straight should be possible and boring.

### 15.5 Shifted (marketplace)
Player-to-player app-style market: stolen phones/watches (from crimes), drip, weapons, consumables, product stock. Listings look like a resale app (photos, seller ratings, "collection only, no timewasters"). 8% listing tax (sink). Iconic drip resales are the endgame economy spectacle.

### 15.6 The First-Fortnight Curve (sample tuning)
| Day | Typical net worth | Milestone |
|---|---|---|
| 1 | £1.5k dirty | First reveal, first level, first ped ride |
| 2–3 | £4k / first £1k clean | First front (saving for ChickenLix); Rank 3 |
| 4–6 | £12k | First crew (Younger + Shotter), Trap flat |
| 7–9 | £25k | First line live; first hit-squad survived |
| 10–14 | £50k+ | **First postcode taken from GLB** — the early-game boss moment |

---

## 16. Progression & Ranks

### 16.1 Rep & the Ladder
**Rep** is the master progression currency, earned by everything (crimes, wars, lines, defences). Ranks gate systems so complexity unfolds in layers:

| # | Rank | Rep | Unlocks |
|---|---|---|---|
| 1 | Wasteman | 0 | Tier-1 crimes, gym |
| 2 | Yout | 300 | Bike theft, Shifted, Daily Graft |
| 3 | Roadman | 1,000 | Tier-2 crimes, first crew slot, contested zones |
| 4 | Grafter | 2,500 | Lines, fronts, extortion |
| 5 | Older | 6,000 | Tier-3 crimes, raid NPCs, defence editor |
| 6 | Certi | 14,000 | Found/join a firm's war roster, escort runs |
| 7 | Elder | 30,000 | Heists, war declarations (as leader) |
| 8 | General | 60,000 | 2nd city access bonuses, Iconic crafting |
| 9 | Roadfather | 120,000 | Prestige cosmetics, mentor system (boost a newbie, both gain) |
| 10 | **Top Boy** | 250,000 | Seasonal crown: literally rendered on your sprite. One per city per season on the leaderboard throne |

Rank-ups are full-screen **ceremonies**: your sprite under a streetlight, rain, new title stamped like a court document, Feed auto-post, +caps. Make them feel like knighthoods of the road.

### 16.2 Horizontal Progression
Crime-skill mastery titles, drip collections (wardrobe completion %, set bonuses), tag-style unlocks, trap trophies (war wins rendered as objects in your house), Feed clout score. Always a chase for every player type.

---

## 17. Social Systems

### 17.1 Firms (player gangs)
Create at Rank 6 (fee: £25k clean — firms are earned). 30 members max. Roles: Top Boy (leader), Elders (officers: declare war, accept members, set tag), Soldiers, Youts (new). Firm bank (donations, territory cut), firm perks tree (bought with collective contribution: +defence, +line yields, war ticket +1), firm tag (composited from the founder's tag editor).
Solo players lose nothing structural — firms multiply war capacity and social pull, not core access (Pillar: the game respects the lone operator; some of the best Torn players were famously solo).

### 17.2 Cypher (chat)
Encrypted-styled chat app: firm channel, war channel (auto vs opponents, filtered), DMs, city channel (rate-limited, moderated §21.4). Voice deliberately excluded at launch (moderation cost, vibe risk); expressive sticker packs of in-game moments instead ("man's shook", the duffel, the pitbull).

### 17.3 Flexta (the Feed)
Auto-generated posts (opt-out per event type) for: rank-ups, Iconic finds, war wins, first postcode, heist splits, legendary escapes ("outran armed response with 2% stamina"). Others can rate (💯 / 🔥 / 🐀) — reactions grant tiny rep. The Feed is aspiration fuel: seeing someone's penthouse post at Rank 3 is the strongest "one day" hook we can build, and it's user-generated for free.

### 17.4 Leaderboards
Weekly + seasonal; city-scoped and national: Rep gained, war Stripes, richest Books, biggest single reveal, line volume, defence streak. Weekly scoping means new players see reachable boards from day one.

### 17.5 The Bookies
In-fiction betting at Betfrenz venues on in-game events only (war outcomes between other firms, weekly leaderboard races). In-game currency only, capped stakes, 18+ product with RTP honesty (§21.3). Social spectacle: firms betting on rivals' wars turns every war into content for non-participants.

### 17.6 Mentorship
Rank 9s can sponsor fresh players: mentor gets rep from the mentee's milestones; mentee gets a "vouched" tag, small buffs, and a human welcome. Converts veterans into the tutorial's final layer and gives late-game players a prestige activity that grows the game.

---

## 18. Dopamine & Retention Architecture

The explicit design of the reward psychology. Rule zero, honestly held: **every spike must correspond to real progress or real story.** Spikes that lie (fake scarcity, manipulated near-losses) burn trust and retention in weeks; spikes that celebrate true events compound for years.

### 18.1 The Spike Inventory
| Trigger | Frequency | Mechanism |
|---|---|---|
| Reveal ceremony | Every crime (dozens/day) | Variable-ratio loot + anticipation gap (§7.5) |
| Crit outcomes | ~8% of jobs | Random ×2–4 payouts, full flash |
| Near-miss copy | ~15% of jobs | "Feds were 3 seconds out" — arousal without loss |
| Skill/rank progress chunks | Several/session | Bars visibly chunk with every act |
| Collect stacks | Session-open | Guaranteed warm open (§5.1) |
| Timer completions | 3–8/day | Push → open → claim |
| Street events | ~20% of district visits | Novelty droplets |
| Hit-squad survivals / escapes | Weekly | Earned war stories |
| RAID DEFENCE live join | Rare, unscheduled | The apex spike — adrenaline + social stakes |
| War resolution | Weekly at midgame | Group-scale win/loss ceremony |
| First-postcode / heist splits | Milestones | Jackpot ceremonies with Feed echo |
| Season end land-rush | 8-weekly | Server-wide festival |

### 18.2 Variable Reward Tuning
Loot tables are **transparent-odds** (long-press any activity: see the table — trust builds engagement, and regulators increasingly require it anyway). Distribution shape per crime: ~70% baseline band, 20% good, 8% crit, 2% jackpot item. Pity floors: no crit in 25 rolls → next roll's crit odds triple (quietly — the player just feels "due" correctly for once).

### 18.3 Near-Miss Discipline
Near-miss copy fires only when the sim actually produced a close call (fed distance, alarm margin, flee roll within 10%). **Never fabricated.** Fabricated near-misses are the slot-machine trick we explicitly refuse; real ones are just good storytelling of the simulation.

### 18.4 Daily Graft & Streaks
Three rotating dailies (one per loop scale: a crime task, a management task, a social/territory task) + a weekly "Big Graft" chain. Streak rewards escalate to day 7 then plateau (no infinite-streak anxiety), one free freeze/week (§5.4). Completion feeds a visible weekly duffel that opens Sunday night — the week's own reveal ceremony.

### 18.5 First Session (FTUE) — Minute by Minute
The most engineered 12 minutes in the project:
- **0:00–0:30** Cold open, zero menus: you're already walking The Strip behind a mark, one floating prompt. **Snatch.** Chase beat (feds!), duck into an alley —
- **0:30–1:30** — straight into the first **reveal ceremony**. Phone (the UI) is "unlocked" in-fiction: Uncle T rings it: "Yo. Saw that. Come Fields, let me look at you." One-tap travel.
- **1:30–4:00** The Fields: meet Uncle T (mentor), get the bando key (Tier-1 house = home anchor), first wardrobe item (drip taste), gym shown (queue 1 session = first timer).
- **4:00–8:00** Three-job graft chain on The Strip with escalating reveals; one scripted **real** near-miss; level Pickpocket to 2 (first bar completion); bank £200 at Bung ("never carry what you can't lose" — teaching the core economy in one line).
- **8:00–11:00** Back home: Bossman street-event intro, Daily Graft revealed (2/3 already done by playing — instant claim), **notification permission asked in-fiction**: Uncle T: "You want man to ring you when the block needs you, yeah?" (measured: diegetic asks convert 15–25 points better than system-prompt cold asks).
- **11:00–12:00** The horizon beat: map pans to Rimley Market, GLB tags on the walls, Uncle T: "That market used to be ours, y'know." Session ends with gym timer running, energy part-spent, Daily 1 short, and a named enemy. **Day-2 hook: revenge, not routine.**

### 18.6 Notification Matrix (hard-capped: max 4/day, quiet 23:00–08:00 local, all opt-outable by category)
| Event | Priority | Copy example |
|---|---|---|
| **Raid on your trap (live)** | Bypass cap | "🚨 MANDEM ARE RUNNING UP ON YOUR TRAP. DEFEND IT." |
| War window opens | High | "It's on. GLB war starts in 30." |
| War resolved | High | "War's done. Get in here." |
| Runner back / line dry | Med | "Runner's touched down with the Ps." |
| Income capped | Med | "Your corner's stacked. Don't leave it out." |
| Energy/Nerve full | Low | "Roads are quiet. Too quiet." |
| Streak at risk (20:00, day incomplete) | Low | "Daily Graft's not gonna graft itself." |
Copy is written in-voice, rotated from pools of 10+ per event so it never goes stale — the notification tray should read like your mandem texting you, because that's exactly what it is.

### 18.7 Live Ops Rhythm
- **Weekly:** Wednesday "Drop Day" (Shifted exclusive stock), weekend event rotation (Blackout Storms ×2 odds nights, Double-line Sundays, Crackdown events that force the whole city to lay low or defy it together).
- **Seasonal (8 wks):** themed season (e.g. "Winter Pressure" — cold snap visuals, heating-bill flavour sinks, Christmas jewellery jobs), one new system-lite or district, season pass of *cosmetic-only* tracks (monetisation phase pending, §22.4).

---

## 19. UI/UX & Screens

### 19.1 Orientation: Landscape (locked)
**Landscape, two thumbs.** (v1.0 recommended portrait; overruled — landscape is locked.) What landscape buys us:
1. Wide field of view — the street, the mark, the patrol and the escape route sit in one frame; top-down crime reads best in widescreen (GTA2 framing).
2. Honest two-thumb ergonomics: joystick left, action cluster right, with real spacing — no cramped one-thumb compromises in fights and chases.
3. Cinematic ceremonies — reveals, rank-ups and war cards get film framing, and the reveal is the most-seen screen in the game.
Consequences carried through the doc: district layouts are horizontal-biased (streets run across the screen), the in-game phone renders as a centred portrait card over the dimmed world (§19.4) — you're holding *their* phone inside yours — and management flows must stay comfortable in short two-handed bursts. Tablets come free.

### 19.2 Controls
- **Left thumb:** dynamic virtual joystick (appears where the thumb lands). Edge-push = sprint (drains Stamina).
- **Right thumb:** one **context action button** that reads the world (SNATCH / TALK / ENTER / LIFT / TAG / ATTACK), plus a small equipped-item slot above it, plus the phone icon (top right, badge-dotted).
- Long-press context button = alternate action where relevant (e.g. case a house vs enter).
- All minigames are one-thumb: taps, holds, timing bars. **Nothing ever needs two simultaneous touches.**

### 19.3 HUD (world view, landscape)
- **Top strip:** cash chip (dirty wad icon + clean card icon, tap = Bung), heat pips (sirens), rep/rank sliver.
- **Top-right:** phone icon w/ notification badge; mini-map disc below it (tap = district map).
- **Bottom-left/right:** joystick zone / action cluster.
- **Ambient bars:** Energy & Nerve as two slim arcs around the action button — visible exactly when you're about to spend them, invisible clutter otherwise.
- Reveal ceremonies, fights and dialogues take over the lower third; the world stays visible above (you're always *in* the place).

### 19.4 The Phone (the entire meta-UI)
Tap the phone icon: the character raises their phone — a centred, portrait-shaped diegetic OS card over the dimmed world ("PebbleOS", scuffed screen protector optional cosmetic). Apps:
| App | Function |
|---|---|
| **Bung** | Bank: dirty↔clean balances, laundering queue, transfers |
| **Roadmap** | District/city/country maps, travel booking, territory overlay, opp-turf shading |
| **Trapline** | County-lines network (the transit-map view) |
| **Cypher** | Chats |
| **Flexta** | The Feed |
| **Shifted** | Marketplace |
| **Firm** | Gang: roster, bank, perks, war room, assignment board |
| **Contacts** | Uncle T, the Brief, Delroy, Keisha, the Cleaner, plugs — each a service menu with voice-note-styled flavour lines |
| **OddJobz** | Legit gigs |
| **Betfrenz** | Bookies |
| **Camera** | Screenshot mode with gritty filters + your tag watermark (free marketing machine) |
| **Settings** | Options, notification categories, accessibility |
Phone opens in <150 ms from anywhere except mid-fight/mid-minigame. The badge economy across app icons is the session's table of contents.

### 19.5 Screen Inventory (MVP-relevant set)
Boot/login → Character creation (3 steps) → World HUD → Phone home + 12 apps above → Reveal overlay → Fight overlay → Minigame overlays (lockpick, snatch-timing, spray-tag, serve-wave) → Gym/Stats → Wardrobe (drip paper-doll on your actual sprite) → Crew board → Defence editor → Raid loadout → Raid results → War room → Jail → Hospital → Leaderboards → Season screen → Onboarding beats. (~28 screens; wireframe pass is the next design deliverable after this doc.)

### 19.6 Game Feel ("juice") Standards
- Cash never appears — it **counts up** (tickers everywhere, tabular numerals).
- Every tap: ≤80 ms visual + haptic acknowledgement. Fights: hit-stop 40 ms, micro-shake on crits.
- Rain-on-lens droplets on speed; sodium-lamp bloom pulses subtly with the soundtrack.
- Bars **chunk**, never crawl, and overshoot-bounce on completion.
- One rule above all: nothing in the UI is ever ashamed to be a game — but everything wears the fiction's skin.

---

## 20. Art Direction

### 20.1 Mood
Top Boy exteriors, Blue Story tension, THIS IS ENGLAND texture. Overcast daylight; sodium-and-neon nights; wet everything. Beauty in the brutalist: long shadows off walkway railings, glowing chicken-shop signage in drizzle. The world is grey; **the players are the colour** — drip, tags and faction hues pop against desaturated streets by design.

### 20.2 Palette (hex, master swatches)
| Use | Hex |
|---|---|
| Night tarmac / UI base | `#121417` |
| Panel dark / cards | `#1E2126` / `#2A2E33` |
| Concrete light | `#9AA0A6` · highlights `#C4C9CD` |
| Brick | `#6E3B2E` · warm `#874936` |
| Overcast sky | `#8C97A0` |
| **Sodium orange (signature)** | `#FFA94D` · glow `#FFC97A` |
| Hi-vis accent (UI CTAs, alerts) | `#D9E021` |
| Police blue / strobe red | `#2E5EAA` / `#D63B3B` |
| Money green (counts only) | `#57C785` |
| Rarity: Basic→Iconic | `#B9C0C7` → `#6FCF6F` → `#4DA3FF` → `#B06CF0` → `#F2C14E` |

### 20.3 Rendering & Perspective
- HD 2D (painted-texture, *not* pixel art), ~3/4 top-down like classic GTA2 but modern fidelity.
- Dynamic 2D lighting w/ normal maps: streetlamp pools, headlight cones, window glow, police strobes washing the walls (strobe wash = the universal "it's gone wrong" signal).
- Rain system: droplets, puddle plane reflections, character wet-darkening. Rain is our fog-of-atmosphere and it's on a third of the time.
- CCTV grammar: when a camera clocks you, a brief corner vignette of desaturated CCTV footage of *you* — chilling, informative, iconic.

### 20.4 Environment Kits (modular, per-district budgets)
UK street furniture pack (bollards, red postbox, bus stop, phone box relic, wheelie bins, CCTV poles, A-boards), terrace row kit, estate block kit (walkways, stair towers, cage pitch), shopfront kit with **swappable parody signage** (ChickenLix, PoundZone, Betfrenz, NatBest cashpoint, Morrizons Local), market kit, industrial kit (containers, roller shutters, forklifts), night-strip kit (neon, queue barriers, bouncer podium). Districts are 70% shared kit + 30% bespoke landmarks — that ratio is what makes five districts feasible for a small team, and expansion cities mostly re-dress kits (Birmingham brick tones, Liverpool dock cranes).

### 20.5 Characters & the Drip Pipeline
- One base rig, ~128 px tall at 1×, 8-direction, layered paper-doll (body / bottoms / top / jacket / head / accessory) so **every clothing item is worn art, not portrait art** — the drip economy and the art budget are the same system.
- Silhouette rules: player silhouettes read at 100% zoom in 0.3 s (puffer volume, hood shapes, ped helmets); faction NPCs read by two-colour trim + tag glyph.
- Animation set v1 (~40 clips): locomotion ×8 dir (idle/walk/run), snatch, lift, spray, lockpick loop, serve, fight (windup/hit/hurt/down), duppy'd, phone-out, celebrate, carry-duffel, drive states.

### 20.6 VFX List v1
Reveal suite (bag drop, rarity glow, card flips, cash burst), crit slash, near-miss streak, level chunk-and-bounce, rank ceremony rain scene, tag spray drips, strobe wash, dog alert, alarm pulse rings, blood-lite hit puffs (stylised, no gore — §21), rain/puddle set, muzzle+shock frame for straps (rare = impactful).

### 20.7 Typography & Iconography
Display: heavy condensed grotesque (Archivo Black / Anton class) — tabloid-headline energy for ceremonies and war cards. Body/UI: Inter. Numbers: tabular for all tickers. Icons: 2 px stroke, slightly rough-edged, as if drawn with a marker; app icons follow real-OS conventions closely enough to feel like a phone, parody enough to be ours.

### 20.8 Audio
- **Music:** original UK drill/grime instrumental bed, 138–142 BPM, sliding 808s; intensity-layered stems (ambient street → job tension → chase → raid). Silence is used: The Fields at night is just rain and distant sirens until something happens.
- **SFX pillars:** cash ticker, duffel zip, spray rattle, shutter slams, dog bark (fear in one sample), siren doppler, moped whine, the notification text-tone (must be *the* sound players set as their real ringtone — that's the bar).
- **VO:** no full voice acting; short bark library ("Oi!", "FEDS!", "Allow it", "Say nothing") + Cypher voice-note *style* (text rendered as audio-wave bubbles, no actual audio) keeps it human and localisable.

---

## 21. Content, Rating & Compliance (practical, non-negotiable)

This is a crime fiction in the GTA/Top Boy tradition. These rules keep it publishable, defensible and honest:

1. **Everyone is an adult.** Every character — player, crew, NPC, "youngers" included — is explicitly 18+. The real county-lines horror is child exploitation; this game does not depict minors, full stop. (In-fiction, "younger" = junior in the hierarchy, and character art must read adult.)
2. **Fictional gangs, real cities.** Real city and postcode geography; invented factions, estates, venue names and brands (parody signage kit). Never use the name, colours or iconography of any real gang, living person or real crime victim's case.
3. **Product stays abstract.** Drugs are "product/food" — a crate icon. No named substances, no consumption depiction, no preparation detail, ever. Sale is a game verb, like GTA — not a manual. This is also what app-store review requires (Apple/Google both reject "drug use depiction," accept abstracted crime fiction; PEGI 18 anticipated for crime/violence themes).
4. **Violence is stylised.** Hit puffs, no gore, no torture mechanics, KO not kill ("duppy'd" = knocked out; hospital, not funerals). Knife crime exists in the fiction because it's true of the setting — the game never celebrates it: strap/blade use always carries the game's heaviest costs (§10.4).
5. **Betting is play-money only,** transparent odds, capped stakes, 18+ product overall (§17.5, §18.2).
6. **UGC moderation:** name/tag filters + report pipeline from day one; city chat rate-limited; war channels auto-archived.
7. **Engagement ethics as policy** (restating §5.4/§18): no fabricated near-misses, no fake scarcity, hard notification caps, streak freezes, published loot odds. We are building a game people love for years, not a slot machine wearing a bally.

---

## 22. MVP Roadmap

### 22.1 Philosophy
Ship the **dopamine core** first and prove it retains, then bolt on the strategy meta in the order that deepens returns. Every milestone is playable and testable end-to-end. (Timeframes are rough solo-dev-with-AI ranges, not promises — scope is the commitment, dates aren't.)

### 22.2 Milestones
| M | Name | Scope (IN) | Explicitly OUT | Exit test |
|---|---|---|---|---|
| **M0** | The Snatch (1–2 wks) | Landscape world scene (The Strip slice), joystick + context button, phone snatch + chase, reveal ceremony v1, cash/Nerve | Everything else | 10 testers each replay the loop 10+ times *unprompted* |
| **M1** | Vertical Slice (4–6 wks) | The Fields + The Strip full; 4 crimes (snatch, pickpocket, shoplift, burglary); Energy/Nerve/timers; stats+gym; heat v1 + arrest/jail; Bung bank + dirty/clean + 1 front; FTUE (§18.5); Daily Graft; drip v1 (8 items); reveal v2 | Multiplayer visibility, crew, territory | D1 retention ≥35% on a 50-person closed test |
| **M2** | The World Pushes Back (4 wks) | Rimley Market; E8 Mandem + GLB factions, beef meter, patrols/hit squads, street robbers, street events; combat full (§10); crew v1 (Younger/Shotter/Enforcer); trap Tiers 1–2; corner shotting + extortion | Wars, lines | D7 ≥15%; "best moment?" answers name an NPC story |
| **M3** | Take the Postcode (4–5 wks) | Defence editor + presets; raids vs NPC (full §14.4 anatomy); postcode claim flow; territory income; Trapline v1 (2 towns, runners); scouting; Flexta v1 | Player-firm wars | ≥60% of D14 actives hold a postcode or a live line |
| **M4** | Firms & War (5–6 wks) | Firms, Cypher, war loop vs players (declare/prep/48h/Stripes/shields), live-defence join + raid push, leaderboards, The Docks district, ATM raid + warehouse job | Heists, city 2 | One organic firm rivalry produces a 48h war with both sides showing up |
| **M5** | Season 1 Launch (4 wks) | Neon Row; seasons + soft reset; weekend events; Betfrenz; The Jewellers heist; Shifted economy pass; notification matrix final; store/compliance pass | Cities 2+, Container heist, mentorship | Soft-launch KPIs (§22.3) green for 3 consecutive weeks |

Post-launch cadence: one expansion city or one major system per season, alternating.

### 22.3 KPI Targets (soft launch)
D1 ≥ 38% · D7 ≥ 17% · D30 ≥ 8% · sessions/DAU 3.2+ · median session 7–12 min · notification opt-in ≥ 60% · crash-free ≥ 99.5% · % of D7 actives in a firm or holding territory ≥ 50% (the meta-adoption health metric).

### 22.4 Monetisation (flagged for a later phase — one constraint recorded now)
The economy above is designed to stand **without** selling power or energy: the intended model is cosmetics (drip, tags, trap skins) + a cosmetic season pass. Decision deliberately deferred; the design constraint (no pay-to-win pressure points in core loops) is already baked in.

---

## 23. Open Questions & Known Risks

**Resolved since v1.0:** orientation = **landscape** (§19.1); title = **ENDS**.

**Still open:**
1. Seasonal soft map-reset of territory (§14.6) — great for freshness, some veterans will grumble; alternatives exist (decay-based).
2. Betfrenz in-game betting included at launch vs deferred (§17.5).

**Design risks & mitigations:**
- *Real-place sensitivity* (crime fiction on real postcodes): mitigated by §21.2 fiction layer; keep a rename lever per district if any location draws heat.
- *HD-2D art volume*: the kit-ratio rule (§20.4) and the paper-doll pipeline (§20.5) are the budget; protect them from bespoke-asset creep.
- *Live-defence liveness*: if too few raids get live defence, add "defence window scheduling" (defender picks 2h daily vulnerability windows, CoC-shield style) — designed, shelved, ready.
- *Slang localisation*: UK slang is the brand; ship the long-press translator (§3) and keep system copy (settings, store) plain.
- *App-store review*: §21.3 abstractions are load-bearing; any future feature touching substances/gambling goes through that filter first.
- *Economy inflation at scale*: the sink ratio target (§15.3) gets a live dashboard from M2 onward; tune fees before payouts.

---

## Appendix A — Master Tuning Tables (v1 baselines)

### A.1 Crime Table
| Crime | Rank | Nerve | Base payout (dirty) | Crit | XP | Heat | District |
|---|---|---|---|---|---|---|---|
| Phone snatch | 1 | 2 | £40–120 | flagship phone (£300–500 item) | 10 | +1 | Strip/Neon |
| Pickpocket | 1 | 2 | £25–80 | +watch (£150–400) | 10 | +1 | Strip |
| Shoplift | 1 | 2 | goods £30–90 | hidden till £250 | 8 | +1 | Strip |
| Bike theft | 2 | 3 | ped £150–300 (fence) | e-bike £600 | 12 | +2 | any |
| Corner shotting | 3 | 5/session | £15/serve, 8–14 serves | "weight" buyer ×5 | 18 | +1/wave | contested |
| Burglary | 3 | 4 | £200–600 + items | wall safe £800–1.5k | 20 | +2 | Rimley |
| Extortion | 4 | 5 | £120–300/venue/wk | — | 15 | +2 | Rimley |
| Chop run | 4 | 6 | £400–900 by model | rare order ×2.5 | 22 | +3 | Docks |
| Touting/jacking | 4 | 4 | £150–450 (night) | — | 15 | +2 | Neon |
| ATM ram-raid | 5 | 8 | £2,000–5,000 | full cassette £8k | 40 | +5 | Docks/Strip |
| Warehouse job | 5 | 9 | £3,000–8,000 | cage pallet ×2 | 45 | +4 | Docks |
| Grow harvest | 5 | — (timer) | product units | mother-plant strain | 25 | site risk | trap |
| Counterfeit run | 6 | 8 | margin £2–6k | designer batch ×3 | 35 | +3 | Leeds/via |
| Heist: Jewellers | 7 | 15 | £15k–50k pool | the safe gamble ×2 | 120 | +8 | W1 |

### A.2 Skill-Track Template (two samples; all tracks follow the shape)
**Pickpocket:** L3 faster lift · L5 watches · L8 read carry-value · L10 crowd immunity · L13 double-dip chance 15% · L15 zero-fumble greens · L18 "mark radar" minimap dots · L20 *Fingersmith* title + gold-hand badge.
**Shotting:** L3 +1 serve/wave · L5 undercover tells clearer · L8 regulars (guaranteed first wave) · L10 −1 Nerve cost · L13 weight-buyer odds ×2 · L15 heat/wave halved · L18 crew-corner yield +10% aura · L20 *Pattern Man* title.

### A.3 Defence Elements
| Element | Cost (clean) | Tier req | Effect |
|---|---|---|---|
| Reinforced door | £800 | T2 | 12 s breach hold (stacking routes) |
| Lookout post | £600 + Lookout | T2 | +fed-ETA pressure; 120° detection |
| Dog run | £1,000 | T2 | Patrol cone; *Meat* counter (£50 consumable) |
| Stair trap | £1,200 | T3 | One-time 3 s stun |
| Camera | £900 | T3 | Position reveal to defence |
| Cage | £2,500 | T3 | +8 s on stash crack |
| Decoy stash | £1,500 | T4 | Eats one Grab for junk |

### A.4 Formula Card (quick reference)
HP `100+TGH×5` · ATK `STR×2+wpn` · DEF `TGH×2+gear` · DMG `ATK×(1−DEF/(DEF+150))×0.85–1.15` · Crit `5%+SPD×0.2` ×1.7 · Flee `30+(ΔSPD×2)+40shove, 10–85%` · Duppy'd loss `25% carried dirty` · Arrest loss `100% carried dirty+contraband` · Raidable stash `20% stash dirty` · Wash fees `30→12% by front tier` · Sink ratio target `55–65%`.

---

*ENDS GDD v1.1 — written for Snicla. Companion document: ENDS Backend Design Document v1.0. Next deliverables: (1) M0 build spec for Claude Code, (2) wireframe pack for the 28-screen inventory, (3) district map layouts for The Fields + The Strip.*

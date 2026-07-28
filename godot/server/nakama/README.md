# Nakama server — INERT until M3

The game runs fully on the client's `LocalGateway` today (M1/M2). This folder is
the **server-authoritative** implementation for M3, written and ready but not yet
wired in.

## When you get to M3
1. Install **Docker Desktop** (not present on this machine yet).
2. `cd godot/server/nakama && docker compose up` — brings up Nakama + Postgres.
3. Admin console: http://localhost:7351 (default `admin` / `password`).
4. Build the TS runtime module (`src/main.ts` → `data/modules/*.js`) with the
   Nakama TS setup (`npm i` + `tsc`), or run it via the JS runtime.
5. In Godot, add a `NakamaGateway` that implements the **same methods** as
   `autoload/server_gateway.gd` but calls these RPCs over the Nakama SDK. Point
   the game at it by swapping the `ServerGateway` autoload — no other client
   changes, because no game logic lives in the UI.

## Why it's split this way
Backend design doc doctrine: the server owns every number that matters (money,
XP, outcomes, wars); the client is "a very pretty liar" that only animates
server-resolved results. Keeping all logic behind one gateway is what makes this
swap cost ~one file instead of a rewrite.

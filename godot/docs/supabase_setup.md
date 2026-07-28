# Postcode Wars — cloud accounts (Supabase) setup

Accounts + cross-device save use **Supabase** (hosted Postgres + Auth). The game
calls Supabase directly over HTTPS from the web build. Until you fill in the two
public values below, the game runs **local-only** (progress saved per-device) and
GUEST RUN always works.

## 1. Create the project
1. Go to https://supabase.com → sign in → **New project** (free tier is fine).
2. Pick a name + database password (the DB password is not used by the game).
3. Wait ~2 min for it to provision.

## 2. Create the saves table + security
Open **SQL Editor** → New query → paste and run:

```sql
-- one row per player, holding their whole game state as JSON
create table if not exists public.saves (
  user_id    uuid primary key references auth.users(id) on delete cascade,
  state      jsonb not null default '{}',
  updated_at timestamptz not null default now()
);

alter table public.saves enable row level security;

-- a player can only read/write their OWN row
create policy "own save read"   on public.saves for select using (auth.uid() = user_id);
create policy "own save insert" on public.saves for insert with check (auth.uid() = user_id);
create policy "own save update" on public.saves for update using (auth.uid() = user_id);
```

## 3. (Recommended) turn off email confirmation for a smooth first run
**Authentication → Sign In / Providers → Email** → turn **Confirm email** OFF.
(With it on, new players must click a link in their inbox before their first
sign-in. You can leave it on if you prefer that.)

## 4. Get the two PUBLIC values
**Project Settings → API**:
- **Project URL** — e.g. `https://abcd1234.supabase.co`
- **anon / public** key — the long `eyJ…` string labelled *anon public*

> Only ever use the **anon (public)** key here. It's designed to be embedded in
> client apps and is safe in the repo because Row-Level Security (step 2) stops
> anyone reading another player's save. **Never** put the `service_role` secret in
> the game.

## 5. Paste them into the game
Edit `godot/data/backend.json`:

```json
{
  "supabase_url": "https://YOUR-PROJECT.supabase.co",
  "anon_key": "eyJhbGciOi...your-anon-key..."
}
```

Re-export the web build and deploy. Done — NEW FACE creates an account, GET TO
WORK signs in and pulls your cloud save, and progress auto-syncs after that.

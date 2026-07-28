extends Node
## Events — a global signal hub (guide Step 3). Signals only, no logic. The
## Director, Threads, Telemetry and Notifications all listen here so systems
## react without knowing about each other. Every system that changes state emits;
## every system that reacts listens. No direct cross-references between screens.

signal session_started(seconds_since_last: int)
signal session_ending()
signal money_changed(dirty: int, clean: int)
signal job_completed(job_id: String, outcome: String, payout: int, stages: int)
signal job_failed(job_id: String, stage: int)
signal level_up(new_level: int)
signal xp_gained(amount: int)
signal stat_trained(stat: String, new_value: int)
signal venue_unlocked(venue_id: String)
signal objective_changed(objective_id: String)
signal objective_completed(objective_id: String)
signal beat_triggered(beat_id: String)
signal timer_started(timer_id: String, ends_at: int)
signal timer_completed(timer_id: String)
signal heat_changed(pips: int)
signal ambushed(attacker: Dictionary)
signal combat_resolved(won: bool, log: Array)
signal arrested(charge: String, minutes: int)
signal hospitalised(minutes: int)
signal daily_completed(index: int)
signal dailies_all_complete()
signal relationship_changed(character_id: String, delta: int)
signal item_acquired(item_id: String, rarity: String)
signal travelled(city: String)
signal target_cased(target_id: String)

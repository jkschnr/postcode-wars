/* ============================================================
   POSTCODE WARS — UPGRADE 01 · ART MAP
   Maps game content to the new art in upgrade_01/art/.
   Load AFTER the base art.js — it extends, never replaces.
   ============================================================ */

/* Venue fascia signage, 640 × 220. One per venue type. */
window.VENUE_SIGN = {
  barber:'barber', chicken:'chicken', tyres:'tyres', betting:'betting',
  laundry:'laundry', corner:'corner', gym:'gym', lockups:'lockups',
  /* aliases used in the base screens */
  'uncle t':'barber', 'chickenlix':'chicken', 'maz tyres':'tyres',
  'betfrenz':'betting', 'bubbles':'laundry', 'pearl & sons':'corner',
  'ironworks':'gym', 'arch 14':'lockups', 'the fence':'lockups'
};
window.signFor = function (venue) {
  const k = String(venue || '').toLowerCase().trim();
  return 'upgrade_01/art/sign-' + (VENUE_SIGN[k] || 'corner') + '.png';
};

/* Crew class emblems, 128 × 128. */
window.CREW_BADGE = { driver:'driver', muscle:'muscle', tech:'tech', face:'face',
  wheelman:'driver', enforcer:'muscle', hacker:'tech', talker:'face' };
window.badgeFor = function (cls) {
  const k = String(cls || '').toLowerCase().trim();
  return 'upgrade_01/art/badge-' + (CREW_BADGE[k] || 'muscle') + '.png';
};

/* Vehicles, side-on, 520 × 260. */
window.VEHICLE_ART = { moped:'moped', scooter:'scooter', transit:'transit', van:'transit',
  car:'hirecar', hire:'hirecar', hirecar:'hirecar' };
window.vehicleFor = function (v) {
  const k = String(v || '').toLowerCase().trim();
  return 'upgrade_01/art/veh-' + (VEHICLE_ART[k] || 'moped') + '.png';
};

/* 28 new items. Names are the in-game strings; ids are the files. */
window.ITEM_ART_2 = {
  'crowbar, bent':'crowbar', 'angle grinder':'angle_grinder', 'cordless drill':'drill',
  'sledgehammer':'sledge', 'work gloves':'gloves', 'balaclava, black':'balaclava',
  'tracksuit, clean':'tracksuit', 'puffa jacket':'puffa', 'watch, no papers':'watch',
  'gold chain':'chain', 'signet ring':'ring', 'bundle of fifties':'bundle_cash',
  'coin pouch':'coin_pouch', 'tray of sims':'sim_tray', 'laptop, wiped':'laptop',
  'router, cloned':'router', 'bodycam, lifted':'bodycam', 'police radio':'radio',
  'warrant, unserved':'warrant', 'passport, not yours':'passport', 'deeds to the arches':'deeds',
  'burner sim':'burner_sim', 'bag of pills':'pill_bag', 'set of scales':'scales',
  'vac-sealed bag':'vac_bag', 'crate, unmarked':'crate', 'toolbox':'toolbox', 'ladder':'ladder'
};
window.artFor2 = function (name) {
  const k = String(name || '').toLowerCase().replace(/\u2019/g, "'").trim();
  if (window.ITEM_ART_2[k]) return 'upgrade_01/art/item-' + ITEM_ART_2[k] + '.png';
  if (window.artFor) return window.artFor(name);   /* fall back to the base 12 */
  return 'upgrade_01/art/item-crate.png';
};

/* Drop-in replacement for the base itemArt() that knows about all 40 items. */
window.itemArt2 = function (name, height, extra) {
  return '<div style="height:' + height + 'px;border-radius:12px;overflow:hidden;background-image:url(' +
    artFor2(name) + ');background-size:cover;background-position:center;' + (extra || '') + '"></div>';
};

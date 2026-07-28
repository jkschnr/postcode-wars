/* ============================================================
   POSTCODE WARS — UPGRADE 01 · GRADE
   City colour grade · weather · time of day · heat state.
   Pure overlay layers. No art required, no layout changes.
   ============================================================
   Usage:
     applyGrade(el, { city:'glasgow', weather:'rain', time:'night', heat:4 })
   `el` is any positioned container (a street band, a screen frame).
   Call once on mount; call again to change state.
   ============================================================ */

/* Each city gets its own light temperature and haze. Same art, 13 moods. */
window.CITY_GRADE = {
  london:     { tint:'#FFA94D', amt:0.18, haze:'#2a1f16', sat:1.02, name:'sodium' },
  birmingham: { tint:'#FFB066', amt:0.15, haze:'#241d16', sat:1.00, name:'sodium warm' },
  manchester: { tint:'#8FB8D8', amt:0.16, haze:'#161d24', sat:0.94, name:'rain blue' },
  liverpool:  { tint:'#7FC8C0', amt:0.15, haze:'#14201f', sat:0.96, name:'dock teal' },
  leeds:      { tint:'#C2A87A', amt:0.14, haze:'#201d16', sat:0.98, name:'stone' },
  newcastle:  { tint:'#9FB4D8', amt:0.17, haze:'#161a24', sat:0.93, name:'cold north' },
  glasgow:    { tint:'#8FA3C2', amt:0.20, haze:'#131721', sat:0.90, name:'granite' },
  nottingham: { tint:'#D8A87F', amt:0.14, haze:'#211a15', sat:1.00, name:'brick' },
  bristol:    { tint:'#93C79F', amt:0.15, haze:'#161f19', sat:0.97, name:'green damp' },
  grimsby:    { tint:'#A8BFC7', amt:0.16, haze:'#151c1f', sat:0.92, name:'salt' },
  luton:      { tint:'#E0B27A', amt:0.13, haze:'#1f1a14', sat:0.99, name:'flat amber' },
  swindon:    { tint:'#C7C2A8', amt:0.12, haze:'#1d1c17', sat:0.96, name:'ringroad' },
  margate:    { tint:'#B9C7D8', amt:0.15, haze:'#171c22', sat:0.94, name:'seafront' }
};

/* Weather is a session-level state. It changes how every street reads. */
window.WEATHER = {
  dry:     { wet:0.00, streaks:0,   fog:0.00, label:'DRY' },
  drizzle: { wet:0.28, streaks:0.5, fog:0.10, label:'DRIZZLE' },
  rain:    { wet:0.55, streaks:1.0, fog:0.14, label:'RAIN' },
  downpour:{ wet:0.80, streaks:1.6, fog:0.22, label:'DOWNPOUR' }
};

/* Three grades only. A 4am job should look like 4am. */
window.TIME_OF_DAY = {
  dusk:  { lift:'#2a1f18', dark:0.20, warm:0.16, label:'DUSK'  },
  night: { lift:'#0e1116', dark:0.42, warm:0.10, label:'NIGHT' },
  dawn:  { lift:'#1c2026', dark:0.30, warm:0.04, label:'DAWN'  }
};

function layer(el, key, css) {
  let d = el.querySelector(':scope > [data-grade="' + key + '"]');
  if (!d) {
    d = document.createElement('div');
    d.setAttribute('data-grade', key);
    d.style.position = 'absolute';
    d.style.inset = '0';
    d.style.pointerEvents = 'none';
    el.appendChild(d);
  }
  d.style.cssText += ';' + css;
  return d;
}

window.applyGrade = function (el, o) {
  o = o || {};
  const city = CITY_GRADE[o.city] || CITY_GRADE.london;
  const w = WEATHER[o.weather] || WEATHER.rain;
  const t = TIME_OF_DAY[o.time] || TIME_OF_DAY.night;
  const heat = Math.max(0, Math.min(5, o.heat || 0));
  if (getComputedStyle(el).position === 'static') el.style.position = 'relative';

  /* 1 — time of day: overall darkness and lift */
  layer(el, 'tod', 'z-index:2;background:' + t.lift + ';opacity:' + t.dark + ';mix-blend-mode:multiply;');

  /* 2 — city tint: the light temperature of the place */
  layer(el, 'city', 'z-index:3;background:' + city.tint + ';opacity:' + city.amt + ';mix-blend-mode:soft-light;');

  /* 3 — haze: distance and damp air */
  layer(el, 'haze', 'z-index:4;background:linear-gradient(180deg,' + city.haze + ' 0%, rgba(0,0,0,0) 55%);opacity:' + (0.5 + w.fog * 2) + ';');

  /* 4 — wet sheen: reflected light off the road */
  layer(el, 'wet', 'z-index:5;background:linear-gradient(180deg, rgba(0,0,0,0) 40%, ' + city.tint +
    '22 78%, ' + city.tint + '3a 100%);opacity:' + w.wet + ';mix-blend-mode:screen;');

  /* 5 — rain streaks: two sheets at different angles read as depth */
  const st = layer(el, 'rain', 'z-index:6;opacity:' + Math.min(1, w.streaks * 0.5) + ';overflow:hidden;');
  st.innerHTML = w.streaks ? `
    <div style="position:absolute;inset:-25%;background-image:repeating-linear-gradient(101deg, rgba(255,255,255,0.13) 0 1px, rgba(255,255,255,0) 1px ${Math.round(14 / w.streaks)}px);animation:pwRainA ${Math.round(900 / w.streaks)}ms linear infinite;"></div>
    <div style="position:absolute;inset:-25%;background-image:repeating-linear-gradient(97deg, rgba(255,255,255,0.08) 0 1px, rgba(255,255,255,0) 1px ${Math.round(22 / w.streaks)}px);animation:pwRainB ${Math.round(1500 / w.streaks)}ms linear infinite;"></div>` : '';

  /* 6 — heat: at 4+ the street turns police blue and breathes. Felt before it is read. */
  const h = layer(el, 'heat', 'z-index:7;');
  if (heat >= 4) {
    h.style.background = 'radial-gradient(120% 60% at 50% 0%, rgba(46,94,170,0.30), rgba(46,94,170,0) 70%)';
    h.style.animation = 'pwHeatPulse 2600ms ease-in-out infinite';
    h.style.opacity = '1';
  } else if (heat === 3) {
    h.style.background = 'radial-gradient(120% 60% at 50% 0%, rgba(46,94,170,0.14), rgba(46,94,170,0) 70%)';
    h.style.animation = 'none';
    h.style.opacity = '1';
  } else {
    h.style.opacity = '0';
    h.style.animation = 'none';
  }

  el.dataset.gradeState = [o.city || 'london', w.label, t.label, 'HEAT ' + heat].join(' · ');
  return el.dataset.gradeState;
};

/* Keyframes the grade layers rely on. Injected once. */
(function () {
  if (document.getElementById('pw-grade-keys')) return;
  const s = document.createElement('style');
  s.id = 'pw-grade-keys';
  s.textContent = `
@keyframes pwRainA { to { transform:translate(-90px, 420px); } }
@keyframes pwRainB { to { transform:translate(-60px, 420px); } }
@keyframes pwHeatPulse { 0%,100% { opacity:0.55; } 50% { opacity:1; } }
@keyframes pwSweep { 0% { transform:translateX(-40%) skewX(-18deg); opacity:0; }
  12% { opacity:0.9; } 88% { opacity:0.9; } 100% { transform:translateX(140%) skewX(-18deg); opacity:0; } }
@keyframes pwFlicker { 0%,72%,100% { opacity:1; } 74% { opacity:0.25; } 76% { opacity:0.9; } 78% { opacity:0.4; } 80% { opacity:1; } }
@keyframes pwDrift { 0% { transform:translateX(0); } 100% { transform:translateX(-60px); } }`;
  document.head.appendChild(s);
})();

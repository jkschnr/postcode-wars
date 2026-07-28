/* ============================================================
   POSTCODE WARS — UPGRADE 01 · AMBIENCE
   Idle motion so a screen feels inhabited while nothing happens.
   All of it is decorative, pointer-events:none, and safe to strip.
   ============================================================
   Usage:
     ambience(el, { headlights:true, lamp:true, drift:true, litter:true })
   Call on any street band / hero image container.
   ============================================================ */

window.ambience = function (el, o) {
  o = o || {};
  if (getComputedStyle(el).position === 'static') el.style.position = 'relative';
  let w = el.querySelector(':scope > [data-ambience]');
  if (w) w.remove();
  w = document.createElement('div');
  w.setAttribute('data-ambience', '1');
  w.style.cssText = 'position:absolute;inset:0;overflow:hidden;pointer-events:none;z-index:8;';
  el.appendChild(w);

  /* A car passes every 9–16 s. Headlight sweep only — never a drawn car. */
  if (o.headlights !== false) {
    const sweep = document.createElement('div');
    sweep.style.cssText = 'position:absolute;top:0;bottom:0;width:34%;left:0;' +
      'background:linear-gradient(90deg, rgba(255,232,190,0) 0%, rgba(255,232,190,0.20) 45%, rgba(255,201,122,0.30) 60%, rgba(255,232,190,0) 100%);' +
      'opacity:0;';
    w.appendChild(sweep);
    const pass = () => {
      sweep.style.animation = 'none';
      void sweep.offsetWidth;
      sweep.style.animation = 'pwSweep ' + (1100 + Math.random() * 700) + 'ms ease-in-out both';
      setTimeout(pass, 9000 + Math.random() * 7000);
    };
    setTimeout(pass, 1200 + Math.random() * 4000);
  }

  /* One lamp in shot flickers on a long, irregular cycle. */
  if (o.lamp !== false) {
    const lamp = document.createElement('div');
    const lx = o.lampX || (18 + Math.random() * 64);
    lamp.style.cssText = 'position:absolute;top:-10%;left:' + lx + '%;width:26%;height:70%;' +
      'background:radial-gradient(50% 40% at 50% 0%, rgba(255,201,122,0.30), rgba(255,169,77,0.07) 45%, rgba(0,0,0,0) 72%);' +
      'animation:pwFlicker ' + (5200 + Math.random() * 4000) + 'ms steps(1,end) infinite;';
    w.appendChild(lamp);
  }

  /* Very slow horizontal drift on a haze layer — reads as air moving. */
  if (o.drift !== false) {
    const d = document.createElement('div');
    d.style.cssText = 'position:absolute;inset:-8% -20%;' +
      'background:radial-gradient(40% 60% at 30% 70%, rgba(255,255,255,0.035), rgba(0,0,0,0) 70%);' +
      'animation:pwDrift ' + (26000 + Math.random() * 12000) + 'ms ease-in-out infinite alternate;';
    w.appendChild(d);
  }

  /* Two scraps of litter turning over in the gutter. */
  if (o.litter) {
    for (let i = 0; i < 2; i++) {
      const s = document.createElement('div');
      s.style.cssText = 'position:absolute;bottom:' + (4 + i * 7) + '%;left:' + (10 + i * 40) + '%;' +
        'width:' + (6 + i * 3) + 'px;height:' + (4 + i * 2) + 'px;background:rgba(200,200,190,0.14);' +
        'animation:pwDrift ' + (14000 + i * 5000) + 'ms linear infinite alternate;';
      w.appendChild(s);
    }
  }
  return w;
};

/* Stop all ambience on a container (before a screen transition, or for a still capture). */
window.ambienceOff = function (el) {
  const w = el && el.querySelector(':scope > [data-ambience]');
  if (w) w.remove();
};

/* ============================================================
   POSTCODE WARS — UPGRADE 01 · FX
   Rarity light · job-type stingers · map travel draw · paperwork interrupt.
   ============================================================ */

window.RARITY = {
  basic:  { col:'#B9C0C7', glow:0.10, shake:0 },
  decent: { col:'#6FCF6F', glow:0.18, shake:0 },
  peng:   { col:'#4DA3FF', glow:0.30, shake:1 },
  certi:  { col:'#B06CF0', glow:0.44, shake:2 },
  iconic: { col:'#F2C14E', glow:0.62, shake:3 }
};

/* ------------------------------------------------------------
   1 · RARITY AS LIGHT
   Rarity is currently only a border colour. Give the good stuff
   a glow pool that spills onto the surface behind it.
   ------------------------------------------------------------ */
window.rarityLight = function (el, rarity) {
  const r = RARITY[rarity] || RARITY.basic;
  if (getComputedStyle(el).position === 'static') el.style.position = 'relative';
  let g = el.querySelector(':scope > [data-rarity-glow]');
  if (!g) {
    g = document.createElement('div');
    g.setAttribute('data-rarity-glow', '1');
    g.style.cssText = 'position:absolute;inset:-30%;pointer-events:none;z-index:-1;';
    el.insertBefore(g, el.firstChild);
  }
  g.style.background = 'radial-gradient(50% 50% at 50% 55%, ' + r.col +
    Math.round(r.glow * 255).toString(16).padStart(2, '0') + ', rgba(0,0,0,0) 70%)';
  el.style.borderColor = r.col;
  if (r.glow >= 0.44) g.style.animation = 'pwHeatPulse 3200ms ease-in-out infinite';
  return r;
};

/* Pick the best rarity in a drop — the bag rim and glow pool take its colour. */
window.bestRarity = function (list) {
  const order = ['basic', 'decent', 'peng', 'certi', 'iconic'];
  return list.reduce((a, b) => (order.indexOf(b) > order.indexOf(a) ? b : a), 'basic');
};

/* ------------------------------------------------------------
   2 · JOB-TYPE STINGERS
   One shared reveal for every job reads flat. Four types, four
   entrances — the player knows what happened before reading.
   ------------------------------------------------------------ */
window.STINGER = {
  wheels:   { col:'#4DA3FF', word:'GONE',    anim:'pwStingSlide 520ms cubic-bezier(.15,.9,.25,1) both', note:'streaks past, left to right' },
  graft:    { col:'#FFA94D', word:'DONE',    anim:'pwStingStamp 460ms cubic-bezier(.2,.9,.3,1) both',  note:'lands square, no flourish' },
  hustle:   { col:'#B06CF0', word:'SOLD',    anim:'pwStingFlip 560ms cubic-bezier(.2,.8,.3,1) both',   note:'turns over like a card' },
  violence: { col:'#D63B3B', word:'SORTED',  anim:'pwStingHit 380ms cubic-bezier(.3,1.6,.4,1) both',   note:'snaps in hard and rattles' }
};

window.stinger = function (host, type, text) {
  const s = STINGER[type] || STINGER.graft;
  const el = document.createElement('div');
  el.style.cssText = 'position:absolute;left:0;right:0;top:34%;text-align:center;pointer-events:none;z-index:40;' +
    'font-family:Anton, Impact, sans-serif;text-transform:uppercase;font-size:132px;line-height:0.9;' +
    'color:' + s.col + ';text-shadow:0 0 60px ' + s.col + '66, 0 8px 0 rgba(0,0,0,0.5);animation:' + s.anim + ';';
  el.textContent = text || s.word;
  if (getComputedStyle(host).position === 'static') host.style.position = 'relative';
  host.appendChild(el);
  if (type === 'violence') {
    host.style.animation = 'pwShake 260ms cubic-bezier(.36,.07,.19,.97) both';
    setTimeout(() => (host.style.animation = 'none'), 320);
  }
  setTimeout(() => el.remove(), 1600);
  return s;
};

/* ------------------------------------------------------------
   3 · MAP TRAVEL DRAW
   The route draws city to city with the glow riding the line.
   Give it an <svg> overlay sized to the map viewport.
   ------------------------------------------------------------ */
window.travelDraw = function (svg, from, to, ms, done) {
  const NS = 'http://www.w3.org/2000/svg';
  const dx = to.x - from.x, dy = to.y - from.y;
  const mid = { x: from.x + dx * 0.5 - dy * 0.16, y: from.y + dy * 0.5 + dx * 0.16 };
  const d = 'M' + from.x + ',' + from.y + ' Q' + mid.x + ',' + mid.y + ' ' + to.x + ',' + to.y;

  const path = document.createElementNS(NS, 'path');
  path.setAttribute('d', d);
  path.setAttribute('fill', 'none');
  path.setAttribute('stroke', '#FFA94D');
  path.setAttribute('stroke-width', '3');
  path.setAttribute('stroke-linecap', 'round');
  svg.appendChild(path);

  const len = path.getTotalLength();
  path.style.strokeDasharray = len;
  path.style.strokeDashoffset = len;
  path.style.transition = 'stroke-dashoffset ' + (ms || 900) + 'ms cubic-bezier(.3,.8,.3,1)';

  const head = document.createElementNS(NS, 'circle');
  head.setAttribute('r', '7');
  head.setAttribute('fill', '#FFC97A');
  head.setAttribute('filter', 'drop-shadow(0 0 10px #FFA94D)');
  svg.appendChild(head);

  const t0 = performance.now();
  requestAnimationFrame(() => (path.style.strokeDashoffset = '0'));
  (function ride(t) {
    const p = Math.min(1, (t - t0) / (ms || 900));
    const pt = path.getPointAtLength(len * p);
    head.setAttribute('cx', pt.x);
    head.setAttribute('cy', pt.y);
    if (p < 1) requestAnimationFrame(ride);
    else { head.remove(); done && done(); }
  })(t0);
  return path;
};

/* ------------------------------------------------------------
   4 · PAPERWORK INTERRUPT
   A warrant or seizure notice slides over the screen at a story
   beat. The document art already exists — this is the delivery.
   ------------------------------------------------------------ */
window.PAPER_KIND = {
  warrant: { title:'WARRANT OF ENTRY',   ref:'CR/2026/', col:'#D63B3B', body:'Premises may be entered and searched. Force may be used.' },
  seizure: { title:'SEIZURE NOTICE',     ref:'PA/2026/', col:'#C9A227', body:'Cash detained under suspicion of unlawful origin. 48 hours to respond.' },
  eviction:{ title:'NOTICE TO QUIT',     ref:'HS/2026/', col:'#FFA94D', body:'Possession sought. You have 14 days from the date shown.' },
  charge:  { title:'CHARGE SHEET',       ref:'PS/2026/', col:'#2E5EAA', body:'You are charged with the offence set out below. You must attend.' }
};

window.paperInterrupt = function (host, kind, fields, onDismiss) {
  const k = PAPER_KIND[kind] || PAPER_KIND.warrant;
  const scrim = document.createElement('div');
  scrim.style.cssText = 'position:absolute;inset:0;z-index:60;background:rgba(6,7,9,0.78);' +
    'display:flex;align-items:center;justify-content:center;padding:48px;animation:pwFade 220ms ease-out both;';
  const rows = Object.entries(fields || {}).map(([k2, v]) => `
    <div style="display:flex;justify-content:space-between;gap:16px;border-bottom:1px solid rgba(0,0,0,0.18);padding:12px 0;">
      <span style="font-family:'IBM Plex Mono',monospace;font-size:20px;letter-spacing:0.12em;color:#6b6558;">${k2.toUpperCase()}</span>
      <span style="font-family:'IBM Plex Mono',monospace;font-size:22px;color:#2a2620;text-align:right;">${v}</span>
    </div>`).join('');

  scrim.innerHTML = `
    <div style="width:100%;max-width:880px;background:#dcd6c2;border-radius:4px;padding:44px 48px;
      box-shadow:0 40px 80px rgba(0,0,0,0.6);animation:pwPaperIn 460ms cubic-bezier(.2,.9,.3,1) both;">
      <div style="display:flex;align-items:baseline;justify-content:space-between;gap:20px;border-bottom:3px solid ${k.col};padding-bottom:16px;">
        <span style="font-family:Anton,Impact,sans-serif;font-size:46px;text-transform:uppercase;color:#1e1b16;">${k.title}</span>
        <span style="font-family:'IBM Plex Mono',monospace;font-size:22px;color:${k.col};">${k.ref}${Math.floor(1000 + Math.random() * 8999)}</span>
      </div>
      <div style="font-size:26px;line-height:1.45;color:#3a3529;padding:20px 0 8px;">${k.body}</div>
      ${rows}
      <div style="display:flex;align-items:center;gap:20px;padding-top:26px;">
        <div style="flex:1;font-family:'IBM Plex Mono',monospace;font-size:19px;color:#6b6558;">SERVED IN PERSON · SIGNED</div>
        <div style="border:4px solid ${k.col};color:${k.col};border-radius:6px;padding:6px 18px;transform:rotate(-4deg);
          font-family:Anton,Impact,sans-serif;font-size:34px;text-transform:uppercase;
          animation:pwStingStamp 520ms cubic-bezier(.2,.9,.3,1) 320ms both;">SERVED</div>
      </div>
      <button style="margin-top:30px;width:100%;height:96px;border:none;border-radius:10px;background:#2a2620;color:#dcd6c2;
        font-family:Anton,Impact,sans-serif;font-size:34px;text-transform:uppercase;letter-spacing:0.04em;">Take it</button>
    </div>`;

  if (getComputedStyle(host).position === 'static') host.style.position = 'relative';
  host.appendChild(scrim);
  scrim.querySelector('button').addEventListener('click', () => {
    scrim.style.animation = 'pwFade 180ms ease-in reverse both';
    setTimeout(() => { scrim.remove(); onDismiss && onDismiss(); }, 180);
  });
  return scrim;
};

/* Keyframes for stingers, paperwork and shake. Injected once. */
(function () {
  if (document.getElementById('pw-fx-keys')) return;
  const s = document.createElement('style');
  s.id = 'pw-fx-keys';
  s.textContent = `
@keyframes pwFade { from { opacity:0; } to { opacity:1; } }
@keyframes pwPaperIn { from { transform:translateY(-60px) rotate(-1.5deg) scale(0.97); opacity:0; }
  to { transform:none; opacity:1; } }
@keyframes pwStingSlide { 0% { transform:translateX(-60%) skewX(-14deg); opacity:0; }
  60% { transform:translateX(0) skewX(-4deg); opacity:1; } 100% { transform:none; opacity:1; } }
@keyframes pwStingStamp { 0% { transform:scale(1.6) rotate(-6deg); opacity:0; }
  60% { transform:scale(1) rotate(-2deg); opacity:1; } 100% { transform:scale(1) rotate(-2deg); opacity:1; } }
@keyframes pwStingFlip { 0% { transform:perspective(900px) rotateY(96deg) scale(0.9); opacity:0; }
  to { transform:none; opacity:1; } }
@keyframes pwStingHit { 0% { transform:scale(2.1); opacity:0; } 55% { transform:scale(0.94); opacity:1; }
  100% { transform:scale(1); opacity:1; } }
@keyframes pwShake { 10%,90% { transform:translateX(-3px); } 20%,80% { transform:translateX(5px); }
  30%,50%,70% { transform:translateX(-8px); } 40%,60% { transform:translateX(8px); } }`;
  document.head.appendChild(s);
})();

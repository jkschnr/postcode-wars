/* Sprite-strip player + small motion helpers. Strips are horizontal, nearest-neighbour.
   sprite(el, { src, frames, fw, fh, fps, loop, autoplay, mode })  → controller */
window.sprite = function (el, o) {
  const fw = o.fw, fh = o.fh, n = o.frames, scale = (el.clientWidth || fw) / fw;
  el.style.imageRendering = 'pixelated';
  el.style.backgroundImage = 'url(' + o.src + ')';
  el.style.backgroundRepeat = 'no-repeat';
  el.style.backgroundSize = (fw * n * scale) + 'px ' + (fh * scale) + 'px';
  let i = 0, timer = null;
  const show = k => { i = ((k % n) + n) % n; el.style.backgroundPosition = (-i * fw * scale) + 'px 0'; };
  const api = {
    show,
    play(fps, loop) {
      api.stop();
      const step = 1000 / (fps || o.fps || 8);
      timer = setInterval(() => {
        if (!loop && i === n - 1) { api.stop(); return; }
        show(i + 1);
      }, step);
      return api;
    },
    once(fps) { show(0); return api.play(fps, false); },
    stop() { if (timer) clearInterval(timer); timer = null; return api; },
    frame: () => i
  };
  show(0);
  if (o.autoplay) api.play(o.fps, o.loop !== false);
  return api;
};

/* Talking head: idle blinks, mouth flaps while a line is "spoken". */
window.talkingHead = function (el, src, opts) {
  opts = opts || {};
  const sp = sprite(el, { src, frames:4, fw:opts.fw || 96, fh:opts.fh || 120 });
  let talking = false, blinkT = null, talkT = null;
  function scheduleBlink() {
    blinkT = setTimeout(() => {
      if (!talking) { sp.show(1); setTimeout(() => { if (!talking) sp.show(0); }, 110); }
      scheduleBlink();
    }, 1800 + Math.random() * 3200);
  }
  scheduleBlink();
  return {
    sprite: sp,
    say(ms) {
      talking = true;
      clearInterval(talkT);
      talkT = setInterval(() => sp.show(2 + Math.round(Math.random())), 110);
      setTimeout(() => { clearInterval(talkT); talking = false; sp.show(0); }, ms || 2200);
    },
    stop() { clearInterval(talkT); clearTimeout(blinkT); sp.stop(); }
  };
};

/* Type a line out, character by character — pairs with talkingHead. */
window.typeOut = function (el, text, cps, done) {
  let i = 0;
  el.textContent = '';
  const step = 1000 / (cps || 42);
  const t = setInterval(() => {
    el.textContent = text.slice(0, ++i);
    if (i >= text.length) { clearInterval(t); done && done(); }
  }, step);
  return () => clearInterval(t);
};

/* Count a number up — money, XP, anything with tabular figures. */
window.countTo = function (el, target, ms, fmt) {
  const t0 = performance.now();
  fmt = fmt || (v => v.toLocaleString('en-GB'));
  function step(t) {
    const p = Math.min(1, (t - t0) / (ms || 900));
    el.textContent = fmt(Math.round(target * (1 - Math.pow(1 - p, 3))));
    if (p < 1) requestAnimationFrame(step);
  }
  requestAnimationFrame(step);
};

/* Capture prep: export engines can drop CSS background images. Bake each art background
   into a same-origin data-URL <img> (sprite strips are cropped to their current frame) so
   exported reference PNGs match the live render. Capture-time only — never called in game. */
window.__capPrep = async function () {
  const load = src => new Promise(r => { const i = new Image(); i.onload = () => r(i); i.onerror = () => r(null); i.src = src; });
  const targets = [];
  document.querySelectorAll('*').forEach(d => {
    const st = getComputedStyle(d);
    if (!st.backgroundImage.includes('/art/')) return;
    const u = st.backgroundImage.match(/url\("([^"]+)"\)/);
    if (u) targets.push([d, u[1], st]);
  });
  let n = 0;
  for (const [d, src, st] of targets) {
    const img = await load(src);
    if (!img) continue;
    let url = src, fit = st.backgroundSize.includes('contain') ? 'contain' : 'cover', pos = st.backgroundPosition;
    if (src.includes('anim-')) {
      // strips animate in game; a still reads correctly in an exported reference frame
      url = src.replace('anim-', 'px-');
      fit = 'cover'; pos = '50% 8%';
      if (!(await load(url))) continue;
    }
    const el = document.createElement('img');
    el.src = url;
    el.style.cssText = 'position:absolute;inset:0;width:100%;height:100%;z-index:0;pointer-events:none;object-fit:' +
      fit + ';object-position:' + pos + ';image-rendering:' + st.imageRendering + ';opacity:' + st.opacity + ';';
    if (st.position === 'static') d.style.position = 'relative';
    d.style.backgroundImage = 'none';
    d.insertBefore(el, d.firstChild);
    n++;
  }
  return n;
};

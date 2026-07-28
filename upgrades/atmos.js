/* Atmosphere: real graded street imagery + ghost typography, the look the map screens get.
   mountHero({ id, lat, lon, zoom, kicker, title, meta, back, right, ghost, tint })
   mountBackdrop({ lat, lon, zoom, grade })  — full-frame graded street behind everything */
(function () {
  function makeMap(el, lat, lon, zoom) {
    const m = L.map(el, { dragging:false, touchZoom:false, scrollWheelZoom:false, doubleClickZoom:false,
      boxZoom:false, keyboard:false, zoomControl:false, zoomSnap:0.1, attributionControl:true });
    L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      { attribution:'© OpenStreetMap contributors', maxZoom:19 }).addTo(m);
    m.setView([lat, lon], zoom);
    return m;
  }

  window.mountHero = function (o) {
    const host = document.getElementById(o.id || 'hero');
    if (!host) return;
    const tint = o.tint || '255,169,77';
    host.innerHTML = `
      <div style="position:relative; height:${o.height || 420}px; margin:-28px -32px 26px; overflow:hidden; border-bottom:1px solid #2A2E33;">
        <div id="hero-leaf" style="position:absolute; inset:0; z-index:0; isolation:isolate; background:#0E1013;"></div>
        <div style="position:absolute; inset:0; z-index:2; pointer-events:none; background:
          radial-gradient(44% 44% at 72% 30%, rgba(${tint},0.30), rgba(${tint},0) 70%),
          linear-gradient(180deg, rgba(18,20,23,0.72) 0%, rgba(18,20,23,0.06) 30%, rgba(12,14,16,0.6) 72%, #121417 100%),
          linear-gradient(90deg, rgba(12,14,16,0.6) 0%, rgba(12,14,16,0) 24%, rgba(12,14,16,0) 76%, rgba(12,14,16,0.6) 100%);"></div>
        <div class="disp" style="position:absolute; right:20px; bottom:-46px; z-index:3; font-size:210px; line-height:0.8;
          color:#EDEFF2; opacity:0.11; letter-spacing:-0.02em; pointer-events:none;">${o.ghost || ''}</div>
        <div style="position:absolute; left:32px; right:32px; top:26px; z-index:3; display:flex; align-items:center; justify-content:space-between; gap:20px;">
          ${o.back ? backLink(o.back.label, o.back.href) : '<span></span>'}
          ${o.right || ''}
        </div>
        <div style="position:absolute; left:32px; right:32px; bottom:26px; z-index:3; display:flex; align-items:flex-end; justify-content:space-between; gap:24px;">
          <div style="min-width:0; display:flex; flex-direction:column; gap:8px;">
            <span class="mono" style="font-size:22px; letter-spacing:0.18em; color:rgb(${tint});">${o.kicker || ''}</span>
            <span class="disp" style="font-size:${o.titleSize || 84}px; line-height:0.88; text-shadow:0 6px 30px rgba(0,0,0,0.95);">${o.title || ''}</span>
            ${o.meta ? `<span class="mono" style="font-size:22px; letter-spacing:0.1em; color:#C3C9CF; text-shadow:0 2px 12px rgba(0,0,0,0.9);">${o.meta}</span>` : ''}
          </div>
          ${o.aside || ''}
        </div>
      </div>`;
    makeMap('hero-leaf', o.lat, o.lon, o.zoom || 16.2);
  };

  window.mountBackdrop = function (o) {
    const frame = document.getElementById('frame');
    if (!frame) return;
    const wrap = document.createElement('div');
    wrap.style.cssText = 'position:absolute; inset:0; z-index:0; isolation:isolate;';
    wrap.innerHTML = `<div id="bd-leaf" style="position:absolute; inset:0; background:#0E1013;
        filter:${o.grade || 'grayscale(1) brightness(0.30) contrast(1.5) sepia(0.06) saturate(0.9) blur(1px)'};"></div>`;
    frame.insertBefore(wrap, frame.firstChild);
    makeMap('bd-leaf', o.lat, o.lon, o.zoom || 15.4);
  };
})();

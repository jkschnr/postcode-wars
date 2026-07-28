/* Shared HUD + bottom nav + frame scaling. Fill <div id="hud"></div> / <div id="nav"></div>. */
(function () {
  const W = 1080, H = 1920;
  function scaleFrame() {
    const f = document.getElementById('frame');
    if (!f) return;
    const s = Math.min(1, window.innerHeight / H, window.innerWidth / W);
    f.style.transform = 'scale(' + s + ')';
    document.body.style.height = (H * s) + 'px';
  }
  window.addEventListener('resize', scaleFrame);

  const pip = (on, c) => `<span style="width:14px;height:14px;border-radius:7px;background:${on ? c : '#3A3F45'};"></span>`;

  window.renderHUD = function (o) {
    o = o || {};
    const dirty = o.dirty || '£12,480', clean = o.clean || '£3,050';
    const en = o.en == null ? 62 : o.en, nv = o.nv == null ? 7 : o.nv, heat = o.heat == null ? 3 : o.heat;
    const lvl = o.lvl || 37, xp = o.xp == null ? 48 : o.xp;
    const el = document.getElementById('hud');
    if (!el) return;
    el.innerHTML = `
      <div style="position:absolute; left:0; top:0; width:1080px; height:140px; box-sizing:border-box; padding:0 32px 14px;
        display:flex; flex-direction:column; justify-content:flex-end; background:#2A2E33; border-bottom:1px solid #3A3F45; z-index:40;">
        <div class="tab" style="display:flex; align-items:center; gap:16px;">
          <div style="display:flex; align-items:center; gap:10px; height:56px; padding:0 16px; border:1px solid #C9A227; border-radius:12px; background:rgba(201,162,39,0.10);">
            <span style="width:20px; height:20px; border-radius:4px; border:2px solid #C9A227;"></span>
            <span class="disp" style="font-size:32px; color:#C9A227;">${dirty}</span>
          </div>
          <div style="display:flex; align-items:center; gap:10px; height:56px; padding:0 16px; border:1px solid #57C785; border-radius:12px; background:rgba(87,199,133,0.10);">
            <span style="width:20px; height:20px; border-radius:4px; border:2px solid #57C785;"></span>
            <span class="disp" style="font-size:32px; color:#57C785;">${clean}</span>
          </div>
          <div style="flex:1; display:flex; flex-direction:column; gap:8px; padding-left:8px;">
            <div style="display:flex; align-items:center; gap:10px;">
              <span class="mono" style="font-size:20px; color:#FFA94D; width:30px;">EN</span>
              <div style="flex:1; height:12px; border-radius:6px; background:#0C0E10; overflow:hidden; display:flex;"><div style="width:${en}%; background:#FFA94D;"></div></div>
              <span class="mono" style="font-size:20px; color:#9AA0A6;">${en}/100</span>
            </div>
            <div style="display:flex; align-items:center; gap:10px;">
              <span class="mono" style="font-size:20px; color:#B06CF0; width:30px;">NV</span>
              <div style="flex:1; height:12px; border-radius:6px; background:#0C0E10; overflow:hidden; display:flex;"><div style="width:${nv * 5}%; background:#B06CF0;"></div></div>
              <span class="mono" style="font-size:20px; color:#9AA0A6;">${nv}/20</span>
            </div>
          </div>
          <div style="display:flex; flex-direction:column; align-items:center; gap:8px;">
            <div style="display:flex; gap:6px;">${[0,1,2,3,4].map(i => pip(i < heat, '#D63B3B')).join('')}</div>
            <span class="mono" style="font-size:20px; letter-spacing:0.1em; color:#9AA0A6;">HEAT</span>
          </div>
          <div style="display:flex; flex-direction:column; align-items:flex-end; gap:6px; padding-left:20px; border-left:1px solid #3A3F45;">
            <span class="disp" style="font-size:40px; line-height:1;">${lvl}</span>
            <div style="width:96px; height:6px; border-radius:3px; background:#0C0E10; overflow:hidden; display:flex;"><div style="width:${xp}%; background:#FFC97A;"></div></div>
          </div>
        </div>
      </div>`;
  };

  const TABS = [
    { key:'map',  label:'MAP',  href:'01-map.html',      icon:'border-radius:50% 50% 50% 4px; transform:rotate(-45deg);' },
    { key:'city', label:'CITY', href:'02-city.html',     icon:'border-radius:4px;' },
    { key:'char', label:'CHAR', href:'07-character.html',icon:'border-radius:50%;', badge:true },
    { key:'crew', label:'CREW', href:'11-crew.html',     icon:'border-radius:4px 4px 18px 18px;' },
    { key:'firm', label:'FIRM', href:'20-firm.html',     icon:'border-radius:4px; transform:rotate(45deg);', dim:true }
  ];

  window.renderNav = function (active) {
    const el = document.getElementById('nav');
    if (!el) return;
    el.innerHTML = `
      <div style="position:absolute; left:0; bottom:0; width:1080px; background:#2A2E33; border-top:1px solid #3A3F45; z-index:50;">
        <div style="height:120px; display:grid; grid-template-columns:repeat(5, 1fr);">
          ${TABS.map(t => {
            const on = t.key === active;
            const col = on ? '#FFA94D' : t.dim ? '#5A6068' : '#9AA0A6';
            return `<a href="${t.href}" style="display:flex; flex-direction:column; align-items:center; justify-content:center; gap:10px; position:relative;
              ${on ? 'border-top:4px solid #FFA94D; background:linear-gradient(180deg, rgba(255,169,77,0.14), rgba(255,169,77,0));' : ''}">
              <span style="width:36px; height:36px; border:2px solid ${col}; ${t.icon}"></span>
              ${t.badge && !on ? '<span style="position:absolute; top:24px; right:calc(50% - 34px); width:16px; height:16px; border-radius:8px; background:#D9E021;"></span>' : ''}
              <span class="mono" style="font-size:20px; letter-spacing:0.1em; color:${col};">${t.label}</span>
            </a>`;
          }).join('')}
        </div>
        <div style="height:40px; display:flex; align-items:center; justify-content:center;">
          <span style="width:200px; height:6px; border-radius:3px; background:#5A6068;"></span>
        </div>
      </div>`;
  };

  window.backLink = function (label, href) {
    return `<a href="${href}" class="mono" style="height:72px; padding:0 24px; border:1px solid #2A2E33; border-radius:14px;
      background:rgba(18,20,23,0.82); display:flex; align-items:center; font-size:20px; letter-spacing:0.14em; color:#9AA0A6;">← ${label}</a>`;
  };

  window.timerRing = function (pct, tint, size) {
    size = size || 56;
    return `<div style="width:${size}px;height:${size}px;border-radius:50%;background:conic-gradient(${tint} 0% ${pct}%, #2A2E33 ${pct}% 100%);
      display:flex;align-items:center;justify-content:center;flex:none;">
      <div style="width:${size - 16}px;height:${size - 16}px;border-radius:50%;background:#1E2126;"></div></div>`;
  };

  window.mountChrome = function (activeTab, hudOpts) {
    renderHUD(hudOpts);
    renderNav(activeTab);
    scaleFrame();
  };
  window.scaleFrame = scaleFrame;
})();

/* Generated art plates. Photography drops in later at the same paths. */
window.ART_ITEM = {
  'burner handset':'phone', 'half-empty jerry can':'jerry', 'bolt cutters, blunt':'cutters',
  'scuffed trainers':'trainers', 'hi-vis and a clipboard':'hivis', 'spare plate set':'plates',
  'cloned card reader':'reader', 'signal jammer, boxed':'jammer', 'keys to a white transit':'van',
  'yard keys, copied':'keys', 'betfrenz till codes':'codes',
  "rhodes' ledger page":'ledger', 'the barber\u2019s little black book':'ledger',
  'cloned reader':'reader', 'plate set':'plates', 'burner':'phone'
};
window.artFor = function (name) {
  const k = String(name || '').toLowerCase().replace(/\u2019/g, "'");
  return 'art/px-item-' + (window.ART_ITEM[k] || 'phone') + '.png';
};
window.itemArt = function (name, height, extra) {
  return '<div style="height:' + height + 'px; border-radius:12px; overflow:hidden; image-rendering:pixelated;' +
    ' background-color:#16191d; background-image:url(' + artFor(name) +
    '); background-size:cover; background-position:center; ' + (extra || '') + '"></div>';
};
window.CAST_PLATE = {
  uncle_t:'barber', silas:'office', nads:'flats', delroy:'yard', shauna:'office', tobes:'flats',
  hallow:'carpark', maz:'yard', pearl:'kitchen', ranj:'yard', nev:'office', bev:'yard',
  kadeem:'carpark', marlon:'flats', wesley:'office', jerome:'flats'
};
window.plateFor = function (c) {
  const id = (c && c.id) || String((c && c.name) || '').toLowerCase();
  return 'art/plate-' + (window.CAST_PLATE[id] || 'flats') + '.png';
};

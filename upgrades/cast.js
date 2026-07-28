// Postcode Wars — invented cast. Everyone is an adult; no real people, brands or gangs.
window.CAST = [
  { id:'uncle_t', name:'Uncle T', age:61, role:'BARBER', city:'London', place:'Mare St barbers',
    brief:'61, barber, warm and tired, mid-haircut, clippers in hand, not looking at camera',
    lines:["Sit down. I'll do your edges while you tell me what you've done.",
           "Your brother used to sit in that chair. Straighter back than you.",
           "Money's money. Doesn't mean you take it from the wrong door."] },
  { id:'silas', name:'Silas Rhodes', age:54, role:'THE BRIEF', city:'London', place:'Office above Betfrenz',
    brief:'54, cardigan, reading glasses, fountain pen, small office with a kettle',
    lines:["I don't take instalments, and I don't take excuses. Kettle's on.",
           "Everything's fixable. That's not the same as free.",
           "You'll notice I never raise my voice. Consider why that works."] },
  { id:'nads', name:'Nads', age:22, role:'RUNNER', city:'London', place:'Bow carpark',
    brief:'22, sharp, amused, mid-sentence, sitting on a wall outside a block of flats',
    lines:["Yard's empty. You coming or what?",
           "I'm not standing in this rain much longer, mate.",
           "Told you the gate code was good. Say thank you."] },
  { id:'delroy', name:'Delroy', age:47, role:'CHOP SHOP', city:'London', place:'Hackney arches',
    brief:'47, overalls, hands on a bonnet, arch lit by one work lamp',
    lines:["German, after 2019. Anything else is scrap to me.",
           "Bring it in facing out. I'm not reversing your mess.",
           "I pay on the plate, not the story."] },
  { id:'shauna', name:'Shauna', age:33, role:'TELLER · BUNG', city:'London', place:'Bung, Mare St',
    brief:'33, lanyard, cashier window, strip lighting, tired half-smile',
    lines:["Anything over eight grand gets a form. Forms get read.",
           "Give it three days and it'll look like wages.",
           "Don't come in here twice in one week. Please."] },
  { id:'tobes', name:'Tobes', age:19, role:'LOOKOUT', city:'London', place:'London Fields',
    brief:'19, hood up, phone light on his face, park railings behind',
    lines:["Van went past twice. Same van.",
           "I'll whistle if it goes wrong. Don't run at me, run past me.",
           "You owe me chicken for this."] },
  { id:'hallow', name:'DC Hallow', age:43, role:'PLAIN CLOTHES', city:'London', place:'High Road',
    brief:'43, unmarked car, coffee cup, polite face that never quite settles',
    lines:["Funny. Description I've got matches you almost exactly.",
           "I've got all evening. You clearly haven't.",
           "Say nothing. That's fine. It reads a certain way, though."] },
  { id:'maz', name:'Maz', age:31, role:'TYRE YARD', city:'Manchester', place:'Ardwick yard',
    brief:'31, high-vis over a hoodie, stacked tyres, rain on the concrete',
    lines:["Bring it round the back. Front's got cameras since March.",
           "Manchester rate, not London rate. Take it or walk.",
           "You've got about nine minutes before the shift changes."] },
  { id:'pearl', name:'Aunty Pearl', age:58, role:'THE KITCHEN', city:'Manchester', place:'Claremont Rd',
    brief:'58, kitchen table, teapot, cardigan, reading a letter',
    lines:["Eat first. Nobody thinks straight hungry.",
           "I hear things in this kitchen I'd rather not repeat.",
           "If you're going to be stupid, be quiet about it."] },
  { id:'ranj', name:'Ranj', age:26, role:'LOCKUPS', city:'Birmingham', place:'Sparkbrook',
    brief:'26, puffer jacket, roller shutter half open, phone in hand',
    lines:["Unit four. Knock twice, don't shout.",
           "I've got space till Thursday, then it's someone else's.",
           "Cash on collection or it stays locked."] },
  { id:'nev', name:'Old Nev', age:66, role:'CARETAKER', city:'Birmingham', place:'Custard Factory',
    brief:'66, flat cap, keys on a belt loop, corridor of an old works building',
    lines:["I've got keys to doors nobody remembers.",
           "Been swept up after worse than you, son.",
           "Half nine, side entrance. I'll be looking the other way."] },
  { id:'bev', name:'Bev', age:39, role:'DOCKS CLERK', city:'Liverpool', place:'Container 12',
    brief:'39, clipboard, hard hat under her arm, containers behind her',
    lines:["Twelve's yours for one night. After that it's paperwork.",
           "I don't want to know what's in it. Genuinely.",
           "Anyone asks, you're my cousin and you're useless."] },
  { id:'kadeem', name:'Kadeem', age:29, role:'DRIVER', city:'Leeds', place:'Harehills',
    brief:'29, driver, one hand on the wheel, streetlight through the windscreen',
    lines:["I drive, I don't carry. Understood?",
           "Two minutes at the kerb, then I'm gone.",
           "Sit in the back and stop looking at the mirrors."] },
  { id:'marlon', name:'Marlon', age:24, role:'GROSVENOR', city:'Bristol', place:'St Pauls',
    brief:'24, leaning on a doorway, gold chain under a plain t-shirt, evening light',
    lines:["Bristol's small. Everyone knows already.",
           "You want work or you want a conversation?",
           "Don't bring London manners down here."] },
  { id:'wesley', name:'Wesley Nunn', age:51, role:'SCRAP BOSS', city:'Leeds', place:'Cross Green',
    brief:'51, weighbridge office, ledger open, magnet crane out the window',
    lines:["Weight's weight. Sentiment's free.",
           "I've bought that same van three times this year.",
           "You'll get the price I said, not the price you hoped."] }
];

window.pick = arr => arr[Math.floor(Math.random() * arr.length)];
window.pickCast = (n, filter) => {
  const pool = (filter ? window.CAST.filter(filter) : window.CAST).slice();
  const out = [];
  while (out.length < n && pool.length) out.push(pool.splice(Math.floor(Math.random() * pool.length), 1)[0]);
  return out;
};
window.PX_ID = { uncle_t:1, silas:1, nads:1, delroy:1, shauna:1, tobes:1, hallow:1, maz:1, pearl:1, ranj:1, nev:1, bev:1, kadeem:1, marlon:1, wesley:1, jerome:1 };
window.pxPortrait = c => {
  const id = (c && c.id) || String((c && c.name) || '').toLowerCase();
  return 'art/px-' + (window.PX_ID[id] ? id : 'nads') + '.png';
};
// Mugshot-style pixel portrait: square frame, nearest-neighbour, sodium ring.
window.portraitSlot = (c, size, ring) => `
  <div style="width:${size}px;height:${size}px;flex:none;border-radius:8px;border:2px solid ${ring || '#FFA94D'};
    overflow:hidden;background-color:#0C0E10;background-image:url(${pxPortrait(c)});
    background-size:cover;background-position:50% 18%;image-rendering:pixelated;"></div>`;

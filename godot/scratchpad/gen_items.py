#!/usr/bin/env python3
"""Transcribe upgrade_05/items.js -> godot/data/items.json (faithful port)."""
import json, collections

def I(n, il, st, r, src, sh, c, v=None, d="", x=None):
    row = collections.OrderedDict(n=n, il=il, st=st, r=r, src=src, sh=sh, c=c, v=v or {}, d=d)
    if x:
        row.update(x)
    return row

SLOTS = [
 {"k":"head","label":"HEAD","blurb":"The most visible slot in the game. This is where drip is read from across a room.","items":[
  I('Nothing',0,'—','Ba','—','none','charc',{},'Just your head, out in the weather.'),
  I('Faded Cap',2,'SPD','Ba','SHOP-B','cap','navy',{},"Curved brim, no logo, been through a wash it shouldn't have."),
  I('School Beanie',3,'TGH','Ba','SHOP-B','beanie','maroon',{},'Still smells faintly of a classroom.'),
  I('Ribbed Beanie',6,'SPD, SLK','De','SHOP-B','beanie','charc',{},'Pulled down to the eyebrows. Standard issue.'),
  I('Five-Panel',8,'SLK','De','SHOP-B','cap','olive',{"flat":True,"button":True},'Flat brim, sits high, says nothing about you.'),
  I('Bucket Hat',10,'SLK, LCK','De','SHOP-B','bucket','sand',{},'Half fisherman, half nuisance. Fully anonymous.'),
  I('Fur-Trim Hood',14,'TGH, SPD','Pe','SHOP-B','hood','olive',{"fur":True,"strings":True},'Zipped to the nose. Nobody sees your face and nobody asks.'),
  I('Trapper Hat',16,'TGH','Pe','SHOP-D','trapper','brown',{},'Ridiculous in April. Unbeatable in January.'),
  I('Cycling Cap',15,'SPD, LCK','Pe','CRIT','cap','white',{"button":True},'Nobody suspects a cyclist. Everybody hates a cyclist.'),
  I('Hard Hat',18,'TGH','Pe','SHOP-D','hardhat','hivis',{},"Site Kit piece. Grants entry to places doors don't.",{"set":'Site Kit'}),
  I('Beanie with the Bobble',20,'SPD, LCK','Pe','SHOP-B','beanie','red',{"bobble":True},'Softens your whole face. Weaponised harmlessness.'),
  I('Bike Helmet',22,'TGH, SPD','Pe','CRIT','helmet','lgrey',{},'Legal to wear. Legal to wear indoors, technically.'),
  I("Nurse's Cap",24,'SLK, LCK','Ce','DEEP','nursecap','white',{},"Nobody's ever asked a nurse what she's doing here."),
  I('Wide-Brim Rain Hat',26,'SLK','Ce','SHOP-D','rainhat','charc',{},'Puts your face in permanent shadow. Costs you every conversation.'),
  I('Sunday Trilby',28,'LCK','Ce','SHOP-D','trilby','brown',{},'Sunday Best piece. You look like you own something.',{"set":'Sunday Best'}),
  I('Motorcycle Lid (Tinted)',32,'TGH, SLK','Ce','DEEP','motolid','black',{},'Full face, dark visor. Illegal in most shops and every bank.'),
  I('The Grey Cap',34,'SLK','Ce','PVP','cap','grey',{},'Grey Man piece. Forgettable by design and by law of averages.',{"set":'The Grey Man'}),
  I('Balaclava Hood (Combined)',38,'SLK, TGH','Ce','DEEP','balaclava','black',{"two":True},'Two problems solved. Two more created.'),
  I('Fresh Fitted',42,'SPD, LCK','Ce','SHOP-D','cap','black',{"flat":True,"fitted":True},'Straight out the box. Somebody will comment.'),
  I("Uncle T's Old Cap",30,'TGH, LCK','Ic','STORY','cap','tan',{},'He gave it to you without saying why. Unsellable.',{"tr":'unsellable'}),
  I('The Crown',90,'all','Ic','STORY','crown','gold',{},'Level 100. Nobody wears this by accident.'),
  I('Season Cap',0,'varies','Ic','EVENT','cap','purple',{"flat":True},"Seasonal. When it's gone it's gone.")
 ]},
 {"k":"face","label":"FACE","blurb":"The trade-off slot. Everything here helps you work and hurts you socially.","items":[
  I('Nothing',0,'—','Ba','—','none','charc',{},'Your actual face. Cameras love it.'),
  I('Neck Gaiter',4,'SLK','Ba','SHOP-B','gaiter','charc',{},'Pulled up in winter. Nobody blinks.',{"tr":'mild search risk'}),
  I('Snood',7,'SLK, TGH','De','SHOP-B','gaiter','olive',{},'Half a scarf doing a full-time job.',{"tr":'mild search risk'}),
  I('Surgical Mask',9,'SLK','De','SHOP-B','mask','sky',{},"Nobody's questioned one of these since 2020."),
  I('Skull Bandana',12,'SLK','De','CRIT','gaiter','black',{"skull":True},"Says exactly what you're doing. Loudly.",{"tr":'search risk'}),
  I('Balaclava',15,'SLK ×2','Pe','SHOP-B','balaclava','black',{},'Cuts your face out of the footage. And out of everything else.',{"tr":'CCTV −60%, no drip, +search'}),
  I('Ski Mask (Two-Hole)',18,'SLK, TGH','Pe','SHOP-D','balaclava','charc',{"two":True},'Warmer. Somehow more sinister.',{"tr":'as above, +TGH'}),
  I('Dust Mask',20,'SLK','Pe','SHOP-D','mask','white',{"valve":True},"Site Kit piece. You're working. Obviously you're working.",{"set":'Site Kit'}),
  I('Scarf, Wrapped High',22,'SLK, LCK','Pe','SHOP-B','gaiter','maroon',{"scarf":True},"Deniable. It's cold, isn't it."),
  I('Motorcycle Snood',26,'SLK, SPD','Ce','DEEP','gaiter','navy',{},"Comes off in one pull. That's the feature.",{"tr":'search risk'}),
  I('Respirator',30,'SLK, TGH','Ce','SHOP-D','respirator','lgrey',{},'Absolute overkill. Absolutely effective.',{"tr":'heavy search risk'}),
  I('Grey Snood',34,'SLK ×2','Ce','PVP','gaiter','grey',{},'Grey Man piece. Nothing to describe to a sketch artist.',{"set":'The Grey Man',"tr":'reduced search risk'}),
  I('Bally, Gold Thread',45,'SLK ×2, LCK','Ic','PVP','balaclava','black',{"gold":True},'Someone put effort into a thing meant to be invisible.',{"tr":'as balaclava'}),
  I('The Clean Face',50,'LCK ×2','Ic','STORY','none','gold',{},'You stopped hiding. Somehow that works better now.',{"tr":'no concealment at all'})
 ]},
 {"k":"jacket","label":"JACKET","blurb":"The statement piece. Biggest silhouette, biggest status read.","items":[
  I('Nothing',0,'—','Ba','—','none','charc',{},"It's England. This is a mistake."),
  I('Charity Shop Fleece',1,'TGH','Ba','SHOP-B','jacket','teal',{"zip":True},"Three quid. Smells of somebody's nan."),
  I('Thin Windbreaker',3,'SPD','Ba','SHOP-B','jacket','sky',{"zip":True,"w":6},'Stops wind. Loses to rain immediately.'),
  I('Zip-Up Hoodie',5,'TGH, SPD','Ba','SHOP-B','jacket','charc',{"zip":True,"collar":'hood',"strings":True},'The uniform. Nobody looks twice.'),
  I('Tracksuit Top',8,'SPD ×2','De','SHOP-B','jacket','navy',{"zip":True,"stripes":True},'Two stripes. Built for leaving somewhere quickly.',{"set":'Full Northside'}),
  I('Denim Jacket',10,'TGH','De','SHOP-B','jacket','denim',{"buttons":True,"pockets":True,"w":6},'Stylish. Useless in February.'),
  I('Gilet',12,'TGH, SPD','De','SHOP-B','jacket','olive',{"zip":True,"sleeveless":True,"baffles":True},'Warm arms are for people with time.'),
  I('Northside Puffer',16,'TGH ×2, LCK','Pe','SHOP-B','jacket','black',{"zip":True,"baffles":True,"w":9},"Two sizes too big. That's the point.",{"set":'Full Northside'}),
  I('Long Puffer',20,'TGH ×2','Pe','SHOP-B','jacket','charc',{"zip":True,"baffles":True,"w":8,"bot":29},'Down to the knee. Fits everything. Hides everything.',{"set":'Full Northside'}),
  I('Parka with the Fur',22,'TGH, SLK','Pe','SHOP-D','jacket','olive',{"zip":True,"collar":'fur',"pockets":True,"bot":28,"w":8},"Hood up, it's a different person walking."),
  I('Wax Jacket',24,'TGH, LCK','Pe','SHOP-D','jacket','green',{"buttons":True,"pockets":True,"collar":'lapel'},'Countryside energy. Nobody stops a man in a wax jacket.',{"set":'Sunday Best'}),
  I('Hi-Vis Coat',25,'TGH','Pe','SHOP-D','jacket','hivis',{"zip":True,"hivis":True,"pockets":True},'The most powerful item in the game and it costs forty quid.',{"set":'Site Kit'}),
  I('Bomber',26,'SPD, TGH','Pe','CRIT','jacket','olive',{"zip":True,"w":7,"bot":24},'Cuffs at the wrist, nothing catches on anything.'),
  I('Grey Anorak',28,'SLK ×2','Ce','SHOP-D','jacket','grey',{"collar":'hood',"pockets":True},"You've already forgotten what it looks like.",{"set":'The Grey Man'}),
  I('Cropped Puffer',30,'SPD, LCK','Ce','SHOP-B','jacket','red',{"zip":True,"baffles":True,"w":8,"bot":22},'Shorter, faster, colder.',{"set":'Full Northside'}),
  I('Leather Jacket',32,'TGH, STR','Ce','SHOP-D','jacket','black',{"zip":True,"collar":'lapel',"pockets":True},'Takes a graze better than skin does.'),
  I('Overcoat',34,'SLK, LCK','Ce','SHOP-D','jacket','charc',{"buttons":True,"collar":'lapel',"bot":29,"w":7},'Long, dark, respectable. Doors open.',{"set":'Sunday Best'}),
  I('Technical Shell',36,'SPD, SLK','Ce','DEEP','jacket','teal',{"zip":True,"collar":'hood',"pockets":True},"Rustles. That's the one flaw and it's a real one."),
  I('Tailored Blazer',40,'LCK ×2, SLK','Ce','SHOP-D','jacket','navy',{"buttons":True,"collar":'lapel',"pockets":True,"w":6},'Nobody asks a man in a blazer for ID.',{"set":'Sunday Best'}),
  I("Site Foreman's Coat",42,'TGH, LCK','Ce','DEEP','jacket','orange',{"zip":True,"hivis":True,"collar":'hood',"pockets":True},'Clipboard sold separately. Clipboard essential.',{"set":'Site Kit'}),
  I('The Puffer',50,'TGH ×3, LCK','Ic','PVP','jacket','black',{"zip":True,"baffles":True,"w":9,"bot":28},'Everyone in the borough knows this jacket.',{"set":'Full Northside'}),
  I("Kayo's Jacket",35,'TGH ×2, LCK ×2','Ic','STORY','jacket','denim',{"buttons":True,"pockets":True},"It still fits. That's the annoying part. Unsellable.",{"tr":'unsellable'}),
  I('Prison Tracksuit Top',15,'TGH ×2','Ic','JAIL','jacket','lgrey',{"zip":True,"w":9},'Grey. Enormous. Weirdly comfortable. You kept it.',{"set":'Prison Issue'}),
  I('Winter Pressure Coat',0,'varies','Ic','EVENT','jacket','purple',{"zip":True,"baffles":True,"w":8,"bot":28},'Seasonal.')
 ]},
 {"k":"top","label":"TOP","blurb":"Under the jacket. Low visibility, so this is where pure stat items live.","items":[
  I('Vest',1,'—','Ba','SHOP-B','top','white',{"vest":True},'Optimistic.'),
  I('Plain Black Tee',2,'SPD','Ba','SHOP-B','top','black',{"crew":True},'The most useful garment ever made.'),
  I("Football Shirt (Nobody's Team)",4,'SPD, LCK','Ba','SHOP-B','top','teal',{"crew":True,"number":True},"Deliberately forgettable. That's the feature."),
  I('Long-Sleeve Base Layer',6,'TGH','De','SHOP-B','top','navy',{"crew":True},'Tight, warm, no snag points.'),
  I('Oversized Hoodie',9,'TGH, SLK','De','SHOP-B','top','charc',{"hood":True},'Swallows you whole. Ideal.'),
  I('Thermal',11,'TGH ×2','De','SHOP-B','top','cream',{"crew":True},'Rooftops in January are a different job in this.'),
  I('Rugby Top',14,'TGH, STR','Pe','SHOP-B','top','maroon',{"collar":True,"stripe":True},'Collar. Buttons. Built for being grabbed.'),
  I('Compression Top',16,'SPD ×2','Pe','SHOP-D','top','black',{"crew":True},'Everything tucked in. Nothing to hold onto.'),
  I('Plain White Shirt',18,'LCK','Pe','SHOP-B','top','white',{"collar":True},'Sunday Best piece. Instant respectability.',{"set":'Sunday Best'}),
  I('Grey Marl Sweatshirt',22,'SLK ×2','Pe','SHOP-D','top','grey',{"crew":True},'Grey Man piece. Beige for people who find beige loud.',{"set":'The Grey Man'}),
  I('Hi-Vis Tee',24,'TGH, LCK','Pe','SHOP-D','top','hivis',{"crew":True,"hivis":True},"Site Kit piece. Nobody stops a man who's obviously working.",{"set":'Site Kit'}),
  I('Merino Base',28,'TGH, SPD','Ce','SHOP-D','top','brown',{"crew":True},'Expensive, invisible, correct.'),
  I('Prison Issue Tee',12,'TGH ×2','Ce','JAIL','top','lgrey',{"crew":True},'Prison Issue piece. Washed a thousand times.',{"set":'Prison Issue'}),
  I('Body Warmer, Padded',32,'TGH ×2, SPD','Ce','DEEP','top','olive',{"vest":True,"stripe":True},'Bulk without arms. Movement without cold.'),
  I("Sess's Merch Tee",26,'LCK ×2','Ic','STORY','top','purple',{"crew":True,"number":True},'He gave you one for free. It has your name on the back. Bad idea.'),
  I('Vest (Iconic)',55,'all ×1','Ic','PVP','top','cream',{"vest":True},'Still just a vest. Now it means something.')
 ]},
 {"k":"bottoms","label":"BOTTOMS","blurb":"Speed lives here. This is the running slot.","items":[
  I('Old Jeans',1,'—','Ba','SHOP-B','bottoms','denim',{"belt":True,"pockets":True},'Stiff, loud, hopeless in a chase.'),
  I('Poly Trackies',3,'SPD','Ba','SHOP-B','bottoms','navy',{"elastic":True,"cuff":True},'Swish when you walk. Everyone hears you coming.'),
  I('Slim Joggers',6,'SPD ×2','De','SHOP-B','bottoms','charc',{"elastic":True,"cuff":True},'Cuffed at the ankle. Nothing to catch on a fence.',{"set":'Full Northside'}),
  I('Combat Trousers',9,'TGH, SLK','De','SHOP-B','bottoms','olive',{"pockets":True,"belt":True},'Nine pockets. You will lose things in all nine.'),
  I('Faded Jeans',10,'LCK','De','SHOP-B','bottoms','sky',{"belt":True,"pockets":True},'Comfortable. Slow. Honest about it.'),
  I('Tech Cargos',14,'SPD, SLK','Pe','SHOP-B','bottoms','black',{"pockets":True,"cuff":True},"Zips that seal. Pockets that don't spill on a run.",{"set":'Full Northside'}),
  I('Work Trousers',16,'TGH','Pe','SHOP-D','bottoms','sand',{"pockets":True,"belt":True},"Knee pads built in. You'll be grateful once.",{"set":'Site Kit'}),
  I('Running Tights',18,'SPD ×2, LCK','Pe','SHOP-D','bottoms','black',{"elastic":True},'Fast. Deeply undignified.'),
  I('Grey Chinos',20,'SLK ×2','Pe','SHOP-D','bottoms','grey',{"belt":True,"crease":True},'Trousers so forgettable they’re almost an alibi.',{"set":'The Grey Man'}),
  I('Waterproof Overtrousers',22,'TGH, SPD','Pe','CRIT','bottoms','teal',{"elastic":True,"cuff":True},'Rustle badly. Keep you moving in weather that stops others.'),
  I('Suit Trousers',24,'LCK, SLK','Ce','SHOP-D','bottoms','charc',{"belt":True,"crease":True},'Creased sharp. Nobody questions a crease.',{"set":'Sunday Best'}),
  I('Padded Motorcycle Jeans',28,'TGH ×2','Ce','SHOP-D','bottoms','denim',{"belt":True,"pockets":True,"bands":True},'Made for coming off a bike. Which you will.'),
  I('Prison Bottoms',12,'TGH ×2','Ce','JAIL','bottoms','lgrey',{"elastic":True},'Elastic waist. No belt allowed. You know why.',{"set":'Prison Issue'}),
  I('Cargo Shorts',26,'SPD, LCK','Ce','SHOP-B','bottoms','sand',{"pockets":True,"belt":True,"short":True},"Four days a year these are correct. Those days you're unstoppable."),
  I('Reinforced Trackies',32,'SPD ×2, TGH','Ce','DEEP','bottoms','black',{"elastic":True,"cuff":True,"crease":True},'Double-stitched everywhere that usually goes.',{"set":'Full Northside'}),
  I('Site Trousers, Hi-Vis Bands',34,'TGH, LCK','Ce','DEEP','bottoms','hivis',{"pockets":True,"belt":True,"bands":True},'You are so clearly meant to be here.',{"set":'Site Kit'}),
  I('The Trackies',48,'SPD ×3','Ic','PVP','bottoms','black',{"elastic":True,"cuff":True,"crease":True},"Nobody outruns you in these. That's not a stat. That's a fact.",{"set":'Full Northside'}),
  I('Season Bottoms',0,'varies','Ic','EVENT','bottoms','purple',{"elastic":True,"cuff":True},'Seasonal.')
 ]},
 {"k":"feet","label":"FEET","blurb":"The status slot. In UK street culture, trainers say more than anything else you own.","items":[
  I('Bare Feet',0,'—','Ba','—','none','charc',{},'Something has gone very wrong.'),
  I('Charity Shop Trainers',1,'—','Ba','SHOP-B','shoe','grey',{"laces":True},'Someone else broke these in. Badly.'),
  I('Canvas Plimsolls',3,'SPD','Ba','SHOP-B','shoe','black',{"soleY":23,"soleH":2},'No grip, no support, no weight either.',{"set":'Prison Issue'}),
  I('Battered Classics',5,'SPD','Ba','SHOP-B','shoe','white',{"laces":True,"swoosh":True},'Held together by habit.'),
  I('Mesh Runners',8,'SPD ×2','De','SHOP-B','shoe','sky',{"laces":True,"swoosh":True},'Light. Fast. Ruined by one puddle.'),
  I('Skate Shoes',10,'SPD, TGH','De','SHOP-B','shoe','black',{"laces":True,"soleY":23,"soleH":3},'Flat, wide, grip like glue on a wall.'),
  I('Triple-Sole Trainers',14,'SPD, LCK','Pe','SHOP-B','shoe','white',{"laces":True,"soleY":20,"soleH":6},'Chunky. Loud. Correct.',{"set":'Full Northside'}),
  I('Work Boots',16,'TGH ×2','Pe','SHOP-D','shoe','tan',{"boot":True,"laces":True,"steel":True,"soleC":'#23262A',"soleHi":'#383C41'},'Steel toe. Doors mind them.',{"set":'Site Kit'}),
  I('Trail Runners',18,'SPD ×2, TGH','Pe','SHOP-D','shoe','orange',{"laces":True,"swoosh":True,"soleC":'#33383D',"soleHi":'#4A5057'},'Made for hills. Excellent on scaffolding.'),
  I('Grey Trainers',20,'SLK ×2','Pe','SHOP-D','shoe','grey',{"laces":True},'Genuinely indescribable footwear.',{"set":'The Grey Man'}),
  I('Leather Brogues',22,'LCK ×2','Pe','SHOP-D','shoe','brown',{"brogue":True,"soleC":'#5A3A22',"soleHi":'#7A5233',"soleY":24,"soleH":2},'Click on pavement. Announce respectability.',{"set":'Sunday Best'}),
  I('Fresh Whites',24,'SPD, LCK ×2','Ce','SHOP-B','shoe','white',{"laces":True,"soleY":21,"soleH":5},'Ruined the moment it rains. Worth it.',{"set":'Full Northside'}),
  I('Chelsea Boots',26,'LCK, SLK','Ce','SHOP-D','shoe','black',{"boot":True,"strap":True,"soleC":'#23262A',"soleHi":'#383C41',"soleY":24,"soleH":2},'On and off in one motion. Underrated.',{"set":'Sunday Best'}),
  I('Motorcycle Boots',30,'TGH ×2, SPD','Ce','SHOP-D','shoe','black',{"boot":True,"strap":True,"soleC":'#33383D',"soleHi":'#4A5057'},"Ankle armour. You'll notice the day you need it."),
  I('Rigger Boots',32,'TGH ×2','Ce','DEEP','shoe','tan',{"boot":True,"strap":True,"steel":True,"soleC":'#23262A',"soleHi":'#383C41'},'Pull-on. No laces to fail at the worst moment.',{"set":'Site Kit'}),
  I('Silent Soles',36,'SLK ×2, SPD','Ce','DEEP','shoe','charc',{"laces":True,"soleC":'#23262A',"soleHi":'#33383D'},'Rubber, soft, dead quiet on stairs.'),
  I('Court Classics, Boxed',40,'SPD, LCK ×2','Ce','SHOP-D','shoe','cream',{"laces":True,"swoosh":True},'Never worn. Someone kept them fifteen years.'),
  I('The Ones',52,'SPD ×2, LCK ×2','Ic','PVP','shoe','white',{"laces":True,"swoosh":True,"soleY":20,"soleH":6},"Everyone clocks them. That's the whole item.",{"set":'Full Northside'}),
  I("Kayo's Trainers",20,'SPD ×2, LCK','Ic','STORY','shoe','red',{"laces":True},'Half a size too big. You wear them anyway. Unsellable.',{"tr":'unsellable'}),
  I('Golden Sole',88,'all','Ic','EVENT','shoe','gold',{"laces":True,"soleC":'#C9A227',"soleHi":'#E4C154',"soleY":21,"soleH":5},'Season leaderboard reward. One per city per season.')
 ]},
 {"k":"hands","label":"HANDS","blurb":"Small stats, big utility. Half of these are tools that pretend to be clothing.","items":[
  I('Nothing',0,'—','Ba','—','none','charc',{},'Every surface remembers you.',{"tr":'prints everywhere'}),
  I('Nitriles (Box of 100)',2,'SLK','Ba','SHOP-B','box','sky',{"label":True,"tab":True},"Ninety-eight left. Don't think about the two."),
  I('Woolly Gloves',4,'TGH','Ba','SHOP-B','glove','maroon',{},'Warm. Useless for anything requiring fingers.'),
  I('Fingerless Mitts',6,'SLK, SPD','De','SHOP-B','glove','charc',{"fingerless":True},'Warmth and dexterity, at 60% of each.'),
  I('Leather Gloves',9,'SLK ×2','De','SHOP-B','glove','brown',{"thin":True},'No prints, steadier grip. Every job a touch cleaner.'),
  I('Work Gloves',12,'TGH, STR','De','SHOP-D','glove','tan',{"strap":True},'Site Kit piece. Grip like a vice.',{"set":'Site Kit'}),
  I('Driving Gloves',15,'SPD, SLK','Pe','SHOP-D','glove','black',{"fingerless":True,"thin":True},'Wheel never slips. You look like a lunatic on foot.'),
  I('Knuckle Duster',18,'STR ×2','Pe','SHOP-D','duster','steel',{},"Fits in a pocket. Doesn't fit any explanation.",{"tr":'offensive weapon charge'}),
  I('Tactical Gloves',22,'SLK, TGH','Pe','DEEP','glove','black',{"knuck":True,"strap":True},'Padded knuckles. Deniable. Just about.'),
  I('Latex, Double-Gloved',24,'SLK ×2, LCK','Ce','DEEP','glove','sky',{"thin":True},'Twice as careful. Half as comfortable.'),
  I('Weighted Gloves',28,'STR ×2, TGH','Ce','SHOP-D','glove','charc',{"knuck":True,"strap":True},'Sand in the knuckles. Technically sportswear.',{"tr":'search risk'}),
  I('Grey Gloves',30,'SLK ×2','Ce','PVP','glove','grey',{"thin":True},'Grey Man piece. Hands nobody could describe.',{"set":'The Grey Man'}),
  I('Wedding Ring (Not Yours)',26,'LCK ×2','Ce','CRIT','ring','gold',{},"Someone's initials inside. You don't look at them often."),
  I('The Duster',46,'STR ×3','Ic','PVP','duster','gold',{},'Brass. Old. Someone else’s history in your pocket.',{"tr":'jail time +50%'})
 ]},
 {"k":"weapon","label":"WEAPON","blurb":"Every step up in damage is a step up in what happens when you are stopped. The best weapon in the game should be a decision the player regrets at least once.","items":[
  I('Empty Hands',0,'—','Ba','—','none','charc',{},'Free. Legal. Occasionally sufficient.'),
  I('Bottle (Empty)',2,'STR','Ba','SHOP-B','bottle','green',{},"It was already there. That's the whole appeal.",{"tr":'breaks after one fight'}),
  I('Rolled Magazine',3,'STR','Ba','SHOP-B','magazine','paper',{},"Sounds ridiculous. Isn't."),
  I('Torch (Heavy)',5,'STR, LCK','Ba','SHOP-B','torch','black',{},"It's a torch. It's genuinely a torch. Mostly."),
  I('Screwdriver',7,'STR, SLK','De','SHOP-B','screwdriver','red',{},'A tool. Say tool. Keep saying tool.',{"tr":'mild charge'}),
  I('Bat',9,'STR ×2','De','SHOP-B','bat','wood',{},'There’s a ball in the boot. There is always a ball in the boot.',{"tr":'charge if no bag'}),
  I('Scaffold Pole',12,'STR ×2, TGH','De','SHOP-D','pole','steel',{},'Site Kit adjacent. Free at any site. Impossible to hide.',{"tr":'conspicuous'}),
  I('Pepper Spray',14,'SLK','Pe','SHOP-D','spray','red',{"nozzle":True},'Technically for dogs. Legally for dogs. Used for dogs once.',{"tr":'illegal in UK — real charge'}),
  I('Extendable Baton',16,'STR ×2, SPD','Pe','SHOP-D','baton','black',{"grip":True},"Pocket-sized until it very much isn't.",{"tr":'charge'}),
  I('Shank',18,'STR ×2','Pe','SHOP-D','blade','charc',{"len":13,"w":2},"Persuasion, sharpened. Marks don't argue.",{"tr":'serious charge, jail ×1.5'}),
  I('Lock Knife',20,'STR, SLK','Pe','DEEP','blade','wood',{"len":11,"w":3,"fold":True},"Folds away. The law doesn't care that it folds away.",{"tr":'serious charge'}),
  I('Machete (Garden)',26,'STR ×3','Ce','DEEP','machete','black',{},"Someone's going to ask about the garden. There is no garden.",{"tr":'jail ×2, heavy search flag'}),
  I('Rambo',30,'STR ×3, TGH','Ce','SHOP-D','blade','black',{"len":18,"w":4,"guard":True,"serr":True},'Big blade, bigger sentence.',{"tr":'jail ×2'}),
  I('Sawn-Off',45,'STR ×4','Ic','STORY','sawnoff','wood',{},'A statement, not a sidearm. Using it changes the game.',{"tr":'endgame only, instant heat 10, district event'}),
  I("Delroy's Wrench",24,'STR ×2, LCK ×2','Ic','STORY','wrench','steel',{},'"Bring it back. I mean it. That’s a good wrench." Unsellable.',{"tr":"none — it's a tool"}),
  I('The Bat, Signed',50,'STR ×3, LCK','Ic','PVP','bat','wood',{"signed":True},'Someone wrote a name on it. Not yours.',{"tr":'charge'})
 ]},
 {"k":"body","label":"BODY","blurb":"Toughness slot. Also the \"blocks set bonuses\" trade-off slot.","items":[
  I('Nothing',0,'—','Ba','—','none','charc',{},'Just fabric between you and everything.'),
  I('Padded Gilet',6,'TGH','De','SHOP-B','vestArmour','olive',{"pouch":True},'A bit of bulk. A bit of warmth. A bit of help.'),
  I('Chest Rig',12,'TGH, SLK','De','SHOP-D','vestArmour','charc',{"molle":True,"pouch":True,"straps":True},'Pouches for everything. Looks like exactly what it is.',{"tr":'conspicuous'}),
  I("Builder's Harness",16,'TGH, STR','Pe','SHOP-D','harness','hivis',{},'Site Kit piece. Also genuinely stops you falling.',{"set":'Site Kit'}),
  I('Stab Vest',20,'TGH ×3','Pe','SHOP-D','vestArmour','black',{"plate":True,"straps":True},'Ugly with everything. You walk away from more.',{"tr":'blocks all set bonuses'}),
  I('Motorcycle Armour',24,'TGH ×2, SPD','Pe','SHOP-D','vestArmour','dsteel',{"plate":True,"molle":True},'Built for tarmac at speed. Handy for other things.'),
  I('Money Belt',18,'SLK, LCK','Pe','SHOP-B','vestArmour','brown',{"belt":True},'Halves what an ambush takes off you. Deeply uncool.'),
  I('Covert Vest',30,'TGH ×3, SLK','Ce','DEEP','vestArmour','cream',{"plate":True},'Under a shirt, invisible. Costs what a car costs.'),
  I('Weighted Training Vest',26,'STR ×2, TGH','Ce','SHOP-D','vestArmour','red',{"pouch":True,"straps":True},'Train in it, fight in it, regret it on a chase.',{"tr":'−SPD while worn'}),
  I('Grey Gilet',32,'SLK ×2, TGH','Ce','PVP','vestArmour','grey',{"pouch":True},'Grey Man piece. A shape, not a person.',{"set":'The Grey Man'}),
  I('Prison Issue Vest',14,'TGH ×2','Ce','JAIL','vestArmour','lgrey',{},'Prison Issue piece. Institutional and indestructible.',{"set":'Prison Issue'}),
  I('The Plate',60,'TGH ×4','Ic','PVP','vestArmour','black',{"plate":True,"molle":True,"straps":True},'Overkill. Beautiful, heavy, ridiculous overkill.',{"tr":'blocks sets'})
 ]},
 {"k":"bag","label":"BAG","blurb":"Carry capacity, inventory slots, and the \"you look like you are carrying\" trade-off.","items":[
  I('Pockets',0,'—','Ba','—','none','charc',{},'Four pockets and optimism.',{"slots":'+0'}),
  I('Bin Bag',1,'LCK','Ba','SHOP-B','binbag','black',{},'Holds everything. Convinces nobody.',{"slots":'+2'}),
  I('Carrier Bag',2,'SLK','Ba','SHOP-B','carrier','white',{},'The most invisible object in Britain.',{"slots":'+1'}),
  I('School Rucksack',5,'TGH','Ba','SHOP-B','bag','navy',{"straps":True,"zip":True,"pockets":True},"Someone's name in marker inside. Not yours.",{"slots":'+3'}),
  I('Crossbody',8,'SPD, SLK','De','SHOP-B','bag','charc',{"cross":True,"flap":True,"top":14},"Sits tight. Doesn't swing when you run.",{"slots":'+2'}),
  I('Sports Holdall',12,'TGH','De','SHOP-B','bag','navy',{"handle":True,"zip":True,"long":True,"top":14},'Big. Obvious. Everyone knows what a holdall means.',{"slots":'+5',"tr":'+8% ambush chance'}),
  I('Toolbag',15,'TGH, LCK','Pe','SHOP-D','bag','tan',{"handle":True,"pockets":True,"top":14},'Site Kit piece. Rattles convincingly.',{"set":'Site Kit',"slots":'+4'}),
  I('Backpack, Technical',18,'SPD, TGH','Pe','SHOP-D','bag','olive',{"straps":True,"zip":True,"pockets":True},'Straps that don’t shift. Everything stays where it was.',{"slots":'+5'}),
  I('Laptop Bag',20,'SLK, LCK','Pe','SHOP-B','bag','brown',{"flap":True,"cross":True,"top":14},"Sunday Best piece. You're a professional, obviously.",{"set":'Sunday Best',"slots":'+3'}),
  I('Grey Rucksack',24,'SLK ×2','Ce','PVP','bag','grey',{"straps":True,"zip":True},'Grey Man piece. Nobody has ever described this bag.',{"set":'The Grey Man',"slots":'+4'}),
  I('Duffel',28,'TGH ×2, LCK','Ce','DEEP','bag','charc',{"handle":True,"zip":True,"long":True,"top":13},'The reveal-ceremony bag. Now you own one.',{"slots":'+7',"tr":'+12% ambush chance'}),
  I('Courier Bag',30,'SPD ×2, SLK','Ce','DEEP','bag','teal',{"cross":True,"flap":True,"top":13},"You're delivering something. You're always delivering something.",{"slots":'+5'}),
  I("Kayo's Holdall",22,'TGH, LCK ×2','Ic','STORY','bag','red',{"handle":True,"zip":True,"long":True,"top":14},'Still has a receipt in the side pocket from March. Unsellable.',{"slots":'+6',"tr":'unsellable'}),
  I('The Bag',55,'all, LCK ×2','Ic','PVP','bag','black',{"handle":True,"zip":True,"long":True,"pockets":True,"top":13},'Everything fits. Everything always fits.',{"slots":'+9'})
 ]},
 {"k":"phone","label":"PHONE","blurb":"Non-gear utility slot. Gates line features rather than giving combat stats.","items":[
  I('Cracked Android',1,'—','Ba','start','phone','charc',{"cracked":True},'Screen like a windscreen. Works. Mostly.'),
  I('Burner Phone',6,'—','De','SHOP-B','phone','black',{"keys":True,"antenna":True},'Clean line, no trace. Sets up the lines to come.',{"tr":'Unlocks 1 line'}),
  I('Second Burner',12,'—','De','SHOP-B','phone','navy',{"keys":True,"antenna":True},'One for the work, one for the other work.',{"tr":'Unlocks 2nd line'}),
  I('Prepaid Bundle',16,'—','Pe','SHOP-B','sim','orange',{},'Enough minutes to run a small county.',{"tr":'+20% line yield'}),
  I('Encrypted Handset',24,'—','Pe','SHOP-D','phone','black',{"screen":'#1B2A24'},'Costs a fortune. Worth every penny once.',{"tr":'−30% police intel gain'}),
  I('Dual-Sim Flagship',30,'—','Ce','SHOP-D','phone','dsteel',{"dual":True},"The one you'd never nick from someone else.",{"tr":'+1 line, +10% yield'}),
  I("Kayo's Old Nokia",10,'—','Ic','STORY','phone','teal',{"keys":True,"antenna":True},'Battery lasts a week. Contacts list is a problem. Unsellable.',{"tr":'+1 prison call minute/week'}),
  I('The Line',60,'—','Ic','STORY','sim','gold',{},'Not a phone. A number. Everyone already knows it.',{"tr":'+2 lines, +25% yield'})
 ]},
 {"k":"cons","label":"CONSUMABLES","blurb":"Single-use. The tactical layer. Bought cheap, used at the right moment.","items":[
  I('Energy Drink',0,'+15 HP mid-fight','Ba','SHOP-B','can','hivis',{"tab":True},"Tastes like a fruit that doesn't exist.",{"price":'£4'}),
  I('Meal Deal',0,'+10 Energy','Ba','SHOP-B','packet','sky',{"food":True},"Sandwich, crisps, drink. The nation's fuel.",{"price":'£4'}),
  I('Chicken & Chips',0,'+15 Energy','Ba','SHOP-B','box','red',{"label":True},'Small box. Restores more than it should.',{"price":'£6'}),
  I('Painkillers',0,'−30% hospital time','Ba','SHOP-B','packet','white',{"pills":True},'Over the counter. Under the tongue.',{"price":'£8'}),
  I('Coffee, Petrol Station',0,'+5 Energy, +5% SPD 1h','Ba','SHOP-B','cup','brown',{},'Terrible. Effective. Both true.',{"price":'£3'}),
  I('Bolt Cutters',0,'Unlocks locked stages','De','SHOP-D','tool','steel',{},'Bulky. Conspicuous. Occasionally the whole job.',{"price":'£120'}),
  I('Crowbar',0,'+15% forced entry','De','SHOP-D','crowbar','red',{},'Aggravates any charge. Opens any door.',{"price":'£45'}),
  I('Lock Pick Set',0,'+20% SLK on locks','De','SHOP-D','picks','black',{},'Requires patience you may not have.',{"price":'£180'}),
  I('Meat (For The Dog)',0,'Bypasses dog defences','De','SHOP-B','packet','cream',{"meat":True},'Cheapest counter to the scariest thing in the game.',{"price":'£5'}),
  I('Burner SIM',0,'Resets police intel','De','SHOP-B','sim','sky',{},'New number, new man, same problems.',{"price":'£25'}),
  I('Spray Can',0,'Tag territory, +rep','De','SHOP-B','spray','purple',{"cap":True,"nozzle":True},'Your name on a wall. Somebody will paint over it.',{"price":'£12'}),
  I('Pepper Spray',0,'Skips one enemy round','Pe','SHOP-D','spray','red',{"nozzle":True},'Single use. Ends most conversations.',{"price":'£30'}),
  I('Fake ID',0,'One stop-and-search escape','Pe','SHOP-D','card','sky',{"photo":True,"chip":True},'Good enough for a bouncer. Not for a custody sergeant.',{"price":'£400'}),
  I('Angle Grinder',0,'Unlocks stage 5 on some jobs','Pe','SHOP-D','grinder','orange',{},'Loud enough to wake a street. Fast enough to matter.',{"price":'£350'}),
  I('Camera Jammer',0,'−80% CCTV, 10 min','Ce','SHOP-D','jammer','charc',{},'Illegal to own, sell, or explain.',{"price":'£600'}),
  I("Solicitor's Card",0,'−50% jail time, one use','Ce','SHOP-D','card','cream',{},"Frankie's number. He'll bill you for the card.",{"price":'£900'}),
  I('Bottle of Something Decent',0,'+20 relationship','Pe','SHOP-B','spirits','maroon',{},'Works on everyone except Silas, who says thank you and doesn’t drink it.',{"price":'£60'}),
  I('Clean Phone Drop',0,'Cancels one ambush','Ce','DEEP','phone','grey',{"keys":True},'Somebody owes somebody. Tonight it’s for you.',{"price":'£250'})
 ]},
 {"k":"trophy","label":"TROPHIES","blurb":"No slot, no stats, cannot be sold. They exist to be looked at.","items":[
  I('The Engraved Watch',0,'—','Ic','Act II','watch','steel',{},'Initials and a date in 1994. Worth two hundred. You can’t sell it and you’ve stopped trying.'),
  I("Rico's First Wage Packet",0,'—','Ic','Given back','envelope','sand',{"sealed":True},"He said he didn't need it yet. It's still sealed."),
  I('Belmarsh Visiting Order',0,'—','Ic','Prologue','envelope','paper',{"window":True},'Your name, printed by a machine. A number underneath it.'),
  I("Uncle T's Note",0,'—','Ic','If you lose him','note','charc',{},'Four words on the back of a receipt. You’ve read it a lot.'),
  I('Photo of a Dog',0,'—','Ic','Pickpocket crit','photo','sky',{},'Someone’s wallet. You kept the photo and left the rest on a bus.'),
  I('Green Lane Bandana',0,'—','Ic','Act III','bandana','green',{},'Taken, or given. The game remembers which.'),
  I("Silas's Fountain Pen",0,'—','Ic','Act IV','pen','black',{},'It’s a nice pen. It writes very well. You hate it.'),
  I("The Boiler Man's Second Phone",0,'—','Ic','Echo chain','phone','charc',{"keys":True},'He got a new one. You took that one too. He never found out.'),
  I("Mum's Spare Key",0,'—','Ic','20 answered calls','key','steel',{},'You’ve always had one. She gave you another anyway.'),
  I('Season Trophy',0,'—','Ic','Top 100','trophy','gold',{},'Season 1. It says so on the base.'),
  I('The Ledger',0,'—','Ic','Top Boy ending','ledger','brown',{},'Every name. Every number. Yours now.')
 ]}
]

SETS = [
 {"n":'Full Northside',"tag":'street status — the flex build',"c":'#4DA3FF',"b3":'+8% snatch/street payouts',"b5":'+15% payouts, "clocked" aura in Neon Row, NPCs greet you by name'},
 {"n":'The Grey Man',"tag":'the stealth build — deliberately boring on purpose',"c":'#9AA0A6',"b3":'−15% heat gain',"b5":'−30% heat gain, CCTV ID halved, witnesses can’t describe you'},
 {"n":'Sunday Best',"tag":'the legitimacy build — opens doors instead of forcing them',"c":'#C9A227',"b3":'+20% clean-money prices',"b5":'NPCs treat you as legitimate — new dialogue, halved stop-and-search'},
 {"n":'Site Kit',"tag":'dress as a builder, walk in the front',"c":'#D9E021',"b3":'walk into industrial areas unquestioned',"b5":'+25% success on industrial jobs, daylight jobs raise no heat'},
 {"n":'Prison Issue',"tag":'earned, not bought — only from the jail branch',"c":'#B06CF0',"b3":'+10% Toughness',"b5":'+20% Toughness, cellmates always talk, jail time −25%'}
]

RARITY = {"Ba":'BASIC',"De":'DECENT',"Pe":'PENG',"Ce":'CERTI',"Ic":'ICONIC'}
SOURCE = {"SHOP-B":"Bossman's","SHOP-D":"Delroy's back room","CRIT":'Job crit drop',"DEEP":'Push-your-luck stage 4–5',"PVP":'Arena win',"STORY":'Story reward',"FENCE":'Player resale',"JAIL":'Prison branch',"EVENT":'Seasonal'}

# assign a stable id per item: slot_key + index
for s in SLOTS:
    for i, it in enumerate(s["items"]):
        it["id"] = "%s_%d" % (s["k"], i)
        it["slot"] = s["k"]

out = collections.OrderedDict(slots=SLOTS, sets=SETS, rarity=RARITY, source=SOURCE)
total = sum(len(s["items"]) for s in SLOTS)
with open("data/items.json", "w") as f:
    json.dump(out, f, ensure_ascii=False, indent=1)
print("wrote data/items.json:", total, "items,", len(SLOTS), "slots,", len(SETS), "sets")

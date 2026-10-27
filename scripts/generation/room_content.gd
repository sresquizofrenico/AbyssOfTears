class_name RoomContent
extends RefCounted

static func prepare(layout: FloorLayout, owned: Dictionary={}) -> void:
 var room: Dictionary=layout.rooms[layout.current]
 if not layout.expanded or room.get("prepared",false): return
 room.prepared=true
 if not room.has("pickups"): room.pickups=[]
 room.props=[]
 var rng:=RandomNumberGenerator.new()
 rng.seed=layout.seed_value+layout.floor_index*1000+layout.current*71
 if room.kind=="start":
  room.pickups.append({"id":"crystal","position":Vector2(480,300),"reward_kind":"key","chest":false,"collected":false})
 elif room.kind=="shop":
  var ids: Array[String]=[]
  for attempt in range(28):
   if ids.size()==2: break
   var id:=RelicCatalog.roll(rng,layout.floor_index,"shop")
   if not ids.has(id) and int(owned.get(id,0))<int(RelicCatalog.definition(id).max_stack): ids.append(id)
  for definition: Dictionary in RelicCatalog.DATA:
   if ids.size()==2: break
   if not ids.has(definition.id) and int(owned.get(definition.id,0))<int(definition.max_stack): ids.append(definition.id)
  for i in range(ids.size()):
   room.pickups.append({"id":ids[i],"position":Vector2(360+i*120,274),"price":Economy.item_price(ids[i],layout.floor_index,rng),"collected":false,"chest":false})
  room.pickups.append({"id":"crystal","position":Vector2(600,274),"reward_kind":"key","price":int(Economy.config().key_price),"collected":false,"chest":false})
 elif room.kind=="special":
  room.props=[{"kind":"switch","position":Vector2(360,274),"used":false},{"kind":"fountain","position":Vector2(600,274),"used":false}]
 elif room.kind=="secret":
  room.pickups.append({"id":RelicCatalog.roll(rng,layout.floor_index,"secret"),"position":Vector2(480,274),"chest":true,"collected":false})
 elif room.kind in ["combat","descent"]:
  room.props.append({"kind":"barrel","position":Vector2(200,274),"health":2.0,"used":false,"drop_key":false,"drop_type":Economy.weighted_index(rng,Economy.config().barrel_weights),"coin_amount":Economy.coin_value(rng)})
  if layout.floor_index>0 and layout.current%2==0:
   room.props.append({"kind":"trap","position":Vector2(480,200)})
  if room.kind=="combat" and layout.current%3==2:
   room.pickups.append({"id":RelicCatalog.roll(rng,layout.floor_index,"chest"),"position":Vector2(760,274),"chest":true,"locked":true,"collected":false})

class_name RoomContent
extends RefCounted

static func prepare(layout: FloorLayout) -> void:
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
   var id:=RelicCatalog.roll(rng,layout.floor_index)
   if not ids.has(id): ids.append(id)
  for definition: Dictionary in RelicCatalog.DATA:
   if ids.size()==2: break
   if not ids.has(definition.id): ids.append(definition.id)
  for i in range(2):
   room.pickups.append({"id":ids[i],"position":Vector2(360+i*120,274),"price":6+int(RelicCatalog.definition(ids[i]).rarity)*3,"collected":false,"chest":false})
  room.pickups.append({"id":"crystal","position":Vector2(600,274),"reward_kind":"key","price":4,"collected":false,"chest":false})
 elif room.kind=="special":
  room.props=[{"kind":"switch","position":Vector2(360,274),"used":false},{"kind":"fountain","position":Vector2(600,274),"used":false}]
 elif room.kind=="secret":
  var rare: Array[String]=[]
  for definition: Dictionary in RelicCatalog.DATA:
   if int(definition.rarity)>=3: rare.append(definition.id)
  room.pickups.append({"id":rare[rng.randi_range(0,rare.size()-1)],"position":Vector2(480,274),"chest":true,"collected":false})
 elif room.kind in ["combat","descent"]:
  room.props.append({"kind":"barrel","position":Vector2(200,274),"health":2.0,"used":false,"drop_key":rng.randf()<0.35})
  if layout.floor_index>0 and layout.current%2==0:
   room.props.append({"kind":"trap","position":Vector2(480,200)})
  if room.kind=="combat" and layout.current%3==2:
   room.pickups.append({"id":RelicCatalog.roll(rng,layout.floor_index),"position":Vector2(760,274),"chest":true,"locked":true,"collected":false})

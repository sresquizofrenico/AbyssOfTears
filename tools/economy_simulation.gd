extends RefCounted

static func receive(data: Dictionary, state: Dictionary) -> void:
 if data.get("locked",false):
  if state.keys<=0: return
  state.keys-=1
 var kind: String=data.get("reward_kind","relic")
 if kind=="coins": state.coins+=Economy.amount(data)
 elif kind=="key": state.keys=mini(99,state.keys+1)
 elif kind=="relic":
  if not state.inventory.add(data.id,state.stats): state.coins+=int(Economy.config().duplicate_compensation)

static func run(runs: int=2000, policy: String="greedy") -> Array[Dictionary]:
 var rows: Array[Dictionary]=[]
 for floor_index in range(3): rows.append({"floor":floor_index+1,"gross":0.0,"before_shop":0.0,"after_shop":0.0,"purchases":0.0,"prices":0.0,"offers":0,"both_affordable":0.0,"rare_offers":0.0,"legendary_rewards":0,"relic_rewards":0})
 for attempt in range(runs):
  var seed_value:=attempt*73+17
  var state: Dictionary={"coins":0,"keys":0,"inventory":RelicInventory.new(),"stats":ActorStats.new()}
  var deaths:=RandomNumberGenerator.new()
  deaths.seed=seed_value+45271
  for floor_index in range(3):
   var before_floor: int=state.coins
   var layout:=FloorLayout.new()
   layout.generate(seed_value,floor_index,true)
   var stock: Array=[]
   for room_id in range(layout.rooms.size()):
    layout.current=room_id
    var room: Dictionary=layout.rooms[room_id]
    if room.kind=="secret":
     if state.keys<=0: continue
     state.keys-=1
    RoomContent.prepare(layout,state.inventory.owned)
    if room.kind=="shop": stock=room.pickups; continue
    if room.kind in ["combat","descent"]:
     var rng:=RandomNumberGenerator.new()
     rng.seed=seed_value+floor_index*1000+room_id*71
     for i in range(3+floor_index+(1 if room.kind=="descent" else 0)):
      var amount:=Economy.enemy_coin(deaths,rng.randi_range(0,[7,13,19][floor_index]))
      state.coins+=amount
     for prop: Dictionary in room.props:
      if prop.kind!="barrel": continue
      if int(prop.drop_type)==1: state.coins+=int(prop.coin_amount)
      elif int(prop.drop_type)==2: state.keys+=1
    var reward_rng:=RandomNumberGenerator.new()
    reward_rng.seed=seed_value+floor_index*101+room_id
    var rewards: Array=room.get("pickups",[]).duplicate(true)
    rewards.append_array(Economy.room_rewards(reward_rng,floor_index,room.kind))
    for data: Dictionary in rewards:
     if data.get("reward_kind","relic")=="relic":
      rows[floor_index].relic_rewards+=1
      if int(RelicCatalog.definition(data.id).rarity)==4: rows[floor_index].legendary_rewards+=1
     receive(data,state)
   var row: Dictionary=rows[floor_index]
   row.gross+=state.coins-before_floor
   row.before_shop+=state.coins
   var available: Array=[]
   var sum:=0
   var has_rare:=false
   for data: Dictionary in stock:
    if data.get("reward_kind","relic")!="relic": continue
    if int(state.inventory.owned.get(data.id,0))>=int(RelicCatalog.definition(data.id).max_stack): continue
    available.append(data)
    sum+=int(data.price)
    row.prices+=int(data.price)
    row.offers+=1
    if int(RelicCatalog.definition(data.id).rarity)>=2: has_rare=true
   if available.size()==2 and state.coins>=sum: row.both_affordable+=1
   if has_rare: row.rare_offers+=1
   available.sort_custom(func(a: Dictionary,b: Dictionary): return int(a.price)<int(b.price))
   for data: Dictionary in available:
    if policy=="save_for_rare" and int(RelicCatalog.definition(data.id).rarity)<2: continue
    if state.coins<int(data.price): continue
    state.coins-=int(data.price)
    receive(data,state)
    row.purchases+=1
    if policy=="save_for_rare": break
   row.after_shop+=state.coins
 for row: Dictionary in rows:
  row.price_mean=row.prices/maxi(1,int(row.offers))
  for key in ["gross","before_shop","after_shop","purchases","both_affordable","rare_offers"]: row[key]/=runs
  row.policy=policy
  row.runs=runs
 return rows

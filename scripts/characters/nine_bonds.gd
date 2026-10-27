class_name NineBonds
extends RefCounted
static func fresh() -> Dictionary:
 return {"bond_timer":0.0,"bond_dash":0.0,"beam_pending":false,"counter_pending":false,"blocked":0.0,"bond_shield":0.0,"family_ward":0.0,"near_ids":{},"evades":0,"precision_charge":false,"observed":{},"observation_time":{},"resist_type":"","resist_time":0.0,"trail_time":0.0,"low_guard":false,"field_budget":0.0,"field_pending":false,"ward_near":false,"component_stock":{},"samples":0,"antidotes":0,"antidote_time":0.0,"memory_floor":-1}
static func activate(p) -> void:
 var s: Dictionary=p.character_state
 match p.character_id:
  "kairon": s.beam_pending=true
  "nami": s.bond_shield=0.75
  "beren","dalia":
   s.bond_dash=0.28 if resonance(p) else 0.24
   p.immunity=maxf(p.immunity,0.16)
   p.evasion_window=maxf(p.evasion_window,0.16)
   if p.character_id=="dalia": s.field_budget=1.2 if resonance(p) else 1.0; s.field_pending=true
  "elora":
   s.bond_shield=3.6 if resonance(p) else 3.0
   s.blocked=0.0
   s.counter_pending=true
static func tick(p, delta: float, was_active: bool) -> void:
 var s: Dictionary=p.character_state
 for key in ["bond_timer","bond_dash","resist_time"]: s[key]=maxf(0,float(s[key])-delta)
 if s.bond_timer<=0: p.stats.clear_temporary("bond_passive")
 if p.character_id=="elora":
  var ratio: float=p.stats.health/p.stats.max_health
  if ratio<0.35: s.low_guard=true
  elif ratio>0.45: s.low_guard=false
  p.stats.set_temporary("elora_guard",{"defense":0.15 if s.low_guard else 0.0})
static func reduce(p, amount: float, source: String) -> float:
 var s: Dictionary=p.character_state
 if float(s.family_ward)>0:
  var blocked:=minf(amount,float(s.family_ward)); s.family_ward-=blocked; amount-=blocked
 if p.character_id=="kairon" and source in ["acid","lightning","heat","cold"]:
  if s.resist_type==source and s.resist_time>0: amount*=0.8
  s.resist_type=source
  s.resist_time=3.0
 if p.character_id=="dalia" and s.ward_near and s.field_budget>0:
  var blocked:=minf(amount,float(s.field_budget)); s.field_budget-=blocked; amount-=blocked
 if p.character_id in ["nami","elora"] and p.ability_active>0:
  if p.character_id=="elora" or p.position.distance_to(p.skill_origin)<=120:
   var blocked:=minf(amount,float(s.bond_shield))
   s.bond_shield-=blocked
   s.blocked+=blocked
   amount-=blocked
 return maxf(0,amount)
static func near_miss(p, bullet: AbyssProjectile, distance: float) -> void:
 if p.character_id!="yura" or distance<18 or distance>=30 or p.velocity.length()<p.stats.speed*0.65: return
 var s: Dictionary=p.character_state
 var id:=bullet.get_instance_id()
 if s.near_ids.has(id): return
 if s.near_ids.size()>=64: s.near_ids.clear()
 s.near_ids[id]=true
 s.evades=mini(3,int(s.evades)+1)
 if s.evades>=3:
  s.precision_charge=true
  s.evades=0
static func observed(p, enemy) -> void:
 var s: Dictionary=p.character_state
 var id:=str(enemy.get_instance_id())
 if enemy.clock-float(s.observation_time.get(id,-10.0))<0.6: return
 s.observation_time[id]=enemy.clock
 var species: String=enemy.definition.id
 s.observed[species]=mini(3,int(s.observed.get(species,0))+1)
static func hit_multiplier(p, enemy) -> float:
 return 1.12 if p.character_id=="celine" and int(p.character_state.observed.get(enemy.definition.id,0))>=3 else 1.0
static func room(p, clean: bool, mobility: bool=false) -> void:
 if p.character_id=="aria" and clean:
  p.stats.set_temporary("bond_passive",{"attack_interval":-p.stats._attack_interval*0.15})
  p.character_state.bond_timer=6.0
 if p.character_id=="dalia" and mobility:
  p.stats.set_temporary("bond_passive",{"speed":20.0})
  p.character_state.bond_timer=5.0
static func new_room(p) -> void:
 p.character_state.near_ids.clear()
 if p.character_id=="lyra":
  p.stats.set_temporary("bond_passive",{"speed":15.0})
  p.character_state.bond_timer=4.0
static func killed(p, enemy) -> void:
 if p.character_id=="beren" and enemy.rank=="elite":
  p.stats.set_temporary("bond_passive",{"speed":20.0})
  p.character_state.bond_timer=5.0
static func resonance(p) -> bool:
 if p.character_id not in BondCatalog.SISTERS: return false
 var count:=0
 for id in ["mirror","boots","clock","shield","orbital"]:
  if p.relics.has(id): count+=1
 return count>=2
static func paint(p) -> void:
 if p.character_id not in BondCatalog.IDS: return
 var s: Dictionary=p.character_state
 var c: Color=p.character_color
 if p.ability_active>0:
  match p.character_id:
   "lyra":
    p.draw_arc(Vector2(0,-12),35,p.clock,p.clock+PI,24,c,2)
    p.draw_line(Vector2(0,-12),Vector2.from_angle(p.clock)*30+Vector2(0,-12),c,2)
   "kairon": p.draw_line(p.facing*20,p.facing*55,Color(c,0.5),5)
   "nami":
    for i in range(3): p.draw_circle(Vector2.from_angle(p.clock+i*TAU/3)*29,3,c)
   "yura":
    p.draw_arc(Vector2(0,-9),34,0,TAU,32,Color(c,0.6),1)
    p.draw_line(Vector2(-9,-44),Vector2(9,-44),c,2)
   "beren","dalia":
    for i in range(3): p.draw_line(-p.dash_direction*(10+i*8),-p.dash_direction*(20+i*8),Color(c,0.5-i*0.12),4)
   "celine": p.draw_arc(p.facing*35,9,0,TAU,16,c,2)
   "elora": p.draw_arc(Vector2(0,-9),32,0,TAU,24,Color(c,0.3+float(s.bond_shield)/5),3)
 if resonance(p):
  for i in range(3): p.draw_circle(Vector2(-7+i*7,-48),1.8,Color("e6c291"))

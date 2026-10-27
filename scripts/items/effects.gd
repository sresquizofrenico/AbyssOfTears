class_name RelicEffects
extends RefCounted

# Recipes are validated when the catalog loads. Secondary damage/projectiles do
# not re-enter the shot/hit pipeline, so combinations cannot recursively expand.
const OPERATIONS := {
 "constant":["pickup_radius","secret_radius","cooldown","critical","shield"],
 "shot":["power","velocity","reach","extra","fan","element","bounce","pierce","homing","return","split","explode","push","mark","far"],
 "hit":["burn_bonus","burn_extend","chill","pull"],
 "pickup":["heal"],"tick":["conditional","regen","cycle"],
 "kill":["buff","heal","recharge"],"room":["buff","heal","coin","recharge"],
 "hurt":["buff","recharge","pulse","time"],
 "ability":["buff","evade","echo","heal"],"active":["heal","pulse","buff","time","echo"],
 "challenge":["buff","determination"]}
var recipes: Array[Dictionary]=[]
var constants: Dictionary={}
var counters: Dictionary={}
var uses: Dictionary={}
var durations: Dictionary={}
var regeneration: Dictionary={}
var active_recharge: Dictionary={}
var active_id: String=""
var rng:=RandomNumberGenerator.new()
var tick_age:=0.0
var echo_time:=0.0
var echo_power:=0.0
var hostile_time:=0.0
var hostile_scale:=1.0
var shots:=0

static func valid_recipe(effect: Variant) -> bool:
 if not effect is Dictionary: return false
 if not OPERATIONS.has(effect.get("hook")) or effect.get("op") not in OPERATIONS[effect.hook]: return false
 for field in ["value","chance","duration","interval","radius","every","offset","budget"]:
  if effect.has(field):
   var value=effect[field]
   if not (value is float or value is int) or not is_finite(float(value)): return false
 if effect.has("chance") and (effect.chance<0 or effect.chance>1): return false
 for field in ["duration","interval","radius","every","budget"]:
  if effect.has(field) and float(effect[field])<=0: return false
 for field in ["every","budget","offset"]:
  if effect.has(field) and float(effect[field])!=floorf(float(effect[field])): return false
 if effect.op=="element" and effect.get("element") not in ["fire","ice","electric","poison"]: return false
 var required: Array=[]
 if effect.op in ["buff","cycle","time","echo"]: required.append("duration")
 if effect.op=="regen": required.append_array(["value","interval","budget"])
 elif effect.op=="pulse": required.append_array(["value","radius"])
 elif effect.op not in ["element","conditional","cycle","buff","coin"]: required.append("value")
 for field: String in required:
  if not effect.has(field): return false
 if effect.op in ["heal","recharge","evade","echo","pulse","determination","regen","shield","cooldown","critical","pickup_radius","secret_radius"] and float(effect.get("value",0))<=0: return false
 if effect.op=="cycle" and (not effect.get("alternate") is Dictionary or effect.alternate.is_empty()): return false
 if effect.has("duration") and float(effect.duration)>120: return false
 if effect.op=="conditional" and effect.get("when") not in ["low","full","moving","still"]: return false
 if effect.op in ["buff","conditional","cycle"]:
  if not effect.get("modifiers") is Dictionary or effect.modifiers.is_empty(): return false
  for values: Variant in [effect.modifiers,effect.get("alternate",{})]:
   if not values is Dictionary: return false
   for field in values:
    var amount=values[field]
    if field not in ["damage","speed","attack_interval","defense"] or not (amount is float or amount is int) or not is_finite(float(amount)): return false
 return true

func rebuild(owned: Dictionary) -> void:
 recipes.clear()
 constants.clear()
 for id: String in owned:
  var definition:=RelicCatalog.definition(id)
  var index:=0
  for original: Dictionary in definition.get("effects",[]):
   var effect:=original.duplicate(true)
   effect.source=id
   effect.key=id+":"+str(index)
   recipes.append(effect)
   if effect.hook=="constant":
    if effect.op=="shield": constants.shield=minf(float(constants.get("shield",60)),float(effect.value))
    else: constants[effect.op]=float(constants.get(effect.op,0))+float(effect.value)*int(owned[id])
   index+=1
  if active_id.is_empty() and definition.get("category")=="activo": active_id=id

func value(key: String) -> float:
 return float(constants.get(key,0))

func eligible(effect: Dictionary, player) -> bool:
 var key: String=effect.key
 counters[key]=int(counters.get(key,0))+1
 var every:=maxi(1,int(effect.get("every",1)))
 if posmod(int(counters[key])+int(effect.get("offset",0)),every)!=0: return false
 if effect.has("budget") and int(uses.get(key,0))>=int(effect.budget): return false
 if effect.has("chance"):
  var base:=float(effect.chance)
  var chance:=0.0 if base<=0 else 1.0 if base>=1 else clampf(base+player.stats.luck*0.005,0,0.95)
  if rng.randf()>=chance: return false
 return true

func packet(player) -> Dictionary:
 shots+=1
 var result: Dictionary={"power":1.0,"velocity":1.0,"reach":0.0,"extra":0,"fan":0,"pierce":0,"bounce":0,"homing":0,"return":0,"split":0,"explode":0.0,"push":0.0,"mark":0,"far":0.0,"elements":[]}
 for effect: Dictionary in recipes:
  if effect.hook!="shot" or not eligible(effect,player): continue
  if effect.op=="element":
   if not result.elements.has(effect.element): result.elements.append(effect.element)
  else: result[effect.op]+=float(effect.get("value",0))
 var critical:=clampf(player.stats.critical_chance,0,0.4)
 result.critical=critical>0 and rng.randf()<critical
 result.power=clampf(result.power,0.3,2.0)*(1.5 if result.critical else 1.0)
 result.extra=clampi(int(result.extra),0,2)
 result.fan=clampi(int(result.fan),0,2)
 result.pierce=clampi(int(result.pierce),0,3)
 result.bounce=clampi(int(result.bounce),0,2)
 return result

func execute(effect: Dictionary, player, game) -> bool:
 var amount:=float(effect.get("value",0))
 match effect.op:
  "heal":
   if player.stats.health>=player.stats.max_health: return false
   player.stats.health=minf(player.stats.max_health,player.stats.health+amount*(0.5 if player.character_id=="nox" else 1.0))
   player.health_changed.emit(player.stats.health,player.stats.max_health)
  "buff":
   player.stats.set_temporary("relic:"+effect.key,effect.modifiers)
   durations[effect.key]=float(effect.duration)
  "recharge": player.ability_remaining=maxf(0,player.ability_remaining-amount)
  "evade":
   player.immunity=maxf(player.immunity,amount)
   player.evasion_window=maxf(player.evasion_window,amount)
  "echo":
   echo_time=maxf(echo_time,float(effect.duration))
   echo_power=maxf(echo_power,amount)
  "time":
   hostile_time=maxf(hostile_time,float(effect.duration))
   hostile_scale=clampf(amount,0.35,1.0)
  "coin":
   if game==null: return false
   var data:=Economy.coin_data(1,player.position+Vector2(35,0))
   game.room_pickups.append(data)
   game.spawn_pickup(data)
  "pulse":
   if game==null: return false
   for enemy in game.enemies.duplicate():
    if not is_instance_valid(enemy) or enemy.dead or enemy.position.distance_to(player.position)>float(effect.radius): continue
    if effect.get("element")=="electric": enemy.slowed=maxf(enemy.slowed,1.0)
    enemy.take_damage(amount)
   if game.effects.size()<16: game.effects.append({"point":player.position,"life":0.4,"kind":19})
  "determination":
   if player.character_id=="shader": player.add_determination(amount)
  _: return false
 return true

func event(hook: String, player, game=null) -> bool:
 var activated:=false
 for effect: Dictionary in recipes:
  if effect.hook!=hook or (hook=="active" and effect.source!=active_id): continue
  if not eligible(effect,player): continue
  if execute(effect,player,game):
   uses[effect.key]=int(uses.get(effect.key,0))+1
   activated=true
 return activated

func tick(delta: float, player) -> void:
 echo_time=maxf(0,echo_time-delta)
 if echo_time<=0: echo_power=0
 hostile_time=maxf(0,hostile_time-delta)
 for id: String in active_recharge: active_recharge[id]=maxf(0,float(active_recharge[id])-delta)
 for key: String in durations.keys():
  durations[key]=float(durations[key])-delta
  if float(durations[key])<=0:
   player.stats.clear_temporary("relic:"+key)
   durations.erase(key)
 tick_age+=delta
 if tick_age<0.1: return
 var elapsed:=tick_age
 tick_age=0.0
 for effect: Dictionary in recipes:
  if effect.hook!="tick": continue
  if effect.op=="conditional":
   var condition: bool=player.stats.health<=player.stats.max_health*0.35 if effect.when=="low" else player.stats.health>=player.stats.max_health if effect.when=="full" else player.velocity.length()>1 if effect.when=="moving" else player.velocity.length()<=1
   if condition: player.stats.set_temporary("relic:"+effect.key,effect.modifiers)
   else: player.stats.clear_temporary("relic:"+effect.key)
  elif effect.op=="cycle":
   player.stats.set_temporary("relic:"+effect.key,effect.modifiers if int(player.relics.clock/float(effect.duration))%2==0 else effect.alternate)
  elif effect.op=="regen":
   regeneration[effect.key]=float(regeneration.get(effect.key,0))+elapsed
   if regeneration[effect.key]>=float(effect.interval):
    regeneration[effect.key]=0.0
    var healing:=effect.duplicate(true)
    healing.op="heal"
    if int(uses.get(effect.key,0))<int(effect.budget) and execute(healing,player,null): uses[effect.key]=int(uses.get(effect.key,0))+1

func activate(player, game) -> bool:
 if active_id.is_empty() or float(active_recharge.get(active_id,0))>0: return false
 if not event("active",player,game): return false
 active_recharge[active_id]=float(RelicCatalog.definition(active_id).cooldown)
 return true

func equip(id: String, owned: Dictionary) -> bool:
 if not owned.has(id) or RelicCatalog.definition(id).get("category")!="activo": return false
 active_id=id
 return true

func hit(bullet, enemy, player, game) -> void:
 if bullet.generation>0: return
 for effect: Dictionary in recipes:
  if effect.hook!="hit" or not eligible(effect,player): continue
  match effect.op:
   "burn_bonus":
    if enemy.burning>0 and not enemy.dead: enemy.take_damage(float(effect.value))
   "burn_extend":
    if not enemy.dead: enemy.burning=maxf(enemy.burning,minf(6.0,float(effect.value)))
   "chill":
    if not enemy.dead: enemy.apply_chill()
   "pull":
    if not enemy.dead: enemy.move_and_collide((player.position-enemy.position).normalized()*minf(18,float(effect.value)))
 if bullet.split>0:
  for angle in [-0.55,0.55]:
   var before: int=game.bullets.size()
   game.spawn_bullet(enemy.position+bullet.direction*22,bullet.direction.rotated(angle),bullet.speed,bullet.damage*0.22,180,false)
   if game.bullets.size()>before: game.bullets.back().generation=1
 if bullet.explosion>0:
  var count:=0
  for other in game.enemies.duplicate():
   if not is_instance_valid(other) or other==enemy or other.dead or other.position.distance_to(enemy.position)>45: continue
   other.take_damage(bullet.damage*minf(0.5,bullet.explosion))
   count+=1
   if count>=6: break

func pickup(id: String, player, game) -> void:
 for effect: Dictionary in recipes:
  if effect.hook=="pickup" and effect.source==id and execute(effect,player,game): uses[effect.key]=int(uses.get(effect.key,0))+1

func active_exhausted() -> bool:
 if active_id.is_empty(): return true
 for effect: Dictionary in recipes:
  if effect.hook=="active" and effect.source==active_id and (not effect.has("budget") or int(uses.get(effect.key,0))<int(effect.budget)): return false
 return true

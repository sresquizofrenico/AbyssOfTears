class_name CharacterRules
extends RefCounted

static func fresh() -> Dictionary:
 return {"special_floors":{},"passive_timer":0.0,"guard_timer":0.0,"guard_charge":false,"healing_left":4.5,"shadow_timer":0.0,"kill_timer":0.0,"kill_stacks":0,"hits":0,"dash":0.0,"windup":0.0,"shield_budget":0.0,"panic":false,"evasion_cooldown":0.0}

static func activate(player) -> void:
 match player.character_id:
  "neris":
   player.immunity=maxf(player.immunity,0.24)
   player.evasion_window=maxf(player.evasion_window,0.22)
  "nyra":
   player.immunity=maxf(player.immunity,0.2)
   player.evasion_window=maxf(player.evasion_window,0.2)
   player.character_state.dash=0.16
  "kael": player.character_state.windup=0.35
  "lumi": player.heal_budget=minf(1.5,float(player.character_state.healing_left))
  "vex": player.mixture=posmod(player.mixture+1,4)
  "orin": player.character_state.shield_budget=2.5
  "nox": player.stats.set_temporary("character",{"damage":player.stats._damage*0.35,"speed":player.stats._speed*0.2})
  "shader":
   player.immunity=maxf(player.immunity,0.2)
   player.evasion_window=maxf(player.evasion_window,0.2)
   update_shader(player)

static func tick(player, delta: float, was_active: bool) -> void:
 var state: Dictionary=player.character_state
 for key in ["passive_timer","guard_timer","shadow_timer","kill_timer","dash","evasion_cooldown"]: state[key]=maxf(0,float(state[key])-delta)
 player.awakened=maxf(0,player.awakened-delta)
 if player.character_id in ["neris","nyra"] and state.passive_timer<=0: player.stats.clear_temporary("passive")
 if player.character_id=="nox":
  if state.kill_timer<=0:
   state.kill_stacks=0
   player.stats.clear_temporary("passive")
  if was_active and player.ability_active<=0:
   player.stats.set_temporary("character",{"damage":-0.15,"speed":-40.0})
   player.fatigue=2.0
  elif player.fatigue>0:
   player.fatigue=maxf(0,player.fatigue-delta)
   if player.fatigue<=0: player.stats.clear_temporary("character")
 if player.character_id=="shader": update_shader(player)

static func update_shader(player) -> void:
 var state: Dictionary=player.character_state
 var ratio: float=player.stats.health/player.stats.max_health
 if ratio<0.35: state.panic=true
 elif ratio>0.42: state.panic=false
 if state.panic: player.stats.set_temporary("shader_panic",{"damage":player.stats._damage*0.15,"speed":player.stats._speed*0.1})
 else: player.stats.clear_temporary("shader_panic")
 var speed_multiplier:=1.0
 var rate_multiplier:=1.0
 if player.ability_active>0: speed_multiplier*=1.25; rate_multiplier*=1.2
 if player.awakened>0: speed_multiplier*=1.1; rate_multiplier*=1.15
 player.stats.set_temporary("shader_power",{"damage":player.stats._damage*0.4 if player.awakened>0 else 0.0,"speed":player.stats._speed*(speed_multiplier-1),"attack_interval":player.stats._attack_interval/rate_multiplier-player.stats._attack_interval})

static func reduce_damage(player, amount: float, source: String) -> float:
 var state: Dictionary=player.character_state
 if player.character_id=="orin":
  if source=="contact": amount*=0.8
  if player.ability_active>0:
   var blocked:=minf(float(state.shield_budget),amount)
   state.shield_budget-=blocked
   amount-=blocked
 if player.character_id=="lumi" and state.guard_charge and state.guard_timer>0:
  amount*=0.8
  state.guard_charge=false
 if player.character_id=="shader" and player.ability_active>0: amount*=0.7
 return maxf(0,amount)

static func hurt(player) -> void:
 if player.character_id=="lumi":
  player.character_state.guard_charge=true
  player.character_state.guard_timer=3.0
 if player.character_id=="shader": update_shader(player)

static func evaded(player) -> void:
 if player.evasion_window<=0: return
 # Consume the verifiable evasion window once; holding a finger is not an evade.
 player.evasion_window=0
 if player.character_id=="nyra":
  player.stats.set_temporary("passive",{"speed":30.0})
  player.character_state.passive_timer=2.0
 elif player.character_id=="mira": player.character_state.shadow_timer=1.2

static func killed(player) -> void:
 if player.character_id!="nox": return
 var state: Dictionary=player.character_state
 state.kill_stacks=mini(3,int(state.kill_stacks)+1)
 state.kill_timer=3.0
 player.stats.set_temporary("passive",{"damage":int(state.kill_stacks)*0.05})

static func special_room(player, floor_index: int) -> void:
 if player.character_id!="neris" or player.character_state.special_floors.has(str(floor_index)): return
 player.character_state.special_floors[str(floor_index)]=true
 player.character_state.passive_timer=4.0
 player.stats.set_temporary("passive",{"speed":20.0})

static func hit(player, enemy, bullet, game) -> void:
 if bullet.generation>0: return
 var state: Dictionary=player.character_state
 if player.character_id=="eira" and not enemy.dead: enemy.apply_chill()
 if player.character_id=="vex" and bullet.elements.size()>=2 and not enemy.dead and enemy.reaction_cooldown<=0:
  enemy.reaction_cooldown=0.8
  enemy.take_damage(minf(0.5,bullet.damage*0.2))
 if player.character_id=="kael":
  state.hits+=1
  if int(state.hits)%4==0:
   for angle in [-0.45,0.45]:
    var before: int=game.bullets.size()
    game.spawn_bullet(enemy.position+bullet.direction*23,bullet.direction.rotated(angle),bullet.speed,bullet.damage*0.2,160,false)
    if game.bullets.size()>before: game.bullets.back().generation=1

static func near_miss(player, distance: float) -> void:
 if player.character_id!="mira" or distance<18 or distance>=30 or player.velocity.length()<player.stats.speed*0.65 or player.character_state.evasion_cooldown>0: return
 player.character_state.shadow_timer=1.2
 player.character_state.evasion_cooldown=5.0

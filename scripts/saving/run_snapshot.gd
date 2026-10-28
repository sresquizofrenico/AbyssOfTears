class_name RunSnapshot
extends RefCounted
const VERSION:=1
const STATS: Array=["max_health","health","_damage","_speed","_attack_interval","attack_range","projectile_speed","_defense","luck","effect_chance","base_critical","critical_chance","temporary"]
const PLAYER: Array=["position","facing","cooldown","immunity","clock","pickup_pose"]
const ENEMY: Array=["position","velocity","facing","once","weak","slowed","poisoned","poison_tick","marked","frozen","chill_stacks","slow_strength","reaction_cooldown","rank","elite_timer","burning","burn_tick","destination","events","health","max_health","hit_radius","speed","clock","attack_timer","flash","telegraph"]
const BOSS: Array=["floor_level","phase","pattern","aim","announced","attacks","sequence","sequence_step","display_name"]
const BULLET: Array=["position","direction","speed","damage","remaining","hostile","pierce","bounces","elements","clock","generation","homing","returning","returned","split","explosion","push","marking","far_bonus","travelled","critical"]
const HAZARD: Array=["position","kind","age","duration","radius","activated","original_speed","stat_source"]
const INVENTORY: Array=["owned","shield_timer","clock","impacts"]
const EFFECTS: Array=["counters","uses","durations","regeneration","active_recharge","active_id","tick_age","echo_time","echo_power","hostile_time","hostile_scale","shots"]
const ARENA: Array=["mode","antidote_time","stations","fields","gate_open","crafted","used_antidotes"]

static func capture(game) -> Dictionary:
 var data: Dictionary={"version":VERSION,"active":true,"character":game.selected_character,"seed":game.dungeon_seed,"floor":game.layout.floor_index,"room":game.layout.current,"run_serial":game.run_serial,"next_enemy":game.next_enemy_uid,"coins":game.coins,"keys":game.keys,"rooms":game.layout.rooms.duplicate(true),"entry":game.entry_transition.duplicate(true),"stats":RunCodec.take(game.player.stats,STATS),"player":RunCodec.take(game.player,PLAYER),"ability":game.player.ability_snapshot(),"inventory":RunCodec.take(game.player.relics,INVENTORY),"effects":RunCodec.take(game.player.relics.effects,EFFECTS),"loot_state":str(game.loot_rng.state),"effect_state":str(game.player.relics.effects.rng.state),"enemies":[],"bullets":[],"hazards":[],"props":[],"arena":RunCodec.take(game.bonds,ARENA),"events":game.progress.data.events.duplicate(true)}
 # These source keys belong to a hazard in the scene and are rebound at restore.
 for key in data.stats.temporary.keys():
  if key=="curse" or str(key).begins_with("cold_env:"): data.stats.temporary.erase(key)
 for enemy in game.enemies:
  if not is_instance_valid(enemy) or enemy.dead: continue
  var value:=RunCodec.take(enemy,ENEMY)
  value.kind=enemy.kind
  value.uid=int(enemy.get_meta("run_uid",0))
  value.boss=enemy is TideWarden
  if value.boss: value.boss_data=RunCodec.take(enemy,BOSS)
  data.enemies.append(value)
 for bullet in game.bullets:
  if not is_instance_valid(bullet) or bullet.expired: continue
  var value:=RunCodec.take(bullet,BULLET)
  value.hits=[]
  for enemy in game.enemies:
   if bullet.hits.has(enemy.get_instance_id()): value.hits.append(int(enemy.get_meta("run_uid",0)))
  data.bullets.append(value)
 for hazard in game.hazards:
  if is_instance_valid(hazard) and not hazard.is_queued_for_deletion(): data.hazards.append(RunCodec.take(hazard,HAZARD))
 for prop in game.props: data.props.append({"clock":prop.clock,"flash":prop.flash})
 return data

static func valid(data: Variant) -> bool:
 if not data is Dictionary or data.get("version")!=VERSION or not data.get("active") is bool: return false
 if not data.active: return data.size()==2
 for key in ["character","seed","floor","room","run_serial","next_enemy","coins","keys","rooms","entry","stats","player","ability","inventory","effects","loot_state","effect_state","enemies","bullets","hazards","props","arena","events"]:
  if not data.has(key): return false
 if not data.character is String or CharacterCatalog.definition(data.character).is_empty(): return false
 for key in ["seed","floor","room","run_serial","next_enemy","coins","keys"]:
  if not RunCodec.number(data[key]) or data[key]<0 or float(data[key])!=floorf(float(data[key])): return false
 if data.floor>2 or data.seed>2147483647 or data.coins>1000000 or data.keys>99 or data.run_serial>1e9 or data.next_enemy>1000000: return false
 if not data.rooms is Array or data.rooms.size()!=12 or data.room>=12: return false
 var layout:=FloorLayout.new()
 layout.generate(int(data.seed),int(data.floor),true)
 for i in range(12):
  var room: Variant=data.rooms[i]
  if not room is Dictionary or room.get("cell")!=layout.rooms[i].cell or room.get("kind")!=layout.rooms[i].kind or room.get("links")!=layout.rooms[i].links: return false
  for flag in ["cleared","rewarded","visited","prepared","damaged","miniboss_done","miniboss_rewarded","bond_resources","bond_visited","machine_done","locked","revealed","mapped"]:
   if room.has(flag) and not room[flag] is bool: return false
  if not room.get("pickups",[]) is Array or room.get("pickups",[]).size()>160 or not room.get("props",[]) is Array or room.get("props",[]).size()>32: return false
  for item in room.get("pickups",[]):
   if not item is Dictionary or not item.get("position") is Vector2 or not item.get("id") is String: return false
   if not item.get("reward_kind","relic") in ["relic","coins","key","heal","artifact","component","sample","fragment"]: return false
   if item.get("reward_kind","relic")=="relic" and RelicCatalog.definition(item.id).is_empty(): return false
   if not RunCodec.number(item.get("price",0)) or item.get("price",0)<0: return false
   for flag in ["collected","chest","locked","paid","opened"]:
    if item.has(flag) and not item[flag] is bool: return false
  for prop in room.get("props",[]):
   if not prop is Dictionary or prop.get("kind") not in ["switch","fountain","barrel","trap"] or not prop.get("position") is Vector2: return false
 if not RunCodec.valid_fields(ActorStats.new(),STATS,data.stats): return false
 if data.stats.max_health<1 or data.stats.max_health>100 or data.stats.health<=0 or data.stats.health>data.stats.max_health or absf(data.stats._speed)>10000 or absf(data.stats._attack_interval)>10: return false
 if not data.ability is Dictionary: return false
 var p:=AbyssPlayer.new()
 p.configure_character(data.character)
 var ok:=RunCodec.valid_fields(p,PLAYER,data.player) and RunCodec.matches(p.ability_snapshot(),data.ability)
 if not data.ability is Dictionary or data.ability.size()!=p.ability_snapshot().size(): ok=false
 for key in p.ability_snapshot():
  if not data.ability.has(key): ok=false
 if not data.ability.get("character_state") is Dictionary: ok=false
 else:
  for key in CharacterRules.fresh():
   if not data.ability.character_state.has(key) and not str(key).begins_with("guest_"): ok=false
 p.free()
 if not RunCodec.number(data.ability.get("mixture")): ok=false
 elif data.ability.mixture<0 or data.ability.mixture>3: ok=false
 if not ok or not data.player.position is Vector2 or not RoomBlueprint.BOUNDS.grow(-14).has_point(data.player.position): return false
 if not RunCodec.valid_fields(RelicInventory.new(),INVENTORY,data.inventory) or not RunCodec.valid_fields(RelicEffects.new(),EFFECTS,data.effects): return false
 for id in data.inventory.owned:
  var item:=RelicCatalog.definition(id)
  if item.is_empty() or not RunCodec.number(data.inventory.owned[id]) or data.inventory.owned[id]<1 or data.inventory.owned[id]>int(item.max_stack): return false
 for values in data.stats.temporary.values():
  if not values is Dictionary: return false
  for key in values:
   if key not in ["damage","speed","attack_interval","defense"] or not RunCodec.number(values[key]): return false
 for field in ["counters","uses","durations","regeneration","active_recharge"]:
  for value in data.effects[field].values():
   if not RunCodec.number(value): return false
 if not data.effects.active_id.is_empty() and not data.inventory.owned.has(data.effects.active_id): return false
 for key in ["loot_state","effect_state"]:
  if not data[key] is String or not data[key].is_valid_int() or data[key].length()>21: return false
 if not data.enemies is Array or data.enemies.size()>16 or not data.bullets is Array or data.bullets.size()>96 or not data.hazards is Array or data.hazards.size()>10 or not data.props is Array or data.props.size()!=data.rooms[data.room].get("props",[]).size(): return false
 var ids: Array=[]
 for value in data.enemies:
  if not value is Dictionary or not RunCodec.number(value.get("kind")) or value.kind<0 or value.kind>19 or not value.get("boss") is bool or not RunCodec.number(value.get("uid")) or value.uid<=0 or value.uid>=data.next_enemy or ids.has(value.uid): return false
  ids.append(value.uid)
  var actor:=AbyssEnemy.new()
  var fields: Dictionary=value.duplicate()
  for key in ["kind","uid","boss","boss_data"]: fields.erase(key)
  ok=RunCodec.valid_fields(actor,ENEMY,fields)
  actor.free()
  if not ok or value.health<=0 or value.rank not in ["normal","elite","miniboss","boss"]: return false
  if value.boss:
   var boss:=TideWarden.new()
   ok=value.has("boss_data") and RunCodec.valid_fields(boss,BOSS,value.boss_data)
   boss.free()
   if not ok or value.boss_data.floor_level<0 or value.boss_data.floor_level>2 or int(value.boss_data.pattern) not in [0,1,2] or int(value.boss_data.phase) not in [1,2]: return false
 for value in data.bullets:
  if not value is Dictionary or not value.get("hits") is Array: return false
  var node:=AbyssProjectile.new()
  var fields: Dictionary=value.duplicate()
  fields.erase("hits")
  ok=RunCodec.valid_fields(node,BULLET,fields)
  node.free()
  if not ok or value.speed<0 or value.speed>2000 or value.damage<0 or value.generation<0 or value.generation>4: return false
 for value in data.hazards:
  var node:=EnemyHazard.new()
  ok=RunCodec.valid_fields(node,HAZARD,value)
  node.free()
  if not ok or value.kind not in ["acid","wall","dark","curse","cold","heat","lightning","explosion"]: return false
 for value in data.props:
  if not value is Dictionary or not RunCodec.number(value.get("clock")) or not RunCodec.number(value.get("flash")): return false
 var arena:=BondsArena.new()
 ok=RunCodec.valid_fields(arena,ARENA,data.arena)
 arena.free()
 if not ok or data.arena.mode not in ["","field"] or data.arena.fields.size()>8 or data.arena.stations.size()>4: return false
 for station in data.arena.stations:
  if not station is Dictionary or station.get("kind") not in ["machine","antidote"] or not station.get("point") is Vector2 or not station.get("used",false) is bool: return false
  if station.kind=="machine" and (station.get("id") not in BondsArena.MACHINES or not station.get("recipe") is Array): return false
 for field in data.arena.fields:
  if not field is Dictionary or field.get("kind") not in ["flame","ward"] or not field.get("point") is Vector2 or not RunCodec.number(field.get("life")) or not RunCodec.number(field.get("tick")): return false
 if not data.entry is Dictionary or not data.events is Dictionary or data.events.size()>4096: return false
 for key in data.events:
  if not key is String or not data.events[key] is bool: return false
 return true

static func player_into(game, data: Dictionary) -> void:
 game.player.stats=ActorStats.new()
 RunCodec.put(game.player.stats,STATS,data.stats)
 RunCodec.put(game.player,PLAYER,data.player)
 game.player.restore_ability(data.ability)
 game.player.character_state.near_ids.clear()
 game.player.relics=RelicInventory.new()
 RunCodec.put(game.player.relics,INVENTORY,data.inventory)
 game.player.relics.effects.rebuild(game.player.relics.owned)
 RunCodec.put(game.player.relics.effects,EFFECTS,data.effects)
 game.player.relics.effects.rng.state=int(data.effect_state)

static func actors_into(game, data: Dictionary) -> void:
 var mapping: Dictionary={}
 for value: Dictionary in data.enemies:
  if value.boss: game.spawn_guardian(int(value.boss_data.floor_level))
  else: game.spawn_enemy(int(value.kind),value.position,value.weak,value.rank)
  var actor=game.enemies.back()
  RunCodec.put(actor,ENEMY,value)
  actor.set_meta("run_uid",int(value.uid))
  mapping[int(value.uid)]=actor.get_instance_id()
  if value.boss:
   RunCodec.put(actor,BOSS,value.boss_data)
   game.boss_name.text=TideWarden.BOSS_NAMES[actor.floor_level]
   game.boss_bar.max_value=actor.max_health
   game.boss_bar.value=actor.health
 for value: Dictionary in data.bullets:
  game.spawn_bullet(value.position,value.direction,value.speed,value.damage,value.remaining,value.hostile)
  var node=game.bullets.back()
  RunCodec.put(node,BULLET,value)
  for id in value.hits:
   if mapping.has(int(id)): node.hits[mapping[int(id)]]=true
 for value: Dictionary in data.hazards:
  var node:=EnemyHazard.new()
  node.position=value.position
  node.kind=value.kind
  node.player=game.player
  game.world.add_child(node)
  game.hazards.append(node)
  RunCodec.put(node,HAZARD,value)
  if node.activated and node.kind in ["cold","curse"]:
   game.player.stats.set_temporary(node.stat_source if node.kind=="cold" else "curse",{"speed":-game.player.stats._speed*(0.25 if node.kind=="cold" else 0.3)})
 for i in range(game.props.size()):
  game.props[i].clock=data.props[i].clock
  game.props[i].flash=data.props[i].flash
 RunCodec.put(game.bonds,ARENA,data.arena)
 if game.bonds.gate_open and is_instance_valid(game.bonds.gate_body): game.bonds.gate_body.collision_layer=0
 game.next_enemy_uid=int(data.next_enemy)
 game.loot_rng.state=int(data.loot_state)

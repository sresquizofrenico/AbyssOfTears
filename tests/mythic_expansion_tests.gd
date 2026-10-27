extends SceneTree
var checks:=0
var failures:=0
func check(value: bool, message: String) -> void:
 checks+=1
 if not value:
  failures+=1
  push_error("TEST FAILED: "+message)
func _initialize() -> void: run.call_deferred()
func clear_bullets(game) -> void:
 for bullet in game.bullets:
  if is_instance_valid(bullet): bullet.expire()
 game.bullets.clear()
func shot_matches(op: String, effect: Dictionary, bullet: AbyssProjectile, count: int, player) -> bool:
 match op:
  "power": return bullet.damage!=player.stats.damage
  "velocity": return bullet.speed!=player.stats.projectile_speed
  "reach": return bullet.remaining>player.stats.attack_range
  "extra","fan": return count>1
  "element": return effect.element in bullet.elements
  "pierce": return bullet.pierce>0
  "bounce": return bullet.bounces>0
  "homing": return bullet.homing
  "return": return bullet.returning
  "split": return bullet.split>0
  "explode": return bullet.explosion>0
  "push": return bullet.push>0
  "mark": return bullet.marking
  "far": return bullet.far_bonus>0
 return false
func run() -> void:
 var progress:=CharacterCatalog.progress_node()
 var saved: Dictionary=progress.data.duplicate(true)
 var saved_path: String=progress.storage_path
 progress.storage_path="user://mythic-test-progress.json"
 progress.data=progress.fresh()
 var migration: Dictionary=progress.fresh()
 migration.version=1
 migration.counters.enemies=43
 migration.unlocked.append("mira")
 migration.erase("boss_types")
 var migrated: Dictionary=progress.validate(JSON.parse_string(JSON.stringify(migration)))
 check(not migrated.is_empty() and migrated.version==2 and migrated.counters.enemies==43 and migrated.unlocked.has("mira"),"Version-one JSON migrates without relocking previously earned characters")
 check(progress.import_code("AOT1."+Marshalls.utf8_to_base64(JSON.stringify(migration))) and progress.is_unlocked("mira"),"Old portable backups still restore")
 progress.data=progress.fresh()
 check(CharacterCatalog.DATA.size()==11 and CharacterCatalog.rarity_name("shader")=="Mítico","Eleven-character roster and independent Mythic character rarity")
 check(not progress.shader_ready() and not progress.record("shader_trial","fake"),"Shader trial cannot bypass its six prerequisites")
 var distribution: Array[int]=[0,0,0,0,0,0]
 var ids: Dictionary={}
 for entry: Dictionary in RelicCatalog.DATA:
  distribution[int(entry.rarity)]+=1
  check(not ids.has(entry.id),"No duplicated object ID: "+entry.id)
  ids[entry.id]=true
  check(RelicCatalog.icon(entry.id)!=null,"Real loadable icon: "+entry.id)
  check(not entry.description.is_empty() and entry.max_stack>0,"Description and stack rules: "+entry.id)
  for recipe: Dictionary in entry.get("effects",[]): check(RelicEffects.valid_recipe(recipe),"Executable recipe schema: "+entry.id)
 check(distribution==[30,25,20,13,9,3] and ids.size()==100,"Exactly one hundred items with requested six-tier distribution")
 var data:=Economy.config()
 for context: String in data.rarity:
  for row: Array in data.rarity[context]: check(row.size()==6 and is_equal_approx(row.reduce(func(a,b): return a+b,0),100),"All configured rarity rows sum to 100 across six tiers")
 check(not Economy.context_allows("origin_fragment",0,"shop"),"Shop fallback cannot force a zero-weight Mythic item")
 check(not RelicEffects.valid_recipe({"hook":"shot","op":"unknown"}),"Unknown effect operations rejected")
 check(not RelicEffects.valid_recipe({"hook":"ability","op":"buff","modifiers":{"damage":1}}),"Missing buff duration rejected")
 check(not RelicEffects.valid_recipe({"hook":"shot","op":"pierce","value":1,"chance":NAN}),"Non-finite proc probability rejected")
 check(not RelicEffects.valid_recipe({"hook":"shot","op":"pierce","value":1,"every":0.5}),"Fractional shot counters rejected")
 var bad_entry: Dictionary=RelicCatalog.definition("light_boots").duplicate(true)
 bad_entry.modifiers.damage="invalid"
 check(not RelicCatalog.valid_entry(bad_entry),"Invalid permanent modifier rejected")
 bad_entry=RelicCatalog.definition("blue_flask").duplicate(true)
 bad_entry.cooldown=0
 check(not RelicCatalog.valid_entry(bad_entry),"Zero active-item cooldown rejected")
 bad_entry=RelicCatalog.definition("blue_flask").duplicate(true)
 bad_entry.icon_region[0]=-1
 check(not RelicCatalog.valid_entry(bad_entry),"Invalid atlas bounds rejected")
 root.size=Vector2i(960,540)
 var game=load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 game.set_physics_process(false)
 var verified: Dictionary={}
 for entry: Dictionary in RelicCatalog.DATA:
  game.dungeon_mode=false
  game.expedition=false
  game.trial_kind=""
  game.lab_mode=false
  game.selected_character="neris"
  game.start_game()
  for body in game.world.get_children():
   if body is CollisionObject2D: body.disable_mode=CollisionObject2D.DISABLE_MODE_KEEP_ACTIVE
  game.world.process_mode=Node.PROCESS_MODE_DISABLED
  var player: AbyssPlayer=game.player
  player.stats.health=player.stats.max_health-2
  var prior_damage:=player.stats.damage
  var prior_speed:=player.stats.speed
  var prior_interval:=player.stats.attack_interval
  var prior_range:=player.stats.attack_range
  var prior_health:=player.stats.health
  var pickup: RelicPickup=game.spawn_pickup({"id":entry.id,"position":player.position,"collected":false,"chest":false})
  check(pickup.claim() and not pickup.claim() and player.relics.has(entry.id),"Real collection exactly once: "+entry.id)
  if not entry.modifiers.is_empty():
   check(player.stats.damage!=prior_damage or player.stats.speed!=prior_speed or player.stats.attack_interval!=prior_interval or player.stats.attack_range!=prior_range or player.stats.max_health!=6 or player.stats.defense!=0 or player.stats.luck!=0 or player.stats.projectile_speed!=410,"Stat modifier has a real effect: "+entry.id)
  for effect: Dictionary in player.relics.effects.recipes:
   var key: String=entry.id+"/"+effect.key
   var observed:=false
   match effect.hook:
    "constant":
     observed=player.relics.effects.value(effect.op)>0
     if effect.op=="shield": observed=observed and player.relics.block_hit() and not player.relics.block_hit()
     if effect.op=="critical": observed=observed and player.stats.critical_chance>0
    "pickup": observed=player.stats.health>prior_health
    "shot":
     for n in range(32):
      clear_bullets(game)
      game.spawn_player_bullet(player.position,Vector2.UP,player.stats)
      if not game.bullets.is_empty():
       for bullet: AbyssProjectile in game.bullets:
        if shot_matches(effect.op,effect,bullet,game.bullets.size(),player): observed=true
     clear_bullets(game)
    "hit":
     var enemy: AbyssEnemy=game.enemies[0]
     enemy.health=100
     enemy.max_health=100
     enemy.position=player.position+Vector2(80,0)
     enemy.burning=3
     var old_position:=enemy.position
     var bullet:=AbyssProjectile.new()
     bullet.damage=1
     game.apply_relic_hit(bullet,enemy)
     observed=enemy.health<98.9 if effect.op=="burn_bonus" else enemy.burning>=5 if effect.op=="burn_extend" else enemy.chill_stacks>0 if effect.op=="chill" else enemy.position!=old_position
     bullet.free()
    "tick":
     if effect.op=="conditional":
      player.stats.health=player.stats.max_health*0.2 if effect.when=="low" else player.stats.max_health
      player.velocity=Vector2(20,0) if effect.when=="moving" else Vector2.ZERO
      player.relics.effects.tick(0.11,player)
      observed=player.stats.temporary.has("relic:"+effect.key)
     elif effect.op=="cycle":
      player.clock=0
      player.relics.clock=0
      player.relics.effects.tick(0.11,player)
      var first:=player.stats.damage
      player.clock=float(effect.duration)+0.1
      player.relics.clock=player.clock
      player.relics.effects.tick(0.11,player)
      observed=player.stats.damage!=first and player.stats.defense>0
     elif effect.op=="regen":
      var health:=player.stats.health
      player.relics.effects.tick(float(effect.interval)+0.1,player)
      observed=player.stats.health>health
    _:
     for n in range(16):
      player.ability_remaining=10
      player.stats.health=maxf(1,player.stats.max_health-2)
      player.character_id="shader" if effect.op=="determination" else "neris"
      var health:=player.stats.health
      var before: int=game.pickups.size()
      var enemy: AbyssEnemy=game.enemies[0]
      enemy.position=player.position+Vector2(50,0)
      enemy.health=100
      var old_health:=enemy.health
      if effect.hook=="active":
       player.relics.effects.active_recharge[entry.id]=0
       player.relics.effects.activate(player,game)
      else: player.relics.effects.event(effect.hook,player,game)
      match effect.op:
       "buff": observed=observed or player.stats.temporary.has("relic:"+effect.key)
       "heal": observed=observed or player.stats.health>health
       "coin": observed=observed or game.pickups.size()>before
       "recharge": observed=observed or player.ability_remaining<10
       "evade": observed=observed or player.evasion_window>0
       "echo": observed=observed or player.relics.effects.echo_time>0
       "time": observed=observed or player.relics.effects.hostile_time>0
       "pulse": observed=observed or enemy.health<old_health
       "determination": observed=observed or player.determination>0
     if effect.has("budget"): check(int(player.relics.effects.uses.get(effect.key,0))<=int(effect.budget),"Consumable/run budget cannot be exceeded: "+key)
   check(observed,"Recipe changes live combat/inventory state: "+key)
   verified[key]=observed
  await process_frame
 # Existing catalog data is no longer mutated by laboratory targets or ranked enemies.
 var damage_before: float=EnemyCatalog.DATA[0].damage
 game.start_relic_room()
 check(EnemyCatalog.DATA[0].damage==damage_before,"Laboratory does not mutate shared enemy data")
 var lab_ids: Dictionary={}
 for page in range(8):
  game.start_relic_room(page)
  check(game.pickups.size()<=14,"Laboratory only instantiates one fourteen-item page")
  for pickup: RelicPickup in game.pickups: lab_ids[pickup.data.id]=true
  await process_frame
 check(lab_ids.size()==100,"All one hundred objects can appear physically through paged lab")
 # The larger pickup radius never bypasses shop purchase confirmation.
 game.dungeon_mode=false
 game.lab_mode=false
 game.start_game()
 game.world.process_mode=Node.PROCESS_MODE_DISABLED
 game.player.relics.add("magnetic_glove",game.player.stats)
 var magnetic_pickup: RelicPickup=game.spawn_pickup({"id":"heart","position":game.player.position+Vector2(60,0),"chest":false,"collected":false})
 magnetic_pickup.position=game.player.position+Vector2(60,0)
 magnetic_pickup.cooldown=0
 magnetic_pickup._physics_process(0.001)
 check(magnetic_pickup.taking and game.player.relics.has("heart"),"Magnet really collects free objects beyond the old radius")
 var shop_pickup: RelicPickup=game.spawn_pickup({"id":"crystal","position":game.player.position,"price":6,"chest":false,"collected":false})
 shop_pickup.cooldown=0
 shop_pickup._physics_process(0.001)
 check(not shop_pickup.data.collected and not game.player.relics.has("crystal"),"Magnet never turns a shop product into a free pickup")
 # Demonstrate actual encounter ranks and unique bosses through defeat adapters.
 progress.data=progress.fresh()
 game.show_main_menu()
 game.start_dungeon(9011)
 game.world.process_mode=Node.PROCESS_MODE_DISABLED
 for floor_index in range(3):
  game.layout.floor_index=floor_index
  game.spawn_guardian(floor_index)
  var boss: TideWarden=game.enemies.back()
  for pattern in range(3):
   boss.pattern=pattern
   boss.perform_pattern()
  check(boss.attacks==[1,1,1],"Each distinct boss executes its three patterns")
  boss.take_damage(10000)
 check(progress.data.boss_types.size()==3,"Three actual distinct boss IDs count toward Shader")
 for i in range(10):
  game.spawn_enemy(6,Vector2(300,180),false,"elite")
  var elite: AbyssEnemy=game.enemies.back()
  elite.take_damage(1000)
  game.on_enemy_defeated(elite,elite.position,99)
 check(progress.amount("elites")==10,"Ten actual elite defeats count exactly once")
 game.spawn_enemy(18,Vector2(400,160),false,"miniboss")
 game.enemies.back().take_damage(1000)
 check(progress.is_unlocked("orin"),"Real miniboss makes Orin attainable")
 for i in range(30): progress.record("item","discovery%d" % i,{"id":RelicCatalog.DATA[i].id})
 check(progress.is_unlocked("vex"),"Expanded catalog makes Vex attainable")
 for i in range(5): progress.record("secret","secret%d" % i)
 progress.record("ending","main")
 for i in range(3): progress.record("room","hard%d" % i,{"hard":true,"clean":true})
 check(progress.shader_ready() and not progress.is_unlocked("shader"),"Six accumulated prerequisites open the trial without granting Shader")
 game.show_main_menu()
 game.show_character_selection()
 await process_frame
 var selection: CharacterSelection=game.panel
 selection.index=10
 selection.refresh()
 check(selection.begin_button.text=="LA PRUEBA" and not selection.begin_button.disabled,"Locked Mythic slot offers eligible trial")
 check(not game.begin_character_run("shader"),"Trial availability never bypasses character lock")
 check(game.start_trial("shader") and game.player.character_id!="shader","Trial starts with an already unlocked character")
 game.world.process_mode=Node.PROCESS_MODE_DISABLED
 for stage in range(3):
  check(game.trial_stage==stage,"Trial stages occur consecutively")
  var attempts:=0
  while not game.enemies.is_empty() and attempts<10:
   attempts+=1
   for enemy: AbyssEnemy in game.enemies.duplicate():
    if is_instance_valid(enemy): enemy.take_damage(10000)
  game.clear_wave()
 check(game.state=="victory" and progress.is_unlocked("shader"),"Winning all three actual trial encounters permanently unlocks Shader")
 check(not game.start_trial("shader"),"Completed Shader trial cannot farm duplicate unlocks")
 game.show_main_menu()
 game.show_character_selection()
 check(game.begin_character_run("shader"),"Unlocked Shader can begin a real dungeon")
 game.world.process_mode=Node.PROCESS_MODE_DISABLED
 var shader: AbyssPlayer=game.player
 check(shader.stats.critical_chance==0.08,"Shader critical bonus matches actual stat")
 var speed:=shader.stats.speed
 var damage:=shader.stats.damage
 var rate:=1.0/shader.stats.attack_interval
 check(game.use_character_ability(),"Shader survival instinct activates")
 check(is_equal_approx(shader.stats.speed,speed*1.25) and is_equal_approx(1.0/shader.stats.attack_interval,rate*1.2),"Shader exact temporary speed and fire-rate modifiers")
 shader.immunity=0
 var health:=shader.stats.health
 shader.take_damage(2)
 check(is_equal_approx(health-shader.stats.health,2*0.7-shader.stats.defense),"Survival instinct reduces incoming damage by thirty percent")
 shader.stats.health=shader.stats.max_health*0.3
 CharacterRules.update_shader(shader)
 check(shader.character_state.panic,"Critical-health passive activates below thirty-five percent")
 shader.stats.health=shader.stats.max_health*0.38
 CharacterRules.update_shader(shader)
 check(shader.character_state.panic,"Passive hysteresis prevents threshold flicker")
 shader.stats.health=shader.stats.max_health*0.5
 CharacterRules.update_shader(shader)
 check(not shader.character_state.panic,"Passive deactivates above forty-two percent")
 check(not game.use_shader_awaken(),"Awakening refuses incomplete determination bar")
 shader.add_determination(150)
 check(shader.determination==100 and game.use_shader_awaken() and shader.determination==0,"Awakening consumes a capped full bar")
 check(is_equal_approx(shader.stats.damage,damage*1.4),"Awakening increases actual damage forty percent")
 clear_bullets(game)
 game.spawn_player_bullet(shader.position,Vector2.UP,shader.stats)
 check(game.bullets[0].pierce>=1,"Awakening grants actual additional piercing")
 var snapshot:=shader.ability_snapshot()
 game.start_game(true)
 check(game.player.awakened==snapshot.awakened and game.player.determination==snapshot.determination,"Room change preserves exclusive resource and active duration")
 # Five independent touch streams exercise movement, attack and all three actions.
 var actor: AbyssPlayer=game.player
 actor.relics.add("blue_flask",actor.stats)
 actor.relics.effects.equip("blue_flask",actor.relics.owned)
 actor.stats.health=actor.stats.max_health-2
 actor.ability_remaining=0
 actor.awakened=0
 actor.add_determination(100)
 game._physics_process(0.001)
 var centers: Array[Vector2]=[game.controls.joystick_center()+Vector2(25,0),game.controls.attack_positions()[0],game.controls.item_center(),game.controls.ability_center(),game.controls.awaken_center()]
 for i in range(5):
  var event:=InputEventScreenTouch.new()
  event.index=40+i
  event.position=centers[i]
  event.pressed=true
  root.push_input(event,true)
 check(game.controls.move_vector.x>0 and game.controls.fire_vector==Vector2.UP and actor.ability_remaining>0 and actor.awakened>0 and actor.relics.effects.active_recharge.get("blue_flask",0)>0,"Five real ScreenTouch streams coexist without conflating fingers")
 for i in range(5):
  var event:=InputEventScreenTouch.new()
  event.index=40+i
  event.position=centers[i]
  event.pressed=false
  root.push_input(event,true)
 check(game.controls.move_vector==Vector2.ZERO and game.controls.fire_vector==Vector2.ZERO and game.controls.special_fingers.is_empty(),"Every action releases its own touch state")
 var item_recharge: float=actor.relics.effects.active_recharge.blue_flask
 actor.relics.add("silver_hourglass",actor.stats)
 actor.relics.effects.equip("silver_hourglass",actor.relics.owned)
 actor.relics.effects.equip("blue_flask",actor.relics.owned)
 check(actor.relics.effects.active_recharge.blue_flask==item_recharge,"Equipping another active item cannot reset a recharge")
 # Maximum-content combination is bounded in the real coordinator, including fragments.
 for entry: Dictionary in RelicCatalog.DATA: game.player.relics.add(entry.id,game.player.stats)
 for i in range(100): game.spawn_player_bullet(game.player.position,Vector2.UP,game.player.stats)
 check(game.bullets.size()<=96,"All one hundred objects cannot exceed global projectile cap")
 clear_bullets(game)
 game.spawn_player_bullet(game.player.position,Vector2.UP,game.player.stats)
 check(game.bullets.size()<=12,"Single combined attack remains limited to twelve projectiles")
 game.queue_free()
 await process_frame
 await process_frame
 await create_timer(0.25).timeout
 progress.data=saved
 progress.storage_path=saved_path
 print("MYTHIC EXPANSION RESULT: %d checks, %d failures, %d recipe branches verified" % [checks,failures,verified.size()])
 quit(1 if failures else 0)

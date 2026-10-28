extends SceneTree
var checks:=0
var failures:=0
var game
var store
var progress
func _initialize() -> void: run.call_deferred()
func check(value: bool, message: String) -> void:
 checks+=1
 if not value:
  failures+=1
  push_error("TEST FAILED: "+message)
func reload_from_disk() -> bool:
 game.save_now(true)
 game.show_main_menu()
 store.flush()
 store.cached=store.load_disk()
 return game.continue_run()
func frozen() -> void:
 game.set_world_active(false)
 game.set_physics_process(false)
 game.set_process(false)
func room(kind: String) -> int:
 for i in range(game.layout.rooms.size()):
  if game.layout.rooms[i].kind==kind: return i
 return -1
func open_all() -> void:
 for data in game.layout.rooms:
  data.cleared=true
  data.locked=false
  data.revealed=true
func run() -> void:
 root.size=Vector2i(960,540)
 progress=root.get_node("Progress")
 store=root.get_node("RunSave")
 progress.storage_path="user://checkpoint-progress.json"
 progress.data=progress.fresh()
 store.storage_path="user://checkpoint-test.json"
 store.cached={}
 game=load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 check(not game.panel.buttons.has("continue"),"Continue hidden without compatible checkpoint")
 check(game.start_dungeon(777),"Existing campaign starts")
 frozen()
 check(RunSnapshot.valid(RunSnapshot.capture(game)),"Current campaign serializable")
 # Reproducible maps, all four exit directions and their opposite interior markers.
 var directions: Dictionary={}
 for seed_value in range(12):
  for floor_index in range(3):
   var layout:=FloorLayout.new()
   layout.generate(seed_value,floor_index,true)
   for i in range(12):
    layout.current=i
    for target: int in layout.rooms[i].links:
     var t:=RoomTransition.record(layout,target)
     check(t.origin==i and t.destination==target and t.entry==-t.exit,"Opposite entrance and traceable door IDs")
     check(t.spawn.distance_to(t.marker)>=40 and t.facing==Vector2(t.exit),"Interior marker and inward facing")
     var blueprint:=RoomBlueprint.create(seed_value,floor_index,target,layout.rooms[target].kind)
     check(not RoomBlueprint.blocks(blueprint,t.spawn,18),"Spawn marker reachable without wall intersection")
     directions[str(t.exit)]=true
 check(directions.size()==4,"All four cardinal doors exercised")
 open_all()
 for target_kind in ["combat","shop","boss","secret","treasure"]:
  var target:=room(target_kind)
  var origin: int=game.layout.rooms[target].links[0]
  game.layout.current=origin
  game.start_game(true)
  frozen()
  var before_health: float=game.player.stats.health
  var direction:=RoomTransition.direction(game.layout,origin,target)
  game.travel_to(target)
  frozen()
  check(game.layout.current==target and game.entry_transition.entry==-direction,"Actual transition to "+target_kind)
  check(game.player.position.distance_to(game.entry_transition.marker)<100,"Actual spawn near correct doorway in "+target_kind)
  check(not game.chamber.blocks(game.player.position,18) and game.player.stats.health==before_health,"Safe transition preserves health")
  check(game.chamber.find_children("Entry_*","Marker2D",false,false).size()==game.layout.rooms[target].links.size(),"Each connected door has a real interior Marker2D")
  check(game.door_cooldown>0 and game.world.position==Vector2.ZERO,"No immediate bounce; camera recentered")
  game.travel_to(origin)
  frozen()
  check(game.layout.current==origin and game.player.facing==Vector2(-direction),"Return through same doorway")
 # Free rewards / paid items / opened chests survive real JSON round trip.
 game.start_dungeon(777)
 frozen()
 open_all()
 game.layout.current=room("shop")
 game.start_game(true)
 frozen()
 game.coins=200
 var product=game.pickups[0]
 var id: String=product.data.id
 var price: int=product.data.price
 game.player.position=product.position
 product.cooldown=0
 check(game.purchase_pickup(product),"Buy physical shop product")
 check(game.coins==200-price and game.player.relics.has(id),"Money and item change together")
 var post_money: int=game.coins
 check(reload_from_disk(),"Continue after real disk read")
 frozen()
 check(game.coins==post_money and game.player.relics.has(id),"Purchase not free or lost on reload")
 check(game.layout.rooms[game.layout.current].pickups[0].collected,"Sold product remains sold")
 var owned_count: int=game.player.relics.owned[id]
 check(reload_from_disk(),"Second reload")
 frozen()
 check(game.player.relics.owned[id]==owned_count and game.coins==post_money,"Repeated reload cannot duplicate purchase")
 game.resume_game()
 frozen()
 var data: Dictionary={"id":"boots","position":Vector2(480,300),"chest":true,"locked":true,"collected":false}
 game.room_pickups.append(data)
 var chest=game.spawn_pickup(data)
 game.keys=2
 game.player.position=chest.position
 chest.cooldown=0
 check(chest.open_chest() and game.keys==1,"Locked chest opens once")
 check(reload_from_disk(),"Save open chest before taking reward")
 frozen()
 check(game.keys==1 and game.room_pickups.back().opened and not game.room_pickups.back().chest,"Open state and paid key restored")
 game.resume_game()
 frozen()
 var reward=game.pickups.back()
 reward.cooldown=0
 reward.open_age=1
 game.player.position=reward.position
 check(reward.claim(),"Reward from restored chest can be picked up")
 check(reload_from_disk(),"Save chest reward")
 frozen()
 check(game.keys==1 and game.player.relics.has("boots") and game.room_pickups.back().collected,"Chest cannot dispense twice")
 # Combat: damaged enemies, bullets with pierce-hit ledger, hazards and cooldowns.
 game.resume_game()
 game.spawn_enemy(15,Vector2(700,220))
 game.spawn_guardian(2)
 frozen()
 game.enemies[0].health=1.2
 game.enemies[0].once=true
 game.player.stats.health=3.25
 game.player.ability_remaining=12.3
 game.player.relics.effects.active_recharge["test"]=7.5
 game.player.stats.set_temporary("test",{"damage":0.2})
 game.spawn_bullet(Vector2(590,300),Vector2.RIGHT,400,1,500,false)
 game.bullets.back().hits[game.enemies[0].get_instance_id()]=true
 game.spawn_hazard(Vector2(350,310),"lightning")
 game.hazards.back().age=0.7
 var enemies_before: int=game.enemies.size()
 var bullets_before: int=game.bullets.size()
 var random_before: String=str(game.loot_rng.state)
 var enemy_uid: int=game.enemies[0].get_meta("run_uid")
 check(reload_from_disk(),"Serializable combat checkpoint restores")
 frozen()
 check(game.enemies.size()==enemies_before and is_equal_approx(game.enemies[0].health,1.2) and game.enemies[0].once,"Enemy damage and one-use duplication flag retained")
 check(game.enemies[0].get_meta("run_uid")==enemy_uid,"Stable enemy identity after restore")
 check(game.bullets.size()==bullets_before and game.bullets.back().hits.has(game.enemies[0].get_instance_id()),"Projectile hit ledger remaps stable enemy IDs")
 check(game.hazards.size()==1 and is_equal_approx(game.hazards[0].age,0.7),"Hazard announcement time retained")
 check(game.player.stats.health==3.25 and is_equal_approx(game.player.ability_remaining,12.3),"No free healing or cooldown refresh")
 check(game.player.stats.temporary.has("test") and game.player.relics.effects.active_recharge.test==7.5,"Temporary stat and item cooldown retained")
 check(str(game.loot_rng.state)==random_before,"RNG stream retained without floating point precision loss")
 # Safe checkpoint + validation, atomic rotation and backup recovery.
 check(game.save_now(true),"Safe checkpoint written")
 var saved: Dictionary=store.load_disk()
 check(not saved.is_empty(),"Disk validation accepts generated snapshot")
 var corrupt: Dictionary=saved.duplicate(true)
 corrupt.rooms[0].links=[999]
 check(not RunSnapshot.valid(corrupt),"Invalid map rejected")
 corrupt=saved.duplicate(true)
 corrupt.stats.health=-1
 check(not RunSnapshot.valid(corrupt),"Invalid health rejected")
 corrupt=saved.duplicate(true)
 corrupt.ability.character_state={}
 check(not RunSnapshot.valid(corrupt),"Missing character state rejected")
 var file:=FileAccess.open(store.storage_path,FileAccess.WRITE)
 file.store_string("broken")
 file.close()
 store.cached=store.load_disk()
 check(store.recovered and store.available(),"Corrupt main recovers valid backup")
 var old_path: String=store.storage_path
 store.storage_path="user://missing-directory/save.json"
 check(not game.save_now(true) and store.last_error!=OK,"Write failure reported without fake success")
 store.storage_path=old_path
 store.cached=saved
 game.show_main_menu()
 await process_frame
 check(game.panel.buttons.has("continue"),"Continue visible when compatible save exists")
 check(game.continue_run() and game.state=="paused","Continue starts paused for orientation")
 frozen()
 game.resume_game()
 game.finish(false)
 store.flush()
 store.cached=store.load_disk()
 check(not store.available(),"Defeat invalidates checkpoint instead of resurrecting run")
 game.show_main_menu()
 check(not game.panel.buttons.has("continue"),"Continue removed after defeat")
 game.queue_free()
 await process_frame
 store.flush()
 await preload("res://tests/audio_test_cleanup.gd").drain(self)
 print("CHECKPOINT RESULT: %d checks, %d failures" % [checks,failures])
 quit(0 if failures==0 else 1)

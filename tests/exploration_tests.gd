extends SceneTree
var checks := 0
var failures := 0
var game

func check(value: bool, message: String) -> void:
 checks+=1
 if not value:
  failures+=1
  push_error("TEST FAILED: "+message)

func route(map: FloorLayout, target: int) -> Array[int]:
 var previous: Dictionary={map.current:-1}
 var queue: Array[int]=[map.current]
 while not queue.is_empty():
  var at: int=queue.pop_front()
  for next: int in map.rooms[at].links:
   if next==map.secret_room or previous.has(next): continue
   previous[next]=at
   queue.append(next)
 var path: Array[int]=[]
 if not previous.has(target): return path
 var at:=target
 while at!=map.current:
  path.push_front(at)
  at=previous[at]
 return path

func clear_room() -> void:
 for attempt in range(4):
  for enemy in game.enemies.duplicate(): enemy.take_damage(999)
  if game.enemies.is_empty(): break
 for node in game.hazards:
  if is_instance_valid(node) and node.kind=="explosion": node._physics_process(1.3)
 await process_frame
 game.clear_wave()
 await process_frame

func navigate(target: int) -> void:
 var path:=route(game.layout,target)
 for next: int in path:
  await clear_room()
  game.travel_to(next)
  await process_frame
 await clear_room()
 check(game.layout.current==target,"Target reachable without using a secret")

func _initialize() -> void:
 run.call_deferred()

func run() -> void:
 root.size=Vector2i(960,540)
 var signatures: Dictionary={}
 for seed_id in range(100):
  for floor_id in range(3):
   var map:=FloorLayout.new()
   map.generate(seed_id,floor_id,true)
   check(map.rooms.size()==12 and map.distances_from_start().size()==12,"Twelve connected rooms")
   var same:=FloorLayout.new()
   same.generate(seed_id,floor_id,true)
   check(map.rooms==same.rooms,"Expanded floors deterministic")
   check(not route(map,map.boss_room).is_empty(),"Boss reachable without secret lock")
   check(map.room_hidden(map.secret_room) and not map.visible_rooms().has(map.secret_room),"Secret hidden initially")
   for i in range(map.rooms.size()):
    map.current=i
    RoomContent.prepare(map)
    for next: int in map.rooms[i].links:
     check(map.rooms[next].links.has(i),"Expanded doors reciprocal")
    for data: Dictionary in map.rooms[i].get("pickups",[]):
     var point: Vector2=data.position
     check(point.x>=70 and point.x<=890 and point.y>=100 and point.y<=450,"Pickup within arena bounds")
     for pillar in [Vector2(320,200),Vector2(640,200),Vector2(320,355),Vector2(640,355)]:
      check(point.distance_to(pillar)>55,"Pickup clear of pillars")
   var signature: Array=[]
   for room: Dictionary in map.rooms: signature.append(room.cell)
   signatures[str(signature)]=true
 check(signatures.size()>100,"Different seeds yield varied layouts")
 game=load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 game.start_dungeon()
 check(game.layout.expanded and game.layout.rooms.size()==12,"Game uses expanded generator")
 var key: RelicPickup=game.pickups[0]
 check(key.data.reward_kind=="key" and game.keys==0,"Physical start key")
 key.claim()
 check(game.keys==1,"Key pickup increments key inventory")
 await navigate(8)
 game.show_doors()
 game.show_shop()
 game.coins=0
 check(not game.buy_offer(2),"Shop refuses insufficient currency")
 game.coins=20
 check(game.buy_offer(2) and game.coins==16,"Shop charges exact key price")
 check(not game.buy_offer(2) and game.coins==16,"Cannot pay twice")
 game.resume_game()
 for pickup in game.pickups:
  if pickup.data.get("reward_kind","")=="key": pickup.claim()
 check(game.keys==2,"Purchased key is physically collected")
 await navigate(9)
 var lever: RoomProp
 var fountain: RoomProp
 for prop in game.props:
  if prop.data.kind=="switch": lever=prop
  if prop.data.kind=="fountain": fountain=prop
 game.player.position=lever.position
 lever._physics_process(0.016)
 check(not game.layout.room_hidden(10),"Lever reveals secret")
 game.player.stats.health=2
 game.player.position=fountain.position
 fountain._physics_process(0.016)
 check(game.player.stats.health==4,"Fountain heals")
 fountain._physics_process(0.016)
 check(game.player.stats.health==4,"Fountain is single use")
 # Get adjacent via an unlocked path; the last step consumes one key exactly.
 var neighbor: int=game.layout.rooms[10].links[0]
 await navigate(neighbor)
 var keys: int=game.keys
 game.travel_to(10)
 check(game.layout.current==10 and game.keys==keys-1,"Secret door consumes a key")
 check(game.pickups.size()==1 and int(RelicCatalog.definition(game.pickups[0].data.id).rarity)<4,"First-floor secret has valid table loot without guaranteed legendary")
 game.pickups[0].data.chest=false
 game.pickups[0].claim()
 game.travel_to(neighbor)
 game.travel_to(10)
 check(game.keys==keys-1 and game.pickups.is_empty(),"Secret lock and loot cannot be farmed")
 # Locked coffer rejection/unlocking uses the same proximity path as real touch movement.
 var chest: RelicPickup=game.spawn_pickup({"id":"crystal","position":Vector2(480,300),"chest":true,"locked":true,"collected":false})
 game.keys=0
 game.player.position=chest.position
 chest.cooldown=0
 chest._physics_process(0.016)
 check(chest.data.chest and not chest.claim(),"Locked coffer cannot be collected without key")
 game.keys=1
 chest.cooldown=0
 chest._physics_process(0.016)
 check(not chest.data.locked and not chest.data.chest and game.keys==0,"Key opens coffer once")
 chest.cooldown=0
 chest._physics_process(0.016)
 check(chest.taking and game.keys==0,"Opened coffer awards item without charging again")
 # New dungeon for isolated props/guardian checks and complete progression.
 game.start_dungeon()
 var secret_neighbor: int=game.layout.rooms[game.layout.secret_room].links[0]
 await navigate(secret_neighbor)
 var door: Vector2=game.door_point(game.layout.secret_room)
 var direction:=Vector2(game.layout.rooms[game.layout.secret_room].cell-game.layout.rooms[game.layout.current].cell)
 game.spawn_bullet(door-direction*30,direction,300,1,200,false)
 game._physics_process(0.3)
 check(not game.layout.room_hidden(game.layout.secret_room),"Shooting the suspicious wall reveals secret")
 game.keys=0
 var room_before: int=game.layout.current
 game.travel_to(game.layout.secret_room)
 check(game.layout.current==room_before and game.keys==0,"Empty key inventory cannot enter locked room")
 var combat:=1
 while game.layout.rooms[combat].kind!="combat": combat+=1
 await navigate(combat)
 var barrel: RoomProp
 for prop in game.props:
  if prop.data.kind=="barrel": barrel=prop
 check(barrel!=null,"Interactive barrel exists")
 barrel.data.drop_type=1
 barrel.data.coin_amount=1
 game.spawn_bullet(barrel.position+Vector2(0,35),Vector2.UP,300,3,100,false)
 var before: int=game.pickups.size()
 game._physics_process(0.1)
 check(barrel.data.used and game.pickups.size()==before+1,"Projectile breaks barrel and drops physical reward")
 barrel.take_damage(10)
 check(game.pickups.size()==before+1,"Broken barrel cannot duplicate drops")
 var trap:=RoomProp.new()
 trap.data={"kind":"trap","position":Vector2(480,274)}
 trap.player=game.player
 trap.position=Vector2(480,274)
 game.world.add_child(trap)
 game.player.position=trap.position
 game.player.immunity=0
 var hp: float=game.player.stats.health
 trap._physics_process(0.4)
 check(game.player.stats.health==hp,"Trap announces before damage")
 trap._physics_process(0.45)
 check(game.player.stats.health<hp,"Trap damages only in active window")
 game.pause_game()
 var age:=trap.clock
 await physics_frame
 await physics_frame
 check(trap.clock==age,"Pause freezes traps")
 game.resume_game()
 game.player.stats.health=game.player.stats.max_health
 for floor_id in range(3):
  await navigate(game.layout.boss_room)
  # navigate cleared the guardian through real damage and signal handling.
  check(game.layout.boss_defeated(),"Guardian defeat recorded")
  var exit_id:=0
  for i in range(game.layout.rooms.size()):
   if game.layout.rooms[i].kind=="descent": exit_id=i
  await navigate(exit_id)
  game.show_doors()
  game.descend()
 check(game.state=="victory","Three expanded floors complete without softlock")
 # Isolate guardian patterns, phases, health UI and elemental compatibility.
 game.start_dungeon()
 game.layout.current=game.layout.boss_room
 game.start_game(true)
 var boss: TideWarden=game.enemies[0]
 check(game.boss_panel.visible and boss.max_health==28,"Guardian health bar and difficulty")
 boss.attack_timer=0.5
 boss._physics_process(0.01)
 check(boss.telegraph and boss.announced,"Guardian announces attacks")
 for pattern in range(3):
  boss.pattern=pattern
  boss.perform_pattern()
 var refuge := true
 for bullet in game.bullets: bullet.expire()
 game.bullets.clear()
 boss.pattern=1
 boss.perform_pattern()
 for bullet in game.bullets:
  if absf(wrapf(bullet.direction.angle()-boss.aim.angle(),-PI,PI))<0.55: refuge=false
 check(refuge,"Guardian ring preserves announced safe arc")
 check(boss.attacks==[1,2,1],"Three distinct guardian patterns executed")
 check(game.bullets.size()>0 and game.hazards.size()>0,"Patterns create real shots and warning zone")
 boss.take_damage(15)
 check(boss.phase==2 and game.boss_bar.value==boss.health,"Second phase and health UI update")
 for bullet in game.bullets: bullet.expire()
 game.bullets.clear()
 boss.pattern=0
 boss.perform_pattern()
 check(game.bullets.size()==5,"Second phase expands aimed fan to five shots")
 boss.burning=3
 var before_hp:=boss.health
 boss._physics_process(0.01)
 check(boss.health<before_hp,"Guardian receives elemental damage")
 boss.take_damage(999)
 await process_frame
 game.clear_wave()
 check(game.layout.boss_defeated() and not game.boss_panel.visible,"Guardian can be defeated")
 check(game.pickups.size()>0,"Boss delivers physical relic reward")
 game.show_main_menu()
 game.show_seed_menu()
 check(not game.start_seeded_run("-1") and not game.start_seeded_run("x"),"Invalid seeds rejected")
 check(game.start_seeded_run("12345") and game.dungeon_seed==12345,"Seed entry starts actual dungeon")
 var original: Array=game.layout.rooms.duplicate(true)
 game.start_dungeon(12345)
 check(game.layout.rooms==original,"Same entered seed reproduces prepared layout")
 game.pause_game()
 check(game.panel.visible,"Seed can be consulted while paused")
 game.queue_free()
 await process_frame
 print("EXPLORATION RESULT: %d checks, %d failures" % [checks,failures])
 quit(1 if failures else 0)

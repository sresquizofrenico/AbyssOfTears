extends SceneTree
var checks := 0
var failures := 0
func check(value: bool, message: String) -> void:
 checks += 1
 if not value:
  failures+=1
  push_error("TEST FAILED: "+message)
func _initialize() -> void:
 run.call_deferred()
func run() -> void:
 root.size=Vector2i(960,540)
 var game = load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 game.start_relic_room()
 check(game.pickups.size()==14,"All fourteen physical relics accessible in laboratory")
 var ids := {}
 for entry: Dictionary in RelicCatalog.DATA:
  ids[entry.id]=true
  check(RelicCatalog.icon(entry.id)!=null,"Original icon loads "+entry.id)
  var inventory := RelicInventory.new()
  var stats := ActorStats.new()
  for i in range(int(entry.max_stack)): check(inventory.add(entry.id,stats),"Stack accepted "+entry.id)
  check(not inventory.add(entry.id,stats),"Stack capped "+entry.id)
 check(ids.size()==100,"Unique relic IDs")
 var p: RelicPickup = game.pickups[1]
 game.player.position=p.position
 p.cooldown=0
 p._physics_process(0.01)
 check(p.taking and game.player.relics.has(p.data.id),"Proximity collects and applies item")
 check(not p.claim(),"Pickup cannot be collected twice")
 check(game.toast.visible and game.toast_icon.texture!=null,"Pickup toast includes icon")
 var chest: RelicPickup = game.pickups[3]
 chest.data.chest=true
 game.player.position=chest.position
 chest.cooldown=0
 chest._physics_process(0.01)
 check(not chest.data.chest and not chest.taking,"Chest opens before pickup")
 chest.cooldown=0
 chest._physics_process(0.01)
 check(chest.taking,"Opened chest awards relic")
 game.start_game()
 var inventory: RelicInventory = game.player.relics
 for id in ["double","crown","fire","ice","electric","pierce","bounce","mirror"]: inventory.add(id,game.player.stats)
 inventory.clock=0
 game.spawn_player_bullet(Vector2(480,400),Vector2.UP,game.player.stats)
 check(game.bullets.size()==12,"Double + crown + mirror has bounded twelve shots")
 var bullet: AbyssProjectile = game.bullets[0]
 check(bullet.pierce==1 and bullet.bounces==1 and bullet.elements.size()==3,"Attack properties compose")
 var enemy: AbyssEnemy = game.enemies[0]
 enemy.position=Vector2(480,200)
 enemy.health=100
 enemy.max_health=100
 var other: AbyssEnemy=game.enemies[1]
 other.position=Vector2(500,200)
 other.health=100
 inventory.impacts=2
 game.apply_relic_hit(bullet,enemy)
 check(enemy.burning==3 and enemy.slowed==2,"Fire and frost coexist")
 check(other.health<100 and game.sparks.size()==1,"Electric impact jumps to nearby enemy")
 var before: float=enemy.health
 enemy._physics_process(0.1)
 check(enemy.health<before,"Burn deals periodic real damage")
 check(enemy.velocity.length()<=enemy.speed*0.61,"Frost slows movement")
 game.start_game()
 inventory=game.player.relics
 inventory.add("shield",game.player.stats)
 before=game.player.stats.health
 game.player.take_damage(1)
 check(game.player.stats.health==before and inventory.shield_timer>0,"Lunar shield blocks hit")
 game.player.immunity=0
 game.player.take_damage(1)
 check(game.player.stats.health<before,"Shield has cooldown")
 inventory.tick(8)
 check(inventory.block_hit(),"Shield recharges")
 game.start_game()
 inventory=game.player.relics
 inventory.add("orbital",game.player.stats)
 var point: Vector2=inventory.orbital_point(game.player.position)
 game.spawn_enemy_bullet(point,Vector2.RIGHT)
 game._physics_process(0.001)
 check(game.bullets.is_empty() or game.bullets[0].expired,"Orbital blocks enemy projectile")
 game.start_game()
 inventory=game.player.relics
 inventory.add("bounce",game.player.stats)
 inventory.add("pierce",game.player.stats)
 game.spawn_player_bullet(Vector2(900,250),Vector2.RIGHT,game.player.stats)
 bullet=game.bullets.back()
 game._physics_process(0.1)
 check(not bullet.expired and bullet.direction.x<0 and bullet.bounces==0,"Wall bounce reverses actual trajectory")
 game.start_game()
 inventory=game.player.relics
 inventory.add("heart",game.player.stats)
 inventory.add("boots",game.player.stats)
 inventory.add("clock",game.player.stats)
 inventory.add("crystal",game.player.stats)
 check(game.player.stats.max_health==7 and game.player.stats.speed==205 and game.player.stats.attack_interval<1.0/2.8 and game.player.stats.damage>1,"Stat relics affect distinct stats")
 game.pause_game()
 game.show_inventory()
 check(game.state=="inventory" and game.panel.visible,"Inventory available from pause")
 game.show_main_menu()
 game.start_dungeon()
 var map: FloorLayout=game.layout
 var treasure:=0
 for i in range(8):
  if map.rooms[i].kind=="treasure": treasure=i
 map.current=treasure
 game.start_game(true)
 check(game.pickups.size()==1,"Treasure has physical pedestal")
 var saved: Dictionary=game.pickups[0].data
 game.pickups[0].claim()
 check(saved.collected,"Collection stored in room state")
 game.start_game(true)
 check(game.pickups.is_empty(),"Revisiting cannot duplicate relic")
 check(not game.player.relics.owned.is_empty(),"Inventory survives room transition")
 game.restart_game()
 check(game.player.relics.owned.is_empty(),"New run clears inventory")
 var rng:=RandomNumberGenerator.new()
 rng.seed=12
 var rarity_counts := [0,0,0,0,0]
 for i in range(10000):
  var id := RelicCatalog.roll(rng)
  rarity_counts[int(RelicCatalog.definition(id).rarity)]+=1
 check(rarity_counts[0]>rarity_counts[1] and rarity_counts[3]==0 and rarity_counts[4]==0,"First-floor base loot excludes epic and legendary rewards")
 game.show_main_menu()
 game.start_game()
 var money: RelicPickup = game.spawn_pickup({"id":"crystal","position":Vector2(480,274),"reward_kind":"coins","collected":false})
 var coins: int = game.coins
 money.claim()
 check(game.coins==coins+5,"Coin chest reward applies")
 game.player.stats.health=2
 var heal: RelicPickup = game.spawn_pickup({"id":"heart","position":Vector2(480,274),"reward_kind":"heal","collected":false})
 heal.claim()
 check(game.player.stats.health==4,"Consumable heals without inventory")
 check(game.player.relics.owned.is_empty(),"Consumables do not become permanent relics")
 game.start_game()
 game.player.relics.add("pierce",game.player.stats)
 for i in range(2,game.enemies.size()): game.enemies[i].position=Vector2(100+i*60,120)
 var first: AbyssEnemy=game.enemies[0]
 var second: AbyssEnemy=game.enemies[1]
 first.position=Vector2(480,200)
 second.position=Vector2(480,170)
 var hp_first: float=first.health
 var hp_second: float=second.health
 game.spawn_player_bullet(Vector2(480,240),Vector2.UP,game.player.stats)
 var piercing: AbyssProjectile=game.bullets.back()
 game._physics_process(0.2)
 check(first.health<hp_first and second.health<hp_second and piercing.hits.size()==2,"Piercing hits two distinct enemies once each")
 game.start_game()
 var curse:=EnemyHazard.new()
 curse.kind="curse"
 curse.player=game.player
 curse.position=game.player.position
 game.world.add_child(curse)
 curse._physics_process(0.9)
 game.player.relics.add("boots",game.player.stats)
 curse.restore()
 check(is_equal_approx(game.player.stats.speed,205),"Curse restoration preserves speed relic gained during curse")
 game.start_benchmark()
 check(game.enemies.size()==game.MAX_ENEMIES and game.bullets.size()==game.MAX_BULLETS,"Stress chamber reaches fixed budgets")
 game._physics_process(0.016)
 check(game.bullets.size()<=game.MAX_BULLETS,"Stress simulation remains bounded")
 game.queue_free()
 await process_frame
 print("RELIC RESULT: %d checks, %d failures" % [checks,failures])
 await preload("res://tests/audio_test_cleanup.gd").drain(self)
 quit(1 if failures else 0)

extends SceneTree
var failures := 0
var checks := 0
func check(value: bool, message: String) -> void:
 checks += 1
 if not value:
  failures += 1
  push_error("TEST FAILED: " + message)
func _initialize() -> void:
 run.call_deferred()
func run() -> void:
 root.size = Vector2i(960,540)
 var game = load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 game.start_game()
 var ids := {}
 for kind in range(20):
  game.start_game()
  for other in game.enemies: other.set_physics_process(false)
  game.spawn_enemy(kind,Vector2(480,210))
  var enemy: AbyssEnemy = game.enemies.back()
  enemy.set_physics_process(false)
  ids[enemy.definition.id] = true
  check(enemy.definition.name.length()>0 and enemy.health>0,"Enemy data %d" % kind)
  var before := enemy.health
  enemy.take_damage(1)
  check(enemy.health < before,"Enemy receives damage %d" % kind)
  var population: int = game.enemies.size()
  var shots: int = game.bullets.size()
  enemy.perform_attack(Vector2.DOWN)
  if kind in [1,4,11,17]:
   check(game.bullets.size()>shots,"Ranged pattern %d" % kind)
  if kind in [7,8,12,16,19]:
   var found := false
   for node in game.world.get_children():
    if node is EnemyHazard: found = true
   check(found,"Hazard emitted %d" % kind)
  if kind == 10: check(game.enemies.size()>population,"Summoner creates larva")
  if kind == 5: check(enemy.collision_mask==0,"Ghost phases pillars")
  if kind == 6:
   enemy.facing = Vector2.DOWN
   before = enemy.health
   enemy.take_damage(1,Vector2.UP)
   check(is_equal_approx(before-enemy.health,0.3),"Directional armor reduces frontal hit")
  if kind == 15:
   enemy.health = 1
   enemy._physics_process(0.01)
   check(game.enemies.size()==population+1,"Duplicator creates one weak copy")
   enemy._physics_process(0.01)
   check(game.enemies.size()==population+1,"Duplicator cannot recurse")
  if kind == 13:
   enemy.destination = Vector2(700,400)
   enemy.perform_attack(Vector2.DOWN)
   check(enemy.position==Vector2(700,400),"Hunter moves to announced destination")
  if kind in [0,2,3,4,9]:
   enemy._physics_process(0.1)
   check(enemy.velocity==Vector2.ZERO if kind==4 else enemy.velocity.length()>0,"Locomotion %d" % kind)
  if kind in [14,18]:
   enemy.take_damage(100)
   if kind == 18: check(game.enemies.size()==population+1,"Colossus releases two larvae")
   else:
    var explosion := false
    for node in game.world.get_children():
     if node is EnemyHazard and node.kind=="explosion": explosion=true
    check(explosion,"Core leaves announced death explosion")
 check(ids.size()==20,"Twenty unique IDs")
 game.start_game()
 var h := EnemyHazard.new()
 h.kind="curse"
 h.player=game.player
 h.position=game.player.position
 game.world.add_child(h)
 var speed: float = game.player.stats.speed
 h._physics_process(0.9)
 check(game.player.stats.speed<speed,"Curse reduces speed")
 h.restore()
 check(game.player.stats.speed==speed,"Curse restores speed")
 for i in range(100): game.spawn_enemy(10,Vector2(100,100))
 check(game.enemies.size()==game.MAX_ENEMIES,"Summon population cap")
 for i in range(30): game.spawn_hazard(Vector2(400,200),"acid")
 var hazard_count := 0
 for node in game.world.get_children():
  if node is EnemyHazard: hazard_count+=1
 check(hazard_count<=game.MAX_HAZARDS,"Hazard budget")
 game.show_main_menu()
 game.expedition=true
 game.start_game()
 var seen := {}
 for wave in range(5):
  for enemy in game.enemies: seen[enemy.kind]=true
  # Despawn without death triggers to inspect the progression graph independently.
  for enemy in game.enemies: enemy.queue_free()
  game.enemies.clear()
  game.clear_wave()
 check(seen.size()==20 and game.state=="victory","Expedition exposes every enemy and can end")
 game.queue_free()
 await process_frame
 print("ENEMY RESULT: %d checks, %d failures" % [checks,failures])
 quit(1 if failures else 0)

extends SceneTree
var game
func _initialize() -> void:
 run.call_deferred()
func step() -> void:
 while game.bullets.size()<game.MAX_BULLETS:
  game.spawn_enemy_bullet(Vector2(480,220),Vector2.UP)
 game._physics_process(1.0/60.0)
 for enemy in game.enemies: enemy._physics_process(1.0/60.0)
func run() -> void:
 var samples: Array[float]=[]
 for trial in range(5):
  game=load("res://scenes/main.tscn").instantiate()
  root.add_child(game)
  game.start_benchmark()
  for enemy in game.enemies: enemy.set_physics_process(false)
  for warmup in range(120): step()
  var begin:=Time.get_ticks_usec()
  for i in range(720): step()
  samples.append((Time.get_ticks_usec()-begin)/720.0/1000.0)
  game.queue_free()
  await process_frame
 samples.sort()
 print("BENCHMARK_MS_PER_STEP ",samples," MEDIAN ",samples[2])
 quit()

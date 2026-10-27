extends SceneTree

var failures := 0
var checks := 0
var game

func _initialize() -> void:
 run.call_deferred()

func expect(condition: bool, message: String) -> void:
 checks += 1
 if not condition:
  failures += 1
  push_error("TEST FAILED: " + message)
 else:
  print("PASS: " + message)

func touch(index: int, point: Vector2, pressed: bool) -> InputEventScreenTouch:
 var event := InputEventScreenTouch.new()
 event.index = index
 event.position = point
 event.pressed = pressed
 return event

func run() -> void:
 root.size = Vector2i(960,540)
 var settings = root.get_node("Settings")
 var previous: Dictionary = settings.values.duplicate()
 expect(settings.validate(null) == settings.DEFAULTS, "Corrupt settings recover defaults")
 expect(settings.validate({"version":99}) == settings.DEFAULTS, "Unsupported settings version recovers defaults")
 var clean: Dictionary = settings.validate({"version":1,"quality":999,"control_scale":-1,"control_opacity":"bad"})
 expect(clean.quality == 2 and clean.control_scale == 0.8 and clean.control_opacity == 0.75, "Settings validate types and clamp ranges")
 # Actual damaged-file recovery, in an isolated user data directory set by tools/validate.py.
 var saved_exists := FileAccess.file_exists(settings.PATH)
 var saved_text := FileAccess.get_file_as_string(settings.PATH) if saved_exists else ""
 var file := FileAccess.open(settings.PATH,FileAccess.WRITE)
 file.store_string("{broken json")
 file.close()
 settings.load_settings()
 expect(settings.values == settings.DEFAULTS, "Damaged file loads without crashing")
 settings.values.control_opacity = 0.55
 expect(settings.save_settings() == OK, "Settings save atomically")
 settings.values = settings.DEFAULTS.duplicate()
 settings.load_settings()
 expect(is_equal_approx(settings.values.control_opacity, 0.55), "Settings survive reload")
 settings.values = previous
 if saved_exists:
  file = FileAccess.open(settings.PATH,FileAccess.WRITE)
  file.store_string(saved_text)
  file.close()
 else:
  DirAccess.remove_absolute(settings.PATH)

 var stats := ActorStats.new()
 stats.modify({"max_health":-100,"speed":10000,"attack_interval":-10,"health":100,"effect_chance":8})
 expect(stats.max_health == 1 and stats.health == 1 and stats.speed == 400 and stats.attack_interval == 0.08 and stats.effect_chance == 1, "Stats enforce safe bounds and allowlist")
 stats.apply_damage(100)
 expect(stats.health == 0, "Lethal damage clamps health to zero")
 game = load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 expect(game.state == "menu" and game.panel.visible, "Main scene opens menu")
 game.show_credits()
 expect(game.state == "credits" and game.panel.visible, "Bundled engine licenses open in credits")
 game.show_main_menu()
 game.start_game()
 await physics_frame
 expect(game.enemies.size() == 6, "Room spawns all three enemy types")
 var kinds: Dictionary = {}
 for enemy in game.enemies: kinds[enemy.kind] = true
 expect(kinds.size() == 3, "Distinct enemy behaviors exist")
 var controls: TouchControls = game.controls
 var center := controls.joystick_center()
 # Inject through the viewport, exercising the real input callback.
 root.push_input(touch(0,center+Vector2(40,-40),true), true)
 root.push_input(touch(1,controls.attack_positions()[1],true), true)
 await process_frame
 expect(controls.move_vector.length() > 0.9 and controls.fire_vector == Vector2.RIGHT, "Two independent touch fingers move and fire together")
 expect(controls.move_vector.length() <= 1.001, "Diagonal movement is normalized")
 var start_position: Vector2 = game.player.position
 for i in range(8): await physics_frame
 expect(game.player.position.distance_to(start_position) > 1.0, "Touch movement drives the character")
 expect(game.bullets.size() > 0, "Held attack creates projectiles while moving")
 root.push_input(touch(1,controls.attack_positions()[1],false), true)
 expect(controls.fire_vector == Vector2.ZERO and controls.move_vector.length() > 0, "Releasing attack preserves joystick")
 root.push_input(touch(2,controls.attack_positions()[0],true), true)
 root.push_input(touch(3,controls.attack_positions()[2],true), true)
 expect(controls.fire_vector == Vector2.DOWN, "Last attack finger selects one cardinal direction")
 root.push_input(touch(3,controls.attack_positions()[2],false), true)
 expect(controls.fire_vector == Vector2.UP, "Releasing last attack restores held direction")
 game.pause_game()
 expect(game.state == "paused" and controls.move_vector == Vector2.ZERO and controls.fire_vector == Vector2.ZERO, "Pause clears all touch state")
 var paused_position: Vector2 = game.player.position
 await physics_frame
 await physics_frame
 expect(game.player.position == paused_position, "Pause freezes simulation")
 game.show_options("paused")
 expect(game.state == "options", "Options opens from pause")
 game.resume_game()
 game.player.cooldown = 0
 expect(game.player.try_shoot(Vector2.UP), "First shot allowed")
 expect(not game.player.try_shoot(Vector2.UP), "Cadence rejects immediate second shot")
 var health: float = game.player.stats.health
 game.player.take_damage(1)
 game.player.take_damage(1)
 expect(game.player.stats.health == health-1, "Invulnerability blocks repeated damage")
 expect(game.health_bar.value == game.player.stats.health, "HUD health bar reflects damage")
 game.player.position = Vector2(58,275)
 controls.move_vector = Vector2.LEFT
 for i in range(10): await physics_frame
 controls.release_all()
 expect(game.player.position.x >= 54.9, "Player body cannot cross chamber wall")
 var chamber = game.chamber
 expect(chamber.blocks(Vector2(320,200)) and chamber.blocks(Vector2(10,10)) and not chamber.blocks(Vector2(480,390)), "Pillars and walls block projectiles")
 var projectile := AbyssProjectile.new()
 game.world.add_child(projectile)
 projectile.remaining = 1
 projectile.advance(0.1)
 expect(projectile.expired, "Projectiles expire at range limit")
 # Keep enemies still to make bullet-hit integration deterministic.
 for enemy in game.enemies: enemy.set_physics_process(false)
 var victim: AbyssEnemy = game.enemies[0]
 victim.position = Vector2(480,300)
 victim.health = 1
 var old_count: int = game.enemies.size()
 game.spawn_bullet(Vector2(480,330),Vector2.UP,600,1,100,false)
 for i in range(6): await physics_frame
 expect(game.enemies.size() == old_count-1 and game.coins == 0, "Projectile collision kills enemy without a guaranteed automatic payment")
 for enemy in game.enemies.duplicate(): enemy.take_damage(999)
 await process_frame
 expect(game.state == "victory", "Last enemy triggers victory")
 game.start_game()
 expect(game.coins == 0 and game.enemies.size() == 6 and game.player.stats.health == 6, "Restart creates a clean run")
 game.player.take_damage(999)
 expect(game.state == "defeat", "Player death triggers defeat")
 game.start_game()
 game._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
 expect(game.state == "paused", "Focus loss pauses game")
 game.show_main_menu()
 expect(game.world == null and game.bullets.is_empty() and game.enemies.is_empty(), "Menu disposes previous run")
 game.start_game()
 for i in range(game.MAX_BULLETS + 20): game.spawn_enemy_bullet(Vector2(480,150),Vector2.DOWN)
 expect(game.bullets.size() == game.MAX_BULLETS, "Projectile budget limits memory")
 game.show_main_menu()
 root.size = Vector2i(1280,540)
 await process_frame
 game.start_game()
 await process_frame
 expect(game.world.position.x > 0 and game.controls.attack_center().x > 1000, "Wide-screen layout centers room and anchors controls")
 game.controls.scale_factor = 1.25
 var lowest: Vector2 = game.controls.attack_positions()[2]
 expect(lowest.y + 30 * game.controls.scale_factor < game.controls.size.y, "Largest controls remain within screen")
 for quality in range(3):
  settings.values.quality = quality
  game.chamber.quality = quality
  game.chamber.queue_redraw()
  await process_frame
 print("SMOKE: All three graphics profiles exercised")
 settings.values = previous
 game.show_main_menu()
 game.queue_free()
 await process_frame
 print("RESULT: %d checks, %d failures" % [checks, failures])
 await preload("res://tests/audio_test_cleanup.gd").drain(self)
 quit(1 if failures else 0)

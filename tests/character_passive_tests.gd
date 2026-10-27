extends SceneTree
var checks:=0
var failures:=0
var game
func check(value: bool, message: String) -> void:
 checks+=1
 if not value:
  failures+=1
  push_error("TEST FAILED: "+message)
func _initialize() -> void: run.call_deferred()
func prepare(id: String) -> AbyssPlayer:
 game.dungeon_mode=false
 game.trial_kind=""
 game.expedition=false
 game.lab_mode=false
 game.selected_character=id
 game.start_game()
 game.world.process_mode=Node.PROCESS_MODE_DISABLED
 return game.player
func run() -> void:
 var progress:=CharacterCatalog.progress_node()
 var saved: Dictionary=progress.data.duplicate(true)
 var path: String=progress.storage_path
 progress.storage_path="user://passives-test.json"
 progress.data=progress.fresh()
 for entry: Dictionary in CharacterCatalog.DATA: progress.data.unlocked.append(entry.id)
 game=load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 game.set_physics_process(false)
 var player:=prepare("neris")
 var speed:=player.stats.speed
 CharacterRules.special_room(player,0)
 check(player.stats.speed==speed+20,"Exploration passive changes real speed")
 player.tick_ability(1)
 CharacterRules.special_room(player,0)
 check(player.character_state.passive_timer==3 and player.stats.speed==speed+20,"Revisiting cannot renew or stack the exploration reward")
 CharacterRules.special_room(player,1)
 check(player.character_state.passive_timer==4 and player.stats.speed==speed+20,"Next floor permits one fresh exploration effect")
 player=prepare("nyra")
 speed=player.stats.speed
 player.activate_ability()
 var health:=player.stats.health
 player.take_damage(1)
 check(player.stats.health==health and player.stats.speed==speed+30 and player.evasion_window==0,"Real evaded hit grants Nyra one brief speed bonus")
 player.take_damage(1)
 check(player.stats.speed==speed+30,"Repeated immunity callbacks cannot stack the bonus")
 player.tick_ability(2.1)
 check(is_equal_approx(player.stats.speed,speed),"Nyra passive expires independently of her decoy")
 player=prepare("kael")
 var target: AbyssEnemy=game.enemies[0]
 target.health=100
 var bullet:=AbyssProjectile.new()
 bullet.damage=1
 for i in range(4): game.apply_relic_hit(bullet,target)
 check(game.bullets.size()==2 and game.bullets[0].generation==1,"Fourth primary Kael impact creates exactly two bounded fragments")
 for fragment: AbyssProjectile in game.bullets.duplicate(): game.apply_relic_hit(fragment,target)
 check(game.bullets.size()==2,"Secondary fragments cannot recursively fragment")
 bullet.free()
 player=prepare("lumi")
 health=player.stats.health
 player.take_damage(1)
 var first:=health-player.stats.health
 player.immunity=0
 health=player.stats.health
 player.take_damage(1)
 var second:=health-player.stats.health
 check(second<first and player.character_state.guard_charge,"Lumi protects the next real incoming hit")
 player.character_state.healing_left=0
 player.ability_remaining=0
 check(not player.activate_ability(),"Lumi cannot create infinite healing after the run budget is exhausted")
 player=prepare("vex")
 target=game.enemies[0]
 target.health=100
 bullet=AbyssProjectile.new()
 bullet.damage=1
 bullet.elements=["fire","ice"]
 game.apply_relic_hit(bullet,target)
 first=100-target.health
 health=target.health
 game.apply_relic_hit(bullet,target)
 second=health-target.health
 check(first>second and target.reaction_cooldown>0,"Two different elements trigger Vex's bounded reaction")
 bullet.free()
 player=prepare("orin")
 health=player.stats.health
 player.take_damage(2,"contact")
 first=health-player.stats.health
 player.immunity=0
 health=player.stats.health
 player.take_damage(2,"projectile")
 second=health-player.stats.health
 check(first<second,"Fortress reduces contact damage more than projectile damage")
 player.immunity=0
 player.activate_ability()
 health=player.stats.health
 player.take_damage(2)
 check(player.stats.health==health and is_equal_approx(player.character_state.shield_budget,0.5),"Ancient barrier consumes a finite damage budget")
 player.take_damage(2)
 check(player.stats.health<health and player.character_state.shield_budget==0,"Barrier spills damage after its budget is exhausted")
 player=prepare("eira")
 target=game.enemies[0]
 target.health=100
 bullet=AbyssProjectile.new()
 bullet.damage=0.1
 for i in range(3): game.apply_relic_hit(bullet,target)
 check(target.chill_stacks==3 and target.frozen>0,"Consecutive Eira impacts briefly freeze a normal enemy")
 for i in range(10): game.apply_relic_hit(bullet,target)
 check(target.chill_stacks==3 and target.slow_strength<=0.6,"Chill stacking has a hard limit")
 game.spawn_guardian(0)
 target=game.enemies.back()
 for i in range(3): game.apply_relic_hit(bullet,target)
 check(target.frozen==0,"Bosses resist immobilization")
 bullet.free()
 player=prepare("solen")
 player.relics.effects.rng.seed=81273
 var burns:=0
 for i in range(100):
  for shot: AbyssProjectile in game.bullets: shot.expire()
  game.bullets.clear()
  game.spawn_player_bullet(player.position,Vector2.UP,player.stats)
  if "fire" in game.bullets[0].elements: burns+=1
 check(burns>=20 and burns<=50,"Solen's normal attacks use moderate real burn probability")
 player=prepare("mira")
 player.velocity=Vector2(player.stats.speed,0)
 game.spawn_enemy_bullet(player.position+Vector2(24,0),Vector2.UP)
 game._physics_process(0.001)
 check(player.character_state.shadow_timer>0 and player.pursuit_point()!=player.position,"An actual close-moving projectile grants Mira a distracting illusion")
 var cooldown: float=player.character_state.evasion_cooldown
 CharacterRules.near_miss(player,24)
 check(player.character_state.evasion_cooldown==cooldown,"Near-miss effects cannot multiply from repeated samples")
 player=prepare("nox")
 var damage:=player.stats.damage
 for i in range(8):
  game.spawn_enemy(0,Vector2(500,180))
  game.enemies.back().take_damage(1000)
 check(player.character_state.kill_stacks==3 and is_equal_approx(player.stats.damage,damage+0.15),"Nox kill power is capped at three actual defeat events")
 player.tick_ability(3.1)
 check(player.character_state.kill_stacks==0 and is_equal_approx(player.stats.damage,damage),"Nox kill bonuses expire without damaging permanent stats")
 game.queue_free()
 await process_frame
 await process_frame
 await create_timer(0.25).timeout
 progress.data=saved
 progress.storage_path=path
 print("CHARACTER PASSIVES RESULT: %d checks, %d failures" % [checks,failures])
 await preload("res://tests/audio_test_cleanup.gd").drain(self)
 quit(1 if failures else 0)

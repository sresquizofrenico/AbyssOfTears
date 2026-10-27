extends SceneTree
var checks:=0
var failures:=0
func check(value: bool, message: String) -> void:
 checks+=1
 if not value:
  failures+=1
  push_error("TEST FAILED: "+message)
func _initialize() -> void:
 run.call_deferred()
func touch(point: Vector2, finger: int, pressed: bool) -> void:
 var event:=InputEventScreenTouch.new()
 event.index=finger
 event.position=point
 event.pressed=pressed
 root.push_input(event,true)
func run() -> void:
 root.size=Vector2i(960,540)
 var progress:=CharacterCatalog.progress_node()
 var original: Dictionary=progress.data.duplicate(true)
 var old_path: String=progress.storage_path
 progress.storage_path="user://character-test.json"
 progress.data=progress.fresh()
 var settings_before:=FileAccess.get_file_as_string("user://settings.json") if FileAccess.file_exists("user://settings.json") else ""
 check(CharacterCatalog.DATA.size()==10,"Ten distinct original definitions")
 var ids: Dictionary={}
 for entry: Dictionary in CharacterCatalog.DATA:
  check(not ids.has(entry.id),"Character IDs unique")
  ids[entry.id]=true
  check(CharacterCatalog.preview_stats(entry.id)!=null,"Locked statistics have a valid data source")
  check(CharacterCatalog.texture(entry.id)!=null,"Each character has a real loadable sprite")
  check(entry.cooldown>entry.duration and entry.duration>0,"Abilities have bounded duration and recharge")
  check(CharacterSounds.ability_sound(entry.id).data.size()>0,"Original ability audio has actual samples")
  check(CharacterCatalog.playable(entry.id)==(entry.id=="neris"),"Fresh save unlocks only original protagonist")
 check(CharacterCatalog.definition("neris").name.contains("Errante"),"Original Neris ID retained")
 check(not CharacterCatalog.playable("missing"),"Unknown character denied")
 var game=load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 game.show_character_selection()
 await process_frame
 var selection: CharacterSelection=game.panel
 for i in range(10):
  check(selection.index==i,"Navigation visits every catalog entry")
  check(selection.begin_button.disabled==(i!=0),"Locked characters cannot begin")
  if i>0:
   check(selection.character.modulate.r<0.1,"Locked art is an obscured silhouette")
   check(selection.heading.text=="Viajero sellado" and selection.status.text.contains("Progreso"),"Hidden name and real requirement progress")
   selection.start()
   check(not selection.pending and not game.begin_character_run(selection.entries[i].id),"Both UI and gameplay reject locked start")
  selection.select_offset(1)
 check(selection.index==0,"Navigation wraps safely")
 check(progress.begin_run(),"New run persisted")
 check(progress.record("enemy","a"),"First enemy event accepted")
 check(not progress.record("enemy","a") and progress.amount("enemies")==1,"Duplicate event cannot inflate progress")
 for i in range(1,100): progress.record("enemy","e%d" % i)
 check(progress.is_unlocked("eira"),"One hundred real enemy events unlock Eira")
 for i in range(3): progress.record("floor","floor%d" % i,{"character":"neris"})
 check(progress.is_unlocked("nyra"),"Three Errante floors unlock Nyra")
 progress.record("boss","guardian",{"elemental":true})
 check(progress.is_unlocked("kael") and progress.is_unlocked("solen"),"Boss and elemental boss unlocks")
 progress.record("secret","wall")
 check(progress.is_unlocked("mira"),"Secret discovery unlocks Mira")
 for i in range(4): progress.record("room","r%d" % i,{"clean":true})
 progress.record("room","hit",{"clean":false})
 check(not progress.is_unlocked("lumi"),"Damage breaks the clean-room streak")
 for i in range(5): progress.record("room","clean%d" % i,{"clean":true})
 check(progress.is_unlocked("lumi"),"Five consecutive clean rooms unlock Lumi")
 progress.record("ending","main")
 check(progress.is_unlocked("nox"),"Main ending unlocks Nox")
 for entry: Dictionary in RelicCatalog.DATA: progress.record("item",entry.id,{"id":entry.id})
 check(progress.amount("items")==14 and not progress.is_unlocked("vex"),"Fourteen available objects never masquerade as twenty")
 check(not progress.is_unlocked("orin"),"No fabricated minijefe achievement")
 var backup_code: String=progress.export_code()
 var backup_count: int=progress.amount("enemies")
 check(not progress.import_code("invalid") and progress.amount("enemies")==backup_count,"Invalid backup never clears progress")
 progress.data=progress.fresh()
 check(progress.import_code(backup_code) and progress.is_unlocked("eira") and progress.amount("items")==14,"Portable backup restores permanent progress")
 progress.record("enemy","new-after-backup")
 check(progress.import_code(backup_code) and progress.amount("enemies")==backup_count+1,"Import merges progress without rewinding newer achievements")
 var before: Dictionary=progress.data.duplicate(true)
 check(progress.save_progress()==OK,"Progress written to user storage")
 progress.data=progress.fresh()
 progress.load_progress()
 check(progress.data==before,"Permanent unlocks and counters survive reload")
 var file:=FileAccess.open(progress.storage_path,FileAccess.WRITE)
 file.store_string("broken JSON")
 file.close()
 progress.load_progress()
 check(progress.recovered and progress.is_unlocked("eira"),"Corrupted primary recovers last valid backup")
 check(progress.validate({"version":99}).is_empty(),"Unknown future format is rejected")
 var bad: Dictionary=progress.fresh()
 bad.counters.enemies="invalid"
 check(progress.validate(bad).is_empty(),"Invalid progress counters rejected")
 var readonly_path: String=progress.storage_path
 progress.storage_path="user://missing-parent/progress.json"
 before=progress.data.duplicate(true)
 check(not progress.record("enemy","iofail") and progress.data==before,"Failed save rolls back event and counter")
 progress.storage_path=readonly_path
 # Unlock unavailable content only in this isolated test fixture, never in release code.
 for entry: Dictionary in CharacterCatalog.DATA:
  if not progress.data.unlocked.has(entry.id): progress.data.unlocked.append(entry.id)
 game.show_main_menu()
 for entry: Dictionary in CharacterCatalog.DATA:
  game.selected_character=entry.id
  game.start_dungeon(786)
  var player: AbyssPlayer=game.player
  var stats:=CharacterCatalog.preview_stats(entry.id)
  check(player.character_id==entry.id and player.stats.damage==stats.damage and player.stats.speed==stats.speed,"Real gameplay uses selected initial stats")
  check(player.body_texture==CharacterCatalog.texture(entry.id),"Gameplay sprite matches selection")
  check(player.relics.add("crystal",player.stats),"Existing item acquisition works for each character")
  check(is_equal_approx(player.stats.damage,stats.damage+0.35),"Permanent item damage is applied")
  player.stats.health=maxf(1,player.stats.max_health-2)
  check(game.use_character_ability(),"Each character ability executes")
  check(not game.use_character_ability(),"Rapid repeat cannot bypass recharge")
  check(player.ability_active>0 and player.ability_remaining>0,"Ability timers initialized")
  match entry.id:
   "neris":
    player._physics_process(0.01)
    check(is_equal_approx(player.velocity.length(),520) and player.immunity>0,"Astral dash moves with temporary protection")
   "nyra":
    player.position+=Vector2(80,0)
    check(player.pursuit_point()!=player.position,"Nyra leaves an actual alternate pursuit target")
    game.spawn_enemy(0,player.skill_origin)
    var enemy: AbyssEnemy=game.enemies.back()
    var health:=player.stats.health
    enemy._physics_process(0.01)
    check(player.stats.health==health,"Enemy at decoy cannot damage distant player")
   "kael": check(game.bullets.back().pierce==4 and is_equal_approx(game.bullets.back().damage,player.stats.damage*3),"Rupture is stronger and genuinely piercing")
   "lumi":
    var health:=player.stats.health
    for i in range(40): player.tick_ability(0.1)
    check(player.stats.health>health and player.stats.health<=health+1.501,"Restorative field has a finite healing budget")
   "vex":
    game.spawn_player_bullet(player.position,Vector2.UP,player.stats)
    check(not game.bullets.back().elements.is_empty(),"Alchemical skill adds a combat element")
   "orin":
    var health:=player.stats.health
    player.take_damage(2)
    check(player.stats.health==health,"Ancient barrier actually blocks damage")
   "eira","solen":
    player.ability_remaining=0
    game.spawn_enemy(0,player.position+Vector2(60,0))
    var enemy: AbyssEnemy=game.enemies.back()
    game.use_character_ability()
    check(enemy.slowed>0 if entry.id=="eira" else enemy.burning>0,"Elemental area ability affects real enemy state")
   "mira":
    game.spawn_player_bullet(player.position,Vector2.UP,player.stats)
    check(game.bullets.size()==2,"Living reflection produces a second actual shot")
   "nox":
    check(player.stats.damage>stats.damage+0.35 and player.stats.attack_interval<stats.attack_interval,"Abyss power changes actual combat stats")
    player.relics.add("crystal",player.stats)
    player.tick_ability(4.1)
    check(player.fatigue>0 and player.stats.speed<stats.speed,"Abyss power has a real exhaustion drawback")
    player.tick_ability(2.1)
    check(is_equal_approx(player.stats.damage,stats.damage+0.7),"Buff expiration preserves permanent upgrades acquired during skill")
  var recharge:=player.ability_remaining
  game.start_game(true)
  check(is_equal_approx(game.player.ability_remaining,recharge),"Changing rooms cannot reset cooldown")
  game.pause_game()
  var paused_recharge: float=game.player.ability_remaining
  await process_frame
  check(game.player.ability_remaining==paused_recharge,"Pause freezes character timers")
  game.resume_game()
 # Three simultaneous real ScreenTouch streams: movement, shooting and skill.
 game.selected_character="neris"
 game.start_dungeon(887)
 touch(game.controls.joystick_center()+Vector2(30,0),31,true)
 touch(game.controls.attack_positions()[0],32,true)
 touch(game.controls.ability_center(),33,true)
 check(game.controls.move_vector.x>0 and game.controls.fire_vector==Vector2.UP and game.player.ability_remaining>0,"Three-finger movement, attack and ability coexist")
 touch(game.controls.ability_center(),33,false)
 check(game.controls.move_vector.x>0 and game.controls.fire_vector==Vector2.UP,"Releasing ability preserves movement and firing")
 touch(game.controls.joystick_center(),31,false)
 touch(game.controls.attack_positions()[0],32,false)
 check(game.controls.move_vector==Vector2.ZERO and game.controls.fire_vector==Vector2.ZERO,"Touch streams release independently")
 for scale_value in [0.8,1.0,1.25]:
  game.controls.scale_factor=scale_value
  for point: Vector2 in game.controls.attack_positions():
   check(point.distance_to(game.controls.ability_center())>60*scale_value,"Skill target never overlaps firing controls")
 game.show_main_menu()
 game.show_progress_backup()
 await process_frame
 check(game.state=="progress_backup" and game.panel.get_global_rect().end.y<=540,"Progress backup opens as an accessible touch menu")
 check(EnemyCatalog.DATA.size()==20 and game.layout.rooms.size()==12,"Existing enemy and exploration catalogs preserved")
 var settings_after:=FileAccess.get_file_as_string("user://settings.json") if FileAccess.file_exists("user://settings.json") else ""
 check(settings_after==settings_before,"Character progression never rewrites existing settings file")
 game.queue_free()
 await process_frame
 await process_frame
 # Allow the audio server thread to release stopped playback buffers before exit.
 await create_timer(0.25).timeout
 progress.data=original
 progress.storage_path=old_path
 print("CHARACTER PROGRESS RESULT: %d checks, %d failures" % [checks,failures])
 quit(1 if failures else 0)

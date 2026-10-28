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
func freeze() -> void:
 game.set_physics_process(false)
 game.set_process(false)
 game.set_world_active(false)
func round_trip() -> bool:
 if not game.save_now(true): return false
 store.cached=store.load_disk()
 return not store.cached.is_empty() and game.continue_run()
func run() -> void:
 root.size=Vector2i(960,540)
 store=root.get_node("RunSave")
 progress=root.get_node("Progress")
 progress.storage_path="user://durability-progress.json"
 progress.data=progress.fresh()
 progress.redeem("ABISMO-TOTAL")
 store.storage_path="user://durability-run.json"
 store.cached={}
 game=load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 for entry: Dictionary in CharacterCatalog.DATA:
  game.selected_character=entry.id
  game.start_dungeon(981)
  freeze()
  game.player.ability_remaining=11.25
  game.player.character_state.fate_remaining=53.0
  game.player.relics.add("fire",game.player.stats)
  game.player.relics.add("double",game.player.stats)
  game.player.stats.health=maxf(1,game.player.stats.max_health-0.5)
  var health: float=game.player.stats.health
  check(round_trip(),"Real disk round trip: "+str(entry.id))
  freeze()
  check(game.player.character_id==entry.id and game.player.stats.health==health,"Hero identity and life: "+str(entry.id))
  check(game.player.relics.has("fire") and game.player.relics.has("double"),"Combined relics survive: "+str(entry.id))
  check(is_equal_approx(game.player.ability_remaining,11.25) and game.player.character_state.fate_remaining==53,"Ability / emergency cooldown survive: "+str(entry.id))
  if entry.id in BondCatalog.IDS: check(BondArt.rear_texture(entry.id)!=null,"Original back sprite loaded: "+str(entry.id))
 check(not CharacterPresentation.private_enabled(),"Public mode is default")
 for entry: Dictionary in CharacterPresentation.entries():
  check(entry.name==CharacterCatalog.definition(entry.id).name,"Public names stay original")
 # Cold/curse source rebinding and expiry.
 game.resume_game()
 freeze()
 game.spawn_hazard(Vector2(250,240),"cold")
 var cold=game.hazards.back()
 game.player.position=cold.position
 cold._physics_process(0.9)
 var slow: float=game.player.stats.speed
 check(round_trip(),"Activated cold zone is serializable")
 freeze()
 check(is_equal_approx(game.player.stats.speed,slow) and game.hazards.back().activated,"Cold modifier restored exactly once")
 game.hazards.back()._physics_process(5)
 check(not game.player.stats.temporary.has(game.hazards.back().stat_source),"Restored hazard expires and restores speed")
 # All current floors + before/after descent, boss health and room completion.
 game.resume_game()
 freeze()
 for data in game.layout.rooms: data.cleared=true
 game.layout.current=game.layout.boss_room
 game.start_game(true)
 freeze()
 game.spawn_guardian(0)
 game.enemies.back().health=12.5
 check(round_trip(),"Boss room load")
 freeze()
 check(game.enemies.back() is TideWarden and game.enemies.back().health==12.5 and game.boss_bar.value==12.5,"Boss health / bar restored")
 game.resume_game()
 freeze()
 for actor in game.enemies.duplicate(): actor.take_damage(9999)
 game.clear_wave()
 check(game.layout.rooms[game.layout.current].cleared,"Boss defeated normally")
 check(round_trip(),"Completed boss checkpoint")
 freeze()
 check(game.enemies.is_empty() and game.layout.boss_defeated(),"Boss does not respawn after continue")
 for floor_index in range(2):
  game.resume_game()
  freeze()
  game.layout.current=game.layout.rooms.find(game.layout.rooms.filter(func(r): return r.kind=="descent")[0])
  game.layout.rooms[game.layout.current].cleared=true
  game.layout.rooms[game.layout.boss_room].cleared=true
  game.state="doors"
  game.descend()
  freeze()
  check(game.layout.floor_index==floor_index+1,"Descend retains current campaign progression")
  check(round_trip(),"New floor checkpoint")
  freeze()
  check(game.layout.floor_index==floor_index+1 and game.layout.current==0,"Continue starts on correct floor and room")
 # OS suspension and periodic save do not rely on quit notification.
 game.resume_game()
 freeze()
 game.coins=17
 game._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
 store.cached=store.load_disk()
 check(store.cached.coins==17 and game.state=="paused","Application suspension flushes checkpoint")
 game.resume_game()
 freeze()
 game.coins=19
 game.autosave_age=5.1
 game._process(0)
 await process_frame
 store.flush()
 check(store.load_disk().coins==19,"Periodic checkpoint handles abrupt termination without close event")
 game.show_main_menu()
 await process_frame
 var main: AnimatedMainMenu=game.panel
 main.skip_intro()
 main.guard_time=0
 await process_frame
 check(main.buttons.has("continue"),"Continue actually on main screen")
 for pressed in [true,false]:
  var event:=InputEventScreenTouch.new()
  event.index=93
  event.position=main.buttons["continue"].get_global_rect().get_center()
  event.pressed=pressed
  root.push_input(event,true)
 main._process(0.3)
 check(game.state=="paused" and game.dungeon_mode and game.coins==19,"Touch Continue restores saved expedition")
 freeze()
 # Future effects: short initial evasion and bounded emergency protection.
 game.player.configure_character("yura")
 game.player.stats.health=0.5
 game.player.ability_active=4
 game.player.immunity=0
 game.player.character_state.fate_remaining=0
 check(NineBonds.reduce(game.player,2,"projectile")==0 and game.player.character_state.fate_remaining==90,"Yura avoids one fatal predicted hit")
 check(NineBonds.reduce(game.player,2,"projectile")>0,"Fate cannot repeat during long cooldown")
 # Settings have independent atomic backups, preserve selected character.
 var settings=root.get_node("Settings")
 settings.values.selected_character="lyra"
 settings.values.music_volume=0.31
 check(settings.save_settings()==OK,"Settings and selected hero saved")
 settings.values.music_volume=0.42
 check(settings.save_settings()==OK,"Settings backup rotated")
 var file:=FileAccess.open(settings.PATH,FileAccess.WRITE)
 file.store_string("bad")
 file.close()
 settings.load_settings()
 check(is_equal_approx(settings.values.music_volume,0.31) and settings.values.selected_character=="lyra","Corrupt settings recover audio and selected hero")
 # Portable backup includes the actual expedition, not only permanent unlocks.
 game.resume_game()
 freeze()
 game.player.configure_character("lyra")
 game.selected_character="lyra"
 game.coins=23
 game.save_now(true)
 var bundle:=SaveBundle.export_code(progress,store)
 check(bundle.begins_with("AOT5."),"Complete portable format version")
 var before: Dictionary=progress.data.duplicate(true)
 check(not SaveBundle.import_code(bundle.substr(0,bundle.length()-8)+"tampered",progress,store) and progress.data==before,"Damaged complete backup rejected without mutation")
 store.invalidate()
 store.flush()
 check(SaveBundle.import_code(bundle,progress,store),"Portable expedition imports after reinstall simulation")
 store.cached=store.load_disk()
 check(store.available() and store.cached.coins==23 and store.cached.character=="lyra","Portable backup restores actual run and character")
 # Tombstone is durable and subsequent attempts cannot recover a completed run.
 store.invalidate()
 store.flush()
 check(not store.load_disk().active,"Completed/dead run tombstone persists")
 check(not store.read_one(store.storage_path+".bak").active,"Inactive backup cannot resurrect a dead run")
 game.dungeon_mode=false
 game.queue_free()
 await process_frame
 store.flush()
 await preload("res://tests/audio_test_cleanup.gd").drain(self)
 print("DURABILITY RESULT: %d checks, %d failures" % [checks,failures])
 quit(0 if failures==0 else 1)
